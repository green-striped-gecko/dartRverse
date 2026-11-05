# Golden fixtures — self-test for this skill

Each fixture is a real, historical defect with a known pre-fix commit.
To self-test after editing the skill or the conventions catalogue: check
out the function's pre-fix state (`git show <pre-fix>:R/<file>` into a
scratch copy), run Phase A on it, and confirm the review finds the listed
defect with at least the listed severity. A fixture the review misses is a
regression in the skill — fix the skill, not the fixture.

| Fixture | Pre-fix state | Defect the review must find | Expected class | Min severity |
|---|---|---|---|---|
| `gl.filter.overshoot` | parent of `8070db1` | filter kept overshoot loci instead of removing them | Spec axis: inverted filter logic | BLOCKER |
| `utils.het.report.r` (pop.het) | parent of `e288a06` | per-individual `n_loc` recycled against per-locus vector, corrupting adjusted Ho | DAT2 metadata/vector sync | HIGH |
| `gl.test.heterozygosity` | parent of `a018871` | `plot.out = FALSE` returned empty results | PLT3 results coupled to plotting | HIGH |
| `gl.read.csv` | parent of `f13efcb` | `gen2fbm` ran unconditionally and wiped ploidy | DAT1 ploidy integrity | HIGH |
| `gl.filter.hamming` | parent of `a67aa07` | legacy proportion threshold (0<t<1) silently truncated to 0 by Rcpp int coercion | API1 silent semantic change | HIGH |

Negative fixture discipline: when a shipped review misses a real defect
that later surfaces, add the case here in the same commit as the skill fix,
so the miss can never recur silently.
