# Writing style for campaign outputs

The single tone/style authority for everything this skill writes: report
text, the chat presentation of a review, and MR titles/bodies.
`report-contract.md` and `pr-template.md` define *structure*; this file
defines *how the prose reads*. When they seem to conflict, structure files
win on structure, this file wins on wording.

## Base layer

Follow the **Google Developer Documentation Style Guide**
(https://developers.google.com/style) — you know it; apply it. The
load-bearing subset for this campaign:

- Active voice, present tense, second person where a reader acts.
- Sentence-case headings; one consistent term per concept (pick "locus
  metrics" or "loc.metrics" per artifact and stay with it).
- Code font for anything the reader types or the code contains:
  function names, arguments, values, filenames (`gl.report.callrate`,
  `verbose = 0`, `loc.metrics`).
- One main action or claim per sentence; conditions before instructions
  ("If the object is FBM-backed, skip the densification check").
- No promotional or filler language: "simply", "easily", "powerful",
  "robust", "seamless", "comprehensive" — delete on sight.
- No fake certainty: separate current behavior from proposed behavior;
  never report an untested procedure as working; where something could
  not be verified, say so instead of filling the gap.

## Campaign deltas (override the base where they differ)

- **Audience**: the function's custodian — a population geneticist and
  R author, often the original writer of the code (conventions STY5).
  Expand or avoid R-internals jargon; keep genetics vocabulary.
- **Impersonal defects**: findings and MR text state what the code does,
  never what a person did. "The loop recycles the vector", not "you/the
  author recycled the vector".
- **Evidence before assertion**: every claim of breakage has a failure
  scenario; every claim of fixing has a rerunnable check. "Faster" is a
  number or it is omitted. "Should now work" is banned — show the run.
- **Lead with the verdict/outcome**, then support. In chat, the first
  sentence answers "what did you find?".
- **Preserve technical tokens verbatim**: rule IDs (DAT2), finding IDs
  (F3), severities, commit SHAs, argument names, quoted output. Never
  paraphrase these.
- **British/Australian spelling** in prose (colour, behaviour) except
  inside code, output quotes, and API names.
- **No AI attribution decoration**: no generated-with footers, no emoji,
  no model name in MR bodies or commit messages. Provenance lives in the
  report's header, where it is auditable.

## AI-tells to remove before delivering

Audit your own draft and rewrite any of these:

- Hedged openers and throat-clearing ("It's worth noting that",
  "Interestingly,").
- Rule-of-three padding ("clear, concise, and consistent") where one
  precise word carries the meaning.
- Empty abstract assertions ("this improves maintainability") without the
  concrete mechanism — say what changes for whom.
- Symmetrical contrast filler ("it's not just X, it's Y").
- Uniform sentence length; vary it, keep paragraphs short.
- Summaries that restate what the reader just read.

## Per-surface notes

**Report findings** — a finding is: claim, location, failure scenario,
proposed change; in that order, no narrative between them. Severity words
(BLOCKER…INFO) do the emphasis; adjectives do not. One "what works well"
line in the verdict section is enough praise when deserved.

**Chat presentation (Phase A hand-off)** — under a minute to read:
verdicts first with one driving sentence, then the findings table
(# / Issue / What happens / Proposed fix / Severity — one line per cell,
consequences in plain words), then the approval boxes, all in one turn.
Route detail to the report file; do not paste it into chat. A member
should be able to decide from the table alone; the report exists for the
member who wants the evidence.

The boxes appear over the table, so they repeat what the member needs
rather than pointing back at it. "Change 1 (see table)" is a failure;
"Restrict gl.Ho to SNP data. gl.Ho() on a SilicoDArT object stops
returning a value and errors instead" is what a question text should say.
Keep each option description to the outcome of choosing it.

**MR bodies** — structure per `pr-template.md`; readable in under a
minute; detail beyond that belongs in the linked report. State skipped
checks in Evidence with the reason — an MR that hides a skipped check is
worse than a smaller MR.
