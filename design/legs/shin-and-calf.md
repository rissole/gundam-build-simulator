# Shin and calf

Last updated: 2026-10-24

[Design index](../../ROBOT_DESIGN.md) · [Shared design rules](../global.md)

The right leg will mirror this design.

Connected assemblies and clearance checks: [foot and ankle](foot-and-ankle.md), [knee](knee.md).

Dimensions and reference pose: [shared proportion layout](../proportions.md#legs-and-feet).

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
