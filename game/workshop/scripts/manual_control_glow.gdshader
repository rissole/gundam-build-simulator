shader_type spatial;
// Tint the control's own faces with a soft pulse. Alpha blending keeps the
// original shading readable; a brighter fresnel rim carries the silhouette.
// Depth testing stays enabled; the guidance manager also checks sightlines.
render_mode unshaded, blend_mix, cull_back, depth_draw_never, shadows_disabled;

uniform vec4 glow_color : source_color = vec4(1.0, 0.74, 0.3, 1.0);
uniform float pulse_seconds = 1.4;
uniform float dim_alpha = 0.12;
uniform float bright_alpha = 0.55;
uniform float rim_alpha = 0.35;

void vertex() {
	// Separate the duplicate surface just enough to avoid coplanar flicker.
	VERTEX += NORMAL * 0.0005;
}

void fragment() {
	float pulse = 0.5 - 0.5 * cos(TIME * 6.28318530718 / pulse_seconds);
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.0);
	ALBEDO = glow_color.rgb * 1.4;
	ALPHA = clamp(mix(dim_alpha, bright_alpha, pulse) + rim * rim_alpha, 0.0, 1.0);
}
