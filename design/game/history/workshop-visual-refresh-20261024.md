# Workshop visual refresh — 2026-10-24

The user requested a minimal, practical engineering workshop with improved lighting,
less visual crowding, and removal of prolific overlapping-surface flicker. They
explicitly limited the scope to the workshop; robot source models remain unchanged.
They requested screenshots, targeted checks only, and a commit when complete.

## Presentation

Pale walls, a muted protective wall band, matte graphite/grey equipment, and
restrained safety yellow replace the teal-heavy palette. Broad neutral light and
lighter shadows improve working contrast. The interior lighting key excludes the
roof/truss shadow casters; four broad fill lights keep the M3 room within the
Compatibility renderer's per-mesh light limit. Existing model materials are preserved.

Short floor corner marks replace full bay outlines. Compact labels on posts replace
large floating bay boards; rack instructions are shortened to identifiers, sign text
fits its plate, and large room identifiers sit against the walls. Equipment routes,
station locations, interfaces and recipes are unchanged.

Coplanar repairs include wall corners, floor inserts, crane/gantry butt joints,
clamp links, telescoping decks, folding guards, cradle members and personnel rails.
Small rendered section/reveal adjustments preserve existing collision envelopes
where motion/support depends on them. Authored structural butt joints are reflected
in the generator and generated layout together. No depth-test bypass or render-order
trick hides the defects.

## Screenshots

- [Room overview](../../../docs/images/workshop-engineering-overview.png)
- [Limb station and rail](../../../docs/images/workshop-engineering-limb-bay.png)
- [Final assembly gantry](../../../docs/images/workshop-engineering-gantry.png)

## Evidence and limits

**Surface geometry:** `workshop_style_audit.gd` passes 14 checks: 13 sampled poses
(initial, five access-fold phases, four fixture inserts, three cradle/lift phases)
and a negative control that injects a duplicate floor insert. Each pose inspects
987–993 generated workshop meshes, excluding robot source mesh resources. No
same-facing overlapping triangles within 0.25 mm remain in these poses. The initial
primitive-only audit found 142 overlapping pairs. This is sampled geometry evidence,
not an exhaustive proof of every possible equipment configuration.

**Rendered inspection:** Godot 4.7.2, OpenGL Compatibility on Apple M2. The final
capture set contains five room views, twelve moving-camera rail/floor views and two
identical-camera repeats. The repeated frames are pixel-identical. Inspected views
show clean floor inserts/joints without visible z-fighting, open floor space and the
intended restrained palette. Captures retain input hashes and unchanged-input proof
in `game/workshop/verification/workshop-engineering-delivery-2026-10-24T23-29-40-581141/`.
The directory also holds `camera-motion.gif`; the geometry report is
`game/workshop/verification/style-surfaces.json`.

**Targeted mechanical checks:** mobile platform 113 checks; shared access platforms
43; personnel lift 30; base-workshop geometry 21 checks across 17 poses; default and
M3 startup. Authoring regeneration matches byte-for-byte; whitespace check passes.
An initial parallel lift run hit a Jolt job-system stall; the sequential retry passed.
The old `m3_geometry_test` still references retired `hip_lift` and errors before its
assertions; it is not claimed as passing. No full regression or walked acceptance
run was performed.

**Player response:** pending. Rendered inspection is not user acceptance of the style,
label usability, walking/reach, or wider M3 workflow. Preserve the earlier positive
rail/lift scale and handling feedback when iterating.

Reproduce the focused surface audit:

```sh
./play.command --headless --script tests/workshop_style_audit.gd
```

Reproduce rendered M3 captures:

```sh
./play.command --windowed --resolution 1440x900 --disable-render-loop --fixed-fps 60 \
  --script tests/workshop_visual_review.gd -- --m3-workshop --review-tag=engineering
```
