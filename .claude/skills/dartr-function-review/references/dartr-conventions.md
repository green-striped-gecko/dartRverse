# dartR function conventions

Rules catalogue for the dartRverse function-review skill. Extracted from
"For the Developer" (Georges, Gruber & Mijangos 2021, v2) and modernized
against the dartR.base codebase (Aug 2026, dev branch).

Every rule has an ID (cite it in findings), a status, and where possible a
mechanical check. Statuses:

- **[confirmed]** — matches current code; the skill enforces it.
- **[proposed]** — modernization or new rule awaiting team ratification;
  the skill reports against it but findings are labelled "proposed rule".

A documented decision by the team overrides any rule here. When a rule and
the code disagree and the code is clearly the newer intent, flag the rule,
not the code.

---

## FS — Function structure

The canonical anatomy of a `gl.*` function, in order:

- **FS1** [confirmed] One exported function per file; filename matches the
  function (`gl.filter.callrate.r`). Function names use dots, lower case:
  `gl.<verb>.<noun>` (`gl.report.*`, `gl.filter.*`, `gl.read.*`, `gl.keep.*`,
  `gl.drop.*`, `gl.recode.*`, `gl.dist.*`, `gl.tree.*`, `gl.*2*` converters).
  Internal helpers are `utils.*` and are not exported unless needed.
- **FS2** [confirmed] SET VERBOSITY first:
  `verbose <- gl.check.verbosity(verbose)` with `verbose = NULL` as the
  parameter default.
  *(2021 doc says `gl.set.verbosity()` here — outdated; that function sets
  the session default, it is not the entry-point check.)*
- **FS3** [confirmed] FLAG SCRIPT START:
  `funname <- match.call()[[1]]` then
  `utils.flag.start(func = funname, verbose = verbose)`.
  *(2021 proforma's `build=` and `v=` arguments are outdated.)*
- **FS4** [confirmed] CHECK DATATYPE:
  `datatype <- utils.check.datatype(x, verbose = verbose)`, with `accept=`
  when the function takes non-genlight input (`dist`, `fd`, `matrix`).
  *(2021 doc says `gl.check.datatype()` — outdated name.)*
- **FS5** [confirmed] FUNCTION SPECIFIC ERROR CHECKING next: dependency
  guards (DEP1), then parameter validation. Fail fast with
  `stop(error("..."))` before any work is done.
- **FS6** [confirmed] DO THE JOB — the main body, after all checks.
- **FS7** [confirmed] Functions that output files call
  `gl.check.wd(plot.dir, verbose = 0)` (or equivalent) rather than writing
  to the working directory unchecked.
- **FS8** [confirmed] ADD TO HISTORY when (and only when) the function
  returns a modified genlight object:
  `nh <- length(x@other$history); x@other$history[[nh + 1]] <- match.call()`.
  Read-only `gl.report.*` functions do not append history.
- **FS9** [confirmed] FLAG SCRIPT END:
  `if (verbose > 0) cat(report("Completed:", funname, "\n"))`.
- **FS10** [confirmed] RETURN explicitly: `return(x)` for objects the user
  assigns; `invisible(x)` when printing the object on call would be noise.
- **FS11** [proposed] Use `inherits(x, "genlight")` / `is(x, "dartR")`
  rather than `class(x)[1] == "genlight"` (the 2021 proforma's idiom breaks
  under class hierarchies; the dartR S4 class extends genlight).

## DOC — Documentation (roxygen2)

- **DOC1** [confirmed] Required tags, in the house order: `@name`, `@title`
  (no full stop), `@family`, `@description` (one short paragraph),
  `@details`, `@param` (every parameter, each ending with
  `[required]` or `[default <value>]`), `@return`, `@author`
  (see DOC7 for the required internal structure),
  `@examples`, `@export`. `@references` and `@seealso` where relevant.
- **DOC2** [confirmed] The `verbose` param text is standard:
  "Verbosity: 0, silent or fatal errors; 1, begin and end; 2, brief progress
  messages; 3, progress and results summary; 5, full report
  [default 2, unless specified using gl.set.verbosity]."
- **DOC3** [confirmed] `@examples` use packaged datasets (TST1) and must run
  fast enough for CRAN; wrap slow or toolchain-dependent examples in
  `\donttest{}` — but note CRAN's incoming checks DO run `\donttest`.
- **DOC4** [confirmed] After editing any roxygen header, run
  `devtools::document()` in the same change so `man/*.Rd` and `NAMESPACE`
  stay in sync. A PR with a changed header and an unchanged `.Rd` is a
  finding.
- **DOC5** [proposed] Behavior/documentation agreement is a review axis of
  its own: every claim in `@description`/`@details` must be true of the
  code as it stands, and every verbose level promised must actually print.
- **DOC6** [proposed] ASCII only in roxygen (no curly quotes, arrows,
  accented characters) — safest for the PDF manual across platforms.
- **DOC7** [proposed] `@author` must state both an author and a custodian as
  two separate labelled parts, even when they are the same person:
  `Author(s): <name(s)>. Custodian: <name> -- Post to
  \url{https://groups.google.com/d/forum/dartr}`. A block naming only a
  custodian, with no `Author(s):` line, is a finding under this rule —
  reported against DOC7 specifically, not folded into DOC1, since DOC1's
  [confirmed] status only covers tag *presence*, not this internal
  structure. Not [confirmed]: many current files state only
  `Custodian: <name>` with no separate Author(s) line (e.g. `gl2snapper.r`,
  `gl2phylip.r`, `gl.propShared.r` has the reverse gap — an author with no
  Custodian label at all).

## VRB — Verbosity and messaging

- **VRB1** [confirmed] Verbose scale: 0 silent or fatal errors; 1 begin and
  end; 2 + brief progress and warnings; 3 + results summary; 5 full report.
  Level 4 is unused — do not invent behavior for it.
  *(2021 doc lists "4 – to be implemented"; treat 4 as reserved.)*
- **VRB2** [confirmed] Message helpers from `R/zzz.r` (crayon): `error()`
  red for fatal errors inside `stop()`, `warn()` yellow, `report()` green,
  `important()` blue. Never `cat()` raw uncolored user messages.
- **VRB3** [confirmed] Warnings are gated: `if (verbose >= 2) cat(warn(...))`.
  Fatal errors are never gated — `stop(error(...))` fires at any verbosity.
- **VRB4** [proposed] Warnings that affect results (e.g. a cap hit, loci
  silently exempted from processing) print at `verbose >= 1`, not `>= 2` —
  a user running quietly must still learn their output is partial.

## DAT — Data structure integrity

- **DAT1** [confirmed] Genotype encoding: SNP data 0/1/2/NA with ploidy 2;
  SilicoDArT 0/1/NA with ploidy 1. Any code path that creates or transforms
  a genlight must preserve ploidy. (Recurring historical bug: `gen2fbm`
  wiping ploidy in `gl.read.csv`.)
- **DAT2** [confirmed] Any manipulation of genotypes must be accompanied by
  companion manipulation of the metadata: `@other$loc.metrics` rows must
  track loci 1:1, `@other$ind.metrics` (and `pop`, `ploidy`) must track
  individuals 1:1. adegenet does not do this for you. (Recurring bug class:
  `gl.impute` desync, `pop.het` recycling.)
- **DAT3** [confirmed] When subsetting loci by index, re-subset
  `loc.metrics` from the ORIGINAL object
  (`x2@other$loc.metrics <- x@other$loc.metrics[keep, , drop = FALSE]`) —
  idempotent whether or not the `[` method handled it. Prefer positive
  index subsetting (safe for genlight, dartR, and FBM-backed objects;
  duplicate locus names make name-based dropping unsafe).
- **DAT4** [confirmed] Metrics flags: if a function invalidates a locus
  metric (deletes individuals/populations, recodes genotypes), set the
  matching `@other$loc.metrics.flags` to FALSE or recalculate via
  `utils.recalc.*` / `gl.recalc.metrics`.
- **DAT5** [confirmed] Functions accepting external genlight objects should
  tolerate objects not built by dartR; where structure is assumed, either
  run/require `gl.compliance.check()` or fail with a clear message.
- **DAT6** [proposed] FBM-awareness: functions must work on FBM-backed
  dartR objects or refuse them explicitly. Avoid full densification
  (`as.matrix(x)`) when an accessor (`glNA()`, locus metrics) or
  column-wise access serves; a function that silently materializes a
  100 GB matrix is a finding.

## DEP — Dependencies

- **DEP1** [confirmed] Packages in Suggests are guarded at the top of the
  function:
  `if (!(requireNamespace(pkg, quietly = TRUE))) stop(error("Package", pkg, "needed for this function to work. Please install it.\n"))`.
- **DEP2** [confirmed] Call non-base functions from dependency packages
  with explicit namespacing (`stringr::str_split()`) in new code.
- **DEP3** [proposed] Rcpp policy: Rcpp stays in Suggests with a DEP1
  guard; run-time `Rcpp::cppFunction()` puts helper functions and includes
  in `includes=`; migration of hot kernels to `src/` (making the package
  compiled) is a team-level decision, not a per-function one.

## PLT — Plots and file output

- **PLT1** [confirmed] Plots are ggplot2, using `plot.theme`
  (default `theme_dartR()`) and `plot.colors` parameters; multi-panel
  layouts via patchwork. Colours/palettes come from `R/zzz.r`
  (`two_colors`, `discrete_palette`, etc.).
  *(2021 doc's `plot_theme`/`plot_colors` underscore names are outdated.)*
- **PLT2** [proposed] Saving: the current idiom is
  `plot.file`/`plot.dir` + `utils.plot.save()`, with `plot.dir` resolved by
  `gl.check.wd()`. The 2021 idiom (save RDS to `tempdir()`, retrieve via
  `gl.list.reports()`/`gl.print.reports()`) survives in ~60 files; the team
  should ratify one idiom — recommendation: `plot.file`/`plot.dir`, and
  migrate `tempdir()` code as functions are touched.
- **PLT3** [confirmed] Computation must not depend on plotting: results are
  computed and returned regardless of `plot.out`/`plot.display`; plotting
  failures or `plot.out = FALSE` must not empty the returned object.
  (Recurring bug class: `gl.test.heterozygosity`.)

## STY — Programming style

- **STY1** [confirmed] Write for the future reader: comment the *why* and
  the non-obvious, indent conditional/repetition blocks, wrap at 80
  characters.
- **STY2** [confirmed] Hoist loop-invariant computation out of loops;
  convert the genlight once (`mat <- as.matrix(x)`) rather than per
  iteration — subject to DAT6 for large data.
- **STY3** [confirmed] Prefer base R or established utility packages;
  avoid context-dependent cleverness.
- **STY4** [proposed] Style reference updated from Advanced R 1st-ed style
  page to the tidyverse style guide (https://style.tidyverse.org), applied
  to new code only — no wholesale reformatting of untouched code.
- **STY5** [confirmed] Etiquette: do not rewrite another developer's
  function without discussing the problem and proposed fix with them;
  match the file's existing formatting style. (For the review campaign:
  the report-then-approve workflow satisfies this rule.)

## API — Stability and back-compatibility (new section)

- **API1** [proposed] No silent semantic changes: if an argument's meaning,
  default, or the function's numerical output changes, the change must be
  (a) approved by the custodian, (b) guarded where feasible — old-style
  argument values raise an informative error rather than being reinterpreted
  (e.g. proportion-style `threshold` in `gl.filter.hamming`), and
  (c) recorded in NEWS.
- **API2** [proposed] Removed or renamed parameters error loudly via
  R's unused-argument mechanism or an explicit check — never absorbed
  by `...`.
- **API3** [proposed] Functions are consumed downstream by sibling
  dartRverse packages and the dartr2shiny generator: signature changes
  require a grep across `dartR.*` siblings before merging.

## GIT — Contribution workflow

- **GIT1** [confirmed] Branch flow: personal `dev_<name>` branches →
  PR into `dev` (integration/beta) → `main` (release/CRAN). Never commit
  to `dev` or `main` directly; never act against the flow direction.
  *(2021 doc's `master`/`Beta` names are outdated.)*
- **GIT2** [confirmed] Before starting work, sync `dev_<name>` with
  `origin/dev`; resolve conflicts on your own branch, not in `dev`.
- **GIT3** [confirmed] A fix on `dev` is not in a CRAN or default
  `install_github()` install — user-facing replies must point at
  `ref = "dev"` when the fix has not been released.
- **GIT4** [proposed] For the review campaign: one function per commit and
  per PR, commit message stating why + evidence (before/after, test
  output); the review report is linked in the PR body.

## TST — Test data and verification (new section)

- **TST1** [confirmed] Packaged datasets for examples and checks:
  `testset.gl` (SNP), `testset.gs` (SilicoDArT), plus `platypus.gl` and
  others from dartR.data. Examples must be small and fast (CRAN).
- **TST2** [proposed] Characterization first: before modifying a function,
  snapshot its current outputs on reference data into
  `tests/testthat/`; behavior changes must be visible as snapshot diffs
  and each accepted diff must map to an approved finding.
- **TST3** [proposed] Every claimed fix carries evidence in the PR: the
  failing case before, the passing case after, or a property check
  (e.g. brute-force verification of an algorithmic guarantee).
