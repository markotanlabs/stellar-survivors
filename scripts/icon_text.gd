extends HBoxContainer
## A line of HUD text where "{alloys}40", "{gas}1" and "{credits}20" show as resource
## icons with numbers (see res_icon.gd). Set .text like a Label.

const ResIcon = preload("res://scripts/res_icon.gd")
const ResIconControl = preload("res://scripts/res_icon_control.gd")

var font_size := 20
var font_colour := Color.WHITE
var outline := 6
var _text := ""

var text: String:
	get:
		return _text
	set(value):
		if value == _text:
			return
		_text = value
		_rebuild()


func _init(size: int = 20, colour: Color = Color.WHITE, outline_px: int = 6) -> void:
	font_size = size
	font_colour = colour
	outline = outline_px
	alignment = BoxContainer.ALIGNMENT_CENTER
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation", 2)


func _rebuild() -> void:
	for child in get_children():
		child.queue_free()
	for part in ResIcon.parse(_text):
		var kind := String(part[0])
		if kind != "":
			var icon := ResIconControl.new(kind, font_size * 1.05)
			icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			add_child(icon)
		else:
			var label := Label.new()
			label.text = String(part[1])
			label.add_theme_font_size_override("font_size", font_size)
			label.add_theme_color_override("font_color", font_colour)
			label.add_theme_color_override("font_outline_color", Color("0b0e14"))
			label.add_theme_constant_override("outline_size", outline)
			label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(label)
