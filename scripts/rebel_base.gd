extends Node2D
## The Rebel Rock: the Roid Rebels' giant asteroid base, with a Mini MAG and 8 Gatlings.
## The first time it's hit, every Rebel in the system attacks, and the Gatlings wake up
## and fire across the whole system.

signal first_hit(attacker: Node2D)
signal base_destroyed(base: Node2D)

const GD = preload("res://scripts/game_data.gd")
const Sfx = preload("res://scripts/sfx.gd")
const Explosion = preload("res://scripts/explosion.gd")
const Projectile = preload("res://scripts/projectile.gd")
const PlanetGun = preload("res://scripts/planet_gun.gd")

var faction := GD.Faction.REBELS
var alive := true
var health := 2400.0
var max_health := 2400.0
var radius := 6.0   # units
var _shape := PackedVector2Array()
var _alarmed := false
var _cooldown := 3.0
var _time := 0.0
var _font: Font
var _charge_left := 0.0
var _charge_target: Node2D = null
var _guns: Array = []


func setup(pos_px: Vector2, shape: PackedVector2Array) -> void:
	position = pos_px
	_shape = shape
	_font = ThemeDB.fallback_font


func _ready() -> void:
	add_to_group("targets")
	call_deferred("_mount_guns")


## 8 Gatlings around the rock, dormant until it's attacked.
func _mount_guns() -> void:
	for i in 8:
		var gun := PlanetGun.new()
		get_parent().add_child(gun)
		gun.setup(position + Vector2.RIGHT.rotated(TAU * i / 8.0) * radius * GD.UNIT * 0.85, faction, "rock_gatling")
		gun.active = false
		_guns.append(gun)


func take_damage(amount: float, attacker: Node2D = null) -> void:
	if not alive:
		return
	if not _alarmed:
		_alarmed = true
		first_hit.emit(attacker)
		for gun in _guns:
			if is_instance_valid(gun):
				gun.active = true
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
		boom.setup(position, radius * GD.UNIT * 3.0)
		base_destroyed.emit(self)
		for gun in _guns:
			if is_instance_valid(gun):
				gun.queue_free()
		queue_free()


func _process(delta: float) -> void:
	_time += delta
	if _charge_left > 0.0:
		_charge_left -= delta
		if _charge_left <= 0.0 and is_instance_valid(_charge_target):
			_shoot(_charge_target)
		return_draw()
		return
	_cooldown -= delta
	if _cooldown <= 0.0:
		_fire_mini_mag()
	if is_visible_in_tree():
		queue_redraw()


func _fire_mini_mag() -> void:
	var weapon: Dictionary = GD.WEAPONS["mini_mag"]
	var reach := float(weapon["range"]) * GD.UNIT
	var best: Node2D = null
	var best_d := reach
	for t in get_tree().get_nodes_in_group("targets"):
		var node := t as Node2D
		if node == null or node.get_parent() != get_parent() or not node.visible:
			continue
		if not (node.get("alive") == true) or not GD.is_hostile(faction, int(node.get("faction"))):
			continue
		var d := position.distance_to(node.position)
		if d <= best_d:
			best_d = d
			best = node
	if best == null:
		return
	_cooldown = float(weapon["cooldown"])
	# Charge up first: a glow builds on the rock, so you can see the shot coming.
	_charge_left = float(weapon.get("charge", 0.0))
	_charge_target = best
	Sfx.play("mag_charge", self, -10.0)
	if _charge_left <= 0.0:
		_shoot(best)


func _shoot(target: Node2D) -> void:
	Sfx.play("mini_mag_fire", self)
	var weapon: Dictionary = GD.WEAPONS["mini_mag"]
	var shot := Projectile.new()
	get_parent().add_child(shot)
	shot.setup_free(position, target.position, float(weapon["damage"]), float(weapon["speed"]) * GD.UNIT, Color(String(weapon["colour"])), self, float(weapon["range"]) * GD.UNIT * 1.3)
	shot.set_style(false, false, true, true)


func return_draw() -> void:
	if is_visible_in_tree():
		queue_redraw()


func _draw() -> void:
	var u := GD.UNIT
	var r := radius * u
	var pts := PackedVector2Array()
	for p in _shape:
		pts.append(p.rotated(_time * 0.05) * r)
	draw_colored_polygon(pts, Color("6e5a48"))
	var outline := pts.duplicate()
	outline.append(pts[0])
	draw_polyline(outline, Color("0b0e14"), 3.0)
	draw_circle(Vector2(-r * 0.3, -r * 0.2), r * 0.25, Color("4a3a2e"))
	draw_circle(Vector2(r * 0.35, r * 0.3), r * 0.18, Color("4a3a2e"))
	var k := GD.screen_scale(self)
	if _charge_left > 0.0:
		var t := 1.0 - _charge_left / 2.5
		var glow := Color("8fd1ff")
		draw_circle(Vector2.ZERO, r * (0.3 + 0.4 * t), Color(glow, 0.12 + 0.25 * t))
		draw_circle(Vector2.ZERO, r * (0.1 + 0.15 * t), Color(glow.lightened(0.5), 0.5 + 0.5 * t))
	if health < max_health:
		var w := 140.0 * k
		draw_rect(Rect2(Vector2(-w / 2.0, r + 10.0 * k), Vector2(w, 7.0 * k)), Color(0.02, 0.03, 0.05, 0.8))
		draw_rect(Rect2(Vector2(-w / 2.0, r + 10.0 * k), Vector2(w * health / max_health, 7.0 * k)), Color("e5484d"))
	var label := "REBEL ROCK  %d" % int(ceil(health))
	var tw := _font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
	draw_set_transform(Vector2(0, -r - 10.0 * k), 0.0, Vector2(k, k))
	draw_string_outline(_font, Vector2(-tw / 2.0, 0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, 4, Color("0b0e14"))
	draw_string(_font, Vector2(-tw / 2.0, 0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("e5484d"))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
