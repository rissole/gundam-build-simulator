shader_type spatial;
// The held part's manual destination. Depth testing is disabled so the cue
// shows through walls and equipment. It stays amber: green is reserved for the
// aimed snap preview when a click would place the part.
render_mode unshaded, blend_mix, cull_back, depth_draw_never, depth_test_disabled, shadows_disabled;

uniform vec4 glow_color : source_color = vec4(1.0, 0.78, 0.12, 1.0);
uniform float pulse_seconds = 1.4;
uniform float dim_alpha = 0.10;
uniform float bright_alpha = 0.40;
uniform float rim_alpha = 0.40;
uniform float brightness = 1.3;

void fragment() {
	float pulse = 0.5 - 0.5 * cos(TIME * 6.28318530718 / pulse_seconds);
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.0);
	ALBEDO = glow_color.rgb * brightness;
	ALPHA = clamp(mix(dim_alpha, bright_alpha, pulse) + rim * rim_alpha, 0.0, 1.0);
}
