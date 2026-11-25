extends Control
## Wrapping card text where resources show as their icons (v0.9.162): "¢5" becomes the
## credit coin and 5, and the words Alloy(s), Gas (not "Gas Giant") and Credit(s)
## become their icons. Lays the words out itself, a line at a time, and asks for the
## height it needs.

const ResIcon = preload("res://scripts/res_icon.gd")

var font_size := 15
var icon_scale := 1.6   # icons drawn this much bigger than ResIcon's in-line size (v0.9.166)
var colour := Color(0.875, 0.875, 0.875)
var _words: Array = []
var _lines: Array = []   # [[word, ...], ...]
var _laid_for := -1.0


## The text with resource words swapped for icon tokens ({credits}, {alloys}, {gas}).
static func iconize(text: String) -> String:
	var out := text
	var rules := [
		# (never inside an icon token that's already there: that made "{{credits}}", v0.9.187)
		["¢(\\d+)", "{credits}$1"],
		["(?<!\\{)\\b[Aa]lloys?\\b(?!\\})", "{alloys}"],
		["(?<!\\{)\\bGas\\b(?! [Gg]iant)(?!\\})", "{gas}"],
		["(?<!\\{)\\b[Cc]redits?\\b(?!\\})", "{credits}"],
	]
	for r in rules:
		var re := RegEx.new()
		re.compile(String(r[0]))
		out = re.sub(out, String(r[1]), true)
	return out


func set_text(text: String) -> void:
	_words = Array(iconize(text).split(" ", false))
	_laid_for = -1.0
	_layout()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_layout)
	_layout()


func _font() -> Font:
	return get_theme_font("font", "Label")


func _layout() -> void:
	var width := size.x if size.x > 20.0 else 210.0
	if is_equal_approx(width, _laid_for):
		return
	_laid_for = width
	var font := _font()
	var space := font.get_string_size(" ", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	_lines = [[]]
	var x := 0.0
	for w in _words:
		var ww := _word_width(font, String(w))
		if x > 0.0 and x + space + ww > width:
			_lines.append([])
			x = 0.0
		if x > 0.0:
			x += space
		x += ww
		(_lines[-1] as Array).append(w)
	custom_minimum_size.y = _line_h(font) * _lines.size()
	queue_redraw()


func _line_h(font: Font) -> float:
	return maxf(font.get_height(font_size), font_size * 0.9 * icon_scale) + 2.0


## Width of one word, its icons at icon_scale.
func _word_width(font: Font, word: String) -> float:
	var w := 0.0
	for part in ResIcon.parse(word):
		if String(part[0]) != "":
			w += font_size * 0.9 * icon_scale + 2.0
		else:
			w += font.get_string_size(String(part[1]), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	return w


func _draw() -> void:
	var font := _font()
	var space := font.get_string_size(" ", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var line_h := _line_h(font)
	var y := (line_h - font.get_height(font_size)) / 2.0 + font.get_ascent(font_size)
	for line in _lines:
		var x := 0.0
		for w in line:
			for part in ResIcon.parse(String(w)):
				if String(part[0]) != "":
					var r := font_size * 0.45 * icon_scale
					ResIcon.draw(self, String(part[0]), Vector2(x + r, y - font_size * 0.35), r)
					x += font_size * 0.9 * icon_scale + 2.0
				else:
					var t := String(part[1])
					draw_string(font, Vector2(x, y), t, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, colour)
					x += font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
			x += space
		y += line_h
