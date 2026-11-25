extends Node2D
## A quick expanding ring of light: blink departures and arrivals, the Hot Exit pulse.

var colour := Color("8fd1ff")
var radius := 60.0
var life := 0.45
var _age := 0.0


func setup(pos_px: Vector2, new_radius: float, new_colour: Color, new_life: float = 0.45) -> void:
	position = pos_px
	radius = new_radius
	colour = new_colour
	life = new_life
	z_index = 6


func _process(delta: float) -> void:
	_age += delta
	if _age >= life:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var t := _age / life
	var r := radius * (0.25 + 0.75 * sqrt(t))
	var a := 1.0 - t
	draw_circle(Vector2.ZERO, r * 0.6, Color(colour, 0.25 * a))
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, Color(colour, 0.9 * a), 4.0 * (1.0 - t) + 1.0)
	draw_arc(Vector2.ZERO, r * 0.7, 0.0, TAU, 48, Color(colour.lightened(0.5), 0.5 * a), 2.0)
