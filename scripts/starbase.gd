extends Node2D
## A Starbase as something that can be shot: 1,500 health and a health bar. Its body is
## drawn by the system view; when it's destroyed, the view removes it from the system.

signal hit(base: Node2D)
signal base_destroyed(base: Node2D)

const GD = preload("res://scripts/game_data.gd")
const Explosion = preload("res://scripts/explosion.gd")
const RepairPlus = preload("res://scripts/repair_plus.gd")

var faction := GD.Faction.UNE
var alive := true
var _plus_timer := 0.0
var health := GD.STARBASE_HEALTH
var max_health := GD.STARBASE_HEALTH
var radius := 1.3 * GD.STATION_SCALE    # units (stations 25% bigger, v0.9.137)
var structure: Dictionary = {}


func setup(st: Dictionary) -> void:
	structure = st
	faction = int(st["faction"])
	position = Vector2(st["pos"]) * GD.UNIT
	max_health = float(st.get("health", GD.STARBASE_HEALTH))
	health = max_health
	z_index = 2


func _ready() -> void:
	add_to_group("targets")


func take_damage(amount: float, _attacker: Node2D = null) -> void:
	if not alive:
		return
	health -= maxf(amount - GD.STARBASE_HARDNESS, 0.0)   # armor hardness shaves every hit
	structure["hp"] = health
	hit.emit(self)
	queue_redraw()
	if health <= 0.0:
		alive = false
		for i in 3:
			var boom := Explosion.new()
			get_parent().add_child(boom)
			boom.setup(position + Vector2(randf_range(-20, 20), randf_range(-20, 20)), 60.0)
		base_destroyed.emit(self)
		queue_free()


var _enemy_check := 0.0
var _enemies_cached := false


func _process(delta: float) -> void:
	# Repairs itself 5% a second while no enemy ships are in the system.
	_enemy_check -= delta
	if _enemy_check <= 0.0:
		_enemy_check = 0.5   # performance: look around twice a second, not every frame
		_enemies_cached = _enemies_near()
	if health < max_health and not _enemies_cached:
		health = minf(max_health, health + max_health * GD.SELF_REPAIR * delta)
		structure["hp"] = health
		_repair_plus(delta, radius * GD.UNIT)
	if is_visible_in_tree() and (health < max_health or GD.show_full_names):
		queue_redraw()


func _enemies_near() -> bool:
	for child in get_parent().get_children():
		if child.is_in_group("ships") and child.get("alive") == true and GD.is_hostile(faction, int(child.get("faction"))):
			return true
	return false


func _draw() -> void:
	if health >= max_health:   # a full health bar is never shown
		return
	var k := GD.screen_scale(self)
	var w := 90.0 * k
	var y := radius * GD.UNIT + 10.0 * k
	draw_rect(Rect2(Vector2(-w / 2.0, y), Vector2(w, 6.0 * k)), Color(0.02, 0.03, 0.05, 0.8))
	var colour := Color("3dd17a") if faction == GD.Faction.UNE else Color("e5484d")
	draw_rect(Rect2(Vector2(-w / 2.0, y), Vector2(w * maxf(health, 0.0) / max_health, 6.0 * k)), colour)


## Green "+" signs rising while it repairs itself.
func _repair_plus(delta: float, spread_px: float) -> void:
	_plus_timer -= delta
	if _plus_timer > 0.0 or not is_visible_in_tree():
		return
	_plus_timer = 0.5
	var plus := RepairPlus.new()
	get_parent().add_child(plus)
	plus.setup(position + Vector2(randf_range(-spread_px, spread_px), -spread_px * 0.6))
