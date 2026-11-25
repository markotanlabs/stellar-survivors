extends Control
## Xander's animated infographics: one looping little scene per lesson page.
## Pages: "asteroids" (mine, don't shoot), "fields", "colonize", "growth".

const GD = preload("res://scripts/game_data.gd")

const INK := Color("0b0e14")
const CREAM := Color("f4efe2")
const MUTED := Color("8fa3b8")
const GOLD := Color("f0d27a")
const ALLOY := Color("b07cff")
const GAS := Color("5fe39a")
const CASH := Color("e8c547")
const BAD := Color("ff6b5a")
const UNE := Color("8fb4e3")
const ROCK := Color("6d6458")

var page := "asteroids"
var _t := 0.0
var _font: Font


func _init() -> void:
	custom_minimum_size = Vector2(470, 190)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true


func set_page(id: String) -> void:
	page = id
	_t = 0.0
	queue_redraw()


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_t += delta
	queue_redraw()


func _draw() -> void:
	_font = ThemeDB.fallback_font
	# Backdrop: a dark screen with a faint grid, like a holo-table.
	draw_rect(Rect2(Vector2.ZERO, size), Color("070b12"))
	for x: int in range(0, int(size.x), 24):
		draw_line(Vector2(x, 0), Vector2(x, size.y), Color(0.4, 0.6, 0.8, 0.05), 1.0)
	for y: int in range(0, int(size.y), 24):
		draw_line(Vector2(0, y), Vector2(size.x, y), Color(0.4, 0.6, 0.8, 0.05), 1.0)
	match page:
		"asteroids":
			_page_asteroids()
		"fields":
			_page_fields()
		"colonize":
			_page_colonize()
		"growth":
			_page_growth()
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.79, 0.65, 0.35, 0.6), false, 1.0)


# --- page 1: mine it, don't shoot it -------------------------------------------------

func _page_asteroids() -> void:
	var day := 2.0
	var d := fposmod(_t, day) / day
	# Left: a Starbase's orbit working two rocks, a Hauler carrying the haul home.
	var sb := Vector2(92, 92)
	_orbit(sb, 66.0)
	var alloy_rock := Vector2(58, 58)
	var gas_rock := Vector2(130, 128)
	_rock(alloy_rock, 13.0, ALLOY, 0.0)
	_rock(gas_rock, 11.0, GAS, 1.0)
	_starbase(sb)
	# Each "day" the yields hop from the rocks to the Starbase.
	if d < 0.45:
		var k := d / 0.45
		_alloy_icon(alloy_rock.lerp(sb, k), 6.0)
		_gas_icon(gas_rock.lerp(sb, k), 5.0)
	# Then the Hauler carries them to the planet.
	var planet := Vector2(258, 92)
	_planet(planet, 20.0, Color("3a7bd5"), Color("4caf6a"))
	var hk := clampf((d - 0.4) / 0.5, 0.0, 1.0)
	var hauler := sb.lerp(planet - Vector2(24, 0), hk)
	draw_rect(Rect2(hauler - Vector2(7, 4), Vector2(14, 8)), Color("c9d2d8"))
	draw_rect(Rect2(hauler - Vector2(5, 3), Vector2(4, 6)), ALLOY)
	draw_rect(Rect2(hauler + Vector2(1, -3), Vector2(4, 6)), GAS)
	if d > 0.88:
		_rise_text("+ALLOYS +GAS", planet + Vector2(0, -28), (d - 0.88) / 0.12, GAS)
	_caption("MINE IT", Vector2(150, 178), GAS)
	_caption("PAYS EVERY DAY", Vector2(150, 18), MUTED, 12)
	# Divider.
	draw_line(Vector2(300, 14), Vector2(300, 176), Color(1, 1, 1, 0.12), 1.0)
	# Right: shooting a rock. $1, and the Alloys are gone until a new rock drifts in.
	var cycle := 4.0
	var c := fposmod(_t, cycle)
	var target := Vector2(392, 88)
	var gun := Vector2(328, 160)
	_ship(gun, -0.9, UNE)
	if c < 1.4:
		if fmod(c, 0.25) < 0.12:
			draw_line(gun, target, Color(1.0, 0.85, 0.4, 0.9), 2.0)
		_rock(target + Vector2(randf_range(-1, 1), randf_range(-1, 1)) * (c / 1.4) * 2.0, 15.0, ALLOY, 2.0)
	elif c < 2.6:
		var k := (c - 1.4) / 1.2
		draw_arc(target, 8.0 + k * 30.0, 0.0, TAU, 24, Color(1.0, 0.6, 0.2, 1.0 - k), 3.0)
		_rise_text("+¢1", target + Vector2(-18, -10), k, CASH)
		_alloy_icon(target + Vector2(22, 4 - k * 10.0), 6.0)
		draw_line(target + Vector2(14, -4 - k * 10.0), target + Vector2(30, 12 - k * 10.0), BAD, 2.5)
		_text("GONE", target + Vector2(36, 10 - k * 10.0), 12, BAD)
	else:
		# A replacement drifts in from the edge.
		var k := (c - 2.6) / 1.4
		_rock(Vector2(480, 30).lerp(target, ease(k, 0.4)), 15.0, ALLOY, 2.0)
	_caption("SHOOT IT", Vector2(386, 178), BAD)
	_caption("¢1, THEN WAIT", Vector2(386, 18), MUTED, 12)


# --- page 2: asteroid fields ---------------------------------------------------------

func _page_fields() -> void:
	var c := fposmod(_t, 6.0)
	var centre := Vector2(130, 96)
	# The field: a dashed boundary packed with rocks.
	_dashed_circle(centre, 82.0, Color(0.8, 0.7, 0.5, 0.35), 0.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var rocks: Array = []
	for i: int in 14:
		var a := rng.randf() * TAU
		var r := sqrt(rng.randf()) * 74.0
		rocks.append(centre + Vector2(cos(a), sin(a)) * r)
	# A Starbase drops into the middle and its orbit sweeps out over most of the field.
	var grow := clampf((c - 0.4) / 1.4, 0.0, 1.0)
	var orbit := 62.0 * ease(grow, 0.4)
	var mined := 0
	for i: int in rocks.size():
		var p: Vector2 = rocks[i]
		var inside := p.distance_to(centre) <= orbit and grow > 0.0
		if inside:
			mined += 1
		_rock(p, 6.0 + float(i % 3) * 2.0, ALLOY if i % 3 != 2 else GAS, float(i))
		if inside:
			draw_arc(p, 11.0, 0.0, TAU, 16, Color(GAS, 0.55), 1.5)
	if grow > 0.0:
		_orbit(centre, orbit)
		_starbase(centre)
	_caption("ONE STARBASE ORBIT", Vector2(130, 14), MUTED, 12)
	_caption("%d ROCKS MINED" % mined, Vector2(130, 184), GAS)
	draw_line(Vector2(262, 14), Vector2(262, 176), Color(1, 1, 1, 0.12), 1.0)
	# Right: the Kharkiv boosting toward a field, and the boost cutting out at the edge.
	var edge := Vector2(400, 70)
	_dashed_circle(edge + Vector2(48, 0), 40.0, Color(0.8, 0.7, 0.5, 0.35), 0.0)
	for i: int in 4:
		_rock(edge + Vector2(40 + (i % 2) * 18, -16 + i * 11), 5.0, ROCK, float(i))
	var k := fposmod(_t, 3.0) / 3.0
	var ship := Vector2(282, 70).lerp(edge + Vector2(18, 0), k)
	var in_field := ship.x > edge.x
	if not in_field:
		draw_line(ship - Vector2(10, 0), ship - Vector2(30 + sin(_t * 30.0) * 4.0, 0), Color(0.5, 0.8, 1.0, 0.9), 4.0)
	_ship(ship, 0.0, UNE)
	if in_field:
		_text("NO BOOST", ship + Vector2(-36, -16), 13, BAD)
	_caption("NO BOOSTING IN FIELDS", Vector2(366, 112), MUTED, 12)
	# Asteroid Field systems: what you break stays broken.
	var b := fposmod(_t, 3.0)
	var spot := Vector2(366, 148)
	if b < 1.2:
		_rock(spot, 11.0, ALLOY, 5.0)
	elif b < 1.8:
		var e := (b - 1.2) / 0.6
		draw_arc(spot, 6.0 + e * 20.0, 0.0, TAU, 20, Color(1.0, 0.6, 0.2, 1.0 - e), 3.0)
	else:
		_dashed_circle(spot, 11.0, Color(1, 1, 1, 0.3), 0.0)
	_caption("FIELD SYSTEMS: GONE FOR GOOD", Vector2(366, 182), BAD, 11)


# --- page 3: colonization ------------------------------------------------------------

func _page_colonize() -> void:
	var c := fposmod(_t, 9.0)
	var earth := Vector2(62, 92)
	var world := Vector2(392, 92)
	var pops := 1 if c < 1.4 else (2 if c < 4.2 else 1)
	_planet(earth, 26.0, Color("3a7bd5"), Color("4caf6a"))
	_pops(earth + Vector2(0, 42), pops)
	if c >= 1.4 and c < 2.6:
		_rise_text("UNLOCKED", earth + Vector2(0, -40), (c - 1.4) / 1.2, GOLD)
	# The empty world, with its rocket button above.
	var settled := c > 7.6
	_planet(world, 22.0, Color("6a8f5a") if not settled else Color("3a7bd5"), Color("c9b27a") if not settled else Color("4caf6a"))
	var button := world + Vector2(0, -44)
	var locked := c < 1.4
	draw_circle(button, 13.0, INK)
	draw_arc(button, 13.0, 0.0, TAU, 20, GOLD if not locked else MUTED, 2.0)
	_rocket(button, 0.8, GOLD if not locked else MUTED)
	if locked:
		_text("2 POPS", button + Vector2(-22, -18), 11, MUTED)
	# The Kharkiv flies into the button.
	var fly := clampf((c - 2.0) / 1.6, 0.0, 1.0)
	var kh := Vector2(220, 30).lerp(button, ease(fly, 0.5))
	if c < 4.2:
		_ship(kh, kh.angle_to_point(button) if fly < 1.0 else 0.0, CREAM)
	if c >= 3.6 and c < 4.2:
		draw_arc(button, 13.0 + (c - 3.6) * 40.0, 0.0, TAU, 20, Color(GOLD, 1.0 - (c - 3.6) / 0.6), 3.0)
	# The slow Colony Ship crawls over, then settles.
	if c >= 4.2 and c < 6.6:
		var k := (c - 4.2) / 2.4
		var cs := (earth + Vector2(30, 0)).lerp(world - Vector2(28, 0), k)
		draw_rect(Rect2(cs - Vector2(8, 5), Vector2(16, 10)), Color("c9d2d8"))
		draw_circle(cs + Vector2(2, 0), 2.5, GAS)
		_text("SLOW...", cs + Vector2(-20, -10), 11, MUTED)
	if c >= 6.6 and c <= 7.6:
		var k := (c - 6.6) / 1.0
		draw_arc(world, 30.0, -PI / 2.0, -PI / 2.0 + TAU * k, 32, GAS, 4.0)
		_text("SETTLING %d%%" % int(k * 100.0), world + Vector2(-34, 44), 11, GAS)
	if settled:
		_rise_text("COLONIZED", world + Vector2(0, 46), minf(1.0, (c - 7.6) / 1.4) * 0.4, GAS)
	# What it costs.
	var chips := ["STARBASE THERE", "1 POP", "%d ALLOYS" % GD.colony_alloys(), "¢%d" % GD.COLONY_CREDITS]
	var x := 128.0
	for chip in chips:
		var w := _font.get_string_size(String(chip), HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x + 12.0
		draw_rect(Rect2(Vector2(x, 168), Vector2(w, 18)), Color(1, 1, 1, 0.06))
		draw_rect(Rect2(Vector2(x, 168), Vector2(w, 18)), Color(GOLD, 0.5), false, 1.0)
		_text(String(chip), Vector2(x + 6, 181), 11, CREAM)
		x += w + 6.0


# --- page 4: growth rewards ----------------------------------------------------------

func _page_growth() -> void:
	var step := 0.45     # one "day" in the demo
	var loop := 12.0
	var c := fposmod(_t, loop)
	# Work out pops and the growth bar from the steps so far.
	var steps := int(c / step)
	var pops := 1
	var progress := steps
	var records: Array = []   # times a new record (even pop) was reached
	var used := 0
	while pops < 4 and progress >= GD.growth_needed(pops):
		progress -= GD.growth_needed(pops)
		used += GD.growth_needed(pops)
		pops += 1
		if pops % 2 == 0:
			records.append(float(used) * step)
	var need := GD.growth_needed(pops)
	var planet := Vector2(96, 96)
	_planet(planet, 30.0, Color("3a7bd5"), Color("4caf6a"))
	_pops(planet + Vector2(0, 46), pops)
	# Growth bar: one segment per step the next pop needs.
	var bar := Rect2(Vector2(36, 162), Vector2(120, 10))
	var seg := bar.size.x / float(need)
	for i: int in need:
		var r := Rect2(bar.position + Vector2(seg * i + 1, 0), Vector2(seg - 2, bar.size.y))
		draw_rect(r, GAS if i < progress else Color(1, 1, 1, 0.1))
	_text("NEXT POP: %d STEPS" % need, Vector2(36, 188), 11, MUTED)
	_caption("+1 STEP EVERY DAY", Vector2(96, 18), MUTED, 12)
	# Each new record: a gold bubble, the Flagship grabs it, a Planet card flips out.
	var kh_home := Vector2(250, 40)
	var kh := kh_home
	for rt in records:
		var since := c - float(rt)
		var bubble := planet + Vector2(44, -30)
		if since < 1.0:
			var pulse := 1.0 + sin(_t * 8.0) * 0.08
			draw_circle(bubble, 14.0 * pulse, Color(GOLD, 0.35))
			draw_arc(bubble, 14.0 * pulse, 0.0, TAU, 24, GOLD, 2.0)
			_text("NEW HIGH!", bubble + Vector2(-26, -20), 11, GOLD)
			kh = kh_home.lerp(bubble, ease(clampf(since / 1.0, 0.0, 1.0), 0.5))
		elif since < 2.6:
			var k := clampf((since - 1.0) / 0.5, 0.0, 1.0)
			_card(Vector2(330, 96), k, since)
			kh = bubble.lerp(kh_home, clampf((since - 1.0) / 1.2, 0.0, 1.0))
	_ship(kh, PI, CREAM)
	_caption("EVERY 2ND/3RD POP (NEW HIGH)", Vector2(370, 18), GOLD, 12)
	_caption("FLY IN, PICK A PLANET CARD", Vector2(370, 184), MUTED, 11)


# --- little drawing helpers ----------------------------------------------------------

func _rock(at: Vector2, r: float, fleck: Color, seed_value: float) -> void:
	var pts := PackedVector2Array()
	for i: int in 7:
		var a := TAU * float(i) / 7.0 + _t * 0.3 + seed_value
		var wobble := 0.78 + 0.22 * sin(seed_value * 3.1 + float(i) * 1.7)
		pts.append(at + Vector2(cos(a), sin(a)) * r * wobble)
	draw_colored_polygon(pts, ROCK)
	pts.append(pts[0])
	draw_polyline(pts, Color("3b352e"), 1.5)
	draw_circle(at + Vector2(r * 0.2, -r * 0.15), maxf(1.5, r * 0.18), fleck)
	draw_circle(at + Vector2(-r * 0.3, r * 0.2), maxf(1.2, r * 0.13), fleck)


func _starbase(at: Vector2) -> void:
	var hexagon := PackedVector2Array()
	for i: int in 6:
		var a := TAU * float(i) / 6.0
		hexagon.append(at + Vector2(cos(a), sin(a)) * 11.0)
	draw_colored_polygon(hexagon, Color("4a5868"))
	hexagon.append(hexagon[0])
	draw_polyline(hexagon, UNE, 2.0)
	draw_circle(at, 4.0, GOLD)


func _orbit(at: Vector2, r: float) -> void:
	draw_circle(at, r, Color(GAS, 0.05))
	_dashed_circle(at, r, Color(GAS, 0.55), _t * 0.3)


func _dashed_circle(at: Vector2, r: float, colour: Color, turn: float) -> void:
	var dashes := maxi(8, int(r / 4.0))
	for i: int in dashes:
		var a := turn + TAU * float(i) / float(dashes)
		draw_arc(at, r, a, a + TAU / float(dashes) * 0.55, 4, colour, 1.5)


func _planet(at: Vector2, r: float, sea: Color, land: Color) -> void:
	draw_circle(at, r + 4.0, Color(sea, 0.15))
	draw_circle(at, r, sea)
	draw_circle(at + Vector2(-r * 0.3, -r * 0.2), r * 0.35, land)
	draw_circle(at + Vector2(r * 0.35, r * 0.3), r * 0.25, land)
	draw_arc(at, r, PI * 0.1, PI * 1.1, 20, Color(0, 0, 0, 0.35), r * 0.35)


func _ship(at: Vector2, angle: float, colour: Color) -> void:
	var nose := Vector2(cos(angle), sin(angle))
	var side := nose.orthogonal()
	draw_colored_polygon(PackedVector2Array([at + nose * 11.0, at - nose * 8.0 + side * 6.0, at - nose * 5.0, at - nose * 8.0 - side * 6.0]), colour)


func _rocket(at: Vector2, k: float, colour: Color) -> void:
	draw_colored_polygon(PackedVector2Array([at + Vector2(0, -9) * k, at + Vector2(5, 5) * k, at + Vector2(-5, 5) * k]), colour)
	draw_line(at + Vector2(0, 6) * k, at + Vector2(0, 10) * k, Color(1.0, 0.5, 0.2), 2.0)


func _alloy_icon(at: Vector2, r: float) -> void:
	draw_colored_polygon(PackedVector2Array([at + Vector2(0, -r), at + Vector2(r, 0), at + Vector2(0, r), at + Vector2(-r, 0)]), ALLOY)


func _gas_icon(at: Vector2, r: float) -> void:
	draw_circle(at, r, GAS)
	draw_circle(at + Vector2(-r * 0.3, -r * 0.3), r * 0.35, Color(1, 1, 1, 0.5))


func _pops(at: Vector2, count: int) -> void:
	var gap := 12.0
	var x0 := at.x - gap * float(count - 1) / 2.0
	for i: int in count:
		var p := Vector2(x0 + gap * i, at.y)
		draw_circle(p + Vector2(0, -4), 3.0, CREAM)
		draw_rect(Rect2(p + Vector2(-3, 0), Vector2(6, 5)), CREAM)
	_text("%d POP%s" % [count, "" if count == 1 else "S"], at + Vector2(20 + gap * float(count - 1) / 2.0, 4), 11, CREAM)


func _card(at: Vector2, k: float, since: float) -> void:
	var w := 64.0 * k
	var h := 88.0
	var r := Rect2(at - Vector2(w / 2.0, h / 2.0), Vector2(w, h))
	draw_rect(r, Color("1a1408"))
	draw_rect(r, GOLD, false, 2.0)
	if k > 0.8:
		draw_rect(Rect2(r.position + Vector2(6, 8), Vector2(w - 12, 34)), Color("3a7bd5"))
		_text("PLANET", r.position + Vector2(9, 60), 11, GOLD)
		_text("CARD", r.position + Vector2(15, 74), 11, GOLD)
		draw_arc(at, 50.0 + sin(since * 6.0) * 3.0, 0.0, TAU, 32, Color(GOLD, 0.25), 2.0)


func _text(text: String, at: Vector2, fs: int, colour: Color) -> void:
	draw_string(_font, at + Vector2(1, 1), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0, 0, 0, 0.7))
	draw_string(_font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, colour)


## Centred caption text.
func _caption(text: String, at: Vector2, colour: Color, fs: int = 13) -> void:
	var w := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	_text(text, at - Vector2(w / 2.0, 0), fs, colour)


## Text that floats up and fades out as k goes 0 to 1.
func _rise_text(text: String, at: Vector2, k: float, colour: Color) -> void:
	var w := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
	var c := colour
	c.a = 1.0 - clampf(k, 0.0, 1.0) * 0.8
	_text(text, at - Vector2(w / 2.0, k * 14.0), 13, c)
