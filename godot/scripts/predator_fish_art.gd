class_name FredPredatorFishArt
extends RefCounted

const Surface = preload("res://scripts/character_surface.gd")

# Species proportions remain within the established presentation footprint.
# All positions are local (nose faces right); collision/depth are owned by Main.
static func body_contour(species: String, radii: Vector2) -> PackedVector2Array:
	var normalized := PackedVector2Array()
	if species == "BASS":
		normalized = PackedVector2Array([Vector2(-0.90,-0.18),Vector2(-0.60,-0.62),Vector2(-0.20,-0.96),Vector2(0.28,-0.94),Vector2(0.62,-0.60),Vector2(0.96,-0.23),Vector2(1.02,0.15),Vector2(0.62,0.66),Vector2(0.18,0.91),Vector2(-0.33,0.76),Vector2(-0.68,0.35),Vector2(-0.90,0.18)])
	else:
		normalized = PackedVector2Array([Vector2(-0.92,-0.17),Vector2(-0.66,-0.58),Vector2(-0.16,-0.87),Vector2(0.34,-0.76),Vector2(0.64,-0.42),Vector2(1.00,-0.19),Vector2(1.02,0.11),Vector2(0.66,0.41),Vector2(0.27,0.75),Vector2(-0.26,0.71),Vector2(-0.69,0.38),Vector2(-0.92,0.17)])
	for index in normalized.size():
		normalized[index] *= radii
	return Surface.rounded_contour(normalized)

static func _placed(points: PackedVector2Array, origin: Vector2, facing: float, pitch: float) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point in points:
		result.append(origin + Vector2(point.x * facing, point.y).rotated(pitch))
	return result

static func draw_fish(canvas: Node2D, position: Vector2, species: String, profile: Dictionary, pose: Dictionary, surface: Dictionary) -> void:
	var body := Color(profile.body)
	var back := Color(profile.back)
	var belly := Color(profile.belly)
	var marking := Color(profile.marking)
	var radii := Vector2(profile.body_radii) * Vector2(1.0, float(pose.body_breathe))
	var facing := float(profile.facing)
	var pitch := float(pose.body_pitch) * facing
	var tail_root := Vector2(-radii.x * 0.87, 0)
	var tail_sway := float(pose.tail_base) * 0.34 + float(pose.tail_tip) * 0.24
	var tail := PackedVector2Array([tail_root + Vector2(3,-4), tail_root + Vector2(-27,-20+tail_sway), tail_root + Vector2(-22,-3+tail_sway), tail_root + Vector2(-28,20+tail_sway), tail_root + Vector2(3,4)])
	Surface.draw_volume(canvas, _placed(tail, position, facing, pitch), Color(back.lightened(0.20), 0.93), 0.3)
	for ray in range(7):
		var tip := tail_root + Vector2(-24, lerpf(-18, 18, float(ray) / 6.0) + tail_sway)
		canvas.draw_polyline(_placed(PackedVector2Array([tail_root, tip]), position, facing, pitch), Color(belly, 0.36), 0.8, true)
	var dorsal := PackedVector2Array()
	var dorsal_base := -radii.x * (0.52 if species == "BASS" else 0.70)
	var dorsal_width := 43.0 if species == "BASS" else 25.0
	dorsal.append(Vector2(dorsal_base, -radii.y * 0.40))
	for spine in range(7):
		var ratio := float(spine) / 6.0
		var height := sin(ratio * PI) * (15.0 if species == "BASS" else 13.0)
		dorsal.append(Vector2(dorsal_base + ratio * dorsal_width, -radii.y * 0.66 - height - float(pose.dorsal_flex) * 0.4))
	dorsal.append(Vector2(dorsal_base + dorsal_width, -radii.y * 0.40))
	Surface.draw_volume(canvas, _placed(dorsal, position, facing, pitch), Color(back.lightened(0.20), 0.88), 0.3)
	for index in range(1, 8):
		canvas.draw_polyline(_placed(PackedVector2Array([Vector2(dorsal[index].x, -radii.y * 0.4), dorsal[index]]), position, facing, pitch), Color(belly,0.44),0.8,true)
	var contour := _placed(body_contour(species, radii), position, facing, pitch)
	Surface.draw_volume(canvas, contour, body, float(surface.wet_specular))
	var belly_shape := PackedVector2Array([Vector2(-radii.x*0.73,radii.y*0.2),Vector2(-radii.x*0.22,radii.y*0.48),Vector2(radii.x*0.40,radii.y*0.42),Vector2(radii.x*0.88,radii.y*0.15),Vector2(radii.x*0.55,radii.y*0.64),Vector2(radii.x*0.10,radii.y*0.82),Vector2(-radii.x*0.40,radii.y*0.58)])
	Surface.draw_volume(canvas, _placed(Surface.rounded_contour(belly_shape),position,facing,pitch),Color(belly,0.82),0.2)
	# Low-contrast flank scales follow body taper, leaving the face uncluttered.
	for row in range(3):
		for column in range(7):
			var x := -radii.x*0.61 + column*radii.x*0.155 + (row%2)*3.0
			var y := (row-1)*radii.y*0.38
			var center := _placed(PackedVector2Array([Vector2(x,y)]),position,facing,pitch)[0]
			canvas.draw_arc(center,3.0,0.25,PI-0.25,6,Color(belly,0.19),0.65,true)
	var pattern := str(profile.pattern)
	if pattern == "broken_lateral_band":
		for index in range(8):
			var center := Vector2(-radii.x*0.64 + index*8.0, sin(index*1.7)*1.6)
			Surface.draw_volume(canvas,_placed(Surface.ellipse(center,Vector2(6.0,3.0)),position,facing,pitch),Color(marking,0.68),0.0,true)
	elif pattern == "pale_chain_spots":
		for index in range(12):
			var center := Vector2(-radii.x*0.58+(index%6)*11.0,(-0.36 if index<6 else 0.18)*radii.y)
			Surface.draw_volume(canvas,_placed(Surface.ellipse(center,Vector2(2.8,1.6),-0.3),position,facing,pitch),Color(belly.lightened(0.12),0.68))
	elif pattern == "vertical_bars":
		for index in range(6):
			var x := -radii.x*0.58+index*10.0
			var stripe := PackedVector2Array([Vector2(x,-radii.y*0.58),Vector2(x+3,-2),Vector2(x+1,radii.y*0.42)])
			canvas.draw_polyline(_placed(stripe,position,facing,pitch),Color(marking,0.60),2.5,true)
	var gill := Vector2(radii.x*0.39, 0.5)
	Surface.draw_volume(canvas,_placed(Surface.ellipse(gill,Vector2(radii.x*0.21,radii.y*0.64)),position,facing,pitch),body.lightened(0.06),0.6)
	var gill_edge := PackedVector2Array([gill+Vector2(-4,-radii.y*0.55),gill+Vector2(-9,0),gill+Vector2(-3,radii.y*0.60)])
	canvas.draw_polyline(_placed(Surface.smooth_line(gill_edge),position,facing,pitch),back.darkened(0.12),1.5,true)
	# Fins attach behind the operculum and share the existing animation channels.
	for fin_index in range(2):
		var root_point := Vector2(radii.x*(0.25 if fin_index==0 else -0.40),radii.y*0.35)
		var tip := root_point+Vector2(-18,16+float(pose.pectoral_sweep)*0.24)
		var fin := PackedVector2Array([root_point,tip,root_point+Vector2(3,7)])
		Surface.draw_volume(canvas,_placed(fin,position,facing,pitch),Color(belly.darkened(0.24),0.86))
		for ray in range(3):
			canvas.draw_polyline(_placed(PackedVector2Array([root_point,tip+Vector2(ray*3,-ray*2)]),position,facing,pitch),Color(belly,0.45),0.7,true)
	var eye := _placed(PackedVector2Array([Vector2(radii.x*0.69,-radii.y*0.24)]),position,facing,pitch)[0]
	canvas.draw_circle(eye,4.8,back.darkened(0.35))
	canvas.draw_circle(eye-Vector2(0,0.3),3.5,Color("d5b75e"))
	canvas.draw_circle(eye+Vector2(facing*0.7,0),2.3,Color("111e20"))
	canvas.draw_circle(eye+Vector2(-0.8,-1.5),0.95,Color("fffbe8"))
	var jaw_open := float(pose.jaw_open)*0.5
	var jaw := PackedVector2Array([Vector2(radii.x*0.98,2),Vector2(radii.x*0.74,4+jaw_open),Vector2(radii.x*(0.42 if species=="BASS" else 0.62),radii.y*0.27)])
	canvas.draw_polyline(_placed(jaw,position,facing,pitch),back.darkened(0.25),2.0,true)
	if species != "BASS":
		for index in range(3):
			var tooth := Vector2(radii.x*0.91-index*4.0,4)
			canvas.draw_polyline(_placed(PackedVector2Array([tooth,tooth+Vector2(-1,2.4)]),position,facing,pitch),Color(belly,0.85),0.8,true)
	var closed := contour.duplicate()
	closed.append(contour[0])
	canvas.draw_polyline(closed,Color(back.darkened(0.25),0.88),1.2,true)
	var rim := PackedVector2Array()
	for index in range(2, 11):
		rim.append(contour[index])
	canvas.draw_polyline(rim,Color(belly.lightened(0.22),0.55),1.0,true)
