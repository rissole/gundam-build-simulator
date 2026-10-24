extends Node3D
var paused = false
var equipment = EquipmentRegistry.new()
var model = AssemblyModel.new()
var source: Dictionary = {}
var primitives = preload("res://scripts/primitives.gd").new()
func material(color: Color, metal: float = 0.0) -> Material:return primitives.material(color,metal)
func box(parent: Node3D, at: Vector3, size: Vector3, mat: Material, solid: bool = false) -> MeshInstance3D:return primitives.box(parent,at,size,mat,solid)
func sign_panel(parent: Node3D, text: String, at: Vector3, size: Vector2, font: int, pixel: float) -> Label3D:return primitives.sign_panel(parent,text,at,size,font,pixel)
func source_uid(uid: String) -> String:return model.source_uid(uid)
func _mesh(uid: String) -> MeshInstance3D:
	var result = MeshInstance3D.new();result.mesh = source[source_uid(uid)].mesh;return result
