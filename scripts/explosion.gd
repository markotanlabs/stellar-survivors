extends Node2D

const Sfx = preload("res://scripts/sfx.gd")
## A quick expanding flash where something was destroyed.

const LIFETIME := 0.6

var _age := 0.0
var _size := 40.0


func setup(pos_px: Vector2, size_px: float) -> void:
	position = pos_px
	_size = size_px
	call_deferred("_boom")


func _boom() -> void:
	Sfx.play("explosion_large" if _size >= 90.0 else "explosion_small", self, 0.0 if _size >= 90.0 else -4.0)


func _process(delta: float) -> void:
	_age += delta
	if _age >= LIFETIME:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var t := _age / LIFETIME
	draw_circle(Vector2.ZERO, _size * (0.4 + t), Color(1.0, 0.62, 0.25, 0.7 * (1.0 - t)))
	draw_circle(Vector2.ZERO, _size * 0.5 * (1.0 - t), Color(1.0, 0.95, 0.8, 1.0 - t))
