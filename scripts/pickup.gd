extends Node2D
## A reward dropped in the world: fly the fleet to it to collect it.
## kind "fleet": a spinning red card (costs credits). kind "tech": a spinning blue chip (free).
## kind "secret": the chip with a pulsing purple glow (free, rare).

const GD = preload("res://scripts/game_data.gd")

var kind := "fleet"
var rarity := "Good"
var _time := 0.0
var _font: Font


func setup(pos_px: Vector2, new_kind: String, new_rarity: String) -> void:
	position = pos_px
	kind = new_kind
	rarity = new_rarity
	_font = ThemeDB.fallback_font


func _process(delta: float) -> void:
	_time += delta
	if is_visible_in_tree() and GD.on_screen(self):
		queue_redraw()


## How far the pickup's glow reaches (pixels in the world), matching what's drawn.
func glow_radius() -> float:
	return 36.0 * GD.screen_scale(self)


func _draw() -> void:
	var k := GD.screen_scale(self)
	var bob := sin(_time * 3.0) * 4.0 * k
	var spin := cos(_time * 3.0)   # turning in place, like a coin
	var glow := GD.rarity_colour(rarity)
	if kind == "tech":
		glow = Color("5aa0ff")
	elif kind == "secret":
		glow = Color("b266ff")
	elif kind == "repair":
		glow = Color("3dd17a")
	var pulse := 0.25 + 0.12 * sin(_time * (8.0 if kind == "secret" else 4.0))
	draw_circle(Vector2(0, bob), 36.0 * k, Color(glow, pulse))
	draw_set_transform(Vector2(0, bob), 0.0, Vector2(maxf(0.08, absf(spin)) * k, k))
	if kind == "repair":
		# A repair kit: a white case with a green cross.
		draw_rect(Rect2(Vector2(-16, -12), Vector2(32, 24)), Color("e9e6dc") if spin > 0.0 else Color("b8bec4"))
		draw_rect(Rect2(Vector2(-16, -12), Vector2(32, 24)), glow, false, 3.0)
		draw_rect(Rect2(Vector2(-3, -8), Vector2(6, 16)), glow)
		draw_rect(Rect2(Vector2(-8, -3), Vector2(16, 6)), glow)
	elif kind == "fleet":
		var rect := Rect2(Vector2(-13, -18), Vector2(26, 36))
		draw_rect(rect, Color("a4504a") if spin > 0.0 else Color("6a2f2a"))
		draw_rect(rect, glow, false, 3.0)
		draw_rect(Rect2(Vector2(-8, -12), Vector2(16, 10)), Color("e9e6dc"))
	else:
		# A chip: square body, pins on every side, a circuit mark in the middle.
		draw_rect(Rect2(Vector2(-14, -14), Vector2(28, 28)), Color("3e6690") if spin > 0.0 else Color("27415c"))
		draw_rect(Rect2(Vector2(-14, -14), Vector2(28, 28)), glow, false, 3.0)
		for i in 4:
			var o := -9.0 + i * 6.0
			draw_line(Vector2(o, -14), Vector2(o, -20), glow, 2.0)
			draw_line(Vector2(o, 14), Vector2(o, 20), glow, 2.0)
			draw_line(Vector2(-14, o), Vector2(-20, o), glow, 2.0)
			draw_line(Vector2(14, o), Vector2(20, o), glow, 2.0)
		draw_line(Vector2(-7, 0), Vector2(0, 0), Color("e9f6ff"), 2.0)
		draw_line(Vector2(0, 0), Vector2(0, -7), Color("e9f6ff"), 2.0)
		draw_line(Vector2(0, 0), Vector2(6, 6), Color("e9f6ff"), 2.0)
		draw_circle(Vector2(0, 0), 2.5, Color("e9f6ff"))
		draw_circle(Vector2(6, 6), 2.0, Color("e9f6ff"))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var label := "FLEET CARD" if kind == "fleet" else ("SECRET TECH" if kind == "secret" else ("REPAIR KIT" if kind == "repair" else "TECH"))
	var tw := _font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
	draw_set_transform(Vector2(0, -30.0 * k + bob), 0.0, Vector2(k, k))
	draw_string_outline(_font, Vector2(-tw / 2.0, 0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, 4, Color("0b0e14"))
	draw_string(_font, Vector2(-tw / 2.0, 0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, glow)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
