extends Node2D
## Afterimage: a ghost of the fleet left where it blinked from. For a moment enemies
## see it as the fleet: they aim at it, and shots that reach it are soaked up harmlessly.

const GD = preload("res://scripts/game_data.gd")

var faction := GD.Faction.UNE
var alive := true
var radius := 3.0        # units: the ghost's hitbox for shots
var _ghosts: Array = []  # [local offset, heading, size px]
var _left := GD.AFTERIMAGE_SECONDS
var _flicker := 0.0


func setup(centre_px: Vector2, ghosts: Array) -> void:
	position = centre_px
	var reach := 1.0
	for g in ghosts:
		var at: Vector2 = g[0]
		_ghosts.append([at - centre_px, float(g[1]), float(g[2])])
		reach = maxf(reach, (at - centre_px).length() / GD.UNIT + 1.0)
	radius = reach
	z_index = 2


func _ready() -> void:
	add_to_group("targets")


func take_damage(_amount: float, _attacker: Node2D = null) -> void:
	_flicker = 0.12


func _process(delta: float) -> void:
	_left -= delta
	_flicker = maxf(0.0, _flicker - delta)
	if _left <= 0.0:
		alive = false
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var a := clampf(_left / GD.AFTERIMAGE_SECONDS, 0.0, 1.0) * (0.9 if _flicker > 0.0 else 0.55)
	var colour := Color(0.56, 0.82, 1.0, a)
	for g in _ghosts:
		var at: Vector2 = g[0]
		var dir := Vector2.RIGHT.rotated(float(g[1]))
		var side := dir.orthogonal()
		var r := float(g[2]) * 0.5
		var hull := PackedVector2Array([at + dir * r, at - dir * r * 0.7 + side * r * 0.6, at - dir * r * 0.4, at - dir * r * 0.7 - side * r * 0.6, at + dir * r])
		draw_polyline(hull, colour, 2.0)
		draw_colored_polygon(PackedVector2Array([hull[0], hull[1], hull[2], hull[3]]), Color(colour, a * 0.25))
