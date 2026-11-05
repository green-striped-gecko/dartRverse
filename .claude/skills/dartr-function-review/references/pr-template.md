# Merge request structure and tone

One function per MR, from `dev_<name>` into `dev` (GIT1/GIT4). The MR is
the campaign's public artifact: a custodian who never saw the review
session must be able to judge the change from the MR alone.

## Title

House style, matching existing history:

- Bug-dominated change: `fix bug in <function>: <what was wrong, stated as the defect>`
  - `fix bug in gl.filter.overshoot: kept overshoot loci instead of removing them`
- Broader improvement: `improve <function>: <2–4 word summary of the areas>`
  - `improve gl.filter.hamming: guards, call-rate-safe dedup, no densification`
- Docs only: `docs: <function> <what changed>`
- New function: `add <function>: <what it does>`
  - `add gl.report.foo: per-population foo statistic`

Lower case after the colon, no full stop, no "various fixes", no emoji.

## Body structure

```
## What changed
One bullet per applied change, in the order of the report's approved list,
each ending with its finding IDs: "guard proportion-style thresholds with
a migration error (F1)". Unapproved/deferred findings are NOT silently
absent — see Review below.

## Why
Only where the reason is not obvious from What: the failure scenario in
one or two sentences, citing the rule class in words
("precondition gap: legacy threshold=0.2 was silently truncated to 0").

## Evidence
The verification that was actually run, with concrete numbers:
- characterization test result (diffs mapped to approved changes, or "no
  behavioral diff")
- before/after output for the failing case
- property checks where used ("brute-force pairwise check: min Hamming
  among kept loci = 4, threshold 3")

## API impact
Present ALWAYS, even as "None." For a new function: "New exported
function; no existing callers." If not none: what changes for existing
callers, the guard added for old-style calls, the NEWS entry, and the
result of the sibling-package/dartr2shiny caller grep.

## Review
Link to the report file. One line: "N findings; approved 1,3,4 by <member>;
2 rejected (intended behavior), 5 deferred." Deferred items keep living in
the report, not in the MR.
```

## Tone

All MR prose follows `references/style.md` (Google Developer
Documentation Style Guide base layer + campaign deltas: evidence before
assertion, impersonal defects, no AI attribution decoration, under a
minute to read). This file owns structure only.
