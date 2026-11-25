extends Control
## Card art: wobbly felt-tip scribbles on cream paper, one silly little picture per
## card, with only the odd sound effect ("PEW", "BONK") for words. The lines "boil" (redraw with fresh wobble a few times a second) like a
## hand-drawn cartoon. Drawn in a 220 x 120 space and scaled to fit.

var card_name := ""
## Zoom past "fit": the doodles leave some margin, so a little zoom fills the frame
## (the edges are clipped). 1.0 shows the whole 220 x 120 drawing.
var zoom := 1.0

const INK := Color("1d1b22")
const PAPER := Color("efe9da")
const RED := Color("e0473f")
const BLUE := Color("3d78c9")
const GREEN := Color("3aa55c")
const YELLOW := Color("f2c230")
const ORANGE := Color("f08a2a")
const PURPLE := Color("8a5cc9")
const GREY := Color("8c8a86")
const SKY := Color("8fd3f0")

var _frame := 0
var _t := 0.0
var _rng := RandomNumberGenerator.new()
var _k := 1.0
var _off := Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_t += delta
	var f := int(_t / 0.14) % 3
	if f != _frame:
		_frame = f
		queue_redraw()


# --- scribble kit ----------------------------------------------------------------

func _p(v: Vector2) -> Vector2:
	return _off + v * _k


func _wob() -> Vector2:
	return Vector2(_rng.randf_range(-1.1, 1.1), _rng.randf_range(-1.1, 1.1))


## A wobbly stroke through the points, drawn twice like a quick felt-tip.
func _stroke(pts: Array, colour: Color = INK, width: float = 2.2, closed: bool = false) -> void:
	for pass_i: int in 2:
		var line := PackedVector2Array()
		var all := pts.duplicate()
		if closed:
			all.append(pts[0])
		for i: int in all.size() - 1:
			var a: Vector2 = all[i]
			var b: Vector2 = all[i + 1]
			var steps := maxi(1, int(a.distance_to(b) / 9.0))
			for s: int in steps:
				line.append(_p(a.lerp(b, float(s) / float(steps)) + _wob()))
		line.append(_p(Vector2(all[all.size() - 1]) + _wob()))
		draw_polyline(line, Color(colour, 0.95 if pass_i == 0 else 0.5), width * _k * (1.0 if pass_i == 0 else 0.7))


func _line(a: Vector2, b: Vector2, colour: Color = INK, width: float = 2.2) -> void:
	_stroke([a, b], colour, width)


## A loose circle that overshoots its start, as a quick hand would.
func _circle(c: Vector2, r: float, colour: Color = INK, width: float = 2.2) -> void:
	var pts: Array = []
	var start := _rng.randf() * TAU
	var n := maxi(10, int(r * 0.9))
	for i: int in n + 3:
		var a := start + TAU * float(i) / float(n)
		pts.append(c + Vector2(cos(a), sin(a)) * (r + _rng.randf_range(-1.2, 1.2)))
	_stroke(pts, colour, width)


## Messy marker colouring inside a circle: zig-zag hatching.
func _fill_circle(c: Vector2, r: float, colour: Color) -> void:
	var line := PackedVector2Array()
	var y := -r + 2.0
	var left := true
	while y < r - 1.0:
		var half := sqrt(maxf(0.0, r * r - y * y)) - 1.5
		line.append(_p(c + Vector2(-half if left else half, y) + _wob()))
		left = not left
		y += 3.2
	if line.size() > 1:
		draw_polyline(line, Color(colour, 0.75), 3.0 * _k)


func _fill_poly(pts: Array, colour: Color) -> void:
	var poly := PackedVector2Array()
	for p in pts:
		poly.append(_p(Vector2(p) + _wob() * 0.6))
	draw_colored_polygon(poly, Color(colour, 0.55))


func _box(r: Rect2, colour: Color = INK, fill: Color = Color(0, 0, 0, 0)) -> void:
	var pts := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]
	if fill.a > 0.0:
		_fill_poly(pts, fill)
	_stroke(pts, colour, 2.2, true)


func _text(at: Vector2, text: String, size: int = 13, colour: Color = INK, tilt: float = -0.06) -> void:
	var font := ThemeDB.fallback_font
	draw_set_transform(_p(at), tilt + _rng.randf_range(-0.02, 0.02), Vector2(_k, _k))
	draw_string(font, Vector2.ZERO, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, colour)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _stars(n: int) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = hash(card_name)
	for i: int in n:
		var at := Vector2(r.randf_range(6, 214), r.randf_range(6, 114))
		_line(at - Vector2(2, 0), at + Vector2(2, 0), Color(INK, 0.35), 1.2)
		_line(at - Vector2(0, 2), at + Vector2(0, 2), Color(INK, 0.35), 1.2)


## A doodle spaceship: a pointy blob with a window and a flame.
func _ship(c: Vector2, s: float, angle: float = 0.0, colour: Color = BLUE, flame: bool = true) -> void:
	var d := Vector2.RIGHT.rotated(angle)
	var n := d.orthogonal()
	var body := [c + d * s, c - d * s * 0.7 + n * s * 0.5, c - d * s * 0.45, c - d * s * 0.7 - n * s * 0.5]
	_fill_poly(body, colour)
	_stroke(body, INK, 2.2, true)
	_circle(c + d * s * 0.2, s * 0.14, INK, 1.6)
	if flame:
		var tail := c - d * s * 0.55
		_stroke([tail + n * s * 0.15, tail - d * s * (0.5 + 0.15 * _frame), tail - n * s * 0.15], ORANGE, 2.0)


func _planet(c: Vector2, r: float, colour: Color = GREEN) -> void:
	_fill_circle(c, r, colour)
	_circle(c, r)


func _rock(c: Vector2, r: float) -> void:
	var pts: Array = []
	for i: int in 7:
		var a := TAU * float(i) / 7.0
		pts.append(c + Vector2(cos(a), sin(a)) * r * (0.8 + 0.25 * sin(a * 3.0 + 1.0)))
	_fill_poly(pts, GREY)
	_stroke(pts, INK, 2.2, true)


func _starbase(c: Vector2, r: float) -> void:
	_circle(c, r)
	_circle(c, r * 0.4)
	_fill_circle(c, r * 0.4, BLUE)
	for i: int in 4:
		var d := Vector2.RIGHT.rotated(PI * 0.25 + i * PI * 0.5)
		_line(c + d * r * 0.4, c + d * r)


func _stick(c: Vector2, s: float = 1.0) -> void:
	_circle(c - Vector2(0, 9) * s, 4.0 * s)
	_line(c - Vector2(0, 5) * s, c + Vector2(0, 5) * s)
	_line(c - Vector2(5, 1) * s, c + Vector2(5, -1) * s)
	_line(c + Vector2(0, 5) * s, c + Vector2(-4, 12) * s)
	_line(c + Vector2(0, 5) * s, c + Vector2(4, 12) * s)


func _bubble(c: Vector2, r: float) -> void:
	_circle(c, r, Color(SKY.darkened(0.3), 0.9), 1.8)
	_stroke([c + Vector2(-r * 0.55, -r * 0.3), c + Vector2(-r * 0.3, -r * 0.6)], Color(1, 1, 1, 0.9), 2.0)


func _speed(at: Vector2, n: int = 3, length: float = 26.0) -> void:
	for i: int in n:
		_line(at + Vector2(0, i * 7.0), at + Vector2(-length + i * 4.0, i * 7.0), Color(INK, 0.6), 1.5)


func _burst(c: Vector2, r: float, colour: Color = YELLOW) -> void:
	var pts: Array = []
	for i: int in 16:
		var a := TAU * float(i) / 16.0
		pts.append(c + Vector2(cos(a), sin(a)) * (r if i % 2 == 0 else r * 0.55))
	_fill_poly(pts, colour)
	_stroke(pts, INK, 2.0, true)


# --- the pictures -----------------------------------------------------------------

func _draw() -> void:
	# Fit the whole drawing, then the zoom on top: big art, little empty paper.
	_k = minf(size.x / 220.0, size.y / 120.0) * zoom
	_off = (size - Vector2(220, 120) * _k) / 2.0
	_rng.seed = hash(card_name) + _frame * 7919
	draw_rect(Rect2(Vector2.ZERO, size), PAPER)
	match card_name:
		# --- Tech ---
		"Deep Core Mining":
			_rock(Vector2(110, 70), 38)
			_stick(Vector2(58, 72))
			_line(Vector2(63, 64), Vector2(80, 52))
			_stroke([Vector2(74, 46), Vector2(82, 52), Vector2(86, 60)], INK, 2.6)
		"Gas Giant Siphons":
			_planet(Vector2(80, 70), 42, ORANGE)
			_stroke([Vector2(112, 44), Vector2(150, 26), Vector2(176, 28)], INK, 3.0)
			_ship(Vector2(186, 36), 16, PI * 0.95, BLUE, false)
			_text(Vector2(140, 74), "*slurp*", 15)
		"Urban Sprawl":
			_planet(Vector2(110, 150), 80, GREEN)
			for i: int in 9:
				var h := 26.0 + float((i * 53) % 50)
				_box(Rect2(34 + i * 17, 84 - h, 15, h), INK, Color(BLUE if i % 2 == 0 else YELLOW, 0.45))
			_text(Vector2(150, 26), "MORE!", 16, RED)
		"Trade Networks":
			_planet(Vector2(40, 64), 24, GREEN)
			_planet(Vector2(180, 64), 24, BLUE)
			_stroke([Vector2(64, 60), Vector2(110, 48), Vector2(156, 60)], INK, 1.8)
			_text(Vector2(92, 40), "¢", 22, GREEN)
		"Advanced Logistics":
			_box(Rect2(70, 14, 80, 96), INK, Color(1, 1, 1, 0.6))
			for i: int in 4:
				_box(Rect2(80, 26 + i * 20, 10, 10))
				_line(Vector2(96, 31 + i * 20), Vector2(138, 31 + i * 20), Color(INK, 0.6), 1.5)
			_stroke([Vector2(81, 29), Vector2(85, 34), Vector2(92, 24)], GREEN, 2.4)
			_box(Rect2(152, 66, 12, 12), RED)
		"Extended Orbits":
			_starbase(Vector2(90, 62), 18)
			_circle(Vector2(90, 62), 44, Color(BLUE, 0.8), 1.6)
			_line(Vector2(134, 62), Vector2(196, 62), YELLOW, 4.0)
		"Long-Range Sensors":
			_stick(Vector2(40, 74), 1.2)
			_circle(Vector2(52, 58), 6)
			_circle(Vector2(64, 58), 6)
			_text(Vector2(150, 40), "?!", 22, RED)
			_ship(Vector2(184, 58), 9, PI, RED, false)
			_stroke([Vector2(72, 58), Vector2(120, 50), Vector2(168, 58)], Color(INK, 0.4), 1.2)
		"Warp Drive Tuning":
			_ship(Vector2(120, 60), 30, 0.0, BLUE)
			_speed(Vector2(70, 46), 4, 40)
			_stroke([Vector2(150, 92), Vector2(162, 80), Vector2(170, 84), Vector2(160, 96)], GREY, 3.0)
			_text(Vector2(20, 110), "nyoooom", 15)
		"Colony Pods":
			_planet(Vector2(110, 140), 70, GREEN)
			_circle(Vector2(110, 22), 16)
			_fill_circle(Vector2(110, 22), 16, RED)
			_line(Vector2(96, 30), Vector2(106, 52))
			_line(Vector2(124, 30), Vector2(114, 52))
			_box(Rect2(102, 50, 16, 14), INK, YELLOW)
		"Orbital Habitats":
			_planet(Vector2(110, 108), 40, GREEN)
			for i: int in 4:
				_box(Rect2(96 + (i % 2) * 6, 58 - i * 14, 22, 14), INK, Color(YELLOW, 0.8))
		"Planetary Shields":
			_planet(Vector2(80, 64), 30, BLUE)
			_bubble(Vector2(80, 64), 42)
			_rock(Vector2(160, 40), 12)
			_text(Vector2(150, 84), "BOING", 16, RED)
		"Fortified Starbases":
			_starbase(Vector2(90, 62), 32)
			_box(Rect2(70, 40, 40, 10), INK, Color(1, 1, 1, 0.8))
		"Damage Control":
			_ship(Vector2(100, 60), 36, 0.2, BLUE)
			_box(Rect2(90, 46, 26, 9), INK, Color(1, 1, 1, 0.9))
			_box(Rect2(70, 66, 9, 22), INK, Color(GREY, 0.6))
		"Blink Drive":
			_stroke([Vector2(40, 48), Vector2(60, 60), Vector2(40, 72), Vector2(48, 60)], Color(INK, 0.35), 1.6, true)
			_burst(Vector2(52, 60), 14, Color(SKY, 0.8))
			_ship(Vector2(170, 60), 22, 0.0, BLUE, false)
			_text(Vector2(96, 30), "*poof*", 16)
		"Blink Drive II":
			_burst(Vector2(40, 60), 12, Color(SKY, 0.8))
			_burst(Vector2(100, 40), 12, Color(SKY, 0.8))
			_ship(Vector2(170, 60), 20, 0.0, BLUE, false)
			_circle(Vector2(110, 92), 12)
			_line(Vector2(110, 92), Vector2(110, 84))
		"Afterimage":
			_ship(Vector2(70, 60), 24, 0.0, Color(SKY, 0.4), false)
			_text(Vector2(46, 34), "boo", 13)
			_ship(Vector2(190, 30), 12, PI, RED, false)
			_line(Vector2(176, 34), Vector2(96, 56), RED, 1.6)
			_ship(Vector2(150, 96), 16, 0.0, BLUE)
		"Slipstream":
			_ship(Vector2(130, 60), 28, 0.0, BLUE)
			for i: int in 3:
				_line(Vector2(30, 40 + i * 20), Vector2(62, 50 + i * 10), RED, 2.0)
		"Tightened Logistics":
			_circle(Vector2(90, 64), 34)
			_line(Vector2(90, 64), Vector2(116, 44), RED, 3.0)
			_box(Rect2(132, 40, 66, 26), INK, YELLOW)
		"Ram Plating":
			_ship(Vector2(80, 60), 28, 0.0, BLUE)
			_box(Rect2(104, 52, 22, 16), INK, GREY)
			_ship(Vector2(160, 60), 20, PI, RED, false)
			_burst(Vector2(132, 58), 14)
			_text(Vector2(112, 28), "BONK", 18, RED)
		"Afterburner Wake":
			_ship(Vector2(170, 50), 22, 0.0, BLUE, false)
			for i: int in 5:
				_burst(Vector2(140 - i * 24, 52 + sin(i) * 4), 9 - i, ORANGE)
			_ship(Vector2(70, 92), 12, -0.5, RED, false)
		"Quick Spool":
			_stroke([Vector2(90, 20), Vector2(130, 20), Vector2(112, 60), Vector2(130, 100), Vector2(90, 100), Vector2(108, 60)], INK, 2.4, true)
			_line(Vector2(80, 66), Vector2(140, 54), RED, 3.0)
		"Hot Exit":
			_circle(Vector2(110, 62), 12)
			_circle(Vector2(110, 62), 28, ORANGE)
			_circle(Vector2(110, 62), 44, Color(ORANGE, 0.6))
			_ship(Vector2(190, 40), 10, 0.6, RED, false)
		"Overdrive Tanks":
			_box(Rect2(70, 18, 60, 90), INK, Color(GREEN, 0.7))
			_ship(Vector2(170, 64), 14, 0.0, BLUE)
		"Drift Thrusters":
			_stroke([Vector2(30, 90), Vector2(80, 88), Vector2(130, 70), Vector2(150, 40)], Color(INK, 0.5), 3.0)
			_stroke([Vector2(30, 98), Vector2(84, 96), Vector2(138, 76), Vector2(160, 44)], Color(INK, 0.5), 3.0)
			_ship(Vector2(164, 30), 18, -1.0, BLUE)
			_text(Vector2(20, 30), "SKRRT", 18)
		"Asteroid Force Fields":
			_rock(Vector2(110, 64), 28)
			_bubble(Vector2(110, 64), 42)
			_box(Rect2(94, 54, 12, 7), INK, INK)
			_box(Rect2(112, 54, 12, 7), INK, INK)
		# --- Planet buildings ---
		"City":
			for i: int in 5:
				var h := 30.0 + float((i * 37) % 40)
				_box(Rect2(50 + i * 24, 104 - h, 20, h), INK, Color(BLUE, 0.4))
		"PD MAG":
			_planet(Vector2(110, 130), 60, GREEN)
			_box(Rect2(100, 50, 20, 22), INK, GREY)
			_line(Vector2(110, 52), Vector2(140, 18), INK, 5.0)
			_text(Vector2(146, 36), "PEW", 16, RED)
		"Fleet Academy":
			_ship(Vector2(110, 70), 30, 0.0, BLUE)
			_fill_poly([Vector2(92, 34), Vector2(122, 26), Vector2(140, 34), Vector2(112, 42)], INK)
			_line(Vector2(132, 34), Vector2(136, 50), YELLOW, 2.0)
		"Tech Lab":
			_stroke([Vector2(96, 20), Vector2(96, 50), Vector2(76, 100), Vector2(144, 100), Vector2(124, 50), Vector2(124, 20)], INK, 2.4)
			_fill_poly([Vector2(86, 76), Vector2(134, 76), Vector2(144, 100), Vector2(76, 100)], GREEN)
			_circle(Vector2(104, 66), 4)
			_circle(Vector2(116, 56), 3)
		"Cryo Medicals":
			_box(Rect2(80, 30, 60, 70), Color(SKY.darkened(0.3)), Color(SKY, 0.6))
			_stick(Vector2(110, 68), 1.4)
		"Logistics Hub":
			_box(Rect2(70, 60, 36, 36), INK, Color(ORANGE, 0.7))
			_box(Rect2(110, 60, 36, 36), INK, Color(ORANGE, 0.7))
			_box(Rect2(90, 24, 36, 36), INK, Color(ORANGE, 0.7))
		"Mining Corp":
			_box(Rect2(80, 56, 60, 40), INK, Color(ORANGE, 0.6))
			_line(Vector2(100, 56), Vector2(104, 46))
			_line(Vector2(120, 56), Vector2(116, 46))
			_stroke([Vector2(60, 30), Vector2(80, 20), Vector2(96, 30)], INK, 3.0)
			_line(Vector2(78, 22), Vector2(70, 52), INK, 2.4)
		"Gas Refineries":
			_box(Rect2(70, 50, 80, 50), INK, Color(GREY, 0.6))
			_box(Rect2(126, 20, 14, 30), INK, Color(GREY, 0.6))
			_burst(Vector2(133, 14), 8, GREEN)
		"Space Elevators":
			_planet(Vector2(110, 140), 50, GREEN)
			_line(Vector2(110, 90), Vector2(110, 10))
			_box(Rect2(102, 40, 16, 14), INK, YELLOW)
			_starbase(Vector2(110, 12), 10)
		"Orbital Drydocks":
			_box(Rect2(40, 46, 140, 6), INK, GREY)
			_box(Rect2(40, 86, 140, 6), INK, GREY)
			_ship(Vector2(112, 69), 26, 0.0, BLUE, false)
			_speed(Vector2(70, 58), 3, 26)
			_text(Vector2(150, 34), "zoom", 15)
		"Shipwright Guild":
			# Two Construction Ships heading out together (v0.9.226).
			_box(Rect2(40, 80, 70, 14), INK, GREY)
			_ship(Vector2(120, 48), 20, -0.3, YELLOW, true)
			_ship(Vector2(150, 74), 20, -0.3, YELLOW, true)
			_text(Vector2(70, 34), "+1", 18)
		"Construction Yards":
			_box(Rect2(70, 50, 60, 46), INK, Color(YELLOW, 0.5))
			_line(Vector2(140, 96), Vector2(140, 20), INK, 3.0)
			_line(Vector2(140, 22), Vector2(90, 22), INK, 3.0)
			_line(Vector2(96, 22), Vector2(96, 44), Color(INK, 0.7), 1.5)
			_box(Rect2(88, 42, 16, 10), INK, ORANGE)
			_burst(Vector2(130, 60), 8)
		"Repair Gantries":
			_circle(Vector2(110, 62), 46, GREEN)
			_ship(Vector2(110, 64), 24, 0.0, BLUE)
			for i: int in 3:
				var at := Vector2(80 + i * 30, 30 - (i % 2) * 8)
				_line(at - Vector2(6, 0), at + Vector2(6, 0), GREEN, 3.0)
				_line(at - Vector2(0, 6), at + Vector2(0, 6), GREEN, 3.0)
		"Tractor Arrays":
			_starbase(Vector2(70, 62), 18)
			_rock(Vector2(170, 56), 16)
			for i: int in 3:
				_stroke([Vector2(92, 54 + i * 8), Vector2(124, 50 + i * 8), Vector2(152, 54 + i * 8)], Color(SKY.darkened(0.2), 0.9), 1.6)
			_text(Vector2(118, 110), "hnngh", 15)
		"Bunker Foundry":
			_starbase(Vector2(110, 62), 30)
			for i: int in 4:
				_box(Rect2(70 + i * 22, 92, 18, 12), INK, Color(GREY, 0.8))
			_box(Rect2(78, 26, 64, 10), INK, Color(GREY, 0.8))
		"Drone Docks":
			_starbase(Vector2(60, 62), 22)
			_ship(Vector2(160, 64), 22, PI, BLUE, false)
			for i: int in 3:
				var d := Vector2(110 + i * 14, 40 + (i % 2) * 40)
				_circle(d, 4)
				_line(d, Vector2(150, 64), Color(GREEN, 0.8), 1.4)
		"Mini MAG Batteries":
			_box(Rect2(80, 60, 60, 40), INK, GREY)
			for side: float in [-1.0, 1.0]:
				_line(Vector2(110 + side * 26, 70), Vector2(110 + side * 70, 30), INK, 6.0)
				draw_circle(_p(Vector2(110 + side * 70, 30)), 5.0 * _k, Color("8fd1ff"))
			_text(Vector2(110, 112), "zzzap", 14, RED)
		"Long-Range Batteries":
			_box(Rect2(30, 70, 34, 26), INK, GREY)
			_line(Vector2(56, 74), Vector2(150, 40), INK, 5.0)
			_line(Vector2(150, 40), Vector2(196, 26), Color(INK, 0.5), 2.0)
			_text(Vector2(150, 80), "PEW", 16, RED)
		"Hangar Crews":
			_stick(Vector2(70, 80))
			_stick(Vector2(100, 80))
			_line(Vector2(104, 72), Vector2(130, 56), INK, 2.4)
			_ship(Vector2(160, 52), 14, -0.4, GREEN, false)
			_burst(Vector2(138, 66), 6)
		"Customs Office":
			_box(Rect2(60, 46, 70, 54), INK, Color(BLUE, 0.4))
			_box(Rect2(84, 70, 22, 30), INK, Color(1, 1, 1, 0.6))
			_starbase(Vector2(170, 40), 14)
			_text(Vector2(150, 96), "¢", 26, GREEN)
		"Hauler Depot":
			_box(Rect2(100, 54, 24, 18), INK, ORANGE)
			for i: int in 3:
				_box(Rect2(126 + i * 18, 56, 14, 14), INK, GREY)
			_speed(Vector2(92, 52), 3, 40)
			_text(Vector2(40, 106), "vroom", 15)
		"Colony Office":
			_box(Rect2(50, 40, 60, 60), INK, Color(1, 1, 1, 0.7))
			_stroke([Vector2(62, 74), Vector2(70, 84), Vector2(92, 56)], GREEN, 3.0)
			_planet(Vector2(170, 120), 50, GREEN)
			_circle(Vector2(160, 40), 8)
			_fill_circle(Vector2(160, 40), 8, RED)
		"Trade Port":
			_box(Rect2(60, 34, 100, 64), INK, Color(YELLOW, 0.5))
			_stroke([Vector2(150, 34), Vector2(176, 20), Vector2(190, 32)], INK, 2.0)
			_text(Vector2(96, 82), "¢", 34, GREEN)
			_line(Vector2(86, 88), Vector2(130, 46), RED, 3.0)
		# --- Fleet ---
		"Hardened Plating":
			_ship(Vector2(110, 60), 36, 0.0, BLUE)
			_box(Rect2(96, 44, 22, 32), INK, Color(GREY, 0.8))
			for y: float in [50.0, 70.0]:
				_circle(Vector2(100, y), 1.5)
		"Reinforced Hulls":
			_ship(Vector2(110, 60), 36, 0.0, BLUE)
			for i: int in 3:
				_box(Rect2(84 + i * 14, 54, 14, 10), INK, Color(RED, 0.6))
		"Shield Emitters":
			_ship(Vector2(110, 60), 26, 0.0, BLUE)
			_bubble(Vector2(110, 60), 44)
		"Overclocked Thrusters":
			_ship(Vector2(150, 60), 24, 0.0, BLUE, false)
			_burst(Vector2(100, 60), 20, ORANGE)
			_speed(Vector2(70, 46), 3, 40)
		"Rapid Loaders":
			_box(Rect2(40, 50, 100, 20), INK, GREY)
			for i: int in 3:
				_box(Rect2(150 + i * 14, 54, 10, 12), INK, YELLOW)
		"Missile Racks":
			_ship(Vector2(110, 64), 30, 0.0, BLUE)
			for i: int in 4:
				_box(Rect2(84 + i * 14, 30, 8, 18), INK, RED)
		"Drone Bay Expansion":
			for i: int in 3:
				_ship(Vector2(70 + i * 40, 50 + (i % 2) * 20), 10, 0.0, GREEN)
		"Efficient Shipyards":
			_box(Rect2(40, 50, 140, 40))
			_ship(Vector2(110, 70), 26, 0.0, Color(BLUE, 0.5), false)
			_stroke([Vector2(170, 20), Vector2(182, 20), Vector2(180, 36), Vector2(172, 36)], INK, 2.0, true)
		"Sustained Fire":
			_box(Rect2(30, 50, 80, 20), INK, GREY)
			for i: int in 6:
				_line(Vector2(120 + i * 16, 60), Vector2(130 + i * 16, 60), ORANGE, 2.5)
			_text(Vector2(110, 40), "BRRRRRT", 16)
		"Flak Retrofit":
			_ship(Vector2(100, 66), 24, 0.0, BLUE)
			_box(Rect2(92, 40, 18, 12), INK, GREY)
			for i: int in 3:
				_burst(Vector2(150 + i * 20, 30 + (i % 2) * 18), 8, ORANGE)
		"Kharkiv Gatling", "Kharkiv PDC", "Kharkiv Flak", "Kharkiv Mini MAG", "Kharkiv Torpedo Tube", "Kharkiv Missile Pod":
			# The Kharkiv with one new gun bolted on, firing its kind of shot (v0.9.225).
			_ship(Vector2(84, 66), 36, 0.0, BLUE, false)
			_box(Rect2(96, 50, 16, 10), INK, ORANGE)
			match card_name:
				"Kharkiv Gatling":
					for i: int in 4:
						_line(Vector2(118 + i * 14, 54), Vector2(126 + i * 14, 54), ORANGE, 2.0)
					_text(Vector2(140, 104), "BRRT", 13)
				"Kharkiv PDC":
					for i: int in 5:
						_line(Vector2(112, 55), Vector2(150 + i * 8, 24 + i * 7), Color(INK, 0.6), 1.2)
					_text(Vector2(140, 104), "tktktk", 13)
				"Kharkiv Flak":
					for i: int in 3:
						_burst(Vector2(140 + i * 16, 30 + (i % 2) * 16), 7, ORANGE)
				"Kharkiv Mini MAG":
					_line(Vector2(114, 55), Vector2(190, 55), SKY, 3.0)
					_burst(Vector2(192, 55), 5, SKY)
				"Kharkiv Torpedo Tube":
					_line(Vector2(114, 55), Vector2(160, 45), Color(INK, 0.4), 1.5)
					_box(Rect2(160, 40, 16, 8), INK, RED)
				"Kharkiv Missile Pod":
					for i: int in 3:
						_line(Vector2(114, 55), Vector2(160 + i * 10, 26 + i * 14), Color(INK, 0.4), 1.2)
						_burst(Vector2(162 + i * 10, 26 + i * 14), 3, SKY)
		"Twin MAG Mount":
			_ship(Vector2(100, 64), 38, 0.0, BLUE, false)
			_line(Vector2(120, 56), Vector2(176, 56), INK, 5.0)
			_line(Vector2(120, 72), Vector2(176, 72), INK, 5.0)
			_burst(Vector2(182, 56), 6, SKY)
			_burst(Vector2(182, 72), 6, SKY)
		"Broadside Battery":
			_ship(Vector2(80, 62), 34, 0.0, BLUE, false)
			for i: int in 3:
				_line(Vector2(96, 50 + i * 12), Vector2(140, 50 + i * 12), INK, 4.0)
			_text(Vector2(150, 70), "PEW", 16, RED)
		"Extra Torpedo Tubes":
			_ship(Vector2(60, 64), 22, 0.0, BLUE)
			_stroke([Vector2(84, 58), Vector2(130, 36), Vector2(180, 44)], ORANGE, 2.0)
			_stroke([Vector2(84, 70), Vector2(130, 92), Vector2(180, 84)], ORANGE, 2.0)
			_circle(Vector2(182, 44), 4)
			_circle(Vector2(182, 84), 4)
		"PDC Nest":
			_ship(Vector2(80, 70), 28, 0.0, BLUE)
			for i: int in 5:
				_line(Vector2(96, 56), Vector2(130 + i * 14, 20 + i * 4), Color(GREY.darkened(0.3), 0.9), 1.4)
			_ship(Vector2(186, 36), 7, PI, RED, false)
		"Missile Pods":
			_ship(Vector2(60, 64), 24, 0.0, BLUE)
			for i: int in 6:
				_stroke([Vector2(84, 64), Vector2(130, 30 + i * 12), Vector2(190, 50 + i * 4)], Color(SKY.darkened(0.3), 0.9), 1.4)
		"Gun Deck":
			_box(Rect2(50, 54, 110, 26), INK, Color(BLUE, 0.6))
			for i: int in 4:
				_line(Vector2(70 + i * 24, 54), Vector2(80 + i * 24, 36), INK, 3.0)
			_text(Vector2(120, 110), "BRRRT", 15)
		"Hot-Loaded MAGs":
			_box(Rect2(40, 56, 120, 14), INK, GREY)
			_burst(Vector2(170, 63), 16, SKY)
			for i: int in 3:
				_stroke([Vector2(70 + i * 24, 50), Vector2(74 + i * 24, 40), Vector2(70 + i * 24, 30)], ORANGE, 2.0)
		"Shaped Warheads":
			_box(Rect2(50, 54, 90, 18), INK, GREY)
			_fill_poly([Vector2(140, 54), Vector2(170, 63), Vector2(140, 72)], RED)
			_stroke([Vector2(140, 54), Vector2(170, 63), Vector2(140, 72)], INK, 2.2, true)
			_text(Vector2(70, 40), "KABOOM", 15, RED)
		"Bigger Swarms":
			for i: int in 8:
				var at := Vector2(50 + (i % 4) * 34, 36 + floorf(i / 4.0) * 40)
				_line(at, at + Vector2(16, -4), INK, 3.0)
				_line(at - Vector2(6, -2), at, ORANGE, 2.0)
		"Proximity Fuses":
			for i: int in 3:
				_burst(Vector2(70 + i * 40, 50 + (i % 2) * 20), 14, ORANGE)
			_ship(Vector2(110, 60), 8, 0.5, RED, false)
		"Long-Range PDCs":
			_box(Rect2(40, 66, 34, 26), INK, GREY)
			_line(Vector2(74, 72), Vector2(200, 40), Color(INK, 0.7), 1.4)
			_line(Vector2(74, 80), Vector2(200, 60), Color(INK, 0.4), 1.0)
			_text(Vector2(130, 112), "x2 RANGE", 13)
		"PDC Overdrive":
			_box(Rect2(60, 60, 40, 30), INK, GREY)
			for i: int in 6:
				_line(Vector2(100, 70), Vector2(150 + i * 8, 20 + i * 12), Color(INK, 0.6), 1.2)
			_text(Vector2(130, 112), "tktktk", 13)
		"Wingmen":
			for i: int in 4:
				_ship(Vector2(60 + i * 32, 40 + absf(i - 1.5) * 22), 10, 0.0, GREEN)
		"Mine Layer":
			_ship(Vector2(160, 46), 22, 0.0, BLUE)
			for i: int in 3:
				_circle(Vector2(120 - i * 34, 76), 7)
				_fill_circle(Vector2(120 - i * 34, 76), 7, RED)
			_text(Vector2(40, 112), "plop", 12)
		_:
			_stars(6)
			_text(Vector2(96, 72), "?", 34)
