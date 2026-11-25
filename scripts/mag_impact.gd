extends Node2D
## A MAG slug punching through something (v0.9.161): sparks, white-hot ejecta, a little
## fire and torn metal spraying back out of the entry hole, and a jet of fire and glowing ejecta blowing out of
## the exit hole along the slug's path, then drifting smoke.

const LIFE := 0.9

var _age := 0.0
var _entry := Vector2.ZERO   # local to this node (it sits at the exit point)
var _dir := Vector2.RIGHT
var _k := 1.0
var _sparks: Array = []   # [pos, vel, life]
var _debris: Array = []   # [pos, vel, size, spin, angle, colour]
var _ejecta: Array = []   # [pos, vel, size, life]
var _fire: Array = []     # [pos, vel, radius, life]


## entry/exit in the parent's space; dir = the slug's direction; power scales it all.
func setup(entry: Vector2, exit_px: Vector2, dir: Vector2, power: float = 1.0) -> void:
	position = exit_px
	_entry = entry - exit_px
	_dir = dir.normalized()
	_k = clampf(power, 0.5, 2.0)
	z_index = 6
	var back := -_dir
	# Entry: a shower of sparks, white-hot ejecta and bits of hull blown back out toward
	# the shooter, with a small puff of fire (v0.9.168: ejecta and more sparks here too).
	for i in int(24 * _k):
		var a := back.rotated(randf_range(-1.2, 1.2))
		_sparks.append([_entry, a * randf_range(180.0, 560.0) * _k, randf_range(0.18, 0.45)])
	for i in int(8 * _k):
		var eb := back.rotated(randf_range(-0.8, 0.8))
		_ejecta.append([_entry, eb * randf_range(160.0, 440.0) * _k, randf_range(1.2, 2.4) * _k, randf_range(0.25, 0.55)])
	for i in int(4 * _k):
		var fb := back.rotated(randf_range(-0.6, 0.6))
		_fire.append([_entry, fb * randf_range(30.0, 90.0) * _k, randf_range(3.5, 7.0) * _k, randf_range(0.25, 0.45)])
	for i in int(6 * _k):
		var a2 := back.rotated(randf_range(-1.2, 1.2))
		_debris.append([_entry, a2 * randf_range(60.0, 200.0), randf_range(1.5, 3.5) * _k, randf_range(-12.0, 12.0), randf() * TAU, Color(0.55, 0.58, 0.64).darkened(randf() * 0.4)])
	# Exit: a cone of fire and white-hot ejecta blown out along the slug's path.
	for i in int(10 * _k):
		var f := _dir.rotated(randf_range(-0.45, 0.45))
		_fire.append([Vector2.ZERO, f * randf_range(40.0, 170.0) * _k, randf_range(5.0, 11.0) * _k, randf_range(0.35, 0.7)])
	for i in int(12 * _k):
		var e := _dir.rotated(randf_range(-0.6, 0.6))
		_ejecta.append([Vector2.ZERO, e * randf_range(220.0, 620.0) * _k, randf_range(1.5, 3.0) * _k, randf_range(0.35, 0.8)])
	for i in int(4 * _k):
		var e2 := _dir.rotated(randf_range(-0.7, 0.7))
		_debris.append([Vector2.ZERO, e2 * randf_range(120.0, 320.0), randf_range(2.0, 4.5) * _k, randf_range(-14.0, 14.0), randf() * TAU, Color(0.42, 0.45, 0.5).darkened(randf() * 0.3)])


func _process(delta: float) -> void:
	_age += delta
	if _age >= LIFE:
		queue_free()
		return
	var drag := pow(0.04, delta)   # fast things slow down hard
	for s in _sparks:
		s[0] += s[1] * delta
		s[1] *= drag
	for d in _debris:
		d[0] += d[1] * delta
		d[1] *= pow(0.2, delta)
		d[4] += float(d[3]) * delta
	for e in _ejecta:
		e[0] += e[1] * delta
		e[1] *= pow(0.08, delta)
	for f in _fire:
		f[0] += f[1] * delta
		f[1] *= pow(0.05, delta)
	if GD_on_screen():
		queue_redraw()


func GD_on_screen() -> bool:
	var p := get_global_transform_with_canvas().origin
	var r := get_viewport_rect()
	return p.x > -200.0 and p.y > -200.0 and p.x < r.size.x + 200.0 and p.y < r.size.y + 200.0


func _draw() -> void:
	var t := _age / LIFE
	# Flash at both holes for the first instant.
	if _age < 0.08:
		var fl := 1.0 - _age / 0.08
		draw_circle(_entry, 9.0 * _k, Color(1.0, 0.95, 0.8, 0.9 * fl))
		draw_circle(Vector2.ZERO, 14.0 * _k, Color(1.0, 0.85, 0.5, 0.9 * fl))
	# Fire: hot yellow cores going orange, then red, then grey smoke.
	for f in _fire:
		var life: float = f[3]
		var ft := clampf(_age / life, 0.0, 1.0)
		var smoke := _age > life
		var r: float = float(f[2]) * (0.6 + ft * 1.2) if not smoke else float(f[2]) * (1.8 + (_age - life) * 3.0)
		if smoke:
			var st := clampf((_age - life) / (LIFE - life), 0.0, 1.0)
			draw_circle(f[0], r, Color(0.35, 0.35, 0.38, 0.35 * (1.0 - st)))
		else:
			var hot := Color(1.0, 0.92, 0.55).lerp(Color(1.0, 0.45, 0.12), ft).lerp(Color(0.6, 0.15, 0.08), maxf(0.0, ft - 0.6) * 2.5)
			draw_circle(f[0], r, Color(hot, 0.85 * (1.0 - ft * 0.6)))
			draw_circle(f[0], r * 0.45, Color(1.0, 0.97, 0.8, 0.7 * (1.0 - ft)))
	# Ejecta: white-hot streaks cooling to orange.
	for e in _ejecta:
		var life2: float = e[3]
		if _age > life2:
			continue
		var et := _age / life2
		var v: Vector2 = e[1]
		var tail: Vector2 = e[0] - v * 0.035
		var col := Color(1.0, 0.95, 0.75).lerp(Color(1.0, 0.45, 0.1), et)
		draw_line(tail, e[0], Color(col, 1.0 - et), float(e[2]))
	# Sparks at the entry: thin bright streaks.
	for s in _sparks:
		var life3: float = s[2]
		if _age > life3:
			continue
		var st2 := _age / life3
		var sv: Vector2 = s[1]
		draw_line(s[0] - sv * 0.02, s[0], Color(1.0, 0.93, 0.6, 1.0 - st2), 1.6)
	# Torn metal tumbling away.
	for d in _debris:
		var sz: float = d[2]
		var ang: float = d[4]
		var c: Color = d[5]
		var pts := PackedVector2Array([Vector2(-sz, -sz * 0.6), Vector2(sz, -sz * 0.3), Vector2(sz * 0.5, sz * 0.7), Vector2(-sz * 0.7, sz * 0.4)])
		var xf := Transform2D(ang, d[0])
		draw_colored_polygon(xf * pts, Color(c, 1.0 - t * t))
