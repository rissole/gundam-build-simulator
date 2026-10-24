extends RefCounted
## Hangar lighting and room finish, previewed in Blender before implementation.
## A dim cool ambient and one shadowed key leave contrast to narrow roof beams
## pooled on each work bay. Everything here is visual: the blockout floor and
## wall solids keep their collision, and nothing enters a bay, route or the
## crane envelope (fittings sit at walls, on the floor surface or above 23.8 m).
## Compatibility draws unshadowed lights in one pass but limits them to 32 per
## frame and 8 spots per mesh, so the rig uses 17 spots, the floor is split
## into 4 m slabs (at most 8 cones reach any one) and the walls into panels.
## General high-bay fixtures only glow.
const AMBIENT = 0.11
const KEY = 0.16
# Blender preview watts -> Godot energy with physical (squared) falloff.
const WATTS_TO_ENERGY = 1.0/(4.0*PI*PI)
# Inner faces: axis, plane, inward sign.
const WALLS = {"W":["x",-13.85,1.0],"E":["x",25.85,-1.0],"S":["z",-8.85,1.0],"N":["z",38.85,-1.0]}
const DOOR = Vector2(2.25,23.75)
const GANTRY_PAD = [3.5,22.5,24.0,37.5]
var game: Node
var root: Node3D
var mats: Dictionary = {}

func _init(workshop: Node) -> void:
	game = workshop

func build(env: Environment, key: DirectionalLight3D) -> void:
	root = Node3D.new();root.name = "HangarDressing";game.add_child(root)
	_environment(env,key)
	_materials()
	var blockout: Node3D = game.leg_layout.blockout
	for id in ["floor","wall_x-14","wall_x26","wall_z-9","wall_z39"]:blockout.pieces[id].visual.visible = false
	blockout.pieces.roof.visual.material_override = mats.deck
	for id in blockout.pieces:
		if id.begins_with("truss"):blockout.pieces[id].visual.material_override = mats.truss
	var bays: Array = []
	for id in game.leg_layout.layout().workshop.bays:bays.append([id]+Array(game.leg_layout.layout().workshop.bays[id].bounds))
	_floor(bays)
	_walls()
	_roof()
	_services()
	_door()
	_lights(bays)

func _environment(env: Environment, key: DirectionalLight3D) -> void:
	# Background only shows in metal reflections inside the closed hall.
	env.background_color = Color("4a5154")
	env.ambient_light_color = Color("9fb0bc")
	env.ambient_light_energy = AMBIENT
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.08
	# Light depth haze lets the far end of the 48 m hall recede.
	env.fog_enabled = true
	env.fog_light_color = Color("484f52")
	env.fog_density = 0.003
	env.fog_sky_affect = 0.0
	key.rotation_degrees = Vector3(-72,-25,0)
	key.light_energy = KEY
	key.light_color = Color("ffe9cf")
	key.shadow_opacity = 0.9

func _materials() -> void:
	var concrete = _noise_texture()
	for i in 4:
		var slab = _mat(["6d716e","6a6e6b","707370","676b68"][i],.78)
		_triplanar(slab,concrete,null,.25);mats["slab%d" % i] = slab
	mats.joint = _mat("3f4241",.95)
	mats.epoxy = _mat("5a605e",.32)
	mats.dado = _triplanar(_mat("8a8d88",.88),concrete,null,.3)
	mats.cladding = _triplanar(_mat("a2a7a2",.7),null,_rib_texture(false),1.0/.6)
	mats.upper = _mat("70777a",.85)
	mats.glazing = _mat("9fb3c2",.3,0,"cfdeea",2.4)
	mats.mullion = _mat("2d3335",.6,.3)
	mats.truss = _mat("4f585a",.6,.25)
	# Faint emission stands in for light bounced off the floor: no GI here.
	mats.deck = _triplanar(_mat("7a8184",.6,0,"b9c2c6",.14),null,_rib_texture(false),1.0/.8)
	mats.fixture = _mat("2a2f31",.5,.4)
	mats.lens = _mat("fff4e2",.3,0,"fff1dc",10.0)
	mats.led = _mat("e9f2ff",.3,0,"e3eeff",6.0)
	mats.door = _triplanar(_mat("7e8789",.55),null,_rib_texture(true),1.0)
	mats.frame = _mat("2d3335",.6,.3)
	mats.hazard = _triplanar(_mat("ffffff",.6),_hazard_texture(),null,1.0/.4)
	mats.panel = _mat("8e9694",.5,.2)
	mats.status = _mat("22ff66",.4,0,"38e070",2.0)
	mats.amber = _mat("ffaa33",.4,0,"ffb040",4.0)
	# Muted and matte so fire points read as building fabric, not interactables.
	mats.fire = _mat("5e3e3b",.85)
	mats.tray = _mat("6f7778",.45,.6)
	mats.duct = _mat("9aa1a2",.35,.7)

func _mat(color: String, rough: float, metal: float = 0.0, emit: String = "", energy: float = 0.0) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(color);mat.roughness = rough;mat.metallic = metal
	if not emit.is_empty():
		mat.emission_enabled = true;mat.emission = Color(emit);mat.emission_energy_multiplier = energy
	return mat

func _triplanar(mat: StandardMaterial3D, albedo: Texture2D, normal: Texture2D, scale: float) -> StandardMaterial3D:
	mat.uv1_triplanar = true;mat.uv1_world_triplanar = true;mat.uv1_scale = Vector3.ONE*scale
	if albedo != null:mat.albedo_texture = albedo
	if normal != null:
		mat.normal_enabled = true;mat.normal_texture = normal;mat.normal_scale = .8
	return mat

func _noise_texture() -> ImageTexture:
	var noise = FastNoiseLite.new();noise.seed = 7;noise.frequency = .03;noise.fractal_octaves = 5
	var source: Image = noise.get_seamless_image(128,128)
	var image = Image.create_empty(128,128,false,Image.FORMAT_RGB8)
	for y in 128:
		for x in 128:
			var v = lerpf(.86,1.0,source.get_pixel(x,y).r)
			image.set_pixel(x,y,Color(v,v,v))
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)

func _rib_texture(horizontal: bool) -> ImageTexture:
	# One profiled-sheet rib per tile, as a tangent-space normal map.
	var image = Image.create_empty(32,32,false,Image.FORMAT_RGB8)
	for y in 32:
		for x in 32:
			var slope = .6*cos(TAU*(y if horizontal else x)/32.0)
			var n = (Vector3(0,-slope,1) if horizontal else Vector3(-slope,0,1)).normalized()*.5+Vector3.ONE*.5
			image.set_pixel(x,y,Color(n.x,n.y,n.z))
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)

func _hazard_texture() -> ImageTexture:
	var image = Image.create_empty(32,32,false,Image.FORMAT_RGB8)
	for y in 32:
		for x in 32:image.set_pixel(x,y,Color("c9a640") if (x+y)%32 < 16 else Color("222526"))
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)

func _box(at: Vector3, size: Vector3, mat: Material, shadow: bool = false) -> MeshInstance3D:
	var mesh: MeshInstance3D = game.box(root,at,size,mat)
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadow else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mesh

func _multi(mesh: Mesh, transforms: Array, mat: Material) -> void:
	# Repeated fittings draw as one call; Compatibility has no auto-instancing.
	var multimesh = MultiMesh.new();multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = mesh;multimesh.instance_count = transforms.size()
	for i in transforms.size():multimesh.set_instance_transform(i,transforms[i])
	var node = MultiMeshInstance3D.new();node.multimesh = multimesh;node.material_override = mat
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;root.add_child(node)

static func _scaled(at: Vector3, size: Vector3, basis: Basis = Basis.IDENTITY) -> Transform3D:
	return Transform3D(basis*Basis.from_scale(size),at)

## A box on a wall's inner face, `offset` to `offset+depth` into the room.
func _wall_box(wall: String, a0: float, a1: float, y0: float, y1: float, offset: float, depth: float, mat: Material, shadow: bool = false) -> MeshInstance3D:
	return _box(_wall_at(wall,(a0+a1)/2,(y0+y1)/2,offset+depth/2),_wall_size(wall,a1-a0,y1-y0,depth),mat,shadow)

func _wall_at(wall: String, along: float, y: float, depth: float) -> Vector3:
	var spec: Array = WALLS[wall];var across: float = spec[1]+spec[2]*depth
	return Vector3(across,y,along) if spec[0] == "x" else Vector3(along,y,across)

func _wall_size(wall: String, length: float, height: float, depth: float) -> Vector3:
	return Vector3(depth,height,length) if WALLS[wall][0] == "x" else Vector3(length,height,depth)

## Spans along a wall: long walls run into the end walls; end walls stop at
## the long walls' fittings (`inset`), and the north wall skips the door.
func _runs(wall: String, inset: float) -> Array:
	if wall in ["W","E"]:return [[-9.0,39.0]]
	var runs = [[-13.85+inset,25.85-inset]]
	if wall == "N":runs = [[-13.85+inset,DOOR.x],[DOOR.y,25.85-inset]]
	return runs

func _floor(bays: Array) -> void:
	# 4 m slabs with 15 mm sawcut joints over a dark base. One mesh per slab
	# keeps every floor surface within reach of at most 8 spot cones.
	_box(Vector3(6,-.1,15),Vector3(40,.16,48),mats.joint)
	for ix in 10:
		for iz in 12:
			_box(Vector3(-12+ix*4,-.04,-7+iz*4),Vector3(3.985,.08,3.985),mats["slab%d" % ((ix*3+iz*5)%4)])
	# Sealed bay pads mark work areas by tone rather than outlines. 3 mm keeps
	# them clear of the 4 mm cassette pads and the 12 mm corner marks.
	for bay in bays+[["gantry"]+GANTRY_PAD]:
		_box(Vector3((bay[1]+bay[2])/2,.0015,(bay[3]+bay[4])/2),Vector3(bay[2]-bay[1],.003,bay[4]-bay[3]),mats.epoxy)

func _walls() -> void:
	for wall in WALLS:
		var long = wall in ["W","E"]
		# Cladding replaces the hidden wall visual in panels (shadows as before).
		var a0 = -9.0 if long else -13.85;var a1 = 39.0 if long else 25.85
		var count = 6 if long else 5
		for i in count:
			var p0 = a0+(a1-a0)*i/count
			_wall_box(wall,p0,p0+(a1-a0)/count,0,25,-.3,.3,mats.cladding,true)
		# Precast dado to 3.2 m in ~4 m panels with dark joints.
		for run in _runs(wall,.08):
			var n = maxi(1,int((run[1]-run[0])/4.0))
			for i in n:
				var p0 = run[0]+(run[1]-run[0])*i/n
				_wall_box(wall,p0+.01,p0+(run[1]-run[0])/n-.01,0,3.2,0,.08,mats.dado)
		for run in _runs(wall,.35):_wall_box(wall,run[0],run[1],4.55,4.65,0,.35,mats.tray)
		# Dark top band so the roof recedes; it runs behind the door head.
		_wall_box(wall,a0 if long else -13.81,a1 if long else 25.81,21.6,25,0,.04,mats.upper)
		if long:_clerestory(wall)

func _clerestory(wall: String) -> void:
	_wall_box(wall,-8,38,17.4,21.2,0,.03,mats.glazing)
	var bars: Array = []
	for i in 24:bars.append(_scaled(_wall_at(wall,-8+i*2,19.3,.05),_wall_size(wall,.12,3.8,.10)))
	# Transoms sit 1 cm behind the mullion faces so the crossings never coincide.
	for y in [17.35,19.3,21.25]:bars.append(_scaled(_wall_at(wall,15,y,.045),_wall_size(wall,46,.12,.09)))
	_multi(BoxMesh.new(),bars,mats.mullion)
	# Supply duct, slim enough to pass inside the east crane columns.
	var duct = CylinderMesh.new();duct.top_radius = .3;duct.bottom_radius = .3;duct.height = 48;duct.radial_segments = 16
	_multi(duct,[Transform3D(Basis(Vector3.RIGHT,PI/2),_wall_at(wall,15,15,.42))],mats.duct)
	var straps: Array = []
	for z in range(-6,38,6):straps.append(_scaled(_wall_at(wall,z,15.32,.21),_wall_size(wall,.08,.06,.42)))
	_multi(BoxMesh.new(),straps,mats.mullion)

func _roof() -> void:
	# Bottom chords and Warren webs stay above the crane bridge (top 23.3 m).
	var parts: Array = []
	var rise = 24.5-23.95;var bay = 1.98;var tilt = atan2(rise,bay)
	for z in [-6,2,10,18,26,34]:
		parts.append(_scaled(Vector3(6,23.95,z),Vector3(39.6,.22,.22)))
		for i in 20:
			var x = -13.8+(i+.5)*bay
			parts.append(_scaled(Vector3(x,(23.95+24.5)/2,z),Vector3(Vector2(bay,rise).length(),.1,.1),Basis(Vector3.BACK,tilt if i%2 else -tilt)))
	_multi(BoxMesh.new(),parts,mats.truss)
	# General high-bays glow between trusses; ambient and the key carry fill.
	var bodies: Array = [];var lenses: Array = []
	for x in [-7.0,6.0,19.0]:
		for z in [-2.0,6.0,14.0,22.0,30.0]:
			bodies.append(_scaled(Vector3(x,24.55,z),Vector3(.76,.5,.76)))
			lenses.append(_scaled(Vector3(x,24.29,z),Vector3(.68,.02,.68)))
	var cylinder = CylinderMesh.new();cylinder.top_radius = .5;cylinder.bottom_radius = .5;cylinder.height = 1;cylinder.radial_segments = 20
	_multi(cylinder,bodies,mats.fixture)
	_multi(cylinder,lenses,mats.lens)

func _services() -> void:
	# Column hazard sleeves start on each foot plate.
	for x in [-12.5,25.3]:
		for z in [-7.0,1.0,19.0,37.0]:_box(Vector3(x,.84,z),Vector3(.44,1.2,.44),mats.hazard)
	for x in [8.8,17.2]:_box(Vector3(x,.9,31.1),Vector3(.64,1.2,.64),mats.hazard)
	# Distribution boards with one dim status lamp, and flush fire points.
	for item in [["W",4.0],["W",26.0],["E",3.0],["E",22.0],["E",31.0]]:
		var wall: String = item[0];var along: float = item[1]
		_box(_wall_at(wall,along,1.6,.08+.15),_wall_size(wall,1.2,1.8,.3),mats.panel)
		_box(_wall_at(wall,along-.4,2.35,.38+.015),_wall_size(wall,.08,.08,.03),mats.status)
		_box(_wall_at(wall,along+1.6,1.25,.08+.05),_wall_size(wall,.4,.7,.1),mats.fire)

func _door() -> void:
	# The final bay's hangar door: the finished robot's way out.
	for x in [2.6,23.4]:
		_box(Vector3(x,10.5,38.6),Vector3(.7,21,.5),mats.frame)
		_box(Vector3(x,1.0,38.32),Vector3(.72,2.0,.06),mats.hazard)
	_box(Vector3(13,21.3,38.6),Vector3(21.5,.8,.5),mats.frame)
	_box(Vector3(13,10.45,38.78),Vector3(20.1,20.9,.12),mats.door)
	_box(Vector3(13,21.85,38.3),Vector3(.6,.3,.1),mats.amber)

func _lights(bays: Array) -> void:
	# Roof task beams pool on each bay; long bays get two narrower beams.
	var lamps: Array = [];var lenses: Array = []
	for bay in bays:
		var lx: float = bay[2]-bay[1];var lz: float = bay[4]-bay[3]
		var n = 2 if maxf(lx,lz) > 2.5*minf(lx,lz) else 1
		for i in n:
			var f = (i+.5)/n
			var at = Vector3(bay[1]+lx*f if lx >= lz else (bay[1]+bay[2])/2,24.35,bay[3]+lz*f if lz > lx else (bay[3]+bay[4])/2)
			var r = maxf(lx/(n if lx >= lz else 1),lz/(n if lz > lx else 1))/2
			_spot(at,Vector3.DOWN,rad_to_deg(atan((r+.5)/24.3)),26000,Color("fff0dc"),40,2.0,24.35)
			lamps.append(_scaled(at+Vector3(0,.25,0),Vector3(.56,.4,.56)))
			lenses.append(_scaled(at+Vector3(0,.04,0),Vector3(.48,.02,.48)))
	var cylinder = CylinderMesh.new();cylinder.top_radius = .5;cylinder.bottom_radius = .5;cylinder.height = 1;cylinder.radial_segments = 16
	_multi(cylinder,lamps,mats.fixture)
	_multi(cylinder,lenses,mats.lens)
	# Warm column floods rake across the bays from 9 m.
	for flood in [[-12.1,1.0,-4.0,8.0],[-12.1,19.0,-6.0,19.0],[24.9,1.0,14.0,4.0],[24.9,19.0,15.0,14.0]]:
		var x: float = flood[0];var z: float = flood[1]
		_box(Vector3(x,9,z),Vector3(.5,.35,.5),mats.fixture)
		var at = Vector3(x+(.3 if x < 0 else -.3),8.9,z)
		var aim = Vector3(flood[2]-x,-9,flood[3]-z)
		_spot(at,aim,27.5,6500,Color("ffd9a8"),30,1.2,aim.length())
	# Cool clerestory daylight: broad and shadowless from each long wall.
	for side in [[-13.0,1.0],[25.0,-1.0]]:
		_spot(Vector3(side[0],19,13),Vector3(side[1],-.8,0),55,11000,Color("cfe0f0"),32,1.0,20)
	# Gantry: LED strips under each deck, downlights under the lower two.
	var strips: Array = []
	for y in [8.3,11.1,13.9]:
		for x in [4.25,21.75]:strips.append(_scaled(Vector3(x,y-.11,31),Vector3(.08,.02,12)))
		if y < 13:_spot(Vector3(13,y-.15,31),Vector3.DOWN,75,5500,Color("e3eeff"),16,1.0,8)
	_multi(BoxMesh.new(),strips,mats.led)

## Spot sized from the Blender preview's watts, compensating Godot's range
## window at the distance the beam is meant to land.
func _spot(at: Vector3, direction: Vector3, half_angle: float, watts: float, color: Color, reach: float, edge: float, landing: float) -> void:
	var light = SpotLight3D.new()
	var up = Vector3.FORWARD if absf(direction.normalized().y) > .9 else Vector3.UP
	light.transform = Transform3D(Basis.looking_at(direction,up),at)
	var window = pow(maxf(1.0-pow(landing/reach,4),.05),2)
	light.light_energy = watts*WATTS_TO_ENERGY/window
	light.light_color = color
	light.spot_range = reach;light.spot_attenuation = 2.0
	light.spot_angle = half_angle;light.spot_angle_attenuation = edge
	light.shadow_enabled = false
	light.distance_fade_enabled = false
	root.add_child(light)
