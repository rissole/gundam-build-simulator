extends RefCounted
## A labelled, front-facing key shared by physical equipment panels.
static func make(game: Node, parent: Node3D, at: Vector3, caption: String, yaw: float = 0.0, primary: bool = false) -> MeshInstance3D:
	var mount = Node3D.new();parent.add_child(mount);mount.position = at;mount.rotation.y = yaw
	var material = game.material(Color("497567") if primary else Color("34434a"),.25)
	var key: MeshInstance3D = game.box(mount,Vector3.ZERO,Vector3(.24,.18,.055),material)
	key.set_meta("control_bank",parent)
	var faces: Array = parent.get_meta("button_faces",[])
	faces.append(key);parent.set_meta("button_faces",faces)
	var label = Label3D.new();key.add_child(label);label.position.z = .03
	label.text = caption;label.font_size = 32;label.pixel_size = .0013
	label.modulate = Color("f2f4ec");label.outline_size = 0
	return key

## Opt in explicitly. The handler receives (held: bool, delta: float), with true
## once per physics tick and false once on release (delta = 0). Bind an action
## after those arguments if a controller shares one handler across its buttons.
## Controllers recheck motion interlocks on each tick; aim is checked only at latch.
static func set_hold_handler(button: MeshInstance3D, handler: Callable) -> void:
	button.set_meta("hold_handler",handler)

static func hold_handler(target: Dictionary) -> Callable:
	if target.get("type","") != "equipment" or target.get("input","") in ["place","pickup"]:return Callable()
	var button = target.get("node")
	if not is_instance_valid(button):return Callable()
	return button.get_meta("hold_handler",Callable())
