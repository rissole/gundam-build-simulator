# LG-01-3D-01 left leg model

Started 2026-11-01 · Branch `model/leg-lg01` · **In progress**

A high-definition, separately modelled left leg from the hip ball (Z 9.20) to
the sole, with the FA-02 foot and all armor, generated in Blender from Python,
plus a drag-to-scrub build timeline viewer.

## Scope

- Every part in the [leg component list](../../design/legs/leg-components.csv)
  and the FA-02 [foot component list](../../design/legs/foot-and-ankle/foot-components.csv)
  as a separate, named object with real thickness and its part number in the
  object's custom properties. Armor is on.
- The right leg is not delivered: mirroring is verified only.
- Out of scope: the Godot game, torso, arms, head, workshop clearances and
  fabrication-grade solids. The [FA-01 model](../foot-fa01/README.md) stays intact.

## Sources, highest authority first

1. [Proportions](../../design/proportions.md): joint heights and the
   2026-11-01 envelopes.
2. Component specifications: [thigh and hip](../../design/legs/thigh-and-hip.md),
   [knee](../../design/legs/knee.md), [shin and calf](../../design/legs/shin-and-calf.md),
   [foot and ankle](../../design/legs/foot-and-ankle.md) with its detail packet,
   and the [leg prototype interface](../../design/game/leg-prototype-interface.md).
   Joint centres and mating interfaces are kept; armor is fitted to the new envelopes.
3. [Style guide](../../design/visual-design/turnaround/README.md).
4. Concept images: [LG-01](../../design/legs/images/README.md) (with its known
   drawing errors), FA-02 and the [turnaround](../../design/visual-design/turnaround/turnaround-v3.jpg).
5. The [FA-01 model](../foot-fa01/README.md): generator code and lessons.

Where a lower source conflicts with a higher one, the higher source wins and the
conflict is recorded in [MODELING_NOTES.md](MODELING_NOTES.md). Questions raised
while modelling, with the default chosen, are in [OPEN_QUESTIONS.md](OPEN_QUESTIONS.md).

## Deliverables

To be completed as phases finish.
