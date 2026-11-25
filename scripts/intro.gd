extends Node
## The MarkoLabs developer intro, before the main menu (v0.9.155).
## A thinking statue in a spotlight; a space goblin walks in, hops up onto the rock
## and his back, then takes the head off with three tinks of his pickaxe
## and sits on the stump. Drawn in code on a 480x270 stage rendered at 4x with MSAA. Any key or click skips it. Plays every launch
## unless Settings > "Skip developer intro" is on.

const GD = preload("res://scripts/game_data.gd")
const Settings = preload("res://scripts/settings.gd")

const MENU := "res://scenes/menu.tscn"
const STAGE := Vector2i(480, 270)
const S := 1.5                 # statue art is designed on a 320x180 grid
const K := 1.6                 # the goblin is designed small and drawn 1.6x
const OY := -8.0               # the stage sits a little high, leaving room for the logo
const FLOOR := 240.0

# Timeline (seconds)
const T_LIGHT := 0.3
const T_WALK0 := 0.6
const T_WALK1 := 1.45
# Mario-style hops: [start, end, from, to, arc height]: onto the rock, then up onto his back
# (the top of it, behind the neck, where he swings from).
const JUMPS := [
	[1.5, 1.8, Vector2(166, 240), Vector2(192, 183), 26.0],
	[1.9, 2.3, Vector2(192, 183), Vector2(240, 100), 34.0],
]
const T_ONHEAD1 := 2.75   # a little wave at you from his back, then to work
const TINKS := [3.05, 3.45, 3.85]
const T_HOP0 := 4.15
const T_HOP1 := 4.5
const T_LOGO := 4.55
const T_OUT0 := 6.75
const T_OUT1 := 7.45
const RES := 4.0   # the 480x270 stage renders at 4x (1920x1080) with MSAA, so edges stay smooth

const GOB := {
	"sk": Color("7cc24a"), "sk_d": Color("4e8a2b"), "sk_l": Color("a6e070"), "ol": Color("0f170b"),
	"su": Color("3d3658"), "su_d": Color("2a2540"), "gog": Color("5fd6e8"), "eye": Color("f6e35a"),
	"wood": Color("9a6a35"), "wood_d": Color("6a4420"), "iron": Color("b9c3cd"), "tooth": Color("f2efe2"),
	"boot": Color("231f33"),
}
const LIGHT_COL := Color(220.0 / 255.0, 232.0 / 255.0, 1.0)

# Drawn over the stage picture (UV = the 480x270 stage). The spotlight cone matches
# _background(): 146..186 wide at the top, 94..238 at the floor, in statue units (x1.5)
# moved by OY.
const SMOKE_SHADER := """shader_type canvas_item;
uniform float light = 1.0;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}
float fbm(vec2 p) {
	float v = 0.0; float a = 0.5;
	for (int i = 0; i < 5; i++) { v += a * noise(p); p = p * 2.03 + vec2(1.7, 9.2); a *= 0.5; }
	return v;
}
void fragment() {
	vec4 base = texture(TEXTURE, UV);
	vec2 p = UV * vec2(480.0, 270.0);
	float top = -8.0; float floor_y = 232.0;
	float f = clamp((p.y - top) / (floor_y - top), 0.0, 1.0);
	float l = mix(219.0, 141.0, f); float r = mix(279.0, 357.0, f);
	float soft = 8.0 + 26.0 * f;
	float cone = smoothstep(l - soft, l + soft, p.x) * (1.0 - smoothstep(r - soft, r + soft, p.x));
	cone *= 1.0 - 0.35 * f;                        // brightest near the lamp
	float n1 = fbm(p * 0.011 + vec2(TIME * 0.035, -TIME * 0.012));
	float n2 = fbm(p * 0.023 + vec2(-TIME * 0.05, TIME * 0.02) + 5.0);
	float smoke = smoothstep(0.38, 0.78, n1 * 0.65 + n2 * 0.35);
	vec3 lit = vec3(0.86, 0.9, 1.0);
	base.rgb += lit * smoke * cone * 0.20 * light;  // smoke glowing in the beam
	base.rgb += lit * smoke * 0.022;                // a faint haze everywhere
	// Dust motes drifting down through the beam.
	vec2 cell = floor(p / 5.0 + vec2(0.0, -TIME * 0.5));
	float m = hash(cell);
	vec2 inside = fract(p / 5.0 + vec2(0.0, -TIME * 0.5)) - 0.5;
	float mote = step(0.982, m) * (1.0 - smoothstep(0.05, 0.16, length(inside)));
	base.rgb += vec3(1.0, 0.97, 0.9) * mote * cone * 0.55 * light * (0.6 + 0.4 * sin(TIME * 3.0 + m * 40.0));
	COLOR = base;
}
"""

# The same grit as the title screen (menu.gd _build_grit).
const GRIT_SHADER := """shader_type canvas_item;
float rand(vec2 co) { return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453); }
void fragment() {
	vec2 uv = UV;
	float d = distance(uv * vec2(1.0, 0.8), vec2(0.5, 0.4));
	float vig = smoothstep(0.3, 0.85, d);
	float grain = rand(floor(uv * vec2(960.0, 540.0)) + floor(TIME * 10.0) * 0.137) - 0.5;
	float scan = 0.5 + 0.5 * sin(uv.y * 1080.0 * 1.57);
	vec3 col = vec3(0.5 + grain * 0.5) * (1.0 - vig);
	float alpha = max(vig * 0.72, 0.045) + scan * 0.02;
	COLOR = vec4(col, alpha);
}
"""
const OFFS := [Vector2(-0.6, 0), Vector2(0.6, 0), Vector2(0, -0.6), Vector2(0, 0.6)]   # outline thickness (statue units)
const GOB_OFFS := [Vector2(-0.45, 0), Vector2(0.45, 0), Vector2(0, -0.45), Vector2(0, 0.45)]   # the goblin's (goblin units)

# --- statue shapes (designed on a 320x180 grid, drawn 1.5x) -------------------------
const COL := {
	"bg": Color("06080f"),
	"floor": Color("0c101b"),
	"floor_edge": Color("141a29"),
	"st": Color("7d87a9"),
	"st_l": Color("a7b1cf"),
	"st_d": Color("59617f"),
	"st_dd": Color("3d4462"),
	"ol": Color("12151f"),
	"rk": Color("4f5366"),
	"rk_l": Color("6b7086"),
	"rk_d": Color("363949"),
}
const ROCK := [
	["rk", [Vector2(110, 162), Vector2(113, 138), Vector2(120, 126), Vector2(134, 120), Vector2(176, 118), Vector2(194, 121), Vector2(206, 130), Vector2(210, 162)]],
	["rk_l", [Vector2(120, 126), Vector2(134, 120), Vector2(176, 118), Vector2(194, 121), Vector2(200, 126), Vector2(170, 125), Vector2(132, 127)]],
	["rk_d", [Vector2(110, 162), Vector2(113, 145), Vector2(150, 150), Vector2(210, 148), Vector2(210, 162)]],
]
const BODY := [
	["st_dd", [Vector2(150, 118), Vector2(178, 114), Vector2(186, 118), Vector2(184, 126), Vector2(176, 126), Vector2(152, 128)]],
	["st_dd", [Vector2(178, 118), Vector2(186, 120), Vector2(184, 148), Vector2(190, 152), Vector2(190, 156), Vector2(176, 156), Vector2(176, 150), Vector2(178, 132)]],
	["st_d", [Vector2(150, 80), Vector2(160, 76), Vector2(170, 98), Vector2(184, 112), Vector2(186, 118), Vector2(180, 120), Vector2(166, 104), Vector2(152, 90)]],
	["st", [Vector2(138, 118), Vector2(136, 100), Vector2(139, 86), Vector2(147, 74), Vector2(158, 67), Vector2(168, 66), Vector2(176, 70), Vector2(176, 80), Vector2(170, 96), Vector2(162, 108), Vector2(158, 122), Vector2(140, 124)]],
	["st", [Vector2(142, 112), Vector2(170, 106), Vector2(186, 108), Vector2(192, 114), Vector2(188, 122), Vector2(166, 124), Vector2(146, 126)]],
	["st", [Vector2(182, 112), Vector2(192, 114), Vector2(192, 124), Vector2(188, 146), Vector2(196, 152), Vector2(198, 158), Vector2(180, 158), Vector2(180, 152), Vector2(184, 130)]],
	["st", [Vector2(164, 70), Vector2(174, 70), Vector2(184, 100), Vector2(188, 110), Vector2(180, 112), Vector2(172, 96)]],
	["st", [Vector2(180, 112), Vector2(188, 110), Vector2(194, 82), Vector2(194, 66), Vector2(186, 64), Vector2(184, 80)]],
]
const HAND := [
	["st", [Vector2(184, 66), Vector2(195, 62), Vector2(198, 67), Vector2(194, 71), Vector2(186, 72)]],
]
const LIGHT := [
	["st_d", [Vector2(166, 92), Vector2(172, 94), Vector2(164, 106), Vector2(158, 124), Vector2(154, 124), Vector2(158, 108)]],
	["st_d", [Vector2(146, 126), Vector2(166, 124), Vector2(188, 122), Vector2(186, 126), Vector2(160, 128)]],
	["st_d", [Vector2(184, 130), Vector2(188, 146), Vector2(184, 148)]],
	["st_l", [Vector2(151, 73), Vector2(161, 67), Vector2(170, 65), Vector2(175, 67), Vector2(162, 70), Vector2(149, 79), Vector2(143, 84)]],
	["st_l", [Vector2(147, 74), Vector2(158, 67), Vector2(168, 66), Vector2(174, 68), Vector2(166, 70), Vector2(152, 75), Vector2(141, 84)]],
	["st_l", [Vector2(146, 113), Vector2(170, 107), Vector2(186, 109), Vector2(190, 112), Vector2(170, 110), Vector2(150, 116)]],
	["st_l", [Vector2(164, 70), Vector2(174, 70), Vector2(176, 74), Vector2(168, 74)]],
	["st_l", [Vector2(184, 66), Vector2(195, 62), Vector2(197, 65), Vector2(188, 67)]],
	["st_d", [Vector2(138, 118), Vector2(137, 104), Vector2(142, 112), Vector2(146, 124), Vector2(140, 124)]],
	["st_d", [Vector2(162, 108), Vector2(158, 122), Vector2(152, 124), Vector2(156, 112)]],
]
const HEAD := [
	["st", [Vector2(-5, 0), Vector2(-7, -6), Vector2(-6, -12), Vector2(-1, -16), Vector2(6, -16), Vector2(11, -12), Vector2(13, -6), Vector2(15, -2), Vector2(14, 2), Vector2(10, 4), Vector2(4, 3), Vector2(0, 2)]],
	["st_l", [Vector2(-6, -12), Vector2(-1, -16), Vector2(6, -16), Vector2(11, -12), Vector2(6, -13), Vector2(-1, -13)]],
	["st_d", [Vector2(-5, 0), Vector2(-7, -6), Vector2(-4, -6), Vector2(-1, 1)]],
	["st_dd", [Vector2(6, -8), Vector2(10, -8), Vector2(9, -6)]],
	["st_d", [Vector2(12, -6), Vector2(15, -2), Vector2(13, -1)]],
]
const NECK_CUT := [Vector2(-5, 0), Vector2(0, 2), Vector2(4, 3), Vector2(2, -1), Vector2(-3, -2)]
const SEAMS := [[Vector2(166, 104), Vector2(182, 112)], [Vector2(152, 126), Vector2(146, 126)], [Vector2(176, 70), Vector2(184, 98)]]
const NECK_PIVOT := Vector2(175, 64)

var _t := 0.0
var _leaving := false
var _leave_t := 0.0
var _stage: Node2D
var _view: SubViewport
var _overlay: Control
var _fade: ColorRect
var _smoke: ShaderMaterial
var _players: Array = []
var _streams := {}
var _fired := {}
var _step_n := -1
var _rung_n := -1
# the head, once it's off
var _head_pos := Vector2.ZERO
var _head_vel := Vector2.ZERO
var _head_rot := 0.0
var _head_loose := false
var _head_landed := false
var _sim_left := 0.0
# derived geometry
var _neck := Vector2.ZERO
var _head_c := Vector2.ZERO
var _ladder_foot := Vector2(150.0, FLOOR)
var _ladder_top := Vector2(219.0, 108.0)
var _ladder_len := 0.0
var _ladder_ang := 0.0
var _shoulder := Vector2.ZERO
var _seat := Vector2.ZERO


func _ready() -> void:
	Settings.load_settings()
	if Settings.skip_intro or GD.intro_seen:
		get_tree().change_scene_to_file.call_deferred(MENU)
		return
	GD.intro_seen = true
	Settings.apply()
	_neck = NECK_PIVOT * S
	_head_c = Vector2(4.0, -7.0) * S
	_ladder_len = _ladder_foot.distance_to(_ladder_top)
	_ladder_ang = (_ladder_top - _ladder_foot).angle()
	# Stand where the struck pickaxe tip (hand + 13 along the swing) lands on the neck.
	var a1 := -2.3 + 3.2
	_shoulder = _neck - Vector2(3.0 + 13.0 * cos(a1), -12.0 + 13.0 * sin(a1)) * K
	_seat = Vector2(_neck.x - 2.0, _neck.y + 6.0 * K - 2.0)
	_build()
	_load_sounds()


func _build() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var back := ColorRect.new()
	back.color = Color.BLACK
	back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(back)
	_view = SubViewport.new()
	_view.size = Vector2i(Vector2(STAGE) * RES)
	_view.transparent_bg = false
	_view.msaa_2d = Viewport.MSAA_4X
	_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_view)
	_stage = Stage.new()
	_stage.set("intro", self)
	_view.add_child(_stage)
	var screen := TextureRect.new()
	screen.texture = _view.get_texture()
	screen.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	screen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	screen.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(screen)
	# Smoke hanging in the air, lit where the spotlight cuts through it, with dust motes.
	_smoke = ShaderMaterial.new()
	var smoke_shader := Shader.new()
	smoke_shader.code = SMOKE_SHADER
	_smoke.shader = smoke_shader
	screen.material = _smoke
	# The title screen's grit: film grain, faint scanlines and a dark vignette.
	var grit := ColorRect.new()
	grit.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grit.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var grit_mat := ShaderMaterial.new()
	var grit_shader := Shader.new()
	grit_shader.code = GRIT_SHADER
	grit_mat.shader = grit_shader
	grit.material = grit_mat
	layer.add_child(grit)
	_overlay = Overlay.new()
	_overlay.set("intro", self)
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_overlay)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 1)
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_fade)


func _load_sounds() -> void:
	for n in ["intro_light", "intro_step", "intro_jump", "intro_tink1", "intro_tink2",
			"intro_tink3", "intro_crack", "intro_thud", "intro_roll", "intro_sting"]:
		var path := "res://sounds/%s.wav" % n
		if ResourceLoader.exists(path):
			_streams[n] = load(path)
	for i in 6:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)


func _sound(n: String, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	if not _streams.has(n):
		return
	for p in _players:
		var player := p as AudioStreamPlayer
		if not player.playing:
			player.stream = _streams[n]
			player.volume_db = linear_to_db(maxf(Settings.sfx, 0.001)) + volume_db
			player.pitch_scale = pitch
			player.play()
			return


func _input(event: InputEvent) -> void:
	if _leaving or _t < 0.2:
		return
	var pressed: bool = (event is InputEventKey and event.pressed and not event.echo) or (event is InputEventMouseButton and event.pressed) or (event is InputEventJoypadButton and event.pressed)
	if pressed:
		_leave()


func _leave() -> void:
	_leaving = true
	_leave_t = 0.0
	for p in _players:
		(p as AudioStreamPlayer).stop()


func _process(delta: float) -> void:
	if _stage == null:
		return
	if _leaving:
		_leave_t += delta
		_fade.color.a = clampf(_leave_t / 0.3, 0.0, 1.0)
		if _leave_t >= 0.35:
			set_process(false)
			get_tree().change_scene_to_file(MENU)
		return
	_t += delta
	_cues()
	_head_physics(delta)
	_stage.queue_redraw()
	_smoke.set_shader_parameter("light", _light())
	_overlay.queue_redraw()
	# Darkness before the light, a flicker as it comes on, the fade out at the end.
	var dark := 0.0
	if _t < T_LIGHT:
		dark = 1.0
	elif _t < 0.6 and _light() < 1.0:
		dark = 0.25
	if _t > T_OUT0:
		dark = clampf((_t - T_OUT0) / (T_OUT1 - T_OUT0), 0.0, 1.0)
	_fade.color.a = dark
	if _t >= T_OUT1 + 0.1:
		set_process(false)
		get_tree().change_scene_to_file(MENU)


func _light() -> float:
	if _t < T_LIGHT:
		return 0.0
	if _t < 0.6 and int(_t * 30.0) % 3 == 0:
		return 0.4
	return 1.0


## Sound cues on the timeline (each fires once).
func _cue(key: String, at: float, sound: String, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	if _t >= at and not _fired.has(key):
		_fired[key] = true
		_sound(sound, volume_db, pitch)


func _cues() -> void:
	_cue("light", T_LIGHT, "intro_light", -2.0)
	if _t >= T_WALK0 and _t < T_WALK1:
		var n := int(_t * 14.0 / PI)
		if n != _step_n:
			_step_n = n
			_sound("intro_step", -8.0, randf_range(0.9, 1.15))
	for i in JUMPS.size():
		var j: Array = JUMPS[i]
		_cue("jump%d" % i, float(j[0]), "intro_jump", -6.0, 1.0 + i * 0.08)
		_cue("land%d" % i, float(j[1]), "intro_step", -5.0, 0.85)
	_cue("tink1", TINKS[0], "intro_tink1", -4.0)
	_cue("tink2", TINKS[1], "intro_tink2", -4.0)
	_cue("tink3", TINKS[2], "intro_tink3", -3.0)
	_cue("crack", TINKS[2] + 0.02, "intro_crack", -4.0)
	_cue("seat", T_HOP1, "intro_step", -6.0, 0.8)
	_cue("sting", T_LOGO, "intro_sting", -4.0)


## After the third tink the head arcs off, bounces once and rolls away to the right.
func _head_physics(delta: float) -> void:
	if not _head_loose:
		if _t < TINKS[2]:
			return
		_head_loose = true
		_head_pos = _neck + _head_c
		_head_vel = Vector2(95.0, -70.0)
	_sim_left += delta
	var step := 1.0 / 240.0
	var r := 11.0
	while _sim_left >= step:
		_sim_left -= step
		_head_vel.y += 520.0 * step
		_head_pos += _head_vel * step
		if _head_pos.y > FLOOR - r:
			_head_pos.y = FLOOR - r
			if absf(_head_vel.y) > 60.0:
				_head_vel.y = -_head_vel.y * 0.35
			else:
				_head_vel.y = 0.0
			_head_vel.x = maxf(_head_vel.x, 150.0)
			if not _head_landed:
				_head_landed = true
				_sound("intro_thud", -2.0)
				_sound("intro_roll", -4.0)
		_head_rot += _head_vel.x / r * step * (1.0 if _head_landed else 0.35)


static func _ease(x: float) -> float:
	x = clampf(x, 0.0, 1.0)
	return x * x * (3.0 - 2.0 * x)


func ladder_pose() -> Array:
	return []   # no ladder: he jumps up (v0.9.156)


func goblin_state() -> Array:
	## [feet position, pose, axe 0..1, pickaxe on his back?], or [] before he arrives.
	var t := _t
	if t < T_WALK0:
		return []
	if t < T_WALK1:
		var k := (t - T_WALK0) / (T_WALK1 - T_WALK0)
		return [Vector2(lerpf(-40.0, 166.0, k), FLOOR), "walk", 0.0, true]
	for j in JUMPS:
		if t < float(j[0]):
			return [j[2], "stand", 0.0, true]   # a beat between hops
		if t < float(j[1]):
			var kj := (t - float(j[0])) / (float(j[1]) - float(j[0]))
			var p: Vector2 = (j[2] as Vector2).lerp(j[3], kj)
			return [p - Vector2(0, 4.0 * float(j[4]) * kj * (1.0 - kj)), "jump", 0.0, true]
	if t < T_ONHEAD1:
		return [_shoulder, "peek", 0.0, true]
	if t < T_HOP0:
		var axe := 0.0
		for tk in TINKS:
			var tkf := float(tk)
			if t >= tkf - 0.14 and t < tkf:
				axe = _ease((t - (tkf - 0.14)) / 0.14)
			elif t >= tkf and t < tkf + 0.28:
				axe = 1.0 - _ease((t - tkf) / 0.28)
		if t > float(TINKS[2]) + 0.1:
			axe = 0.0
		return [_shoulder, "swing", axe, false]
	if t < T_HOP1:
		var k4 := _ease((t - T_HOP0) / (T_HOP1 - T_HOP0))
		return [_shoulder.lerp(_seat, k4) - Vector2(0, sin(k4 * PI) * 14.0), "stand", 0.0, true]
	return [_seat, "sit", 0.0, true]


## The stage: everything drawn at 480x270, with a small transform stack (the
## statue at 1.5x, the goblin at 2x, the head turning as it rolls).
class Stage extends Node2D:
	var intro: Node = null
	var _stack: Array = [Transform2D.IDENTITY]

	func _push(pos: Vector2, rot: float = 0.0, sc: float = 1.0, sx: float = 1.0) -> void:
		var local := Transform2D(rot, Vector2(sc * sx, sc), 0.0, pos)
		var m: Transform2D = _stack[-1] * local
		_stack.append(m)
		draw_set_transform_matrix(m)

	func _pop() -> void:
		_stack.pop_back()
		draw_set_transform_matrix(_stack[-1])

	func _poly(pts: Array, col: Color) -> void:
		draw_colored_polygon(PackedVector2Array(pts), col)

	func _line(a: Vector2, b: Vector2, col: Color, w: float = 1.0) -> void:
		draw_line(a, b, col, w)

	func _rect(x: float, y: float, w: float, h: float, col: Color) -> void:
		draw_rect(Rect2(x, y, w, h), col)

	## A dark outline round the whole group (each shape drawn 1 step out in four
	## directions), then the fills on top.
	func _silhouette(parts: Array) -> void:
		for o in OFFS:
			_push(o)
			for p in parts:
				_poly(p[1], COL["ol"])
			_pop()
		for p in parts:
			_poly(p[1], COL[String(p[0])])

	func _draw() -> void:
		if intro == null:
			return
		var t: float = intro.get("_t")
		_stack = [Transform2D.IDENTITY]
		draw_set_transform_matrix(Transform2D.IDENTITY)
		_push(Vector2.ZERO, 0.0, RES)
		_rect(0, 0, STAGE.x, STAGE.y, COL["bg"])
		_push(Vector2(0, OY))
		_push(Vector2.ZERO, 0.0, S)
		_background(intro.call("_light"))
		_silhouette([ROCK[0]])
		for i in range(1, ROCK.size()):
			_poly(ROCK[i][1], COL[String(ROCK[i][0])])
		_silhouette(BODY)
		for p in LIGHT:
			_poly(p[1], COL[String(p[0])])
		for s in SEAMS:
			_line(s[0], s[1], COL["st_dd"], 1.0)
		_pop()
		var loose: bool = intro.get("_head_loose")
		var neck: Vector2 = intro.get("_neck")
		if loose:
			_push(neck, 0.0, S)
			_poly(NECK_CUT, COL["st_l"])   # the fresh cut
			_pop()
		else:
			_head(neck + intro.get("_head_c"), 0.0)
		_push(Vector2.ZERO, 0.0, S)
		_silhouette(HAND)   # the hand stays where the chin was
		_pop()
		var lp: Array = intro.call("ladder_pose")
		var gs: Array = intro.call("goblin_state")
		if not lp.is_empty():
			_ladder(lp[0], lp[1])
		if not gs.is_empty():
			var at: Vector2 = gs[0]
			_goblin(at, String(gs[1]), t, float(gs[2]), bool(gs[3]))
		if loose:
			_head(intro.get("_head_pos"), intro.get("_head_rot"))
		_sparks(t, neck)
		_pop()

	func _background(light: float) -> void:
		_rect(0, 160, 320, 60, COL["floor"])
		_line(Vector2(0, 160), Vector2(320, 160), COL["floor_edge"], 1.0)
		_poly([Vector2(146, 0), Vector2(186, 0), Vector2(238, 160), Vector2(94, 160)], Color(LIGHT_COL, 18.0 / 255.0 * light))
		_poly([Vector2(150, 0), Vector2(182, 0), Vector2(216, 160), Vector2(116, 160)], Color(LIGHT_COL, 16.0 / 255.0 * light))
		for ring in [[70.0, 9.0, 22.0], [52.0, 6.0, 26.0], [34.0, 4.0, 30.0]]:
			var pts: Array = []
			for i in 24:
				var a := i * PI / 12.0
				pts.append(Vector2(166.0 + float(ring[0]) * cos(a), 161.0 + float(ring[1]) * sin(a)))
			_poly(pts, Color(LIGHT_COL, float(ring[2]) / 255.0 * light))

	func _head(centre: Vector2, rot: float) -> void:
		var hc: Vector2 = intro.get("_head_c")
		_push(centre, rot, S)
		_push(-hc / S)
		_silhouette([HEAD[0]])
		for i in range(1, HEAD.size()):
			_poly(HEAD[i][1], COL[String(HEAD[i][0])])
		_pop()
		_pop()

	func _ladder(foot: Vector2, ang: float) -> void:
		var length: float = intro.get("_ladder_len")
		var d := Vector2.RIGHT.rotated(ang)
		var n := Vector2(-d.y, d.x)
		for side in [-4.5, 4.5]:
			var a: Vector2 = foot + n * float(side)
			var b: Vector2 = a + d * length
			_line(a, b, GOB["ol"], 3.0)
			_line(a, b, GOB["wood"], 1.0)
		var r := 7.0
		while r < length - 2.0:
			_line(foot + d * r - n * 4.5, foot + d * r + n * 4.5, GOB["wood_d"], 1.0)
			r += 9.0

	func _sparks(t: float, neck: Vector2) -> void:
		for i in TINKS.size():
			var dt := t - float(TINKS[i])
			if dt < 0.0 or dt >= 0.35:
				continue
			for j in 7:
				var a := -0.4 - j * 0.45 + i * 0.3
				var sp := 40.0 + float(j * 37 % 50)
				var p := Vector2(neck.x - 2.0 + cos(a) * sp * dt, neck.y - 2.0 + sin(a) * sp * dt + 120.0 * dt * dt)
				_rect(p.x, p.y, 1, 1, Color(1.0, 0.94, 0.67, 1.0 - dt / 0.35))
			for j in 3:
				var q := Vector2(neck.x + 3.0 + j * 2.0 + 20.0 * dt, neck.y + 30.0 * dt + 300.0 * dt * dt)
				_rect(q.x, q.y, 1.5, 1.5, COL["st_d"])

	## The goblin, feet at `at`. pose: walk, jump, stand, peek, swing, sit.
	func _goblin(at: Vector2, pose: String, t: float, axe: float, back: bool) -> void:
		var step := sin(t * 14.0)
		var bob := 0.0
		var legs: Array = []
		if pose == "carry" or pose == "walk":
			bob = -absf(step)
			legs = [[Vector2(-2, -6), Vector2(-2 + step * 2.5, 0)], [Vector2(2, -6), Vector2(2 - step * 2.5, 0)]]
		elif pose == "climb":
			var k := sin(t * 10.0)
			legs = [[Vector2(-2, -6), Vector2(-3, -1 + k * 2.0)], [Vector2(2, -6), Vector2(1, -1 - k * 2.0)]]
		elif pose == "jump":   # knees tucked up
			legs = [[Vector2(-2, -6), Vector2(0, -3), Vector2(-2, -1)], [Vector2(2, -6), Vector2(5, -4), Vector2(3, -1)]]
		elif pose == "sit":
			var kick := sin(t * 6.0)
			legs = [[Vector2(-2, -6), Vector2(3, -6), Vector2(4 + kick * 1.5, 3)], [Vector2(2, -6), Vector2(7, -6), Vector2(8 - kick * 1.5, 3)]]
		else:
			legs = [[Vector2(-2, -6), Vector2(-2, 0)], [Vector2(2, -6), Vector2(2, 0)]]
		var sh_b := Vector2(-2, -12 + bob)
		var sh_f := Vector2(3, -12 + bob)
		var axe_a := -2.3 + axe * 3.2   # raised behind the head .. struck forward-down
		var hands: Array
		match pose:
			"carry":
				hands = [Vector2(-3, -19 + bob), Vector2(4, -19 + bob)]
			"climb":
				var k2 := sin(t * 10.0)
				hands = [Vector2(1, -17 + k2 * 2.0), Vector2(5, -17 - k2 * 2.0)]
			"swing":
				var hp := Vector2(3.0 + cos(axe_a) * 5.0, -12.0 + bob + sin(axe_a) * 5.0)
				hands = [hp, hp]
			"sit":
				hands = [Vector2(-4, -6), Vector2(5, -6)]
			"jump":
				hands = [Vector2(-5, -9), Vector2(5, -22)]   # fist up, Mario style
			"peek":
				hands = [Vector2(-4, -7), Vector2(7, -15)]   # a little wave
			_:
				hands = [Vector2(-4, -6 + bob * 0.5), Vector2(5, -6 + bob * 0.5)]
		_push(at, 0.0, K)
		# Outline pass (every shape nudged out four ways), then the fills.
		for o in GOB_OFFS:
			_push(o)
			_goblin_shapes(false, bob, legs, hands, sh_b, sh_f, axe_a, back)
			_pop()
		_goblin_shapes(true, bob, legs, hands, sh_b, sh_f, axe_a, back)
		var hb := bob
		_poly([Vector2(-11, -23 + hb), Vector2(-12, -26 + hb), Vector2(-6, -22 + hb), Vector2(-6, -20 + hb)], GOB["sk_d"])   # inner ear
		_poly([Vector2(-5, -25 + hb), Vector2(0, -27 + hb), Vector2(5, -26 + hb), Vector2(3, -25 + hb), Vector2(-3, -24 + hb)], GOB["sk_l"])   # lit scalp
		_line(Vector2(-5, -23 + hb), Vector2(5, -24 + hb), GOB["boot"], 1.0)   # goggle strap
		_poly([Vector2(1, -25 + hb), Vector2(4, -25 + hb), Vector2(4, -23 + hb), Vector2(1, -23 + hb)], GOB["gog"])   # goggle lens
		_poly([Vector2(4, -21 + hb), Vector2(6, -21 + hb), Vector2(6, -20 + hb), Vector2(4, -20 + hb)], GOB["eye"])   # glowing eye
		_line(Vector2(5, -16 + hb), Vector2(8, -17 + hb), GOB["ol"], 1.0)   # grin
		_poly([Vector2(6, -16 + hb), Vector2(7, -16 + hb), Vector2(7, -15 + hb), Vector2(6, -15 + hb)], GOB["tooth"])
		_line(Vector2(-4, -8 + bob), Vector2(5, -8 + bob), GOB["su_d"], 1.0)   # belt
		_pop()

	## A goblin colour, or the outline colour on the outline pass.
	func _gc(fill: bool, k: String) -> Color:
		if fill:
			return GOB[k]
		return GOB["ol"]

	func _goblin_shapes(fill: bool, bob: float, legs: Array, hands: Array, sh_b: Vector2, sh_f: Vector2, axe_a: float, back: bool) -> void:
		var w := 0.0 if fill else 0.5
		if back:   # pickaxe slung on his back
			_line(Vector2(-9, -3 + bob), Vector2(-6, -30 + bob), _gc(fill, "wood"), 1.0 + w)
			_poly([Vector2(-13, -29 + bob), Vector2(-9, -32 + bob), Vector2(-6, -32 + bob), Vector2(-1, -31 + bob), Vector2(3, -28 + bob), Vector2(-2, -29 + bob), Vector2(-6, -30 + bob), Vector2(-9, -30 + bob)], _gc(fill, "iron"))
		for leg in legs:
			var a: Vector2 = leg[0]
			var b: Vector2 = leg[-1]
			if leg.size() == 3:   # bent at the knee (sitting)
				_line(a, leg[1], _gc(fill, "su_d"), 2.0 + w)
				_line(leg[1], b, _gc(fill, "su_d"), 2.0 + w)
			else:
				_line(a, b, _gc(fill, "su_d"), 2.0 + w)
			_poly([b + Vector2(-1, -1), b + Vector2(2, -1), b + Vector2(3, 0.5), b + Vector2(-1, 0.5)], _gc(fill, "boot"))
		_line(sh_b, hands[0], _gc(fill, "sk_d"), 1.0 + w)   # back arm
		_poly([Vector2(-4, -14 + bob), Vector2(3, -14 + bob), Vector2(6, -10 + bob), Vector2(5, -6 + bob), Vector2(-4, -6 + bob), Vector2(-5, -10 + bob)], _gc(fill, "su"))   # body
		_poly([Vector2(-4, -23 + bob), Vector2(-14, -28 + bob), Vector2(-11, -23 + bob), Vector2(-5, -19 + bob)], _gc(fill, "sk"))   # ear, swept back
		_poly([Vector2(-5, -25 + bob), Vector2(0, -27 + bob), Vector2(5, -26 + bob), Vector2(7, -22 + bob), Vector2(11, -20 + bob), Vector2(11, -17 + bob), Vector2(8, -18 + bob), Vector2(6, -15 + bob), Vector2(1, -14 + bob), Vector2(-4, -15 + bob), Vector2(-6, -19 + bob)], _gc(fill, "sk"))   # head
		if not back:   # the pickaxe in his hands
			var h: Vector2 = hands[-1]
			var d := Vector2(cos(axe_a), sin(axe_a))
			var n := Vector2(-d.y, d.x)
			var tip := h + d * 11.0
			_line(h - d * 2.0, tip, _gc(fill, "wood"), 1.0 + w)
			_poly([tip + n * 5.0, tip + d * 1.5, tip - n * 5.0, tip - n * 3.0 - d, tip - d * 1.2, tip + n * 3.0 - d], _gc(fill, "iron"))
		_line(sh_f, hands[-1], _gc(fill, "sk"), 1.0 + w)   # front arm
		for hp in hands:
			var p: Vector2 = hp
			_poly([p + Vector2(-1, -1), p + Vector2(1, -1), p + Vector2(1, 1), p + Vector2(-1, 1)], _gc(fill, "sk"))


## The logo, drawn at full resolution over the pixel stage.
class Overlay extends Control:
	var intro: Node = null
	var _last_t := 0.0
	var _flicker := -1          # the letter on the blink, or -1
	var _flicker_left := 0.0
	var _next_flicker := 1.2

	## MARKOLABS, alive like SURVIVORS on the title screen (menu.gd LogoWord): a wave
	## through the letters, a sheen sweeping across, a soft glow, and now and then one
	## letter flickering like a damaged sign.
	func _draw() -> void:
		if intro == null:
			return
		var t: float = intro.get("_t")
		var dt := maxf(0.0, t - _last_t)
		_last_t = t
		if t < T_LOGO:
			return
		_next_flicker -= dt
		if _next_flicker <= 0.0:
			_flicker = randi() % 9
			_flicker_left = randf_range(0.15, 0.4)
			_next_flicker = randf_range(1.5, 3.0)
		if _flicker_left > 0.0:
			_flicker_left -= dt
			if _flicker_left <= 0.0:
				_flicker = -1
		var font := ThemeDB.fallback_font
		var k := minf(size.x / float(STAGE.x), size.y / float(STAGE.y))
		var origin := (size - Vector2(STAGE) * k) / 2.0
		var a := clampf((t - T_LOGO) / 0.6, 0.0, 1.0)
		var title := "MARKOLABS"
		var gold := Color(0.91, 0.77, 0.28)
		var fs := int(17.0 * k)
		var gap := fs * 0.55   # letter spacing
		var tw := 0.0
		for ch in title:
			tw += font.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + gap
		tw -= gap
		var y := origin.y + 232.0 * k + fs
		var x := size.x / 2.0 - tw / 2.0
		var lt := t - T_LOGO
		var sweep := fmod(lt, 4.5) / 1.3 * float(title.length() + 4) - 2.0
		for i: int in title.length():
			var ch := title[i]
			var w := font.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			var yy := y + sin(lt * 2.2 + i * 0.55) * 2.5 * k / 4.0
			var near := clampf(1.0 - absf(float(i) - sweep) / 1.6, 0.0, 1.0)
			var c := gold.lerp(Color(1.0, 0.97, 0.85), near * 0.8)
			var glow_alpha := 0.14 + 0.3 * near
			if i == _flicker:
				var on := fmod(t * 23.0, 1.0) < 0.5
				c = Color(gold, 0.25 if on else 0.8)
				glow_alpha = 0.0
			c.a *= a
			draw_string_outline(font, Vector2(x, yy), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, int(12.0 * k / 4.0), Color(gold, glow_alpha * a))
			draw_string(font, Vector2(x, yy), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, c)
			x += w + gap
		var a2 := clampf((t - T_LOGO - 0.4) / 0.6, 0.0, 1.0)
		var fs2 := int(8.0 * k)
		var sub := "presents"
		var sw := font.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, fs2).x
		draw_string(font, Vector2(size.x / 2.0 - sw / 2.0, y + 21.0 * k - fs + fs2), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, fs2, Color(0.96, 0.94, 0.89, 0.86 * a2))
