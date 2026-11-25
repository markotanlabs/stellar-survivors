extends Node2D
## A flak shell bursting (v0.9.185): not a fireball, but a WW2-style flak puff. A pin-prick
## flash, a spray of shrapnel streaks, and a lumpy cloud of pale smoke with a dark rim
## that hangs in the air and slowly thins out. Pale so it reads against black space.

const Sfx = preload("res://scripts/sfx.gd")
const LIFE := 1.4

var _age := 0.0
var _r := 20.0
var _lumps: Array = []    # [offset, radius]
var _shards: Array = []   # [direction, speed]
var _drift := Vector2.ZERO


func setup(pos_px: Vector2, radius_px: float) -> void:
	position = pos_px
	_r = maxf(radius_px * 0.55, 8.0)
	z_index = 5
	rotation = randf() * TAU
	for i in 5:
		var a := TAU * i / 5.0 + randf_range(-0.4, 0.4)
		_lumps.append([Vector2.RIGHT.rotated(a) * _r * randf_range(0.25, 0.5), _r * randf_range(0.45, 0.65)])
	_lumps.append([Vector2.ZERO, _r * 0.7])
	for i in 10:
		_shards.append([Vector2.RIGHT.rotated(randf() * TAU), randf_range(_r * 4.0, _r * 7.0)])
	_drift = Vector2.RIGHT.rotated(randf() * TAU) * randf_range(2.0, 6.0)
	call_deferred("_bang")


func _bang() -> void:
	Sfx.play("explosion_small", self, -12.0, 0.2)


func _process(delta: float) -> void:
	_age += delta
	if _age >= LIFE:
		queue_free()
		return
	position += _drift * delta
	if is_visible_in_tree():
		queue_redraw()


func _draw() -> void:
	var t := _age / LIFE
	# The cloud swells fast, then hangs and thins.
	var grow := 0.55 + 0.45 * (1.0 - pow(1.0 - minf(_age / 0.25, 1.0), 3.0)) + 0.15 * t
	var fade := 1.0 - smoothstep(0.35, 1.0, t)
	# Dark rim first (all lumps a touch bigger), then the pale smoke on top.
	for l in _lumps:
		draw_circle(Vector2(l[0]) * grow, float(l[1]) * grow + 2.0, Color(0.16, 0.17, 0.2, 0.85 * fade))
	for l in _lumps:
		draw_circle(Vector2(l[0]) * grow, float(l[1]) * grow, Color(0.74, 0.76, 0.8, 0.9 * fade))
	# Soft shading on the lower side of the puff.
	for l in _lumps:
		draw_circle(Vector2(l[0]) * grow + Vector2(0, float(l[1]) * 0.3 * grow), float(l[1]) * grow * 0.6, Color(0.52, 0.55, 0.6, 0.55 * fade))
	# Shrapnel: thin bright streaks flung out in the first moment.
	if _age < 0.22:
		var st := _age / 0.22
		for s in _shards:
			var d: Vector2 = s[0]
			var reach: float = float(s[1]) * (0.2 + st * 0.8) * 0.45   # flung well clear of the puff
			draw_line(d * reach * 0.7, d * reach, Color(1.0, 0.92, 0.7, 1.0 - st), 1.5)
	# The flash: a small, hot pin-prick at the heart.
	if _age < 0.07:
		var ft := 1.0 - _age / 0.07
		draw_circle(Vector2.ZERO, _r * 0.5 * ft, Color(1.0, 0.95, 0.75, ft))
