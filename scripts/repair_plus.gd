extends Node2D
## A small green "+" that floats up from a ship being repaired and fades out.

const GD = preload("res://scripts/game_data.gd")
const LIFETIME := 1.1

var _age := 0.0
var _start := Vector2.ZERO


func setup(pos_px: Vector2) -> void:
	_start = pos_px
	position = pos_px
	z_index = 12


func _process(delta: float) -> void:
	_age += delta
	if _age >= LIFETIME:
		queue_free()
		return
	var k := GD.screen_scale(self)
	position = _start + Vector2(0, -34.0 * k * _age / LIFETIME)
	queue_redraw()


func _draw() -> void:
	var k := GD.screen_scale(self)
	var t := _age / LIFETIME
	var alpha := 1.0 if t < 0.5 else 1.0 - (t - 0.5) / 0.5
	var arm := 7.0 * k
	var ink := Color(0.04, 0.05, 0.08, alpha)
	var green := Color(GD.GAIN_COLOUR)
	green.a = alpha
	draw_line(Vector2(-arm, 0), Vector2(arm, 0), ink, 6.0 * k)
	draw_line(Vector2(0, -arm), Vector2(0, arm), ink, 6.0 * k)
	draw_line(Vector2(-arm, 0), Vector2(arm, 0), green, 3.0 * k)
	draw_line(Vector2(0, -arm), Vector2(0, arm), green, 3.0 * k)
