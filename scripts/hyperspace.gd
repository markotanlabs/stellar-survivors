extends CanvasLayer
## Full-screen hyperspace effect: stars stretch into lines rushing out from the centre.
## Set intensity between 0 (off) and 1 (full).

var intensity := 0.0
var _streaks: Array = []
var _canvas: Node2D


func _ready() -> void:
	layer = 1
	_canvas = Node2D.new()
	add_child(_canvas)
	_canvas.draw.connect(_draw_streaks)
	for i in 160:
		_streaks.append({"angle": randf() * TAU, "dist": randf(), "speed": randf_range(0.6, 1.4), "width": randf_range(1.0, 3.0)})


func _process(delta: float) -> void:
	if intensity <= 0.001:
		_canvas.visible = false
		return
	_canvas.visible = true
	for s in _streaks:
		s["dist"] = float(s["dist"]) + delta * float(s["speed"]) * (0.4 + 1.6 * intensity)
		if float(s["dist"]) > 1.0:
			s["dist"] = 0.02
			s["angle"] = randf() * TAU
	_canvas.queue_redraw()


func _draw_streaks() -> void:
	var size := _canvas.get_viewport_rect().size
	var centre := size / 2.0
	var reach := size.length() * 0.6
	_canvas.draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.08, 0.16, 0.45 * intensity))
	for s in _streaks:
		var dir := Vector2.RIGHT.rotated(float(s["angle"]))
		var d := float(s["dist"])
		var start := centre + dir * reach * d * d
		var length := reach * (0.05 + 0.35 * intensity) * d
		var colour := Color(0.82, 0.9, 1.0, intensity * clampf(d * 2.0, 0.0, 1.0))
		_canvas.draw_line(start, start + dir * length, colour, float(s["width"]))
