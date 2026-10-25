extends RefCounted
## Small, deterministic, seamless PBR maps for the visual spike. One shared set
## per process; no downloads or per-part textures. These are material studies,
## not a replacement for authored hero assets or baked edge wear.
static var _maps: Dictionary = {}

static func maps() -> Dictionary:
	if not _maps.is_empty():return _maps
	const SIZE = 256
	var noise = FastNoiseLite.new()
	noise.seed = 41;noise.frequency = .035;noise.fractal_octaves = 4
	var broad: Image = noise.get_seamless_image(SIZE,SIZE)
	noise.seed = 113;noise.frequency = .24;noise.fractal_octaves = 2
	var grain: Image = noise.get_seamless_image(SIZE,SIZE)
	var albedo = Image.create_empty(SIZE,SIZE,false,Image.FORMAT_RGB8)
	var rough = Image.create_empty(SIZE,SIZE,false,Image.FORMAT_RGB8)
	var normal = Image.create_empty(SIZE,SIZE,false,Image.FORMAT_RGB8)
	var paint = Image.create_empty(SIZE,SIZE,false,Image.FORMAT_RGB8)
	for y in SIZE:
		for x in SIZE:
			var cloud = broad.get_pixel(x,y).r
			var grit = grain.get_pixel(x,y).r
			# Irregular sealed patches, fine aggregate and gentle parallel scuffs.
			# World mapping keeps their scale independent of each slab's size.
			var scuff = pow(maxf(0.0,sin(TAU*y/16.0)),16.0)*smoothstep(.45,.7,cloud)
			var value = clampf(.63+cloud*.32+grit*.06-scuff*.06,.5,1.0)
			albedo.set_pixel(x,y,Color(value,value,value))
			var polish = smoothstep(.35,.67,cloud)
			var r = clampf(.88-polish*.52+grit*.06+scuff*.10,.3,.96)
			rough.set_pixel(x,y,Color(r,r,r))
			var dx = grain.get_pixel((x+1)%SIZE,y).r-grain.get_pixel((x+SIZE-1)%SIZE,y).r
			var dy = grain.get_pixel(x,(y+1)%SIZE).r-grain.get_pixel(x,(y+SIZE-1)%SIZE).r
			var n = Vector3(-dx*.7,-dy*.7,1).normalized()*.5+Vector3.ONE*.5
			normal.set_pixel(x,y,Color(n.x,n.y,n.z))
			var coating = .84+cloud*.12+grit*.04
			paint.set_pixel(x,y,Color(coating,coating,coating))
	var sources = {"albedo":albedo,"roughness":rough,"normal":normal,"paint":paint}
	for entry in sources:
		var source: Image = sources[entry]
		source.generate_mipmaps()
		_maps[entry] = ImageTexture.create_from_image(source)
	return _maps

static func concrete(mat: StandardMaterial3D, tile_metres: float = 4.0) -> StandardMaterial3D:
	var textures = maps()
	_mapping(mat,tile_metres,true)
	mat.albedo_texture = textures.albedo
	mat.roughness = 1.0
	mat.roughness_texture = textures.roughness
	mat.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	mat.normal_enabled = true;mat.normal_texture = textures.normal;mat.normal_scale = .55
	return mat

static func coating(mat: StandardMaterial3D, tile_metres: float = 1.5) -> StandardMaterial3D:
	var textures = maps()
	# Local mapping: painted equipment can move without sliding through its wear.
	_mapping(mat,tile_metres,false)
	mat.albedo_texture = textures.paint
	mat.roughness = .85
	mat.roughness_texture = textures.roughness
	mat.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	mat.normal_enabled = true;mat.normal_texture = textures.normal;mat.normal_scale = .18
	return mat

static func _mapping(mat: StandardMaterial3D, tile_metres: float, world: bool) -> void:
	mat.uv1_triplanar = true;mat.uv1_world_triplanar = world
	mat.uv1_scale = Vector3.ONE/tile_metres
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
