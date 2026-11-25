extends Node2D
## A big damage number that pops over a target when a heavy hit (100+) lands:
## white for your hits, red for damage you take.

const GD = preload("res://scripts/game_data.gd")
const LIFETIME := 1.1

var _text := ""
var _colour := Color.WHITE
var _age := 0.0
var _start := Vector2.ZERO
var _drift := 0.0
var _font: Font
var _size := 30


## tint: "bonus" (a weapon's bonus vs that ship type: yellow) or "hardened" (armor or
## shield hardening cut it: grey). Hardened wins if both.
func setup(pos_px: Vector2, amount: float, yours: bool, tint: String = "") -> void:
	# Spread out so a stream of hits doesn't stack into one blob.
	_start = pos_px + Vector2(randf_range(-26.0, 26.0), randf_range(-14.0, 10.0))
	position = _start
	_text = str(int(round(amount))) if amount >= 1.0 else str(snappedf(amount, 0.1))
	# Small hits small, big hits big.
	_size = 15 if amount < 10.0 else (19 if amount < 50.0 else (26 if amount < 200.0 else 38))
	_colour = Color("f4efe2") if yours else Color("ff5a5f")
	if tint == "hardened":
		_colour = Color("9aa3ab")
	elif tint == "bonus":
		_colour = Color("ffd23f")
	_drift = randf_range(-34.0, 34.0)
	_font = ThemeDB.fallback_font
	z_index = 30


func _process(delta: float) -> void:
	_age += delta
	if _age >= LIFETIME:
		queue_free()
		return
	var k := GD.screen_scale(self)
	var t := _age / LIFETIME
	position = _start + Vector2(_drift * t, -46.0 * t) * k
	queue_redraw()


func _draw() -> void:
	var k := GD.screen_scale(self)
	var t := _age / LIFETIME
	# Pop in big, settle, then fade.
	var pop := 1.5 - 0.5 * clampf(t / 0.15, 0.0, 1.0)
	var alpha := 1.0 if t < 0.6 else 1.0 - (t - 0.6) / 0.4
	var size := _size
	var w := _font.get_string_size(_text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(k, k) * pop)
	draw_string_outline(_font, Vector2(-w / 2.0, 0), _text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 7, Color(0.04, 0.05, 0.08, alpha))
	draw_string(_font, Vector2(-w / 2.0, 0), _text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(_colour, alpha))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
