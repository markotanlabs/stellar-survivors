extends RefCounted
## Resource icons in a Stellaris-like style, drawn in code so they work anywhere:
## $ is a gold coin, Alloys stacked ingots, Gas a green gas flame.
## ResIcon.draw(canvas, "alloys", centre, radius) from any _draw().

const COLOURS := {
	"credits": Color("e8c14a"),
	"alloys": Color("d97ae0"),
	"gas": Color("6fd16a"),
}


## muted: draw it in greys (e.g. a resource nobody is collecting).
static func draw(canvas: CanvasItem, kind: String, c: Vector2, s: float, muted: bool = false) -> void:
	var ink := Color("0b0e14")
	match kind:
		"credits":
			var gold: Color = COLOURS["credits"]
			canvas.draw_circle(c, s, _m(gold.darkened(0.35), muted))
			canvas.draw_circle(c, s * 0.8, _m(gold, muted))
			canvas.draw_arc(c, s, 0.0, TAU, 20, ink, 1.2)
			# The credit sign: a C with a line straight through it (v0.9.141; was a $).
			# v0.9.148: a bigger, bolder, darker C and a thinner line so the C reads first.
			var mark := _m(Color("3a2606"), muted)
			canvas.draw_arc(c + Vector2(s * 0.04, 0), s * 0.5, 1.05, TAU - 1.05, 20, mark, maxf(1.6, s * 0.3), true)
			canvas.draw_line(c + Vector2(0, -s * 0.76), c + Vector2(0, s * 0.76), mark, maxf(1.0, s * 0.1), true)
		"alloys":
			# Stacked alloy ingots, after the reference: a pink bar on a teal bar, a small
			# copper ingot tucked behind on the left. Bars lean slightly.
			var tilt := -0.35
			canvas.draw_colored_polygon(_capsule(c + Vector2(-0.62, 0.22) * s, 0.12 * s, 0.26 * s, tilt), _m(Color("b8643c"), muted))
			var teal := _capsule(c + Vector2(0.1, 0.3) * s, 0.42 * s, 0.34 * s, tilt)
			canvas.draw_colored_polygon(teal, _m(Color("1f8fa8"), muted))
			canvas.draw_colored_polygon(_capsule(c + Vector2(0.08, 0.2) * s, 0.36 * s, 0.16 * s, tilt), _m(Color("3fb6cc"), muted))
			var pink := _capsule(c + Vector2(-0.12, -0.28) * s, 0.42 * s, 0.34 * s, tilt)
			canvas.draw_colored_polygon(pink, _m(Color("d97ae0"), muted))
			canvas.draw_colored_polygon(_capsule(c + Vector2(-0.14, -0.38) * s, 0.36 * s, 0.15 * s, tilt), _m(Color("f0a8f2"), muted))
			var rim_teal := teal.duplicate()
			rim_teal.append(teal[0])
			canvas.draw_polyline(rim_teal, ink, 1.0)
			var rim_pink := pink.duplicate()
			rim_pink.append(pink[0])
			canvas.draw_polyline(rim_pink, ink, 1.0)
		"gas":
			# A green gas flame: a tall leaning tip, a smaller lobe on the right and a round
			# dark notch at the base (after the reference the player sent).
			var green: Color = COLOURS["gas"]
			var shape := PackedVector2Array()
			for p in GAS_FLAME:
				shape.append(c + Vector2(p) * s)
			canvas.draw_colored_polygon(shape, _m(green, muted))
			var rim := shape.duplicate()
			rim.append(shape[0])
			canvas.draw_polyline(rim, ink, 1.0)
			canvas.draw_circle(c + Vector2(0.0, 0.72) * s, 0.28 * s, ink)



## Greyed-out version of a colour, keeping its lightness.
static func _m(col: Color, muted: bool) -> Color:
	if not muted:
		return col
	var v := col.get_luminance() * 0.75 + 0.18
	return Color(v, v, v, col.a)


## A rounded bar (ingot): half_len along its length, r its half-thickness, turned by angle.
static func _capsule(centre: Vector2, half_len: float, r: float, angle: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var steps := 8
	for i in steps + 1:
		var a := -PI / 2.0 + PI * i / steps
		pts.append(Vector2(half_len, 0) + Vector2.RIGHT.rotated(a) * r)
	for i in steps + 1:
		var a := PI / 2.0 + PI * i / steps
		pts.append(Vector2(-half_len, 0) + Vector2.RIGHT.rotated(a) * r)
	var out := PackedVector2Array()
	for p in pts:
		out.append(centre + p.rotated(angle))
	return out


## The gas flame outline, clockwise from the bottom (radius-1 units, y down).
const GAS_FLAME := [
	Vector2(0.0, 0.95), Vector2(0.45, 0.88), Vector2(0.7, 0.6), Vector2(0.78, 0.2),
	Vector2(0.7, -0.15), Vector2(0.55, -0.5), Vector2(0.4, -0.15), Vector2(0.3, -0.45),
	Vector2(0.15, -0.8), Vector2(0.0, -1.0), Vector2(-0.2, -0.7), Vector2(-0.45, -0.4),
	Vector2(-0.65, -0.05), Vector2(-0.72, 0.3), Vector2(-0.6, 0.65), Vector2(-0.35, 0.88),
]


# --- text with icons ---------------------------------------------------------------
# Write "{alloys}40", "{gas}1" or "{credits}20" in any text and it shows the icon and
# the number instead of a word. Used by in-world labels and IconText (the HUD).

## [[icon kind or "", text], ...]
static func parse(text: String) -> Array:
	var out: Array = []
	var parts := text.split("{")
	if parts[0] != "":
		out.append(["", parts[0]])
	for i in range(1, parts.size()):
		var piece: String = parts[i]
		var close := piece.find("}")
		if close < 0:
			out.append(["", "{" + piece])
			continue
		var kind := piece.left(close).to_lower()
		if COLOURS.has(kind):
			out.append([kind, ""])
		else:
			out.append(["", "{" + piece.left(close + 1)])
		var rest := piece.substr(close + 1)
		if rest != "":
			out.append(["", rest])
	return out


static func text_width(font: Font, text: String, size: int) -> float:
	var w := 0.0
	for part in parse(text):
		if String(part[0]) != "":
			w += size * 0.9 + 2.0
		else:
			w += font.get_string_size(String(part[1]), HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	return w


## Draws text (with icons) starting at pos, pos.y being the text baseline.
static func draw_text(canvas: CanvasItem, font: Font, pos: Vector2, text: String, size: int, colour: Color, outline: int = 4, muted: bool = false) -> void:
	var x := pos.x
	var ink := Color(0.04, 0.05, 0.08, colour.a)
	for part in parse(text):
		var kind := String(part[0])
		if kind != "":
			var s := size * 0.45
			draw(canvas, kind, Vector2(x + s, pos.y - size * 0.35), s, muted)
			x += size * 0.9 + 2.0
		else:
			var t := String(part[1])
			if outline > 0:
				canvas.draw_string_outline(font, Vector2(x, pos.y), t, HORIZONTAL_ALIGNMENT_LEFT, -1, size, outline, ink)
			canvas.draw_string(font, Vector2(x, pos.y), t, HORIZONTAL_ALIGNMENT_LEFT, -1, size, colour)
			x += font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
