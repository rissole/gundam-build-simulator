# 03 — Reuse interchangeable standard hardware

Status: implemented 2026-10-26; mechanical checks recorded in the
[implementation evidence](README.md#implementation-evidence--2026-10-26).
Player recheck and detail-pass obligations below remain open. The work order is
retained as the original scope, not an instruction to repeat completed work.

## Problem and design constraint

`LG-W24` appears interchangeable with existing `W-24`. The player requests that
build-specific duplicates stop proliferating. Reuse is based on actual fit and
function, not merely matching names or nominal bolt diameter.

Current sources: `author_leg_prototype.py` defines `lg-w24` / `LG-W24` and
`lg-w12` / `LG-W12`. `pitch-actuator-definitions.json` has the existing `washer`
kind with family `W-24`. Existing source meshes can have baked orientations that
differ between instances. Keep physical instance identity separate from type.

## Sources and implementation

Read the assembly-review skill and relevant foot hardware/interface documents,
`leg-prototype-interface.md`, `tools/author_leg_prototype.py`,
`tools/author_pitch_actuator.py`, `tools/author_hip_interfaces.py`, source manifests,
and `scripts/assembly_model.gd`, `part_storage.gd`, `workshop_content.gd`.

1. Compare W-24/LG-W24 inner/outer diameter, thickness, bearing surface, material
   or other specified fit distinctions, authored collision and installed poses.
   Resolve accidental prototype mismatches to the established standard where
   they do not encode a real interface requirement; record the evidence.
2. Merge compatible copies into the existing canonical type, stock location and
   pocket stack. All compatible slots accept any physical copy. Preserve exact
   consumed identity and slot-specific source/pose when fitting or undoing.
3. Update generators, generated definitions/content, manuals, storage labels,
   diagrams and stock quantities together. Do not merely rename the UI while
   keeping incompatible hidden stock pools. Do not delete needed physical copies.
4. Perform a bounded audit of other standard hardware introduced by the leg/hip
   generators, particularly LG-W12. Merge proven duplicates in this same family
   repair; retain genuinely different screw lengths, heads or fits with explicit
   functional labels. Record unresolved engineering differences for detailing.
5. Put a reusable authoring rule/check at the shared generation/audit boundary:
   check the existing catalogue before registering standard hardware, and reject
   demonstrated duplicate specifications. Do not guess equivalence from a name
   or force an unrelated full catalogue migration.

## Acceptance and verification

- Proven equivalent M24 copies share one user-facing type, drawer and pocket
  stack across foot, leg and hip. Current quantities remain sufficient for both
  legs and all original foot uses.
- Swapped source copies install correctly at each affected orientation, including
  upward hip and downward fork interfaces; washers bear on the correct face.
- Wrong-size or otherwise incompatible hardware remains rejected. Undo returns
  the consumed copy and restores stock counts without duplication.
- Run the generator's check mode and relevant `part_variants_test`,
  `assembly_model_test`, `pockets_model_test`, `leg_content_test`,
  `robot_content_test`, `pitch_interface_test` and `source_assets` through the
  routine runner as affected. Add a small cross-build interchangeability case.
- Human recheck: collect standard washers once and use them on foot and leg/hip
  work without choosing a build-specific duplicate.

Record measured equivalence and any remaining differences in the existing
component/interface documents. Detailed component work must consult this shared
catalogue; it must not reintroduce prefixes as new fit categories.
