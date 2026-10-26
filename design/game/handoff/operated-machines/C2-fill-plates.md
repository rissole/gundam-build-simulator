# C2 — Fixed lift landing plates and hinge edge rails (Grok task)

Written 2026-10-27. **Specification only; not implemented by the Phase 1
coordinator.** Parent session launches Grok later. Work only on `gantry-access`
in `/private/tmp/gbs-gantry`; never touch another branch/worktree or `main`.
Read repository `AGENTS.md`, `design/game/workshop-state.md` and this folder's
`README.md`. Apply `.agents/skills/gundam-assembly-review/SKILL.md` proportionally
for these fixed collision changes. [C1](C1-gap-audit.md) contains measured runtime
bounds, exclusions and the C0 guard-handedness finding.

## Exact scope

Close ten 0.300 m landing slots with fixed 0.280 m plates, retaining 0.020 m car
clearance, and extend the outer guard along the eight 1.30 m hinge-apron edges.
No toe-board crosses a doorway. No finger/leaf/wing dimensions, transforms,
mode logic, elevator behavior, support datum, manual, save or crane changes.
Do not repair guard handedness: C0/C3 is a separate human-gated task. Do not build
v2. Moving-part fixes belong to the coordinator, never this task.

Only edit:

- `game/workshop/tools/author_workshop_blockout.py`
- `game/workshop/assets/workshop-layout.json` (generated)
- `game/workshop/tests/gantry_dressing_test.gd`

No new suite: extend the already-classified routine `gantry_dressing_test`.
Every quoted anchor below was checked to occur exactly once at C1 commit
`6165379`. Assert occurrence count before each replacement; stop on drift.

## 1. Generator edits

In `game/workshop/tools/author_workshop_blockout.py`, replace this entire line:

```python
            deck(f"wing_hinge_{side}_{tag}",x0,x1,23.4,24.7,level,[])
```

with:

```python
            deck(f"wing_hinge_{side}_{tag}",x0,x1,23.4,24.7,level,["left" if left else "right"])
```

The existing `deck` helper produces the exact fixed rail/post boxes:
rail centre `(3.46 or 22.54, level+1.06, 24.05)`, size `(.08,.08,1.30)`;
posts at that X, `Y=level+.51`, `Z=23.44/24.66`, size `(.08,1.02,.08)`.
Parent is `""`; material yellow, solid true. This retains the 1.50 m walking width.

Replace this exact two-line anchor:

```python
    # Rendered joints have distinct sections while physics retains the authored
    # envelopes. Telescoping plates must not share their host's top/side planes.
```

with:

```python
    # Fixed landing lips stop 20 mm short of the moving car. Keep the full
    # doorway width and stay between the shaft's corner guide bands.
    for level in data["access"]["levels"]:
        tag=str(level)
        for side,x in [("left",5.14),("right",20.86)]:
            box(f"outer_{side}_{tag}_landing_fill",[x,level-.1,29.25],
                [.28,.20,1.50],"deck")
    for side,x in [("left",8.06),("right",17.94)]:
        box(f"hip_apron_{side}_landing_fill",[x,8.30,29.25],
            [.28,.20,1.50],"deck")

    # Rendered joints have distinct sections while physics retains the authored
    # envelopes. Telescoping plates must not share their host's top/side planes.
```

Regenerate with:

```sh
python3 game/workshop/tools/author_workshop_blockout.py
python3 game/workshop/tools/author_workshop_blockout.py --check
```

Exact JSON delta: **34 appended/new solids** (10 plates, 8 rails, 16 posts), no
modified existing solids/groups or other layout sections. All new records have
`parent: ""`, `solid: true`. Plates have no visual offsets or alternative sizes.
Existing `outer_`, `hip_apron_` and `wing_hinge_` dressing prefixes already cover
these pieces. Do not change `gantry_dressing.gd` or its triangle budget.

Plate world X bounds are 5.00..5.28 /20.72..21.00 at all four levels, and
7.92..8.20 /17.80..18.08 at8.4 only; Y is `level-.20..level`, Z28.50..30.00.
The moving cars occupy X5.30..7.90 /18.10..20.70. Nothing may enter the central
service reservation X11.4..14.6/Z27.2..35.3, aft well Z31.7..35.3 or leg corridor
X10.5..15.5/Z20.5..30.6. Plates must stay out of the guide bands
Z27.4..27.7 /30.3..30.6. Do not bridge the wing hinge, extend a work finger,
cover a shaft, or fill the deliberate finger-to-apron or flank-to-aft openings.

## 2. Focused runtime assertions

In `game/workshop/tests/gantry_dressing_test.gd`, replace the exact line:

```gdscript
	var before = _collision_state(game)
```

with:

```gdscript
	_check_landing_fills(world,lifts,access)
	var before = _collision_state(game)
```

Replace the exact line:

```gdscript
func _collision_state(root_node: Node) -> Dictionary:
```

with the following block, preserving literal tabs as GDScript indentation:

```gdscript
func _piece_bounds(piece: Dictionary) -> AABB:
	var shape: CollisionShape3D = piece.shape
	return shape.global_transform*AABB(-shape.shape.size/2,shape.shape.size)

func _check_landing_fills(world, lifts: Array, access) -> void:
	var expected: Dictionary = {}
	for entry in [[8.4,"8.4"],[11.2,"11.2"],[14.0,"14"],[16.4,"16.4"]]:
		var level: float = entry[0]
		var tag: String = entry[1]
		for side in ["left","right"]:
			var left: bool = side=="left"
			var x: float = 5.14 if left else 20.86
			expected["outer_"+side+"_"+tag+"_landing_fill"] = AABB(Vector3(x-.14,level-.2,28.5),Vector3(.28,.2,1.5))
			var edge: String = "left" if left else "right"
			var rail: String = "wing_hinge_"+side+"_"+tag+"_"+edge+"_rail"
			expect(world.pieces.has(rail),"fixed hinge apron has an outboard rail: "+rail)
			if world.pieces.has(rail):
				var bounds: AABB = _piece_bounds(world.pieces[rail])
				var wanted = AABB(Vector3(3.42 if left else 22.5,level+1.02,23.4),Vector3(.08,.08,1.3))
				expect(bounds.is_equal_approx(wanted),"hinge guard stays outside walk and wing sweep: "+rail)
	for side in ["left","right"]:
		var x: float = 8.06 if side=="left" else 17.94
		expected["hip_apron_"+side+"_landing_fill"] = AABB(Vector3(x-.14,8.2,28.5),Vector3(.28,.2,1.5))
	var actual: Array = world.pieces.keys().filter(func(id):return id.ends_with("_landing_fill"))
	expect(actual.size()==10,"exactly ten fixed landing plates")
	for id in expected:
		expect(world.pieces.has(id),"landing plate exists: "+id)
		if not world.pieces.has(id):continue
		var piece: Dictionary = world.pieces[id]
		var bounds: AABB = _piece_bounds(piece)
		expect(piece.body.get_parent()==world and bounds.is_equal_approx(expected[id]),"plate has fixed parent, flush top and doorway bounds: "+id)
		var left: bool = "_left_" in id
		var lift = lifts[0] if left else lifts[1]
		var deck_shape: CollisionShape3D = null
		for child in lift.deck.get_children():
			if child is CollisionShape3D and child.shape is BoxShape3D and child.shape.size.is_equal_approx(Vector3(2.6,.12,2.6)):deck_shape=child
		expect(deck_shape!=null,"real lift deck collision is available: "+id)
		if deck_shape==null:continue
		var car: AABB = deck_shape.global_transform*AABB(-deck_shape.shape.size/2,deck_shape.shape.size)
		var gap: float = maxf(car.position.x-bounds.end.x,bounds.position.x-car.end.x)
		expect(absf(gap-.02)<.00002,"plate reduces landing slot to 20 mm without touching car: "+id)
		# Include closed doors and guide shoes; test their complete vertical
		# travel envelopes, not just a parked empty car or JSON dimensions.
		var collisions: Array = []
		for child in lift.deck.get_children():
			if not child is CollisionShape3D or not child.shape is BoxShape3D:continue
			var swept: AABB = child.global_transform*AABB(-child.shape.size/2,child.shape.size)
			swept.position.y += lift.stops[0]-lift.height
			swept.size.y += lift.stops[-1]-lift.stops[0]
			if bounds.grow(.001).intersects(swept):collisions.append(str(child.name))
		expect(collisions.is_empty(),"plate clears all car hardware for full lift travel: "+id+" "+str(collisions))
	for mode in access.spec.modes:
		world.apply_frames(access.frames_at(access._goals(mode)))
		var moved: Array = []
		for id in expected:
			if world.pieces.has(id) and not _piece_bounds(world.pieces[id]).is_equal_approx(expected[id]):moved.append(id)
		expect(moved.is_empty(),"landing plates stay fixed in access mode "+mode+": "+str(moved))
	world.apply_frames(access.frames_at(access.values()))

func _collision_state(root_node: Node) -> Dictionary:
```

This compares runtime deck geometry and complete straight lift travel envelopes;
it does not simulate walking/reach. Keep the existing dressing, intermediate
fold and lift/shelf movement checks intact. The fixture constructs lifts in
`left`, `right` JSON order; stop if that setup changes.

## 3. Acceptance and stop

Run only:

```sh
python3 game/workshop/tools/author_workshop_blockout.py --check
python3 game/workshop/tools/run_regressions.py --only gantry_dressing_test access_lift_test wide_elevators_test --jobs 4
rg -n 'landing_fill|wing_hinge_.*_(left|right)_rail' game/workshop/assets/workshop-layout.json
rg -n '_check_landing_fills|20 mm|full lift travel' game/workshop/tests/gantry_dressing_test.gd
git diff --check
```

Also verify the generated JSON against the pre-task version: only the 34 new
solids may differ; assert every prior solid is byte-equivalent as parsed data,
all groups unchanged, and the rest of the layout unchanged. Confirm generated
plate IDs number 10, hinge rails number 8 and new hinge posts number 16.
No full suite, diagnostics, rendered review or automated walking/reach sweep.
The later coordinator integration adds the single `workshop_smoke_test`.

Stop on anchor mismatch, unexpected generated changes, a moving-part fix,
collision/regression failure, new import/icon needs, or elapsed-time warning.
Do not relax collision margins, retire assertions, alter budgets, add gates or
fall back to diagnostics. Report the specific discrepancy to the parent.
The C1 baseline passed 63/45/93 checks, but that is not evidence for this patch.

Commit this task alone, with message ending in a blank line then:

```text
Co-Authored-By: Codex <noreply@openai.com>
```

Report commit, exact files, test results/time, any open issue, and unreviewed
player acceptance. Stop; do not launch another agent, merge, implement C3/v2 or
claim the player's falling/asymmetry complaint is resolved.

Coordinator specification validation (2026-10-27): all four anchors match once;
applying the generator snippets in memory yields exactly 34 additions with all
prior solids and other workshop fields unchanged. The complete test file with
the snippets inserted passes Godot `--check-only` from an uncommitted scratch
copy. This is syntax/data validation, not a C2 runtime regression pass; production
code/layout remain unchanged for the later Grok run.
