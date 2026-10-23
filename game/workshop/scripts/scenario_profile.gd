class_name ScenarioProfile
extends RefCounted
## Declarative launch scenarios. Every profile carries every field.
const SAVE_PATH = "user://workshop-save.json"
const LEG_CONTENT = "res://assets/leg-prototype-content.json"
const FOOT_INTRO = "Prepare the heel pads and pitch actuator, then secure them to the foot."
const RETENTION_INTRO = "M2 Hip retainer: a completed leg starts on its home rail. Dock upward, pocket the hardware, then carry ONE retaining half onto the lift shelf. Ride up and fit it. Use E / click / Q / Z; the holder stays supporting the leg."
const CRANE_INTRO = "M2 Crane delivery: completed foot and pre-beam leg supplied. Use Go to / Down / Up at the crane console, attach both magnetic ends, deliver the Upper-leg beam, fit four washer/bolt pairs and stow both ends."
const FOOT_COLLIDER_FAMILIES = ["FA-100","FA-101","FA-102","FA-103","FA-104","FA-105","FA-106","FA-200","FA-201","FA-300","FA-301","FA-302","FA-303","FA-304","FA-400","FA-401","FA-402","FA-403","FA-404"]
const IDS = ["foot","pads_single","pads_multi","leg_bay_retention","leg_bay_crane"]

static func resolve(user_args: Array, tree: SceneTree, override: String = "") -> Dictionary:
	var legacy: bool = user_args.has("--legacy-stations")
	if not override.is_empty():return profile(override,legacy)
	for arg in user_args:
		if str(arg).begins_with("--profile="):return profile(str(arg).trim_prefix("--profile="),legacy)
	var trial = ""
	for arg in user_args:
		if str(arg).begins_with("--m2-trial="):trial = str(arg).trim_prefix("--m2-trial=")
	if trial.is_empty() and tree != null and tree.has_meta("m2_trial"):trial = tree.get_meta("m2_trial")
	if user_args.has("--m2-workshop") and trial.is_empty():return {"selector":"m2"}
	if not trial.is_empty():return profile("leg_bay_"+trial,legacy)
	if user_args.has("--single-pad"):return profile("pads_single",legacy)
	if user_args.has("--pads-only") or user_args.has("--multi-test"):return profile("pads_multi",legacy)
	return profile("foot",legacy)

## `legacy_stations` swaps the supported foot fixture for the fixed foot station.
static func profile(id: String, legacy_stations: bool = false) -> Dictionary:
	if not id in IDS:
		push_error("Unknown scenario profile: "+id)
		id = "foot"
	var p = {"parent_locations":{},"foot_collider_families":FOOT_COLLIDER_FAMILIES,"id":id,"pads":"pair","pitch":true,"leg_content":"","trial":"","layout":"component_room","equipment":["foot_fixture"],"staging":"","session":{"codec":"workshop","path":SAVE_PATH},"spawn":[],"intro":FOOT_INTRO,"station_rotation":true,"prep_stations":["prep","prep2","prep3"]}
	match id:
		"foot":
			if legacy_stations:p.equipment = ["legacy_foot_station"]
		"pads_single":
			p.pads = "single";p.pitch = false;p.equipment = ["legacy_foot_station"];p.prep_stations = ["prep"]
		"pads_multi":
			p.pitch = false;p.equipment = ["legacy_foot_station"];p.prep_stations = ["prep","prep2"]
		"leg_bay_retention","leg_bay_crane":
			var trial: String = id.trim_prefix("leg_bay_")
			p.parent_locations = {"foot":"support:foot_carrier"}
			p.leg_content = LEG_CONTENT;p.trial = trial;p.layout = "leg_bay";p.staging = "leg_bay"
			p.equipment = ["leg_rail","hip_lift","lift_shelf" if trial == "retention" else "service_crane"]
			p.session = {"codec":"trial","path":"user://m2-"+trial+"-save.json"}
			p.spawn = [8.3,.03,10.5,-PI/2] if trial == "retention" else [4.0,.03,20,-PI/2]
			p.intro = RETENTION_INTRO if trial == "retention" else CRANE_INTRO
			p.station_rotation = false
	return p
