extends Node2D
## Title screen: a live battle behind the menu. Earth on the left, the Kharkiv firing a
## MAG slug at a Rebel ship, Rebel lasers and UNE Gatling tracers trading fire.
## Menu (bottom left): Start Run, Unlocks, Tutorial (starts a normal run for now), Settings, Quit.

const GD = preload("res://scripts/game_data.gd")
const Sfx = preload("res://scripts/sfx.gd")
const Settings = preload("res://scripts/settings.gd")
const MusicPlayer = preload("res://scripts/music.gd")

const GOLD := Color("e8c547")
const CREAM := Color("f4efe2")
const MUTED := Color("a9b4c0")
const HOLO_GREEN := Color("3dd17a")   # the fleet-status display's colours
const HOLO_RED := Color("e5484d")
const ShipInfo = preload("res://scripts/ship_info.gd")
const PatchNotes = preload("res://scripts/patch_notes.gd")
const FeedbackPanel = preload("res://scripts/feedback.gd")

var _time := 0.0
var _stars: Array = []      # [pos, size, alpha]
var _nebula: Array = []     # [pos, radius, colour]
var _grime: Array = []      # [pos, size, alpha] on the Kharkiv
var _debris: Array = []     # [pos, size, angle, spin, drift]
var _cities: Array = []     # [pos, brightness]
var _ui: CanvasLayer
var _settings_panel: PanelContainer
var _notes_layer: Control = null   # the patch notes page
var _note: Label
var _note_left := 0.0
var _font: Font
var _fullscreen_box: CheckBox = null
var _book: Control = null             # Noob Mode: the "Space 4 Dummies" book behind the menu
var _noob_switch: Control = null      # the Noob Mode switch under the book
var _guide_hud: CanvasLayer = null    # a guide-only HUD showing the tutorial pages
var _menu_panel: PanelContainer = null
var _settings_noob: CheckBox = null   # ...and in Settings, kept in step
var _sub_advisor: CheckBox = null
var _sub_tutorial: CheckBox = null
var _noob_subs: Control = null


func _ready() -> void:
	Settings.load_settings()
	Settings.apply()
	Sfx.reset_death_audio()   # in case the last run ended in the flagship's slow bleed-out
	_font = ThemeDB.fallback_font
	add_child(Sfx.new())
	add_child(FeedbackPanel.new())   # Enter anywhere: send feedback
	MusicPlayer.shared(get_tree())
	Settings.apply()
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 260:
		var size := 3.0 if rng.randf() < 0.08 else (2.0 if rng.randf() < 0.4 else 1.0)
		_stars.append([Vector2(rng.randf() * 2400.0, rng.randf() * 1080.0), size, rng.randf_range(0.25, 0.95), rng.randf() * TAU])
	# Nebula: soft overlapping clouds in three colours.
	for cl in [[Vector2(1500, 250), Color(0.45, 0.22, 0.62)], [Vector2(1180, 880), Color(0.16, 0.45, 0.55)], [Vector2(1820, 620), Color(0.62, 0.28, 0.16)]]:
		for i in 26:
			var at: Vector2 = cl[0] + Vector2(rng.randf_range(-320, 320), rng.randf_range(-170, 170))
			_nebula.append([at, rng.randf_range(80.0, 240.0), cl[1]])
	# Wear and tear on the Kharkiv's plating: grime patches and scratches.
	for i in 70:
		_grime.append([Vector2(rng.randf_range(-30, 470), rng.randf_range(-10, 220)), Vector2(rng.randf_range(6, 40), rng.randf_range(2, 10)), rng.randf_range(0.08, 0.25)])
	# Drifting wreckage.
	for i in 18:
		_debris.append([Vector2(rng.randf_range(900, 1900), rng.randf_range(80, 900)), rng.randf_range(3.0, 9.0), rng.randf() * TAU, rng.randf_range(-1.2, 1.2), Vector2(rng.randf_range(-8, 8), rng.randf_range(-5, 5))])
	# City lights on Earth's night side.
	for i in 90:
		var a := rng.randf() * TAU
		var d := sqrt(rng.randf()) * 400.0
		_cities.append([Vector2(70, 330) + Vector2(cos(a), sin(a)) * d, rng.randf_range(0.4, 1.0)])
	_build_grit()
	_build_ui()


func _process(delta: float) -> void:
	_time += delta
	if _note_left > 0.0:
		_note_left -= delta
		_note.modulate.a = clampf(_note_left, 0.0, 1.0)
	queue_redraw()
	# The book tucks in behind the menu's bottom-right corner.
	if _book != null and _menu_panel != null:
		var r := _menu_panel.get_global_rect()
		_book.position = Vector2(r.end.x - 96.0, r.end.y - 344.0)
		if _noob_switch != null:
			_noob_switch.position = Vector2(r.end.x + 14.0, r.end.y + 10.0)


# --- the scene ---------------------------------------------------------------------

const SUN := Vector2(1880, 60)


func _draw() -> void:
	var view := get_viewport_rect().size
	var s := view.y / 1080.0
	draw_rect(Rect2(Vector2.ZERO, view), Color("05080f"))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(s, s))
	# Nebula clouds, then the stars through them.
	for n in _nebula:
		var tint: Color = n[2]
		draw_circle(n[0], float(n[1]), Color(tint, 0.022))
	for st in _stars:
		var twinkle := 0.75 + 0.25 * sin(_time * 1.5 + float(st[3]))
		draw_rect(Rect2(st[0], Vector2(st[1], st[1])), Color(0.86, 0.91, 1.0, float(st[2]) * twinkle))
		if float(st[1]) >= 3.0:
			var p: Vector2 = st[0] + Vector2(1.5, 1.5)
			draw_line(p - Vector2(7, 0), p + Vector2(7, 0), Color(0.86, 0.91, 1.0, 0.25 * twinkle), 1.0)
			draw_line(p - Vector2(0, 7), p + Vector2(0, 7), Color(0.86, 0.91, 1.0, 0.25 * twinkle), 1.0)
	_draw_sun()
	_draw_asteroids()
	_draw_debris()
	_draw_earth()
	_draw_starbase()
	_draw_rebels()
	_draw_corvettes()
	_draw_cruiser()
	_draw_kharkiv()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## A hard white sun just off the top-right corner, with a long lens flare.
func _draw_sun() -> void:
	for i in 10:
		draw_circle(SUN, 420.0 - i * 38.0, Color(1.0, 0.85, 0.6, 0.012 + i * 0.004))
	draw_circle(SUN, 46.0, Color(1.0, 0.95, 0.85, 0.9))
	draw_circle(SUN, 30.0, Color.WHITE)
	draw_line(SUN - Vector2(900, 0), SUN + Vector2(300, 0), Color(1.0, 0.9, 0.75, 0.07), 6.0)
	draw_line(SUN - Vector2(500, 0), SUN + Vector2(200, 0), Color(1.0, 0.95, 0.85, 0.12), 2.0)
	for k in 3:
		var at := SUN.lerp(Vector2(960, 540), 0.35 + k * 0.22)
		draw_circle(at, 16.0 + k * 10.0, Color(0.7, 0.85, 1.0, 0.04))


func _draw_asteroids() -> void:
	var rocks := [[Vector2(1250, 125), 22.0], [Vector2(1370, 985), 30.0], [Vector2(778, 964), 18.0], [Vector2(1858, 184), 16.0], [Vector2(572, 93), 13.0], [Vector2(1462, 863), 13.0], [Vector2(1180, 330), 9.0]]
	var lit := (SUN - Vector2(960, 540)).normalized()
	for i in rocks.size():
		var c: Vector2 = rocks[i][0]
		var r: float = rocks[i][1]
		var pts := PackedVector2Array()
		for k in 9:
			pts.append(c + Vector2.RIGHT.rotated(TAU * k / 9.0 + _time * 0.04 * (1 + i % 2)) * r * (0.72 + 0.28 * ((k * 7 + i * 3) % 4) / 3.0))
		draw_colored_polygon(pts, Color(0.23, 0.22, 0.2))
		draw_circle(c + lit * r * 0.3, r * 0.55, Color(0.45, 0.42, 0.37, 0.6))
		draw_circle(c - lit * r * 0.35, r * 0.18, Color(0.12, 0.11, 0.1, 0.7))   # a crater
		var outline := pts.duplicate()
		outline.append(pts[0])
		draw_polyline(outline, Color(0.05, 0.05, 0.06), 2.0)


func _draw_debris() -> void:
	for d in _debris:
		var at: Vector2 = d[0] + Vector2(d[4]) * _time
		at = Vector2(fposmod(at.x - 800.0, 1200.0) + 800.0, fposmod(at.y, 1000.0) + 40.0)
		var size: float = d[1]
		var ang: float = float(d[2]) + float(d[3]) * _time
		var pts := PackedVector2Array([at + Vector2(size, 0).rotated(ang), at + Vector2(-size * 0.6, size * 0.5).rotated(ang), at + Vector2(-size * 0.3, -size * 0.7).rotated(ang)])
		draw_colored_polygon(pts, Color(0.32, 0.34, 0.38, 0.85))
		if int(size) % 3 == 0:
			draw_circle(at, 1.5, Color(1.0, 0.6, 0.25, 0.5 + 0.5 * sin(_time * 6.0 + size)))   # still smouldering


func _draw_earth() -> void:
	var c := Vector2(70, 330)
	var r := 410.0
	var to_sun := (SUN - c).normalized()
	for i in 10:
		draw_circle(c, r + 36.0 - i * 3.5, Color(0.5, 0.78, 1.0, 0.028))
	draw_circle(c, r, Color("1f5a99"))
	draw_circle(c + to_sun * 60.0, r * 0.82, Color("2f6fb4"))
	draw_circle(c + to_sun * 130.0, r * 0.5, Color("4189cf", 0.6))
	# Continents with ragged coasts, polar ice, a desert.
	for land in [[[Vector2(120, 60), Vector2(180, 52), Vector2(230, 80), Vector2(262, 120), Vector2(250, 160), Vector2(282, 205), Vector2(295, 260), Vector2(272, 320), Vector2(250, 380), Vector2(220, 420), Vector2(200, 450), Vector2(150, 470), Vector2(110, 480), Vector2(96, 430), Vector2(80, 380), Vector2(50, 320), Vector2(30, 250), Vector2(28, 190), Vector2(40, 140), Vector2(80, 92)], Color("3f7a32")],
			[[Vector2(300, 420), Vector2(340, 432), Vector2(375, 460), Vector2(372, 500), Vector2(360, 540), Vector2(330, 580), Vector2(290, 615), Vector2(262, 600), Vector2(245, 580), Vector2(252, 520), Vector2(260, 480)], Color("4c8a3a")]]:
		var coast: Array = land[0]
		var green: Color = land[1]
		draw_colored_polygon(PackedVector2Array(coast), green)
	draw_colored_polygon(PackedVector2Array([Vector2(160, 160), Vector2(210, 170), Vector2(220, 205), Vector2(185, 220), Vector2(150, 200)]), Color("b89f68"))
	draw_colored_polygon(PackedVector2Array([Vector2(-60, -60), Vector2(120, -78), Vector2(220, -60), Vector2(120, -30), Vector2(0, -36)]), Color(0.92, 0.95, 1.0, 0.85))
	# Clouds drift slowly; long streaks with a softer halo.
	var drift := sin(_time * 0.05) * 30.0
	var sc := get_viewport_rect().size.y / 1080.0
	for cl in [[Vector2(160, 120), 120.0], [Vector2(300, 250), 90.0], [Vector2(130, 380), 140.0], [Vector2(320, 520), 100.0], [Vector2(80, 620), 120.0], [Vector2(230, 690), 80.0], [Vector2(360, 90), 60.0]]:
		var at: Vector2 = cl[0] + Vector2(drift, 0)
		draw_set_transform(at * sc, -0.12, Vector2(float(cl[1]), 13.0) * sc)
		draw_circle(Vector2.ZERO, 1.0, Color(1, 1, 1, 0.45))
		draw_set_transform(at * sc, -0.12, Vector2(float(cl[1]) * 1.2, 22.0) * sc)
		draw_circle(Vector2.ZERO, 1.0, Color(1, 1, 1, 0.12))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(sc, sc))
	# Night side: a crescent of shadow away from the sun, with city lights.
	var perp := to_sun.orthogonal()
	var night := PackedVector2Array()
	for i in 33:
		var t := PI * float(i) / 32.0
		night.append(c + (perp * cos(t) - to_sun * sin(t)) * r)
	for i in 33:
		var t := PI * float(32 - i) / 32.0
		night.append(c + (perp * cos(t) - to_sun * sin(t) * 0.25) * r)
	draw_colored_polygon(night, Color(0.01, 0.02, 0.05, 0.62))
	for city in _cities:
		var p: Vector2 = city[0]
		if (p - c).dot(to_sun) < -0.3 * r and p.distance_to(c) < r - 6.0:
			draw_rect(Rect2(p, Vector2(2, 2)), Color(1.0, 0.8, 0.45, float(city[1]) * (0.7 + 0.3 * sin(_time * 3.0 + p.x))))
	# Atmosphere: a bright rim on the sunlit edge.
	draw_arc(c, r, 0.0, TAU, 128, Color(0.56, 0.82, 1.0, 0.35), 5.0)
	draw_arc(c, r + 2.0, to_sun.angle() - 0.9, to_sun.angle() + 0.9, 48, Color(0.8, 0.93, 1.0, 0.7), 4.0)


## A UNE Starbase hanging in the middle distance: the armoured ring, solar wings and
## blinking lights from the game.
## The Starbase, as a green wireframe on the tactical display: ring, spokes, core, wings.
func _draw_starbase() -> void:
	var c := Vector2(1290, 175 + sin(_time * 0.6) * 3.0)
	var g := HOLO_GREEN
	for side in [-1.0, 1.0]:
		draw_line(c + Vector2(side * 30, 0), c + Vector2(side * 44, 0), Color(g, 0.6), 2.0)
		var panel := Rect2(c + Vector2(side * 44 - (0.0 if side > 0.0 else 24.0), -13), Vector2(24, 26))
		draw_rect(panel, Color(g, 0.15))
		for k in 3:
			draw_line(Vector2(panel.position.x + 6 + k * 6, panel.position.y), Vector2(panel.position.x + 6 + k * 6, panel.end.y), Color(g, 0.35), 1.0)
		draw_rect(panel, Color(g, 0.9), false, 2.0)
	draw_circle(c, 28.0, Color(g, 0.12))
	_holo_ring(c, 28.0, g)
	for i in 4:
		var d := Vector2.RIGHT.rotated(PI * 0.25 + i * PI * 0.5)
		draw_line(c + d * 10.0, c + d * 25.0, Color(g, 0.6), 1.5)
	var core := PackedVector2Array()
	for i in 8:
		core.append(c + Vector2.RIGHT.rotated(PI / 8.0 + i * TAU / 8.0) * 11.0)
	draw_colored_polygon(core, Color(g, 0.25))
	core.append(core[0])
	draw_polyline(core, g, 2.0)
	draw_circle(c, 4.0 * (0.8 + 0.2 * sin(_time * 2.0)), g)
	var blink := 1.0 if fmod(_time, 1.6) < 0.25 else 0.25
	draw_circle(c + Vector2(-70, 0), 2.5, Color(1.0, 0.3, 0.25, blink))
	draw_circle(c + Vector2(70, 0), 2.5, Color(0.3, 1.0, 0.45, blink))


## A glowing wireframe ring with a few lit windows travelling round it.
func _holo_ring(c: Vector2, r: float, colour: Color) -> void:
	var flicker := 0.85 + 0.15 * sin(_time * 9.0 + c.x * 0.01)
	draw_arc(c, r, 0.0, TAU, 48, Color(colour, 0.25), 7.0)
	draw_arc(c, r, 0.0, TAU, 48, Color(colour, flicker), 2.5)
	for i in 12:
		if i % 3 == 0:
			continue
		draw_circle(c + Vector2.RIGHT.rotated(_time * 0.3 + i * TAU / 12.0) * r, 2.0, Color(colour, 0.9))


## A ship drawn like the fleet-status display: a glowing wireframe silhouette over a
## faint fill, with a spine and a cross-brace, so the battle reads like a tactical
## simulation the Commander is watching. nose: the bow; length: bow to stern in pixels.
func _holo(type_id: String, nose: Vector2, length: float, facing: float, colour: Color) -> void:
	var dir := Vector2.RIGHT.rotated(facing)
	var centre := nose - dir * length * 0.5
	var sc := length * 0.5 / 0.95
	var turn := facing + PI * 0.5   # the shapes point their nose up
	var flicker := 0.85 + 0.15 * sin(_time * 9.0 + nose.x * 0.01)
	var pts := PackedVector2Array()
	for p in ShipInfo.SHAPES.get(type_id, ShipInfo.SHAPES["corvette"]):
		pts.append(centre + (Vector2(float(p[0]), float(p[1])) * sc).rotated(turn))
	draw_colored_polygon(pts, Color(colour, 0.2 * colour.a))
	var outline := pts.duplicate()
	outline.append(pts[0])
	draw_polyline(outline, Color(colour, 0.25 * colour.a), 7.0)   # soft glow
	draw_polyline(outline, Color(colour, flicker * colour.a), 2.5)
	var spine_a := centre + (Vector2(0, -0.8) * sc).rotated(turn)
	var spine_b := centre + (Vector2(0, 0.8) * sc).rotated(turn)
	draw_line(spine_a, spine_b, Color(colour, 0.6 * colour.a), 1.5)
	var brace_a := centre + (Vector2(-0.3, 0.2) * sc).rotated(turn)
	var brace_b := centre + (Vector2(0.3, 0.2) * sc).rotated(turn)
	draw_line(brace_a, brace_b, Color(colour, 0.5 * colour.a), 1.5)


func _draw_rebels() -> void:
	var bob := sin(_time * 1.05) * 6.0
	var lead := Vector2(1690, 300 + bob)
	_holo("corvette", lead, 100.0, PI, HOLO_RED)
	draw_circle(lead + Vector2(106, 0), 7.0, Color(1.0, 0.54, 0.24, 0.9))
	# The lead ship is burning: smoke trailing back, sparks off the hull.
	for i in 7:
		var u := fmod(_time * 0.5 + i / 7.0, 1.0)
		draw_circle(lead + Vector2(60 + u * 140, -14 - u * 30), 6.0 + u * 18.0, Color(0.25, 0.24, 0.24, 0.35 * (1.0 - u)))
	draw_circle(lead + Vector2(52, -10), 5.0 + 2.0 * sin(_time * 11.0), Color(1.0, 0.55, 0.2, 0.9))
	_holo("corvette", Vector2(1630, 560), 90.0, PI, HOLO_RED)
	_holo("corvette", Vector2(1740, 650), 90.0, PI, HOLO_RED)
	_holo("corvette", Vector2(1830, 450), 54.0, PI, Color(HOLO_RED, 0.8))
	# One Rebel keeps getting blown apart and replaced.
	var cycle := fmod(_time, 6.0)
	var doomed := Vector2(1590, 760)
	if cycle < 4.6:
		_holo("corvette", doomed, 75.0, PI, HOLO_RED)
	else:
		var t := (cycle - 4.6) / 1.4
		for k in 4:
			draw_circle(doomed + Vector2(20, 0), (14.0 + 60.0 * t) * (1.0 - k * 0.2), Color(1.0, 0.55 + k * 0.1, 0.2 + k * 0.15, (0.8 - k * 0.15) * (1.0 - t)))
		for k in 6:
			var dir := Vector2.RIGHT.rotated(k * 1.05)
			draw_rect(Rect2(doomed + Vector2(20, 0) + dir * 90.0 * t, Vector2(5, 3)), Color(0.4, 0.4, 0.42, 1.0 - t))
	# Lasers at the corvettes, flickering.
	var flick := 0.55 + 0.45 * absf(sin(_time * 7.0))
	for l in [[Vector2(1628, 560), Vector2(996, 640)], [Vector2(1738, 650), Vector2(1046, 710)]]:
		draw_line(l[0], l[1], Color(0.9, 0.28, 0.3, 0.22 * flick), 14.0)
		draw_line(l[0], l[1], Color(0.95, 0.35, 0.35, flick), 4.0)
	# Flak bursting around them.
	for i in 4:
		var u := fmod(_time * 0.8 + i * 0.25, 1.0)
		var at := [Vector2(1660, 500), Vector2(1760, 600), Vector2(1600, 680), Vector2(1700, 410)][i] as Vector2
		draw_circle(at, 6.0 + u * 22.0, Color(1.0, 0.7, 0.3, 0.55 * (1.0 - u)))
		draw_circle(at, 3.0 + u * 8.0, Color(1.0, 0.95, 0.75, 0.7 * (1.0 - u)))


func _draw_corvettes() -> void:
	for c in [Vector2(1000, 640), Vector2(1050, 710), Vector2(990, 784)]:
		var flame := 22.0 + 8.0 * sin(_time * 23.0 + c.y)
		draw_colored_polygon(PackedVector2Array([c - Vector2(94, 7), c - Vector2(94 + flame, 0), c - Vector2(94, -7)]), Color(0.56, 0.82, 1.0, 0.55))
		_holo("corvette", c, 94.0, 0.0, HOLO_GREEN)
		draw_circle(c - Vector2(98, 0), 5.0, Color(0.85, 0.95, 1.0, 0.9))
	# Gatling tracers flying right.
	for i in 6:
		var base := [Vector2(1066, 632), Vector2(1106, 644), Vector2(1116, 702), Vector2(1156, 716), Vector2(1056, 778), Vector2(1096, 790)][i] as Vector2
		var x := base.x + fmod(_time * 145.0 + i * 37.0, 160.0)
		var a := 1.0 - fmod(_time * 145.0 + i * 37.0, 160.0) / 160.0
		draw_colored_polygon(PackedVector2Array([Vector2(x + 14, base.y), Vector2(x, base.y - 8), Vector2(x, base.y + 8)]), Color(0.94, 0.75, 0.38, a))


## A UNE Cruiser below the Kharkiv, ripple-firing a Swarm Missile salvo.
func _draw_cruiser() -> void:
	var c := Vector2(860, 520 + sin(_time * 0.9) * 4.0)
	var flame := 18.0 + 6.0 * sin(_time * 19.0)
	draw_colored_polygon(PackedVector2Array([c - Vector2(120, 10), c - Vector2(120 + flame, 0), c - Vector2(120, -10)]), Color(0.56, 0.82, 1.0, 0.5))
	_holo("cruiser", c, 120.0, 0.0, HOLO_GREEN)
	var cycle := fmod(_time, 4.0) / 4.0
	if cycle < 0.75:
		var u := cycle / 0.75
		var targets := [Vector2(1630, 560), Vector2(1740, 650), Vector2(1690, 300)]
		for i in 6:
			var tgt: Vector2 = targets[i % 3]
			var side := -1.0 if i % 2 == 0 else 1.0
			var lift := Vector2(0, side * (90.0 + i * 12.0))
			var a := c.lerp(tgt, u) + lift * sin(u * PI)
			var b := c.lerp(tgt, maxf(0.0, u - 0.05)) + lift * sin(maxf(0.0, u - 0.05) * PI)
			draw_line(b, a, Color(0.8, 0.8, 0.82, 0.35), 3.0)
			draw_circle(a, 3.0, Color(0.62, 0.88, 1.0))
			if u > 0.95:
				draw_circle(tgt, 18.0, Color(1.0, 0.65, 0.3, 0.6))


## The Kharkiv, as a green wireframe on the tactical display (its real silhouette and
## habitat ring), firing its MAG at the lead Rebel.
func _draw_kharkiv() -> void:
	var o := Vector2(640, 150 + sin(_time * 1.05) * 6.0)
	# Engine plumes behind it (the triangles stay).
	for y in [20.0, 112.0, 204.0]:   # the model's three engines
		var flame := 60.0 + 14.0 * sin(_time * 21.0 + y)
		draw_colored_polygon(PackedVector2Array([o + Vector2(-34, y - 12), o + Vector2(-34 - flame, y), o + Vector2(-34, y + 12)]), Color(0.56, 0.82, 1.0, 0.35))
		draw_colored_polygon(PackedVector2Array([o + Vector2(-34, y - 6), o + Vector2(-34 - flame * 0.6, y), o + Vector2(-34, y + 6)]), Color(0.9, 0.97, 1.0, 0.6))
	# Bow at the MAG muzzle, stern at the engines.
	var nose := o + Vector2(480, 112)
	var length := 514.0
	var centre := nose - Vector2(length * 0.5, 0)
	var ring := length * 0.5 / 0.95 * 0.61
	draw_circle(centre, ring, Color(HOLO_GREEN, 0.06))
	_holo_ring(centre, ring, HOLO_GREEN)
	_holo("capital", nose, length, 0.0, HOLO_GREEN)
	# Command core in the middle, pulsing like the real one.
	var core := PackedVector2Array()
	for i in 8:
		core.append(centre + Vector2.RIGHT.rotated(PI / 8.0 + i * TAU / 8.0) * 44.0)
	draw_colored_polygon(core, Color(HOLO_GREEN, 0.18))
	core.append(core[0])
	draw_polyline(core, HOLO_GREEN, 2.0)
	draw_circle(centre, 14.0 * (0.8 + 0.2 * sin(_time * 2.0)), Color(HOLO_GREEN, 0.9))
	# Running lights.
	var blink := 1.0 if fmod(_time, 1.4) < 0.2 else 0.2
	draw_circle(centre + Vector2(-245, -136), 3.0, Color(1.0, 0.3, 0.25, blink))
	draw_circle(centre + Vector2(-245, 136), 3.0, Color(0.3, 1.0, 0.45, blink))
	# The MAG: charge up (power running up the hull, a swelling glow, a sparkle),
	# fire a slug at the lead Rebel ship, impact. Every 3.5 s.
	var muzzle := o + Vector2(480, 112)
	var hit := Vector2(1694, 298 + sin(_time * 1.05) * 6.0)
	var cycle := fmod(_time, 3.5)
	var charge := clampf(cycle / 2.2, 0.0, 1.0)
	var light := Color(0.72, 0.89, 1.0)
	if cycle < 2.2:
		for k in 3:
			var u := fmod(_time * (1.0 + 3.0 * charge) + k * 0.33, 1.0)
			var a := o + Vector2(20, 100 + k * 10)
			draw_line(a.lerp(muzzle, u), a.lerp(muzzle, minf(1.0, u + 0.08)), Color(light, 0.3 + 0.5 * charge), 2.0)
		draw_circle(muzzle, 10.0 + 40.0 * charge * charge, Color(light, 0.08 + 0.2 * charge))
		draw_circle(muzzle, 5.0 + 12.0 * charge, Color(0.9, 0.96, 1.0, 0.6 + 0.4 * charge))
		if charge > 0.8:
			var l := 30.0 * (charge - 0.8) / 0.2 + 10.0
			draw_line(muzzle - Vector2(l, 0), muzzle + Vector2(l, 0), Color.WHITE, 2.0)
			draw_line(muzzle - Vector2(0, l), muzzle + Vector2(0, l), Color.WHITE, 2.0)
	elif cycle < 2.6:
		var u := (cycle - 2.2) / 0.4
		var head := muzzle.lerp(hit, u)
		draw_line(muzzle.lerp(hit, maxf(0.0, u - 0.25)), head, Color(light, 0.35), 16.0)
		draw_line(muzzle.lerp(hit, maxf(0.0, u - 0.25)), head, Color(0.9, 0.96, 1.0), 5.0)
		draw_circle(head, 8.0, Color.WHITE)
		draw_circle(muzzle, 26.0 * (1.0 - u), Color(1, 1, 1, 0.6 * (1.0 - u)))   # muzzle flash
	else:
		var t := (cycle - 2.6) / 0.9
		for i in 4:
			draw_circle(hit, (20.0 + 70.0 * t) * (1.0 - i * 0.2), Color(1.0, 0.85 - i * 0.1, 0.6 - i * 0.12, (0.75 - i * 0.12) * (1.0 - t)))
		draw_circle(hit, 12.0 * (1.0 - t), Color.WHITE)


# --- the menu ----------------------------------------------------------------------

## Film grain, a faint scanline and a heavy vignette over the scene (under the menu).
func _build_grit() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 1
	add_child(layer)
	var rect := ColorRect.new()
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(rect)
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shader := Shader.new()
	shader.code = """shader_type canvas_item;
float rand(vec2 co) { return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453); }
void fragment() {
	vec2 uv = UV;
	float d = distance(uv * vec2(1.0, 0.8), vec2(0.5, 0.4));
	float vig = smoothstep(0.3, 0.85, d);
	float grain = rand(floor(uv * vec2(960.0, 540.0)) + floor(TIME * 10.0) * 0.137) - 0.5;   // a new pattern 10 times a second
	float scan = 0.5 + 0.5 * sin(uv.y * 1080.0 * 1.57);
	vec3 col = vec3(0.5 + grain * 0.5) * (1.0 - vig);
	float alpha = max(vig * 0.72, 0.045) + scan * 0.02;
	COLOR = vec4(col, alpha);
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	rect.material = material


func _build_ui() -> void:
	_ui = CanvasLayer.new()
	_ui.layer = 2
	add_child(_ui)
	# The Noob Mode book goes in first so the menu panel draws over it.
	_book = NoobBook.new()
	_book.set("on", Settings.xander_on())
	_ui.add_child(_book)
	_book.connect("opened", _open_tutorial)
	var panel := PanelContainer.new()
	_menu_panel = panel
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.047, 0.078, 0.88)
	style.border_color = Color("2a3442")
	style.set_border_width_all(2)
	style.border_width_top = 4
	style.border_color = Color("2a3442")
	style.set_corner_radius_all(10)
	style.content_margin_left = 32
	style.content_margin_right = 32
	style.content_margin_top = 36
	style.content_margin_bottom = 32
	style.shadow_color = Color(0, 0, 0, 0.55)
	style.shadow_size = 30
	panel.add_theme_stylebox_override("panel", style)
	_ui.add_child(panel)
	# The Noob Mode switch sits under the book (added after the menu so it draws on top).
	_noob_switch = NoobSwitch.new()
	_noob_switch.set("on", Settings.xander_on())
	_ui.add_child(_noob_switch)
	_noob_switch.connect("toggled", func(on: bool) -> void: _set_noob(on))
	# Pinned to the bottom-left corner and growing upward, so Quit is never cut off.
	panel.anchor_left = 0.0
	panel.anchor_right = 0.0
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	panel.offset_left = 110   # was 200 (v0.9.122): a bit further left
	panel.offset_right = 110
	panel.offset_top = -60
	panel.offset_bottom = -60
	panel.custom_minimum_size = Vector2(520, 0)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	panel.add_child(column)
	var logo := VBoxContainer.new()
	logo.add_theme_constant_override("separation", 0)
	column.add_child(logo)
	# The logo, alive: STELLAR breathes, SURVIVORS waves, shimmers and flickers.
	var stellar := LogoWord.new()
	stellar.setup("STELLAR", 56, CREAM, false)
	logo.add_child(stellar)
	var survivors := LogoWord.new()
	survivors.setup("SURVIVORS", 56, GOLD, true)
	logo.add_child(survivors)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 18)
	column.add_child(spacer)
	_button(column, "Start Run", 30, _start_run)
	var unlocks := _button(column, "Faction Unlocks", 30, Callable())
	unlocks.disabled = true   # no COMING SOON tag (v0.9.224)
	# For now a normal run is the tutorial (an Endless mode comes later).
	var tutorial := _button(column, "Tutorial", 30, _start_run)
	tutorial.tooltip_text = "Starts a run: right now a normal run is the tutorial"
	_button(column, "Settings", 30, _open_settings)
	var rule := ColorRect.new()
	rule.color = Color("2a3442")
	rule.custom_minimum_size = Vector2(0, 1)
	column.add_child(rule)
	# Bottom row: Quit on the left, PATCH NOTES tucked in the bottom-right corner.
	var bottom := HBoxContainer.new()
	column.add_child(bottom)
	var quit := _button(bottom, "Quit", 22, func() -> void: get_tree().quit())
	quit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_build_patch_notes_button(bottom)
	_note = _label(column, "", 16, MUTED)
	_note.modulate.a = 0.0
	# Gold line along the top of the panel.
	# Gold line across the top of the menu.
	var accent := ColorRect.new()
	accent.color = GOLD
	accent.custom_minimum_size = Vector2(0, 4)
	accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(accent)
	column.move_child(accent, 0)
	var hint := _label(null, "Fullscreen: Settings > Fullscreen, or press F11", 15, MUTED)
	_ui.add_child(hint)
	hint.anchor_left = 1.0
	hint.anchor_right = 1.0
	hint.anchor_top = 1.0
	hint.anchor_bottom = 1.0
	hint.offset_left = -500
	hint.offset_right = -40
	hint.offset_top = -76
	hint.offset_bottom = -52
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var version := _label(null, "Prototype build v%s  ·  created by tan da man" % GD.VERSION, 15, MUTED)
	_ui.add_child(version)
	version.anchor_left = 1.0
	version.anchor_right = 1.0
	version.anchor_top = 1.0
	version.anchor_bottom = 1.0
	version.offset_left = -520
	version.offset_right = -40
	version.offset_top = -50
	version.offset_bottom = -24
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_build_coming_features()
	_build_settings()


## Bottom right, above the version line: what's on the way.
## A small PATCH NOTES button in the menu's bottom-right corner, beside Quit.
func _build_patch_notes_button(parent: Control) -> void:
	var button := Button.new()
	button.text = "  PATCH NOTES  "
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 14)
	button.add_theme_color_override("font_color", GOLD)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.035, 0.047, 0.078, 0.85)
	normal.border_color = Color(GOLD, 0.6)
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(4)
	normal.content_margin_top = 4
	normal.content_margin_bottom = 4
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(GOLD, 0.18)
	hover.border_color = GOLD
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	parent.add_child(button)
	button.mouse_entered.connect(func() -> void: Sfx.ui("hover"))
	button.pressed.connect(func() -> void:
		Sfx.ui("click")
		_open_patch_notes())


## The patch notes page: a big panel with the last three major revisions.
func _open_patch_notes() -> void:
	if _notes_layer != null:
		_notes_layer.visible = true
		return
	_notes_layer = ColorRect.new()
	(_notes_layer as ColorRect).color = Color(0.01, 0.015, 0.03, 0.78)
	_notes_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	_ui.add_child(_notes_layer)
	_notes_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_notes_layer.gui_input.connect(func(event: InputEvent) -> void:
		var mb := event as InputEventMouseButton
		if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_notes_layer.visible = false)   # click outside the page to close
	var centre := CenterContainer.new()
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_notes_layer.add_child(centre)
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.047, 0.078, 0.98)
	style.border_color = GOLD
	style.set_border_width_all(2)
	style.border_width_top = 5
	style.set_corner_radius_all(10)
	style.content_margin_left = 40
	style.content_margin_right = 40
	style.content_margin_top = 28
	style.content_margin_bottom = 28
	style.shadow_color = Color(0, 0, 0, 0.6)
	style.shadow_size = 30
	panel.add_theme_stylebox_override("panel", style)
	panel.custom_minimum_size = Vector2(1180, 820)
	centre.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	panel.add_child(column)
	var head := HBoxContainer.new()
	column.add_child(head)
	var title := _label(head, "PATCH NOTES", 36, GOLD)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label(head, "Current build v%s   " % GD.VERSION, 16, MUTED).size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var close := _button(head, "Close", 20, func() -> void: _notes_layer.visible = false)
	close.custom_minimum_size = Vector2(130, 44)
	var rule := ColorRect.new()
	rule.color = Color("2a3442")
	rule.custom_minimum_size = Vector2(0, 2)
	column.add_child(rule)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 680)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 26)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	for rev in PatchNotes.REVISIONS:
		var block := VBoxContainer.new()
		block.add_theme_constant_override("separation", 8)
		list.add_child(block)
		var top := HBoxContainer.new()
		top.add_theme_constant_override("separation", 16)
		block.add_child(top)
		_label(top, String(rev[1]), 26, CREAM)
		var versions := _label(top, String(rev[0]), 16, GOLD)
		versions.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		for line in Array(rev[2]):
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 12)
			block.add_child(row)
			var dot := _label(row, "•", 18, GOLD)
			dot.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
			var text := _label(row, String(line), 18, Color("d6dde4"))
			text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			text.custom_minimum_size = Vector2(1000, 0)


func _build_coming_features() -> void:
	var box := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.047, 0.078, 0.82)
	style.set_border_width_all(2)
	style.border_color = Color("2a3442")
	style.border_width_top = 3
	style.set_corner_radius_all(8)
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 16
	style.content_margin_bottom = 18
	style.shadow_color = Color(0, 0, 0, 0.5)
	style.shadow_size = 20
	box.add_theme_stylebox_override("panel", style)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# The [ENTER] for feedback hint sits on top of the panel (v0.9.202).
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 10)
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(stack)
	stack.anchor_left = 1.0
	stack.anchor_right = 1.0
	stack.anchor_top = 1.0
	stack.anchor_bottom = 1.0
	stack.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	stack.grow_vertical = Control.GROW_DIRECTION_BEGIN
	stack.offset_left = -40
	stack.offset_right = -40
	stack.offset_top = -96
	stack.offset_bottom = -96
	_feedback_hint(stack)
	stack.add_child(box)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	box.add_child(column)
	_label(column, "IN PROGRESS", 20, GOLD)
	for item in ["Working Card Rarities", "Pop Happiness", "Devastation", "Government Types", "Different Faction Unlocks", "3D Art & Lighting Engine", "Multiplayer OoOoooOOo 👀"]:
		_label(column, "•  " + String(item), 17, CREAM)


## Clicking the book: the start-of-run tutorial pages, right here on the title screen.
func _open_tutorial() -> void:
	if _guide_hud != null and is_instance_valid(_guide_hud):
		return
	_guide_hud = (load("res://scripts/hud.gd") as GDScript).new()
	_guide_hud.set("guide_only", true)
	add_child(_guide_hud)
	_guide_hud.call("show_economy_guide")
	_guide_hud.connect("guide_closed", func() -> void:
		if _guide_hud != null and is_instance_valid(_guide_hud):
			_guide_hud.queue_free()
		_guide_hud = null)


func _set_noob(on: bool) -> void:
	Settings.noob_mode = on
	if on and not Settings.advisor_on:
		# Opening the book again brings Xander back, with all his warnings.
		Settings.advisor_on = true
		Settings.advisor_dismissed = []
	Settings.save_settings()
	_sync_noob()


## Keeps the title toggle, the Settings toggle and its sub-options in step.
func _sync_noob() -> void:
	# The book shows ON only while Xander is actually around: switch him off in a run
	# (his X, or the pause menu) and the book closes here too, so nobody wonders why
	# he's gone quiet.
	if _book != null:
		_book.set("on", Settings.xander_on())
	if _noob_switch != null:
		_noob_switch.set("on", Settings.xander_on())
	if _sub_advisor != null:
		_sub_advisor.set_pressed_no_signal(Settings.advisor_on)
	if _settings_noob != null:
		_settings_noob.set_pressed_no_signal(Settings.noob_mode)
	for sub in [_sub_advisor, _sub_tutorial]:
		if sub != null:
			(sub as CheckBox).disabled = not Settings.noob_mode
	if _noob_subs != null:
		_noob_subs.modulate.a = 1.0 if Settings.noob_mode else 0.45


## "[ENTER] for feedback", right-aligned, with a keycap like the in-game hotkeys.
## Clicking it opens the feedback panel too.
func _feedback_hint(parent: Control) -> void:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_STOP
	row.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	row.tooltip_text = "Bugs, ideas, anything: it goes straight to the developer"
	parent.add_child(row)
	var cap := PanelContainer.new()
	var style := StyleBoxFlat.new()   # same raised key as the in-game hotkeys
	style.bg_color = Color("2c3642")
	style.border_color = Color("12171e")
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 7
	style.set_corner_radius_all(7)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	style.shadow_color = Color(0, 0, 0, 0.45)
	style.shadow_size = 3
	style.shadow_offset = Vector2(0, 3)
	cap.add_theme_stylebox_override("panel", style)
	cap.custom_minimum_size = Vector2(76, 34)
	cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(cap)
	var key := Label.new()
	key.text = "ENTER"
	key.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	key.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	key.add_theme_font_size_override("font_size", 14)
	key.add_theme_color_override("font_color", Color("e9e6dc"))
	cap.add_child(key)
	var text := Label.new()
	text.text = "for feedback"
	text.add_theme_font_size_override("font_size", 16)
	text.add_theme_color_override("font_color", Color("c9d2d8"))
	text.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(text)
	var clicked := func(event: InputEvent) -> void:
		var mb := event as InputEventMouseButton
		if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT and FeedbackPanel.shared != null:
			Sfx.ui("click")
			FeedbackPanel.shared.call("open")
	row.gui_input.connect(clicked)


## A small yellow "COMING SOON" tag on the right of a menu button.
func _coming_soon_tag(button: Button) -> void:
	var tag := Label.new()
	tag.text = "COMING SOON"
	tag.add_theme_font_size_override("font_size", 14)
	tag.add_theme_color_override("font_color", GOLD)
	tag.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(tag)
	tag.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tag.offset_right = -16


func _label(parent: Control, text: String, size: int, colour: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", colour)
	if parent != null:
		parent.add_child(label)
	return label


func _button(parent: Control, text: String, size: int, action: Callable) -> Button:
	var button := Button.new()
	button.text = "   " + text
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(0, 64 if size >= 30 else 48)
	button.add_theme_font_size_override("font_size", size)
	button.add_theme_color_override("font_color", Color("e9e6dc"))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_disabled_color", Color("8a96a3"))
	var flat := StyleBoxFlat.new()
	flat.bg_color = Color(0, 0, 0, 0)
	flat.set_corner_radius_all(6)
	var hover := flat.duplicate() as StyleBoxFlat
	hover.bg_color = Color(GOLD, 0.12)
	hover.border_color = GOLD
	hover.border_width_left = 4
	button.add_theme_stylebox_override("normal", flat)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_stylebox_override("disabled", flat)
	button.add_theme_stylebox_override("focus", flat)
	parent.add_child(button)
	button.mouse_entered.connect(func() -> void:
		if not button.disabled:
			Sfx.ui("hover"))
	if action.is_valid():
		button.pressed.connect(func() -> void:
			Sfx.ui("click")
			action.call())
	return button


func _show_note(text: String) -> void:
	_note.text = "   " + text
	_note_left = 3.0


func _start_run() -> void:
	GD.menu_passed = true
	get_tree().change_scene_to_file("res://scenes/main.tscn")


# --- settings ----------------------------------------------------------------------

func _build_settings() -> void:
	_settings_panel = PanelContainer.new()
	var style := StyleBoxFlat.new()
	# Lighter than the rest of the menu so the dark checkboxes stand out.
	style.bg_color = Color(0.14, 0.18, 0.23, 0.97)
	style.border_color = GOLD
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.content_margin_left = 36
	style.content_margin_right = 36
	style.content_margin_top = 28
	style.content_margin_bottom = 28
	_settings_panel.add_theme_stylebox_override("panel", style)
	_ui.add_child(_settings_panel)
	_settings_panel.position = Vector2(670, 330)   # beside the menu (moved left with it, v0.9.122)
	_settings_panel.custom_minimum_size = Vector2(520, 0)
	_settings_panel.visible = false
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	_settings_panel.add_child(column)
	_label(column, "SETTINGS", 32, GOLD)
	_slider(column, "Music", Settings.music, func(v: float) -> void:
		Settings.music = v
		Settings.apply()
		Settings.save_settings())
	_slider(column, "Sound effects", Settings.sfx, func(v: float) -> void:
		Settings.sfx = v
		Settings.apply()
		Settings.save_settings())
	_toggle(column, "Damage numbers", Settings.damage_numbers, func(on: bool) -> void:
		Settings.damage_numbers = on
		Settings.apply()
		Settings.save_settings())
	_toggle(column, "Abbreviated Ship Names", Settings.abbrev_names, func(on: bool) -> void:
		Settings.abbrev_names = on
		Settings.apply()
		Settings.save_settings())
	_toggle(column, "XP pop-ups on ships", Settings.xp_popups, func(on: bool) -> void:
		Settings.xp_popups = on
		Settings.save_settings())
	_fullscreen_box = _toggle(column, "Fullscreen", Settings.fullscreen, func(on: bool) -> void:
		Settings.fullscreen = on
		Settings.apply()
		Settings.save_settings())
	_fullscreen_box.tooltip_text = "F11 also switches fullscreen"
	_toggle(column, "Skip developer intro", Settings.skip_intro, func(on: bool) -> void:
		Settings.skip_intro = on
		Settings.save_settings())
	# Noob Mode gets its own box at the bottom: the master switch in the header,
	# the parts it switches on inside.
	var noob_box := PanelContainer.new()
	var nbs := StyleBoxFlat.new()
	nbs.bg_color = Color(0.95, 0.76, 0.19, 0.07)
	nbs.border_color = GOLD
	nbs.set_border_width_all(2)
	nbs.border_width_top = 4
	nbs.set_corner_radius_all(8)
	nbs.content_margin_left = 18
	nbs.content_margin_right = 18
	nbs.content_margin_top = 10
	nbs.content_margin_bottom = 12
	noob_box.add_theme_stylebox_override("panel", nbs)
	column.add_child(noob_box)
	var noob_col := VBoxContainer.new()
	noob_col.add_theme_constant_override("separation", 6)
	noob_box.add_child(noob_col)
	var noob_head := HBoxContainer.new()
	noob_col.add_child(noob_head)
	var noob_title := Label.new()
	noob_title.text = "NOOB MODE"
	noob_title.add_theme_font_size_override("font_size", 22)
	noob_title.add_theme_color_override("font_color", GOLD)
	noob_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	noob_head.add_child(noob_title)
	var noob_note := Label.new()
	noob_note.text = "Beginner help for new Commanders."
	noob_note.add_theme_font_size_override("font_size", 14)
	noob_note.add_theme_color_override("font_color", Color("a9b4c0"))
	noob_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	noob_note.custom_minimum_size = Vector2(360, 0)
	noob_col.add_child(noob_note)
	var noob_subs := VBoxContainer.new()
	noob_subs.add_theme_constant_override("separation", 2)
	noob_col.add_child(noob_subs)
	_settings_noob = _toggle(noob_head, "On", Settings.noob_mode, func(on: bool) -> void:
		_set_noob(on))
	_settings_noob.tooltip_text = "Xander and the start-of-run tutorial"
	_noob_subs = noob_subs
	_sub_advisor = _toggle(noob_subs, "Xander, Fleet Advisor", Settings.advisor_on, func(on: bool) -> void:
		Settings.advisor_on = on
		if on:
			Settings.advisor_dismissed = []   # turning him back on brings every warning back
		Settings.save_settings()
		_sync_noob())
	# Ticked = the start-of-run guide shows again (untick it from the guide itself).
	var config := ConfigFile.new()
	config.load(Settings.PATH)
	var guide_on := not bool(config.get_value("guide", "hide_v2", false))
	_sub_tutorial = _toggle(noob_subs, "Tutorial at the start of runs", guide_on, func(on: bool) -> void:
		var cfg := ConfigFile.new()
		cfg.load(Settings.PATH)
		cfg.set_value("guide", "hide_v2", not on)
		cfg.save(Settings.PATH))
	_sync_noob()
	var back := _button(column, "Back", 24, func() -> void: _settings_panel.visible = false)
	back.custom_minimum_size = Vector2(0, 52)


func _slider(parent: Control, text: String, value: float, changed: Callable) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	parent.add_child(row)
	var name_label := _label(row, text, 20, Color("e9e6dc"))
	name_label.custom_minimum_size = Vector2(170, 0)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = value
	slider.custom_minimum_size = Vector2(260, 32)
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.focus_mode = Control.FOCUS_NONE
	row.add_child(slider)
	slider.value_changed.connect(changed)


func _toggle(parent: Control, text: String, on: bool, changed: Callable) -> CheckBox:
	var box := CheckBox.new()
	box.text = text
	box.button_pressed = on
	box.focus_mode = Control.FOCUS_NONE
	box.add_theme_font_size_override("font_size", 20)
	parent.add_child(box)
	box.toggled.connect(changed)
	return box


func _open_settings() -> void:
	_settings_panel.visible = not _settings_panel.visible


func _unhandled_input(event: InputEvent) -> void:
	if FeedbackPanel.is_open:
		return   # typing feedback (Enter panel)
	var key := event as InputEventKey
	if key != null and key.pressed and not key.echo and key.keycode == KEY_F11:
		Settings.fullscreen = not Settings.fullscreen
		Settings.apply()
		Settings.save_settings()
		if _fullscreen_box != null:
			_fullscreen_box.set_pressed_no_signal(Settings.fullscreen)
		get_viewport().set_input_as_handled()
		return
	if key != null and key.pressed and key.keycode == KEY_ESCAPE and _notes_layer != null and _notes_layer.visible:
		_notes_layer.visible = false
		get_viewport().set_input_as_handled()
		return
	if key != null and key.pressed and key.keycode == KEY_ESCAPE and _settings_panel.visible:
		_settings_panel.visible = false
		get_viewport().set_input_as_handled()


## Noob Mode as a "Space 4 Dummies" book peeking out from behind the menu's
## bottom-right corner. Click to toggle; it slides further out when on and when
## hovered, and the hover card explains what Noob Mode does.
class NoobBook extends Control:
	signal opened
	const SfxRef = preload("res://scripts/sfx.gd")
	const Spr = preload("res://scripts/xander_sprite.gd")
	const YELLOW := Color("f2c230")
	const INK := Color("111318")
	const PAGES := Color("efe6cf")
	const BOOK := Vector2(150, 196)

	var on := false
	var _hover := false
	var _out := 0.0     # 0 tucked in, 1 fully out
	var _t := 0.0

	func _init() -> void:
		size = Vector2(290, 330)
		custom_minimum_size = size
		mouse_filter = Control.MOUSE_FILTER_STOP
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		tooltip_text = "noob"   # any text: the card itself comes from _make_custom_tooltip
		mouse_entered.connect(func() -> void:
			_hover = true
			SfxRef.ui("hover"))
		mouse_exited.connect(func() -> void: _hover = false)

	func _gui_input(event: InputEvent) -> void:
		var mb := event as InputEventMouseButton
		if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			SfxRef.ui("click")
			opened.emit()   # open the book: the tutorial pages
			accept_event()

	func _process(delta: float) -> void:
		_t += delta
		var target := (0.55 if on else 0.15) + (0.45 if _hover else 0.0)
		_out = lerpf(_out, target, minf(1.0, delta * 9.0))
		queue_redraw()

	func _draw() -> void:
		var font := ThemeDB.fallback_font
		# Slides out to the right and leans right (clockwise) as it comes out.
		var at := Vector2(20.0 + _out * 60.0, 110.0 - _out * 16.0)
		var angle := deg_to_rad(9.0 + _out * 9.0 + (sin(_t * 2.2) * 0.8 if _hover else 0.0))
		var pivot := at + Vector2(0, BOOK.y)
		draw_set_transform(pivot, angle, Vector2.ONE)
		var o := Vector2(0, -BOOK.y)
		var w := BOOK.x
		var h := BOOK.y
		var dim := 1.0 if on else 0.72
		var tint := Color(dim, dim, dim)
		var depth := Vector2(13, 8)   # how far the back cover sits behind the front
		# Soft drop shadow in a few layers.
		for i: int in 4:
			var grow := float(i) * 4.0
			draw_rect(Rect2(o + depth + Vector2(6, 8) - Vector2(grow, grow) * 0.5, BOOK + Vector2(grow, grow)), Color(0, 0, 0, 0.14))
		# Xander, peeking over the top (drawn early so the book hides his treads).
		_xander(o)
		# Back cover, then the page block along the right and bottom edges.
		draw_rect(Rect2(o + depth, BOOK), Color("2a2416") * tint)
		var tr := o + Vector2(w, 0)
		var br := o + Vector2(w, h)
		var bl := o + Vector2(0, h)
		draw_colored_polygon(PackedVector2Array([tr + Vector2(0, 4), tr + depth + Vector2(-2, 2), br + depth - Vector2(2, 3), br]), PAGES * tint)
		draw_colored_polygon(PackedVector2Array([bl, br, br + depth - Vector2(2, 3), bl + depth - Vector2(2, 3)]), (PAGES * Color(0.86, 0.84, 0.8)) * tint)
		var line_col := Color(0.55, 0.5, 0.4, 0.55)
		for k: int in range(1, 7):
			var f := float(k) / 7.0
			draw_line(tr + Vector2(0, 4) + (depth - Vector2(2, 2)) * f, br + (depth - Vector2(2, 3)) * f, line_col, 1.0)
			draw_line(bl + (depth - Vector2(2, 3)) * f, br + (depth - Vector2(2, 3)) * f, line_col, 1.0)
		# Front cover.
		var cover := Rect2(o, BOOK)
		draw_rect(cover, YELLOW * tint)
		# Spine: dark, with a lit ridge and a crease line.
		draw_rect(Rect2(o, Vector2(16, h)), INK)
		draw_rect(Rect2(o + Vector2(3, 0), Vector2(3, h)), Color(1, 1, 1, 0.12))
		draw_line(o + Vector2(19, 0), o + Vector2(19, h), Color(0, 0, 0, 0.25), 2.0)
		# Title band.
		draw_rect(Rect2(o + Vector2(16, 14), Vector2(w - 16, 44)), INK)
		_fit(font, "SPACE", o + Vector2(26, 48), 30, 92.0, YELLOW * tint)
		_fit(font, "4 DUMMIES", o + Vector2(26, 86), 22, w - 36.0, INK)
		# A doodled ringed planet and a wobbly rocket.
		var pc := o + Vector2(64, 124)
		draw_circle(pc, 16.0, INK)
		draw_circle(pc + Vector2(-3, -3), 12.5, Color("e0703a") * tint)
		draw_arc(pc, 25.0, deg_to_rad(160), deg_to_rad(380), 24, INK, 3.0)
		var rk := o + Vector2(120, 126 - sin(_t * 3.0) * 3.0)
		draw_colored_polygon(PackedVector2Array([rk + Vector2(0, -16), rk + Vector2(6, 2), rk + Vector2(-6, 2)]), INK)
		draw_line(rk + Vector2(-3, 4), rk + Vector2(-5, 12), Color("e0703a"), 2.0)
		draw_line(rk + Vector2(3, 4), rk + Vector2(5, 12), Color("e0703a"), 2.0)
		# Bottom line: what's inside. (The ON/OFF lives on the switch under the book now.)
		_fit(font, "TUTORIAL INSIDE", o + Vector2(24, h - 16), 14, w - 36.0, INK)
		# Gloss: a faint diagonal sheen and a lit top edge.
		draw_colored_polygon(PackedVector2Array([o + Vector2(16, 0), o + Vector2(70, 0), o + Vector2(16, 70)]), Color(1, 1, 1, 0.10))
		draw_line(o + Vector2(16, 1), tr + Vector2(0, 1), Color(1, 1, 1, 0.35), 2.0)
		draw_rect(cover, INK, false, 2.0)
		# The "NEW!" starburst sticker hanging off the top-right corner.
		var sc := tr + Vector2(-2, 2)
		var burst := PackedVector2Array()
		for i: int in 24:
			var r := 21.0 if i % 2 == 0 else 14.0
			var a := TAU * float(i) / 24.0 + _t * 0.4
			burst.append(sc + Vector2(cos(a), sin(a)) * r)
		draw_colored_polygon(burst, Color("e2402a"))
		var nw := font.get_string_size("NEW!", HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
		_text(font, "NEW!", sc + Vector2(-nw / 2.0, 4), 11, Color.WHITE)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	## Draws text, shrinking the font until it fits the given width.
	func _fit(font: Font, text: String, at: Vector2, fs: int, max_w: float, colour: Color) -> void:
		var size_now := fs
		while size_now > 9 and font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size_now).x > max_w:
			size_now -= 1
		_text(font, text, at, size_now, colour)

	## Pops up when Noob Mode is on, ducks down to just his eyestalks when it's off.
	var _peek := 0.0

	func _xander(o: Vector2) -> void:
		var k := 2.0
		var target := (0.62 if on else 0.18) + (0.12 if _hover else 0.0)
		_peek = lerpf(_peek, target, 0.12)
		var rise := Spr.H * k * _peek + sin(_t * 2.0) * 2.0
		var origin := o + Vector2(28.0, -rise + 6.0)
		_runs(Spr.STALK0, origin, k)
		_runs(Spr.STALK1, origin, k)
		_runs(Spr.BODY, origin, k)
		# Little electric brows that flicker.
		if int(_t * 12.0) % 2 == 0:
			for i: int in 2:
				var eye: Vector2 = Spr.EYES[i]
				var at := origin + (eye + Vector2(-2.0, -6.0)) * k
				draw_rect(Rect2(at, Vector2(5.0 * k, k)), Color.WHITE)
				draw_rect(Rect2(at + Vector2(0, k), Vector2(5.0 * k, k)), Color("46c8e8"))

	func _runs(layer: Array, at: Vector2, k: float) -> void:
		for r in layer:
			draw_rect(Rect2(at + Vector2(float(r[0]), float(r[1])) * k, Vector2(float(r[2]) * k, k)), Spr.PALETTE[int(r[3])])

	func _text(font: Font, text: String, at: Vector2, fs: int, colour: Color) -> void:
		draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, colour)

	## The hover card: what Noob Mode switches on.
	func _make_custom_tooltip(_for_text: String) -> Object:
		var panel := PanelContainer.new()
		var st := StyleBoxFlat.new()
		st.bg_color = Color(0.035, 0.047, 0.078, 0.96)
		st.border_color = YELLOW
		st.set_border_width_all(2)
		st.set_corner_radius_all(6)
		st.content_margin_left = 16
		st.content_margin_right = 16
		st.content_margin_top = 12
		st.content_margin_bottom = 12
		panel.add_theme_stylebox_override("panel", st)
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 4)
		panel.add_child(col)
		var lines := [
			["SPACE 4 DUMMIES", 18, YELLOW],
			["Click the book to read the tutorial.", 15, Color("f4efe2")],
			["The switch below turns Noob Mode on or off:", 15, Color("f4efe2")],
			["•  Xander, your Fleet Advisor, warns you before risky moves", 15, Color("f4efe2")],
			["•  The tutorial at the start of each run", 15, Color("f4efe2")],
		]
		for line in lines:
			var l := Label.new()
			l.text = String(line[0])
			l.add_theme_font_size_override("font_size", int(line[1]))
			l.add_theme_color_override("font_color", line[2] as Color)
			col.add_child(l)
		return panel


## One word of the title logo, drawn letter by letter so it can move.
## lively = SURVIVORS: a gentle wave through the letters, a sheen sweeping across every
## few seconds, and now and then one letter flickers like a damaged sign.
## Otherwise (STELLAR): steady letters with a soft breathing glow.
class LogoWord extends Control:
	var text := ""
	var font_size := 56
	var colour := Color.WHITE
	var lively := false
	var _t := 0.0
	var _flicker := -1        # the letter on the blink, or -1
	var _flicker_left := 0.0
	var _next_flicker := 3.0

	func setup(word: String, fs: int, c: Color, is_lively: bool) -> void:
		text = word
		font_size = fs
		colour = c
		lively = is_lively
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		var font := ThemeDB.fallback_font
		custom_minimum_size = Vector2(font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x + 8.0, font.get_height(font_size) + 6.0)

	func _process(delta: float) -> void:
		_t += delta
		if lively:
			_next_flicker -= delta
			if _next_flicker <= 0.0:
				_flicker = randi() % text.length()
				_flicker_left = randf_range(0.15, 0.4)
				_next_flicker = randf_range(4.0, 8.0)
			if _flicker_left > 0.0:
				_flicker_left -= delta
				if _flicker_left <= 0.0:
					_flicker = -1
		queue_redraw()

	func _draw() -> void:
		var font := ThemeDB.fallback_font
		var base_y := font.get_ascent(font_size) + 2.0
		var x := 0.0
		# The sheen: a bright band that sweeps left to right, then rests.
		var sweep := fmod(_t, 4.5) / 1.3 * float(text.length() + 4) - 2.0
		var breathe := 0.5 + 0.5 * sin(_t * 1.6)
		for i: int in text.length():
			var ch := text[i]
			var w := font.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
			var y := base_y
			var c := colour
			var glow_alpha := 0.12 + 0.1 * breathe
			if lively:
				y += sin(_t * 2.2 + i * 0.55) * 2.5
				var near := clampf(1.0 - absf(float(i) - sweep) / 1.6, 0.0, 1.0)
				c = colour.lerp(Color(1.0, 0.97, 0.85), near * 0.8)
				glow_alpha = 0.14 + 0.3 * near
				if i == _flicker:
					var on := fmod(_t * 23.0, 1.0) < 0.5
					c = Color(colour, 0.25 if on else 0.8)
					glow_alpha = 0.0
			draw_string_outline(font, Vector2(x, y), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 12, Color(colour, glow_alpha))
			draw_string(font, Vector2(x, y), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, c)
			x += w


## The Noob Mode switch under the Space 4 Dummies book: a little toggle in the same
## style as the book's old stamp, green and ON, or red and OFF, with a sliding knob.
class NoobSwitch extends Control:
	signal toggled(on: bool)
	const SfxRef = preload("res://scripts/sfx.gd")
	const INK := Color("111318")
	const GREEN := Color("2c8a4a")
	const RED := Color("7a2a2a")
	var on := false
	var _knob := 0.0   # 0 = left (OFF), 1 = right (ON)
	var _hover := false

	func _init() -> void:
		size = Vector2(176, 34)
		custom_minimum_size = size
		mouse_filter = Control.MOUSE_FILTER_STOP
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		tooltip_text = "Noob Mode: Xander and the start-of-run tutorial"
		mouse_entered.connect(func() -> void:
			_hover = true
			SfxRef.ui("hover"))
		mouse_exited.connect(func() -> void: _hover = false)

	func _gui_input(event: InputEvent) -> void:
		var mb := event as InputEventMouseButton
		if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			on = not on
			SfxRef.ui("click")
			toggled.emit(on)
			accept_event()

	func _process(delta: float) -> void:
		_knob = move_toward(_knob, 1.0 if on else 0.0, delta * 6.0)
		queue_redraw()

	func _draw() -> void:
		var font := ThemeDB.fallback_font
		# The label plate.
		var plate := Rect2(Vector2(0, 2), Vector2(96, 30))
		draw_rect(plate, Color("f2c230"))
		draw_rect(plate, INK, false, 2.0)
		var lw := font.get_string_size("NOOB MODE", HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
		draw_string(font, Vector2((plate.size.x - lw) / 2.0, 23), "NOOB MODE", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, INK)
		# The switch: a track that's green when on and red when off, a sliding knob.
		var track := Rect2(Vector2(102, 2), Vector2(72, 30))
		var colour := RED.lerp(GREEN, _knob)
		if _hover:
			colour = colour.lightened(0.15)
		draw_rect(track, colour)
		draw_rect(track, INK, false, 2.0)
		var text := "ON" if on else "OFF"
		var tw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
		var text_x := track.position.x + 8.0 if on else track.end.x - tw - 8.0
		draw_string(font, Vector2(text_x, 22), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)
		var knob_x := lerpf(track.position.x + 4.0, track.end.x - 26.0, _knob)
		var knob := Rect2(Vector2(knob_x, 6), Vector2(22, 22))
		draw_rect(knob, Color("e9e6dc"))
		draw_rect(knob, INK, false, 2.0)
		draw_line(knob.position + Vector2(7, 6), knob.position + Vector2(7, 16), Color(INK, 0.5), 1.5)
		draw_line(knob.position + Vector2(11, 6), knob.position + Vector2(11, 16), Color(INK, 0.5), 1.5)
		draw_line(knob.position + Vector2(15, 6), knob.position + Vector2(15, 16), Color(INK, 0.5), 1.5)
