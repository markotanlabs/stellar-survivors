extends Node2D
## A hidden tech base: an asteroid with small glass-dome tech labs on it.
## It can be shot; destroying it gives a Tech reward.

signal base_destroyed(base: Node2D)

const GD = preload("res://scripts/game_data.gd")
const Explosion = preload("res://scripts/explosion.gd")
const RADIUS := 3.2   # units

var only_on_purpose := true   # stray shots pass through; focus fire or free fire breaks it
var faction := GD.Faction.NEUTRAL   # a derelict: ships only shoot it when you tell them to
var alive := true
var health := GD.TECH_BASE_HEALTH
var max_health := GD.TECH_BASE_HEALTH
var _shape := PackedVector2Array()
var _time := 0.0
var _font: Font


func setup(pos_px: Vector2) -> void:
	position = pos_px
	_font = ThemeDB.fallback_font
	for i in 9:
		var a := TAU * i / 9.0
		_shape.append(Vector2.RIGHT.rotated(a) * randf_range(0.8, 1.0))


func _ready() -> void:
	add_to_group("targets")


func take_damage(amount: float, _attacker: Node2D = null) -> void:
	if not alive:
		return
	# Rock armor, like every asteroid: 3 less per hit, never below 1 (grey numbers).
	if amount > 0.0 and GD.ROCK_ARMOR > 0.0:
		amount = maxf(amount - GD.ROCK_ARMOR, 1.0)
		GD.hit_hardened = true
	health -= amount
	queue_redraw()
	if health <= 0.0:
		alive = false
		var boom := Explosion.new()
		get_parent().add_child(boom)
		boom.setup(position, RADIUS * GD.UNIT * 3.0)
		base_destroyed.emit(self)
		queue_free()


func _process(delta: float) -> void:
	if is_visible_in_tree():
		_time += delta
		queue_redraw()


func _draw() -> void:
	var u := GD.UNIT
	var r := RADIUS * u
	var angle := _time * 0.05
	var pts := PackedVector2Array()
	for p in _shape:
		pts.append(p.rotated(angle) * r)
	draw_colored_polygon(pts, Color("6e665c"))
	var outline := pts.duplicate()
	outline.append(pts[0])
	draw_polyline(outline, Color("0b0e14"), 3.0)
	# Glass-dome tech labs: little domes with a cyan glow inside.
	var domes := [Vector2(-0.35, -0.2), Vector2(0.25, -0.35), Vector2(0.1, 0.3), Vector2(-0.3, 0.35)]
	for i in domes.size():
		var d: Vector2 = domes[i]
		var c := d.rotated(angle) * r
		var size := r * (0.2 if i % 2 == 0 else 0.15)
		var pulse := 0.55 + 0.25 * sin(_time * 2.0 + i)
		draw_circle(c, size, Color(0.56, 0.85, 1.0, 0.35))
		draw_circle(c, size * 0.5, Color(0.7, 0.95, 1.0, pulse))
		draw_arc(c, size, 0.0, TAU, 24, Color("e9f6ff"), 2.0)
		draw_arc(c + Vector2(-size * 0.3, -size * 0.3), size * 0.5, PI, PI * 1.5, 8, Color(1, 1, 1, 0.8), 2.0)
	var k := GD.screen_scale(self)
	if health < max_health:
		var w := 90.0 * k
		draw_rect(Rect2(Vector2(-w / 2.0, r + 8.0 * k), Vector2(w, 6.0 * k)), Color(0.02, 0.03, 0.05, 0.8))
		draw_rect(Rect2(Vector2(-w / 2.0, r + 8.0 * k), Vector2(w * health / max_health, 6.0 * k)), Color("e8c547"))
	var label := "Derelict tech lab" if GD.show_full_names else "???"
	var size_font := 16
	var tw := _font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, size_font).x
	draw_set_transform(Vector2(0, -r - 8.0 * k), 0.0, Vector2(k, k))
	draw_string_outline(_font, Vector2(-tw / 2.0, 0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, size_font, 4, Color("0b0e14"))
	draw_string(_font, Vector2(-tw / 2.0, 0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, size_font, Color("8fd1ff"))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
