# Report contract

Every function review emits the same backbone, so 200 reports are
comparable, citable, and machine-aggregable. File:
`function-review/reports/<package>/<function>.md`. Do not drop sections —
an empty section says "checked, nothing found", which is information;
a missing section says nothing.

## Sections, in order

### 1. Header

```
# Review: gl.filter.hamming (dartR.base)
- Family mode: modify
- Origin: existing   (or: new — contributed by <member>)
- Date: 2026-08-21
- Reviewer: Claude (<model>), dartr-function-review v1.0.0
- Package commit: <short SHA of the reviewed state>
- Datasets: platypus.gl, testset.gl
- Baseline: tests/testthat/test-gl.filter.hamming.R (snapshot captured pre-review)
```

### 2. Verdict callout

Two verdicts, never blended, each from the enum
**Ready / Needs work / Rework**, plus one plain-language sentence each:

```
**Standards: Needs work** — structure and conventions largely conform; two
guard gaps and one memory hazard.
**Spec: Rework** — the documented threshold semantics do not match behavior;
results silently change for legacy callers.
```

`Ready` = merge as is or with trivial fixes. `Needs work` = specific,
bounded fixes required. `Rework` = the approach or contract is wrong;
fixing exceeds the finding list.

### 3. Findings

Numbered `F1…Fn`, ordered most severe first. Each finding:

```
**F3 [HIGH, confidence: high] — precondition gap (DEP1)**
`R/gl.filter.hamming.r:97` — Rcpp is called without a requireNamespace
guard; on a machine without Rcpp the user gets an opaque namespace error.
Failure scenario: fresh install without Suggests; any call fails
uninformatively.
Proposed change: add the DEP1 guard idiom before first use.
```

Rules: severity from BLOCKER / HIGH / MEDIUM / LOW / INFO (one scale, no
per-axis scales); confidence high / medium / low; every finding cites a
rule ID from `dartr-conventions.md` (or names a principle explicitly when
no rule fits — that gap is itself worth reporting to the skill maintainer);
every finding has a concrete failure scenario — "could be cleaner" is not
a finding, it is a note; findings against `[proposed]` rules carry the tag
`(proposed rule)` and are never BLOCKER.

### 4. Proposed changes

The approvable unit. Numbered list `1…n`, each mapping to one or more
findings, each independently applicable and described as a change, not a
diff ("add proportion-threshold guard erroring with migration message
(F1)"). If two changes are inseparable, make them one item. API-affecting
items (API1–3) end with the explicit consequence line:
"**Consequence: numerical output changes for <case>.**"

### 5. Coverage

Checks run and checks skipped, skips with reasons — never silent:

```
- Standards walk: FS, DOC, VRB, DAT, DEP, PLT, STY — run
- Spec: behavior vs roxygen on platypus.gl — run
- FBM path (DAT6): SKIPPED — no FBM fixture available for this function
```

### 6. Approval (filled in Phase B)

```
| Change | Decision | By | Note |
|---|---|---|---|
| 1 | approved | Luis | |
| 2 | rejected | Luis | intended behavior, docs to be fixed instead |
| 3 | deferred | Luis | revisit after gl.report.hamming port |
```

### 7. Outcome (filled in Phase C)

One line per applied change with evidence pointer, snapshot result
(diffs mapped to approved changes), PR number.

### 8. Machine block

Last fenced block in the file, JSON, mirroring the human sections — the
manifest and any dashboard aggregate from this, so it must agree with the
prose:

```json
{
  "function": "gl.filter.hamming",
  "package": "dartR.base",
  "family": "modify",
  "origin": "existing",
  "skill_version": "1.0.0",
  "commit": "<sha>",
  "verdict_standards": "needs_work",
  "verdict_spec": "rework",
  "findings": [
    {"id": "F1", "severity": "HIGH", "confidence": "high", "rule": "API1",
     "status": "approved", "change": 1}
  ],
  "coverage_skipped": ["DAT6: no FBM fixture"],
  "status": "pr-open",
  "pr": 236
}
```

## Tone

All report prose follows `references/style.md` (Google Developer
Documentation Style Guide base layer + campaign deltas). This file owns
structure only.
