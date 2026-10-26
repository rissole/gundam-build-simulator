shader_type spatial;
// Add light over the original control surface, without replacing its material.
// Depth testing stays enabled; the guidance manager also checks sightlines.
render_mode unshaded, blend_add, cull_back, depth_draw_never, shadows_disabled;

uniform vec4 glow_color : source_color = vec4(1.0, 0.63, 0.18, 1.0);
uniform float pulse_seconds = 1.8;
uniform float dim_energy = 0.35;
uniform float bright_energy = 5.0;

void vertex() {
	// Separate the duplicate surface just enough to avoid coplanar flicker.
	VERTEX += NORMAL * 0.0005;
}

void fragment() {
	float pulse = 0.5 - 0.5 * cos(TIME * 6.28318530718 / pulse_seconds);
	ALBEDO = vec3(0.0);
	EMISSION = glow_color.rgb * mix(dim_energy, bright_energy, pulse);
	ALPHA = 1.0;
}
