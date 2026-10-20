extends Control
## Schematic, live instruction illustration: four independent mounting lanes.
var step: int = 0
var state: HeelAssemblyState
var ink = Color("a8b8be")
var accent = Color("80dfbd")

func _draw() -> void:
	var c = size * Vector2(0.5, 0.48)
	var face = PackedVector2Array([c+Vector2(-100,-52),c+Vector2(62,-78),c+Vector2(108,40),c+Vector2(-54,66)])
	var side = PackedVector2Array([face[3],face[2],face[2]+Vector2(0,14),face[3]+Vector2(0,14)])
	draw_colored_polygon(side,Color("192e39"))
	draw_colored_polygon(face,Color("31434c"))
	draw_polyline(PackedVector2Array([face[0],face[1],face[2],face[3],face[0]]),ink,1.6,true)
	var pts = [c+Vector2(-65,-29),c+Vector2(-36,34),c+Vector2(33,-45),c+Vector2(62,18)]
	var font = ThemeDB.fallback_font
	for i in range(4):
		var p: Vector2 = pts[i]
		var done = state != null and state.slots.sleeve[i] != ""
		if step >= 2 and state != null: done = state.slots.bolt[i] != ""
		draw_circle(p,10,accent if done else Color("101e26"))
		draw_arc(p,10,0,TAU,32,ink,1.5,true)
		draw_string(font,p+Vector2(-3,4),str(i+1),HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("10202a") if done else ink)
		if step == 0 and not done:
			draw_line(p+Vector2(0,-35),p+Vector2(0,-14),accent,1.5,true)
			draw_line(p+Vector2(-4,-18),p+Vector2(0,-13),accent,1.5,true)
			draw_line(p+Vector2(4,-18),p+Vector2(0,-13),accent,1.5,true)
			draw_rect(Rect2(p+Vector2(-7,-51),Vector2(14,14)),ink,false,2)
		elif step >= 2 and not done:
			draw_arc(p+Vector2(0,-25),9,0,TAU,24,accent,2,true)
			draw_line(p+Vector2(0,-59),p+Vector2(0,-35),ink,5,true)
			draw_line(p+Vector2(-9,-59),p+Vector2(9,-59),ink,5,true)
	if step == 1:
		draw_line(c+Vector2(-90,92),c+Vector2(90,92),accent,3,true)
		draw_string(font,c+Vector2(-87,113),"PREPARED PAD → SOLE CARRIER",HORIZONTAL_ALIGNMENT_LEFT,-1,12,accent)
	else:
		draw_string(font,c+Vector2(-100,109),"FOUR INDEPENDENT MOUNTING POINTS",HORIZONTAL_ALIGNMENT_LEFT,-1,11,ink)
