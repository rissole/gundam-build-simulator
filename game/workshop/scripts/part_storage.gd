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
		var authored: String = game.model.definitions.parts[kind].get("catalogue_image","")
		if not authored.is_empty():
			images[kind] = load(authored)
			return images[kind]
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
	var groups: Array[Dictionary] = []
	for zone in (["foot","leg","pelvis"] if not game.profile.leg_content.is_empty() else ["foot"]):
		for drawers in [true,false]:
			var kinds: Array[String] = []
			for kind in (drawer_kinds if drawers else shelf_kinds):
				var part_zone = "leg" if kind.begins_with("lg-") else "pelvis" if kind.begins_with("pv-") else "foot"
				if part_zone == zone:kinds.append(kind)
			if not kinds.is_empty():groups.append({"kinds":kinds,"drawers":drawers,"zone":zone})
	for entry in groups:
		var group: Array[String] = entry.kinds
		var drawers: bool = entry.drawers
		var columns = ceili(group.size()/2.0)
		var origin = -9.6 if drawers else 1.0
		var depth = -6.55
		if entry.zone == "leg":
			origin = -10.0 if drawers else -5.5
			depth = 10.2
		elif entry.zone == "pelvis":
			origin = 17.7 if drawers else 21.0
			depth = 30.5
		var spacing = 0.80 if drawers else 1.04
		if columns == 0:continue
		var center = origin+(columns-1)*spacing*0.5
		game.box(game,Vector3(center,0.92,depth),Vector3(columns*spacing,1.84,0.16),cabinet,true)
		# The header is carried by the cabinet instead of hovering in the aisle.
		for offset in [-0.78,0.78]:
			game.box(game,Vector3(center+offset,1.98,depth+0.05),Vector3(0.04,0.30,0.04),cabinet)
			# Connector starts at the upright's front face instead of sharing its sides.
			game.box(game,Vector3(center+offset,2.08,depth+0.08),Vector3(0.04,0.06,0.02),cabinet)
		game.sign_panel(game,"SMALL PARTS / POCKET STOCK" if drawers else "COMPONENTS / SHELF STOCK",Vector3(center,2.10,depth+0.10),Vector2(2.25,0.26),50,0.002)
		for i in range(group.size()):
			var kind: String = group[i]
			var bin = StaticBody3D.new()
			bin.name = "Drawer_"+kind if drawers else "Shelf_"+kind
			bin.position = Vector3(origin+(i%columns)*spacing,0.82+floorf(i/float(columns))*0.70,depth+0.40)
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
				var bounds = prop.mesh.get_aabb()
				# Rest every display component on the shelf's top face.
				prop.position = -bounds.get_center()
				prop.position.y = -0.078-bounds.position.y
				bin.add_child(prop)
			if not drawers:game.box(bin,Vector3(0,-0.30,0.282),Vector3(spacing-0.05,0.40,0.018),front)
			var icon = Sprite3D.new()
			icon.name = "PartImage"
			icon.texture = picture(kind)
			icon.pixel_size = 0.00125
			icon.position = Vector3(-spacing*0.29,0.085,0.303)
			if not drawers:icon.position.y -= 0.4
			icon.shaded = false
			bin.add_child(icon)
			var definition: Dictionary = game.model.definitions.parts[kind]
			var id = game.sign_text(bin,definition.family,Vector3(0.15,0.20,0.305),28,Color("142b35"),0.0022)
			id.name = "PartID"
			if not drawers:id.position.y -= 0.4
			var name = definition.get("short_title",definition.title.split(" · ")[-1])
			game.sign_text(bin,name,Vector3(0.15,0.10 if drawers else -0.30,0.305),15,Color("29434c"),0.0017)
			game.bin_labels[kind] = game.sign_text(bin,"",Vector3(0.15,0.0 if drawers else -0.40,0.305),16,Color("29434c"),0.0018)
	refresh()

func refresh() -> void:
	for kind in game.bins:
		var count: int = game.model.count_at(kind,"bin")
		if stock_counts.get(kind,-1) == count:continue
		stock_counts[kind] = count
		game.bin_labels[kind].text = "%d available"%count
		var prop = game.bins[kind].get_node_or_null("ShelfPart")
		if prop:prop.visible = count>0
