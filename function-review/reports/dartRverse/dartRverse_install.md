# Review: dartRverse_install (dartRverse)

- Family mode: io (installer; no genlight in or out)
- Date: 2026-09-24
- Reviewer: Claude (claude-opus-5-5), dartr-function-review v2.0.0
- Package commit: 07e831e (origin/dev)
- Datasets: none apply; installers mocked (`install.packages`,
  `devtools::install_github`); listing mode run live against CRAN and the
  7 GitHub repos
- Baseline: `tests/testthat/test-dartRverse_install.R` (captured
  pre-review; 25 passes with `NOT_CRAN=true`)

## Verdict

**Standards: Needs work** — wrong input is answered with silence rather
than an error in three places, and a 101-package dependency (devtools)
is carried for one function call.

**Spec: Needs work** — single-package installs call the right installer
with the right branch, but the documented multi-package call crashes, a
reinstall leaves the old version running without saying so, and a fresh
R cannot install any dartR package from CRAN without first installing two
Bioconductor packages the function never mentions.

## Findings

**F1 [HIGH, confidence: high] — reinstall runs over a loaded package (principle: session state; no rule fits)**
`R/dartRverse_install.r:196-210` — `library(dartRverse)` attaches all 7
dartR packages (`.onAttach` → `dartR_check()` → `require()`). The install
branch then tries `detach(..., unload = TRUE)`, which fails whenever a
sibling imports the target (dartR.base, dartR.data, dartR.sim, …), and
installs anyway.
Failure scenario (run, installer mocked): `dartRverse_install("dartR.sim",
rep = "github", branch = "dev")` prints two warnings ("namespace
'dartR.sim' is imported by 'dartR.captive' so cannot be unloaded") and
after the install `dartR.base` stays loaded. The user keeps running the
old code, the one a forum reply told them the fix is in, until they
restart R, and nothing tells them to. Replacing an installed package
under a loaded namespace can also produce "lazy-load database is corrupt"
errors (known R behaviour; not reproduced here).
Proposed change: keep the detach attempt but silence its warnings; if the
package was loaded before the install, end with "Restart R to use the new
version of <package>".

**F2 [MEDIUM, confidence: medium] — Bioconductor imports not handled (FS5)**
`R/dartRverse_install.r:196-211` — dartR.base (and therefore every dartR
package) imports `SNPRelate` and `snpStats`, which are on Bioconductor,
not CRAN (`c("SNPRelate","snpStats") %in% rownames(available.packages())`
is `FALSE FALSE`; default `repos` is CRAN only).
Failure scenario: on a fresh R, `dartRverse_install("dartR.base")` ends in
`install.packages()` reporting "dependencies 'SNPRelate', 'snpStats' are
not available", and dartR.base is not installed. Only the `"all"`
instructions mention BiocManager. (Reasoned from the repository contents;
not run in a clean library.)
Proposed change: before installing, check `SNPRelate` and `snpStats` with
`requireNamespace()`; if either is missing, stop and print the two
`BiocManager::install()` commands.

**F3 [MEDIUM, confidence: high] — unknown package name is silent (FS5, VRB2)**
`R/dartRverse_install.r:189-194` — the "error" is `cat(cli::col_red("\n"))`
followed by a visible `return(-1)`.
Failure scenario (run): `dartRverse_install("dartR.popgn")` prints a blank
line and `[1] -1`. The user can't tell that nothing was installed or why.
Proposed change: `stop()` naming the input and listing the valid names.

**F4 [MEDIUM, confidence: high] — unrecognised or NULL `rep` does nothing (FS5)**
`R/dartRverse_install.r:185,196,203` — the two `pmatch()` tests are
independent `if`s with no else, and `rep = NULL` skips the branch.
Failure scenario (run): `dartRverse_install("dartR.sim", rep =
"bioconductor")` and `rep = NULL` both return `NULL` with no output and
install nothing.
Proposed change: validate `rep` against `"CRAN"`/`"Github"` (partial,
case-insensitive, as now) and `stop()` otherwise.

**F5 [MEDIUM, confidence: high] — documented multi-package call crashes (DOC5, proposed rule)**
`R/dartRverse_install.r:3,157` — `@description` says the function takes
"one (or several)" packages; `if (tolower(package) == "all")` errors on a
vector.
Failure scenario (run): `dartRverse_install(c("dartR.sim",
"dartR.popgen"))` stops with "the condition has length > 1".
Proposed change: install each package in turn (validation per F3 applied
to each name first).

**F6 [MEDIUM, confidence: high] — one failed read aborts the version table (FS5)**
`R/dartRverse_install.r:72-127` — the listing makes 21 unguarded
`readLines(url(...))` calls (7 packages × 3 branches) plus a CRAN index
download.
Failure scenario (run with a mocked failing read): any single failure,
such as a firewall that blocks raw.githubusercontent.com, a GitHub
outage or a flaky connection, stops the whole table with "cannot open the
connection". The installed versions, which need no network, are not
shown either.
Proposed change: wrap each remote read; show `?` for a version that
could not be fetched and print one note line saying which source failed.

**F7 [LOW, confidence: medium] — devtools imported for one call (DEP1, DEP2)**
`R/dartRverse_install.r:28-36,208`, `R/zzz.R:2`, `DESCRIPTION` — the only
use of devtools is `devtools::install_github()`, which devtools
re-exports from remotes. devtools pulls in 101 packages recursively;
remotes pulls in 4. The `requireNamespace("devtools")` guard is dead
code because devtools is in Imports.
Failure scenario: on Linux, installing dartRverse compiles the whole
devtools tree (usethis, gert, pkgdown, …), which fails when system
libraries such as libgit2 are missing, so the suite's installer can't be
installed. (Dependency count run; the Linux failure not reproduced.)
Proposed change: call `remotes::install_github()`; replace devtools with
remotes in Imports; remove the dead guard and `@import devtools`.

**F8 [LOW, confidence: high] — documentation disagrees with the code (DOC1, DOC3, DOC5)**
`R/dartRverse_install.r:1-18` — (a) `@param package` omits `dartR.captive`
and doesn't mention `"all"`. (b) `@return` says NULL; the function
returns `invisible(1)` (listing), `-1` (bad name), or the installer's
value. (c) `verbose` only affects listing mode. (d) No `[default ...]`
tags. (e) Typos: "pacakge", "availble", "before the are", "This functions
expects".
Failure scenario: a user reading `?dartRverse_install` can't find
dartR.captive, or learn that the example only prints instructions.
Proposed change: docs-only rewrite of the roxygen block.

**F9 [INFO, confidence: high] — startup message omits snpStats (outside function scope)**
`R/zzz.R:59` — when core packages are missing, `.onAttach` tells users to
run `BiocManager::install('SNPRelate')` then
`dartRverse_install('dartR.base', rep='CRAN')`, without
`BiocManager::install('snpStats')`. A new user following it hits F2.
Proposed change: none here; fix in a separate change to `zzz.R`.

**F10 [INFO, confidence: high] — FS2/FS3/FS9/VRB2 do not fit this package (rule scope)**
As in the `gl.download.binary` review (F8 there): the umbrella package
can't use dartR.base's entry-point helpers.
Proposed change: none.

## Proposed changes

1. Silence the failing detach and, if the package was loaded before the
   install, end with "Restart R to use the new version of <package>" (F1).
2. Before installing, stop with the `BiocManager::install()` commands if
   `SNPRelate` or `snpStats` is missing (F2).
   **Consequence: on a fresh R, the call errors before installing instead
   of failing inside `install.packages()`.**
3. Unknown package names stop with an error listing the valid names (F3).
   **Consequence: returns an error instead of `-1`; any code checking for
   `-1` stops working.**
4. Unrecognised or NULL `rep` stops with an error (F4).
   **Consequence: calls that silently did nothing now error.**
5. Accept several packages and install each in turn (F5).
6. Listing mode survives failed reads, shows `?`, and notes the failure (F6).
7. Replace devtools with remotes (`remotes::install_github()`, Imports,
   remove the dead guard and `@import devtools`) (F7).
8. Rewrite the roxygen block (F8). Docs only.

## Coverage

- Standards walk: FS, DOC, VRB, DEP, STY — run. DAT, PLT — not applicable.
- Install paths (CRAN, Github, partial `rep`, bad name, bad/NULL `rep`,
  vector input, `"all"`) — run with mocked installers; no package was
  installed.
- Listing mode live (6.8 s, no leaked connections) and with one mocked
  failing read — run.
- Loaded-namespace behaviour after a (mocked) reinstall — run.
- Real install in a clean library (F2 end to end, F7 on Linux): SKIPPED —
  would install ~100 packages; no clean Linux machine.
- Branch existence: all 7 repos have `main`, `beta`, `dev` (`git
  ls-remote`) — run.
- Known complaints (dartR Google Group / GitHub issues): SKIPPED — not
  searched in this pass.
- Sibling callers (API3): no package calls `dartRverse_install()` for its
  return value; it appears in startup and help text only (grep of local
  dartR.* checkouts and dartr2shiny) — re-run after applying: no callers.

## Approval

| Change | Decision | By | Note |
|---|---|---|---|
| 1 | approved | Luis | |
| 2 | approved | Luis | consequence approved explicitly |
| 3 | approved | Luis | consequence approved explicitly |
| 4 | approved | Luis | consequence approved explicitly |
| 5 | approved | Luis | |
| 6 | approved | Luis | |
| 7 | approved | Luis | |
| 8 | approved | Luis | |

## Outcome

- 1: reinstalling loaded `dartR.base` (mocked) prints "Restart R to use the new version of dartR.base" with no warnings (baseline printed 6 detach warnings across the run).
- 2: with `snpStats` mocked as missing, the call stops with the `BiocManager::install('snpStats')` command; nothing installed.
- 3: `"dartR.popgn"` stops with "Unknown dartRverse package: dartR.popgn. Use one of: ..."; a vector with one bad name installs nothing.
- 4: `rep = "bioconductor"` and `rep = NULL` stop with "rep must be 'CRAN' or 'Github'".
- 5: `c("dartR.sim", "dartR.popgen")` calls `install_github` twice, in order. The install branch now returns `invisible(NULL)` (it used to return the installer's value).
- 6: with every GitHub read failing (mocked), the table prints 7 rows with `?` and one note line; live run prints all versions.
- 7: `remotes::install_github()`; devtools replaced by remotes in Imports; dead guard and `@import devtools` removed.
- 8: roxygen rewritten; `devtools::document()` regenerated `man/dartRverse_install.Rd` and `NAMESPACE`.
- Snapshot: 33/33 pass, 0 warnings. Every diff from baseline maps to changes 1, 3, 4, 5. No unexplained diff. Installs blocked (dead repos URL, `install.packages` traced): 0 real calls.
- `R CMD check --no-manual`: 0 errors, 0 warnings, 2 notes (untracked local scaffold files; clock check).
- NEWS.md entry added. Callers: none in sibling `R/` code or dartr2shiny.
- Addendum (approved by Luis in chat): `NEWS.md` heading `# dartRverse (development version)` gave the R CMD check note "No news entries found" on R 4.4.2; renamed to `# dartRverse 1.2.2.9000`, which `tools:::.build_news_db_from_package_NEWS_md()` parses.
- Rebased onto `dev` after #41 merged; `DESCRIPTION`/`NAMESPACE` conflicts resolved (RCurl stays removed).
- PR: #43.

```json
{
  "function": "dartRverse_install",
  "package": "dartRverse",
  "family": "io",
  "skill_version": "2.0.0",
  "commit": "07e831e",
  "verdict_standards": "needs_work",
  "verdict_spec": "needs_work",
  "findings": [
    {"id": "F1", "severity": "HIGH", "confidence": "high", "rule": "none: session state", "status": "approved", "change": 1},
    {"id": "F2", "severity": "MEDIUM", "confidence": "medium", "rule": "FS5", "status": "approved", "change": 2},
    {"id": "F3", "severity": "MEDIUM", "confidence": "high", "rule": "FS5", "status": "approved", "change": 3},
    {"id": "F4", "severity": "MEDIUM", "confidence": "high", "rule": "FS5", "status": "approved", "change": 4},
    {"id": "F5", "severity": "MEDIUM", "confidence": "high", "rule": "DOC5", "status": "approved", "change": 5},
    {"id": "F6", "severity": "MEDIUM", "confidence": "high", "rule": "FS5", "status": "approved", "change": 6},
    {"id": "F7", "severity": "LOW", "confidence": "medium", "rule": "DEP2", "status": "approved", "change": 7},
    {"id": "F8", "severity": "LOW", "confidence": "high", "rule": "DOC1", "status": "approved", "change": 8},
    {"id": "F9", "severity": "INFO", "confidence": "high", "rule": "none: outside scope", "status": "no_change", "change": null},
    {"id": "F10", "severity": "INFO", "confidence": "high", "rule": "FS2", "status": "no_change", "change": null}
  ],
  "coverage_skipped": [
    "clean-library install (F2) and Linux devtools install (F7): not run",
    "Google Group / GitHub issues: not searched"
  ],
  "status": "pr-open",
  "pr": 43
}
```
