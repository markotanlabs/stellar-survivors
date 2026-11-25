extends Node2D
## Drawn around the Kharkiv: the booster meter, the warp charge ring and the warp-in flash.

const GD = preload("res://scripts/game_data.gd")
const FLASH_TIME := 0.7

var boost := 1.0
var show_boost := false
var free_boost := false   # Tightened Logistics is keeping the meter full
var warp_progress := 0.0
var warp_locked := false
var _flash := 0.0


func flash() -> void:
	_flash = FLASH_TIME


func _process(delta: float) -> void:
	if _flash > 0.0:
		_flash = maxf(0.0, _flash - delta)
	queue_redraw()


func _draw() -> void:
	var k := GD.screen_scale(self)
	if show_boost:
		var w := 64.0 * k
		var h := 8.0 * k
		# Always below the Kharkiv's health bar (which sits at r + 6k, 5k tall), at any zoom.
		var top := GD.ship_pixels("capital") + 14.0 * k
		draw_rect(Rect2(Vector2(-w / 2.0, top), Vector2(w, h)), Color(0.02, 0.03, 0.05, 0.75))
		var fill := Color("3dd17a") if free_boost else (Color("8fb4e3") if boost >= 0.999 else Color("4c8dff"))
		draw_rect(Rect2(Vector2(-w / 2.0, top), Vector2(w * boost, h)), fill)
		draw_rect(Rect2(Vector2(-w / 2.0, top), Vector2(w, h)), Color("0b0e14"), false, 2.0 * k)
	if warp_progress > 0.0:
		var colour := Color("f4efe2") if warp_locked else Color("3dd17a")
		draw_arc(Vector2.ZERO, 80.0, 0.0, TAU, 64, Color(colour, 0.2), 4.0 * k)
		draw_arc(Vector2.ZERO, 80.0, -PI / 2.0, -PI / 2.0 + TAU * warp_progress, 64, colour, 5.0 * k)
	if _flash > 0.0:
		var t := 1.0 - _flash / FLASH_TIME
		draw_circle(Vector2.ZERO, 30.0 + 170.0 * t, Color(0.24, 0.82, 0.48, 0.45 * (1.0 - t)))
		draw_arc(Vector2.ZERO, 30.0 + 200.0 * t, 0.0, TAU, 64, Color(0.24, 0.82, 0.48, 1.0 - t), 4.0 * k)
