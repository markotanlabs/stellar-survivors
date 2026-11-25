extends Node2D
## A settled planet's health (v0.9.151: every owned planet has one, 3,000 like a
## Starbase). Enemies can attack it; when its health runs out the planet falls.
## Mars also fires its PD MAG at your ships (armed). Earth falling loses the run.
## Unsettled planets are left alone: alive only while someone owns the planet.

signal fallen(siege: Node2D)
signal hit(siege: Node2D)

const GD = preload("res://scripts/game_data.gd")
const Sfx = preload("res://scripts/sfx.gd")
const Explosion = preload("res://scripts/explosion.gd")
const RepairPlus = preload("res://scripts/repair_plus.gd")
const Projectile = preload("res://scripts/projectile.gd")

var faction := GD.Faction.SONS
var alive := true
var _plus_timer := 0.0
var health := GD.PLANET_HEALTH
var max_health := GD.PLANET_HEALTH
var armed := false   # Mars: fires a PD MAG
var radius := 9.0   # units, matches the planet
var planet_name := "Mars"
var planet: Dictionary = {}
var _since_hit := 99.0
var _shield_hits: Array = []
var _cooldown := 4.0
var _font: Font
var _charge_left := 0.0
var _charge_target: Node2D = null


func setup(pos_px: Vector2, planet_radius: float, owner_faction: int, name_text: String) -> void:
	position = pos_px
	radius = planet_radius
	faction = owner_faction
	planet_name = name_text
	_font = ThemeDB.fallback_font
	z_index = 3


func _ready() -> void:
	add_to_group("targets")
	faction = int(planet.get("owner", faction))
	alive = faction != GD.Faction.NEUTRAL


func take_damage(amount: float, attacker: Node2D = null) -> void:
	if not alive:
		return
	_since_hit = 0.0
	# Hard as Rock (planet trait, v0.9.219): every hit does half damage (grey numbers).
	if GD.planet_traits(planet).has("Hard as Rock"):
		amount *= GD.HARD_AS_ROCK
		GD.hit_hardened = true
	# Planetary shields soak hits first, flaring where they're struck.
	var shields := float(planet.get("shields", 0.0))
	if shields > 0.0:
		var soak := minf(shields, amount)
		planet["shields"] = shields - soak
		amount -= soak
		if attacker != null and is_instance_valid(attacker):
			_shield_hits.append([(attacker.position - position).angle(), 0.0])
	health -= amount
	planet["health"] = maxf(health, 0.0)
	queue_redraw()
	hit.emit(self)
	if health <= 0.0:
		alive = false
		for i in 4:
			var boom := Explosion.new()
			get_parent().add_child(boom)
			boom.setup(position + Vector2.RIGHT.rotated(randf() * TAU) * radius * GD.UNIT * 0.6, radius * GD.UNIT * 1.5)
		fallen.emit(self)
		if armed:
			queue_free()
		else:
			# Lies dormant until someone settles it again, then comes back at full health.
			health = max_health
			planet["health"] = health


func _process(delta: float) -> void:
	# Follows whoever owns the planet: settled planets can be attacked, empty ones can't.
	faction = int(planet.get("owner", faction))
	var owned := faction != GD.Faction.NEUTRAL
	if owned != alive:
		alive = owned
		health = max_health
		planet["health"] = health
		queue_redraw()
	if not alive:
		return
	_since_hit += delta
	var max_sh := float(planet.get("max_shields", 0.0))
	if max_sh > 0.0 and _since_hit > GD.SHIELD_DELAY:
		planet["shields"] = minf(max_sh, float(planet.get("shields", 0.0)) + GD.SHIELD_RECHARGE * 5.0 * delta)
	for h in _shield_hits:
		h[1] = float(h[1]) + delta
	while not _shield_hits.is_empty() and float(_shield_hits[0][1]) > 0.5:
		_shield_hits.pop_front()
	if not _shield_hits.is_empty():
		queue_redraw()
	if health < max_health and not _enemies_near():
		health = minf(max_health, health + max_health * GD.SELF_REPAIR * delta)
		planet["health"] = health
		queue_redraw()
		_repair_plus(delta, radius * GD.UNIT * 0.7)
	if _charge_left > 0.0:
		_charge_left -= delta
		if _charge_left <= 0.0 and is_instance_valid(_charge_target):
			_shoot(_charge_target)
		queue_redraw()
		return
	_cooldown -= delta
	if armed and _cooldown <= 0.0:
		_fire()
	if is_visible_in_tree() and (health < max_health or GD.show_full_names):
		queue_redraw()


func _enemies_near() -> bool:
	for child in get_parent().get_children():
		if child.is_in_group("ships") and child.get("alive") == true and GD.is_hostile(faction, int(child.get("faction"))):
			return true
	return false


func _fire() -> void:
	var weapon: Dictionary = GD.WEAPONS["pd_mag"]
	var reach := float(weapon["range"]) * GD.UNIT
	var best: Node2D = null
	var best_d := reach
	for t in get_tree().get_nodes_in_group("ships"):
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
		_cooldown = 1.0
		return
	_cooldown = float(weapon["cooldown"])
	_charge_left = float(weapon.get("charge", 0.0))
	_charge_target = best
	Sfx.play("mag_charge", self, -8.0)


func _shoot(target: Node2D) -> void:
	Sfx.play("mag_fire", self, 2.0)
	var weapon: Dictionary = GD.WEAPONS["pd_mag"]
	var shot := Projectile.new()
	get_parent().add_child(shot)
	shot.setup_free(position, target.position, float(weapon["damage"]), float(weapon["speed"]) * GD.UNIT, Color(String(weapon["colour"])), self, float(weapon["range"]) * GD.UNIT * 1.2)
	shot.set_style(false, false, false, true)


func _draw() -> void:
	for h in _shield_hits:
		var angle: float = h[0]
		var fade := 1.0 - float(h[1]) / 0.5
		var rr := radius * GD.UNIT * 1.2
		var blue := Color(0.36, 0.63, 1.0)
		draw_arc(Vector2.ZERO, rr, angle - 0.35, angle + 0.35, 12, Color(blue.lightened(0.5), 0.75 * fade), 5.0)
		draw_circle(Vector2.RIGHT.rotated(angle) * rr * 0.94, rr * 0.12 * fade, Color(blue.lightened(0.4), 0.25 * fade))
	if _charge_left > 0.0 and is_instance_valid(_charge_target):
		# The PD MAG charging: a glow on the planet's edge facing its target.
		var t := 1.0 - _charge_left / 2.5
		var edge := (_charge_target.position - position).normalized() * radius * GD.UNIT
		var glow := Color("b8e4ff")
		draw_circle(edge, 10.0 + 30.0 * t, Color(glow, 0.12 + 0.25 * t))
		draw_circle(edge, 4.0 + 12.0 * t, Color(glow.lightened(0.5), 0.5 + 0.5 * t))
	if not alive or health >= max_health:   # a full health bar is never shown
		return
	var k := GD.screen_scale(self)
	var r := radius * GD.UNIT
	var w := 160.0 * k
	var y := r + 44.0 * k   # under the planet's name banner (r + 12, 24 tall), not on top of it
	draw_rect(Rect2(Vector2(-w / 2.0, y), Vector2(w, 8.0 * k)), Color(0.02, 0.03, 0.05, 0.8))
	var bar := Color("5be38f") if faction == GD.Faction.UNE else Color("e5484d")   # yours green, theirs red
	draw_rect(Rect2(Vector2(-w / 2.0, y), Vector2(w * maxf(health, 0.0) / max_health, 8.0 * k)), bar)
	var label := "%s  %d / %d" % [planet_name.to_upper(), int(ceil(health)), int(max_health)]
	var tw := _font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
	draw_set_transform(Vector2(0, y + 28.0 * k), 0.0, Vector2(k, k))
	draw_string_outline(_font, Vector2(-tw / 2.0, 0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, 4, Color("0b0e14"))
	draw_string(_font, Vector2(-tw / 2.0, 0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, bar)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Green "+" signs rising while it repairs itself.
func _repair_plus(delta: float, spread_px: float) -> void:
	_plus_timer -= delta
	if _plus_timer > 0.0 or not is_visible_in_tree():
		return
	_plus_timer = 0.5
	var plus := RepairPlus.new()
	get_parent().add_child(plus)
	plus.setup(position + Vector2(randf_range(-spread_px, spread_px), -spread_px * 0.6))
