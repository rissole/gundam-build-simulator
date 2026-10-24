extends Node3D
## Authored equipment frames and actual solids; shared by live M3 and its
## mechanical harness. No inferred geometry or runtime coordinate overrides.
const Codec = preload("res://scripts/pose_codec.gd")
var game: Node3D
var spec: Dictionary
var groups: Dictionary = {}
var pieces: Dictionary = {}
var materials: Dictionary = {}

func setup(workshop: Node3D, definition: Dictionary) -> void:
	game = workshop;spec = definition
	for entry in {"steel":"506971","dark":"263a43","yellow":"e8b46b","deck":"657b80","floor":"7c8886","wall":"abb9b6"}:
		materials[entry] = game.material(Color({"steel":"506971","dark":"263a43","yellow":"e8b46b","deck":"657b80","floor":"7c8886","wall":"abb9b6"}[entry]),.35)
	for id in spec.groups:_group(id)
	for entry in spec.solids:
		var parent: Node3D = self if entry.parent.is_empty() else groups[entry.parent]
		var visual: MeshInstance3D = game.box(parent,AssemblyRuntime.vec(entry.position),AssemblyRuntime.vec(entry.size),materials[entry.material])
		visual.name = entry.id;visual.visible = not entry.get("hidden",false)
		if entry.has("visual_offset"):visual.position += AssemblyRuntime.vec(entry.visual_offset)
		if entry.has("visual_size"):visual.mesh.size = AssemblyRuntime.vec(entry.visual_size)
		# The directional key represents the overhead luminaires inside the room.
		if entry.id == "roof" or entry.id.begins_with("truss"):visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var piece = {"spec":entry,"visual":visual}
		if entry.solid:
			var body = StaticBody3D.new();body.name = entry.id+"Solid";body.collision_layer = 1
			body.position = AssemblyRuntime.vec(entry.position);body.set_meta("blockout_id",entry.id);parent.add_child(body)
			var shape = CollisionShape3D.new();var box = BoxShape3D.new();box.size = AssemblyRuntime.vec(entry.size)
			shape.shape = box;body.add_child(shape);piece.body = body;piece.shape = shape
		pieces[entry.id] = piece
	for entry in spec.signs:
		var at = AssemblyRuntime.vec(entry.position)
		var width: float = minf(entry.width,2.4)
		game.sign_panel(self,entry.text.split(" / ")[0],at,Vector2(width,.24),40,.0018)
		game.box(self,at-Vector3(0,at.y/2+.06,0),Vector3(.035,maxf(.1,at.y-.12),.035),materials.dark)
	for id in spec.groups:
		if not spec.groups[id].get("enabled",true):enable_group(id,false)
	publish()

func _group(id: String) -> Node3D:
	if groups.has(id):return groups[id]
	var entry: Dictionary = spec.groups[id]
	var parent: Node3D = self if entry.parent.is_empty() else _group(entry.parent)
	var node = Node3D.new();node.name = id;parent.add_child(node)
	node.transform = authored_pose(entry);groups[id] = node
	return node

static func authored_pose(entry: Dictionary) -> Transform3D:
	return Transform3D(Basis.from_euler(AssemblyRuntime.vec(entry.rotation_degrees)*PI/180),AssemblyRuntime.vec(entry.position))

func publish() -> void:
	# Moving static fixtures must be visible to queries in this same physics tick.
	for piece in pieces.values():
		if piece.has("body"):
			piece.body.force_update_transform()
			PhysicsServer3D.body_set_state(piece.body.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,piece.body.global_transform)

func rids_for_groups(ids: Array) -> Array[RID]:
	var result: Array[RID] = []
	for piece in pieces.values():
		if piece.has("body") and belongs_to(piece.spec.parent,ids):result.append(piece.body.get_rid())
	return result

func belongs_to(id: String, ancestors: Array) -> bool:
	while not id.is_empty():
		if id in ancestors:return true
		id = spec.groups[id].parent
	return false

func frame_at(id: String, overrides: Dictionary) -> Transform3D:
	if id.is_empty():return global_transform
	var entry: Dictionary = spec.groups[id]
	return frame_at(entry.parent,overrides)*overrides.get(id,groups[id].transform)

func shapes_at(ids: Array, overrides: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for piece in pieces.values():
		if not piece.has("body") or piece.body.collision_layer==0 or not belongs_to(piece.spec.parent,ids):continue
		var at = frame_at(piece.spec.parent,overrides)*Transform3D(Basis.IDENTITY,AssemblyRuntime.vec(piece.spec.position))
		# Telescoping guard dimensions are baked into the query shape, keeping
		# physics transforms orthonormal even while the render hierarchy scales.
		var shape = BoxShape3D.new();shape.size = AssemblyRuntime.vec(piece.spec.size)*at.basis.get_scale().abs()
		at.basis = at.basis.orthonormalized()
		result.append({"shape":shape,"world":at,"id":piece.spec.id})
	return result

func apply_frames(frames: Dictionary) -> void:
	for id in frames:groups[id].transform = frames[id]
	publish()

func enable_group(id: String, enabled: bool) -> void:
	groups[id].visible=enabled
	for piece in pieces.values():
		if piece.has("body") and belongs_to(piece.spec.parent,[id]):piece.body.collision_layer=1 if enabled else 0
