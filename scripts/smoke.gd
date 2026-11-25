extends Node2D
## A soft puff (smoke, fire or a weapon trail) that grows, drifts and fades away.

const GD = preload("res://scripts/game_data.gd")

var _age := 0.0
var _life := 1.2
var _size := 8.0
var _grow := 2.0
var _colour := Color(0.6, 0.6, 0.6, 0.5)
var _drift := Vector2.ZERO


func setup(pos_px: Vector2, size_px: float, colour: Color, life: float, drift_px: Vector2 = Vector2.ZERO, grow: float = 2.0) -> void:
	position = pos_px
	_size = size_px
	_colour = colour
	_life = life
	_drift = drift_px
	_grow = grow
	z_index = 5


func _process(delta: float) -> void:
	_age += delta
	if _age >= _life:
		queue_free()
		return
	position += _drift * delta
	_drift *= exp(-1.5 * delta)
	if GD.on_screen(self):   # performance: smoke out of view doesn't redraw
		queue_redraw()


func _draw() -> void:
	var t := _age / _life
	var r := _size * (1.0 + _grow * t)
	var c := _colour
	c.a *= (1.0 - t) * (1.0 - t)
	draw_circle(Vector2.ZERO, r, c)
	draw_circle(Vector2.ZERO, r * 0.6, Color(c.r, c.g, c.b, c.a * 0.8))
