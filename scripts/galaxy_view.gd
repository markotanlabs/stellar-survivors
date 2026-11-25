extends Node2D
## Galaxy view: the systems of the tutorial map and the warplanes between them.
## Click a system to open it.

signal system_clicked(index: int)
signal flagship_clicked

const GD = preload("res://scripts/game_data.gd")
const ResIcon = preload("res://scripts/res_icon.gd")
const SCALE := 2.0
const NODE_RADIUS := 34.0

var systems: Array = []
var links: Array = []
var current := 1
var show_fleet := false
var flagship_system := -1   # where the Flagship is (an icon by that system)
var visited := {}        # system index -> true once explored
var fleet_pos := Vector2.ZERO     # in this node's coordinates
var fleet_angle := 0.0
var _font: Font


func setup(new_systems: Array, new_links: Array) -> void:
	systems = new_systems
	links = new_links
	_font = ThemeDB.fallback_font
	queue_redraw()


## Centre of the map, in this node's coordinates.
func centre() -> Vector2:
	var total := Vector2.ZERO
	for s in systems:
		var p: Vector2 = s["galaxy_pos"]
		total += p * SCALE
	return total / max(1, systems.size())


func _unhandled_input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	var click := event as InputEventMouseButton
	if click == null or not click.pressed or click.button_index != MOUSE_BUTTON_LEFT:
		return
	var mouse := get_global_mouse_position()
	# The Flagship marker: click it to take the helm (Fleet Mode).
	if not show_fleet and flagship_system >= 0 and mouse.distance_to(_flagship_marker_pos()) < 46.0:
		flagship_clicked.emit()
		get_viewport().set_input_as_handled()
		return
	for s in systems:
		var p: Vector2 = s["galaxy_pos"]
		if mouse.distance_to(p * SCALE) < NODE_RADIUS + 6.0:
			system_clicked.emit(s["index"])
			get_viewport().set_input_as_handled()
			return


const GREEN := Color("3dd17a")      # warp lanes, as on the system map's warp exits
const GOLD := Color("e8c547")
const CREAM := Color("f4efe2")
const MUTED := Color("93a3ad")
const GLASS := Color(0.05, 0.075, 0.11, 0.95)   # the build menu's dark navy glass
const EDGE := Color("2a3a4a")
const GRID := Color(0.37, 0.81, 0.75, 0.05)     # the build menu's tactical grid


func _draw() -> void:
	# In the game's UI language (v0.9.199): tactical grid and corner brackets, marching
	# green warp lanes, dark glass system discs with faction rings, and pill labels like
	# the planet banners.
	var t := Time.get_ticks_msec() / 1000.0
	_draw_backdrop()
	_draw_lanes(t)
	_draw_systems(t)
	if not show_fleet and flagship_system >= 0 and flagship_system < systems.size():
		# The Flagship marker: big, glowing, above its system. Click it for Fleet Mode.
		var at := _flagship_marker_pos()
		var pulse := 0.5 + 0.5 * sin(t * 3.0)
		at.y += sin(t * 2.0) * 3.0
		var hot := get_global_mouse_position().distance_to(at) < 46.0
		for i in 4:
			draw_circle(at, 30.0 + i * 9.0 + 6.0 * pulse, Color(0.45, 0.66, 0.95, (0.16 - i * 0.035) * (0.6 + 0.4 * pulse)))
		draw_circle(at, 26.0, GLASS)
		draw_arc(at, 26.0, 0.0, TAU, 48, GOLD if hot else Color(0.56, 0.71, 0.89, 0.6 + 0.4 * pulse), 2.5, true)
		var tip := at + Vector2(0, -20)
		var back := at + Vector2(0, 13)
		var side := Vector2(13, 0)
		draw_colored_polygon(PackedVector2Array([tip, back + side, at + Vector2(0, 6), back - side]), Color("3e6fb0"))
		draw_polyline(PackedVector2Array([tip, back + side, at + Vector2(0, 6), back - side, tip]), CREAM, 2.5, true)
		var label := "FLAGSHIP  ·  CLICK FOR FLEET MODE"
		var lw := _font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
		_pill(Rect2(at.x - lw / 2.0 - 14.0, at.y - 72.0, lw + 28.0, 28.0), Color("c9a55a") if not hot else Color("f0d27a"), Color(), 2)
		draw_string(_font, Vector2(at.x - lw / 2.0, at.y - 53.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("f0d27a"))
	if show_fleet:
		var tip := fleet_pos + Vector2.RIGHT.rotated(fleet_angle) * 22.0
		var side := Vector2.RIGHT.rotated(fleet_angle).orthogonal() * 12.0
		var back := fleet_pos - Vector2.RIGHT.rotated(fleet_angle) * 12.0
		draw_line(back - Vector2.RIGHT.rotated(fleet_angle) * 60.0, back, Color(0.56, 0.71, 0.89, 0.6), 6.0, true)
		draw_colored_polygon(PackedVector2Array([tip, back + side, back - side]), Color("3e6fb0"))
		draw_polyline(PackedVector2Array([tip, back + side, back - side, tip]), CREAM, 3.0, true)


## Above the Flagship's system, clear of the wave tag.
func _flagship_marker_pos() -> Vector2:
	var p: Vector2 = systems[flagship_system]["galaxy_pos"]
	return p * SCALE + Vector2(0, -NODE_RADIUS - 70.0)


## Map bounds, padded: the tactical grid fills it, gold brackets mark its corners.
func _bounds() -> Rect2:
	if systems.is_empty():
		return Rect2()
	var r := Rect2(Vector2(systems[0]["galaxy_pos"]) * SCALE, Vector2.ZERO)
	for s in systems:
		r = r.expand(Vector2(s["galaxy_pos"]) * SCALE)
	return r.grow_individual(200.0, 220.0, 200.0, 200.0)


func _draw_backdrop() -> void:
	var r := _bounds()
	if r.size == Vector2.ZERO:
		return
	draw_rect(r, Color(0.02, 0.03, 0.05, 0.35))
	var step := 48.0
	var x := r.position.x
	while x <= r.end.x:
		draw_line(Vector2(x, r.position.y), Vector2(x, r.end.y), GRID, 1.0)
		x += step
	var y := r.position.y
	while y <= r.end.y:
		draw_line(Vector2(r.position.x, y), Vector2(r.end.x, y), GRID, 1.0)
		y += step
	var arm := 46.0
	var c := Color("c9a55a")
	for corner in [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]:
		var cv: Vector2 = corner
		var sx := 1.0 if cv.x <= r.position.x + 1.0 else -1.0
		var sy := 1.0 if cv.y <= r.position.y + 1.0 else -1.0
		draw_polyline(PackedVector2Array([cv + Vector2(0, arm * sy), cv, cv + Vector2(arm * sx, 0)]), c, 3.0, true)
	# Title plate, top left, like a panel header.
	var title := "GALAXY MAP"
	draw_string(_font, r.position + Vector2(22, 40), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, GOLD)
	var tw := _font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x
	draw_line(r.position + Vector2(22, 50), r.position + Vector2(22 + tw, 50), Color(GOLD, 0.5), 2.0)
	draw_string(_font, r.position + Vector2(22, 74), "Click a system to view it  ·  TAB to close", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, MUTED)


func _draw_lanes(t: float) -> void:
	for link in links:
		var pa: Vector2 = Vector2(systems[link[0]]["galaxy_pos"]) * SCALE
		var pb: Vector2 = Vector2(systems[link[1]]["galaxy_pos"]) * SCALE
		var dir := (pb - pa).normalized()
		var a := pa + dir * (NODE_RADIUS + 10.0)
		var b := pb - dir * (NODE_RADIUS + 10.0)
		var length := a.distance_to(b)
		var near := int(link[0]) == current or int(link[1]) == current
		var strength := 1.0 if near else 0.55
		draw_line(a, b, Color(GREEN, 0.07 * strength), 12.0, true)
		# Dashes marching away from where you are (or one way, for far lanes).
		var from := a
		var way := dir
		if int(link[1]) == current:
			from = b
			way = -dir
		var dash := 14.0
		var s := fmod(t * 22.0, dash * 2.0)
		while s < length:
			var p0 := from + way * s
			var p1 := from + way * minf(s + dash, length)
			draw_line(p0, p1, Color(GREEN, 0.75 * strength), 3.0, true)
			s += dash * 2.0


func _draw_systems(t: float) -> void:
	var mouse := get_global_mouse_position()
	for s in systems:
		var p: Vector2 = s["galaxy_pos"]
		var faction: int = s["faction"]
		var c := p * SCALE
		var ring := GD.ring_colour(faction)
		var explored := bool(visited.get(int(s["index"]), false))
		var hot := mouse.distance_to(c) < NODE_RADIUS + 6.0
		if not explored:
			ring = ring.darkened(0.45)
		# Disc: a soft faction glow, dark glass, a crisp ring and a tick scale.
		for i in 3:
			draw_circle(c, NODE_RADIUS + 6.0 + i * 7.0, Color(ring, 0.07 - i * 0.02))
		draw_circle(c, NODE_RADIUS, GLASS if faction != GD.Faction.SONS else Color(0.06, 0.05, 0.04, 0.95))
		draw_arc(c, NODE_RADIUS, 0.0, TAU, 64, ring, 4.0, true)
		draw_arc(c, NODE_RADIUS - 7.0, 0.0, TAU, 48, Color(ring, 0.25), 1.0, true)
		for i in 24:
			var ang := TAU * i / 24.0
			var tick := 5.0 if i % 6 == 0 else 2.5
			var dirv := Vector2.from_angle(ang)
			draw_line(c + dirv * (NODE_RADIUS + 4.0), c + dirv * (NODE_RADIUS + 4.0 + tick), Color(ring, 0.5), 1.0, true)
		if s["index"] == current:
			# You are here: four gold brackets turning slowly.
			for i in 4:
				var a0 := t * 0.6 + i * TAU / 4.0
				draw_arc(c, NODE_RADIUS + 16.0, a0, a0 + 0.8, 16, GOLD, 3.0, true)
		if hot:
			draw_arc(c, NODE_RADIUS + 2.0, 0.0, TAU, 64, Color("f0d27a"), 2.0, true)
		var name_text: String = s["name"]
		if not explored:
			var qw := _font.get_string_size("?", HORIZONTAL_ALIGNMENT_LEFT, -1, 30).x
			draw_string(_font, c + Vector2(-qw / 2.0, 11), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, MUTED)
			name_text = "Unexplored"
		# Philip's waves on the move: a red pill over the system they're in.
		var wave_ships := int(GD.sons_waves_at.get(int(s["index"]), 0))
		if wave_ships > 0:
			var wave_tag := "PHILIP'S WAVE  x%d" % wave_ships
			var ww := _font.get_string_size(wave_tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
			var flash := 0.6 + 0.4 * sin(t * 5.0)
			var red := Color(0.9, 0.28, 0.3)
			_pill(Rect2(c.x - ww / 2.0 - 12.0, c.y - NODE_RADIUS - 52.0, ww + 24.0, 26.0), Color(red, flash), Color(), 2)
			draw_string(_font, Vector2(c.x - ww / 2.0, c.y - NODE_RADIUS - 34.0), wave_tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(red.lightened(0.25), flash))
		# Banner under the disc, like a planet's: name with a faction stripe, then tags.
		var title := name_text.to_upper()
		var nw := _font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
		var y := c.y + NODE_RADIUS + 18.0
		_pill(Rect2(c.x - nw / 2.0 - 16.0, y, nw + 32.0, 30.0), EDGE, ring, 1)
		draw_string(_font, Vector2(c.x - nw / 2.0 + 2.0, y + 21.0), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, CREAM if explored else MUTED)
		y += 36.0
		var tag := ""
		var tag_col := Color()
		if faction == GD.Faction.SONS:
			tag = "SONS OF PHILIP"
			tag_col = Color("d9a441")
		elif explored and String(s.get("type", "")) == "asteroid_field":
			tag = "ASTEROID FIELD"
			tag_col = Color("c79bff")
		if tag != "":
			var tgw := _font.get_string_size(tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
			_pill(Rect2(c.x - tgw / 2.0 - 10.0, y, tgw + 20.0, 22.0), Color(tag_col, 0.6), Color(), 1)
			draw_string(_font, Vector2(c.x - tgw / 2.0, y + 16.0), tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, tag_col)
			y += 28.0
		# What the system makes for you each day, with resource icons.
		var daily := GD.daily_text(int(s["index"]))
		if daily != "":
			var dw := ResIcon.text_width(_font, daily, 16)
			_pill(Rect2(c.x - dw / 2.0 - 10.0, y, dw + 20.0, 26.0), Color(GREEN, 0.35), Color(), 1)
			ResIcon.draw_text(self, _font, Vector2(c.x - dw / 2.0, y + 19.0), daily, 16, Color("5be38f"))


## A dark glass pill: thin border, optional coloured stripe on the left (faction).
func _pill(rect: Rect2, border: Color, stripe: Color, border_w: int) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = GLASS
	sb.border_color = border
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(int(minf(rect.size.y * 0.5, 8.0)))
	sb.shadow_color = Color(0, 0, 0, 0.4)
	sb.shadow_size = 4
	draw_style_box(sb, rect)
	if stripe.a > 0.0:
		draw_rect(Rect2(rect.position + Vector2(3, 5), Vector2(4, rect.size.y - 10)), stripe)


func _process(_delta: float) -> void:
	# Philip's wave tags move and pulse, so keep the map fresh while it's open.
	if is_visible_in_tree():
		queue_redraw()   # marching lanes, turning brackets, hover rings
