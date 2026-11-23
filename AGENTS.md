# AGENTS.md — dartRverse development

## Purpose

This file defines how coding agents should work on the dartRverse ecosystem.
The aim is to extend and maintain dartR without breaking established user
workflows, while supporting large genomic datasets through the FBM-backed
memory model.

These instructions apply to the dartRverse meta-package and to the associated
packages when they are present in the working tree:

- `dartR.base`
- `dartR.data`
- `dartR.popgen`
- `dartR.sim`
- `dartR.spatial`
- `dartR.captive`
- `dartR.sexlinked`

More specific `AGENTS.md` files in individual package directories may add to or
override these instructions.

## Project priorities

In descending order of importance:

1. Scientific correctness.
2. Backward compatibility with established dartR functions and workflows.
3. Equivalent behaviour for standard `genlight` and FBM-backed dartR objects.
4. Preservation of metadata and object integrity.
5. Scalability for large SNP datasets.
6. Clear documentation, informative messages, and reproducible tests.
7. CRAN compliance and maintainable package boundaries.

Do not trade scientific correctness or compatibility for shorter code.

## Ecosystem boundaries

Keep functionality in the package that owns the relevant domain:

- `dartRverse`: installation, package discovery, version reporting, and
  ecosystem-level coordination. Keep this meta-package thin.
- `dartR.base`: core object handling, import/export, reporting, filtering,
  conversions, shared utilities, and basic analyses.
- `dartR.data`: example and reference datasets.
- `dartR.popgen`: population-genetic analyses.
- `dartR.sim`: simulation of SNP data and demographic/genetic processes.
- `dartR.spatial`: spatial and landscape-genetic analyses.
- `dartR.captive`: relatedness, breeding, and captive-management analyses.
- `dartR.sexlinked`: identification and analysis of sex-linked markers.

Before adding a function, inspect neighbouring functions and confirm that the
chosen package is the correct owner. Put shared low-level infrastructure in
`dartR.base`. Avoid circular dependencies and avoid copying the same helper
into several packages.

Use specialist external packages such as `LEA`, `hierfstat`, or `StAMPP` only
where dartRverse does not already provide equivalent functionality or where the
external implementation is deliberately required.

## Compatibility requirements

The established `gl.*` interface is public API. Unless the user explicitly
approves a breaking change, preserve:

- exported function names;
- argument names, order, and defaults;
- accepted input classes;
- return classes and documented return structure;
- locus and individual ordering;
- population assignments, ploidy, names, and relevant metadata;
- documented warnings, errors, verbosity behaviour, and side effects.

Prefer extending an existing function over creating a nearly identical
replacement. New arguments should normally be added after existing arguments
and should default to the previous behaviour.

Do not silently reinterpret an existing argument. If behaviour must change,
identify the compatibility impact before implementation and add regression
tests for the old behaviour.

## Object and metadata integrity

Treat a dartR object as more than its genotype matrix. Any operation that
filters, reorders, combines, converts, saves, or reloads data must keep the
following aligned where applicable:

- individual and locus names;
- genotype rows and columns;
- ploidy;
- population assignments;
- individual metrics;
- locus metrics;
- history and provenance records;
- FBM descriptors and backing-file references;
- any other metadata used by existing dartR helpers.

Use existing dartR accessors and utilities rather than directly modifying
slots when suitable helpers exist. Never assume that a slot or element is
present without checking the supported object variants.

After filtering or reordering, explicitly test that genotype data and metadata
remain in the same order. Do not repair inconsistencies by silently discarding
metadata.

## Dual-backend and FBM rules

New or modified core functions must be assessed against both:

1. the conventional in-memory `genlight` representation; and
2. the FBM-backed dartR representation.

Follow these rules:

- Do not silently coerce or materialise an entire FBM-backed dataset as a dense
  in-memory matrix.
- Prefer block-wise, indexed, or backend-aware operations for large datasets.
- If materialisation is mathematically or technically unavoidable, make the
  boundary explicit, justify it in code comments, estimate the likely memory
  consequence where practical, and warn or fail clearly before exhausting
  memory.
- Preserve identical scientific meaning across backends. Small floating-point
  differences are acceptable only within an explicitly justified tolerance.
- Add equivalence tests using the same small dataset represented by both
  backends.
- Treat conversion, ordination, and persistence functions—particularly code
  related to `gl.fbm2gen()`, `gl.pcoa()`, and `gl.save()`—as memory-sensitive
  areas requiring careful review.
- Do not introduce a nominal FBM code path that eventually calls a helper which
  materialises the complete genotype matrix.

When only one backend can be supported, do not silently fall back. Explain the
limitation and return an informative error unless the existing public API
documents another behaviour.

## `glMean`, `glSum`, and `adegenet`

`dartR.base::glMean()` and `dartR.base::glSum()` are the authoritative dartR
implementations and must support FBM-backed objects. For conventional objects,
they may delegate explicitly to `adegenet` as a fallback where appropriate.

Maintain the following dependency rules:

- Do not put `adegenet` in `Depends` merely to make its functions available.
- Use `Imports` or `Suggests`, as appropriate, and call fallback functions with
  explicit namespace qualification such as `adegenet::glMean()`.
- Do not import `glMean` or `glSum` from both `adegenet` and `dartR.base`.
- Downstream dartRverse packages should resolve these functions through
  `dartR.base`.
- Do not attempt to fix namespace masking by reordering packages in `Depends`.
- Run load and check tests capable of detecting messages such as “replacing
  previous import”.

Apply the same explicit-ownership principle to other namespace conflicts.

## R implementation conventions

- Follow the style of the package and surrounding file; do not reformat
  unrelated code.
- Prefer existing internal helpers over parallel implementations.
- Use namespace-qualified calls for functions from imported packages unless
  the package deliberately imports the symbol.
- Do not use `:::` to access unexported functions from another package.
- Do not add a dependency without explaining why existing dependencies or base
  R are insufficient and obtaining approval.
- Avoid global state, `setwd()`, hidden changes to options, and changes to the
  user's search path.
- Restore temporary options, warning settings, graphics parameters, and
  parallel plans with `on.exit()`.
- Use `TRUE` and `FALSE`, not `T` and `F`.
- Validate inputs early and return errors that identify the invalid argument
  and expected form.
- Respect existing dartR verbosity and reporting conventions.
- Keep randomised algorithms reproducible when a seed is supplied. Tests must
  set an explicit seed.
- Do not optimise away biologically important checks merely for speed.

For numerical code, state the assumed genotype coding, ploidy, missing-data
treatment, allele-frequency denominator, and population grouping in comments
or documentation whenever these are not already unambiguous.

## Scientific correctness

Never infer a population-genetic formula from a function name alone. Before
changing numerical behaviour:

1. inspect the current implementation and documentation;
2. identify the estimator and its assumptions;
3. compare with the cited method or authoritative package implementation;
4. construct a small hand-checkable example;
5. test missing data, unequal sample sizes, monomorphic loci, and relevant
   ploidy cases;
6. compare both storage backends.

Do not change an estimator, correction, denominator, or default filtering rule
without explicitly reporting the scientific and compatibility implications.
Never fabricate reference values merely to make a test pass.

## Documentation

Use `roxygen2` for exported objects. For every new or materially changed
function, update as applicable:

- title and description;
- all parameters and defaults;
- return value and object class;
- scientific assumptions and estimator definitions;
- handling of missing data and ploidy;
- FBM limitations or memory behaviour;
- examples;
- references and related functions;
- package README, vignette, tutorial, or NEWS entry.

Examples should be small, deterministic, and runnable within CRAN constraints.
Do not leave documentation describing behaviour that the implementation no
longer has. Regenerate `NAMESPACE` and `.Rd` files through `roxygen2`; do not
hand-edit generated files unless the package explicitly requires it.

## Testing requirements

Every bug fix requires a regression test that fails before the fix. Every new
feature requires tests of its public behaviour.

Where relevant, cover:

- standard and FBM-backed representations of the same dataset;
- missing genotypes;
- monomorphic and all-missing loci;
- one individual, one locus, and empty-result cases;
- haploid or variable-ploidy inputs where supported;
- one population and multiple populations;
- reordered or filtered loci and individuals;
- preservation of names, populations, metrics, and history;
- invalid inputs and informative error messages;
- deterministic behaviour of random or parallel code;
- expected namespace loading without import-replacement warnings;
- compatibility with previously supported calls.

Use small fixtures. Tests must not require internet access, write into the
source tree, depend on execution order, or rely on packages that are not
declared in `DESCRIPTION`.

Use numerical tolerances that are scientifically defensible; do not widen a
tolerance simply to conceal a regression.

## Verification workflow

Before editing:

1. identify the active package and branch;
2. inspect `DESCRIPTION`, `NAMESPACE`, relevant R files, tests, and
   documentation;
3. inspect `git status` and preserve unrelated user changes;
4. locate the existing helper or closest analogous function;
5. determine whether downstream dartRverse packages are affected.

After editing an R package, run from that package directory:

```sh
Rscript -e "devtools::document()"
Rscript -e "devtools::test()"
Rscript -e "devtools::check(document = FALSE, args = '--no-manual')"
```

When preparing a release or when requested, also run the repository's existing
CRAN-style and CI checks. Do not claim CRAN compliance solely from unit tests.

If an exported object, shared class, backend method, dependency, or namespace
changes, install the modified upstream package and test all affected downstream
dartRverse packages. At minimum, verify that each affected package loads
without warnings and that its tests and package check complete.

If a command cannot be run, report the exact command, reason, and remaining
risk. Distinguish new failures from pre-existing warnings or notes.

## Branches, Git, and scope

The ecosystem uses `main`, `beta`, and `dev` branches. Confirm the intended
branch and follow the repository's current release practice. Do not assume that
`dev`, `beta`, and CRAN versions are interchangeable.

- Keep changes narrowly scoped to the requested task.
- Do not overwrite, revert, or reformat unrelated user work.
- Do not use destructive Git commands.
- Do not commit, push, merge, change branches, bump versions, or update release
  dates unless explicitly requested.
- Do not modify generated documentation, dependency files, or several packages
  merely because they are nearby; establish that the change requires it.
- Review the final diff for unintended API, namespace, documentation, and data
  changes.

## Agent working style

- Begin with repository evidence rather than assumptions.
- For a diagnosis or review request, explain the cause and proposed change; do
  not implement unless implementation was requested.
- For an implementation request, complete the code, documentation, tests, and
  safe verification within scope.
- Ask a question only when a missing choice would materially change the public
  API, scientific result, package ownership, dependency structure, or data
  compatibility.
- Do not hide uncertainty. Separate verified behaviour from inference.
- Prefer a small, complete change over a broad partial refactor.

## Completion report

At the end of a task, report concisely:

1. what changed and why;
2. affected packages and public functions;
3. compatibility or scientific decisions;
4. documentation and tests added or changed;
5. commands run and their results;
6. any checks not run, remaining warnings, or follow-up risks.

A task is not complete merely because code was written. It is complete when the
requested behaviour is implemented, documented, tested, checked at the
appropriate package level, and the remaining limitations are made explicit.
