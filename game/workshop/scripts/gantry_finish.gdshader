shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

// Metric face UVs keep the tread and panel joints consistent on every member.
// UV2 holds the face half-extents. COLOR alpha marks actual chamfer faces;
// RGB shades recessed pockets without extra surfaces or transparent overlays.
uniform vec4 paint : source_color = vec4(0.34, 0.40, 0.42, 1.0);
uniform sampler2D grain_map : filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rough_map : filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D normal_map : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform int finish = 0; // 0 coated frame, 1 safety paint, 2 tread deck, 3 machined steel
varying vec3 face_normal;

float band(float distance_to_line, float width, float pixel) {
	return 1.0 - smoothstep(width, width + pixel, distance_to_line);
}

void vertex() {
	face_normal = NORMAL;
}

void fragment() {
	float pixel = max(length(fwidth(UV)), 0.0005);
	float grain = texture(grain_map, UV / 1.5).r;
	float rough = texture(rough_map, UV / 1.5).r;
	vec3 color = paint.rgb * mix(0.84, 1.04, grain) * COLOR.rgb;
	float edge = max(0.0, min(UV2.x - abs(UV.x), UV2.y - abs(UV.y)));
	float chips = smoothstep(0.90, 0.96, grain) * COLOR.a;
	color = mix(color, vec3(0.34, 0.36, 0.34), chips * 0.65);
	float seam = 0.0;
	float detail_visibility = 1.0 - smoothstep(0.008, 0.035, pixel);
	if (finish == 0 && min(UV2.x, UV2.y) > 0.12) {
		// Long fabricated members: quiet central panels and narrow flange edges.
		float flange = band(edge - 0.035, 0.0015, pixel) * step(0.035, edge);
		float joint = band(abs(fract((UV.x + UV2.x) / 1.6) - 0.5) * 1.6, 0.002, pixel);
		seam = max(flange, joint * 0.45) * detail_visibility;
		color *= 1.0 - seam * 0.25;
	}
	if (finish == 2 && face_normal.y > 0.9) {
		// Closed anti-slip plate, not cut-through grating over solid collision.
		vec2 cell = abs(fract(vec2(UV.x + UV.y, UV.x - UV.y) / 0.085) - 0.5);
		float tread = band(min(cell.x, cell.y) * 0.085, 0.004, pixel) * detail_visibility;
		float border = band(edge, 0.035, pixel);
		color = mix(color * (1.0 + tread * 0.18), vec3(0.43, 0.29, 0.095), border * 0.75);
		rough = mix(rough, 0.78 - tread * 0.18, 0.65);
	}
	ALBEDO = color;
	METALLIC = finish == 3 ? 0.72 : chips * 0.25;
	ROUGHNESS = finish == 3 ? mix(0.34, 0.55, rough) : clamp(0.43 + rough * 0.38, 0.43, 0.87);
	NORMAL_MAP = mix(vec3(0.5, 0.5, 1.0), texture(normal_map, UV / 1.5).rgb, 0.20 * detail_visibility);
	NORMAL_MAP_DEPTH = 0.25;
	AO = 1.0 - seam * 0.12;
}
