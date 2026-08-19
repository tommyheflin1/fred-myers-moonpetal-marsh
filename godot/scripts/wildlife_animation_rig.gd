class_name FredWildlifeAnimationRig
extends RefCounted

const SUPPORTED_KINDS: Array[String] = ["BASS", "PIKE", "MUSKIE", "SNAKE", "HERON", "BUG", "FAIRY"]

static func pose(kind: String, actor_index: int, time_seconds: float, reduced_motion: bool = false) -> Dictionary:
	var normalized_kind := kind.strip_edges().to_upper()
	if normalized_kind not in SUPPORTED_KINDS or actor_index < 0 or not is_finite(time_seconds):
		return _invalid_pose(normalized_kind, reduced_motion)
	var phase_offset := float(SUPPORTED_KINDS.find(normalized_kind)) * 0.67 + float(actor_index) * 0.83
	var phase := maxf(0.0, time_seconds) + phase_offset
	var motion_scale := 0.14 if reduced_motion else 1.0
	var result := _base_pose(normalized_kind, reduced_motion)
	match normalized_kind:
		"BASS", "PIKE", "MUSKIE":
			var species_speed := 1.0 if normalized_kind == "BASS" else (1.18 if normalized_kind == "PIKE" else 0.92)
			result.joint_count = 11
			result.body_pitch = sin(phase * 1.25 * species_speed) * 0.035 * motion_scale
			result.body_breathe = 1.0 + sin(phase * 1.72) * 0.028 * motion_scale
			result.tail_base = sin(phase * 4.4 * species_speed) * 7.0 * motion_scale
			result.tail_tip = sin(phase * 4.4 * species_speed - 0.78) * 15.0 * motion_scale
			result.dorsal_flex = cos(phase * 2.0) * 3.0 * motion_scale
			result.pectoral_sweep = sin(phase * 3.1 + 0.55) * 10.0 * motion_scale
			result.pelvic_sweep = cos(phase * 2.6) * 5.0 * motion_scale
			result.gill_open = 0.42 + (sin(phase * 2.25) + 1.0) * 0.24
			result.jaw_open = maxf(0.0, sin(phase * 1.45 - 0.4)) * 3.2 * motion_scale
			result.eye_focus = sin(phase * 0.73) * 1.5 * motion_scale
			result.material_shift = (sin(phase * 0.62) + 1.0) * 0.5
		"SNAKE":
			result.joint_count = 18
			result.body_breathe = 1.0 + sin(phase * 1.35) * 0.02 * motion_scale
			result.spine_wave = phase * 2.15 * motion_scale
			result.spine_amplitude = (14.0 + sin(phase * 0.8) * 2.0) * motion_scale
			result.head_pitch = sin(phase * 1.42) * 0.09 * motion_scale
			result.jaw_open = maxf(0.0, sin(phase * 1.1 - 0.3)) * 2.4 * motion_scale
			result.tongue_extension = maxf(0.0, sin(phase * 3.0)) * 7.0 * motion_scale
			result.eye_focus = sin(phase * 0.91) * 1.2 * motion_scale
			result.material_shift = (cos(phase * 0.55) + 1.0) * 0.5
		"HERON":
			result.joint_count = 13
			result.body_breathe = 1.0 + sin(phase * 1.16) * 0.025 * motion_scale
			result.wing_primary = sin(phase * 2.35) * 9.0 * motion_scale
			result.wing_secondary = cos(phase * 2.35 + 0.44) * 5.0 * motion_scale
			result.neck_curve = sin(phase * 0.88) * 4.0 * motion_scale
			result.head_pitch = sin(phase * 1.05 + 0.3) * 0.08 * motion_scale
			result.jaw_open = maxf(0.0, sin(phase * 0.72 - 0.8)) * 1.8 * motion_scale
			result.leg_lift = maxf(0.0, sin(phase * 1.31)) * 4.5 * motion_scale
			result.toe_spread = 2.0 + (sin(phase * 1.31) + 1.0) * 1.4 * motion_scale
			result.feather_lift = (sin(phase * 1.84) + 1.0) * 1.8 * motion_scale
			result.eye_focus = sin(phase * 0.69) * 1.0 * motion_scale
		"BUG":
			result.joint_count = 12
			result.body_pitch = sin(phase * 2.4) * 0.08 * motion_scale
			result.hover_lift = sin(phase * 3.2) * 3.0 * motion_scale
			result.wing_primary = sin(phase * 16.0) * 12.0 * motion_scale
			result.wing_secondary = -sin(phase * 16.0) * 8.0 * motion_scale
			result.leg_lift = cos(phase * 3.2) * 2.0 * motion_scale
			result.abdomen_flex = sin(phase * 2.7) * 2.4 * motion_scale
			result.eye_focus = sin(phase * 1.2) * 0.8 * motion_scale
		"FAIRY":
			result.joint_count = 14
			result.body_pitch = sin(phase * 1.7) * 0.06 * motion_scale
			result.hover_lift = sin(phase * 2.6) * 4.0 * motion_scale
			result.wing_primary = sin(phase * 10.0) * 9.0 * motion_scale
			result.wing_secondary = -sin(phase * 10.0 + 0.45) * 6.0 * motion_scale
			result.arm_sweep = sin(phase * 1.8) * 4.0 * motion_scale
			result.leg_lift = cos(phase * 1.8) * 3.0 * motion_scale
			result.crown_tilt = sin(phase * 1.15) * 0.08 * motion_scale
			result.glow = 0.74 + (sin(phase * 2.1) + 1.0) * 0.13
			result.eye_focus = sin(phase * 0.94) * 0.8 * motion_scale
	result.valid = true
	return result

static func surface_profile(kind: String, actor_index: int, time_seconds: float, reduced_motion: bool = false) -> Dictionary:
	var normalized_kind := kind.strip_edges().to_upper()
	if normalized_kind not in SUPPORTED_KINDS or actor_index < 0 or not is_finite(time_seconds):
		return _invalid_surface(normalized_kind, reduced_motion)
	var phase := maxf(0.0, time_seconds) + float(SUPPORTED_KINDS.find(normalized_kind)) * 0.61 + float(actor_index) * 0.79
	var motion_scale := 0.10 if reduced_motion else 1.0
	var result := _base_surface(normalized_kind, reduced_motion)
	result.light_shift = sin(phase * 0.54) * 0.035 * motion_scale
	result.eye_glint = 0.88 + sin(phase * 0.72) * 0.06 * motion_scale
	match normalized_kind:
		"BASS", "PIKE", "MUSKIE":
			result.volume_layers = 9
			result.key_light = 0.30
			result.underside_shadow = 0.36
			result.rim_strength = 0.44
			result.wet_specular = 0.72 + sin(phase * 0.83) * 0.04 * motion_scale
			result.joint_depth = 0.78
			result.facial_depth = 0.82
			result.surface_kind = "overlapping scales and wet muscle volume"
		"SNAKE":
			result.volume_layers = 10
			result.key_light = 0.27
			result.underside_shadow = 0.42
			result.rim_strength = 0.38
			result.wet_specular = 0.48 + sin(phase * 0.64) * 0.035 * motion_scale
			result.joint_depth = 0.90
			result.facial_depth = 0.88
			result.surface_kind = "overlapping keeled scales and muscular spine"
		"HERON":
			result.volume_layers = 11
			result.key_light = 0.34
			result.underside_shadow = 0.31
			result.rim_strength = 0.48
			result.feather_depth = 0.86
			result.joint_depth = 0.82
			result.facial_depth = 0.76
			result.surface_kind = "layered contour feathers and jointed limbs"
		"BUG":
			result.volume_layers = 9
			result.key_light = 0.31
			result.underside_shadow = 0.40
			result.rim_strength = 0.50
			result.wing_translucency = 0.66
			result.wet_specular = 0.42
			result.joint_depth = 0.72
			result.facial_depth = 0.64
			result.surface_kind = "segmented shell and translucent veined wings"
		"FAIRY":
			result.volume_layers = 10
			result.key_light = 0.36
			result.underside_shadow = 0.28
			result.rim_strength = 0.58
			result.wing_translucency = 0.74
			result.wet_specular = 0.36
			result.joint_depth = 0.76
			result.facial_depth = 0.72
			result.surface_kind = "moonlit skin, articulated limbs and luminous wings"
	result.valid = true
	return result

static func _base_pose(kind: String, reduced_motion: bool) -> Dictionary:
	return {
		"valid": false,
		"kind": kind,
		"joint_count": 0,
		"body_pitch": 0.0,
		"body_breathe": 1.0,
		"tail_base": 0.0,
		"tail_tip": 0.0,
		"dorsal_flex": 0.0,
		"pectoral_sweep": 0.0,
		"pelvic_sweep": 0.0,
		"gill_open": 0.0,
		"jaw_open": 0.0,
		"head_pitch": 0.0,
		"spine_wave": 0.0,
		"spine_amplitude": 0.0,
		"tongue_extension": 0.0,
		"wing_primary": 0.0,
		"wing_secondary": 0.0,
		"neck_curve": 0.0,
		"leg_lift": 0.0,
		"toe_spread": 0.0,
		"feather_lift": 0.0,
		"hover_lift": 0.0,
		"abdomen_flex": 0.0,
		"arm_sweep": 0.0,
		"crown_tilt": 0.0,
		"glow": 1.0,
		"eye_focus": 0.0,
		"material_shift": 0.0,
		"reduced_motion": reduced_motion,
		"presentation_only": true,
		"collision_mutation": false,
		"save_fields": 0,
	}

static func _invalid_pose(kind: String, reduced_motion: bool) -> Dictionary:
	return _base_pose(kind, reduced_motion)

static func _base_surface(kind: String, reduced_motion: bool) -> Dictionary:
	return {
		"valid": false,
		"kind": kind,
		"volume_layers": 0,
		"key_light": 0.0,
		"underside_shadow": 0.0,
		"rim_strength": 0.0,
		"wet_specular": 0.0,
		"feather_depth": 0.0,
		"wing_translucency": 0.0,
		"joint_depth": 0.0,
		"facial_depth": 0.0,
		"light_shift": 0.0,
		"eye_glint": 0.0,
		"surface_kind": "invalid",
		"reduced_motion": reduced_motion,
		"presentation_only": true,
		"collision_mutation": false,
		"save_fields": 0,
	}

static func _invalid_surface(kind: String, reduced_motion: bool) -> Dictionary:
	return _base_surface(kind, reduced_motion)
