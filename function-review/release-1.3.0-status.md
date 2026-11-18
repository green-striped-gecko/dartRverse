# dartRverse 1.3.0 release: status (19 Nov 2026)

Hand-over to pick up the release from another computer. Older details of the
FBM work: `dartR.base/function-review/release-1.3.0-status.md`,
`fbm-step2-plan.md`, `fbm-step3-status.md`.

## Where the release stands

**19 Nov 2026 — CRAN submissions, one package at a time:**

| Package | Version | CRAN |
|---|---|---|
| dartR.data | 1.2.7 | accepted |
| dartR.base | 1.3.0 | accepted |
| dartR.popgen | 1.3.0 | accepted |
| dartR.sim | 1.3.0 | returned by pre-test, fixed, to resubmit (19 Nov) |
| dartR.spatial | 1.3.0 | next (fixed today, see below) |
| dartR.captive | 1.3.0 | waiting |
| dartR.sexlinked | 1.3.0 | waiting |
| dartRverse | 1.3.0 | last |

Submit the next one only after the previous one is accepted. All tarballs
in `D:/Bernd/R/dartRs/cran` were compared file by file with GitHub `beta`
on 19 Nov and match it (only the fields `R CMD build` adds to DESCRIPTION
differ). dartR.spatial was rebuilt after today's fix (19 Nov, 10:18).

**main (19 Nov):** `beta` merged into `main` for the three accepted packages;
`main` now has the same content as `beta`: dartR.data 8776ec0, dartR.base
eae477d, dartR.popgen 55e3543. Do the same for each further package after
CRAN accepts it.

**dartR.sim resubmission (19 Nov, dev 0922c41, beta 12fe5c8):** the CRAN
pre-test (Windows R-devel) gave 2 NOTEs: the `gl.sim.WF.run()` call took
22 s in the examples, and "PVAs" in DESCRIPTION was flagged as possibly
misspelled. Fixes: that call is in `\donttest{}` in the examples of
`gl.sim.WF.run()` and `gl.sim.WF.table()` (the latter ran it too);
DESCRIPTION now says "fully fledged population viability analyses".
`R CMD check --as-cran` of the clean build: 0 errors, 477 s, examples 14 s
OK, vignettes 152 s (only the local dplyr warning and clock note).
Tarball `cran/dartR.sim_1.3.0.tar.gz` rebuilt (19 Nov, 10:51), installed.
Luis is the CRAN maintainer: he uploads and confirms the resubmission.

**dartR.spatial fix (19 Nov, commit 2f1167e, beta f2eec7f):** `reemsplots2`
(GitHub only) removed from `Suggests` and the `Remotes` field deleted, as
CRAN accepts neither. `gl.run.eems()` looks up
`reemsplots2::make_eems_plots()` at run time after its `requireNamespace()`
check and still tells users to install it from GitHub. gl.run.eems tests:
14 pass, 0 fail (3 skipped, need the EEMS program). `R CMD check --as-cran`
of the clean build: 0 errors, 353 s, incoming-feasibility NOTE gone (only
the local dplyr warning and clock note). Installed on the UC PC.

Earlier notes (18 Nov):

- **dartR.base 1.3.0 resubmitted to CRAN** (or ready to be resubmitted: use
  the tarball below). The first upload was rejected automatically only for
  the check time on Windows R-devel (21 min > 10 min; tests 15 min). Windows
  and Debian pre-tests were otherwise `Status: OK`.
- Fix: the 40 slowest test files call `skip_on_cran()` (commit e580622).
  Local `R CMD check --as-cran` of the tarball: 0 errors; tests 148 s
  (was ~12 min); total about 8 min without the `\donttest` examples. Only
  local issues: dplyr built under R 4.4.3 (warning), clock note, and
  `gl.propShared` example 6.4 s elapsed (0.2 s CPU).
- Tarballs in `D:/Bernd/R/dartRs/cran` (local folder, not in git):
  `*_1.3.0.tar.gz` for base, popgen, sim, spatial, captive, sexlinked,
  dartRverse; `dartR.data_1.2.7.tar.gz` unchanged (data stays 1.2.7). The
  dartR.base tarball was rebuilt at 16:06 with the test skips. The others
  were built from `beta` (git archive, `R CMD build`, no warnings).

## Next steps

1. Wait for CRAN to accept dartR.base 1.3.0.
2. Then submit, in dependency order: dartR.popgen, dartR.spatial,
   dartR.sim, dartR.captive, dartR.sexlinked, dartRverse. All require
   `dartR.base (>= 1.3.0)`.
3. **Deadline:** dartR.sim on CRAN (1.2.2) fails its `gl.sim.ind` example
   (dartR.data 1.2.7's `testset.gl` has 3 all-NA loci); CRAN wants it fixed
   before **2026-12-06**. dartR.sim 1.3.0 fixes it.
4. Done (18 Nov, evening): the slowest test files of popgen, sim, spatial,
   captive and sexlinked call `skip_on_cran()` too (pushed to dev and
   merged into beta). Local `R CMD check --as-cran` of clean builds, all
   0 errors (local dplyr warning and clock note only): sexlinked 165 s,
   spatial 316 s, captive 325 s, popgen 418 s, sim 480 s (vignettes 143 s).
   Their tarballs in `cran/` were rebuilt from these commits (16:35).
   **Fix before submitting:**
   - dartR.spatial `Remotes`/`reemsplots2`: done 19 Nov (see above).
   - dartR.sim slow example: done 19 Nov (see above).
5. After acceptance: merge `beta` into `main` (main = CRAN; never earlier).

## Reverse dependencies (CRAN versions vs dartR.base 1.3.0)

R CMD check of the CRAN versions against dartR.base 1.3.0: dartRverse 1.0.6
OK; popgen, spatial, captive, sexlinked 1.2.2 only the local dplyr warning;
dartR.sim 1.2.2 the known `gl.sim.ind` example error (already on its CRAN
check page, not caused by dartR.base). `gl.He`, `gl.Ho`, `gl.propShared`
were moved back to dartR.base so the CRAN add-ons keep working.

## Branches (origin, 19 Nov 2026)

`beta` has the same content as `dev` in every repo (dartRverse dev only adds
this document). `main` = `beta` for data, base and popgen (merged 19 Nov after
CRAN acceptance); the others are merged after their acceptance (dartRverse main only gained the coancestry zips).

| Package | dev | beta | Version |
|---|---|---|---|
| dartR.base | e580622 | 5c88139 | 1.3.0 |
| dartR.popgen | 9cb03bb | 02730f7 | 1.3.0 |
| dartR.sim | 0922c41 | 12fe5c8 | 1.3.0 |
| dartR.spatial | 2f1167e | f2eec7f | 1.3.0 |
| dartR.captive | d1473de | 2578fd8 | 1.3.0 |
| dartR.sexlinked | 29a914f | 5d90b12 | 1.3.0 |
| dartR.data | c77c859 | 5c604db | 1.2.7 |
| dartRverse | (latest) | 3598e40 | 1.3.0 |

All `dev_fbm` branches are deleted (they were fully merged).

## Done today (18 Nov)

- All eight packages: `devtools::check()` 0 errors (only local warning and
  notes). Winbuilder OK for dartR.base and dartRverse.
- dartR.base bug fixes (d3bad79), from Luis's FBM review (14 Nov):
  subsetting with a repeated locus kept NA only in the first copy in memory
  (adegenet SNPbin defect; FBM was correct); `gl.read.PLINK` now stores the
  .bim/.ped alleles as "allele.1/allele.2" instead of the placeholder "A/C".
  Full dartR.base suite: 1444 tests, 0 failures.
- dartR.captive PR #155 (Luis) merged: `loiselle` removed at Jinliang Wang's
  request, Wang credited as contributor, citations per estimator.
- dartRverse: coancestry zips (`binaries/coancestry_<os>.zip`) on `dev` and
  cherry-picked to `main` (da7c68d), so `gl.download.binary("coancestry")`
  works. Click tip printed before the tables of `dartRverse_install()` and
  `gl.download.binary()`, and the "All packages" install line moved above
  the version table (ee8ae82). "coancestry" added to the download notice.
- READMEs of all packages except dartR.data: "What's new" link to NEWS.md.
  dartR.popgen README had leftover merge-conflict markers; resolved.
- Report comparing the FBM work with Luis's summary:
  `D:/downloads/fbm_achievements_1.3.0.pdf` (local file).

## Open items (not blocking the release)

- Neighbour imputation favours individuals with few scored loci (Luis's
  review; both storage types). An estimator change, needs a decision.
- `dartR_coancestry.exe` is blocked on UC-managed Windows PCs by Defender
  ASR rule 01443614-CD74-433A-B99E-2ECDC07BFC25 (unsigned, low-prevalence
  executable). Users at other institutions may hit the same; consider
  code-signing the Windows build or a note in the help page.
  `gl.relatedness` tests with the program could not be run on that PC.
- From Luis's FBM review, not done: read counts/likelihoods on disk (low
  priority), benchmark on data larger than memory, new bigsnpr analyses,
  CSV reader to FBM, `gl2*` exports block-wise.
- Panel functions (dartR.popgen): no tests for `gl.check.future.panel`,
  `gl.select.panel.combined`, `gl.select.panel.parallel`,
  `gl.opt.ind.all`; unclear errors with exactly 2 populations.

## Working conventions

- Run only the affected test files while iterating; full test suite and
  check at the end. Ask before full runs and before winbuilder uploads.
- `main` = CRAN: merge into main only after CRAN acceptance (exception:
  binaries in dartRverse, severe fixes).
- Several READMEs are stored with CRLF in git but checked out as LF on
  Windows: keep CRLF when editing them, or every line shows as changed.
