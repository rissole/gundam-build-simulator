# Shin and calf

Last updated: 2026-11-01

[Design index](../../ROBOT_DESIGN.md) · [Shared design rules](../global.md)

The right leg will mirror this design.

Connected assemblies and clearance checks: [foot and ankle](foot-and-ankle.md), [knee](knee.md).

Dimensions and reference pose: [shared proportion layout](../proportions.md#legs-and-feet).

> **Silhouette revision, 2026-11-01:** the [approved whole-robot silhouette](../../models/silhouette-mannequin/README.md) changes this component's envelope: calf armor up to 1.65 m wide, tapering to 1.06 m toward the ankle, 2.24 m deep including the thruster enclosure (was 1.40 / 0.90 / 1.90). Revised values are in [proportions](../proportions.md); the detailed interfaces below predate the revision and still need updating. Concept sheets: [LG-01](images/README.md); part numbers: [leg component list](leg-components.csv).

> **Modelled 2026-11-01:** [LG-01-3D-01](../../models/leg-lg01/README.md) includes the shin, twin engines and revised calf armor.
> Neutral interfaces and bounded calf/guard clearance pass; full articulation and workshop integration remain open.

## Model-settled working values — 2026-11-01

Coordinates are **leg-local metres**, ground origin beneath the ankle, +X inner,
+Y forward, +Z up. The older 900 × 900 lower-armor box and workshop transport
limits below are superseded for this model; the narrow structural beam and keyed
foot interface remain. The older sections are retained pending coordinated revision.

- Thruster seats are (0,−0.865296,4.025538) and (0,−0.865296,2.875538).
  Ø0.780 mouths have centres (0,−1.550,3.880)/(0,−1.550,2.730), pointing
  12° rearward/downward along (0,−0.978148,−0.207912). Measured calf depth,
  including mouths, is 2.231085; the rear limit remains Y−1.640.
- Upper cradle crown ends at Z4.500. The front armor saddle is Z4.360 at
  X±0.280, with Z4.600 shoulders. Two separate 920 mm shroud apertures retain
  a 900 × 220 mm bridge at Z3.305.
- Shin flange is 0.540 × 0.440 × 0.030 at Z1.380…1.410, with foot-owned
  M36 bolts at X±0.200/Y±0.150. The beam stays 0.300 × 0.200 through Z2.100,
  then expands to 0.640 × 0.620 by Z2.420. Exposed support faces are
  X±0.800/Y±0.140/Z2.690…2.910.
- Calf armor begins Z1.650; the lowest 300 mm measures 1.064912 wide.
  Against FA-02 inner guard walls at absolute X0.710, 3,321 poses give
  38.76 mm sampled clearance and a 6.495 mm continuous vertex/edge bound.
  This is not a complete swept-facet solid check or tool-access approval.

## Confirmed design

### Shin and calf structure

| Component | Confirmed concept |
| --- | --- |
| Structural shin beam | Continuous structural member connecting the knee to the ankle |
| Thruster cradle | Separate mounting structure behind the shin beam, supporting both thruster units |
| Front shin armor | A long front plate |
| Calf side armor | Removable side shells |
| Rear engine enclosure | Angular rear shroud, mostly covering the engine bodies |
| Central bridge panel | Removable armored bridge between the nozzle openings, concealing central mounting hardware |

The shin beam provides the main structural connection independently of the thruster cradle. The thrusters can be treated as separately installed components.

### Connection to the foot

The shin beam's lower end receives the ankle adapter's keyed flange, secured with four bolts. The adapter remains with the foot-side ankle mechanism when this connection is undone. See the [ankle construction and shin connection](foot-and-ankle.md#ankle-construction-and-shin-connection) for joint ownership and movement targets; the [FA-01 interface dimensions](foot-and-ankle/dimensions.md#shin-interface-and-access) now define the keyed flange and bolt access.

For this interface, use a 30 mm shin baseplate on the foot adapter at Z1380, with four M36 bolts at local X±200/Y±150. Keep the beam within 300 × 200 immediately above it. Lower shin armor begins at Z1650 and stays within a 900 × 900 envelope for its first 450 mm. These are assistant-selected interface constraints from the foot clearance review, to be preserved during calf detailing. The shin owns the electrical socket mating to the foot input lead.

### Calf thrusters

- **Purpose:** visual plausibility and aesthetic appeal. They do not need to provide actual movement or meet a flight-performance requirement.
- **Location:** back of each calf.
- **Count:** two per calf.
- **Arrangement:** vertically stacked, preserving a relatively slim leg.
- **Nozzle shape:** circular bell-shaped nozzles contrasting with the angular armor.
- **Enclosure:** engine bodies mostly housed; nozzle mouths exposed in angular recesses.
- **Openings:** two separate rear openings divided by the removable armored bridge panel.
- **Orientation:** nozzle mouths angled slightly rearward and downward; exact angles remain open.
- **Clearance intent:** keep the nozzle mouths visually clear of the ankle and heel, and keep the rear knee clear for articulation.
- **Supporting detail:** believable mounts, vents, and clearances. Exact pipe routes, vent geometry, and connections are not yet defined.

## Workshop support boundary — 2026-10-24

The [coordinated rail/cradle plan](../game/final-assembly-plan.md#shared-limb-workshop-with-different-departure-routes)
selects exposed structural side pads near robotX±0.80/Z2.80, tied into the
shin frame. C-shaped cradle yokes reach around the calf; the rear holder spine
lies at robotY−1.45, outside the selected calf rear bound−1.15 by 0.20 m.
Keep the complete stationary shin/calf transport envelope within X±0.80,
Y−1.15..+0.75, apart from specifically modeled moving joints. These are
workshop fit constraints to resolve against detailed armor/nozzles, not finished
thruster geometry. Do not support the leg on nozzles or actuator rods. Keep
these pads exposed after armor installation so holder release does not create
an unreachable low-level closure. The shared source fixture raises/rolls the
supported leg for rear work; return neutral before rail travel.

## Open design work

### Shin and calf refinement

- Beam cross-section and exact frame geometry.
- Thruster size, spacing, mounting points, and nozzle angles.
- Rear shroud shape, vent placement, service access, and panel retention.
- Internal connections and cable or pipe routing, where useful to the design.
- Knee interface and detailed lower-beam geometry for the accepted four-bolt keyed ankle flange.
