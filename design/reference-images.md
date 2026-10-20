# Reference-image requirements and workflow

Last updated: 2026-10-20

[Design index](../ROBOT_DESIGN.md) · [Shared design rules](global.md)

## Confirmed

- Engineering-diagram visual style.
- Images should preserve the agreed design across body sections.
- Design details should be developed before image generation.
- The references should support the eventual assembly-puzzle concept.

## Selected first foot sheets — FA-01

- Orthographic front, side, and rear views.
- Exploded assembly views.
- Internal-frame views and joint close-ups.
- Consistent part labels and assembly boundaries.
- Dimensions once the dimensional scheme is agreed.

For the first foot set, the user delegated recommendations and authorized generation. Use a landscape assembled-view sheet with orthographic views and a separate exploded construction sheet. Use white backgrounds, dark technical linework, pale gray armor, darker skeleton and restrained blue motion/dimension marks. These are drawing conventions, not a robot color decision. Keep dimensions in millimetres; include FA-01 and “CONCEPT REFERENCE” on sheets. Generated pictures are not guaranteed to print at an engineering scale. Subsequent sheets and the final robot paint remain open.

## Working method for preparing images

This is a documentation and generation workflow, not an additional set of confirmed robot-design decisions.

1. Use the [shared dimensional layout](proportions.md) for scale and pose. Resolve any further dimensions needed for the intended view, along with its assembly boundaries, and record choices before generating the image.
2. Read the shared design rules, relevant dimensional tables, the target component, and the relevant connection or clearance sections from neighboring components. The decision history is background, not an image prompt.
3. Assemble a focused image brief: required silhouette, confirmed parts, attachment relationships, selected views, and agreed dimensions or labels. Flag unresolved details rather than presenting them as approved specifications.
4. Once a whole-robot reference is approved, use it as a visual reference for subsequent sheets. Also use approved adjacent-component images when their shared interface matters. Track the source specification revision and reference image used for each sheet.
5. Review each result against the written design for part counts, joint ownership, installation order, proportions, and consistent geometry across views. Revise the image or discuss a design change before treating it as approved.

Separate files make the brief easier to select and maintain; they do not by themselves guarantee consistent image geometry. Generated diagrams are visual references. Written dimensions, part identifiers, and assembly decisions remain authoritative; exact fit and clearances would need later geometric validation.

## Generated image sets

- **FA-01 — Foot and ankle:** [selected sheets, exact prompts, source revision and image-review notes](legs/foot-and-ankle/images/README.md). Includes assembled views, structural explosion, and armor/sole/services. These are concept references awaiting user review. Known generated-image inconsistencies are recorded; the written design governs geometry and counts.
