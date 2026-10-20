# Shin and calf

Last updated: 2026-10-20

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

## Open design work

### Shin and calf refinement

- Beam cross-section and exact frame geometry.
- Thruster size, spacing, mounting points, and nozzle angles.
- Rear shroud shape, vent placement, service access, and panel retention.
- Internal connections and cable or pipe routing, where useful to the design.
- Knee interface and detailed lower-beam geometry for the accepted four-bolt keyed ankle flange.
