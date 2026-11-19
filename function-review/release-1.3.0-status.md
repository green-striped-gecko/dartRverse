# dartRverse 1.3.0 release: status (20 Nov 2026)

Hand-over to pick up the release from another computer. Older details of the
FBM work: `dartR.base/function-review/release-1.3.0-status.md`,
`fbm-step2-plan.md`, `fbm-step3-status.md`.

## Where the release stands

**20 Nov 2026 — CRAN submissions, one package at a time:**

| Package | Version | CRAN |
|---|---|---|
| dartR.data | 1.2.7 | accepted |
| dartR.base | 1.3.0 | accepted |
| dartR.popgen | 1.3.0 | accepted |
| dartR.sim | 1.3.0 | accepted (20 Nov) |
| dartR.spatial | 1.3.0 | **next**: tarball rebuilt and checked 20 Nov, CRAN note below |
| dartR.captive | **1.3.1** | accepted (20 Nov); main merged 92bee8c |
| dartR.sexlinked | 1.3.0 | checked 20 Nov, CRAN note below; Diana submits |
| dartRverse | 1.3.0 | last |

Submit the next one only after the previous one is accepted. Tarballs in
`D:/Bernd/R/dartRs/cran` (local folder, not in git):

- `dartR.spatial_1.3.0.tar.gz`: **rebuilt 20 Nov 09:13** from `beta`
  f2eec7f with R 4.3.1 on the home PC. The copy there before was the 18 Nov
  build, still with `reemsplots2` in Suggests and the `Remotes` field (the
  19 Nov rebuild was on the UC PC only). The new DESCRIPTION has neither.
- `dartR.captive_1.3.1.tar.gz`: **new, 20 Nov 09:17**, from `beta` aafba88.
  `dartR.captive_1.3.0.tar.gz` removed from the folder.
- The others (18 Nov 17:22) postdate their last `beta` commits and were
  compared with `beta` on 19 Nov.

Neither new tarball has had `R CMD check --as-cran` yet (spatial: the same
commit passed it on the UC PC on 19 Nov, 0 errors). Run it before
submitting captive 1.3.1.

**main:** `beta` merged into `main` for the accepted packages; `main` has
the same content as `beta`: dartR.data 8776ec0, dartR.base eae477d,
dartR.popgen 55e3543 (19 Nov), dartR.sim bdf9ffd, dartR.captive 92bee8c
(20 Nov). Do the same for
each further package after CRAN accepts it.

**20 Nov: Luis's PRs merged into dev, versions 1.3.1 on dev.**

- dartR.captive #156: `gl.test.offspring()` stopped with "Allele
  frequencies must be finite and in [0,1]" whenever it estimated the
  frequencies from about 50 or more individuals (default `epsilon`) and a
  locus was (nearly) fixed; the estimate is now limited to [0, 1]. Tests:
  73 pass, 0 fail. Because the function is unusable on realistic data in
  1.3.0, **captive goes to CRAN as 1.3.1**: dev merged into `beta` (aafba88),
  NEWS has a 1.3.1 section.
- dartR.popgen #137: `gl.select.panel.parallel()` ran only `n_cores` chains
  when `n_cores < n_chains`. Fixed on dev, version 1.3.1 (b13e24a); panel
  tests 99 pass, 0 fail. Not in `beta`/CRAN yet (popgen 1.3.0 is accepted).
- dartR.base 1.3.1 on dev (legacy `readRDS()` objects, `gl.pcoa.plot`
  star labels); not in `beta`.

**CRAN maintainers (`cre`):** Bernd for dartR.base, data, popgen, spatial,
captive and dartRverse; Luis for dartR.sim; Diana Robledo-Ruiz for
dartR.sexlinked. The maintainer uploads and confirms the submission email.

**CRAN note for dartR.spatial 1.3.0** (Bernd uploads; checked 20 Nov,
home PC, R 4.3.1: 0 errors, 336 s, examples 17 s, with donttest 30 s, tests
34 s; only local WARNING adegenet/ade4 built under R 4.3.3 and NOTEs clock,
no pandoc):

```
## Submission summary

This is an update of dartR.spatial (1.2.2 -> 1.3.0). It is part of a
coordinated dartRverse release and requires dartR.base (>= 1.3.0), which CRAN
has accepted. dartR.data 1.2.7, dartR.popgen 1.3.0, dartR.sim 1.3.0 and
dartR.captive 1.3.1 have also been accepted.

## Main changes

* Support for file-backed (FBM) genotype storage from dartR.base 1.3.0.
* The GitHub-only package 'reemsplots2' has been removed from Suggests, and
  the Remotes field has been removed from DESCRIPTION. gl.run.eems() checks for
  'reemsplots2' at run time with requireNamespace() and, if it is missing,
  stops with a message saying how to install it.
* Bug fixes (see NEWS.md), and slow test files call skip_on_cran().

## Test environments

* local Windows 11, R 4.3.1: R CMD check --as-cran

## R CMD check results

0 errors | 0 warnings | 0 notes

(Locally only: a warning that adegenet/ade4 were built under R 4.3.3, and
notes that the current time could not be verified and that pandoc is not
installed. All are specific to the local machine.)

## Reverse dependencies

The only reverse dependency is dartRverse (Suggests). The CRAN version of
dartRverse (1.0.6) was checked against dartR.spatial 1.3.0: Status OK.
```

**dartR.captive 1.3.1 checked (20 Nov, home PC, R 4.3.1):**
`R CMD check --as-cran cran/dartR.captive_1.3.1.tar.gz`: 0 errors, 354 s;
examples 17 s (19 s with donttest), tests 56 s. Only local issues: WARNING
adegenet/ade4 built under R 4.3.3; NOTEs clock, no pandoc, no V8.
Reverse dependencies: only dartRverse (Suggests); the CRAN dartRverse 1.0.6
does not use the functions removed in 1.2.7 (`gl.assign.*`,
`utils.assignment*`). Ready to submit after spatial is accepted.

**dartRverse (20 Nov):** NEWS says captive is 1.3.1; dev merged into `beta`
(0be9b08, now also carries this document, which is build-ignored);
`cran/dartRverse_1.3.0.tar.gz` rebuilt from it (09:25).

**CRAN note for dartR.captive 1.3.1** (Bernd uploads):

```
## Submission summary

This is an update of dartR.captive (1.2.2 -> 1.3.1). It is part of a
coordinated dartRverse release and requires dartR.base (>= 1.3.0); dartR.base
1.3.0, dartR.data 1.2.7, dartR.popgen 1.3.0, dartR.sim 1.3.0 and
dartR.spatial 1.3.0 have been accepted.

## Main changes

* New functions: gl.test.offspring(), gl.report.errorrate(),
  gl.inbreeding(), gl.parentage.power() and gl.relatedness().
* gl.relatedness() uses the external program 'dartR_coancestry' (Coancestry
  estimators, by permission of its author, Jinliang Wang, who is listed as a
  contributor). The program is not shipped with the package and is never
  downloaded automatically: users download it explicitly with
  dartRverse::gl.download.binary() and give its location. gl.inbreeding()
  runs PLINK and GCTA, which users install themselves, in the same way.
  Examples that need these programs are in \dontrun{}, and tests skip when
  the programs are absent.
* Support for file-backed (FBM) genotype storage from dartR.base 1.3.0.
* gl.assign.pca(), gl.assign.pa(), gl.assign.on.genotype() and
  gl.assign.mahalanobis() moved to dartR.popgen; duplicate and unused
  helpers removed.
* Slow test files call skip_on_cran().

## Test environments

* local Windows 11, R 4.3.1: R CMD check --as-cran

## R CMD check results

0 errors | 0 warnings | 0 notes

(Locally only: a warning that adegenet/ade4 were built under R 4.3.3, and
notes that the current time could not be verified and that pandoc and V8
are not installed. All are specific to the local machine.)

## Reverse dependencies

The only reverse dependency is dartRverse (Suggests). It does not use the
functions that were moved or removed.
```

**CRAN note for dartR.sexlinked 1.3.0** (maintainer Diana Robledo-Ruiz
<diana.robledoruiz1@monash.edu> uploads; tarball = `beta` 5d90b12; checked
20 Nov, home PC, R 4.3.1: 0 errors, 269 s, examples 21 s, tests 31 s; only
local WARNING adegenet/ade4 built under R 4.3.3 and NOTEs clock, no pandoc):

```
## Submission summary

This is an update of dartR.sexlinked (1.2.2 -> 1.3.0). It is part of a
coordinated dartRverse release and requires dartR.base (>= 1.3.0), which CRAN
has accepted (as have dartR.data 1.2.7, dartR.popgen 1.3.0, dartR.sim 1.3.0
and dartR.captive 1.3.1).

## Main changes

* gl.report.sexlinked(), gl.filter.sexlinked(), gl.keep.sexlinked() and
  gl.infer.sex() support file-backed (FBM) genotype storage from dartR.base
  1.3.0, reading the data in blocks of loci; results are identical to those
  for data held in memory.
* Bug fixes in gl.drop.sexlinked(), gl.keep.sexlinked(),
  gl.filter.sexlinked() and gl.infer.sex() (see NEWS.md).
* Slow test files call skip_on_cran().

## Test environments

* local Windows 11, R 4.3.1: R CMD check --as-cran

## R CMD check results

0 errors | 0 warnings | 0 notes

(Locally only: a warning that adegenet/ade4 were built under R 4.3.3, and
notes that the current time could not be verified and that pandoc is not
installed. All are specific to the local machine.)

## Reverse dependencies

There are currently no reverse dependencies on CRAN.
```

**Home PC (20 Nov):** `Rscript` on PATH is R 4.6.2 with no packages; the
package library is under R 4.3.1
(`C:/Program Files/R/R-4.3.1/bin/x64/Rscript.exe`). All eight dev versions
installed there on 20 Nov.

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
Reverse dependencies: only dartRverse (Suggests). CRAN's dartRverse 1.0.6
checked against dartR.spatial 1.3.0 on 19 Nov: Status OK. Ready to submit.

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

1. Submit dartR.spatial 1.3.0 (tarball and CRAN note above).
2. After acceptance: merge spatial `beta` into `main`; run
   `R CMD check --as-cran` on `cran/dartR.captive_1.3.1.tar.gz` and submit
   it (its CRAN note must say 1.2.2 -> 1.3.1 and mention the
   `gl.test.offspring()` fix); then dartR.sexlinked, then dartRverse.
3. Done 20 Nov: dartR.sim 1.3.0 accepted, which clears the 2026-12-06
   deadline for the `gl.sim.ind` example error.
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

## Branches (origin, 20 Nov 2026)

`beta` has the same content as `dev` except where dev has moved on to 1.3.1
(base, popgen: dev only; captive: dev and beta). dartRverse dev only adds
this document. `main` = `beta` for data, base, popgen and sim (merged after
CRAN acceptance); the others are merged after their acceptance (dartRverse
main only gained the coancestry zips).

| Package | dev | beta | main | Version dev / beta |
|---|---|---|---|---|
| dartR.base | e416024 | 5c88139 | eae477d | 1.3.1 / 1.3.0 |
| dartR.popgen | b13e24a | 02730f7 | 55e3543 | 1.3.1 / 1.3.0 |
| dartR.sim | 0922c41 | 12fe5c8 | bdf9ffd | 1.3.0 / 1.3.0 |
| dartR.spatial | 2f1167e | f2eec7f | 51c7854 | 1.3.0 / 1.3.0 |
| dartR.captive | 9270e80 | aafba88 | 92bee8c | 1.3.1 / 1.3.1 |
| dartR.sexlinked | 29a914f | 5d90b12 | 4bb887a | 1.3.0 / 1.3.0 |
| dartR.data | c77c859 | 5c604db | 8776ec0 | 1.2.7 / 1.2.7 |
| dartRverse | (latest) | 3598e40 | da7c68d | 1.3.0 / 1.3.0 |

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

- The local check warning "package 'dplyr' was built under R version
  4.4.3" comes only from the UC PC: R there is 4.4.1, while 293 installed
  packages (dplyr among them) were built under newer R. CRAN does not see
  it. Rebuilding dplyr from source failed on 19 Nov and was not pursued
  (Bernd: leave it). The lasting fix is updating R on that PC.

## Working conventions

- Run only the affected test files while iterating; full test suite and
  check at the end. Ask before full runs and before winbuilder uploads.
- `main` = CRAN: merge into main only after CRAN acceptance (exception:
  binaries in dartRverse, severe fixes).
- Several READMEs are stored with CRLF in git but checked out as LF on
  Windows: keep CRLF when editing them, or every line shows as changed.
