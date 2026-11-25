extends Node2D
## A bright streak left behind by a MAG-family round. It lingers for a moment after the
## shot, so you can see who fired and from where, then fades out.

const LINGER := 1.5

var colour := Color("b8e4ff")
var width := 3.0
var _points: Array = []   # [position, age, hidden]: hidden points are inside something the slug went through
var _owner_gone := false


func add_point(pos: Vector2, hidden: bool = false) -> void:
	_points.append([pos, 0.0, hidden])


func owner_gone() -> void:
	_owner_gone = true


func _ready() -> void:
	z_index = 4


func _process(delta: float) -> void:
	for p in _points:
		p[1] = float(p[1]) + delta
	while not _points.is_empty() and float(_points[0][1]) > LINGER:
		_points.pop_front()
	if _owner_gone and _points.is_empty():
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	for i in range(_points.size() - 1):
		var a: Array = _points[i]
		var b: Array = _points[i + 1]
		if bool(a[2]) or bool(b[2]):
			continue   # inside the hull it punched through: no line over the ship
		var fade := 1.0 - float(a[1]) / LINGER
		draw_line(Vector2(a[0]), Vector2(b[0]), Color(colour, 0.15 * fade), width * 3.0)
		draw_line(Vector2(a[0]), Vector2(b[0]), Color(colour.lightened(0.3), 0.7 * fade), width)
