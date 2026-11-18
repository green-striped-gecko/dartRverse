# dartRverse 1.3.0 release: status (18 Nov 2026, evening)

Hand-over to pick up the release from another computer. Older details of the
FBM work: `dartR.base/function-review/release-1.3.0-status.md`,
`fbm-step2-plan.md`, `fbm-step3-status.md`.

## Where the release stands

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
4. The other packages may also exceed CRAN's 10-min check time on Windows
   R-devel; consider `skip_on_cran()` for their slowest test files before
   submitting (dartR.popgen tests ~200 s locally, dartR.sim tests ~350 s
   plus vignettes ~155 s).
5. After acceptance: merge `beta` into `main` (main = CRAN; never earlier).

## Reverse dependencies (CRAN versions vs dartR.base 1.3.0)

R CMD check of the CRAN versions against dartR.base 1.3.0: dartRverse 1.0.6
OK; popgen, spatial, captive, sexlinked 1.2.2 only the local dplyr warning;
dartR.sim 1.2.2 the known `gl.sim.ind` example error (already on its CRAN
check page, not caused by dartR.base). `gl.He`, `gl.Ho`, `gl.propShared`
were moved back to dartR.base so the CRAN add-ons keep working.

## Branches (origin, 18 Nov 2026)

`beta` has the same content as `dev` in every repo. `main` is still the CRAN
1.2.x state (dartRverse main only gained the coancestry zips).

| Package | dev | beta | Version |
|---|---|---|---|
| dartR.base | e580622 | 5c88139 | 1.3.0 |
| dartR.popgen | 0729006 | ab25c03 | 1.3.0 |
| dartR.sim | dcbbf88 | 835abc0 | 1.3.0 |
| dartR.spatial | 8c2a044 | 6819963 | 1.3.0 |
| dartR.captive | 293d944 | b308332 | 1.3.0 |
| dartR.sexlinked | 9fbbd51 | f6b0354 | 1.3.0 |
| dartR.data | c77c859 | 5c604db | 1.2.7 |
| dartRverse | (this commit) | 3598e40 | 1.3.0 |

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
