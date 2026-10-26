extends RefCounted
## Mesh resources own a cached TriangleMesh BVH. Instance transforms stay live;
## narrow queries visit only mesh bounds crossed by the ray, never every face.
## A few offset rays assist edges without filling a ring's empty centre.
const EDGE_TOLERANCE = 0.012
const CACHE_LIMIT = 128
var meshes: Dictionary = {}
var objects: Dictionary = {}
var collections = 0
var builds = 0
var queries = 0
var _clock = 0

func ray_hit(body: Node3D, origin: Vector3, direction: Vector3, maximum: float) -> Dictionary:
	var best: Dictionary = {}
	var visuals: Array = _visuals(body)
	for visual in visuals:
		if not is_instance_valid(visual) or visual.mesh == null or not visual.is_visible_in_tree() or visual.has_meta("pickup_outline") or visual.has_meta("assembly_render_proxy"):continue
		# Contour descendants also carry their source's mesh; skip their entire subtree.
		var parent: Node = visual.get_parent()
		var contour = false
		while parent != body and parent != null:
			if parent.has_meta("pickup_outline"):contour = true;break
			parent = parent.get_parent()
		if contour:continue
		var inverse: Transform3D = visual.global_transform.affine_inverse()
		var local_origin: Vector3 = inverse*origin
		var local_direction: Vector3 = inverse.basis*direction
		if visual.mesh.get_aabb().intersects_ray(local_origin,local_direction) == null:continue
		var triangles: TriangleMesh = _triangles(visual.mesh)
		if triangles == null:continue
		queries += 1
		var hit: Dictionary = triangles.intersect_ray(local_origin,local_direction)
		if hit.is_empty():continue
		var point: Vector3 = visual.global_transform*hit.position
		var distance = origin.distance_to(point)
		if distance > maximum or (not best.is_empty() and distance >= best.distance):continue
		best = {"point":point,"distance":distance}
	return best

func aim_hit(body: Node3D, camera: Camera3D, maximum: float) -> Dictionary:
	var origin = camera.global_position
	var forward = -camera.global_basis.z
	var hit = ray_hit(body,origin,forward,maximum)
	if not hit.is_empty():
		hit.score = hit.distance*0.008
		return hit
	for offset in [camera.global_basis.x,-camera.global_basis.x,camera.global_basis.y,-camera.global_basis.y]:
		var assisted = ray_hit(body,origin+offset*EDGE_TOLERANCE,forward,maximum)
		if assisted.is_empty():continue
		assisted.score = 0.25+assisted.distance*0.008
		if hit.is_empty() or assisted.score < hit.score:hit = assisted
	return hit

func _visuals(body: Node3D) -> Array:
	var key = body.get_instance_id()
	if objects.has(key) and objects[key].object.get_ref() == body and objects[key].revision == body.get_meta("visual_revision",0):return objects[key].visuals
	# Membership changes invalidate once. Pose and visibility never require a scan.
	if objects.size() >= CACHE_LIMIT:objects.erase(objects.keys()[0])
	var visuals: Array = []
	_collect(body,key,visuals)
	collections += 1
	objects[key] = {"object":weakref(body),"visuals":visuals,"revision":body.get_meta("visual_revision",0)}
	return visuals

func _collect(node: Node3D, key: int, visuals: Array) -> void:
	if node.has_meta("pickup_outline") or node.has_meta("assembly_render_proxy"):return
	if node is MeshInstance3D:visuals.append(node)
	for signal_name in ["child_entered_tree","child_exiting_tree"]:
		if not node.is_connected(signal_name,_membership_changed.bind(key)):node.connect(signal_name,_membership_changed.bind(key))
	for child in node.get_children():
		if child is Node3D:_collect(child,key,visuals)

func _membership_changed(child: Node, key: int) -> void:
	if not child.has_meta("pickup_outline"):objects.erase(key)

func _triangles(mesh: Mesh) -> TriangleMesh:
	_clock += 1
	var key = mesh.get_instance_id()
	if not meshes.has(key):
		if meshes.size() >= CACHE_LIMIT:
			var oldest = meshes.keys()[0]
			for candidate in meshes:
				if meshes[candidate].used < meshes[oldest].used:oldest = candidate
			meshes.erase(oldest)
		meshes[key] = {"mesh":mesh,"triangles":mesh.generate_triangle_mesh(),"used":_clock}
		builds += 1
		if not mesh.changed.is_connected(_invalidate.bind(key)):mesh.changed.connect(_invalidate.bind(key))
	meshes[key].used = _clock
	return meshes[key].triangles

func _invalidate(key: int) -> void:
	meshes.erase(key)
