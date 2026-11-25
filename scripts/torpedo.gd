extends Node2D
## Torpedo (prototype): a slow launch, then a long homing run at just under a boosted
## Kharkiv's top speed. Turns slowly, so you can break away with a boost or a hard turn.
## Explodes only on contact with an enemy: full damage at the centre, less towards the
## edge of the blast. Runs out of fuel and it fizzles harmlessly.
## It's a real object with a little health, so PDCs and Gatlings can shoot it down.

const GD = preload("res://scripts/game_data.gd")
const Explosion = preload("res://scripts/explosion.gd")
const Smoke = preload("res://scripts/smoke.gd")
const DamageNumber = preload("res://scripts/damage_number.gd")
const Sfx = preload("res://scripts/sfx.gd")

const LAUNCH_SPEED := 5.0   # units/s as it leaves the tube
const LAUNCH_TIME := 1.4    # seconds to reach full speed
const TURN_RATE := 1.8      # radians/s: wide turns, so it can be dodged
const RETARGET := 18.0      # units: looks for a new ship this close if its target dies
const HEALTH := 8.0

var _seek := 0.0   # seconds until a lost missile looks for a new target
var weapon_name := ""   # for the shooter's per-weapon damage record
var faction := -1
var alive := true
var radius := 0.5            # units, for the hit grid
var target: Node2D = null
var damage := 500.0
var _edge := 0.25            # share of the damage at the very edge of the blast
var _splash := 5.0 * GD.UNIT
var _top_speed := 21.5 * GD.UNIT
var _speed := LAUNCH_SPEED * GD.UNIT
var _fuel := 9.0
var _dir := Vector2.RIGHT
var _health := HEALTH
var _shooter: Node2D = null
var _colour := Color(1.0, 0.42, 0.24)
var _age := 0.0
var _smoke_t := 0.0
var _beep_t := 0.6


func setup(from_px: Vector2, aim_px: Vector2, new_target: Node2D, weapon: Dictionary, shooter: Node2D, bonus_damage: float) -> void:
	position = from_px
	target = new_target
	_shooter = shooter
	faction = int(shooter.get("faction")) if shooter != null else -1
	damage = float(weapon["damage"]) + bonus_damage
	weapon_name = String(weapon.get("name", ""))
	_top_speed = float(weapon["speed"]) * GD.UNIT
	_splash = float(weapon.get("splash", 5.0)) * GD.UNIT
	_edge = float(weapon.get("edge", 0.25))
	_fuel = float(weapon.get("fuel", 9.0))
	_colour = Color(String(weapon["colour"]))
	var to := aim_px - from_px
	_dir = to.normalized() if to.length() > 1.0 else Vector2.RIGHT
	z_index = 3


func _ready() -> void:
	add_to_group("targets")
	add_to_group("ordnance")
	Sfx.play("launch", self, -4.0)


func radius_px() -> float:
	return radius * GD.UNIT


## Point defence and stray rounds can kill it before it lands.
func take_damage(amount: float, _attacker: Node2D = null) -> void:
	if not alive:
		return
	_health -= amount
	if _health <= 0.0:
		_fizzle(16.0)


func _process(delta: float) -> void:
	if not alive:
		return
	_age += delta
	_fuel -= delta
	if _fuel <= 0.0:
		_fizzle(22.0)
		return
	var view := get_parent()
	# Lost its target: pick up the nearest enemy ship close by, or run on straight.
	if target == null or not is_instance_valid(target) or target.get_parent() != view or target.get("alive") != true:
		target = null
		_seek -= delta
		if _seek <= 0.0:
			_seek = 0.1   # performance: a lost missile looks around ten times a second
			target = _find_ship(position + _dir * RETARGET * 0.5 * GD.UNIT, RETARGET * GD.UNIT)
	# Slow out of the tube, then up to full speed.
	var t := clampf(_age / LAUNCH_TIME, 0.0, 1.0)
	_speed = lerpf(LAUNCH_SPEED * GD.UNIT, _top_speed, t * t)
	if target != null:
		var want := (target.position - position).normalized()
		var turn := TURN_RATE * (0.5 + 0.5 * t)
		_dir = _dir.rotated(clampf(_dir.angle_to(want), -turn * delta, turn * delta))
		_beep(delta)
	position += _dir * _speed * delta
	_smoke_t -= delta
	if _smoke_t <= 0.0 and is_visible_in_tree():
		_smoke_t = 0.03
		var puff := Smoke.new()
		view.add_child(puff)
		puff.setup(position - _dir * 14.0, randf_range(3.0, 5.0), Color(0.78, 0.76, 0.74, 0.4), randf_range(0.8, 1.3), Vector2.ZERO, 1.8)
	# Contact with an enemy: boom.
	var nearby: Array = view.call("targets_near", position) if view.has_method("targets_near") else []
	for n in nearby:
		var node := n as Node2D
		if not _is_enemy(node) or node.is_in_group("ordnance"):
			continue
		if position.distance_to(node.position) <= _hit_radius(node) + 6.0:
			_explode()
			return
	queue_redraw()


## Beeps faster the closer it gets, when it's coming for one of yours.
func _beep(delta: float) -> void:
	if int(target.get("faction")) != GD.Faction.UNE or not is_visible_in_tree():
		return
	_beep_t -= delta
	if _beep_t <= 0.0:
		var d := position.distance_to(target.position) / GD.UNIT
		_beep_t = lerpf(0.12, 0.7, clampf(d / 30.0, 0.0, 1.0))
		Sfx.play("blip", self, -6.0, 0.0)


func _is_enemy(node: Node2D) -> bool:
	if node == null or not is_instance_valid(node) or node.get_parent() != get_parent() or node.get("alive") != true:
		return false
	var f = node.get("faction")
	if f == null or not GD.is_hostile(faction, int(f)):
		return false
	return node.get("only_on_purpose") != true


func _find_ship(from: Vector2, reach_px: float) -> Node2D:
	var best: Node2D = null
	var best_d := reach_px
	for n in get_tree().get_nodes_in_group("ships"):
		var node := n as Node2D
		if not _is_enemy(node) or not node.visible:
			continue
		if faction == GD.Faction.UNE and node.get("concealed") == true:
			continue
		var d := from.distance_to(node.position)
		if d <= best_d:
			best_d = d
			best = node
	return best


func _hit_radius(node: Node2D) -> float:
	if node.has_method("radius_px"):
		return float(node.call("radius_px"))
	var type_id = node.get("type_id")
	if type_id != null:
		return GD.ship_pixels(String(type_id)) * 0.8
	var r = node.get("radius")
	if r != null:
		return float(r) * GD.UNIT
	return 2.0 * GD.UNIT


## The big one: full damage at the centre, falling off to the edge of the blast.
func _explode() -> void:
	if not alive:
		return
	alive = false
	var view := get_parent()
	var source: Node2D = _shooter if is_instance_valid(_shooter) else null
	var nearby: Array = view.call("targets_near", position, 2) if view.has_method("targets_near") else []
	for n in nearby:
		var node := n as Node2D
		if not _is_enemy(node) or node.is_in_group("ordnance") or not node.has_method("take_damage"):
			continue
		var d := maxf(0.0, position.distance_to(node.position) - _hit_radius(node) * 0.5)
		if d > _splash:
			continue
		var dealt := damage * lerpf(1.0, _edge, d / _splash)
		GD.hit_weapon = weapon_name
		GD.hit_hardened = false
		node.call("take_damage", dealt, source)
		GD.hit_weapon = ""
		var tint := "hardened" if GD.hit_hardened else ""
		if faction == GD.Faction.UNE:
			GD.damage_dealt += dealt
		if GD.show_damage_numbers and dealt >= GD.DAMAGE_NUMBER_MIN and (faction == GD.Faction.UNE or GD.show_damage_taken):
			var number := DamageNumber.new()
			view.add_child(number)
			number.setup(node.position, dealt, faction == GD.Faction.UNE, tint)
	var boom := Explosion.new()
	view.add_child(boom)
	boom.setup(position, _splash * 0.72)
	var core := Explosion.new()
	view.add_child(core)
	core.setup(position, _splash * 0.35)
	for i: int in 10:
		var puff := Smoke.new()
		view.add_child(puff)
		var off := Vector2.RIGHT.rotated(randf() * TAU) * randf_range(0.2, 0.8) * _splash
		puff.setup(position + off, randf_range(10.0, 18.0), Color(0.5, 0.45, 0.42, 0.45), randf_range(1.2, 2.0), off * 0.3, 1.5)
	queue_free()


## Shot down or out of fuel: a small pop, no damage.
func _fizzle(size_px: float) -> void:
	if not alive:
		return
	alive = false
	var pop := Explosion.new()
	get_parent().add_child(pop)
	pop.setup(position, size_px)
	queue_free()


func _draw() -> void:
	var pulse := 0.5 + 0.5 * sin(_age * 14.0)
	# Lock-on: a pulsing reticle on what it's chasing (red when it's coming for you).
	if target != null and is_instance_valid(target):
		var mine := int(target.get("faction")) == GD.Faction.UNE
		var lock_col := Color(1.0, 0.2, 0.15) if mine else Color(1.0, 0.6, 0.25)
		lock_col.a = 0.35 + 0.45 * pulse
		var at := target.position - position
		var rr := _hit_radius(target) + 10.0 + 4.0 * pulse
		for k: int in 4:
			var a: float = PI * 0.25 + float(k) * PI * 0.5
			var c := at + Vector2.RIGHT.rotated(a) * rr
			draw_line(c, c + Vector2.RIGHT.rotated(a + PI * 0.75) * 9.0, lock_col, 2.0)
			draw_line(c, c + Vector2.RIGHT.rotated(a - PI * 0.75) * 9.0, lock_col, 2.0)
		if mine:
			var faint := lock_col
			faint.a = 0.12 + 0.1 * pulse
			draw_dashed_line(Vector2.ZERO, at, faint, 1.0, 8.0)
		# Coming for your Kharkiv: a huge red "!" riding on the torpedo, the same size on
		# screen at any zoom, so you know to boost or turn now.
		if mine and str(target.get("type_id")) == "capital":
			var k := GD.screen_scale(self)
			var font := ThemeDB.fallback_font
			var fs := 64
			var throb := 1.0 + 0.18 * pulse
			var w := font.get_string_size("!", HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			draw_set_transform(Vector2(0, -26.0 * k), 0.0, Vector2(k, k) * throb)
			draw_circle(Vector2(0, -22), 30.0, Color(1.0, 0.15, 0.1, 0.18 + 0.2 * pulse))
			draw_string_outline(font, Vector2(-w / 2.0, 0), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 10, Color(0.05, 0.0, 0.0, 0.95))
			draw_string(font, Vector2(-w / 2.0, 0), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1.0, 0.25 + 0.3 * pulse, 0.2))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# The torpedo: a long dark body, a hot warhead glow and a flickering engine.
	draw_set_transform(Vector2.ZERO, _dir.angle(), Vector2.ONE)
	var flame := 8.0 + randf() * 6.0 * clampf(_age / LAUNCH_TIME, 0.3, 1.0)
	draw_colored_polygon(PackedVector2Array([Vector2(-9, -2.5), Vector2(-9 - flame, 0), Vector2(-9, 2.5)]), Color(1.0, 0.75, 0.35, 0.85))
	draw_circle(Vector2(-9, 0), 4.0, Color(1.0, 0.55, 0.2, 0.35))
	draw_rect(Rect2(-10, -3, 18, 6), Color(0.32, 0.34, 0.38))
	draw_circle(Vector2(8, 0), 3.0, Color(0.32, 0.34, 0.38))
	draw_line(Vector2(-10, -3), Vector2(-13, -6), Color(0.45, 0.47, 0.5), 2.0)
	draw_line(Vector2(-10, 3), Vector2(-13, 6), Color(0.45, 0.47, 0.5), 2.0)
	draw_circle(Vector2(8, 0), 7.0 + 3.0 * pulse, Color(_colour.r, _colour.g, _colour.b, 0.18 + 0.2 * pulse))
	draw_circle(Vector2(8, 0), 2.2, Color(1.0, 0.85, 0.6))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
