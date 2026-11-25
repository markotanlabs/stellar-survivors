extends Node2D
## An unarmed Hauler carrying a Starbase's collected resources to the nearest planet
## you own, warping between systems if it has to. Each resource rides as a container.

signal delivered(hauler: Node2D, cargo: Dictionary, system_index: int, pos_px: Vector2)
signal destroyed(ship: Node2D)
signal hit(ship: Node2D)

const GD = preload("res://scripts/game_data.gd")
const ResIcon = preload("res://scripts/res_icon.gd")
const Explosion = preload("res://scripts/explosion.gd")

var faction := GD.Faction.UNE
var alive := true
var hull := GD.CIVILIAN_HULL
var max_hull := GD.CIVILIAN_HULL
var armor := GD.CIVILIAN_ARMOR
var max_armor := GD.CIVILIAN_ARMOR
var cargo := {}          # {"alloys": 2, "gas": 1}
var system_index := 0
var legs: Array = []     # {"kind": "planet" | "exit", "pos": Vector2 px, "to": int, "entry": Vector2 px}
var views: Array = []

var _velocity := Vector2.ZERO
var _speed := GD.HAULER_SPEED * GD.UNIT * GD.hauler_speed_mult   # Hauler Depot speeds new Haulers
var _warp_left := 0.0
var _heading := 0.0
var _font: Font
var _time := 0.0
var _path: Array = []    # where the Hauler has been, newest first: the containers follow it like a train


func setup(new_views: Array, start_system: int, start_px: Vector2, new_legs: Array, new_cargo: Dictionary) -> void:
	views = new_views
	system_index = start_system
	position = start_px
	legs = new_legs
	cargo = new_cargo
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
	if hull <= 0.0:
		alive = false
		var boom := Explosion.new()
		get_parent().add_child(boom)
		boom.setup(position, 30.0)
		destroyed.emit(self)
		queue_free()


func _process(delta: float) -> void:
	_time += delta
	if not alive or legs.is_empty():
		return
	if _warp_left > 0.0:
		_warp_left -= delta
		if _warp_left <= 0.0:
			var warp_leg: Dictionary = legs.pop_front()
			var to_index := int(warp_leg["to"])
			var target_view: Node2D = views[to_index]
			reparent(target_view, false)
			system_index = to_index
			position = warp_leg["entry"]
			_path.clear()
			visible = true
		return
	var leg: Dictionary = legs[0]
	var target: Vector2 = leg["pos"]
	var to := target - position
	if to.length() < 0.8 * GD.UNIT:
		if String(leg["kind"]) == "planet":
			delivered.emit(self, cargo, system_index, position)
			queue_free()
		else:
			# Into the warp; reappear in the next system after the usual transit.
			visible = false
			_warp_left = GD.WARP_TRANSIT
			_velocity = Vector2.ZERO
		return
	var desired := to.normalized() * minf(_speed, sqrt(2.0 * _speed * 2.0 * to.length()))
	_velocity = _velocity.move_toward(desired, _speed * 2.0 * delta)
	position += _velocity * delta
	if _velocity.length() > 5.0:
		_heading = _velocity.angle()
	if _path.is_empty() or position.distance_to(_path[0]) > 3.0:
		_path.push_front(position)
		if _path.size() > 120:
			_path.pop_back()
	queue_redraw()


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(0.7, 0.7))
	var dir := Vector2.RIGHT.rotated(_heading)
	var side := dir.orthogonal()
	# Containers trail behind, slightly apart: grey for Alloys, green for Gas.
	var colours: Array = []
	var kinds: Array = []
	for i in int(ceil(float(int(cargo.get("alloys", 0))) / 5.0)):   # a container holds 5 Alloys (v0.9.237)
		colours.append(Color("aeb9c6"))
		kinds.append("alloys")
	for i in int(cargo.get("gas", 0)):
		colours.append(Color("8fd14f"))
		kinds.append("gas")
	var tail := -dir * 16.0
	var tail_dir := -dir
	# Bigger containers, spaced out, held by a glowing gravity chain. They follow the
	# Hauler's path like train cars, so they swing wide on turns and line up on straights.
	var prev := -dir * 8.0
	for i in colours.size():
		var c := _along_path((26.0 + i * 22.0) * 0.7) / 0.7
		var ahead := _along_path((26.0 + i * 22.0 - 8.0) * 0.7) / 0.7
		var cdir := (ahead - c).normalized() if ahead.distance_to(c) > 0.1 else dir
		var cside := cdir.orthogonal()
		var link_to := c + cdir * 7.0
		for j in 4:
			var p := prev.lerp(link_to, (j + 0.5) / 4.0)
			draw_circle(p, 1.8, Color(0.56, 0.85, 1.0, 0.35 + 0.3 * sin(_time * 6.0 - i - j)))
		var box := PackedVector2Array([c + cdir * 7 + cside * 7, c + cdir * 7 - cside * 7, c - cdir * 7 - cside * 7, c - cdir * 7 + cside * 7])
		draw_colored_polygon(box, colours[i])
		draw_polyline(PackedVector2Array([box[0], box[1], box[2], box[3], box[0]]), Color("0b0e14"), 2.0)
		# What's inside, stencilled on the container.
		ResIcon.draw(self, String(kinds[i]), c, 4.5)
		prev = c - cdir * 7.0
		tail = c - cdir * 12.0   # just past the back of the last container
		tail_dir = -cdir
	# The Hauler itself: a stubby box with a cab.
	var body := PackedVector2Array([dir * 10 + side * 5, dir * 10 - side * 5, -dir * 8 - side * 6, -dir * 8 + side * 6])
	draw_colored_polygon(body, GD.faction_colour(faction))
	draw_polyline(PackedVector2Array([body[0], body[1], body[2], body[3], body[0]]), GD.faction_trim(faction), 2.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var k := GD.screen_scale(self)
	# Health bar once damaged, green like the rest of your ships.
	if hull + armor < max_hull + max_armor:
		var w := 30.0 * k
		draw_rect(Rect2(Vector2(-w / 2.0, 12.0), Vector2(w, 3.0 * k)), Color(0.02, 0.03, 0.05, 0.8))
		draw_rect(Rect2(Vector2(-w / 2.0, 12.0), Vector2(w * (hull + armor) / (max_hull + max_armor), 3.0 * k)), Color("3dd17a"))
	# The cargo, always: a green tally trailing behind the last container.
	var parts: Array = []
	if int(cargo.get("alloys", 0)) > 0:
		parts.append("+{alloys}%d" % int(cargo["alloys"]))
	if int(cargo.get("gas", 0)) > 0:
		parts.append("+{gas}%d" % int(cargo["gas"]))
	if not parts.is_empty():
		var cargo_text := "  ".join(PackedStringArray(parts))
		var cw := ResIcon.text_width(_font, cargo_text, 15)
		# Set it clear behind the last car: push the tally's centre out along the train's
		# direction by half its own width (or height), plus a gap, so it never sits on a box.
		var half := Vector2(cw * 0.5, 9.0) * k
		var reach := absf(tail_dir.x) * half.x + absf(tail_dir.y) * half.y + 8.0 * k
		var centre := tail * 0.7 + tail_dir * reach
		draw_set_transform(centre + Vector2(0, 5.0 * k), 0.0, Vector2(k, k))
		ResIcon.draw_text(self, _font, Vector2(-cw / 2.0, 0), cargo_text, 15, Color("3dd17a"))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Its name while Space (info) is held, or "HL" with Abbreviated Ship Names on.
	if not GD.show_full_names and not GD.show_abbrev_names:
		return
	var label := "Hauler" if GD.show_full_names else "HL"
	var tw := _font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
	draw_set_transform(Vector2(0, -10.0 - 4.0 * k), 0.0, Vector2(k, k))
	draw_string_outline(_font, Vector2(-tw / 2.0, 0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, 4, Color("0b0e14"))
	draw_string(_font, Vector2(-tw / 2.0, 0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("f4efe2"))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## A point this far back along the Hauler's recent path, in local pixels.
func _along_path(distance: float) -> Vector2:
	var left := distance
	var here := position
	for p in _path:
		var point: Vector2 = p
		var step := here.distance_to(point)
		if step >= left and step > 0.0:
			return here.lerp(point, left / step) - position
		left -= step
		here = point
	# Path too short: carry on straight behind.
	return here - position - Vector2.RIGHT.rotated(_heading) * left
