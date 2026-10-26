# Launch cage v2 — dimensioned candidate, 2026-10-27

**Design only. Build not approved. The candidate is blocked.** The two-tower
concept cannot be treated as a build specification with these simple swing arms:
parked steel occupies the exit reservation, return paths narrow, the lowest
right landing meets a retained lift guide, and support/route clearances remain
unresolved. The checker deliberately returns **exit 1**. No robot datum, route,
shaft, service opening or bearing patch was moved to obtain a pass. This completes
C5 at its conflict stop; it does not approve a different topology or construction.

[plan.json](plan.json) is the sole proposed geometry/motion source.
[envelopes.json](envelopes.json) contains the measured baseline and explicitly
labelled derived reservations. The proposed steel is a dimensioned counterexample
and starting point for the decisions below, not a feasible finished cage.

Start with the four plans: [8.4](drawings/level-8.4.svg),
[11.2](drawings/level-11.2.svg), [14.0](drawings/level-14.svg),
[16.4](drawings/level-16.4.svg); then [front](drawings/front.svg),
[side with crane heights](drawings/side.svg), and [exit](drawings/exit-route.svg).
Each plan has a dimension register for every positive clearance below 0.30 m in
its height band. T-number links open enlarged spatial details; the complete
[tight-pair index](drawings/tight-index.json) identifies both solids, state and
measurement. Exact zero-margin face contacts remain in the full checker CSV.
SVGs are generated engineering drawings; no rendered game review was performed.

## 1. Datums and sources

World metres, X lateral, Y up, +Z aft. Mirror X about 13 using **X → 26−X**, with
Z unchanged. Front elevation looks +Z; side looks −X. All numerical fields in the
plan and all measured/derived envelope fields are enumerated in the generated
[complete numeric source table](datums.csv): JSON pointer, value and source.
This table is part of this section; a proposed coordinate is labelled a C5 design
choice, never presented as a measurement. Runtime rows additionally record their
stage and UTC time. The table below is the reading guide to that full register.

| Numbers / meaning | Value (m unless stated) | Source |
| --- | --- | --- |
| Hip datum; cap top; cap patches | (13,10.6,26); 10.97; X12.35/13.65, Z26.52..26.78 | `workshop-layout.json:workshop.robot`; measured `gantry_bearing_*`; generator lines 315ff |
| Hold-downs and waist locks | Four jaws; two twist/tilt locks | `module_supports.gd`; measured `gantry_jaw_*`; no replacement robot hardware |
| Shafts / cars / portals | Centres X6.6/19.4,Z29; shaft 3.20 square; car 2.60 square; portal Z28.5..30 = 1.50 | `workshop-layout.json:workshop.elevators`; `work_access_lift.gd:29-157`; individual runtime shape rows |
| Stops | **0.15**, 8.4, 11.2, 14, 16.4 | `workshop.elevators.*.levels`; ground stop is not Y0 |
| Required walking / landing / headroom / seam | 1.20 / 1.50 / 2.20 / ≤0.040 | C5 and concept; seam criterion from C1 |
| Design clearance margins | 0.100 generally; 0.020 to lift/retained hardware; 0 at exact portal faces and exit boundary | `plan.json:criteria`; margin applies after motion-envelope inflation |
| Leg corridor | X10.5..15.5,Z20.5..30.6; floor/bracing reservation through Y7.7 | `workshop.rail.corridor`; concept cradle height. Actual loaded rig reservations separately include its whole height |
| Upper service / aft well | X11.4..14.6,Z27.2..35.3, Y11.2..23; aft Z31.7..35.3 open Y0..23 | `final-assembly-plan.md:406-423`; never filled or moved |
| Outboard crane well | X22.8..25.2,Z31.7..34.7 | `workshop.crane.rear_well_bounds` |
| Mobile platform | Park (6.7,0,19.3); all authored route polylines; actual base/guard boxes | `workshop.mobile_platform`; probe `mobile/*`; standing rider allowance top Y2.35 explicitly proposed |
| Tower / deck / guard / foundation coordinates and sections | Every value in `design_choices` and all 310 `solids` rows | `plan.json`; candidate choices, with full values in `datums.csv` |
| All 10 pivots, radii, angles, tongues, locks, pockets | Every value in `motions`, `parking_pockets`, `seams` | `plan.json`; candidate choices, reflected exactly |
| Raised robot bounds, per component at each installed stage | 158 records; complete union approximately X8.669..17.331,Y1.400..19.400,Z23.810..28.190 | `envelopes.json:robot`; own runtime meshes, excluding child assembly roots |
| Loaded leg travel / tilt / rise | Both sides, path 0..3 every 0.05; 61 poses/side | `indexed_leg_rail.gd:259-279`, `leg_cradle.geometry`; runtime source geometry |
| Backpack sweep | Measured extrema Z30.086, Y16.490; 41 poses | `backpack_hinge.gd:_pose`; 10 mm interpolation enclosure retained |
| Core service kit | Pads X11.1/14.9,Z29.5/32.1; crossbeam top 12.60, upstands 13.05, withdrawal 5.0 | Concept only: **not present in runtime**; `missing_runtime_geometry` is not a fabricated measurement |
| Door | Visible clear frame X2.95..23.05,Y0..20.9; leaf Z38.72..38.84; collision aperture **absent** | `hangar_dressing.gd:282-289`; runtime `wall_z39` at Z38.85..39.15 |
| Crane carry rule | Head Y22.76 ordinary,22.61 cassette,22.53 arms; trolley underside22.875; head top allowance leaves0.025 | **Provisional (unmerged branch)** `b937dec` `service_crane.gd:40,120-137` |
| Crane per-task paths / orientations / entry / load and rig bounds | All 31 task rows, full authored positions and rotations, carry/source/entry boxes, adapter rig parts | **Provisional (unmerged branch)** `git show crane-operator-view:game/workshop/assets/workshop-layout.json`, branch controller and unchanged loaded adapter geometry |
| Section estimate inputs | 40,000 kg,9.81 m/s²,3.80 span,0.45×0.80 box,0.030 wall,E200 GPa | Explicit game-plausibility assumptions; not material or load certification |
| Exit allowance and lowering illustration | 0.30 each side/head/fore; 1.40 illustrative downward translation | C5 design allowance and measured sole height; no carrier or lowering design |

**Per-task crane dimensions — provisional (unmerged branch).** Highest spreader/hook and cable values below are measured from the appropriate full adapter rig, including the mast attachment. Full paths and orientation keys remain in the named envelope row.

| Task | Carry head Y | Lowest carried solid Y | Highest spreader/hook Y | Highest cable Y | Authored entry index / XYZ |
| --- | ---: | ---: | ---: | ---: | --- |
| `shin` | 22.760 | 21.600 | 22.850 | 23.000 | 2 / (14, 6, 10.995) |
| `fork` | 22.760 | 21.540 | 22.850 | 23.000 | 2 / (14, 6, 14.7) |
| `spar` | 22.760 | 21.319 | 22.850 | 23.000 | 2 / (14, 6, 15.54) |
| `right_shin` | 22.760 | 21.600 | 22.850 | 23.000 | 2 / (14, 6, 10.995) |
| `right_fork` | 22.760 | 21.540 | 22.850 | 23.000 | 2 / (14, 6, 14.7) |
| `right_spar` | 22.760 | 21.319 | 22.850 | 23.000 | 2 / (14, 6, 15.54) |
| `foot` | 22.760 | 20.820 | 22.850 | 23.000 | 3 / (14, 5.8, 6.3) |
| `right_foot` | 22.760 | 20.820 | 22.850 | 23.000 | 3 / (14, 5.8, 6.3) |
| `pelvis` | 22.760 | 19.250 | 22.850 | 23.000 | 2 / (13, 10.8, 13) |
| `chest_store` | 22.760 | 17.410 | 22.850 | 23.000 | 3 / (3.25, 6.2, 13) |
| `chest` | 22.760 | 17.410 | 22.850 | 23.000 | 2 / (13, 12.88, 13) |
| `core_store` | 22.760 | 20.540 | 22.850 | 23.000 | 3 / (3.25, 6, 13) |
| `core` | 22.760 | 20.540 | 22.850 | 23.000 | 6 / (13, 18.47, 32.4) |
| `backpack_store` | 22.760 | 20.615 | 22.850 | 23.000 | 3 / (3.25, 5.5, 13) |
| `backpack` | 22.760 | 20.615 | 22.850 | 23.000 | 6 / (13, 18, 31.8) |
| `cassette` | 22.610 | 19.430 | 22.850 | 23.000 | 2 / (14, 4.8, 9.9) |
| `left_arm` | 22.530 | 20.630 | 22.850 | 23.000 | 1 / (14, 9.6, 9.9) |
| `right_arm` | 22.530 | 20.630 | 22.850 | 23.000 | 1 / (14, 9.6, 9.9) |
| `right_arm_store` | 22.530 | 20.630 | 22.850 | 23.000 | 2 / (14, 4.8, -6.3) |
| `left_pauldron` | 22.760 | 20.230 | 22.850 | 23.000 | 3 / (10.79, 18.7, 13) |
| `right_pauldron` | 22.760 | 20.230 | 22.850 | 23.000 | 3 / (15.21, 18.7, 13) |
| `head_baseplate` | 22.760 | 20.762 | 22.850 | 23.000 | 2 / (13, 19, 13) |
| `head_baseplate_to_fixture` | 22.760 | 20.762 | 22.850 | 23.000 | 2 / (3.25, 6, 15.6) |
| `head_left` | 22.760 | 20.180 | 22.850 | 23.000 | 2 / (13, 18.88, 13) |
| `head_left_to_fixture` | 22.760 | 20.180 | 22.850 | 23.000 | 2 / (3.25, 6, 10.6) |
| `head_right` | 22.760 | 20.180 | 22.850 | 23.000 | 2 / (13, 18.88, 13) |
| `head_right_to_fixture` | 22.760 | 20.180 | 22.850 | 23.000 | 2 / (3.25, 6, 17.1) |
| `head_top` | 22.760 | 21.240 | 22.850 | 23.000 | 2 / (13, 17.44, 13) |
| `head_top_to_fixture` | 22.760 | 21.240 | 22.850 | 23.000 | 2 / (3.25, 6, 10.6) |
| `head_crown` | 22.760 | 21.000 | 22.850 | 23.000 | 2 / (13, 17.2, 13) |
| `head_crown_to_fixture` | 22.760 | 21.000 | 22.850 | 23.000 | 2 / (3.25, 6, 17.1) |

**Measurement method.** One final headless boot supplies all 16 boundaries:
foot, actuator, pelvis, left_leg_build, left_leg_dock, right_leg_build,
right_leg_dock, chest, core, backpack, left_arm, right_arm, pauldrons, head,
head_sensors, complete. Robot records start after the hip is supported on the
gantry. Compound parent colliders include children, so component bounds use
recursive actual meshes stopped at child assembly roots; collision geometry is
used for rail loads, holders, lifts, mobile platform and shell. This distinction
prevents pretending a compound hip collider describes just the hip.

The probe reads PhysicsServer3D transforms for blockout solids and actual enabled
shape transforms for equipment after `_pose()`. Lift motion is the vertical union
of **each individual car shape**, preserving the empty spaces between guide
carriages. Car doors retain their current no-landing-gates behavior. Closed car
gates remain within the deck's swept footprint. Arbitrary held-load overhang is
not measured; a future build still needs the shared passenger/cargo rules.

Rail envelopes join adjacent supplied poses with 30 mm inflation. The authored
sinusoidal pivot and ≤4.5° angular interval have <30 mm chord deviation even using
32 m radius; linear travel/rise adds no chord error. Backpack intervals use
10 mm inflation. These are conservative geometric enclosures, not movement tests.
The later core removal kit cannot be probed because it does not exist; current
core/chest geometry and crane guide rig are measured separately.

Crane measurements execute a read-only scratch copy of branch A's controller
against prepared runtime payloads. The cassette includes its retained arm;
core transport includes the attached bridge; adapters supply their own rig
solids. Measurement happens before those prepared sources are consumed.
Loaded adapter geometry agrees with branch A; its other adapter changes concern
empty-rig visual folding. This is **not a branch-A workshop boot or playtest**.
The highest hoist line reaches its authored Y23 attachment; that intentional
connection is distinct from the under-trolley spreader/hook allowance. Every
height/parking conclusion involving it remains **provisional (unmerged branch)**.

Reproduce from the repository root (only the import command needs an unimported
worktree, and C5 explicitly authorizes it once):

```sh
./play.command --headless --editor --import --quit
python3 design/game/gantry-v2/probe/run.py
python3 design/game/gantry-v2/check.py
# Expected exit 1 while the documented conflicts remain.
python3 design/game/gantry-v2/draw.py
```

`probe/run.py` uses `git show crane-operator-view:<path>`, never checks out or
edits that branch, and rejects script errors even if Godot returns zero.
`C5_GODOT` may override the local Godot executable. The actual `--script` source
is [c5_probe.gd](probe/c5_probe.gd). Scratch extracts/logs and full pair evidence
live outside design documents in ignored `game/workshop/verification/c5/`.

## 2. Towers

Two independent moment-frame towers wrap the unchanged shafts. Left column
centres are X4.65/8.55 and Z27.05/30.95; right centres are X17.45/21.35 at the
**same Z**. Four 0.40 square columns per tower run from Y0.25 to17.80. Four
0.65×0.65×0.25 pads make the left foundation footprint X4.325..8.875,
Z26.725..31.275 (right X17.125..21.675). Fore/aft ties are 3.90×0.40×0.25,
centred at Y8.1,10.9,13.7,16.1,17.6. They stay outside both side-door openings.
No tie crosses between towers or across the robot exit.

Each level has an outer landing X3.50..5.28 (right20.72..22.50) and inner landing
X7.92..9.40 (right16.60..18.08), at deck top Y=L, thickness 0.20.
Primary portals/paths occupy Z28.50..30.00. The hip inner landing extends forward
toZ27.27 to reach its arm root. That extension is **blocked on the right**, not
an accepted way to wrap the asymmetric existing guides.

| Clearance / relationship | Result | Required / disposition |
| --- | --- | --- |
| Column face to nominal 3.20 shaft boundary | 0.150 | Candidate wrapping space; actual hardware checked separately |
| Pad face to nominal shaft boundary | 0.025 | Outside shaft; foundations do not enter leg or mobile lanes |
| Landing to 2.60 moving deck edge | 0.020 | Meets lift margin and ≤0.040 seam |
| Right hip landing to forward inner guide carriage | 0.200 envelope overlap | **Fail**; keep guide, car and shaft unchanged; redesign landing/tongue topology |
| Outer forward guard to lift call-panel boxes | 0.040 overlap | **Fail**; local guard cutouts/offsets can be studied without changing portals |
| Column forward face to installed arm's aft bound | 0.170 | Clears static arm bound; not its approach |
| Column to arm approach, tightest positive candidate | About0.080 | **Fail** against 0.100; **provisional (unmerged branch)** |
| Tower top17.80 vs chest lowest carry17.410 | 0.390 vertical overlap | Free-strafe slab conflict; **provisional (unmerged branch)** |

The carry slab reserves all potential free-strafe X/Z positions. An overlap means
unrestricted transit over the tower is unavailable, not that every possible
operator journey hits it. C5 does not invent a new prescribed bypass. Resolve the
operator-view contract before fixing tower-top heights or parking.

## 3. Swing catwalks per level

Left arms point +X when docked; right arms point −X. Retract the tongue, unlock,
then swing left −90° / right +90° about Y, toward −Z, and engage the park lock.
All world-Z guard positions reflect without reversal. Arms are cantilevers;
the dock datum is a work-floor endpoint beside the existing work patch, not a
fastening into temporary robot armor.

| Level | Left pivot XYZ | Main deck X / Z when docked | Extended tongue tip X | Radius enclosing all member corners |
| --- | --- | --- | --- | --- |
| 8.4 | (9.4,8.4,27.95) | 9.42..11.90 /27.27..28.63 |12.16 |2.8245 |
| 11.2 | (9.4,11.2,29.25) |9.42..11.00 /28.57..29.93 |11.26 |1.9544 |
| 14.0 | (9.4,14,29.25) |9.42..11.00 /28.57..29.93 |11.26 |1.9544 |
| 16.4 | (9.4,16.4,29.25) |9.42..11.00 /28.57..29.93 |11.26 |1.9544 |

Right pivots are X16.6, with every X limit reflected. Main floor widths1.36 leave
1.20 between 80 mm rails/posts. Guards rise 1.10; toe-boards are 100 mm high.
The tongue plate is 0.24 long×1.20 wide×0.20 deep, projects0.24 beyond its 20 mm
seam and retracts 0.26 into the arm. The `tongue_stroke` is 0.26 including closure of the seam; the
extended plate length/projection is 0.24. Root running seams and tongue seams are20 mm. Two dock locks and one
pivot are explicit solids on each arm. A park lock is a required interlock,
not an additional invented floor or service crossing.

Hip parked main deck footprint: X8.72..10.08,Z25.45..27.93. Upper parked main
footprint: X8.72..10.08,Z27.65..29.23. Full guard, pivot, tongue and lock bounds
and candidate pockets are in the JSON; use them instead of just these floor
footprints. The checker also finds the proposed hip root/rear handle outside
their declared pockets; those pockets are failed candidates, not usable parking. Root pivot depth is 0.60, which is one reason the upper stack fails.

| Clearance / check | Result | Interpretation |
| --- | --- | --- |
| All 32 authored moving/lift seams |20 mm, zero step | Pass against40 mm |
| Nominal main walk / primary portal width |1.20 /1.50 | Sections meet widths; whole connected paths must also pass |
| 14 m floor to16.4 m pivot underside |1.80 | **Fail**, needs 2.20 |
| Upper parked fore guards crossing primary landing | Intersections in the analytic walking corridor | **Fail**, cannot claim a route back to the same car |
| Upper tongue tip to protected service X edge |0.140 | Positive, above0.100 margin in the static plane |
| Guards near the robot/chest envelope | Some separations down to 0.010 | **Fail**, not player reach evidence |
| Hip parked arms / all unloaded support pockets to exit | Intersections | **Fail**, not a roll-out-ready configuration |

Full clearance data includes every member against every reservation, not just the
nearest pair in this table. Swing intervals are enclosed continuously at 2°
steps using radius×half-step inflation; endpoint-only clearance is never called a
sweep pass. The current analysis also reserves load routes during stow, a
conservative simultaneity assumption. A later staged analysis may separate
stow-before-arrival from parked-load travel, but cannot excuse the actual parked
intrusions or blocked return paths.

The hip endpoint (12.16,8.4,27.95) and upper endpoint (11.26,L,29.25), mirrored,
are candidate patches. Upper rear access alone does **not** establish front
head/shoulder fastening access. The model of physical arm-mouth barriers when
parked, exposed work-edge protection and visible reachable park controls needs
a design decision; no new elevator landing gates are implied. No walking/reach
sweep has been used to claim usability.

## 4. Hip support

Keep the robot at **(13,10.6,26)**. Left independent support pivots at
(8.55,10.55,26.65), with a 3.80 m cantilever to X12.35; right is mirrored to
X13.65. The beam box is 0.45 wide in Z×0.80 deep in Y, topY10.95. A 0.36×0.26
bearing cap20 mm thick gives the unchanged topY10.97 overZ26.52..26.78.
A 0.50×0.80×0.60 root bracket ties the beam toward the front tower column.
All four existing hold-down assemblies are represented by their measured closed
solid bounds, attached to these independent supports. Their contact patch,
handles, linkage and drive are preserved; the robot's waist twist/tilt locks
remain separate. New supports do not borrow catwalk hinges or unload when a
work arm parks.

The load path is hip bearing faces → caps → cantilevers/root moment connections →
tower columns → foundations. The first handoff must keep the crane taking weight
until both caps bear, all four hold-downs close and the waist locks prove their
state. When undoing, crane/receiver support takes weight before releasing loaded
retention. Lowering is a separately supported, synchronized transfer; the
placeholder −90° unloaded support swing is allowed only after that transfer.

| Support clearance / condition | Result | Disposition |
| --- | --- | --- |
| Existing cap datum and four hold-down positions | Preserved exactly (within float measurement precision) | No raised robot datum change |
| Cantilever to hip aggregate component envelope | Up to 0.385 overlap | **Fail**; needs individual contact/void geometry, not a blanket mating exemption |
| Cantilever to supplied loaded leg envelope | Up to 0.450 overlap | **Fail**; refine bearing load path and intermediate leg poses before build |
| Hold-down handle to arm approach | About0.0032 positive separation | **Fail** vs 0.100; **provisional (unmerged branch)** |
| Unloaded root/beam parking to widened exit | Up to 0.500 overlap | **Fail**; support withdrawal must fit a different pocket/topology |

**Game-plausibility section estimate, not certification.** Assume 40 tonnes total
raised robot mass, equally shared:196.2 kN per arm, span 3.80 m. For a steel box
0.45×0.80 with 30 mm walls, E=200 GPa,
`I = (0.45×0.80³ − 0.39×0.74³)/12 = 0.00603022 m⁴`.
A cantilever end load gives `δ = PL³/(3EI) ≈ 0.00298 m` (3 mm),
root moment≈0.746 MN·m and nominal bending stress≈49.5 MPa. Double the load for
a crude dynamic allowance and deflection/stress double. This only supports the
visual plausibility of a deep box; it does not validate welds, root bearing,
column buckling, foundation anchorage, asymmetric load, torsion or actual robot
mass. The 0.65 m pads are spatial placeholders, not engineered foundations.
There is no support stiffness certification or permission to enlarge robot pads.

## 5. State table

`plan.json:states` enumerates all 39 configurations: the five concept states,
31 crane deliveries, two leg deliveries and two service cases. `docked` and
`parked` are explicit motion-ID sets; no mode name hides an omitted level.

| Concept state | Catwalks | Hip support / transfer gate |
| --- | --- | --- |
| Assembly | All four mirrored levels docked | Engaged, four hold-downs and waist locks |
| Delivery/service | Hip: park11.2/14/16.4; legs: park8.4; chest: park14/16.4; arms: park all; other deliveries and service: remain docked candidate | Always engaged; receiver takes load before crane release |
| Prepare for exit (deferred) | All work arms parked; workers on fixed landings | Remains engaged while independent lowering support is established |
| Lower and transfer (deferred) | Work arms remain parked | Remains engaged; reserve whole robot's downward1.40 m illustration, without implementing motion |
| Roll-out ready (deferred) | Work and unloaded hip supports parked | Transfer confirmed before release; robot illustrated lowered, carrier still unspecified |

All configurations fail at least one reserved-volume check. Some failures are
common retained guide/control conflicts, rather than a defect unique to each
delivery. Negative numbers below are conservative envelope overlap depths, not
measured steel penetration. Positive sub-margin clearances also fail.

| State / delivery | Parked work levels (both sides) | Hip support | Minimum clearance m | Below-margin pairs |
| --- | --- | --- | ---: | ---: |
| `assembly` | None | Engaged | -0.3850 | 52 |
| `delivery/shin` | None | Deployed, empty | -0.2000 | 10 |
| `delivery/fork` | None | Deployed, empty | -0.2000 | 10 |
| `delivery/spar` | None | Deployed, empty | -0.2000 | 10 |
| `delivery/right_shin` | None | Deployed, empty | -0.2000 | 10 |
| `delivery/right_fork` | None | Deployed, empty | -0.2000 | 10 |
| `delivery/right_spar` | None | Deployed, empty | -0.2000 | 10 |
| `delivery/foot` | None | Deployed, empty | -0.2000 | 10 |
| `delivery/right_foot` | None | Deployed, empty | -0.2000 | 10 |
| `delivery/pelvis` | 11.2, 14, 16.4 | Ready → engaged before release | -0.4500 | 82 |
| `delivery/chest_store` | None | Deployed, empty | -0.3900 | 58 |
| `delivery/chest` | 14, 16.4 | Engaged | -0.3900 | 94 |
| `delivery/core_store` | None | Deployed, empty | -0.2000 | 10 |
| `delivery/core` | None | Engaged | -0.3850 | 46 |
| `delivery/backpack_store` | None | Deployed, empty | -0.2000 | 10 |
| `delivery/backpack` | None | Engaged | -0.3850 | 46 |
| `delivery/cassette` | None | Deployed, empty | -0.2000 | 10 |
| `delivery/left_arm` | 8.4, 11.2, 14, 16.4 | Engaged | -0.3850 | 151 |
| `delivery/right_arm` | 8.4, 11.2, 14, 16.4 | Engaged | -0.3850 | 160 |
| `delivery/right_arm_store` | None | Deployed, empty | -0.2000 | 10 |
| `delivery/left_pauldron` | None | Engaged | -0.3850 | 52 |
| `delivery/right_pauldron` | None | Engaged | -0.3850 | 52 |
| `delivery/head_baseplate` | None | Engaged | -0.3850 | 52 |
| `delivery/head_baseplate_to_fixture` | None | Engaged | -0.3850 | 52 |
| `delivery/head_left` | None | Engaged | -0.3850 | 52 |
| `delivery/head_left_to_fixture` | None | Engaged | -0.3850 | 52 |
| `delivery/head_right` | None | Engaged | -0.3850 | 52 |
| `delivery/head_right_to_fixture` | None | Engaged | -0.3850 | 52 |
| `delivery/head_top` | None | Engaged | -0.3850 | 52 |
| `delivery/head_top_to_fixture` | None | Engaged | -0.3850 | 52 |
| `delivery/head_crown` | None | Engaged | -0.3850 | 52 |
| `delivery/head_crown_to_fixture` | None | Engaged | -0.3850 | 52 |
| `delivery/left_leg` | 8.4 | Engaged | -0.4500 | 442 |
| `delivery/right_leg` | 8.4 | Engaged | -0.4500 | 458 |
| `service/backpack` | None | Engaged | -0.3850 | 46 |
| `service/core` | None | Engaged | -0.3850 | 52 |
| `prepare_for_exit` | 8.4, 11.2, 14, 16.4 | Engaged | -0.4521 | 330 |
| `lower_and_transfer` | 8.4, 11.2, 14, 16.4 | Engaged | -0.4521 | 386 |
| `roll_out_ready` | 8.4, 11.2, 14, 16.4 | Released only after transfer | -0.5000 | 246 |

Crane heights and approach results in every delivery row are **provisional
(unmerged branch)**. Free carry uses a conservative horizontal slab because the
operator can strafe; the checker also includes the source lift, vertical descent
to approach entry, all authored approach segments, rotations and loaded return
(the same envelope reversed). Rotating arm segments use an enclosing orientation
ball, deliberately broader than their true sweep. Refinement may clear some
flags; it cannot make this a passing build by itself.

## 6. Exit corridor

The complete raised own-mesh union is approximately **8.662 m wide,18.000 m
high,4.380 m deep**, at X8.669..17.331,Y1.400..19.400,Z23.810..28.190.
Reserve X8.369..17.631 (9.262 wide),Y0..19.700, fromZ23.510 to**38.780**.
This includes 0.30 m side/fore/head allowance, but **does not size a transport
carrier or turning/stopping envelope**. Straight +Z translation of the measured
robot fits that lateral reservation. A 1.40 m lowering illustration would put
soles atY0 and top at 18.00; no actual lowering or roll-out mechanism exists.

The concept's X2.25..23.75 doorway is the **outside frame/header span**, not the
clear aperture. Runtime decorative jamb inner faces are X2.95/23.05, header
underside20.90:20.10 m visible clear width. The visible leaf fills it. More
fundamentally, `wall_z39` is a continuous collider atX−13.85..25.85,
Y0..25,Z38.85..39.15. The collision aperture is absent (width0), with no threshold
or door-opening mechanism to measure. The plan stops at the requested leaf datum
Z38.78; crossing the next70 mm reaches the unbroken wall. Do not label the
decorative rectangle an operational exit.

`remove_layout_ids` names **329 existing solids**, including every rear
crossover floor/rail/post at all four levels, `gantry_crosshead`, both old bearing
arms/caps/jaw solids (replaced at the same interfaces), portal columns/feet,
old wings/fingers/rear leaves, flanks/aft fingers, walks, access gates and C2 fills
superseded by the candidate. The inventory is explicit, validated against layout
IDs; it is not a wildcard deletion instruction. Elevators, rails, robots, mobile
platform, crane and shell remain. No permanent replacement crosses the rear.

The checker inventories every current enabled layout solid intersecting the
reserved corridor; the generated [exit inventory](exit-inventory.csv) identifies
its disposition. Current robot bounds, movable work arms, the support envelope,
and retained lift geometry are separately checked. Even after all specified
retirements, the proposed inner landings and parked work/support arms remain in
the robot's reserved path. A future core kit must also be removed and stowed.
A carrier, synchronized transfer, unloaded support withdrawal, operable door,
threshold and an actual departure route need separate approval and measurement.

## 7. Conflicts and decisions

These are outstanding design decisions, not instructions to make code changes.
The invariant datums/routes/reservations stay put. Some comparisons are
conservative-box conflicts and require refinement; none is relabelled a pass.

| ID | Conflict / difference from concept | Options | Recommendation |
| --- | --- | --- | --- |
| C5-01 | Simple outboard swings leave work arms, guards, pivots and even fixed inner landings inside the9.262 m exit reservation; parked upper guards obstruct return to a lift | Retract/fold the complete root/landing extension into a tower pocket; redesign support topology; move robot/exit (violates invariants) | Stop this candidate. Study a retracting root/landing plus fold, keeping datums and the full exit reservation |
| C5-02 | Lateral hip boxes overlap hip/leg conservative envelopes, while unloaded supports still occupy exit allowance and their own pocket bounds | Measure individual mating faces/voids and investigate a retracting load path; retain current raised-only supports; move bearing patches (violates invariant) | Resolve loaded contact and unloaded parking together before any handoff build; no blanket robot collision exclusion |
| C5-03 | Concept door width 21.50 vs measured visible 20.10; no collision aperture or opening action | Separately design opening door/wall/threshold; keep raised assembly only | Keep exit functionality deferred and report the wall explicitly |
| C5-04 | Core rails/two crossframes and5.0 m withdrawal are unimplemented; retiring flanks/aft fingers removes their intended supporting pads | Specify removable kit with tower-supported pads at unchanged coordinates; defer core removal/service | Preserve the central opening and original pad datums; require a separate supported kit before service approval |
| C5-05 | Top pivot reduces headroom to 1.80; rear-only floor endpoints do not prove front connection access; exposed arm mouth/park locks need geometry | Shallower/side-mounted pivots, articulated access and physical arm-mouth guard; retain old gantry until detailed components settle | Start with8.4 only after geometric blockers; no remote fastening or unrequested reach sweeps |
| C5-06 | Historical lowest-load18/19 m is not branch A's carry rule; chest lowest17.410 meets17.80 tower tops; free strafe is not a single fixed route | Change tower/parking section within constraints; retain dynamic obstruction avoidance with agreed operating space; invent a bypass (not authorized) | Treat all crane height/parking constraints as **provisional (unmerged branch)**; reconcile A before fixing steel height |
| C5-07 | Existing guide diagonals are not reflected. Symmetric hip landing intersects right guide carriage; outer guard faces meet call boxes | Shape symmetric landing cutouts around both actual guide exclusions while keeping1.20 path; alter new guard runs locally; move guide/door (violates current constraint) | Preserve shafts/cars/doors/guide volumes and redesign only candidate landings/guards; recheck continuous width |
| C5-08 | Measured normal backpack sweep reachesZ30.086/Y16.490 rather than text30.173 with 30.3/16.6 allowance | Use measured sweep plus interpolation margin; keep larger conceptual allowance where later details need it | Use measured bounds in checker; record difference, keep upper service opening unchanged |

For C5-01 the fixed inboard landing itself reachesX9.4/16.6 and lies in the
full-height exit reservation. Merely changing the angle of a distal arm cannot
solve it. For C5-07 reflecting the current lift guides would change protected
hardware; this run does not do that. A failed box around an irregular hip is
not a proof that all possible supports are impossible. The stop is **this
unresolved candidate**, not rejection of the approved two-tower direction.

## 8. Prototype slice — recommended, not authorized

Choose **Y8.4, both sides, plus the independent hip support handoff**. This is the
user's named asymmetry/gap location and tests the hardest interaction with the
leg corridor before multiplying mechanisms across four levels. First resolve
C5-01/02/07 sufficiently for that slice; keep higher levels and exit features
out of a construction task until their own design gates pass.

Exact slice scope after approval: two tower load paths with unchanged shafts;
one pair of fixed landing/arm-root systems; one mirrored work-arm pair and their
tongues/locks/guards; two bearing supports, two cap patches and four hold-downs;
unchanged waist locks; supported hip crane handoff, both loaded leg endpoints,
empty withdrawal, pause/resume and at-rest save recovery. Keep approved gantry
finish. Do not build upper catwalks, core removal kit, lowering, carrier, door or
whole-robot departure in this slice.

| Task | Agent type | Concrete result / gate |
| --- | --- | --- |
| Resolve root/landing parking, actual hip contact and right guide cutout; re-run dimension tool | Astra High | Revised passing slice geometry without moving datums/routes; then separate user build approval |
| Produce exact edit instructions | Astra High | Verify unique quoted anchors and complete replacements against the approved revision; only then write self-contained Grok tasks |
| Author approved solids/groups and retirement delta | Grok | Exact `author_workshop_blockout.py` edits and regenerated `assets/workshop-layout.json`; no interpretive redesign |
| Define independent load path, support ownership and interlocks | Astra High | Bearing contact before crane release; four hold-downs/waist locks; supported undo; no loaded support parking |
| Implement approved motion/control data and manual checklist edits | Grok | Exact anchors/replacements in the files below; visible physical controls; first-use procedure/repeat goal through branch A's shared mechanism |
| Review geometry, support transitions and integrate | Astra High | Focused checks, final source/manual audit, one coherent player checkpoint; no automatic diagnostics |
| Playtest walking, visibility, hip fastening and machine feel | User | Explicit acceptance or preserved findings; automated geometry cannot supply this |

Likely files a future build touches: `tools/author_workshop_blockout.py`,
`assets/workshop-layout.json`, `scripts/workshop_access.gd`,
`scripts/module_supports.gd`, `scripts/leg_bay_layout.gd`,
`scripts/gantry_dressing.gd`; shared `equipment_registry.gd`/`equipment.gd` only
if the existing movement/support contract needs extension. Use existing zones
and staged receiver data rather than a bespoke controller per delivery.
`work_access_lift.gd` is a preserved integration boundary, not permission to move
its guides/stops. `indexed_leg_rail.gd` routes remain unchanged.

Manual authoring candidates are `tools/author_manual_progress.py`,
`assets/manual-chapters.json` and relevant `assets/robot-definitions.json` pages.
Audit hip support, four hold-downs, waist locks, both leg pin/ring steps and crane
release together. Step outline: identify source/support → take crane weight →
seat on both caps → close four hold-downs/waist locks → release crane → stow the
8.4 paths before loaded leg entry → restore safe work access → retain/lock leg →
withdraw empty holder. Undo transfers weight before retention release. The
independent supports remain engaged when catwalks park; parent support motion
must carry all mounted children, meshes and collision poses together.

Future focused routine plan, run only the suites actually touched, with `--jobs 4`:

- `gantry_dressing_test`, `access_lift_test`, `wide_elevators_test`,
  `workshop_smoke_test`: actual member symmetry, intermediate arm/tongue/guard
  poses, portal seams, car travel, controls and startup.
- `supported_model_test`, `receiver_contract_test`, `rail_endpoint_test`,
  `rail_gates_test`, `zone_register_test`: supported hip/leg handoff, hold-down
  interlocks, unchanged corridor, entry sequencing and empty withdrawal.
- `equipment_motion_test`, `nested_runtime_test`, `save_roundtrip_test`:
  riders/hand loads, pause/resume and retargeting, child inheritance between
  physics ticks, at-rest snapshot restoration; no migrations.
- `manual_objectives_test`, `manual_progress_test`, `manual_completion_test`,
  `manual_control_guidance_test`: affected page ownership, exact controls,
  retained/secured evidence, local return path and no premature completion.

These are future checks, **not tests run in C5**. `indexed_leg_rail_test`,
`pelvis_delivery_test` and other diagnostics remain explicitly opt-in; do not
silently run them as additional verification. The C5 checker is a design tool
and is intentionally absent from the game test inventory. No new game test was
created. There are no executable Grok task files yet: the required geometry
choices and build approval are unresolved, so exact build replacements would
be premature.

## 9. Mechanical evidence versus open player questions

**Final design-tool result: FAIL (exit 1), as required at the conflict stop.**
All 39 states have below-margin pairs; 5,106,010 member/reservation/state
comparisons are recorded. All 310 proposed solids and 10 motions reflect correctly
about X13, including fore/aft guards and tongue travel. All 32 seams pass.
Analytical walking checks pass 92/122 route/configuration cases;
the failures include upper parked guards and top-pivot headroom. Four support
root/handle records escape their declared parking pockets. The complete drawings
contain 818 individually dimensioned positive tight pairs, plus zero-contact
values in the full CSV. The SVGs are drawing evidence only.

The final measurement boot ran 2026-10-26T20:44:35Z through
2026-10-26T20:45:05Z (27 October in Sydney), on Godot 4.7.2.
It recorded 158 component/stage bounds,321 equipment samples, 278 derived/retained
reservations and 31 **provisional (unmerged branch)** crane tasks at `b937dec`.

| Tightest five positive separations | m | Required m | State / phase |
| --- | ---: | ---: | --- |
| `L_gantry_jaw_11.6_26.55_handle` ↔ `crane/left_arm/approach/6` | 0.003208 | 0.100 | `delivery/left_arm` / docked |
| `R_gantry_jaw_11.6_26.55_handle` ↔ `crane/right_arm/approach/6` | 0.003208 | 0.100 | `delivery/right_arm` / docked |
| `L_arm_11.2_fore_post1` ↔ `robot/chest` | 0.010000 | 0.100 | `delivery/left_arm` / swing |
| `L_arm_11.2_aft_post1` ↔ `robot/chest` | 0.010000 | 0.100 | `delivery/left_arm` / swing |
| `R_arm_11.2_fore_post1` ↔ `robot/chest` | 0.010000 | 0.100 | `delivery/left_arm` / swing |


The final runtime probe reached every named boundary and produced complete
component/equipment records without script/engine errors. Earlier scratch
iterations exposed probe-only geometry grouping/adapter-selection mistakes;
those outputs were discarded. One authorized fresh-worktree editor import ran.
Existing image-file export warnings remain. No game regression suite, diagnostic,
rendered review or automated walking/reach sweep ran; no game code, layout,
generator or test file changed.

The checker validates source-layout hash, retirement IDs, all mirrored solids
including fore/aft guards, opposite swing directions, complete state membership,
analytical corridor support/headroom and measured seams. Full pair values are
`verification/c5/clearances.csv.gz`; per-state minima, per-solid/per-volume
summaries, failures and tight geometry are `verification/c5/check.json`.
Small ad-hoc design-tool checks confirmed a mirror mutation, widened seam and
reduced path width fail, and intermediate swing geometry is enclosed. SVG XML
parses and each file remains below 300 KB. These are geometry/tool checks,
not construction or usability acceptance.

**Open player decisions/questions:**

1. Keep the two-tower direction but investigate a **retracting root/landing and
   support** topology, rather than simple distal swings? Recommendation: yes;
   keep robot, shafts, work datums and reservations fixed.
2. After branch A and more permanent component details, is the first separately
   approved slice Y8.4 plus the hip support handoff? Recommendation: yes, once
   its geometry clears. This document does not request or imply build approval.
3. Which front/side work patches need to remain available at each assembly step,
   and what physical park/arm-mouth guard arrangement reads clearly in play?
   Candidate endpoints are not reach acceptance.
4. Continue deferring core removal kit, door, lowering and carrier design?
   Recommendation: yes; reserve their needs without claiming roll-out capability.

Keep the player's positive findings: the accepted gantry finish, a comprehensible
bay/rig workflow, and physical assembly challenge. The C2/C3 lowest-level recheck
and broader machine-operation findings remain in the
[playtest checklist](../robot-workshop-playtest-checklist.md#machine-operation-and-gantry-access--2026-10-26).
