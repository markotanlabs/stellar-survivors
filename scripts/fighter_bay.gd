extends Node2D
## A Starbase Fighter Bay: holds one group of 3 VALK Zero fighters. When an enemy ship
## comes within range, every fighter on board launches at it. Fighters fight for a
## sortie (10 shots each), then fly home to rearm and land (ready again). Each one lost is rebuilt in 15 s.

const GD = preload("res://scripts/game_data.gd")
const Sfx = preload("res://scripts/sfx.gd")
const ShipScript = preload("res://scripts/ship.gd")

var faction := GD.Faction.UNE
var alive := true          # fighters check this to know their home is still there
var range_mult := 1.0
var host: Node2D = null   # a Carrier the bay rides on (null: a fixed Starbase bay)
var on_board := GD.FIGHTER_GROUP
var _out: Array = []
var _rebuild_queue := 0
var _rebuild_timer := 0.0
var _cooldown := 1.0
var _check := 0.0


func setup(pos_px: Vector2, owner_faction: int, new_range_mult: float = 1.0) -> void:
	position = pos_px
	faction = owner_faction
	range_mult = new_range_mult
	_cooldown = randf_range(0.5, 1.5)


func _process(delta: float) -> void:
	if host != null:
		# Riding on a Carrier: follow it, move systems with it, and go when it goes.
		if not is_instance_valid(host) or not (host.get("alive") == true):
			alive = false
			queue_free()
			return
		if host.get_parent() != get_parent():
			reparent.call_deferred(host.get_parent(), false)
			return
		position = host.position
	# Anything that vanished without landing or a death report counts as lost.
	for f in _out.duplicate():
		if not is_instance_valid(f):
			_out.erase(f)
			_rebuild_queue += 1
	# Wingmen cards: a bigger wing, built up one fighter at a time.
	if faction == GD.Faction.UNE and on_board + _out.size() + _rebuild_queue < GD.FIGHTER_GROUP + GD.fighter_group_bonus:
		_rebuild_queue += 1
	# Lost fighters are rebuilt one at a time (15 s each), fight or no fight.
	if _rebuild_queue > 0:
		_rebuild_timer -= delta
		if _rebuild_timer <= 0.0:
			_rebuild_timer = GD.FIGHTER_REBUILD if host != null or faction != GD.Faction.UNE else GD.starbase_rebuild
			_rebuild_queue -= 1
			on_board += 1
	elif _rebuild_queue <= 0:
		_rebuild_timer = GD.FIGHTER_REBUILD if host != null or faction != GD.Faction.UNE else GD.starbase_rebuild
	_cooldown -= delta
	_check -= delta
	# On a Carrier in your fleet, fighters are a secondary weapon: Alt + click sends every
	# fighter on board, and every fighter already out, at the enemy nearest the reticle.
	if host != null and host.get("aiming_secondary") == true:
		if _check <= 0.0:
			_check = 0.25
			_order_strike(host.get("aim_point"))
		return
	if on_board <= 0 or not _out.is_empty() or _cooldown > 0.0 or _check > 0.0:
		return
	_check = 0.25
	var target := _nearest_enemy_ship(float(GD.WEAPONS["bay"]["range"]) * GD.UNIT * range_mult)
	if target == null:
		return
	_launch(target)


func _order_strike(point: Vector2) -> void:
	var reach := float(GD.WEAPONS["bay"]["range"]) * GD.UNIT * range_mult
	var target: Node2D = null
	var best_d := 15.0 * GD.UNIT   # how close to the reticle an enemy must be
	for child in get_parent().get_children():
		var ship := child as Node2D
		if ship == null or not ship.is_in_group("ships") or not (ship.get("alive") == true):
			continue
		if not GD.is_hostile(faction, int(ship.get("faction"))) or ship.get("concealed") == true:
			continue
		if position.distance_to(ship.position) > reach:
			continue
		var d := point.distance_to(ship.position)
		if d <= best_d:
			best_d = d
			target = ship
	if target == null:
		return
	for f in _out:
		if is_instance_valid(f) and f.get("alive") == true and int(f.get("ammo")) != 0:
			f.call("attack", target)
	if on_board > 0 and _cooldown <= 0.0:
		_launch(target)
		_cooldown = 1.0


func _nearest_enemy_ship(reach: float) -> Node2D:
	var best: Node2D = null
	var best_d := reach
	for child in get_parent().get_children():
		var ship := child as Node2D
		if ship == null or not ship.is_in_group("ships") or not (ship.get("alive") == true):
			continue
		if not GD.is_hostile(faction, int(ship.get("faction"))) or ship.get("concealed") == true:
			continue
		var d := position.distance_to(ship.position)
		if d <= best_d:
			best_d = d
			best = ship
	return best


func _launch(target: Node2D) -> void:
	_cooldown = 6.0
	var dir := (target.position - position).normalized()
	var lead: ShipScript = null
	var count := on_board
	for i in on_board:
		var fighter: ShipScript = ShipScript.new()
		get_parent().add_child(fighter)
		var side := dir.orthogonal() * (i - (on_board - 1) / 2.0) * 10.0
		fighter.setup("fighter", faction, position + side, dir.angle(), "fighter")
		fighter.carrier = self
		fighter._sortie_left = GD.FIGHTER_SORTIE
		fighter.ammo = GD.FIGHTER_AMMO
		fighter.attack(target)
		# A V: the first is the lead, the others sit back and to either side of it in
		# pairs. With an even number the odd one out can't pair up, so it closes the V
		# from behind, straight back from the lead (4 fighters fly a diamond).
		if lead == null:
			lead = fighter
		elif count % 2 == 0 and i == count - 1:
			fighter.wing_lead = lead
			fighter.wing_slot = Vector2(-1.5 * (ceilf((count - 2) / 2.0) + 1.0), 0.0) * GD.UNIT
			fighter.set("_run_side", 1.0 if randf() < 0.5 else -1.0)
		else:
			var side_sign := 1.0 if i % 2 == 1 else -1.0
			fighter.wing_lead = lead
			fighter.wing_slot = Vector2(-1.5, 1.5 * side_sign) * GD.UNIT * ceilf(i / 2.0)
			fighter.set("_run_side", side_sign)   # split to opposite sides at the target
		fighter.destroyed.connect(_on_fighter_lost)
		_out.append(fighter)
	on_board = 0
	Sfx.play("jet", self, -12.0, 0.1)


## Called by a fighter as it lands: back on board, ready for the next launch.
func on_landed(fighter: Node2D) -> void:
	if _out.has(fighter):
		_out.erase(fighter)
		on_board += 1


func _on_fighter_lost(fighter: Node2D) -> void:
	if _out.has(fighter):
		_out.erase(fighter)
		_rebuild_queue += 1
