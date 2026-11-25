extends Node2D
## A neutral Arms Dealer station. Fly the fleet into its orbit to shop.
## A big, rugged, lopsided junk-yard station: a welded hull of mismatched plates, an old
## freighter wreck bolted on, a cargo spine stacked with containers (he deals in bulk),
## a swinging crane, a half-dead solar array, turrets, drifting scrap and a neon sign.

const GD = preload("res://scripts/game_data.gd")
const ORBIT := 12.0   # units

var stock: Array = []   # 6 entries: card dictionaries, or {} once bought
var _time := 0.0
var _font: Font


func setup(pos_px: Vector2) -> void:
	position = pos_px
	_font = ThemeDB.fallback_font


func _process(delta: float) -> void:
	_time += delta
	if is_visible_in_tree() and GD.on_screen(self, 200.0 + 6.0 * GD.UNIT / GD.screen_scale(self)):
		queue_redraw()


const HULL := Color("6f6a62")
const HULL_DARK := Color("3d3a36")
const HULL_LIGHT := Color("a59d90")
const RUST := Color("8a4b2c")
const INK := Color("0b0e14")
const GOLD := Color("e8c547")
const CONTAINERS := [Color("8a3b2e"), Color("2f6f74"), Color("b08a2e"), Color("4d5a6a"), Color("6a4a7a"), Color("3f6a3a")]

var _scrap: Array = []        # [pos (units), size, angle, spin, colour]
var _stacks: Array = []       # [rect (units), colour]


func _ready() -> void:
	# The junk and the cargo are laid out once, the same way every time.
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	for i: int in 18:
		var a := rng.randf_range(-0.9, 2.4)   # mostly round the lower left: the scrap yard side
		var d := rng.randf_range(4.2, 6.4)
		var tone: Color = [HULL, HULL_DARK, RUST, Color("5a5f66")][rng.randi() % 4]
		_scrap.append([Vector2(cos(a + PI * 0.5), sin(a + PI * 0.5)) * d, rng.randf_range(0.18, 0.55), rng.randf() * TAU, rng.randf_range(-0.25, 0.25), tone])
	# Container stacks above and below the cargo spine, with gaps where some have sold.
	for row: int in 2:
		for col: int in 6:
			if rng.randf() < 0.15:
				continue
			var x := -4.5 + col * 0.72
			var y := (0.08 if row == 0 else 0.98)
			var askew := rng.randf_range(-0.04, 0.04)
			_stacks.append([Rect2(Vector2(x, y + askew), Vector2(0.66, 0.36)), CONTAINERS[rng.randi() % CONTAINERS.size()]])
			if rng.randf() < 0.45:   # stacked two high
				_stacks.append([Rect2(Vector2(x + 0.05, y + askew - 0.06), Vector2(0.56, 0.3)), CONTAINERS[rng.randi() % CONTAINERS.size()]])


func _draw() -> void:
	var u := GD.UNIT
	var k := GD.screen_scale(self)
	# Dashed orbit.
	for i in 48:
		if i % 2 == 0:
			var a := TAU * i / 48.0 + _time * 0.05
			draw_arc(Vector2.ZERO, ORBIT * u, a, a + TAU / 48.0, 4, Color(0.91, 0.77, 0.28, 0.7), 3.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(u, u))   # everything below is in units
	_draw_scrap()
	_draw_shadow()
	_draw_solar()
	_draw_cargo_spine()
	_draw_wreck()
	_draw_hull()
	_draw_turrets()
	_draw_crane()
	_draw_sign()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var label := "Arms Dealer" if GD.show_full_names else ("AD  ¢" if GD.show_abbrev_names else "")
	if label == "":
		return
	var tw := _font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
	draw_set_transform(Vector2(0, -4.4 * u - 6.0 * k), 0.0, Vector2(k, k))
	draw_string_outline(_font, Vector2(-tw / 2.0, 0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, 4, Color("0b0e14"))
	draw_string(_font, Vector2(-tw / 2.0, 0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("e8c14a"))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# --- the station, in units ------------------------------------------------------------

## Drifting scrap: bent plates and girders tumbling slowly round the yard.
func _draw_scrap() -> void:
	for piece in _scrap:
		var at: Vector2 = piece[0]
		var size: float = piece[1]
		var angle: float = float(piece[2]) + _time * float(piece[3])
		var tone: Color = piece[4]
		var pts := PackedVector2Array()
		for j: int in 4:
			var r := size * (0.6 + 0.4 * absf(sin(j * 1.7 + size * 9.0)))
			pts.append(at + Vector2.RIGHT.rotated(angle + j * TAU / 4.0 + 0.3 * j) * r)
		draw_colored_polygon(pts, tone)
		pts.append(pts[0])
		draw_polyline(pts, INK, 0.05)
		if size > 0.4:   # the big bits have a girder poking out
			draw_line(at, at + Vector2.RIGHT.rotated(angle) * size * 1.8, HULL_DARK, 0.07)


## Soft shadows under each big piece (hull, wreck, cargo spine), offset down-right.
func _draw_shadow() -> void:
	var off := Vector2(0.18, 0.28)
	var shade := Color(0, 0, 0, 0.3)
	for shape in [
		[Vector2(-0.6, -1.5), Vector2(1.4, -2.0), Vector2(2.6, -1.2), Vector2(2.9, 0.2), Vector2(2.2, 1.6), Vector2(0.6, 1.9), Vector2(-0.4, 1.25), Vector2(-0.9, -0.2)],
		[Vector2(0.4, -1.7), Vector2(-2.6, -2.5), Vector2(-3.3, -2.9), Vector2(-3.7, -2.4), Vector2(-3.2, -1.9), Vector2(-3.5, -1.5), Vector2(-0.2, -1.0)],
	]:
		var pts := PackedVector2Array()
		for q in shape:
			pts.append((q as Vector2) + off)
		draw_colored_polygon(pts, shade)
	draw_rect(Rect2(Vector2(-4.7, 0.02) + off, Vector2(4.4, 1.4)), shade)


## A salvaged solar array on a long strut: half its cells are dead, one wing is bent.
func _draw_solar() -> void:
	draw_line(Vector2(2.8, -0.2), Vector2(4.1, -0.5), HULL_DARK, 0.16)
	var wing := Rect2(Vector2(3.6, -1.4), Vector2(1.1, 0.8))
	draw_rect(wing, Color("1d3550"))
	for cx: int in 4:
		for cy: int in 3:
			var cell := Rect2(wing.position + Vector2(cx * 0.27 + 0.02, cy * 0.26 + 0.02), Vector2(0.23, 0.22))
			var dead := (cx * 3 + cy) % 5 == 1 or (cx == 3 and cy == 2)
			draw_rect(cell, Color("0d141c") if dead else Color("2f5a85"))
	draw_rect(wing, INK, false, 0.05)
	# The bent wing: skewed, and hanging off.
	var bent := PackedVector2Array([Vector2(3.7, -0.5), Vector2(4.7, -0.55), Vector2(4.5, 0.25), Vector2(3.6, 0.15)])
	draw_colored_polygon(bent, Color("223a55"))
	draw_line(Vector2(3.9, -0.45), Vector2(3.8, 0.12), Color("2f5a85"), 0.04)
	draw_line(Vector2(4.2, -0.48), Vector2(4.05, 0.18), Color("2f5a85"), 0.04)
	bent.append(bent[0])
	draw_polyline(bent, INK, 0.05)


## The cargo spine: a long truss out to the left, stacked with shipping containers.
## He deals in bulk.
func _draw_cargo_spine() -> void:
	var spine := Rect2(Vector2(-4.7, 0.5), Vector2(4.4, 0.4))
	draw_rect(spine, HULL_DARK)
	for i: int in 12:
		var x := spine.position.x + i * spine.size.x / 12.0
		draw_line(Vector2(x, spine.end.y), Vector2(x + spine.size.x / 12.0, spine.position.y), Color(HULL, 0.8), 0.05)
	draw_rect(spine, INK, false, 0.06)
	for stack in _stacks:
		var r: Rect2 = stack[0]
		var colour: Color = stack[1]
		draw_rect(r, colour)
		# Corrugation lines and a lit top edge.
		for j: int in 4:
			var x := r.position.x + r.size.x * float(j + 1) / 5.0
			draw_line(Vector2(x, r.position.y), Vector2(x, r.end.y), colour.darkened(0.3), 0.025)
		draw_line(r.position, Vector2(r.end.x, r.position.y), colour.lightened(0.3), 0.03)
		draw_rect(r, INK, false, 0.04)
	# Docking lights running down the spine.
	for i: int in 6:
		var on := 0.25 + 0.75 * clampf(sin(_time * 3.0 - i * 0.8), 0.0, 1.0)
		draw_circle(Vector2(-4.5 + i * 0.75, 0.7), 0.06, Color(GOLD, on))


## The wreck of an old freighter he welded on: broken bow, exposed ribs, a rust streak.
func _draw_wreck() -> void:
	var hull := PackedVector2Array([Vector2(0.4, -1.7), Vector2(-2.6, -2.5), Vector2(-3.3, -2.9), Vector2(-3.7, -2.4), Vector2(-3.2, -1.9), Vector2(-3.5, -1.5), Vector2(-0.2, -1.0)])
	draw_colored_polygon(hull, HULL.darkened(0.1))
	draw_colored_polygon(PackedVector2Array([Vector2(-1.2, -1.95), Vector2(-2.6, -2.35), Vector2(-2.7, -2.1), Vector2(-1.3, -1.7)]), RUST)
	# Exposed ribs where the bow tore off.
	for i: int in 5:
		var x := -3.0 + i * 0.16
		draw_line(Vector2(x, -2.75 + i * 0.05), Vector2(x - 0.15, -1.75), HULL_DARK, 0.05)
	draw_line(Vector2(0.2, -1.6), Vector2(-3.0, -2.45), HULL_LIGHT, 0.04)
	hull.append(hull[0])
	draw_polyline(hull, INK, 0.07)
	for i: int in 4:
		draw_circle(Vector2(-0.8 - i * 0.5, -1.55 - i * 0.12), 0.06, Color("ffd27a") if i != 2 else Color("3a2a1a"))   # portholes, one dead


## The main hull: welded from mismatched plates, rivets, hazard stripes, a big hangar door.
func _draw_hull() -> void:
	var body := PackedVector2Array([Vector2(-0.6, -1.5), Vector2(1.4, -2.0), Vector2(2.6, -1.2), Vector2(2.9, 0.2), Vector2(2.2, 1.6), Vector2(0.6, 1.9), Vector2(-0.4, 1.25), Vector2(-0.9, -0.2)])
	draw_colored_polygon(body, HULL)
	# Patch plates in whatever colour he had lying around.
	var patches := [
		[[Vector2(0.0, -1.3), Vector2(1.2, -1.6), Vector2(1.4, -0.7), Vector2(0.1, -0.5)], Color("7a7468")],
		[[Vector2(1.6, -0.9), Vector2(2.5, -0.9), Vector2(2.6, 0.1), Vector2(1.7, 0.2)], RUST],
		[[Vector2(0.4, 0.4), Vector2(1.5, 0.3), Vector2(1.6, 1.4), Vector2(0.6, 1.5)], Color("5d6670")],
		[[Vector2(-0.6, -0.3), Vector2(0.2, -0.3), Vector2(0.2, 0.9), Vector2(-0.4, 1.0)], Color("67604f")],
	]
	for patch in patches:
		var pts := PackedVector2Array(patch[0])
		draw_colored_polygon(pts, patch[1] as Color)
		pts.append(pts[0])
		draw_polyline(pts, Color(INK, 0.6), 0.035)
		for q in patch[0]:
			draw_circle((q as Vector2).lerp(pts[0], 0.12), 0.035, HULL_LIGHT)   # rivets
	# Hazard stripes along the lower edge.
	for i: int in 7:
		var a := Vector2(0.75 + i * 0.2, 1.78 - i * 0.02)
		draw_colored_polygon(PackedVector2Array([a, a + Vector2(0.1, 0), a + Vector2(0.0, -0.18), a + Vector2(-0.1, -0.18)]), GOLD if i % 2 == 0 else INK)
	# The hangar door: where the bulk orders go out, lit from inside.
	var door := Rect2(Vector2(2.3, -0.6), Vector2(0.45, 1.0))
	draw_rect(door, Color("1a1408"))
	draw_rect(Rect2(door.position + Vector2(0.06, 0.06), door.size - Vector2(0.12, 0.12)), Color(GOLD, 0.25 + 0.1 * sin(_time * 1.5)))
	draw_rect(door, INK, false, 0.05)
	# Lit top edge and outline.
	draw_line(body[0], body[1], HULL_LIGHT, 0.07)
	draw_line(body[1], body[2], HULL_LIGHT, 0.07)
	body.append(body[0])
	draw_polyline(body, INK, 0.09)


## Gun turrets: this is an arms dealer, after all. They sweep slowly.
func _draw_turrets() -> void:
	var spots := [Vector2(1.35, -1.75), Vector2(2.75, 0.85), Vector2(-0.55, 1.1)]
	for i: int in spots.size():
		var at: Vector2 = spots[i]
		var aim := Vector2.RIGHT.rotated(_time * 0.3 + i * 2.1)
		draw_line(at, at + aim * 0.5, INK, 0.1)
		draw_line(at, at + aim * 0.48, HULL_LIGHT, 0.04)
		draw_circle(at, 0.2, HULL_DARK)
		draw_circle(at, 0.11, GOLD.darkened(0.3))


## A cargo crane swinging a container between the spine and the hangar.
func _draw_crane() -> void:
	var base := Vector2(0.2, 1.4)
	var swing := 2.9 + 0.45 * sin(_time * 0.35)   # out over the container stacks
	var tip := base + Vector2.RIGHT.rotated(swing) * 2.1
	draw_line(base, tip, INK, 0.16)
	draw_line(base, tip, Color("d9a441"), 0.09)
	for j: int in 5:
		var p := base.lerp(tip, (j + 0.5) / 5.0)
		draw_circle(p, 0.03, INK)   # lattice holes
	draw_circle(base, 0.18, HULL_DARK)
	# The container on the hook, hanging below the tip.
	var hang := tip + Vector2(0, 0.35)
	draw_line(tip, hang, INK, 0.03)
	var box := Rect2(hang - Vector2(0.3, 0.0), Vector2(0.6, 0.3))
	draw_rect(box, CONTAINERS[2])
	draw_rect(box, INK, false, 0.04)


## A neon sign bolted to the wreck: "BULK ARMS", one letter on the blink, and a big $.
func _draw_sign() -> void:
	var at := Vector2(-2.9, -3.25)
	var font := _font
	var text := "BULK ARMS"
	var size := 30
	draw_set_transform(at * GD.UNIT, 0.0, Vector2.ONE)   # the sign is drawn in pixels
	var x := 0.0
	for i: int in text.length():
		var ch := text[i]
		var lit := 1.0
		if i == 6:   # the R flickers like it's about to go
			lit = 0.15 if fmod(_time * 7.0, 5.0) < 1.3 or fmod(_time, 2.3) < 0.15 else 1.0
		var w := font.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		if ch != " ":
			draw_string_outline(font, Vector2(x, 0), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 10, Color(1.0, 0.75, 0.2, 0.25 * lit))
			draw_string(font, Vector2(x, 0), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(1.0, 0.88, 0.45, lit))
		x += w
	# The $ in a ring, pulsing.
	var c := Vector2(x + 26.0, -10.0)
	var pulse := 0.7 + 0.3 * sin(_time * 3.0)
	draw_circle(c, 18.0, Color(0.15, 0.8, 0.4, 0.15 * pulse))
	draw_arc(c, 15.0, 0.0, TAU, 24, Color(0.3, 1.0, 0.5, pulse), 3.0)
	var dw := font.get_string_size("¢", HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x
	draw_string(font, c + Vector2(-dw / 2.0, 9.0), "¢", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(0.5, 1.0, 0.6, pulse))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(GD.UNIT, GD.UNIT))
