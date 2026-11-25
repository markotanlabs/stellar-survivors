extends Node2D
## A short counter-thrust gas jet: white puffs shooting out ahead of a braking ship.

const GD = preload("res://scripts/game_data.gd")

const LIFETIME := 0.45

var _dir := Vector2.RIGHT
var _age := 0.0
var _size := 10.0
var _start := 0.5      # where the jet begins, in sizes from the nozzle (0: right at the hull)
var _life := LIFETIME


func setup(pos_px: Vector2, dir: Vector2, size_px: float, start: float = 0.5, life: float = LIFETIME) -> void:
	position = pos_px
	_dir = dir
	_size = size_px
	_start = start
	_life = life


func _process(delta: float) -> void:
	_age += delta
	if _age >= _life:
		queue_free()
		return
	if GD.on_screen(self):   # performance: puffs out of view don't redraw
		queue_redraw()


func _draw() -> void:
	var t := _age / _life
	# A tight, pressurised jet: small puffs strung out in a narrow line.
	if t < 0.35:
		draw_circle(Vector2.ZERO, _size * 0.07, Color(1, 1, 1, 0.9 * (1.0 - t / 0.35)))   # nozzle flash
	for i in 5:
		var along := _dir * _size * (_start + t * 2.0 + i * 0.22)
		var side := _dir.orthogonal() * _size * (float(i % 2) - 0.5) * 0.02 * t
		draw_circle(along + side, _size * (0.035 + 0.045 * t), Color(0.93, 0.96, 1.0, 0.75 * (1.0 - t)))   # smaller, narrower (v0.9.217)
