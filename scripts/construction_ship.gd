extends Node2D
## A Civilian Construction Ship. It launches from a Shipyard, flies (warping if it has to)
## to each placed station ghost in turn, and welds it together. Unarmed, Corvette-tough.

signal destroyed(ship: Node2D)
signal hit(ship: Node2D)

const GD = preload("res://scripts/game_data.gd")
const Explosion = preload("res://scripts/explosion.gd")

var faction := GD.Faction.UNE
var alive := true
var hull := GD.CIVILIAN_HULL
var max_hull := GD.CIVILIAN_HULL
var armor := GD.CIVILIAN_ARMOR
var max_armor := GD.CIVILIAN_ARMOR
var system_index := 0
var legs: Array = []     # {"kind": "exit" | "point", "pos": Vector2 px, "to": int, "entry": Vector2 px}
var views: Array = []
var motion := Vector2.ZERO
var building := false    # welding beam on
var site_pos := Vector2.ZERO

var _velocity := Vector2.ZERO
var _speed := GD.CONSTRUCTION_SPEED * GD.UNIT
var _warp_left := 0.0
var _heading := 0.0
var _time := 0.0
var _font: Font


func setup(new_views: Array, start_system: int, start_px: Vector2) -> void:
	views = new_views
	system_index = start_system
	position = start_px
	_font = ThemeDB.fallback_font


func _ready() -> void:
	add_to_group("targets")
	z_index = 3


## New orders: fly these legs (the last one is where to stop). Mid-jump, the jump it's
## in finishes first: new_legs must then start from the system it's jumping to
## (see route_from()).
func go(new_legs: Array) -> void:
	if _warp_left > 0.0 and not legs.is_empty() and String(legs[0].get("kind", "")) == "exit":
		legs = [legs[0]] + new_legs
	else:
		legs = new_legs
	building = false
	queue_redraw()


## The system new orders should be planned from: where it is, or where it's jumping to.
func route_from() -> int:
	if _warp_left > 0.0 and not legs.is_empty() and legs[0].has("to"):
		return int(legs[0]["to"])
	return system_index


func is_idle_at(system: int, point_px: Vector2) -> bool:
	return legs.is_empty() and _warp_left <= 0.0 and system_index == system and position.distance_to(point_px) < 1.0 * GD.UNIT


func take_damage(amount: float, _attacker: Node2D = null) -> void:
	if not alive:
		return
	var soak := minf(armor, amount)
	armor -= soak
	hull -= amount - soak
	hit.emit(self)
	queue_redraw()
	if hull <= 0.0:
		alive = false
		var boom := Explosion.new()
		get_parent().add_child(boom)
		boom.setup(position, 30.0)
		destroyed.emit(self)
		queue_free()


## Seconds until it reaches the end of its legs (warp transits included).
func eta() -> float:
	var t := 0.0
	var at := position
	var start := 0
	if _warp_left > 0.0 and not legs.is_empty():
		t += _warp_left
		at = legs[0]["entry"]
		start = 1
	for i in range(start, legs.size()):
		var leg: Dictionary = legs[i]
		var pos: Vector2 = leg["pos"]
		t += at.distance_to(pos) / _speed
		if String(leg["kind"]) == "exit":
			t += GD.WARP_TRANSIT
			at = leg["entry"]
		else:
			at = pos
	return t


func _process(delta: float) -> void:
	_time += delta
	if not alive:
		return
	if _warp_left > 0.0:
		_warp_left -= delta
		if _warp_left <= 0.0:
			visible = true   # always come back out of warp, whatever happened to the orders
			var warp_leg: Dictionary = legs.pop_front() if not legs.is_empty() else {}
			if warp_leg.has("to"):
				var to_index := int(warp_leg["to"])
				reparent(views[to_index], false)
				system_index = to_index
				position = warp_leg["entry"]
			queue_redraw()
		return
	if legs.is_empty():
		motion = Vector2.ZERO
		_velocity = Vector2.ZERO
		visible = true   # parked: never left hidden
		if is_visible_in_tree() and (building or Engine.get_process_frames() % 10 == 0):
			queue_redraw()
		return
	var leg: Dictionary = legs[0]
	var target: Vector2 = leg["pos"]
	var to := target - position
	if to.length() < 0.5 * GD.UNIT:
		if String(leg["kind"]) == "exit":
			visible = false
			_warp_left = GD.WARP_TRANSIT
		else:
			legs.pop_front()
		_velocity = Vector2.ZERO
		motion = Vector2.ZERO
		return
	var desired := to.normalized() * minf(_speed, sqrt(2.0 * _speed * 2.0 * to.length()))
	_velocity = _velocity.move_toward(desired, _speed * 2.0 * delta)
	position += _velocity * delta
	motion = _velocity
	if _velocity.length() > 5.0:
		_heading = _velocity.angle()
	queue_redraw()


func _draw() -> void:
	var dir := Vector2.RIGHT.rotated(_heading)
	var side := dir.orthogonal()
	# Welding beam to the station it's building, with sparks.
	if building:
		var tip := site_pos - position
		var flicker := 0.55 + 0.45 * sin(_time * 40.0)
		draw_line(dir * 8.0, tip, Color(1.0, 0.85, 0.45, 0.5 * flicker), 2.0)
		draw_circle(tip, 3.0 + 2.0 * flicker, Color(1.0, 0.92, 0.6, 0.8 * flicker))
		for i in 4:
			var a := _time * 7.0 + i * 1.7
			var spark := tip + Vector2.RIGHT.rotated(a) * fmod(_time * 30.0 + i * 5.0, 12.0)
			draw_circle(spark, 1.2, Color(1.0, 0.8, 0.35, 0.9))
	# A stubby work tug: civilian yellow hull, blue stripe, a crane arm up front.
	var body := PackedVector2Array([dir * 9 + side * 5, -dir * 9 + side * 6, -dir * 9 - side * 6, dir * 9 - side * 5])
	draw_colored_polygon(body, Color("d9a441"))
	draw_line(-dir * 9 + side * 0.0, dir * 9, Color("3e6fb0"), 3.0)
	var outline := body.duplicate()
	outline.append(body[0])
	draw_polyline(outline, Color("0b0e14"), 2.0)
	draw_line(dir * 9 + side * 3, dir * 15 + side * 1, Color("c9ced6"), 2.0)
	draw_line(dir * 15 + side * 1, dir * 17 - side * 2, Color("c9ced6"), 2.0)
	var k := GD.screen_scale(self)
	var total := hull + armor
	if total < max_hull + max_armor:
		var w := 30.0 * k
		draw_rect(Rect2(Vector2(-w / 2.0, 12.0), Vector2(w, 3.0 * k)), Color(0.02, 0.03, 0.05, 0.8))
		draw_rect(Rect2(Vector2(-w / 2.0, 12.0), Vector2(w * total / (max_hull + max_armor), 3.0 * k)), Color("3dd17a"))
	# Full name while Info is held, "CS" only with Abbreviated Ship Names on, else nothing.
	var label := "Construction Ship" if GD.show_full_names else ("CS" if GD.show_abbrev_names else "")
	if label == "":
		return
	var tw := _font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
	draw_set_transform(Vector2(0, -12.0 - 4.0 * k), 0.0, Vector2(k, k))
	draw_string_outline(_font, Vector2(-tw / 2.0, 0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, 4, Color("0b0e14"))
	draw_string(_font, Vector2(-tw / 2.0, 0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("d9a441"))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
