extends Node2D
## Swarm Missile (prototype): one of a salvo. The launcher's radar sweep has already
## picked its target. It fans out to the side first, then curves in with soft homing,
## so a hard turn or a boost can make some of them miss. Small blast on contact only;
## out of fuel it fizzles. One hit from anything shoots it down.

const GD = preload("res://scripts/game_data.gd")
const Explosion = preload("res://scripts/explosion.gd")
const Smoke = preload("res://scripts/smoke.gd")
const DamageNumber = preload("res://scripts/damage_number.gd")
const Sfx = preload("res://scripts/sfx.gd")

const FAN_TIME := 0.35      # seconds flying straight out to the side before homing
const RAMP_TIME := 0.5      # seconds to reach full speed
const TURN_RATE := 2.6      # radians/s: soft homing, dodgeable
const RETARGET := 10.0      # units
const FUSE := 0.6           # units: proximity fuse beyond the hull

var wild := false   # fired with nothing locked: flies its arc a moment longer, then hunts
var _wander := 0.0
# Snake flight: each missile weaves side to side around its course, out of step with
# the others, and straightens up for the last stretch so it still lands.
const SNAKE_RATE := 7.5     # radians of wave per second
const SNAKE_SWING := 0.55   # radians either side of its course at full swing
var _snake_phase := randf() * TAU
var _move := Vector2.RIGHT  # the way it's actually flying this frame (course + weave)
# About 1 missile in 100 is a dud: partway out its guidance fails, it spins wildly
# out of control trailing smoke, and blows up on its own a moment later.
const DUD_CHANCE := 0.01
var _dud_at := -1.0     # flight time when it goes haywire (-1: a good missile)
var _dud_fuse := 0.0    # seconds of spinning before it blows
var _spin := 0.0        # radians per second, building up
var _seek := 0.0   # seconds until a lost missile looks for a new target
var weapon_name := ""   # for the shooter's per-weapon damage record
var faction := -1
var alive := true
var radius := 0.3
var target: Node2D = null
var damage := 25.0
var _splash := 1.2 * GD.UNIT
var _top_speed := 24.0 * GD.UNIT
var _speed := 0.0
var _fuel := 2.8
var _delay := 0.0           # ripple-fire: waits in the tube for this long
var _dir := Vector2.RIGHT
var _shooter: Node2D = null
var _mount := Vector2.ZERO
var _colour := Color(0.62, 0.88, 1.0)
var _age := 0.0
var _smoke_t := 0.0
var _launched := false


func setup(shooter: Node2D, mount_px: Vector2, out_dir: Vector2, new_target: Node2D, weapon: Dictionary, bonus_damage: float, delay: float) -> void:
	_shooter = shooter
	_mount = mount_px
	position = shooter.position + mount_px
	faction = int(shooter.get("faction"))
	target = new_target
	damage = float(weapon["damage"]) + bonus_damage
	weapon_name = String(weapon.get("name", ""))
	_top_speed = float(weapon["speed"]) * GD.UNIT
	_splash = float(weapon.get("splash", 1.2)) * GD.UNIT
	_fuel = float(weapon.get("fuel", 2.8))
	_colour = Color(String(weapon["colour"]))
	_dir = out_dir.normalized()
	_delay = delay
	visible = false
	z_index = 3


func radius_px() -> float:
	return radius * GD.UNIT


func take_damage(_amount: float, _attacker: Node2D = null) -> void:
	if alive and _launched:
		_fizzle()


func _launch() -> void:
	_launched = true
	visible = true
	add_to_group("targets")
	add_to_group("ordnance")
	_speed = _top_speed * 0.5
	Sfx.play("launch", self, -16.0, 0.2)
	if randf() < DUD_CHANCE:
		_dud_at = randf_range(0.3, 1.2)
		_dud_fuse = randf_range(0.8, 1.5)
		_spin = randf_range(6.0, 9.0) * (1.0 if randf() < 0.5 else -1.0)


func _process(delta: float) -> void:
	if not alive:
		return
	if not _launched:
		# Still in the tube: ride along with the ship.
		if _shooter == null or not is_instance_valid(_shooter) or _shooter.get("alive") != true:
			queue_free()
			return
		position = _shooter.position + _mount
		_delay -= delta
		if _delay <= 0.0:
			_launch()
		return
	_age += delta
	_fuel -= delta
	if _dud_at >= 0.0 and _age >= _dud_at:
		_go_haywire(delta)
		return
	if _fuel <= 0.0:
		_fizzle()
		return
	var view := get_parent()
	if target == null or not is_instance_valid(target) or target.get_parent() != view or target.get("alive") != true:
		target = null
		_seek -= delta
		if wild and _age < 0.6:
			pass   # manual fire: hold the arc a moment before hunting
		elif _seek <= 0.0:
			_seek = 0.1   # performance: a lost missile looks around ten times a second
			target = _find_new(position + _dir * RETARGET * 0.5 * GD.UNIT, RETARGET * GD.UNIT)
	_speed = lerpf(_top_speed * 0.5, _top_speed, clampf(_age / RAMP_TIME, 0.0, 1.0))
	if target != null and _age > FAN_TIME:
		var want := (target.position - position).normalized()
		# Soft at first, tighter the longer it flies, so it doesn't circle its target.
		var turn := TURN_RATE * (1.0 + 1.5 * clampf((_age - FAN_TIME) / 1.2, 0.0, 1.0))
		_dir = _dir.rotated(clampf(_dir.angle_to(want), -turn * delta, turn * delta))
	# The snake: swing either side of the course, less once it's out of the tube and
	# fading out over the last few units to the target.
	var swing := SNAKE_SWING * clampf((_age - 0.1) / 0.3, 0.0, 1.0)
	if target != null and is_instance_valid(target):
		swing *= clampf((position.distance_to(target.position) / GD.UNIT - 2.0) / 6.0, 0.0, 1.0)
	_move = _dir.rotated(sin(_age * SNAKE_RATE + _snake_phase) * swing)
	position += _move * _speed * delta
	_smoke_t -= delta
	# Performance: a thinner trail, and none at all off screen.
	if _smoke_t <= 0.0 and is_visible_in_tree() and GD.on_screen(self):
		_smoke_t = 0.12
		var puff := Smoke.new()
		view.add_child(puff)
		puff.setup(position - _move * 6.0, randf_range(1.5, 2.5), Color(0.8, 0.8, 0.82, 0.3), randf_range(0.4, 0.7), Vector2.ZERO, 1.4)
	var nearby: Array = view.call("targets_near", position) if view.has_method("targets_near") else []
	for n in nearby:
		var node := n as Node2D
		if not _is_enemy(node) or node.is_in_group("ordnance"):
			continue
		# Proximity fuse: goes off a little short of the hull.
		if position.distance_to(node.position) <= _hit_radius(node) + FUSE * GD.UNIT:
			_explode(node)
			return
	if GD.on_screen(self):
		queue_redraw()


func _is_enemy(node: Node2D) -> bool:
	if node == null or not is_instance_valid(node) or node.get_parent() != get_parent() or node.get("alive") != true:
		return false
	var f = node.get("faction")
	if f == null or not GD.is_hostile(faction, int(f)):
		return false
	return node.get("only_on_purpose") != true


func _find_new(from: Vector2, reach_px: float) -> Node2D:
	var best: Node2D = null
	var best_d := reach_px
	for n in get_tree().get_nodes_in_group("ships"):
		var node := n as Node2D
		if not _is_enemy(node) or not node.visible:
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


## Full damage to what it hit, half to anything else in the small blast.
func _explode(struck: Node2D) -> void:
	alive = false
	var view := get_parent()
	var source: Node2D = _shooter if is_instance_valid(_shooter) else null
	var nearby: Array = view.call("targets_near", position) if view.has_method("targets_near") else []
	for n in nearby:
		var node := n as Node2D
		if not _is_enemy(node) or node.is_in_group("ordnance") or not node.has_method("take_damage"):
			continue
		var dealt := damage
		if node != struck:
			if position.distance_to(node.position) > _splash + _hit_radius(node) * 0.5:
				continue
			dealt *= 0.5
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
	boom.setup(position, _splash * 0.6)
	queue_free()


## A dud: guidance gone, it corkscrews about, faster and faster, then blows up where it
## ends up (still hurting any enemy caught in the blast).
func _go_haywire(delta: float) -> void:
	target = null
	_spin *= 1.0 + 1.8 * delta
	_dir = _dir.rotated(_spin * delta)
	_move = _dir
	_speed = move_toward(_speed, _top_speed * 0.45, _top_speed * delta)
	position += _dir * _speed * delta
	_smoke_t -= delta
	if _smoke_t <= 0.0 and is_visible_in_tree():
		_smoke_t = 0.03
		var puff := Smoke.new()
		get_parent().add_child(puff)
		puff.setup(position - _dir * 5.0, randf_range(2.0, 3.5), Color(0.35, 0.33, 0.32, 0.45), randf_range(0.6, 1.0), Vector2.ZERO, 1.6)
	queue_redraw()
	if _age >= _dud_at + _dud_fuse:
		_explode(null)


## Shot down or out of fuel: a grey puff, so a miss doesn't look like a hit.
func _fizzle() -> void:
	alive = false
	var puff := Smoke.new()
	get_parent().add_child(puff)
	puff.setup(position, 5.0, Color(0.7, 0.7, 0.72, 0.5), 0.6, Vector2.ZERO, 1.2)
	queue_free()


func _draw() -> void:
	if not _launched:
		return
	# Its lock stays on the target until it lands: green for yours, red for theirs.
	if target != null and is_instance_valid(target):
		var lock_col := Color(0.35, 1.0, 0.5, 0.55) if faction == GD.Faction.UNE else Color(1.0, 0.25, 0.2, 0.6)
		var at := target.position - position
		var rr := _hit_radius(target) + 6.0
		draw_arc(at, rr, 0.0, TAU, 20, lock_col, 2.0)
		draw_line(at + Vector2(rr - 4.0, 0), at + Vector2(rr + 4.0, 0), lock_col, 2.0)
		draw_line(at - Vector2(rr - 4.0, 0), at - Vector2(rr + 4.0, 0), lock_col, 2.0)
		draw_line(at + Vector2(0, rr - 4.0), at + Vector2(0, rr + 4.0), lock_col, 2.0)
		draw_line(at - Vector2(0, rr - 4.0), at - Vector2(0, rr + 4.0), lock_col, 2.0)
	draw_set_transform(Vector2.ZERO, _move.angle(), Vector2.ONE)
	var flame := 4.0 + randf() * 4.0
	draw_colored_polygon(PackedVector2Array([Vector2(-5, -1.5), Vector2(-5 - flame, 0), Vector2(-5, 1.5)]), Color(_colour.r, _colour.g, _colour.b, 0.85))
	draw_rect(Rect2(-5, -1.5, 9, 3), Color(0.82, 0.84, 0.88))
	draw_circle(Vector2(4, 0), 1.5, Color(0.82, 0.84, 0.88))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
