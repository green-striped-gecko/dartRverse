# Review: .onAttach (dartRverse)

- Family mode: report (startup message; also attaches the suite)
- Scope: `.onAttach()` and the helpers it calls — `dartR_check()`,
  `inform_startup()` (`R/zzz.R`), `dartRverse_attach_message()`,
  `package_version_h()`, `highlight_version()` (`R/attach.R`)
- Date: 2026-09-24
- Reviewer: Claude (claude-opus-5-5), dartr-function-review v2.0.0
- Package commit: 47a2652 (origin/dev, after #41; #43 still open)
- Datasets: none apply; installed state simulated by mocking `require()`
  and `dartR_check()`
- Baseline: `tests/testthat/test-onAttach.R` (captured pre-review; 14
  passes)

## Verdict

**Standards: Needs work** — the attach sequence is deliberate and stays
untouched (the Feb 2026 commits 8a52482 and b52ff43 tuned it to avoid a
`glMean` conflict), but load errors are suppressed and the startup advice
is incomplete.

**Spec: Needs work** — with every package installed the message is
correct. When something is wrong, which is when a user reads it most
closely, it names the wrong cause or leaves a package out.

## Findings

**F1 [HIGH, confidence: high] — load failures reported as "not installed" (VRB3, principle: do not hide errors)**
`R/zzz.R:14-28` — `dartR_check()` wraps `require()` in
`suppressMessages(suppressWarnings(...))`. `require()` returns FALSE both
when a package is absent and when it is installed but fails to load, and
the warning that says which is discarded.
Failure scenario (run, `require()` mocked to fail with a load error for
dartR.popgen): the banner lists `✖ dartR.popgen` under "Not [yet]
installed dartRverse packages" and the error text never appears. After an
R upgrade, when a Bioconductor import or a newer dartR.base is missing,
users are told to install a package they already have. Reinstalling it
doesn't help, because the real cause is hidden. If dartR.base itself
fails, the "core packages are not installed yet" advice fires for the
same wrong reason.
Proposed change: keep the `require()` calls and their order; capture the
load-failure warning instead of discarding it; list installed packages
that failed to load under their own header ("Installed but failed to
load") with the first line of the error, and tell the user to run
`library(<package>)` to see the full message.

**F2 [MEDIUM, confidence: high] — only one missing core package goes unlisted (DOC5, proposed rule)**
`R/zzz.R:30-35` — missing core packages are added to the "not installed"
list only when both are missing (`if (length(core) == 0)`).
Failure scenario (run, dartR.base mocked as missing):
`dartR_check()` returns `core = "dartR.data"` and dartR.base is in no
list. It's the usual fresh-install failure: `install.packages("dartR.base")`
installs its dependency dartR.data, then fails on the Bioconductor
imports. The banner shows `✔ dartR.data` under core and never names
dartR.base.
Proposed change: always add missing core packages to the "not installed"
list.

**F3 [MEDIUM, confidence: high] — startup advice omits snpStats (DOC5, proposed rule)**
`R/zzz.R:59` — the advice lists `BiocManager::install('SNPRelate')` and
then `dartRverse_install('dartR.base', rep='CRAN')`. dartR.base also
imports snpStats (Bioconductor). (F9 in the `dartRverse_install` review.)
Failure scenario (run, core mocked as missing): the message contains no
`snpStats`. A user following it gets "dependency 'snpStats' is not
available" or, once #43 is merged, a stop asking for snpStats.
Proposed change: add `BiocManager::install('snpStats')` to the advice.

**F4 [LOW, confidence: high] — `dartRverse.quiet` does not silence the banner (DOC5, proposed rule)**
`R/zzz.R:40-47,68-76` — the option is checked in `inform_startup()`, but
the welcome banner calls `packageStartupMessage()` directly. The option is
undocumented.
Failure scenario (run): with `options(dartRverse.quiet = TRUE)`, loading
still prints the 3-line banner; only the package sections disappear.
Proposed change: send the banner through `inform_startup()`; document the
option in the package help (`R/dartRverse.R`).

**F5 [INFO, confidence: high] — load time**
`library(dartRverse)` takes 4.1 s here with all 7 packages installed,
because it attaches the whole suite. That is intended.
Proposed change: none.

**F6 [INFO, confidence: high] — FS conventions do not fit this package (rule scope)**
As in the previous two reviews.
Proposed change: none.

## Proposed changes

1. Capture load failures and list them under "Installed but failed to
   load" with the first line of the error; advise `library(<package>)`.
   The `require()` calls and their order are unchanged (F1).
2. Always list missing core packages as not installed (F2).
3. Add `BiocManager::install('snpStats')` to the startup advice (F3).
4. Banner respects `dartRverse.quiet`; document the option (F4).
   **Consequence: users who set `dartRverse.quiet = TRUE` no longer see
   the welcome banner.**

## Coverage

- Standards walk: FS, DOC, VRB, DEP, STY — run. DAT, PLT — not applicable.
- All installed; quiet option; broken add-on; core missing; one core
  missing — run by mocking `require()` / `dartR_check()`.
- Real broken installation (a package failing to load for real): SKIPPED —
  would require breaking the R library shared with a running analysis.
- Load order / `glMean` masking: not changed; not re-tested.
- Load time — run (4.1 s).
- Known complaints (dartR Google Group / GitHub issues): SKIPPED — not
  searched in this pass.

## Approval

| Change | Decision | By | Note |
|---|---|---|---|
| 1 | approved | Luis | |
| 2 | approved | Luis | |
| 3 | approved | Luis | |
| 4 | approved | Luis | consequence (banner hidden when quiet) approved explicitly |

## Outcome

- 1: with `require()` mocked to fail for dartR.popgen, the banner shows "Installed but failed to load / ✖ dartR.popgen <error>" and "Run library(dartR.popgen) to see the full error." A core package that fails to load no longer triggers the "not installed yet" advice (the advice now keys on packages that are really missing). `dartR_check()` gains a `failed` element; `nip` still includes failed packages, so the `dartRverse_install()` version table is unchanged.
- 2: with dartR.base mocked as absent, `dartR_check()$nip` is `"dartR.base"`.
- 3: the advice includes `BiocManager::install('snpStats')`.
- 4: with `dartRverse.quiet = TRUE`, `.onAttach()` emits 0 messages; option documented in `?dartRverse`.
- `require()` calls and attach order unchanged (core, then add-ons, same `lib.loc`).
- Snapshot: 17/17 pass, 0 warnings. Diffs from baseline map to changes 1, 2, 3, 4. No unexplained diff.
- `R CMD check --no-manual`: 0 errors, 0 warnings, 3 notes (untracked scaffold files; clock; the `NEWS.md` heading that #43 fixes).
- NEWS entry added. Callers of `dartR_check()`: `dartRverse_install()` only; none in siblings or dartr2shiny.
- PR: pending.

```json
{
  "function": ".onAttach",
  "package": "dartRverse",
  "family": "report",
  "skill_version": "2.0.0",
  "commit": "47a2652",
  "verdict_standards": "needs_work",
  "verdict_spec": "needs_work",
  "findings": [
    {"id": "F1", "severity": "HIGH", "confidence": "high", "rule": "VRB3", "status": "approved", "change": 1},
    {"id": "F2", "severity": "MEDIUM", "confidence": "high", "rule": "DOC5", "status": "approved", "change": 2},
    {"id": "F3", "severity": "MEDIUM", "confidence": "high", "rule": "DOC5", "status": "approved", "change": 3},
    {"id": "F4", "severity": "LOW", "confidence": "high", "rule": "DOC5", "status": "approved", "change": 4},
    {"id": "F5", "severity": "INFO", "confidence": "high", "rule": "none: performance note", "status": "no_change", "change": null},
    {"id": "F6", "severity": "INFO", "confidence": "high", "rule": "FS2", "status": "no_change", "change": null}
  ],
  "coverage_skipped": [
    "real broken installation: shared R library in use",
    "Google Group / GitHub issues: not searched"
  ],
  "status": "awaiting-approval",
  "pr": null
}
```
