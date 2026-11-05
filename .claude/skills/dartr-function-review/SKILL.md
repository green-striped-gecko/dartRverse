---
name: dartr-function-review
description: Standardized review-and-improve workflow for a single dartRverse function (gl.*, utils.*), existing or new. Use when asked to review, improve, debug, audit, or standardize a dartR function as part of the function-review campaign, e.g. "review gl.report.callrate", "run the function review on gl.impute", "next function in the manifest" — and when a dartR member wants to add a function they have already written to a dartR.* package, e.g. "add my gl.foo from ~/foo.R to dartR.popgen", "format my new function for dartR", "contribute this function". Produces an advisory report first; changes are applied only after a dartR team member approves specific findings.
version: 3.0.0
---

# dartR function review

One invocation = one function, end to end: claim → baseline → review →
report → human approval → apply approved changes → verify → PR.

Two entries, one workflow. An **existing** function is already in a
dartR.* package. A **new** function is one a dartR member has written and
tested on their own and wants added to a package: it goes through Intake
first, then the same Phases A–C. The review never changes what the
member's code computes without approval; formatting it to house
conventions is the bulk of the work.

**The prime rule: the review is advisory.** Phase A never edits the function.
No change — however obvious — is applied until a dartR member has approved
that specific finding in Phase B. Mid-apply discoveries go back through a
report addendum, not straight into code.

Rules of record: `references/dartr-conventions.md` (cite rules by ID in every
finding; `[proposed]` rules generate findings labelled "proposed rule", never
BLOCKERs). Report format: `references/report-contract.md`. Commit/PR format:
`references/pr-template.md`. Prose style for reports, chat hand-offs, and
MRs: `references/style.md` — read it before writing any of the three.

## Intake — new functions only

Skip this section for a function already in a package.

1. **Ask for what is missing** (one short message, only for items not
   already given): path to the member's file, target package
   (`dartR.base`, `dartR.popgen`, …), and one sentence on what the
   function should do. That sentence is the Spec axis reference when the
   file has no roxygen documentation.
2. **Check the name is free.** Grep all `dartR.*` checkouts for an
   existing function or file of the same name; if one exists, stop and
   report it — this is then a review of that function, not a new one.
3. **Place the file unchanged.** Sync `dev_<name>` with `origin/dev`
   (GIT2), copy the member's file to `R/<function>.R` exactly as given,
   and commit nothing yet. The member's code as written is the baseline
   every later change is measured against.
4. **Manifest row** `function,package,family,claimed_by,status` with
   status `new`, claimed by the member. Then continue at Phase A step 2.

## Phase A — Review (read-only)

1. **Sync and claim** (existing functions; new functions did this in Intake). Ensure the local `dev_<name>` branch is synced with
   `origin/dev` (conventions GIT2). Open `function-review/manifest.csv` on
   `dev`; if the function is claimed by someone else, stop and report that.
   Otherwise add/update its row: `function,package,family,claimed_by,status`
   with status `in-review`.

2. **Classify the family mode.** It selects the family-specific checks below:

   | Mode | Functions | Extra focus |
   |---|---|---|
   | `report` | `gl.report.*`, diagnostics | Read-only: input object must come back untouched; no history append (FS8); results independent of plotting (PLT3) |
   | `modify` | `gl.filter.*`, `gl.keep/drop/recode/subsample.*`, `gl.impute` | Genotype–metadata sync (DAT2/DAT3), flags (DAT4), history (FS8), filter does what its name says |
   | `io` | `gl.read.*`, `gl.*2*`, `gl.save/load.*` | Object construction: ploidy (DAT1), loc/ind.metrics completeness, compliance (DAT5), file handling across platforms |
   | `analysis` | `gl.dist.*`, `gl.pcoa.*`, `gl.tree.*`, popgen stats, `utils.*` | Numerical correctness against an independent computation; SNP vs SilicoDArT dispatch; NA handling |

3. **Snapshot baseline (before reading the code critically).** Write a
   characterization test to `tests/testthat/test-<function>.R` capturing
   current outputs on `testset.gl`/`testset.gs` (and `platypus.gl` where
   metrics like TrimmedSequence are needed): returned object dimensions,
   ploidy, key numerical values, loc/ind.metrics row counts. Snapshot what
   the function DOES today, bugs included — the baseline detects change, it
   does not assert correctness. For a new function, the baseline is the
   member's code as placed in Intake step 3; load it with
   `devtools::load_all()` so it runs against the package's own helpers. If output is stochastic, set a seed; if a
   snapshot is impracticable (pure plotting, interactive), record that in
   the report's Coverage section with a reason — never silently skip.

4. **Run the review.** Two independent axes, never blended:
   - **Standards axis** (is it built right?): walk the conventions
     catalogue — FS structure order, DOC completeness, VRB gating, DAT
     integrity, DEP guards, PLT idioms, STY — plus the family checks above.
   - **Spec axis** (is it the right thing?): does actual behavior match the
     roxygen documentation, the function's name, and its `@description`?
     Test claims empirically with `devtools::load_all()` on reference data.
     Check the dartR Google Group / GitHub issues if a known complaint
     exists about this function. For a new function, compare behaviour with
     the member's roxygen if present, otherwise with the one-sentence
     purpose from Intake; a missing roxygen block is a DOC finding, not a
     Spec finding.
   Apply the recurring-bug lenses (the historical classes in DAT/PLT rules):
   ploidy loss, metadata desync, plot/results coupling, inverted filter
   logic, platform-specific calls, FBM densification, silent API traps.
   For every finding: severity, confidence, rule ID, `file:line`, a concrete
   failure scenario, and a proposed change. False-positive discipline: when
   a rule and clearly-newer code intent disagree, flag the rule, not the
   code; do not flag what a linter or R CMD check already enforces.

5. **Write the report** to `function-review/reports/<package>/<function>.md`
   following `references/report-contract.md`, including the machine-readable
   JSON block. Update manifest status to `awaiting-approval`.

6. **Present on screen** (the member has minutes, not an hour; plain
   language per `references/style.md`):
   a. The two verdicts plus one sentence saying what drives them, and a
      line stating that the full report was generated with its path
      ("Full report: `function-review/reports/<package>/<function>.md`")
      so the member knows the table is the summary, not the record.
   b. The findings table — one row per proposed change, one line per cell:

      | # | Issue | What happens | Proposed fix | Severity |

      "What happens" is the consequence in plain words (the failure
      scenario compressed), not a code description. Docs-only changes can
      be flagged in the fix cell.
   c. **Approval boxes** via the AskUserQuestion tool, multiSelect, option
      label = change number + short name, option description = the
      consequence. Group changes into questions of at most 4 options
      (by severity or theme). Changes crossing the escalation gate
      (API1–3, any user-visible behavior change) get their OWN question
      whose text states the consequence explicitly — approval of the
      consequence, not just the fix. The member can always answer in
      free text instead ("apply 1 and 3, defer the rest").
      **New functions:** all changes that cannot alter output, arguments or
      accepted input (roxygen, preamble order, verbosity messages, style)
      go into ONE question with one option, "Apply house formatting
      (changes N–M)", so the member is not asked twenty times. Everything
      else is boxed as for an existing function.

   **Sequencing (hard rule):** print (a–b), then call AskUserQuestion, in
   ONE turn. Never end the turn after the table and wait to be asked for
   the boxes — a member who has to type "show me the boxes" to approve
   their own review is being made to do the skill's work.

   The dialog covers the table while it is open, so the boxes carry their
   own context: each question text names the change and states what
   happens if it is applied, and each option description states what that
   choice does. Write them so a member who never scrolls back to the table
   can still decide. The table stays on screen as the summary; the report
   file stays as the evidence.
   **Stop after the boxes are answered or the member replies.**

## Phase B — Approval (human)

Decisions arrive as AskUserQuestion selections or free text ("apply 1, 3,
4", "all except 2", "2 but only the guard, not the rename"). Record the
decision per finding in the report's Approval section (approved / rejected /
deferred, with any modification verbatim). Nothing else in this phase.

## Phase C — Apply (approved findings only)

1. Implement approved changes exactly as scoped; conventions apply to the
   new code (this skill's own output must pass its own review).
2. **Verify**: run the characterization test. Every diff from baseline must
   map to an approved finding — an unexplained diff is a defect in the fix;
   stop and report it. Update snapshots only for approved behavior changes.
   Run `devtools::document()` if any roxygen changed; run the function on
   reference data at `verbose = 3` end to end.
   **New functions** also: confirm `@export` and the NAMESPACE entry after
   `devtools::document()`; add a NEWS entry under the development version
   ("New function `gl.foo()` …", crediting the member); run
   `devtools::check()` and report any NOTE/WARNING/ERROR the new file
   introduces. The PR title is `add <function>: <what it does>`.
3. If applying reveals a new problem: do not fix it opportunistically.
   Add it to the report as an addendum finding and ask for approval
   (a one-line ask in chat is enough).
4. Commit and open a PR to `dev` per `references/pr-template.md` — one
   function per PR. **Before committing, check whether an open PR already
   exists from `dev_<name>` to `dev`** (`gh pr list --head dev_<name>`):
   if it does, branch from `origin/dev` (e.g. `review-<function>`) and
   commit there instead — a second commit pushed to `dev_<name>` lands in
   the existing PR and bundles two concerns.

   **Pre-push gate:** before committing/pushing anything, print on screen
   the full commit message and the PR title, as the final text of the turn
   (same sequencing rule as the findings table — no tool call after it),
   and wait for the member's OK or edits. Commit, push, and open the PR
   only after that reply. Link the report in the PR body.
5. Update the manifest row: status `pr-open`, PR number. After merge:
   status `done`. (Status lifecycle: `new` for a new function or `in-review` for an
   existing one → `awaiting-approval` → `pr-open` → `done`.)

## Escalation gate (always, regardless of approvals)

Changes to an argument's meaning or default, to numerical output, or to a
function's signature (API1–API3) require the member's explicit approval of
that consequence stated in those words — "fix the bug" does not cover
"…and the results change". Before merging such a change, grep the sibling
`dartR.*` packages and dartr2shiny for callers, and add a NEWS entry.
A new function has no callers yet: its gate is the member's approval
alone, and the report says "caller grep: not applicable (new function)".

## Provenance and self-test

- Every report records: model, this skill's version (frontmatter), package
  commit SHA, datasets used, checks skipped + reasons. Unknown fields are
  written as `not available: <reason>`, never omitted.
- Golden fixtures: `references/fixtures.md` lists functions with known,
  documented defects (seeded or historical). After any edit to this skill
  or the conventions catalogue, re-run Phase A on one fixture and confirm
  each listed defect is still found; bump `version:` in the same commit
  (MAJOR: report contract or workflow change; MINOR: new checks; PATCH:
  wording).
