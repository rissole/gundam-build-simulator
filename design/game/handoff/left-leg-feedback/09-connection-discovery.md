# 09 — Make connection discovery forgiving and explain blocked actions

Status: implemented 2026-10-26; mechanical checks recorded in the
[implementation evidence](README.md#implementation-evidence--2026-10-26).
Player recheck and detail-pass obligations below remain open. The work order is
retained as the original scope, not an instruction to repeat completed work.

## Problem and constraint

The player completed the left leg and enjoyed some of the challenge of finding
physical access for fastening. They also report cases where even the yellow
highlight is absent for no intuitive reason and request more line-of-sight
leniency. Preserve the useful access challenge while making discovery predictable
and failures understandable. This is not permission for remote fastening.

Task 04 fixes pickup surfaces. This task owns installation-slot discovery,
near-surface tolerance and feedback. Task 08 owns active-control guidance.

## Sources and implementation

Read `scripts/targeting.gd` (candidate scoring, `can_see`, discovery, access and
presentation), `component_interaction.gd` (candidate bounds, slot points,
receiving bodies and sight depth), `interaction_outline.gd`, authored connection
targets and `tests/targeting_candidates_test.gd` / `eye_bearing_access_test.gd`.

1. Map why a representative connection can disappear: range/bounds filtering,
   prerequisites, part compatibility, aim score, receiver self-occlusion, scenery
   or equipment access. Build small fixtures for identified failure modes. The
   user has not supplied exact screw IDs, so do not assert a specific slot caused
   all reported failures or run an automated whole-workshop access sweep.
2. Separate discovering a relevant nearby connection from permission to install.
   When a player aims at the visible workpiece, reveal useful connection context
   and a concise reason such as wrong part, finish another connection, move closer
   or obstruction. Use existing discovery-only guidance without a valid-place
   preview for blocked targets. Do not render hidden hardware through walls.
3. Improve aim tolerance and representative target points for exposed receiving
   surfaces. Correct coarse receiver proxies or narrowly scoped near-surface
   allowances where they reject a physically obvious approach. Avoid globally
   excluding an entire assembly from visibility or making every tolerance larger.
4. Keep final action checks live: reach, real obstructions, insertion approach,
   structural prerequisites and equipment state. Prompt, highlight and actual
   click should agree about what action is currently possible.
5. Preserve efficient candidate bounds, current moving/child target updates and
   stable priority among adjacent fasteners. Coordinate with task 04 before
   editing shared scoring and with task 08 before changing outlines.

## Acceptance and verification

- Slight aim offsets and an allowed shallow receiver surface no longer silently
  hide a relevant connection. Wrong part, out-of-reach and unmet prerequisite
  cases give understandable guidance when the workpiece is discoverable.
- True scenery occlusion or an inaccessible insertion path still blocks fitting;
  no global X-ray or remote assembly. Neighbouring connection selection is stable.
- Rotated/mounted components and dynamically articulated targets remain current.
  Discovery-only cues never become valid placement previews accidentally.
- Extend isolated `targeting_candidates_test`, `interaction_outline_test` and
  relevant `eye_bearing_access_test` fixtures. Verify selection, prompt and click
  outcomes together. No automated walked/visibility sweeps or rendered review.
- Human recheck: fasten several left-leg/hip connections from imperfect but
  plausible angles; record exact targets and positions for any remaining
  confusing failures. Ask whether the enjoyable access challenge survives.

Detail pass: every new connection needs a physically useful target and tool
approach. Record geometry-specific remaining failures in the component interface
document and playtest checklist; do not hide them behind unlimited tolerance.
