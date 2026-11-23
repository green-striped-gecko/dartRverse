# Review: gl.download.binary (dartRverse)

- Family mode: io
- Date: 2026-09-24
- Reviewer: Claude (claude-opus-5-5), dartr-function-review v2.0.0
- Package commit: 07e831e (dev, synced to origin/dev)
- Datasets: none apply (the function takes no genetic data); probed against
  the live `binaries/` folder on GitHub (`main`) and the 38 local zips
- Baseline: `tests/testthat/test-gl.download.binary.R` (captured pre-review;
  12 passes with `NOT_CRAN=true`, network required)

## Verdict

**Standards: Needs work** — the body is short and readable, but it has no
input validation, an unused dependency, and documentation that disagrees
with the code in five places.

**Spec: Needs work** — downloads by lower-case name work on all three OSes
and return a valid path; the names the documentation tells users to type
fail, and listing mode ignores `branch` and crashes when the GitHub API
refuses the request.

## Findings

**F1 [HIGH, confidence: high] — documented names fail (DOC5, proposed rule)**
`R/gl.download.binary.r:5,96` — `@param software` lists `"NeEstimator"`,
`"Stairway2"` and `"Gone"`, but every zip on GitHub is lower case and
`raw.githubusercontent.com` is case-sensitive. `software` is pasted into the
URL unchanged.
Failure scenario: `gl.download.binary("NeEstimator", os = "linux")` stops
with "Binary for NeEstimator on linux not available" although
`neestimator_linux.zip` exists (captured in the baseline). The list also
names 4 of the 13 available programs.
Proposed change: lower-case `software` before building the file name;
list all 13 names in `@param software`.

**F2 [MEDIUM, confidence: high] — listing mode ignores `branch` (DOC5, proposed rule)**
`R/gl.download.binary.r:58` — the GitHub API URL hard-codes `trees/dev`,
while downloads use `branch` (default `"main"`).
Failure scenario: a binary added to `dev` but not yet merged to `main`
shows a tick in the table; `gl.download.binary("<it>")` then errors
"not available". Latent today (both branches hold the same 38 zips); it
recurs every time a binary lands on `dev` first, which is the branch model.
Proposed change: build the API URL from `branch`.

**F3 [MEDIUM, confidence: high] — listing mode crashes on API failure (FS5)**
`R/gl.download.binary.r:58-83` — the response of `GET()` is not checked.
Unauthenticated GitHub API calls are limited to 60 per hour per IP; offline
use or a shared campus IP hits this.
Failure scenario (reproduced with a mocked rate-limit body): the function
prints "Available binaries:" and then stops with
`replacement has length zero`, which tells the user nothing.
Proposed change: check `httr::status_code()` and the presence of `$tree`;
stop with a message naming the cause and the GitHub folder URL.

**F4 [MEDIUM, confidence: medium] — every download failure reads as "not available" (FS5, VRB3)**
`R/gl.download.binary.r:101-107` — `tryCatch(..., error = function(e) 1)`
maps any error (no network, proxy, TLS failure, 404) to "Binary for X on Y
not available". The raw `download.file()` warnings ("HTTP status was '404
Not Found'", "downloaded length 0") also print at `verbose = 0`.
Failure scenario: an offline user, or one behind a proxy, is told the
binary does not exist and goes looking for it elsewhere. (Offline case
reasoned from the code; the 404 case was run.)
Proposed change: keep the "not available" message for HTTP 404 only;
otherwise report the underlying error text; suppress the raw warnings and
fold their content into the single `stop()` message.

**F5 [LOW, confidence: high] — no validation of `software` (FS5)**
`R/gl.download.binary.r:96` — a vector is accepted and pasted element-wise.
Failure scenario: `gl.download.binary(c("gone", "plink"), os = "linux")`
stops with two concatenated "not available" messages even though both zips
exist (run).
Proposed change: require a single character string and say so in the error.

**F6 [LOW, confidence: high] — documentation disagrees with the code (DOC1, DOC3, DOC5)**
`R/gl.download.binary.r:1-15` — (a) `verbose` says "Default is zero"; the
default is 2, and only 0 versus non-zero has any effect. (b) `@return` says
NULL; download mode returns `out.dir/software` invisibly. (c) The example
is the bare symbol `gl.download.binary`, and the `\donttest{}` block calls
`dartRverse_install()`. (d) `branch` and `out.dir` lack
`[default ...]` tags. (e) Typos: "seemlessly", "explicitely", "This
functions supports".
Failure scenario: a user reading `?gl.download.binary` cannot learn what
the function returns, which names to pass, or see a working call.
Proposed change: docs-only rewrite of the roxygen block; example lists
binaries and downloads one into `tempdir()` inside `\donttest{}`.

**F7 [LOW, confidence: medium] — unused RCurl dependency (DEP2)**
`R/gl.download.binary.r:19`, `DESCRIPTION` Imports — `url.exists` is no
longer called since c98a712 replaced it with `tryCatch()`; nothing else in
`R/` uses RCurl.
Failure scenario: on Linux, installing `dartRverse` still compiles RCurl,
which fails without the libcurl development headers — a common install
blocker for a package whose only job is installing the suite.
Proposed change: remove the `@importFrom RCurl` line and RCurl from Imports.

**F8 [INFO, confidence: high] — FS2/FS3/FS9/VRB2 do not fit this package (rule scope)**
The entry-point idioms (`gl.check.verbosity`, `utils.flag.start`,
`report()`) live in dartR.base, which `dartRverse` cannot import because it
installs dartR.base. This is a gap in the conventions catalogue, not a
defect in the code: the catalogue should exempt the umbrella package.
Proposed change: none here; note to the skill maintainer.

**F9 [INFO, confidence: medium] — mac binaries are mixed-architecture (outside function scope)**
`binaries/*_mac.zip` — arm64-only: `ms`, `eems`, `epos`; x86_64-only:
`plink`, `structure`, `neestimator`, `gone`, `colony`, `popcluster`,
`faststructure`. `emibd9/EM_IBD_P` is arm64 but links to
`/opt/homebrew/opt/gcc/lib/gcc/current/libgfortran.5.dylib`; the bundled
dylibs are never used (their load paths are absolute, not `@loader_path`).
Failure scenario: `gl.run.epos` fails on Intel Macs; x86_64 tools fail on
Apple Silicon without Rosetta; EMIBD9 fails on any Mac without Homebrew
gcc (not reproduced here: this machine has Homebrew gcc).
Proposed change: none in this function; open a separate issue for the
binaries.

## Proposed changes

1. Lower-case `software` before building the zip name, and list all 13
   programs in `@param software` (F1).
2. Listing mode queries the tree of `branch` instead of `dev` (F2).
   **Consequence: with the default `branch = "main"`, the table now shows
   what is on `main`, not `dev`.**
3. Listing mode checks the API response and stops with a clear message on
   failure (F3).
4. Download failures: "not available" only for HTTP 404; other errors
   reported with their cause; raw `download.file()` warnings no longer
   printed (F4).
5. Validate that `software` is a single character string (F5).
6. Rewrite the roxygen block: `verbose` default and levels, `@return`,
   working example, `[default]` tags, typos (F6). Docs only.
7. Remove RCurl from `@importFrom` and from DESCRIPTION Imports (F7).

## Coverage

- Standards walk: FS, DOC, VRB, DEP, STY — run. DAT, PLT — not applicable
  (no genlight in or out, no plots).
- Spec: behaviour versus roxygen — run with `devtools::load_all()` on
  R 4.4.2 (`/usr/local/bin/Rscript`; the Homebrew R 4.6.1 first on `PATH`
  lacks devtools).
- Downloads on windows/mac/linux (`gone`), partial `os` matching, 404
  path, vector input, `verbose = 0` versus 2 — run.
- Listing mode: live call (baseline) and mocked rate-limit body — run.
- Offline failure path (F4): SKIPPED — not simulated; reasoned from code.
- Zip contents for all 38 zips (top folder equals `software`, so the
  returned path exists) — run.
- Mac binary architectures — run; execution on Intel Mac or a Mac without
  Homebrew gcc SKIPPED — no such machine available.
- Windows `Sys.chmod` skip and Windows download — logic read, download of
  the windows zip run from macOS; execution on Windows SKIPPED.
- Known complaints (dartR Google Group / GitHub issues): SKIPPED — not
  searched in this pass.
- Sibling callers (API3): `dartR.popgen` (`gl.TajimasD`, `gl.run.epos`,
  `gl.run.stairway2`) and `dartR.base` (`gl2genepop`) mention the function
  in docs or messages with lower-case names; no signature change proposed.

## Approval

| Change | Decision | By | Note |
|---|---|---|---|
| 1 | approved | Luis | |
| 2 | approved | Luis | consequence (default table shows `main`) approved explicitly |
| 3 | approved | Luis | |
| 4 | approved | Luis | |
| 5 | approved | Luis | |
| 6 | approved | Luis | |
| 7 | approved | Luis | |

## Outcome

- 1: `NeEstimator` on linux now downloads to `out.dir/neestimator` (test "mixed-case names are lower-cased and download").
- 2: listing requests `git/trees/main` with `branch = "main"` (mocked test); live table on `main` lists 13 programs.
- 3: mocked rate-limit body stops with "Github did not return the list of binaries (API rate limit exceeded)".
- 4: 404 stops with "not available" and no warnings; mocked DNS failure stops with "Download of ... failed (Could not resolve host ...)".
- 5: vector and numeric `software` stop with "single character string".
- 6: roxygen rewritten; `devtools::document()` regenerated `man/gl.download.binary.Rd` and `NAMESPACE`.
- 7: RCurl removed from `DESCRIPTION` Imports and `NAMESPACE`.
- Snapshot: 19/19 pass. Diffs from baseline: the mixed-case case (change 1) and the 4 raw `download.file()` warnings no longer printed (change 4). No unexplained diff.
- `R CMD check --no-manual`: 0 errors, 0 warnings, 2 notes (untracked local scaffold files; clock check).
- End to end at `verbose = 3`: listing on `main` and `gl.download.binary("Stairway2")` on mac ran.
- NEWS.md created (no NEWS file existed). Callers: no calls in dartr2shiny; sibling mentions use lower-case names.
- PR: #41.

```json
{
  "function": "gl.download.binary",
  "package": "dartRverse",
  "family": "io",
  "skill_version": "2.0.0",
  "commit": "07e831e",
  "verdict_standards": "needs_work",
  "verdict_spec": "needs_work",
  "findings": [
    {"id": "F1", "severity": "HIGH", "confidence": "high", "rule": "DOC5", "status": "approved", "change": 1},
    {"id": "F2", "severity": "MEDIUM", "confidence": "high", "rule": "DOC5", "status": "approved", "change": 2},
    {"id": "F3", "severity": "MEDIUM", "confidence": "high", "rule": "FS5", "status": "approved", "change": 3},
    {"id": "F4", "severity": "MEDIUM", "confidence": "medium", "rule": "FS5", "status": "approved", "change": 4},
    {"id": "F5", "severity": "LOW", "confidence": "high", "rule": "FS5", "status": "approved", "change": 5},
    {"id": "F6", "severity": "LOW", "confidence": "high", "rule": "DOC1", "status": "approved", "change": 6},
    {"id": "F7", "severity": "LOW", "confidence": "medium", "rule": "DEP2", "status": "approved", "change": 7},
    {"id": "F8", "severity": "INFO", "confidence": "high", "rule": "FS2", "status": "no_change", "change": null},
    {"id": "F9", "severity": "INFO", "confidence": "medium", "rule": "none: binary packaging", "status": "no_change", "change": null}
  ],
  "coverage_skipped": [
    "F4 offline path: not simulated",
    "Intel Mac / no-Homebrew execution: no machine",
    "Windows execution: no machine",
    "Google Group / GitHub issues: not searched"
  ],
  "status": "done",
  "pr": 41
}
```
