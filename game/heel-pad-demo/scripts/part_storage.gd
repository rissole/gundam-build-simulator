extends Node
## Low wall cabinets for pocket stock; open shelves for carried components.
## Catalogue images are baked from source meshes, shared with the hotbar.
var game: Node
var images: Dictionary = {}
var drawer_kinds: Array[String] = []
var shelf_kinds: Array[String] = []
var stock_counts: Dictionary = {}

func _init(workshop: Node) -> void:
	game = workshop

func picture(kind: String) -> Texture2D:
	if kind.is_empty():return null
	if not images.has(kind):
		var path = "res://assets/part-images/"+kind+".png"
		var pixels = Image.load_from_file(path)
		assert(pixels != null,"Missing part catalogue image: "+kind)
		images[kind] = ImageTexture.create_from_image(pixels)
	return images[kind]

func setup() -> void:
	for item in game.model.items.values():
		if item.location != "bin":continue
		var list: Array[String] = drawer_kinds if game.model.definitions.parts[item.kind].carry_class == "pocket" else shelf_kinds
		if not list.has(item.kind):list.append(item.kind)
	drawer_kinds.sort()
	shelf_kinds.sort()
	var cabinet = game.material(Color("253b45"),0.15)
	var front = game.material(Color("e0e6dd"))
	var trim = game.material(Color("83bba6"),0.2)
	# Two rows at waist/chest height; the back wall provides a continuous aisle.
	for group in [drawer_kinds,shelf_kinds]:
		var drawers: bool = group == drawer_kinds
		var columns = ceili(group.size()/2.0)
		var origin = -9.6 if drawers else 1.0
		var spacing = 0.80 if drawers else 1.04
		if columns == 0:continue
		var center = origin+(columns-1)*spacing*0.5
		game.box(game,Vector3(center,0.92,-6.55),Vector3(columns*spacing,1.84,0.16),cabinet,true)
		game.sign_text(game,"SMALL PARTS / E STOCKS A POCKET" if drawers else "COMPONENTS / E CARRY",Vector3(center,2.18,-6.20),25,Color("233940"),0.004)
		for i in range(group.size()):
			var kind: String = group[i]
			var bin = StaticBody3D.new()
			bin.name = "Drawer_"+kind if drawers else "Shelf_"+kind
			bin.position = Vector3(origin+(i%columns)*spacing,0.82+floorf(i/float(columns))*0.70,-6.15)
			bin.set_meta("bin_kind",kind)
			bin.set_meta("drawer",drawers)
			game.add_child(bin)
			game.bins[kind] = bin
			var collision = CollisionShape3D.new()
			var shape = BoxShape3D.new()
			shape.size = Vector3(spacing-0.04,0.54 if drawers else 0.12,0.56)
			collision.shape = shape
			collision.position.y = 0.06 if drawers else -0.14
			bin.add_child(collision)
			game.box(bin,collision.position,shape.size,front if drawers else cabinet)
			if drawers:game.box(bin,Vector3(0,-0.13,0.31),Vector3(0.20,0.025,0.025),trim)
			else:
				var prop = game._mesh(game.type_sources[kind])
				prop.name = "ShelfPart"
				prop.position = Vector3(0,0.12,0)-prop.mesh.get_aabb().get_center()
				bin.add_child(prop)
			if not drawers:game.box(bin,Vector3(0,-0.30,0.282),Vector3(spacing-0.05,0.40,0.018),front)
			var icon = Sprite3D.new()
			icon.name = "PartImage"
			icon.texture = picture(kind)
			icon.pixel_size = 0.00125
			icon.position = Vector3(-spacing*0.29,0.085,0.292)
			if not drawers:icon.position.y -= 0.4
			icon.shaded = false
			bin.add_child(icon)
			var definition: Dictionary = game.model.definitions.parts[kind]
			var id = game.sign_text(bin,definition.family,Vector3(0.15,0.20,0.295),28,Color("142b35"),0.0022)
			id.name = "PartID"
			if not drawers:id.position.y -= 0.4
			var name = definition.get("short_title",definition.title.split(" · ")[-1])
			game.sign_text(bin,name,Vector3(0.15,0.10 if drawers else -0.30,0.295),15,Color("29434c"),0.0017)
			game.bin_labels[kind] = game.sign_text(bin,"",Vector3(0.15,0.0 if drawers else -0.40,0.295),16,Color("29434c"),0.0018)
	refresh()

func refresh() -> void:
	for kind in game.bins:
		var count: int = game.model.count_at(kind,"bin")
		if stock_counts.get(kind,-1) == count:continue
		stock_counts[kind] = count
		game.bin_labels[kind].text = "%d available"%count
		var prop = game.bins[kind].get_node_or_null("ShelfPart")
		if prop:prop.visible = count>0
