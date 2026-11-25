extends Control
## A resource icon as a UI control (top bar, panels). See res_icon.gd.

const ResIcon = preload("res://scripts/res_icon.gd")

var kind := "alloys"


func _init(new_kind: String = "alloys", px: float = 22.0) -> void:
	kind = new_kind
	custom_minimum_size = Vector2(px, px)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	ResIcon.draw(self, kind, size / 2.0, minf(size.x, size.y) * 0.45)
