extends Node2D
## Afterburner Wake: a patch of burning exhaust left behind a boosting fleet.
## Enemy ships inside take a burn tick every 0.4 s until it dies down.

const GD = preload("res://scripts/game_data.gd")

var radius := 2.2   # units
var _age := 0.0
var _tick := 0.0
var _seed := 0.0


func setup(pos_px: Vector2) -> void:
	position = pos_px
	_seed = randf() * 10.0
	z_index = 1


func _process(delta: float) -> void:
	_age += delta
	if _age >= GD.WAKE_SECONDS:
		queue_free()
		return
	_tick -= delta
	if _tick <= 0.0:
		_tick = 0.4
		_burn()
	queue_redraw()


func _burn() -> void:
	var view := get_parent()
	var nearby: Array = view.call("targets_near", position) if view.has_method("targets_near") else get_tree().get_nodes_in_group("ships")
	var reach := radius * GD.UNIT
	for t in nearby:
		var ship := t as Node2D
		if ship == null or not ship.is_in_group("ships") or not (ship.get("alive") == true):
			continue
		if not GD.is_hostile(GD.Faction.UNE, int(ship.get("faction"))):
			continue
		if ship.position.distance_to(position) <= reach + GD.ship_pixels(String(ship.get("type_id"))) * 0.5:
			ship.call("take_damage", GD.WAKE_DAMAGE, null)
			GD.damage_dealt += GD.WAKE_DAMAGE


func _draw() -> void:
	var fade := 1.0 - _age / GD.WAKE_SECONDS
	var r := radius * GD.UNIT * (0.8 + 0.2 * sin(_age * 9.0 + _seed))
	draw_circle(Vector2.ZERO, r, Color(1.0, 0.45, 0.1, 0.18 * fade))
	draw_circle(Vector2.ZERO, r * 0.6, Color(1.0, 0.7, 0.25, 0.25 * fade))
	draw_circle(Vector2(sin(_age * 5.0 + _seed), cos(_age * 4.0)) * r * 0.25, r * 0.25, Color(1.0, 0.9, 0.6, 0.35 * fade))
