extends Node2D
## Scrolling combat text: "+3 ALLOYS" rises from whatever earned it and fades out.

const GD = preload("res://scripts/game_data.gd")
const ResIcon = preload("res://scripts/res_icon.gd")
const LIFETIME := 1.8
const RISE := 70.0   # screen pixels over its lifetime

var lines: Array = []
var _age := 0.0
var _start := Vector2.ZERO
var _font: Font


func setup(pos_px: Vector2, new_lines: Array) -> void:
	_start = pos_px
	position = pos_px
	lines = new_lines
	_font = ThemeDB.fallback_font


func _process(delta: float) -> void:
	_age += delta
	if _age >= LIFETIME:
		queue_free()
		return
	var k := GD.screen_scale(self)
	var t := _age / LIFETIME
	position = _start + Vector2(0, -RISE * k * (1.0 - pow(1.0 - t, 2.0)))
	queue_redraw()


func _draw() -> void:
	if _font == null:
		return
	var k := GD.screen_scale(self)
	var t := _age / LIFETIME
	# The fade is applied to the whole node (modulate) so the icons fade with the text.
	modulate.a = 1.0 if t < 0.6 else clampf(1.0 - (t - 0.6) / 0.4, 0.0, 1.0)
	var alpha := 1.0
	var colour := Color(GD.GAIN_COLOUR)
	colour.a = alpha
	var ink := Color(0.04, 0.05, 0.08, alpha)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(k, k))
	var size := 22
	for i in lines.size():
		var text: String = lines[i]
		# "+3 ALLOYS", "+1 GAS" and "+¢2" show as the resource icon and the number.
		var kind := ""
		if text.ends_with(" ALLOYS") or text.ends_with(" ALLOY"):
			kind = "alloys"
			text = text.get_slice(" ", 0)
		elif text.ends_with(" GAS"):
			kind = "gas"
			text = text.get_slice(" ", 0)
		elif text.begins_with("+¢"):
			kind = "credits"
			text = "+" + text.substr(2)
		var icon_w := 22.0 if kind != "" else 0.0
		var w := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x + icon_w
		var y := -40.0 - (lines.size() - 1 - i) * 26.0
		var x := -w / 2.0
		if kind != "":
			ResIcon.draw(self, kind, Vector2(x + 9.0, y - 7.0), 9.0)
		draw_string_outline(_font, Vector2(x + icon_w, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 6, ink)
		draw_string(_font, Vector2(x + icon_w, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, colour)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
