shader_type spatial;
render_mode unshaded, cull_front, depth_draw_never, shadows_disabled;

uniform vec4 outline_color : source_color = vec4(0.88, 0.96, 0.98, 1.0);
uniform float width_pixels : hint_range(1.0, 4.0) = 1.6;

void vertex() {
	vec4 clip = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	vec3 view_normal = normalize(MODELVIEW_NORMAL_MATRIX * NORMAL);
	vec2 projected_normal = (PROJECTION_MATRIX * vec4(view_normal, 0.0)).xy;
	float normal_length = length(projected_normal);
	if (normal_length > 0.001) {
		clip.xy += projected_normal / normal_length * width_pixels * 2.0 / VIEWPORT_SIZE * clip.w;
	}
	POSITION = clip;
}

void fragment() {
	ALBEDO = outline_color.rgb;
}
