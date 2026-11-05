# Review: dartRverse_install (dartRverse), third pass: install and update redesign

- Family mode: io (installer; no genlight in or out)
- Origin: existing
- Date: 2026-11-06
- Reviewer: Claude (claude-opus-5-5), dartr-function-review v3.0.0
- Package commit: 7c956f2 (origin/dev), branch `improve-install`, uncommitted at
  the time of writing
- Datasets: `testset.gl` and all datasets in `dartR.data`, only to confirm that
  packages still work after a swap
- Earlier reviews: `dartRverse_install.md` and `dartRverse_install_review2.md`
  in this directory. This file is separate so that their approval records stay
  intact.

## Request

Bernd asked for one function, `dartRverse_install()`, that:

1. updates packages that are already loaded, without restarting R;
2. shows a version table with clickable install and version links;
3. has typed shortcuts for all packages or one package, to CRAN or a branch;
4. makes sure Bioconductor packages install and load;
5. no longer prints commands for `dartRverse_install("all")`.

## Verdict

**Standards: Pass.** No exported name, argument, order or default changed.

**Spec: Pass on Windows with R 4.4.1**, for everything run below. Linux, macOS, a
real click in RStudio and a real third-party file lock were not run.

## Findings from real runs

| ID | Severity | Finding | Status |
|---|---|---|---|
| F1 | HIGH | Replacing a package in the session crashed R (segfault) or gave `internal error in R_decompress1` | fixed |
| F2 | HIGH | A failed package download was reported as a successful install | fixed |
| F3 | MEDIUM | Downloads fail now and then, and R's 60 second default is short for the larger packages | fixed |
| F4 | MEDIUM | `remotes` chose Bioconductor 3.18 for R 4.4.1, where BiocManager says 3.20 | fixed |
| F5 | LOW | `remotes` printed warnings about Bioconductor repositories dartR does not use | fixed |
| F6 | INFO | `validObject(testset.gl)` fails in a fresh session: `slots in class definition but not in object: "fbm"` | not changed, outside this function |

### F1: the crash

R reads a package's functions and datasets when they are first used, by position
in the package's files. Copies of the old package can outlive `unloadNamespace()`.
If one is read after the files were replaced, R gets the wrong bytes from the new
file.

The smallest case needs only `dartR.base`, replaced in place from dev to CRAN, with
dartRverse not loaded. So the cause is in R's handling of replaced packages, and
any in-session update has to deal with it.

| Reading everything before unloading | Attached with `library()` | Loaded only |
|---|---|---|
| no | 3 crashes in 3 runs | 3 of 3 finish, 3 decompress errors each |
| yes | 0 crashes in 3 runs | 3 of 3 finish, no decompress errors |

Clearing R's lazy-load cache did not help (one run). Which package sets crash
varies: all 7 packages loaded in dependency order did not crash, while `dartR.base`
alone and the restore order did. A run that passes without the fix therefore shows
little.

Fix: `dartR_force_promises()` reads every object in the affected namespaces, and
their lazy data, before anything is unloaded. It also runs when unloading is
blocked, because a package that stays loaded has its files replaced as well. This
briefly uses more memory: the compressed `dartR.data` file is 4.6 MB.

## Results

| Run | Result |
|---|---|
| `devtools::test()` | 64 tests, 167 expectations, 0 failures, 0 errors, 0 warnings, 0 skips; guard library stayed empty |
| `devtools::check(document = FALSE, args = "--no-manual")` | 0 errors, 0 warnings, 1 note (clock check) |
| End to end, real installs, final code | 29 of 29 checks; 0 warnings; 0 decompress errors |
| New user, clean copy of R, final code | 7 dartR packages and 4 named Bioconductor packages load; 5.7 min; 0 warnings; 0 errors |

The end-to-end run started from an older `dartR.base` and updated it from CRAN,
updated `dartR.sexlinked` from GitHub dev, and then switched all 7 packages
between dev and CRAN four times in one session. After each switch it checked the
version, the search path, an object created before the switches and every dataset.

The new-user run used a copy of R with only its 29 base and recommended packages.
It installed dartRverse, ran `library(dartRverse)` and `dartRverse_install("all")`.
The function installed SNPRelate, snpStats, gdsfmt, BiocGenerics, zlibbioc and LEA
first, and `gl.report.callrate()` then ran on `testset.gl`.

Other behaviour seen in real runs:

- During an overnight loss of connection, R did not crash and the session stayed
  usable. Installs stopped with "Nothing was installed" and the table showed `?`.
- When a download failed for one package, the other six installed, the session was
  restored and the error named the package. This was before the retry was added.

## Changes

- `R/install_helpers.r` (new, internal); `R/dartRverse_install.r` rewritten with
  the same signature; `R/zzz.R` startup advice.
- `DESCRIPTION`: `BiocManager` added to Imports, `cli (>= 3.4.0)`.
- `NEWS.md`, `README.Rmd`, `README.md`, `man/dartRverse_install.Rd`.
- `tests/testthat/test-dartRverse_install.R`, `test-onAttach.R`.

Changes from the approved plan:

- Only the `BioCsoft` and `CRAN` repositories are used, which avoids 404 warnings.
- Added after testing: F1 to F5.

## Coverage

- Not run: Linux and macOS, where Bioconductor packages can need system libraries.
- Not run: a real click in RStudio. Link text and code were inspected with links
  forced on.
- Not run: a real Windows lock from a loaded third-party package, and a real outside
  package importing a dartR package. Both restart paths are mocked.
- Not run: the retry against a real failing server. It is mocked; the failures that
  led to it were real.
- F1 has no automated test that replaces real files, because that needs real
  installs. The unit tests check that objects are read before unloading; the end-to-end
  run above is the evidence for the crash itself, and is not part of the test suite.
- dartR Google Group not searched for the Bioconductor reports; no GitHub issues
  mention them, so the reported failures were not reproduced from a user's report.

## Approval

The redesign plan was approved by Bernd through plan mode on 2026-11-05. F1 to F5
came up during verification and are reported here for review with the PR.

## Outcome

PR: #53, into `dev`.

```json
{
  "function": "dartRverse_install",
  "package": "dartRverse",
  "family": "io",
  "origin": "existing",
  "skill_version": "3.0.0",
  "commit": "7c956f2",
  "verdict_standards": "pass",
  "verdict_spec": "pass",
  "findings": [
    {"id": "F1", "severity": "HIGH", "confidence": "high", "rule": "none: session state", "status": "fixed", "change": null},
    {"id": "F2", "severity": "HIGH", "confidence": "high", "rule": "none: silent failure", "status": "fixed", "change": null},
    {"id": "F3", "severity": "MEDIUM", "confidence": "high", "rule": "none: reliability", "status": "fixed", "change": null},
    {"id": "F4", "severity": "MEDIUM", "confidence": "high", "rule": "none: dependency resolution", "status": "fixed", "change": null},
    {"id": "F5", "severity": "LOW", "confidence": "high", "rule": "none: messages", "status": "fixed", "change": null},
    {"id": "F6", "severity": "INFO", "confidence": "high", "rule": "none: outside scope", "status": "no_change", "change": null}
  ],
  "coverage_skipped": [
    "Linux and macOS",
    "real click in RStudio",
    "real third-party file lock and real outside importer: mocked",
    "retry against a real failing server: mocked",
    "dartR Google Group: not searched"
  ],
  "status": "pr-open",
  "pr": 53
}
```
