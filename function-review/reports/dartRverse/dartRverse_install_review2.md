# Review: dartRverse_install (dartRverse), second pass

- Family mode: io (installer; no genlight in or out)
- Origin: existing
- Date: 2026-11-05
- Reviewer: Claude (claude-opus-5-5), dartr-function-review v3.0.0
- Package commit: 407dfac (origin/dev)
- Datasets: none apply. Installers mocked (`install.packages`,
  `remotes::install_github`). Remote version reads ran live against CRAN and
  the 7 GitHub repos.
- Baseline: `tests/testthat/test-dartRverse_install.R`, unchanged from PR #43;
  33/33 pass, 0 warnings, 0 skips, with `NOT_CRAN=true`
- Earlier review: `dartRverse_install.md` in this directory (Luis, 2026-09-24,
  PR #43). This file is kept separate so that its approval record stays intact.

## Verdict

**Standards: Needs work** — the function changes the user's search path on
every call, and `branch` input is not checked against `rep`.

**Spec: Needs work** — a successful single-package install works and every
change from PR #43 still holds, but a failed install is reported as a new
version, `dartR.data` is blocked by a check it does not need, and the README
command for dev versions errors.

## Findings

**F1 [HIGH, confidence: high] — failed install is reported as success and leaves the package detached (principle: session state; no rule fits)**
`R/dartRverse_install.r:217-232` — the restart message prints whenever the
package was loaded, whether or not the install worked. The package is detached
before the install and not re-attached if the install fails.
Failure scenario (run, installer mocked to fail): when `install.packages()`
warns "package 'dartR.sim' is not available", the function prints "Restart R to
use the new version of dartR.sim" and returns `NULL`. No new version exists, and
`dartR.sim` is no longer on the search path. When `install_github()` fails on
the first of two packages, the second is not attempted, no summary prints, and
`dartR.sim` is also left detached.
Proposed change: check each install by comparing the installed package's build
stamp before and after. Print the restart message only after a success.
Re-attach a detached package after a failure. Try every requested package, then
stop with an error that names the ones that failed.

**F2 [HIGH, confidence: high] — every call attaches all 7 dartR packages (principle: AGENTS.md, no changes to the user's search path)**
`R/dartRverse_install.r:37` — `dartR_check()` runs before any branch or
validation, and it calls `require()` on each package.
Failure scenario (run): in a session with no dartR package attached,
`dartRverse::dartRverse_install("all")`, which only prints text, attaches 7
packages and takes 10.1 s. An install called this way starts by loading the
packages it is about to replace, so the restart advice from PR #43 always
applies. Loaded compiled code can also block replacing a package on Windows
(known R behaviour; not reproduced here).
Proposed change: stop calling `dartR_check()` from this function. Use the
existing `is_pkg_installed()` for install decisions and `requireNamespace()`,
which loads without attaching, in the version table.

**F3 [MEDIUM, confidence: high] — `branch` is ignored without `rep = "Github"` (principle: silent API trap; API1, proposed rule)**
`R/dartRverse_install.r:222-224` — `rep` defaults to `"CRAN"`, and the CRAN path
never reads `branch`.
Failure scenario (run, mocked): `dartRverse_install("dartR.sim", branch =
"dev")` calls `install.packages("dartR.sim")`. The user asked for dev (1.2.6 in
the live table) and gets CRAN (1.2.2). The only sign is the "from CRAN" line.
Proposed change: stop with an error when `branch` is supplied and `rep` resolves
to CRAN. Do not switch to GitHub automatically, because that reinterprets `rep`.

**F4 [MEDIUM, confidence: high] — Bioconductor check blocks `dartR.data` (DOC5, proposed rule; FS5)**
`R/dartRverse_install.r:5,208-215` — the code comment and `@description` say all
dartR packages depend on dartR.base. `dartR.data` does not on `main`, `beta` or
`dev`: its `Depends` and `Imports` name neither dartR.base nor a Bioconductor
package.
Failure scenario (run, mocked): with `SNPRelate` and `snpStats` missing,
`dartRverse_install("dartR.data")` stops with the BiocManager commands and
installs nothing, although `dartR.data` needs neither package.
Proposed change: skip the check when `dartR.data` is the only package requested.
Correct the comment and `@description`.

**F5 [MEDIUM, confidence: high] — README command for dev versions errors (DOC5, proposed rule)**
`README.Rmd:117`, `README.md:149` — the example uses `repository = "github"`, but
the argument is `rep`. R partial matching does not accept a longer name.
Failure scenario (run): `dartRverse_install("dartR.popgen", repository =
"github", branch = "dev")` stops with `unused argument (repository = "github")`.
Proposed change: use `rep = "Github"` in both files.

**F6 [MEDIUM, confidence: high] — GitHub instructions from `"all"` omit the core packages (DOC5, proposed rule)**
`R/dartRverse_install.r:183-187`, `README.md:125-129` — the block offered for
installing the latest GitHub versions lists the 5 add-ons only.
Failure scenario (read from code; not installed): a user follows the block with
`branch = 'dev'` and does not update `dartR.base` or `dartR.data`, so dev add-ons
(1.2.6) run on whichever core versions are installed.
Proposed change: add `dartR.data` and `dartR.base` as the first two commands in
the block, and update the rendered output in `README.md`.

**F7 [LOW, confidence: high] — version table shows a broken package as not installed (DOC5, proposed rule)**
`R/dartRverse_install.r:137-141` — `dc$failed` is ignored, although `.onAttach`
has reported these packages separately since PR #44.
Failure scenario (run, state mocked): an installed `dartR.sim` that fails to load
prints with a cross and `---`, so the user may reinstall when the cause is
elsewhere.
Proposed change: mark such packages "installed, fails to load" and show the
installed version.

**F8 [LOW, confidence: high] — version table crashes when an add-on loads and no core package does (FS5)**
`R/dartRverse_install.r:93,109` — `versions` is only created in the core branch.
Failure scenario (run, state mocked): with no core package and `dartR.sim`
present, the function stops with `object 'versions' not found`. Add-ons depend on
dartR.base, so this is rare today. Replacing the load check under F2 makes it
easier to reach, for example after dartR.base is removed.
Proposed change: start with `versions <- character(0)`.

**F9 [LOW, confidence: high] — `branch` and `package` accept unusable values (FS5)**
`R/dartRverse_install.r:198,226-229`.
Failure scenario (run, mocked): `branch = c("dev", "beta")` starts the install
loop with a vector `ref` and prints two "Installing" lines. `branch = NULL`
prints "from branch []" and installs the default branch. `package = character(0)`
does nothing and gives no message. `c("dartR.sim", "dartR.sim")` installs twice.
Proposed change: require `branch` to be one non-empty string, without limiting it
to main, beta and dev, so that feature branches keep working. Stop on an empty
`package`, and remove duplicates.

**F10 [LOW, confidence: medium] — failed version reads leave connections open (principle: resource cleanup; no rule fits)**
`R/dartRverse_install.r:75` — `readLines(url(...))` has nothing that closes the
connection when the read fails.
Failure scenario (run on the same expression, 3 reads of a missing branch): R
later prints "closing unused connection" 3 times. Reads that succeed left none
open. Because `gh_version()` catches every warning, such a warning arriving during
a good read could also turn that version into `?` (reasoned; not reproduced).
Proposed change: hold the connection in a variable and close it with `on.exit()`.

**F11 [LOW, confidence: high] — documentation gaps (DOC1; DOC7, proposed rule)**
`R/dartRverse_install.r:1-27` — no `@author`, `@name`, `@family` or `@details`.
The `@param branch` text also holds usage notes for other arguments. The
documentation does not say that `branch` needs `rep = "Github"`.
Failure scenario: a reader of `?dartRverse_install` cannot find the custodian or
learn from the `branch` entry that it depends on `rep`.
Proposed change: docs-only update of the roxygen block.

**F12 [INFO, confidence: medium] — a GitHub install changes only the named package**
Live DESCRIPTION files on `dev`: dartR.sim, popgen, captive, sexlinked and data
have no `Remotes` field, and their dartR.base dependency has no version limit.
Failure scenario (reasoned from the DESCRIPTION files; not installed):
`dartRverse_install("dartR.sim", rep = "Github", branch = "dev")` can leave dev
dartR.sim running on a CRAN dartR.base.
Proposed change: state this in the documentation (change 8). Whether to add
`Remotes` is a team decision for those packages, not this function.

**F13 [INFO, confidence: high] — status of the earlier review and manifest**
PR #43 behaviour holds in the baseline run and the probes for unknown names, bad
`rep`, several packages and `?` for failed reads. Earlier F9 is fixed on `dev`
(`R/zzz.R:65`). The fix is on `dev` only, so `main`, `beta` and the default
`install_github()` do not have it (GIT3). The manifest's `.onAttach` row still
says `pr-open` although #44 is merged.
Proposed change: none in this review.

## Proposed changes

1. Check each install result, print the restart message only after success,
   re-attach after failure, try every package, then stop naming the failures (F1).
   **Consequence: a failed CRAN install changes from a warning and `NULL` to an
   error, and a GitHub failure no longer skips the remaining packages.**
2. Stop attaching packages from this function; use a load-only check in the
   version table, mark packages that fail to load, and initialise `versions`
   (F2, F7, F8).
   **Consequence: `dartRverse::dartRverse_install()` no longer attaches dartR
   packages, so code relying on that must call `library()`. `library(dartRverse)`
   still attaches them.**
3. Validate `branch` and `package`: `branch` with CRAN errors, `branch` must be
   one non-empty string, empty `package` errors, duplicates are removed (F3, F9).
   **Consequence: `dartRverse_install("dartR.sim", branch = "dev")` and calls with
   NULL or vector `branch` or an empty `package` stop with an error instead of
   running.**
4. Skip the Bioconductor check when `dartR.data` is the only package requested,
   and correct the comment and `@description` (F4).
   **Consequence: on a machine without the Bioconductor packages, `dartR.data`
   installs instead of stopping.**
5. Add `dartR.data` and `dartR.base` to the GitHub block printed by `"all"` (F6).
   Printed text and `README.md` only.
6. Change `repository =` to `rep =` in `README.Rmd` and `README.md` (F5). Docs only.
7. Close connections used for version reads with `on.exit()` (F10).
8. Update the roxygen block, including the `branch` and `rep` dependency and the
   F12 note (F11, F12). Docs only.

## Coverage

- Standards walk: FS, DOC, VRB, DEP, STY — run. DAT, PLT — not applicable (no
  genlight in or out, no plots). FS2, FS3, FS9 and VRB2 do not fit this package
  (earlier F10).
- Baseline: `devtools::test(filter = "dartRverse_install")` — run, 33/33 pass.
- Probes: bad `package`, `rep` and `branch`, failed installs, session state,
  version-table states — run with mocked installers. A throwaway first library
  was empty after every run, so nothing was installed.
- Version table and DESCRIPTION reads: 7 repos x 3 branches — run live; all
  reads succeeded and every package has a CRAN version.
- Real failed install and real install in a clean library: SKIPPED — would
  install about 100 packages; failures were mocked.
- Windows lock on loaded compiled code (F2): SKIPPED — needs a real install.
- `R CMD check`: SKIPPED in Phase A — no code changed; required in Phase C.
- Known complaints: GitHub issues in this repo searched, none mention the
  function. dartR Google Group: SKIPPED — not searched in this pass.
- Sibling callers (API3): local `dartR.*` checkouts — no callers in `.R`, `.Rmd`
  or `.yml` files. dartr2shiny: SKIPPED — not checked out on this machine; the
  earlier review found no callers there.
- Earlier report's results for commit 07e831e: not rerun, except the baseline.

## Approval

| Change | Decision | By | Note |
|---|---|---|---|
| 1 | approved | Bernd | consequence approved explicitly |
| 2 | approved | Bernd | consequence approved explicitly |
| 3 | approved | Bernd | consequence approved explicitly |
| 4 | approved | Bernd | consequence approved explicitly |
| 5 | approved | Bernd | |
| 6 | approved | Bernd | |
| 7 | approved | Bernd | |
| 8 | approved | Bernd | |

## Outcome

- 1: a real `install.packages()` call against a dead repository stops with "Installation failed for dartR.sexlinked: package 'dartR.sexlinked' is not available". With a mocked GitHub failure, the second package is still tried, no restart message prints for the failed package, and the package is re-attached.
- 1, method changed during Phase C: F1 proposed comparing build stamps. Reinstalling an unchanged CRAN binary can keep the same stamp and look like a failure (reasoned; not run), so the code matches `install.packages()` failure warnings and catches errors instead. The approved consequence is unchanged. A failure whose warning text is not in the pattern would still count as a success.
- 2: in a session with nothing attached, `"all"` and the version table leave 0 dartR packages attached (was 7), and `"all"` no longer takes 10.1 s. `package_version_h()` also calls `require()`, so the table reads versions through `utils::packageVersion()` instead. `dartR_check()` and `.onAttach` are unchanged. New internal helper: `dartR_status()`.
- 3: `branch` with CRAN, a NULL, vector, empty, NA or numeric `branch`, and an empty `package` all stop and install nothing. `dev_luis` is still accepted, and duplicates install once.
- 4: with the Bioconductor packages mocked as missing, `dartR.data` installs and `c("dartR.data", "dartR.sim")` still stops.
- 5: `"all"` prints 7 GitHub commands, starting with `dartR.data` and `dartR.base`; `README.md` updated.
- 6: `README.Rmd` and `README.md` use `rep = "Github"`.
- 7: the connection count is unchanged after failed reads (mocked) and after a live table (3 before, 3 after).
- 8: roxygen updated; `devtools::document()` regenerated `man/dartRverse_install.Rd`; `NAMESPACE` and `DESCRIPTION` unchanged.
- Snapshot: all 13 baseline tests pass unedited, so there is no baseline diff. The 13 new tests were run before the fixes: 11 failed or errored, and the 2 that passed are guards against over-strict fixes ("unrelated warning", "feature branches"). After the fixes: 26 tests, 67 expectations, 0 failures.
- Full suite: `devtools::test()` 105 expectations, 0 failures, 0 errors, 0 skips, 0 warnings. A throwaway first library stayed empty in the scripted runs.
- `devtools::check(document = FALSE, args = "--no-manual")`: 0 errors, 0 warnings, 3 notes (untracked `.claude/`, untracked `AGENTS.md`, clock check).
- NEWS.md entry added under 1.2.6; version not bumped. Callers: none in local `dartR.*` checkouts; dartr2shiny not checked.
- Not run: a real successful install, the Windows file lock, and `remotes`' skip when the commit is unchanged. In that last case the restart message would still print (reasoned from the code).
- PR: #49.

```json
{
  "function": "dartRverse_install",
  "package": "dartRverse",
  "family": "io",
  "origin": "existing",
  "skill_version": "3.0.0",
  "commit": "407dfac",
  "verdict_standards": "needs_work",
  "verdict_spec": "needs_work",
  "findings": [
    {"id": "F1", "severity": "HIGH", "confidence": "high", "rule": "none: session state", "status": "approved", "change": 1},
    {"id": "F2", "severity": "HIGH", "confidence": "high", "rule": "none: AGENTS.md search path", "status": "approved", "change": 2},
    {"id": "F3", "severity": "MEDIUM", "confidence": "high", "rule": "API1", "status": "approved", "change": 3},
    {"id": "F4", "severity": "MEDIUM", "confidence": "high", "rule": "DOC5", "status": "approved", "change": 4},
    {"id": "F5", "severity": "MEDIUM", "confidence": "high", "rule": "DOC5", "status": "approved", "change": 6},
    {"id": "F6", "severity": "MEDIUM", "confidence": "high", "rule": "DOC5", "status": "approved", "change": 5},
    {"id": "F7", "severity": "LOW", "confidence": "high", "rule": "DOC5", "status": "approved", "change": 2},
    {"id": "F8", "severity": "LOW", "confidence": "high", "rule": "FS5", "status": "approved", "change": 2},
    {"id": "F9", "severity": "LOW", "confidence": "high", "rule": "FS5", "status": "approved", "change": 3},
    {"id": "F10", "severity": "LOW", "confidence": "medium", "rule": "none: resource cleanup", "status": "approved", "change": 7},
    {"id": "F11", "severity": "LOW", "confidence": "high", "rule": "DOC1", "status": "approved", "change": 8},
    {"id": "F12", "severity": "INFO", "confidence": "medium", "rule": "none: outside scope", "status": "approved", "change": 8},
    {"id": "F13", "severity": "INFO", "confidence": "high", "rule": "GIT3", "status": "no_change", "change": null}
  ],
  "coverage_skipped": [
    "real failed install and clean-library install: mocked instead",
    "Windows lock on loaded compiled code: needs a real install",
    "R CMD check: no code changed in Phase A",
    "dartR Google Group: not searched",
    "dartr2shiny caller grep: not checked out on this machine"
  ],
  "status": "pr-open",
  "pr": 49
}
```
