# C1 — Runtime gantry seam audit — 2026-10-27

**Completed measurement; repairs are specified in C2, not implemented here.**
Scope and stop points: [branch C](C-gantry-access.md). The user's reported
asymmetric spot remains unknown (C0). No moving-part length change is justified
by these measurements; C3 remains gated.

## Evidence and limits

Scratch files, intentionally uncommitted, are in `game/workshop/verification/`:
`c1_gap_probe.gd`, `c1_analyse.py`, `c1-pelvis.json`,
`c1-left_leg_dock.json`, the corresponding logs, and `c1-seams.csv`,
`c1-edges.csv`, `c1-mirror.csv`. Reproduce locally with:

```sh
"$HOME/.cache/gundam-tools/Godot-4.7.2/Godot.app/Contents/MacOS/Godot" --headless --path game/workshop --script verification/c1_gap_probe.gd -- pelvis
"$HOME/.cache/gundam-tools/Godot-4.7.2/Godot.app/Contents/MacOS/Godot" --headless --path game/workshop --script verification/c1_gap_probe.gd -- left_leg_dock
python3 game/workshop/verification/c1_analyse.py
```

Both fresh workshop boots reached their named stage with no stage errors. The
probe reads enabled BoxShape3D sizes and PhysicsServer3D world transforms from
the actual blockout and both lifts, after normal lift transform propagation.
It supplies each mode endpoint and measures all four elevated lift stops, with
waist service fingers both available and stowed: 14 states per stage, 28 total.
These supplied poses are geometry evidence, not an operation or walking test.
The initial fresh-worktree script failed to resolve its harness; one authorized
`./play.command --headless --editor --import --quit` resolved imports. Successful
runs have no engine errors; existing image-file export warnings remain.

The live capsule is radius 0.26 m, height 1.70 m. A clear slot wider than 0.52 m
can admit it; a narrower slot can let its rounded foot dip. For example, a
0.30 m slot permits approximately 48 mm geometric dip before corner contact;
this is a catch candidate, not proof of the player's reported fall. The 0.04 m
seam permits less than 1 mm. No player trajectories were simulated.

The analysis lists 1,516 nearby floor-pair seams and 2,834 exposed-edge segments
across repeated stages/modes/levels, not that many distinct defects. It subtracts
adjacent/overlapping deck support within 40 mm and body-height barriers within a
capsule radius, then lists remaining edges longer than 0.52 m. This conservative
box analysis is not structural certification or a complete collision sweep.
Folded vertical leaves are excluded from walkable floors. Raw rows remain local;
the decisions and reproducible dimensions are retained below.

## Mode coverage

| Mode | Wings/fingers retracted and swung at deck Y | Rear hip leaves |
| --- | --- | --- |
| work | None | Flat |
| pelvis | 11.2, 14, 16.4 | Flat |
| leg | 8.4 | Folded |
| chest | 14, 16.4 | Flat |
| arm | 8.4, 11.2, 14, 16.4 | Flat |
| rear | None | Flat |
| head | None | Flat |

The separate `arm_services_stowed` flag retracts the 11.2 m fingers even with
that wing closed. It affects both sides equally. Fixed landing gaps are present
in every mode at both stages.

## Seam decisions

Coordinates are metres, world XYZ unless noted. `L` is deck top; all proposed
fixed pieces have parent `""` (the blockout root). Mirrors are about X13.

| Location | Measured gap / step | Mode | Proposed box centre / size / parent | Clearance to preserve |
| --- | --- | --- | --- | --- |
| Outer walk → left/right lift, L=8.4/11.2/14/16.4, Z28.5..30 | 0.300 m at X5..5.3 /20.7..21 | All | **C2:** centres (5.14,L−0.10,29.25), (20.86,L−0.10,29.25); size (0.28,0.20,1.50); root | Leave 0.020 m to moving car; keep the full 1.50 m doorway; no plate inside car footprint |
| Hip apron → lift, L8.4, same Z band | 0.300 m at X7.9..8.2 /17.8..18.1 | All | **C2:** centres (8.06,8.30,29.25), (17.94,8.30,29.25); size (0.28,0.20,1.50); root | Inner car edges X7.9/18.1 retain 0.020 m; plates stop at apron and stay outside leg corridor X10.5..15.5 |
| Upper branch → car, L11.2/14/16.4 | Flush, 0 gap / step | All | None | Retain Z28.5..30 doorway and shelf turning area |
| Branch → flank; apron → outer rear leaf; rear outer → inner leaf | Flush; 0.010 m apron hinge gap; flush leaf joint | Flat relevant decks | None | Keep rear two-leaf fold, 0.20 m calf separation and Y8.2 underside |
| Wing hinge → wing; wing centre meeting | 0.020 m root; 0.040 m centre | Closed wings | None | Do not bridge the rotating joint with fixed steel |
| Hip finger → wing | Flush at Z24.6; no step | Closed hip wing | None | Preserve retract-before-swing and socket/pin work |
| Waist middle finger → wing / tip | No horizontal gap; middle top 0.025 m lower | Closed waist wing, services available | None for C2; retain small telescoping step | Moving geometry; do not lengthen or fill with fixed plates |
| Hip finger tip → apron front | 1.550 m between Z25.8 and27.35 | Hip wing closed | **No fill** | This is the robot/leg work opening, not a continuous walkway; fixed steel would block docking and downward work |
| Upper flank → aft finger | 1.600 m between Z30.1 and31.7 | All at L11.2 | **No fill** | Rear portal, removable core service kit and lifting routes; aft finger is reached from crossover |

The ten C2 plates end at Z30.0, outside rack-guide bands Z27.4..27.7 and
30.3..30.6. Their nearest central X is 8.20/17.80: none enters the service
reservation X11.4..14.6/Z27.2..35.3, aft well or leg corridor. No toe-board goes
across a lift doorway or downward hip pin/ring sight line.

## Exposed-edge decisions

These are openings, not all repairable seams. A toe-board alone would not make
a body-width opening fall-proof. Keep the deliberate work openings pending
player evidence; do not disguise them as fixed floors.

| Location / extent | Mode | Proposal (centre / size / parent where authorized) | Constraint / disposition |
| --- | --- | --- | --- |
| Hinge apron outboard edge, 1.30 m long at X3.5/22.5, Z23.4..24.7; all levels | All; approach gated with wing stowed | **C2:** continue existing outer railing. Rail centre (3.46 or22.54,L+1.06,24.05), size (.08,.08,1.30); posts at same X, Y=L+.51, Z23.44/24.66, size (.08,1.02,.08); root | Entirely outside 1.5 m walk; ≥0.90 m from stowed wing floor; no new moving part |
| Hinge front edge, 0.70 m at X4.3..5 /21..21.7, Z23.4 | All | None | Wing's forward swing crosses this region; no fixed fill/guard |
| Wing open edge at hip: left rear segments 3.00 m and2.18 m; right front 7.96 m. Upper left rear up to6.38 m; right front7.96 m | Closed wings; transformed edge persists when stowed | None in C2 | Guard handedness finding below; C0/C3. Any new moving guards require coordinator review |
| Hip finger sides/tip, up to1.20 m each; waist middle exposed sides0.80 m, tip sides up to1.20 m, tip width1.15 m | Corresponding wing closed, services available | None | Open work patches; fixed toes would obstruct retraction, downward pins or socket access |
| Hip apron front1.90 m; inner trailing edge1.47–1.55 m; shaft-facing edge outside doorway | All; inner edge also exposed when rear leaves fold | None beyond doorway plates | Preserve bridge sweep, lift guides and hip access. Not a reason to extend apron into leg corridor |
| Rear hip leaf front/back edge, 1.44 m per leaf | Flat rear leaves | None | Left/right guards are on opposite Z edges; preserve rear pin sight lines and C0 gate |
| Upper flank front/rear1.70 m, inward edge2.70 m, outboard front shoulder1.02 m | All upper levels | None | Keep robot/backpack service opening and delivery clearances; work-edge guarding needs task-specific design |
| Rear crossover front: about15.84 m at hip/14/16.4; at11.2 split into4.54/3.04/4.54 m by aft-finger guards | All | None in C2 | No floor extension into aft lifting well; v2 removes crossover entirely |
| Lift doorway when car absent | All | No permanent bridge or gate | Shaft must remain open to moving car; retain accepted no-landing-gates policy and lift nudge/hold behavior |

## Side-by-side result and C0

All 812 paired deck/gate endpoint comparisons across both stages agree under
X→26−X within 0.000002 m. The two landing gaps are symmetric. This does **not**
establish guard symmetry: right wings use a 180° Y parent rotation, but the
same local rear guard is disabled on both sides. In work mode the remaining
left wing rail is at Z23.32, right at Z24.68. Rear hip guard centres are likewise
Z28.59 on the left and27.31 on the right. The resulting 1.28 m fore/aft difference
also persists through their supplied folded configurations. Numbered end posts
were compared spatially, not mistaken for mismatches because their indices swap.

Lift corner guides also use the same local diagonal on both sides, rather than
a reflected diagonal; controls and shelf placement differ by design. None of
these observations identifies the player's unknown asymmetric spot. Record them
for C0; do not change rotations, modes, guards or guide placement now.

## Verification

`python3 game/workshop/tools/run_regressions.py --only gantry_dressing_test access_lift_test wide_elevators_test --jobs 4`
passed: 63 + 45 + 93 checks, 3 cases, 9.735 s, inputs unchanged. These establish
the existing baseline only. No diagnostics, rendered review, walking or reach
sweeps ran. C2 implementation and its own verification belong to the later Grok
run and coordinator integration. Player acceptance remains pending in the
[checklist](../../robot-workshop-playtest-checklist.md#machine-operation-and-gantry-access--2026-10-26).
