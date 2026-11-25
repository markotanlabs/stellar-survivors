extends Node2D
## A Colony Ship carrying pops from one of your planets to a planet the Kharkiv marked.
## It follows legs like a Hauler (warping between systems), then settles for a while.
## While it's flying, a small back-arrow button beside it turns it around (outside Fleet Mode).

signal arrived(ship: Node2D)
signal returned(ship: Node2D)
signal destroyed(ship: Node2D)
signal cancel_requested(ship: Node2D)
signal hit(ship: Node2D)

const GD = preload("res://scripts/game_data.gd")
const Explosion = preload("res://scripts/explosion.gd")

var faction := GD.Faction.UNE
var alive := true
var hull := GD.CIVILIAN_HULL
var max_hull := GD.CIVILIAN_HULL
var armor := GD.CIVILIAN_ARMOR
var max_armor := GD.CIVILIAN_ARMOR
var pops := 1
var system_index := 0
var legs: Array = []
var views: Array = []
var returning := false
var source_planet: Dictionary = {}
var source_system := 0
var target_planet: Dictionary = {}
var target_system := 0
var motion := Vector2.ZERO

var _velocity := Vector2.ZERO
var _speed := GD.COLONY_SPEED * GD.UNIT
var _warp_left := 0.0
var _heading := 0.0
var _font: Font


func setup(new_views: Array, start_system: int, start_px: Vector2, new_legs: Array) -> void:
	views = new_views
	system_index = start_system
	position = start_px
	legs = new_legs
	_font = ThemeDB.fallback_font


func _ready() -> void:
	add_to_group("targets")


func take_damage(amount: float, _attacker: Node2D = null) -> void:
	if not alive:
		return
	# Civilian: Corvette-tough, armor soaks hits before the hull.
	var soak := minf(armor, amount)
	armor -= soak
	hull -= amount - soak
	hit.emit(self)
	queue_redraw()
	if hull <= 0.0:
		alive = false
		var boom := Explosion.new()
		get_parent().add_child(boom)
		boom.setup(position, 26.0)
		destroyed.emit(self)
		queue_free()


## Turn around and fly home along new legs.
func turn_back(new_legs: Array) -> void:
	returning = true
	legs = new_legs
	_warp_left = 0.0
	visible = true
	queue_redraw()


func _process(delta: float) -> void:
	if not alive or legs.is_empty():
		return
	if _warp_left > 0.0:
		_warp_left -= delta
		if _warp_left <= 0.0:
			var warp_leg: Dictionary = legs.pop_front()
			var to_index := int(warp_leg["to"])
			reparent(views[to_index], false)
			system_index = to_index
			position = warp_leg["entry"]
			visible = true
		return
	var leg: Dictionary = legs[0]
	var target: Vector2 = leg["pos"]
	var to := target - position
	if to.length() < 0.8 * GD.UNIT:
		if String(leg["kind"]) == "planet":
			legs.clear()
			motion = Vector2.ZERO
			if returning:
				returned.emit(self)
			else:
				arrived.emit(self)
		else:
			visible = false
			_warp_left = GD.WARP_TRANSIT
			_velocity = Vector2.ZERO
		return
	var desired := to.normalized() * minf(_speed, sqrt(2.0 * _speed * 2.0 * to.length()))
	_velocity = _velocity.move_toward(desired, _speed * 2.0 * delta)
	position += _velocity * delta
	motion = _velocity
	if _velocity.length() > 5.0:
		_heading = _velocity.angle()
	queue_redraw()


## Where the back-arrow button sits, relative to the ship.
func button_offset() -> Vector2:
	var k := GD.screen_scale(self)
	return Vector2(26.0 * k, -26.0 * k)


func can_cancel() -> bool:
	return alive and not returning and not legs.is_empty()


func _unhandled_input(event: InputEvent) -> void:
	if not can_cancel() or not is_visible_in_tree():
		return
	if get_parent().get("allow_planet_clicks") != true:
		return
	var press := event as InputEventMouseButton
	if press == null or not press.pressed or press.button_index != MOUSE_BUTTON_LEFT:
		return
	var k := GD.screen_scale(self)
	if get_global_mouse_position().distance_to(global_position + button_offset()) <= 14.0 * k:
		cancel_requested.emit(self)
		get_viewport().set_input_as_handled()


func _draw() -> void:
	var dir := Vector2.RIGHT.rotated(_heading)
	var side := dir.orthogonal()
	# A rounded pod with the green pop head painted on it.
	var body := PackedVector2Array([dir * 11, dir * 6 + side * 6, -dir * 9 + side * 6, -dir * 11, -dir * 9 - side * 6, dir * 6 - side * 6])
	draw_colored_polygon(body, GD.faction_colour(faction))
	var outline := body.duplicate()
	outline.append(body[0])
	draw_polyline(outline, GD.faction_trim(faction), 2.0)
	var green := Color(GD.GAIN_COLOUR)
	draw_circle(Vector2(0, -2.5), 2.6, green)
	draw_rect(Rect2(Vector2(-3.5, 0.5), Vector2(7, 3.5)), green)
	var k := GD.screen_scale(self)
	if hull + armor < max_hull + max_armor:
		var w := 30.0 * k
		draw_rect(Rect2(Vector2(-w / 2.0, 12.0), Vector2(w, 3.0 * k)), Color(0.02, 0.03, 0.05, 0.8))
		draw_rect(Rect2(Vector2(-w / 2.0, 12.0), Vector2(w * (hull + armor) / (max_hull + max_armor), 3.0 * k)), Color("3dd17a"))
	var label := "Colony Ship" if GD.show_full_names else "CO"
	if GD.show_full_names:
		label += "  ·  %d POP%s" % [pops, "S" if pops > 1 else ""]
	if returning:
		label += "  (returning)"
	var tw := _font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
	draw_set_transform(Vector2(0, -12.0 - 4.0 * k), 0.0, Vector2(k, k))
	draw_string_outline(_font, Vector2(-tw / 2.0, 0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, 4, Color("0b0e14"))
	draw_string(_font, Vector2(-tw / 2.0, 0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(GD.GAIN_COLOUR))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# The back arrow (cancel), only while it's outbound.
	if can_cancel() and get_parent().get("allow_planet_clicks") == true:
		var c := button_offset()
		var hover := get_global_mouse_position().distance_to(global_position + c) <= 14.0 * k
		draw_circle(c, 12.0 * k, Color("0b0e14"))
		draw_circle(c, 11.0 * k, Color("2a3542") if hover else Color("1a222c"))
		draw_arc(c, 11.0 * k, 0.0, TAU, 24, Color("e9e6dc"), 1.5 * k)
		# A curved arrow pointing back.
		draw_arc(c, 5.0 * k, -PI * 0.9, PI * 0.5, 12, Color("e9e6dc"), 2.0 * k)
		var tip := c + Vector2(-5.0, -1.0) * k
		draw_colored_polygon(PackedVector2Array([tip + Vector2(-3.5, 1.0) * k, tip + Vector2(3.0, 1.5) * k, tip + Vector2(-0.5, -4.5) * k]), Color("e9e6dc"))
