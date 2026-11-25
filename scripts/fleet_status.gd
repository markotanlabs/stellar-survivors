extends Control
## Fleet status (prototype): your fleet as wireframe silhouettes in the bottom-right
## corner, StarCraft style. Each ship shades from green to yellow to red as it takes
## damage, flashes white when hit, and pulses when it's nearly gone. A lost ship
## reads OFFLINE and flickers out. 12 ships to a page; arrows page through the rest.

const GD = preload("res://scripts/game_data.gd")
const Sfx = preload("res://scripts/sfx.gd")

const COLS := 4
const ROWS := 3
const PER_PAGE := COLS * ROWS
const CELL := Vector2(62, 54)
const GAP := 6.0
const PAD := 10.0
const HEADER := 26.0
const OFFLINE_TIME := 2.4    # seconds an OFFLINE slot flickers before it's gone

const GREEN := Color("3dd17a")
const YELLOW := Color("e8c547")
const RED := Color("e5484d")

const ShipInfo = preload("res://scripts/ship_info.gd")

var _entries: Array = []     # [{ship, type, frac, flash, offline (-1 or seconds since), seen}]
var _page := 0
var _seen := 0
var _time := 0.0
var _prev: Button
var _next: Button
var _main: Node = null
var _slots: Array = []        # [[Rect2, entry]] drawn this frame, for hovering
var _hover: Object = null     # the ship under the mouse
var _tip: Control = null
var _tip_age := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	anchor_left = 1.0
	anchor_right = 1.0
	anchor_top = 1.0
	anchor_bottom = 1.0
	var w := COLS * CELL.x + (COLS - 1) * GAP + PAD * 2.0
	var h := HEADER + ROWS * CELL.y + (ROWS - 1) * GAP + PAD * 2.0
	offset_left = -w - 16.0
	offset_right = -16.0
	offset_top = -h - 16.0
	offset_bottom = -16.0
	_prev = _pager_button("<", -1)
	_next = _pager_button(">", 1)


func _pager_button(text: String, step: int) -> Button:
	var b := Button.new()
	b.text = text
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 16)
	b.add_theme_color_override("font_color", Color("8fb4e3"))
	b.add_theme_color_override("font_hover_color", Color("f4efe2"))
	b.size = Vector2(26, 22)
	b.visible = false
	add_child(b)
	b.pressed.connect(func() -> void:
		_page = clampi(_page + step, 0, maxi(0, _pages() - 1))
		Sfx.ui("click")
		queue_redraw())
	return b


func _find_main() -> Node:
	var n := get_parent()
	while n != null:
		if n.get("fleet") is Array:
			return n
		n = n.get_parent()
	return null


func _process(delta: float) -> void:
	_time += delta
	if _main == null or not is_instance_valid(_main):
		_main = _find_main()
		if _main == null:
			return
	var fleet: Array = _main.get("fleet")
	# New ships join the board.
	for ship in fleet:
		if not is_instance_valid(ship) or String(ship.get("type_id")) == "fighter":
			continue
		var known := false
		for e in _entries:
			if is_same(e["ship"], ship):
				known = true
				break
		if not known:
			_seen += 1
			_entries.append({"ship": ship, "type": String(ship.get("type_id")), "frac": _health(ship), "flash": 0.0, "offline": -1.0, "seen": _seen})
	# Update health; lost ships go OFFLINE, ships that just left the fleet slip away.
	for e in _entries.duplicate():
		var ship = e["ship"]
		if float(e["offline"]) >= 0.0:
			e["offline"] = float(e["offline"]) + delta
			if float(e["offline"]) >= OFFLINE_TIME:
				_entries.erase(e)
			continue
		if not is_instance_valid(ship) or ship.get("alive") != true:
			e["offline"] = 0.0
			e["frac"] = 0.0
			Sfx.ui("blip")
			continue
		if not fleet.has(ship):
			_entries.erase(e)
			continue
		var f := _health(ship)
		if f < float(e["frac"]) - 0.001:
			e["flash"] = 0.15
		e["frac"] = f
		e["flash"] = maxf(0.0, float(e["flash"]) - delta)
	_entries.sort_custom(_before)
	_page = clampi(_page, 0, maxi(0, _pages() - 1))
	queue_redraw()
	_update_tip(delta)


## Hovering a ship: a small card with its weapons, a description and live health.
func _update_tip(delta: float) -> void:
	var stale := _hover != null and not is_instance_valid(_hover)
	if stale:
		_hover = null
	var mouse := get_local_mouse_position()
	var found: Object = null
	var at := Rect2()
	if visible:
		for pair in _slots:
			var r: Rect2 = pair[0]
			var e: Dictionary = pair[1]
			if r.has_point(mouse) and float(e["offline"]) < 0.0 and is_instance_valid(e["ship"]):
				found = e["ship"]
				at = r
				break
	_tip_age += delta
	if stale or found != _hover or (found != null and _tip_age > 0.5):
		_hover = found
		_tip_age = 0.0
		if _tip != null:
			_tip.queue_free()
			_tip = null
		if found != null:
			_tip = ShipInfo.Card.new(String(found.get("type_id")), found as Node, false)
			add_child(_tip)
			var tip_size := _tip.get_combined_minimum_size()
			_tip.position = Vector2(-tip_size.x - 10.0, clampf(at.position.y + at.size.y - tip_size.y, -size.y * 3.0, size.y - tip_size.y))


## Kharkiv first, then the biggest ships, then in the order they joined.
func _before(a: Dictionary, b: Dictionary) -> bool:
	var ta := _rank(String(a["type"]))
	var tb := _rank(String(b["type"]))
	if ta != tb:
		return ta > tb
	return int(a["seen"]) < int(b["seen"])


func _rank(type_id: String) -> int:
	if type_id == "capital":
		return 100
	if GD.SHIPS.has(type_id):
		return int(GD.SHIPS[type_id]["tier"])
	return 0


func _health(ship: Node) -> float:
	var top := float(ship.get("max_hull")) + float(ship.get("max_armor")) + float(ship.get("max_shields"))
	var now := float(ship.get("hull")) + float(ship.get("armor")) + float(ship.get("shields"))
	return clampf(now / maxf(top, 1.0), 0.0, 1.0)


func _pages() -> int:
	return int(ceil(float(_entries.size()) / float(PER_PAGE)))


func _colour(frac: float) -> Color:
	if frac >= 0.5:
		return YELLOW.lerp(GREEN, (frac - 0.5) / 0.5)
	return RED.lerp(YELLOW, frac / 0.5)


func _draw() -> void:
	if _entries.is_empty():
		_slots.clear()
		_prev.visible = false
		_next.visible = false
		return
	var font := ThemeDB.fallback_font
	var start := _page * PER_PAGE
	var shown := mini(PER_PAGE, _entries.size() - start)
	var rows := int(ceil(float(shown) / float(COLS)))
	var grid_h := rows * CELL.y + (rows - 1) * GAP
	var panel_h := HEADER + grid_h + PAD * 2.0
	var panel := Rect2(Vector2(0, size.y - panel_h), Vector2(size.x, panel_h))
	draw_rect(panel, Color(0.03, 0.05, 0.07, 0.82))
	draw_rect(panel, Color("22303a"), false, 2.0)
	# Header: the count, and page arrows when the fleet doesn't fit.
	var alive := 0
	for e in _entries:
		if float(e["offline"]) < 0.0:
			alive += 1
	var head := panel.position + Vector2(PAD, PAD + 13.0)
	draw_string(font, head, "FLEET  %d" % alive, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("8fb4e3"))
	var pages := _pages()
	_prev.visible = pages > 1
	_next.visible = pages > 1
	if pages > 1:
		var page_text := "%d/%d" % [_page + 1, pages]
		var right := panel.end.x - PAD
		_next.position = Vector2(right - 26.0, panel.position.y + PAD - 4.0)
		var tw := font.get_string_size(page_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
		draw_string(font, Vector2(_next.position.x - tw - 4.0, head.y), page_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("aeb9c6"))
		_prev.position = Vector2(_next.position.x - tw - 34.0, _next.position.y)
	var origin := panel.position + Vector2(PAD, PAD + HEADER)
	_slots.clear()
	for i: int in shown:
		var e: Dictionary = _entries[start + i]
		var col := i % COLS
		var row := floori(float(i) / COLS)
		var cell := Rect2(origin + Vector2(col * (CELL.x + GAP), row * (CELL.y + GAP)), CELL)
		_slots.append([cell, e])
		_draw_slot(cell, e, font)


func _draw_slot(cell: Rect2, e: Dictionary, font: Font) -> void:
	var type_id := String(e["type"])
	var offline := float(e["offline"])
	var frac := float(e["frac"])
	var is_flagship := type_id == "capital"
	draw_rect(cell, Color(0.0, 0.0, 0.0, 0.45))
	draw_rect(cell, Color("e8c547") if is_flagship else Color("2a3846"), false, 1.0)
	var colour := _colour(frac)
	var alpha := 1.0
	if offline >= 0.0:
		# Going offline: red, stuttering, then dark.
		colour = RED
		var fade := offline / OFFLINE_TIME
		alpha = 0.0 if randf() < 0.25 + 0.7 * fade else (1.0 - fade * 0.6)
	elif frac < 0.25:
		alpha = 0.55 + 0.45 * sin(_time * 10.0)   # critical: it pulses
	if float(e["flash"]) > 0.0:
		colour = Color.WHITE
	var centre := cell.get_center() + Vector2(0, -3)
	var sc := minf(cell.size.x, cell.size.y) * 0.42 * float(ShipInfo.SIZES.get(type_id, 0.6))
	var pts := PackedVector2Array()
	for p in ShipInfo.SHAPES.get(type_id, ShipInfo.SHAPES["colony"]):
		pts.append(centre + Vector2(float(p[0]), float(p[1])) * sc)
	if alpha > 0.0:
		draw_colored_polygon(pts, Color(colour, 0.22 * alpha))
		var outline := pts.duplicate()
		outline.append(pts[0])
		draw_polyline(outline, Color(colour, alpha), 1.5)
		# A spine and a cross-brace, for the wireframe look.
		draw_line(centre + Vector2(0, -0.8) * sc, centre + Vector2(0, 0.8) * sc, Color(colour, 0.6 * alpha), 1.0)
		draw_line(centre + Vector2(-0.3, 0.2) * sc, centre + Vector2(0.3, 0.2) * sc, Color(colour, 0.5 * alpha), 1.0)
	# Scanlines over the slot.
	var y := cell.position.y + 1.0
	while y < cell.end.y:
		draw_line(Vector2(cell.position.x + 1.0, y), Vector2(cell.end.x - 1.0, y), Color(0.0, 0.0, 0.0, 0.18), 1.0)
		y += 3.0
	if offline >= 0.0:
		if randf() > offline / OFFLINE_TIME * 0.8:
			var text := "OFFLINE"
			var tw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
			draw_string(font, Vector2(cell.get_center().x - tw / 2.0, cell.end.y - 6.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, RED)
		# Static: a few broken lines across the slot.
		for k: int in 3:
			var sy := cell.position.y + randf() * cell.size.y
			draw_line(Vector2(cell.position.x + 2.0, sy), Vector2(cell.end.x - 2.0, sy), Color(1.0, 0.35, 0.3, 0.25 * (1.0 - offline / OFFLINE_TIME)), 1.0)
	else:
		var code := String(GD.SHIPS[type_id]["code"]) if GD.SHIPS.has(type_id) else ""
		draw_string(font, cell.position + Vector2(4, cell.size.y - 4), code, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(colour, 0.85))
