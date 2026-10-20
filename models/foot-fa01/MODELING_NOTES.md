# FA-01-3D-01 modeling decisions

Source: the [FA-01 written design](../../design/legs/foot-and-ankle.md), its [dimensions](../../design/legs/foot-and-ankle/dimensions.md), [inventory](../../design/legs/foot-and-ankle/parts.md), and [reference sheets](../../design/legs/foot-and-ankle/images/README.md).

The written design governs the model where generated drawings disagree. All 745 inventory objects have their own mesh datablock, identifier and animation. Integral bosses, tabs, braces and features belong to their parent component. Motor/gearbox/controller/connector cartridges retain the module boundaries already defined in FA-01.

## Dimensions resolved during modeling

1. **Nut-plate variants.** The earlier generic 80 mm thread pitch did not match all recorded frame hole coordinates. The ten plates now have four 100 mm-pitch rear crossmember variants, two 200 mm-pitch cradle variants, and four 80 mm-pitch forefoot variants. Plate lengths are pitch + 80 mm; width and thickness remain 80 and 54 mm. Quantities and hardware families are unchanged.
2. **Toe roof and nose.** The original single slope from Z600 to Z400 intersected the front M36 bolt heads, which reach Z472. The modeled roof runs from Y1340/Z600 to Y2145/Z520, then forms a short chisel nose down to Y2200/Z400. Its 20 mm underside clears the front bolt heads by at least 28 mm over the crossmember. The 3000 mm overall length, 1300 mm guard width and 400 mm front-tip height are preserved.
3. **Forefoot axle-cap receivers.** Local receiver ears extend the fixed hinge supports to accommodate the two cap screws. These are integral front-crossmember features, not new inventory parts. The earlier simplified toe-sweep envelope does not include these detailed ears.
4. **Clevis mounting arms.** All six clevises now have individually shaped integral arms reaching their owning frame/ring/adapter. The roll actuator's adapter-side bracket attaches to the rear face below the shin flange, preserving the flange's mating surface.
5. **Armor receivers.** Integral standoffs and receiver bosses connect panel fasteners to the existing rails or cradle. Each shell has four captive bolts, washers and separate retaining collars. Side and rear heads are recessed within the exterior envelope.
6. **Standalone shin interface.** The four interface bolts are displayed seated at the exposed adapter flange for the standalone foot inventory. They require the documented additional 30 mm shin baseplate stack when the leg is modeled; no shin part is included in the 745-object foot.

## Modeling scope

- Renderable polygon meshes with real thickness, bores, hollow housings, sleeves, bolt sockets, external threads, tread grooves, internal actuator parts and cable/connector geometry.
- Individually editable objects and unique mesh datablocks, including identical fasteners.
- Integral manufactured features can contain overlapping mesh shells within their single component. This is a visualization/animation asset, not a manifold fabrication or 3D-printing package.
- External fasteners and lead screws have geometric threads. Internal tapped holes use cylindrical bores; manufacturing thread fits and tolerances are not represented.
- Actuators include the agreed separate motor, gearbox, screw, nut, rod, bearing, guide, seal, sensor, cap and eye objects. Internal gears, windings and individual circuit components remain manufactured-module detail.

## Animation

The sequence begins with the parts separated, builds the foot in its documented order, holds the assembled foot, and reverses into an exploded view. All parts retain their identity throughout; the animation uses translation keyframes, without swapping a combined mesh for separate pieces.

The ankle core and actuator internals assemble at temporary offset positions and then transfer into the foot. The camera follows the bounds of the actual animated geometry, preserving all parts in frame. Stage captions are presentation objects and are excluded from the 745-part exports.

Assembly paths are an explanatory animation. They do not certify collision-free tool access, flexible cable deformation, real fastener driving, structural strength or operation of the robot's articulation. The assembled-position and exploded-position checks are separate from those engineering questions.
