extends Node2D
## A placeholder ship: a triangle sized by ship size, coloured by faction,
## with its short code above it (hold Space for full names).
## Ships fire their loadout at their focus target, or the nearest hostile in range.

signal destroyed(ship: Node2D)

const GD = preload("res://scripts/game_data.gd")
const ShipModels = preload("res://scripts/ship_models.gd")
const Sfx = preload("res://scripts/sfx.gd")
const Smoke = preload("res://scripts/smoke.gd")
const Projectile = preload("res://scripts/projectile.gd")
const Explosion = preload("res://scripts/explosion.gd")
const Torpedo = preload("res://scripts/torpedo.gd")
const SwarmMissile = preload("res://scripts/swarm_missile.gd")

var type_id := "corvette"
var faction := 0
var heading := 0.0
var hull := 0.0
var armor := 0.0
var shields := 0.0
var max_hull := 0.0
var max_armor := 0.0
var max_shields := 0.0
var _base_shields := 0.0     # the ship type's own shields, before Fleet cards
var armor_hardening := 0.0   # flat damage off every hit while armor holds
var shield_hardening := 0.0  # 10% less damage per point while shields are up
var shield_front_only := false   # the shield only covers an arc in front (GD.SONS_SHIELD_ARC)
var mag_pierces_shields := false # MAG-type hits skip the shield (Philip's Destroyers)
var _shield_hits: Array = []  # [angle, age] where the shield was struck, glowing briefly
var aiming_secondary := false # Fleet Mode, Alt held: secondary weapons (MAGs) fire at the reticle
var base_speed := 6.0
var speed_units := 6.0
var damage_log: Array = []   # flagship only: [seconds, amount, weapon, who] for the death screen
var role := ""            # "", "guard", "hideout", "patrol", "phalanx", "raid", "anchor" (never leaves its post)
var raid_target := Vector2.ZERO   # "raid": where the wave is heading (px)
var hold_fire := false    # e.g. while boosting, or hiding Rebels
var alive := true
var focus: Node2D = null  # set by focus fire
var velocity := Vector2.ZERO
var driven := false       # true while the fleet formation moves this ship directly
var route: Array = []     # patrol waypoints in pixels
var escort_point := Vector2.ZERO
var escorting := false    # right-click: flying to the reticle to fight
var ship_name := ""
var carrier: Node2D = null       # fighters: the bay that launched them
var _sortie_left := 0.0          # fighters: safety cap on a sortie's length (s)
var wing_lead: Node2D = null       # fighters: the group lead this wingman follows in the V
var wing_slot := Vector2.ZERO      # fighters: spot in the V, in the lead's frame (px)
var _broke := false               # fighters: the group has split up for the attack
var ammo := -1                   # attacks left (fighters; one burst = one attack); -1 = unlimited
var kills := 0
var damage_done := 0.0   # effective damage this ship has dealt to enemy ships (what actually came off them)
var damage_by_weapon := {}   # the same, split by weapon name ("Other" for rams and the like)
var fog_mode := "full"    # "full", "dot" (seen only by sensors) or "hidden"
var aiming := false      # Fleet Mode: left mouse held, fire at aim_point
var aim_point := Vector2.ZERO
var concealed := false    # hidden from your sensors behind a planet or in an asteroid field

var _base_hull := 0.0
var _base_armor := 0.0
var _guns: Array = []
var _target := Vector2.ZERO
var _moving := false
var _guard_post := Vector2.ZERO
var _since_hit := 99.0
var _attacker: Node2D = null
var _unanswered := 0.0
var _charging := false
var _slow_left := 0.0
var _slow_factor := 1.0
var cruise := 1.0          # patrol squadrons fly at half speed until they fight
var squad_slot := Vector2.INF   # where this ship's spot in its patrol formation is (px)
var _route_i := 0
var _bump_cd := 0.0
var _shake := 0.0
var _flash := 0.0
var _font: Font
var _dt := 0.0
var _time := 0.0
var _run_phase := 0
var _run_side := 1.0
var _run_exit := Vector2.ZERO
var _orbit_angle := 0.0
var _orbit_total := 0.0
var _break_left := 0.0
var _break_point := Vector2.ZERO
var _smoke_timer := 0.0
var _cur_weapon := ""   # the weapon firing right now (for per-weapon Fleet card boosts)
var motion := Vector2.ZERO   # measured velocity, whoever moves the ship (for aim leading)
var _prev_pos := Vector2.ZERO
var _trail: Array = []       # recent positions for the contrail
var _trail_timer := 0.0
var _shot_count := 0
var _muzzle := Vector2.ZERO   # offset of the gun firing right now
var _gun_side := 1.0           # Corvettes: which side sponson fires next


func setup(new_type: String, new_faction: int, pos_px: Vector2, facing: float, new_role: String = "") -> void:
	type_id = new_type
	faction = new_faction
	position = pos_px
	heading = facing
	role = new_role
	_guard_post = pos_px
	hold_fire = role == "hideout"
	ship_name = "Kharkiv" if new_type == "capital" else GD.next_ship_name(new_faction)
	_run_side = 1.0 if randf() < 0.5 else -1.0
	var stats := GD.ship_stats(new_type)
	_base_hull = stats["hull"]
	_base_armor = stats["armor"]
	base_speed = stats["speed"]
	hull = _base_hull
	armor = _base_armor
	max_hull = hull
	max_armor = armor
	speed_units = base_speed
	armor_hardening = float(stats.get("armor_hardening", 0.0))
	_base_shields = float(stats.get("shields", 0.0))
	max_shields = _base_shields
	shields = _base_shields
	shield_hardening = float(stats.get("shield_hardening", 0.0))
	# Philip's Destroyers and Battleships: a frontal shield wall that only MAGs get through.
	if faction == GD.Faction.SONS and (new_type == "destroyer" or new_type == "battleship"):
		_base_shields = GD.SONS_DESTROYER_SHIELDS if new_type == "destroyer" else GD.SONS_BATTLESHIP_SHIELDS
		max_shields = _base_shields
		shields = _base_shields
		shield_hardening = GD.SONS_DESTROYER_SHIELD_HARDENING
		shield_front_only = true
		mag_pierces_shields = true
	var loadout: Array = GD.LOADOUTS.get(new_type, []).duplicate()
	# Fleet cards can bolt extra weapons onto your ship types.
	if faction == GD.Faction.UNE:
		loadout.append_array(Array(GD.extra_weapons.get(new_type, [])))
	for w in loadout:
		_guns.append({"weapon": String(w), "cooldown": randf_range(0.0, 1.5), "burst_left": 0, "burst_timer": 0.0, "target": null, "mount": Vector2.ZERO})
	_assign_mounts()
	apply_fleet_bonuses()
	_redraw()
	if type_id == "carrier":
		call_deferred("_add_bays")


## Gun mounts spread along the hull, so shots visibly come from different points.
func _assign_mounts() -> void:
	var r := GD.ship_pixels(type_id)
	var side_i := 0
	var n := _guns.size()
	for i in n:
		var gun: Dictionary = _guns[i]
		var w := String(gun["weapon"])
		var mount := Vector2.ZERO
		if n > 2:
			if GD.WEAPONS[w].has("charge"):
				mount = Vector2(r * 0.42, (0.12 if i % 2 == 0 else -0.12) * r)
			else:
				var along := lerpf(0.3, -0.4, floorf(side_i * 0.5) / maxf(1.0, float(n) / 2.0))
				mount = Vector2(along * r, (0.32 if side_i % 2 == 0 else -0.32) * r)
				side_i += 1
		gun["mount"] = mount
	# MAG barrels: the first on the centreline, any extras side by side either side of it.
	var mags := 0
	for gun in _guns:
		if GD.WEAPONS[String(gun["weapon"])].has("charge"):
			gun["barrel_y"] = 0.0 if mags == 0 else (0.2 if mags % 2 == 1 else -0.2) * r * (1.0 + floorf((mags - 1) * 0.5) * 0.6)
			mags += 1


## Corvettes fire from the barrel tips of their two side sponsons, left then right.
func _sponson_muzzle() -> Vector2:
	_gun_side = -_gun_side
	var r := GD.ship_pixels(type_id)
	return Vector2(0.34 * r, 0.37 * r * _gun_side).rotated(heading)


## A Fleet card bolted a new weapon onto this ship type: add it to a ship already flying.
func add_weapon(weapon_id: String) -> void:
	_guns.append({"weapon": weapon_id, "cooldown": randf_range(0.0, 1.5), "burst_left": 0, "burst_timer": 0.0, "target": null, "mount": Vector2.ZERO})
	_assign_mounts()
	_redraw()


## Carriers: Fighter Bays that ride along with the ship (they follow it in fighter_bay.gd).
func _add_bays() -> void:
	if not is_inside_tree() or not alive:
		return
	# Loaded by a path held in a variable, not a fixed one: fighter_bay.gd already loads
	# ship.gd, and a fixed path here would make the two scripts depend on each other,
	# which can stop ship.gd from compiling (no ships at all).
	var bay_path := "res://scripts/fighter_bay.gd"
	var bay_script: GDScript = load(bay_path)
	for i in GD.CARRIER_BAYS:
		var bay: Node2D = bay_script.new()
		get_parent().add_child(bay)
		bay.call("setup", position, faction, GD.STARBASE_RANGE_MULT)   # same reach as a Starbase bay
		bay.set("host", self)


## Re-applies the fleet-wide bonuses (Fleet cards), keeping current damage.
func apply_fleet_bonuses() -> void:
	var armor_m := GD.armor_mult
	var hull_m := GD.hull_mult
	var shield_b := GD.shield_bonus
	var speed_m := GD.speed_mult
	if faction == GD.Faction.SONS and not GD.sons_mods.is_empty():
		# The Sons of Philip pick their own cards.
		armor_m = float(GD.sons_mods["armor_mult"])
		hull_m = float(GD.sons_mods["hull_mult"])
		shield_b = float(GD.sons_mods["shield_bonus"])
		speed_m = float(GD.sons_mods["speed_mult"])
	elif faction != GD.Faction.UNE:
		return
	var armor_lost := max_armor - armor
	var hull_lost := max_hull - hull
	max_armor = _base_armor * armor_m
	max_hull = _base_hull * hull_m
	armor = maxf(0.0, max_armor - armor_lost)
	hull = maxf(1.0, max_hull - hull_lost)
	var shield_gain := _base_shields + shield_b - max_shields
	max_shields = _base_shields + shield_b
	shields = clampf(shields + shield_gain, 0.0, max_shields)
	speed_units = base_speed * speed_m
	_redraw()


func _ready() -> void:
	_font = ThemeDB.fallback_font
	add_to_group("ships")
	add_to_group("targets")


## Fly to a point (in pixels, local to the system).
func move_to(point_px: Vector2) -> void:
	_target = point_px
	_moving = true


func stop() -> void:
	_moving = false


func repair(fraction: float) -> void:
	armor = minf(max_armor, armor + max_armor * fraction)
	hull = minf(max_hull, hull + max_hull * fraction)
	_redraw()


func is_damaged() -> bool:
	return armor < max_armor or hull < max_hull


func take_damage(amount: float, attacker: Node2D = null) -> void:
	if not alive:
		return
	# Slipstream: while boosting, shots from behind do half damage to ships in formation.
	if GD.slipstream and GD.boosting and faction == GD.Faction.UNE and driven and attacker != null and is_instance_valid(attacker):
		if (attacker.position - position).dot(Vector2.RIGHT.rotated(heading)) < 0.0:
			amount *= 0.5
	# The flagship keeps a log of what hit it, for the death screen (v0.9.187).
	if type_id == "capital" and amount > 0.0:
		damage_log.append([Time.get_ticks_msec() / 1000.0, amount, GD.hit_weapon if GD.hit_weapon != "" else "Rams and blasts", _source_name(attacker)])
		while damage_log.size() > 400:
			damage_log.pop_front()
	_since_hit = 0.0
	if attacker != null and is_instance_valid(attacker):
		_attacker = attacker
		# Enemies never sit in the open and soak hits: they turn and fight at once.
		if faction != GD.Faction.UNE and attacker.get_parent() == get_parent():
			var their = attacker.get("faction")
			if their != null and GD.is_hostile(faction, int(their)):
				if role == "hideout":
					role = ""
				hold_fire = false
				var first_alarm := not _charging
				if role != "phalanx" and role != "anchor":
					_charging = true
				# Pulled together, like a pack: nearby friends join in, so the player
				# can't pick ships off one at a time from long range.
				if first_alarm:
					_alert_pack(attacker)
		if role == "phalanx":
			# Weak spot: hits from behind do 150%. (The front is covered by the
			# shield wall now; the old 50% frontal cut was dropped in v0.9.131.)
			var to_attacker := (attacker.position - position).normalized()
			if Vector2.RIGHT.rotated(heading).dot(to_attacker) < -0.5:
				amount *= 1.5
	# A frontal shield only covers an arc in front: anything from outside it goes
	# straight to armor and hull, unhardened.
	var covered := true
	if shield_front_only and attacker != null and is_instance_valid(attacker):
		var off := absf(Vector2.RIGHT.rotated(heading).angle_to(attacker.position - position))
		covered = off <= deg_to_rad(GD.SONS_SHIELD_ARC)
	# Shield hardening: a percentage off while shields are up.
	if shields > 0.0 and shield_hardening > 0.0 and covered:
		amount *= maxf(0.1, 1.0 - GD.SHIELD_HARDENING_STEP * shield_hardening)
		GD.hit_hardened = true
	# MAGs punch straight through a pierceable shield into armor and hull.
	var pierce := (mag_pierces_shields and GD.hit_weapon.contains("MAG")) or not covered
	var to_shields := 0.0 if pierce else minf(shields, amount)
	Sfx.play("shield_hit" if to_shields > 0.0 else "hit", self, -10.0, 0.15)
	if to_shields > 0.0 and attacker != null and is_instance_valid(attacker):
		_shield_hits.append([(attacker.position - position).angle(), 0.0])
		if _shield_hits.size() > 6:
			_shield_hits.pop_front()
	shields -= to_shields
	amount -= to_shields
	# Armor hardening: a flat amount off what gets through, while armor holds.
	if amount > 0.0 and armor > 0.0 and armor_hardening > 0.0:
		amount = maxf(amount - armor_hardening, minf(amount, 1.0))   # a hit always does at least 1
		GD.hit_hardened = true
	var to_armor := minf(armor, amount)
	var to_hull := minf(maxf(hull, 0.0), amount - to_armor)
	armor -= to_armor
	hull -= amount - to_armor
	# Credit the shooter with what actually came off (shields, armor and hull, no overkill).
	if attacker != null and is_instance_valid(attacker) and attacker.get("damage_done") != null:
		var theirs = attacker.get("faction")
		if theirs != null and GD.is_hostile(int(theirs), faction):
			var landed := to_shields + to_armor + to_hull
			attacker.set("damage_done", float(attacker.get("damage_done")) + landed)
			var split = attacker.get("damage_by_weapon")
			if split is Dictionary:
				var key := GD.hit_weapon if GD.hit_weapon != "" else "Other"
				split[key] = float(split.get(key, 0.0)) + landed
	_redraw()
	if hull <= 0.0:
		_die()


func _die() -> void:
	alive = false
	var boom := Explosion.new()
	get_parent().add_child(boom)
	boom.setup(position, GD.ship_pixels(type_id) * 2.5)
	destroyed.emit(self)
	queue_free()


func max_range_px() -> float:
	var best := 0.0
	for gun in _guns:
		var weapon: Dictionary = GD.WEAPONS[gun["weapon"]]
		best = maxf(best, _range_of(weapon))
	return best * GD.UNIT


## Performance: ships off screen don't rebuild their drawing every frame; they catch up
## the moment they come into view. (Big waves were spending most of a frame on this.)
var _vis := true
var _stale := false


func _redraw() -> void:
	if _vis:
		queue_redraw()
	else:
		_stale = true


func _cull_margin() -> float:
	var reach := max_range_px() if GD.show_ranges else GD.ship_pixels(type_id) * 4.0
	return 160.0 + reach / GD.screen_scale(self)


func _process(delta: float) -> void:
	if not alive:
		return
	_vis = GD.on_screen(self, _cull_margin()) if is_inside_tree() else true
	if _stale and _vis:
		_stale = false
		queue_redraw()
	_dt = delta
	_time += delta
	_break_left = maxf(0.0, _break_left - delta)
	if _slow_left > 0.0:
		_slow_left -= delta
		if _slow_left <= 0.0:
			_slow_factor = 1.0
	if fog_mode == "dot":
		_redraw()
	_since_hit += delta
	if _since_hit > GD.SHIELD_DELAY and shields < max_shields:
		shields = minf(max_shields, shields + GD.SHIELD_RECHARGE * delta)
	_bump_cd -= delta
	if _shake > 0.0 or _flash > 0.0:
		_shake = maxf(0.0, _shake - delta)
		_flash = maxf(0.0, _flash - delta)
		_redraw()
	_damage_smoke(delta)
	_track_motion(delta)
	if not _shield_hits.is_empty():
		for h in _shield_hits:
			h[1] = float(h[1]) + delta
		while not _shield_hits.is_empty() and float(_shield_hits[0][1]) > 0.45:
			_shield_hits.pop_front()
		_redraw()
	if role == "fighter":
		_fighter_think(delta)
	elif faction != GD.Faction.UNE or role == "patrol" or role == "squad":
		_think(delta)
	elif escorting:
		_escort_think()
	if not driven:
		_physics_move(delta)
	if visible and is_inside_tree():
		_update_guns(delta)


## Floaty movement: accelerate toward the move target, ease in, coast to a stop.
func _physics_move(delta: float) -> void:
	var max_speed := speed_units * GD.UNIT * _slow_factor * cruise
	var accel := max_speed * 1.6
	if _moving:
		var to_target := _target - position
		var dist := to_target.length()
		if dist < 0.5 * GD.UNIT and velocity.length() < accel * 0.2:
			_moving = false
		else:
			var desired := to_target.normalized() * minf(max_speed, sqrt(2.0 * accel * dist))
			velocity = velocity.move_toward(desired, accel * 1.5 * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, accel * 0.6 * delta)
	if velocity.length() > 1.0:
		position += velocity * delta
		heading = lerp_angle(heading, velocity.angle(), clampf(delta * GD.turn_rate(type_id), 0.0, 1.0))
		_redraw()


## Shake, flash red and lose hull after hitting an asteroid.
func bump() -> void:
	if _bump_cd > 0.0 or not alive:
		return
	_bump_cd = 1.0
	_shake = 0.4
	_flash = 0.5
	hull -= max_hull * GD.BUMP_DAMAGE
	velocity *= -0.3
	_redraw()
	if hull <= 0.0:
		_die()


func _escort_think() -> void:
	# Fight around the reticle with normal combat behaviour.
	var enemy: Node2D = focus if focus != null and is_instance_valid(focus) and focus.get_parent() == get_parent() and (focus.get("alive") == true) else null
	if enemy == null:
		enemy = _ai_nearest("escort", GD.GUARD_AGGRO * GD.UNIT, escort_point)
	if enemy != null:
		_engage(enemy)
	else:
		move_to(escort_point)


## Below half health a ship trails smoke; below a quarter it burns too.
func _damage_smoke(delta: float) -> void:
	var total := max_armor + max_hull
	if total <= 0.0 or fog_mode != "full" or not is_visible_in_tree():
		return
	var left := (armor + hull) / total
	if left >= 0.5:
		return
	_smoke_timer -= delta
	if _smoke_timer > 0.0:
		return
	_smoke_timer = 0.12 if left < 0.25 else 0.22
	var r := GD.ship_pixels(type_id)
	var spot := position + Vector2(randf_range(-0.4, 0.4) * r, randf_range(-0.4, 0.4) * r)
	var drift := Vector2(randf_range(-10.0, 10.0), -25.0) - velocity * 0.3
	var puff := Smoke.new()
	get_parent().add_child(puff)
	puff.setup(spot, r * 0.3, Color(0.35, 0.36, 0.38, 0.55), randf_range(1.2, 1.8), drift, 2.2)
	if left < 0.25:
		var fire := Smoke.new()
		get_parent().add_child(fire)
		fire.setup(spot, r * 0.22, Color(1.0, 0.55, 0.15, 0.85) if randf() < 0.6 else Color(1.0, 0.85, 0.3, 0.85), randf_range(0.35, 0.6), drift * 0.5, 0.8)


## Rocks, bases and wrecks don't shoot back: no evasion, just close in and circle.
func _engage_inert(target: Node2D) -> void:
	var reach := maxf(max_range_px(), 6.0 * GD.UNIT)
	var to_target := target.position - position
	match type_id:
		"corvette":
			# Attack runs on buildings too: dive in firing, pass the target, peel out to about
			# 2/3 of range, swing round and come back from the other side. Long straight
			# approaches give the station's guns a fair shot (tight orbits dodged them).
			var dist := to_target.length()
			var dir := to_target.normalized() if dist > 1.0 else Vector2.RIGHT
			if _run_phase == 0:
				move_to(target.position + dir.orthogonal() * _run_side * 2.5 * GD.UNIT)
				if dist < 4.0 * GD.UNIT:
					_run_phase = 1
					_run_exit = target.position + dir * reach * 0.65 + dir.orthogonal() * _run_side * reach * 0.35
			else:
				move_to(_run_exit)
				if position.distance_to(_run_exit) < 3.0 * GD.UNIT:
					_run_phase = 0
					_run_side = -_run_side
		"frigate":
			var radius := reach * 0.8
			if _orbit_total == 0.0 or position.distance_to(target.position) > radius * 2.0:
				_orbit_angle = (position - target.position).angle()
				_orbit_total = 0.001
			_orbit_angle += speed_units * GD.UNIT / maxf(radius, 1.0) * _dt * 0.8
			move_to(target.position + Vector2.RIGHT.rotated(_orbit_angle) * radius)
		_:
			if to_target.length() > reach * 0.5:
				move_to(target.position - to_target.normalized() * reach * 0.4)
			else:
				_moving = false
				heading = lerp_angle(heading, to_target.angle(), clampf(_dt * 1.5 * GD.turn_rate(type_id) / GD.TURN_RATE, 0.0, 1.0))
				_redraw()


## How each ship type fights once it's free to manoeuvre.
func _engage(enemy: Node2D) -> void:
	if enemy.get("type_id") == null:
		_engage_inert(enemy)
		return
	var to_enemy := enemy.position - position
	var dist := to_enemy.length()
	var reach := maxf(max_range_px(), 6.0 * GD.UNIT)
	if _break_left > 0.0:
		move_to(_break_point)
		return
	match type_id:
		"corvette", "fighter":
			# Attack runs: dive past the target firing, peel away, loop back on the other side.
			var dir := to_enemy.normalized() if dist > 1.0 else Vector2.RIGHT
			if _run_phase == 0:
				move_to(enemy.position + dir.orthogonal() * _run_side * 2.5 * GD.UNIT)
				if dist < 3.5 * GD.UNIT:
					_run_phase = 1
					_run_exit = enemy.position + dir * reach * 0.9 + dir.orthogonal() * _run_side * reach * 0.5
			else:
				move_to(_run_exit)
				if position.distance_to(_run_exit) < 3.0 * GD.UNIT:
					_run_phase = 0
					_run_side = -_run_side
		"frigate":
			# Circle-strafe for a lap or two, then break off and come back from a new angle.
			var health_left := (armor + hull) / maxf(1.0, max_armor + max_hull)
			if health_left < 0.4 and _since_hit < 1.0:
				_break_point = position - to_enemy.normalized() * reach * 1.5
				_break_left = 4.0
				return
			var radius := reach * 0.7
			if _orbit_total == 0.0:
				_orbit_angle = (position - enemy.position).angle()
			var step := speed_units * GD.UNIT / maxf(radius, 1.0) * _dt * 0.8
			_orbit_angle += step
			_orbit_total += step
			move_to(enemy.position + Vector2.RIGHT.rotated(_orbit_angle) * radius)
			if _orbit_total > TAU * 1.5:
				_orbit_total = 0.0
				_break_point = enemy.position + Vector2.RIGHT.rotated(_orbit_angle + PI * 0.6) * reach * 1.6
				_break_left = 2.5
		_:
			# Bigger ships hold range and turn their guns to bear.
			if dist > reach * 0.85:
				move_to(enemy.position - to_enemy.normalized() * reach * 0.75)
			else:
				_moving = false
				heading = lerp_angle(heading, to_enemy.angle(), clampf(_dt * 1.5 * GD.turn_rate(type_id) / GD.TURN_RATE, 0.0, 1.0))
				_redraw()


## Sons of Philip phalanx: hold the line and turn slowly to face the nearest threat.
func _phalanx_think(delta: float) -> void:
	_moving = false
	var enemy := _ai_nearest("phalanx", 50.0 * GD.UNIT, position)
	if enemy == null:
		return
	var want := (enemy.position - position).angle()
	var diff := wrapf(want - heading, -PI, PI)
	heading += clampf(diff, -GD.PHALANX_TURN * delta, GD.PHALANX_TURN * delta)
	_redraw()


## Who a hit came from, in a few words ("Rebel Corvette", "Sons Battleship", "a station").
static func _source_name(attacker: Node2D) -> String:
	if attacker == null or not is_instance_valid(attacker):
		return "unknown"
	var side := ""
	var f = attacker.get("faction")
	if f != null and int(f) == GD.Faction.REBELS:
		side = "Rebel "
	elif f != null and int(f) == GD.Faction.SONS:
		side = "Sons "
	var t = attacker.get("type_id")
	if t != null and GD.SHIPS.has(String(t)):
		return side + String(GD.SHIPS[String(t)]["kind"])
	var scr = attacker.get_script()
	var file := String(scr.resource_path).get_file().get_basename() if scr != null else ""
	match file:
		"planet_gun", "starbase":
			return side + "station"
		"planet_siege":
			return "Mars"
		"rebel_base":
			return "the Rebel Rock"
		"torpedo", "swarm_missile":
			return side + "missiles"
	return side.strip_edges() if side != "" else "unknown"


## "anchor": holds its post no matter what (the Mars home guard). Drifts back to the post
## if pushed off it, and otherwise just turns to face the nearest enemy and fires.
func _anchor_think(delta: float) -> void:
	if position.distance_to(_guard_post) > 1.5 * GD.UNIT:
		move_to(_guard_post)
		return
	_moving = false
	var enemy := _ai_nearest("anchor", 60.0 * GD.UNIT, position)
	if enemy == null:
		return
	var want := (enemy.position - position).angle()
	var diff := wrapf(want - heading, -PI, PI)
	var turn := GD.turn_rate(type_id) * delta
	heading += clampf(diff, -turn, turn)
	_redraw()


## Phalanx Volley: each other Destroyer within 8 units cuts Mini MAG reload by 5% (max 25%).
func _phalanx_bonus() -> float:
	if role != "phalanx":
		return 1.0
	var n := 0
	for child in get_parent().get_children():
		if child != self and child.is_in_group("ships") and String(child.get("role")) == "phalanx" and (child.get("alive") == true):
			if position.distance_to((child as Node2D).position) <= GD.PHALANX_RANGE * GD.UNIT:
				n += 1
	return 1.0 - minf(0.25, 0.05 * n)


# --- AI ------------------------------------------------------------------------

func _think(delta: float) -> void:
	# Under fire it can't answer? After a few seconds: "!" and charge the attacker.
	var attacker_ok := _attacker != null and is_instance_valid(_attacker) and _attacker.get_parent() == get_parent()
	if attacker_ok and _since_hit < 1.5 and position.distance_to(_attacker.position) > max_range_px() * 0.95:
		_unanswered += delta
		if _unanswered >= GD.CHARGE_AFTER and not _charging:
			_charging = true
			hold_fire = false
			_redraw()
	elif not _charging:
		_unanswered = 0.0
	if _charging:
		if not attacker_ok:
			_charging = false
			_unanswered = 0.0
			_redraw()
		else:
			if role == "phalanx":
				_phalanx_think(delta)
			elif role == "anchor":
				_anchor_think(delta)
			else:
				_engage(_attacker)
			return
	if role == "phalanx":
		_phalanx_think(delta)
	elif role == "anchor":
		_anchor_think(delta)
	elif role == "hideout":
		# Lying in wait in the rocks: spring on anything of yours that comes close.
		var prey := _ai_nearest("ambush", GD.AMBUSH_REACH * GD.UNIT, position, true)
		if prey != null:
			role = ""
			hold_fire = false
			attack(prey)
			_alert_pack(prey)
	elif role == "guard":
		_guard_think()
	elif role == "raid":
		# A Rebel wave: fight anything on the way, otherwise head for the target and circle it.
		var foe := _ai_nearest("raid", GD.GUARD_AGGRO * GD.UNIT * 1.5, position)
		if foe != null:
			attack(foe)
		elif position.distance_to(raid_target) > 16.0 * GD.UNIT:
			move_to(raid_target + (position - raid_target).normalized() * 14.0 * GD.UNIT)
		else:
			_orbit_angle = (position - raid_target).angle() + 0.6
			move_to(raid_target + Vector2.RIGHT.rotated(_orbit_angle) * 14.0 * GD.UNIT)
	elif role == "squad":
		# Your patrol squadron: hunt any enemy ship in the system at full speed,
		# otherwise hold this ship's spot in the formation at half speed.
		var foe := _ai_nearest("squad", GD.SYSTEM_RADIUS * 2.0 * GD.UNIT, position, true)
		if foe != null:
			attack(foe)
		else:
			cruise = 0.5
			if squad_slot != Vector2.INF:
				move_to(squad_slot)
	elif role == "patrol":
		# Your patrols hunt any enemy ship that enters their system; Rebel patrols
		# only react to what comes close.
		var reach := GD.SYSTEM_RADIUS * 2.0 if faction == GD.Faction.UNE else GD.GUARD_AGGRO
		var enemy := _ai_nearest("patrol", reach * GD.UNIT, position, faction == GD.Faction.UNE)
		if enemy != null:
			attack(enemy)
		elif not route.is_empty():
			var waypoint: Vector2 = route[_route_i % route.size()]
			if position.distance_to(waypoint) < 3.0 * GD.UNIT:
				_route_i += 1
			move_to(waypoint)


func _guard_think() -> void:
	var enemy := _ai_nearest("guard", GD.GUARD_AGGRO * GD.UNIT, _guard_post)
	if enemy != null and position.distance_to(_guard_post) < GD.GUARD_LEASH * GD.UNIT:
		_engage(enemy)
	elif position.distance_to(_guard_post) > 1.0 * GD.UNIT:
		move_to(_guard_post)


## A fighter's sortie: swarm the target, find another when it dies, and fly home to rearm
## once its ammo is spent (or nothing is left nearby, or the safety timer runs out).
## If its bay is gone, it fights on until then, then breaks up.
func _fighter_think(delta: float) -> void:
	_sortie_left -= delta
	# Checked step by step: a bay or target that was just destroyed is a freed object.
	var home_ok := false
	if carrier != null and is_instance_valid(carrier):
		home_ok = carrier.get("alive") == true and carrier.get_parent() == get_parent()
	else:
		carrier = null
	var target_ok := false
	if _attacker != null and is_instance_valid(_attacker):
		target_ok = _attacker.get_parent() == get_parent() and _attacker.get("alive") == true
	else:
		_attacker = null
	var armed := ammo != 0 and _sortie_left > 0.0
	if not target_ok and armed:
		var next := _ai_nearest("fighter", 25.0 * GD.UNIT, position, true)
		if next != null:
			_attacker = next
			target_ok = true
	if armed and target_ok:
		hold_fire = false
		# Flying in: a tight V so the group reads as one wing. Within 10 units of the
		# target (or if the lead is lost) they split up and make their own runs.
		if not _broke:
			var lead_ok: bool = wing_lead != null and is_instance_valid(wing_lead) and wing_lead.get("alive") == true \
				and wing_lead.get_parent() == get_parent() and wing_lead.get("_broke") == false
			var near := position.distance_to(_attacker.position) < 10.0 * GD.UNIT
			if wing_lead == null:
				# The lead: head for the target a little under full speed so the wings keep up.
				if near:
					_broke = true
				else:
					cruise = 0.8
					move_to(_attacker.position)
					return
			elif lead_ok and not near:
				cruise = 1.0
				move_to(wing_lead.position + wing_slot.rotated(float(wing_lead.get("heading"))))
				return
			else:
				_broke = true
		cruise = 1.0
		_engage(_attacker)
		return
	if not home_ok:
		_die()
		return
	hold_fire = true
	move_to(carrier.position)
	if position.distance_to(carrier.position) < 1.5 * GD.UNIT:
		if carrier.has_method("on_landed"):
			carrier.call("on_landed", self)
		alive = false   # landed: not a loss
		queue_free()


## True while this ship is fighting something that's still alive here.
func is_fighting() -> bool:
	return _attacker != null and is_instance_valid(_attacker) and _attacker.get_parent() == get_parent() \
		and (_attacker.get("alive") == true)


## Orders this AI ship to attack a target (used by Rebel intercepts and alarms).
func attack(target: Node2D) -> void:
	cruise = 1.0
	_attacker = target
	_charging = true
	_since_hit = 0.0
	hold_fire = false
	_redraw()


## Nearest live hostile target within reach of a point, in this system.
## torpedoes_ok: guns may shoot at incoming torpedoes and missiles; movement AI never chases them.
## front_only: only targets in the ship's frontal 180 degrees (the Cruiser's missile radar).
## How long an idle gun waits before looking for a target again (seconds).
const SEEK_GAP := 0.15


## Counts down an idle gun's search timer; true when it may look for a target.
func _seek_ready(gun: Dictionary, delta: float) -> bool:
	var left := float(gun.get("seek", 0.0)) - delta
	gun["seek"] = left
	return left <= 0.0


## Performance: AI "who's nearest?" checks are cached for a fraction of a second per
## ship (staggered so a whole wave doesn't search on the same frame). A cached enemy is
## dropped at once if it dies, leaves or moves out of reach.
var _ai_cache := {}   # key -> [node, seconds left]


func _ai_nearest(key: String, reach_px: float, from: Vector2, ships_only: bool = false) -> Node2D:
	var entry: Array = _ai_cache.get(key, [null, 0.0])
	var left := float(entry[1]) - _dt
	var node = entry[0]
	if left > 0.0:
		if node == null:
			entry[1] = left
			_ai_cache[key] = entry
			return null
		if is_instance_valid(node) and node.get_parent() == get_parent() and node.get("alive") == true and from.distance_to((node as Node2D).position) <= reach_px:
			entry[1] = left
			_ai_cache[key] = entry
			return node
	var found := _nearest_hostile(reach_px, from, ships_only)
	_ai_cache[key] = [found, randf_range(0.18, 0.3)]
	return found


func _nearest_hostile(reach_px: float, from: Vector2, ships_only: bool = false, torpedoes_ok: bool = false, front_only: bool = false) -> Node2D:
	var best: Node2D = null
	var best_d2 := reach_px * reach_px
	var fwd := Vector2.RIGHT.rotated(heading)
	var home := get_parent()
	for t in get_tree().get_nodes_in_group("targets"):
		var node := t as Node2D
		if node == null or node == self or node.get_parent() != home or not node.visible:
			continue
		# Cheapest test first: most candidates are simply too far away.
		var d2 := from.distance_squared_to(node.position)
		if d2 > best_d2:
			continue
		if not torpedoes_ok and node.is_in_group("ordnance"):
			continue
		if ships_only and not node.is_in_group("ships"):
			continue
		if not (node.get("alive") == true):
			continue
		if not GD.is_hostile(faction, int(node.get("faction"))):
			continue
		if faction == GD.Faction.UNE and (node.get("concealed") == true):
			continue
		if front_only and fwd.dot(node.position - from) < 0.0:
			continue
		best_d2 = d2
		best = node
	return best


# --- weapons -------------------------------------------------------------------

func _update_guns(delta: float) -> void:
	for gun in _guns:
		var weapon: Dictionary = GD.WEAPONS[gun["weapon"]]
		if weapon.has("heat_rounds"):
			_update_hot_gun(gun, weapon, delta)
			continue
		if weapon.has("swarm"):
			_update_swarm(gun, weapon, delta)
			continue
		gun["cooldown"] = float(gun["cooldown"]) - delta
		if int(gun["burst_left"]) > 0:
			if float(gun.get("charge_total", 0.0)) > 0.0:
				_redraw()   # the charge glow grows every frame
				var tracked = gun.get("target")
				if tracked != null and is_instance_valid(tracked):
					gun["last_aim"] = (tracked as Node2D).position   # keep up with it while charging
			gun["burst_timer"] = float(gun["burst_timer"]) - delta
			if float(gun["burst_timer"]) <= 0.0:
				if aiming_secondary and not GD.is_special(weapon):
					gun["burst_left"] = 0
					continue
				var burst_target = gun["target"]
				var mount: Vector2 = gun.get("mount", Vector2.ZERO)
				_muzzle = _sponson_muzzle() if type_id == "corvette" else mount.rotated(heading)
				if weapon.has("charge"):
					_muzzle = _barrel_tip(gun, GD.ship_pixels(type_id))
					_muzzle_blast(_muzzle, String(weapon["name"]) != "Mini MAG")
					Sfx.play("mag_fire" if String(weapon["name"]) != "Mini MAG" else "mini_mag_fire", self)
				# Long Gatling streams keep their sound going.
				if GD.gatling_extra_seconds > 0.0 and faction == GD.Faction.UNE and not weapon.has("charge") and int(gun["burst_left"]) % 10 == 0:
					Sfx.play("gatling", self, -10.0, 0.1)
				_cur_weapon = String(gun["weapon"])
				if bool(gun.get("free", false)):
					_fire_free(weapon)
				elif is_instance_valid(burst_target) and burst_target.get("alive") != false:
					gun["last_aim"] = (burst_target as Node2D).position
					_fire(weapon, burst_target)
				elif weapon.has("charge") and gun.has("last_aim"):
					# The target died while the MAG was charging: the shot still goes, at
					# where it last was (v0.9.186; it used to vanish without a slug).
					_fire_free(weapon, Vector2(gun["last_aim"]))
				gun["burst_left"] = int(gun["burst_left"]) - 1
				gun["burst_timer"] = float(weapon["gap"])
			continue
		if float(gun["cooldown"]) > 0.0 and _has_reload_ring(weapon):
			_redraw()   # the reload ring fills every frame
		if hold_fire or ammo == 0 or float(gun["cooldown"]) > 0.0:
			continue
		# Alt held: only the heavy weapons fire (MAGs, torpedoes, missiles).
		if aiming_secondary and not GD.is_special(weapon):
			continue
		var reach := _range_of(weapon) * GD.UNIT
		var target: Node2D = null
		var free := false
		if focus != null and is_instance_valid(focus) and focus.get_parent() == get_parent() and position.distance_to(focus.position) <= reach:
			target = focus
		elif aiming or (aiming_secondary and weapon.has("charge")):
			free = true
		elif aiming_secondary and weapon.has("torpedo"):
			# Alt: a torpedo goes for the enemy ship nearest the reticle (it's a homer).
			target = _nearest_hostile(8.0 * GD.UNIT, aim_point, true)
			if target == null or position.distance_to(target.position) > reach:
				continue
		elif aiming_secondary:
			continue   # Alt held: only the heavy weapons fire
		else:
			# Torpedoes only lock on to ships, never to other torpedoes.
			# Performance: an idle gun looks around a few times a second, not every frame.
			if not _seek_ready(gun, delta):
				continue
			target = _nearest_hostile(reach, position, weapon.has("torpedo"), not weapon.has("torpedo"))
			if target == null:
				gun["seek"] = SEEK_GAP
		if target == null and not free:
			continue
		# Several of the same heavy gun on one ship (extra MAGs from cards and the like)
		# take turns instead of firing as one: each waits its share of the reload after
		# the last one went.
		var same := _same_guns(String(gun["weapon"]))
		if same > 1 and float(weapon["cooldown"]) >= 2.0:
			var stagger := minf(1.5, float(weapon["cooldown"]) / float(same))
			if _time - float(_volley_last.get(String(gun["weapon"]), -99.0)) < stagger:
				continue
			_volley_last[String(gun["weapon"])] = _time
		gun["free"] = free
		gun["target"] = target
		if target != null:
			gun["last_aim"] = target.position
		gun["burst_left"] = int(weapon["burst"])
		# Ammo counts attacks: a whole burst uses one (fighters).
		if ammo > 0:
			ammo -= 1
		# Sustained Fire: your Gatlings keep firing for longer.
		if faction == GD.Faction.UNE and String(gun["weapon"]) == "gatling" and GD.gatling_extra_seconds > 0.0:
			gun["burst_left"] = int(weapon["burst"]) + int(GD.gatling_extra_seconds / maxf(float(weapon["gap"]), 0.01))
		# MAG-family guns charge up for a couple of seconds first, so you can see them coming.
		gun["burst_timer"] = float(weapon.get("charge", 0.0))
		gun["charge_total"] = float(weapon.get("charge", 0.0))
		if weapon.has("charge"):
			Sfx.play("mag_charge", self, -12.0)
		elif weapon.has("flak"):
			Sfx.play("hit", self, -6.0, 0.2)
		elif weapon.has("torpedo"):
			pass   # the torpedo plays its own launch sound
		else:
			Sfx.play("gatling", self, -8.0 if faction == GD.Faction.UNE else -10.0, 0.1)
		var cooldown := float(weapon["cooldown"])
		if faction == GD.Faction.UNE:
			cooldown *= GD.cooldown_mult
		elif faction == GD.Faction.SONS and not GD.sons_mods.is_empty():
			cooldown *= float(GD.sons_mods["cooldown_mult"])
		if String(gun["weapon"]) == "mini_mag":
			cooldown *= _phalanx_bonus()
		if faction == GD.Faction.UNE:
			cooldown *= float(GD.weapon_cooldown_mult.get(String(gun["weapon"]), 1.0))
		gun["cooldown"] = cooldown
		gun["cooldown_total"] = cooldown   # for the reload ring


var _volley_last := {}   # weapon id -> when the last of that gun on this ship started firing


func _same_guns(weapon_id: String) -> int:
	var n := 0
	for g in _guns:
		if String(g["weapon"]) == weapon_id:
			n += 1
	return n


func _fire(weapon: Dictionary, target: Node2D) -> void:
	if weapon.has("torpedo"):
		_launch_torpedo(weapon, target, target.position)
		return
	var damage := float(weapon["damage"])
	if faction == GD.Faction.UNE:
		damage = (damage + GD.damage_bonus) * _amp(_cur_weapon)
	# Shots fly straight at where the target will be, with some scatter, so they can miss.
	var speed := float(weapon["speed"]) * GD.UNIT
	var lead := Vector2.ZERO
	var m = target.get("motion")
	if m != null:
		lead = Vector2(m) * position.distance_to(target.position) / maxf(speed, 1.0)
	var spread := float(weapon.get("spread", 0.3)) * GD.UNIT * GD.AUTO_SPREAD   # automatic fire is looser than hand-aimed
	if bool(weapon.get("precise", false)):
		spread = float(weapon.get("spread", 0.3)) * GD.UNIT   # fire-controlled (PDCs): no extra auto-fire scatter
	var scatter := Vector2.RIGHT.rotated(randf() * TAU) * sqrt(randf()) * spread
	var shot := Projectile.new()
	get_parent().add_child(shot)
	shot.setup_free(position + _muzzle, target.position + lead + scatter, damage, speed, Color(String(weapon["colour"])), self, _range_of(weapon) * GD.UNIT)
	shot.intended = target
	if bool(weapon.get("flak", false)):
		shot.call("make_flak", (target.position + lead + scatter).distance_to(position + _muzzle), float(weapon["splash"]) * GD.UNIT)
	_style_shot(shot, weapon)


## Gatlings: no fixed cooldown. They fire a steady stream while there's something to
## shoot, and every round heats the barrels. Full heat: they overheat and must cool all
## the way down before firing again. Letting off lets them cool as they go.
func _update_hot_gun(gun: Dictionary, weapon: Dictionary, delta: float) -> void:
	var gap := float(weapon["gap"])
	var capacity := float(weapon["heat_rounds"])
	if faction == GD.Faction.UNE:
		capacity += GD.gatling_extra_seconds / maxf(gap, 0.01)
	var heat := float(gun.get("heat", 0.0))
	var hot := bool(gun.get("overheated", false))
	var cool_time := float(weapon["overheat"]) * (GD.cooldown_mult if faction == GD.Faction.UNE else 1.0)
	gun["shot_timer"] = float(gun.get("shot_timer", 0.0)) - delta
	var fired := false
	if hot:
		heat -= capacity / maxf(cool_time, 0.1) * delta
		if heat <= 0.0:
			heat = 0.0
			hot = false
	elif not hold_fire and not aiming_secondary:
		var reach := _range_of(weapon) * GD.UNIT
		var target: Node2D = null
		var free := false
		if focus != null and is_instance_valid(focus) and focus.get_parent() == get_parent() and position.distance_to(focus.position) <= reach:
			target = focus
		elif aiming:
			free = true
		elif _seek_ready(gun, delta):
			target = _nearest_hostile(reach, position, false, true)
			if target == null:
				gun["seek"] = SEEK_GAP
		if (target != null or free) and float(gun["shot_timer"]) <= 0.0:
			var mount: Vector2 = gun.get("mount", Vector2.ZERO)
			_muzzle = _sponson_muzzle() if type_id == "corvette" else mount.rotated(heading)
			_cur_weapon = String(gun["weapon"])
			if free:
				_fire_free(weapon)
			else:
				_fire(weapon, target)
			fired = true
			gun["shot_timer"] = gap
			heat += 1.0
			gun["rounds"] = int(gun.get("rounds", 0)) + 1
			if int(gun["rounds"]) % 10 == 1:
				Sfx.play("gatling", self, -8.0 if faction == GD.Faction.UNE else -10.0, 0.1)
			if heat >= capacity:
				hot = true
				Sfx.play("jet", self, -15.0, 0.1)   # a vent of hot gas
	if not fired and not hot:
		# Barrels cool off whenever they aren't firing.
		heat = maxf(0.0, heat - capacity * 0.5 * delta)
	if (heat > 0.0) != (float(gun.get("heat", 0.0)) > 0.0) or heat > 0.0:
		_redraw()
	gun["heat"] = heat
	gun["heat_frac"] = clampf(heat / maxf(capacity, 1.0), 0.0, 1.0)
	gun["overheated"] = hot


## Hot Gatling barrels glow red at the tips; overheated ones pulse.
func _draw_heat(r: float) -> void:
	for gun in _guns:
		var frac := float(gun.get("heat_frac", 0.0))
		if frac < 0.25:
			continue
		var mount: Vector2 = gun.get("mount", Vector2.ZERO)
		var tips: Array = [mount.rotated(heading) + Vector2.RIGHT.rotated(heading) * r * 0.55]
		if type_id == "corvette":
			# Corvettes: both sponson barrel tips glow.
			tips = [Vector2(0.34 * r, 0.37 * r).rotated(heading), Vector2(0.34 * r, -0.37 * r).rotated(heading)]
		var t := (frac - 0.25) / 0.75
		var glow := t
		if bool(gun.get("overheated", false)):
			glow = 0.7 + 0.3 * sin(Time.get_ticks_msec() / 70.0)
		for tip in tips:
			var at: Vector2 = tip
			draw_circle(at, 3.0 + 5.0 * glow, Color(1.0, 0.25, 0.1, 0.25 * glow))
			draw_circle(at, 1.5 + 2.0 * glow, Color(1.0, 0.45 + 0.3 * (1.0 - glow), 0.2, 0.5 + 0.5 * glow))


## Swarm Missiles: a radar beam sweeps a wedge towards the enemy, left to right, locking one target per
## missile, then the salvo ripple-fires, fans out and curves in on its locks.
## Nothing locked: no salvo, and it sweeps again shortly.
func _update_swarm(gun: Dictionary, weapon: Dictionary, delta: float) -> void:
	var sweep: float = float(gun.get("sweep", -1.0))
	if sweep >= 0.0:
		sweep += delta
		var dur := float(weapon["sweep"])
		var reach := _range_of(weapon) * GD.UNIT
		var centre: Vector2 = gun["sweep_dir"]
		var half := deg_to_rad(float(weapon["wedge"])) * 0.5
		# The radar beam sweeps from the left edge of the wedge to the right.
		var beam := lerpf(-half, half, clampf(sweep / dur, 0.0, 1.0))
		var locks: Array = gun["locks"]
		var most := _swarm_count(weapon)
		for t in get_tree().get_nodes_in_group("targets"):
			if locks.size() >= most:
				break
			var node := t as Node2D
			if node == null or node == self or node.get_parent() != get_parent() or not node.visible:
				continue
			if node.is_in_group("ordnance") or node.get("alive") != true or locks.has(node):
				continue
			if not GD.is_hostile(faction, int(node.get("faction"))):
				continue
			if faction == GD.Faction.UNE and node.get("concealed") == true:
				continue
			var to := node.position - position
			var ang := centre.angle_to(to)
			if to.length() > reach or ang < -half or ang > beam:
				continue
			locks.append(node)
			Sfx.play("blip", self, -14.0, 0.15)
		gun["sweep"] = sweep
		_redraw()
		if sweep >= dur:
			gun["sweep"] = -1.0
			var live: Array = []
			for node in locks:
				if is_instance_valid(node) and node.get("alive") == true:
					live.append(node)
			gun["locks"] = []
			# Nothing locked while you aim by hand: the salvo still goes, sprayed wide and
			# at random, and each missile grabs whatever enemy it passes.
			var spray := live.is_empty() and (aiming or aiming_secondary) and faction == GD.Faction.UNE
			if live.is_empty() and not spray:
				gun["cooldown"] = float(weapon["retry"])
			else:
				_launch_swarm(gun, weapon, live, centre)
				var cooldown := float(weapon["cooldown"])
				if faction == GD.Faction.UNE:
					cooldown *= GD.cooldown_mult
				elif faction == GD.Faction.SONS and not GD.sons_mods.is_empty():
					cooldown *= float(GD.sons_mods["cooldown_mult"])
				gun["cooldown"] = cooldown
				gun["cooldown_total"] = cooldown
		return
	gun["cooldown"] = float(gun["cooldown"]) - delta
	if float(gun["cooldown"]) > 0.0:
		_redraw()   # the reload ring fills every frame
	if hold_fire or float(gun["cooldown"]) > 0.0:
		return
	var reach_px := _range_of(weapon) * GD.UNIT
	# The radar sweeps a 180-degree half: where you aim when you're aiming by hand,
	# otherwise centred on the nearest enemy ship in range, whichever way it is (behind
	# included, v0.9.126). No enemy in range: no sweep.
	var dir := Vector2.RIGHT.rotated(heading)
	if aiming or aiming_secondary:   # by hand, or Alt: sweep towards the reticle
		dir = aim_point - position
	elif not _seek_ready(gun, delta):
		return
	else:
		var nearest := _nearest_hostile(reach_px, position, true)
		if nearest == null:
			gun["seek"] = SEEK_GAP
			return
		dir = nearest.position - position
	if dir.length() < 1.0:
		return
	gun["sweep"] = 0.0
	gun["sweep_dir"] = dir.normalized()
	gun["locks"] = []
	Sfx.play("blip", self, -8.0, 0.0)


## A weapon's reach in units on this hull (Cruisers reach 50% further with everything).
func _range_of(weapon: Dictionary) -> float:
	var r := float(weapon["range"]) * float(GD.SHIP_RANGE_MULT.get(type_id, 1.0))
	if faction == GD.Faction.UNE and String(weapon.get("name", "")) == "PDC":
		r *= GD.pdc_range_mult   # Long-Range PDCs (v0.9.212)
	return r


func _swarm_count(weapon: Dictionary) -> int:
	return int(weapon["missiles"]) + (GD.swarm_bonus if faction == GD.Faction.UNE else 0)


## Fleet card boost to one weapon's damage (your ships only).
func _amp(weapon_id: String) -> float:
	return float(GD.weapon_damage_mult.get(weapon_id, 1.0)) if faction == GD.Faction.UNE else 1.0


## One missile per lock; spare missiles go to the toughest locked targets.
func _launch_swarm(gun: Dictionary, weapon: Dictionary, locks: Array, centre: Vector2) -> void:
	var by_toughness := locks.duplicate()
	by_toughness.sort_custom(func(a, b): return _toughness(a) > _toughness(b))
	var count := _swarm_count(weapon)
	var assigned: Array = []
	for node in locks:
		assigned.append(node)
	var i := 0
	while assigned.size() < count:
		assigned.append(by_toughness[i % by_toughness.size()] if not by_toughness.is_empty() else null)
		i += 1
	var unlocked := locks.is_empty()
	var mount: Vector2 = gun.get("mount", Vector2.ZERO)
	var bonus := GD.damage_bonus if faction == GD.Faction.UNE else 0.0
	var amped := weapon.duplicate()
	amped["damage"] = float(weapon["damage"]) * _amp("swarm")
	for k: int in count:
		# Fan out either side of the sweep direction, alternating left and right.
		var side := -1.0 if k % 2 == 0 else 1.0
		var spread: float = lerpf(0.5, 1.3, floorf(k * 0.5) / maxf(1.0, floorf(count * 0.5)))
		var out_dir := centre.rotated(side * spread)
		var delay := k * 0.05
		if unlocked:
			# Manual fire, nothing locked: an even arc across the aim, left to right,
			# rippling out one after another.
			var t := (float(k) + 0.5) / float(count)
			out_dir = centre.rotated(lerpf(-1.1, 1.1, t) + randf_range(-0.05, 0.05))
			delay = k * 0.04
		var m := SwarmMissile.new()
		m.setup(self, mount.rotated(heading), out_dir, assigned[k], amped, bonus, delay)
		m.wild = unlocked
		get_parent().add_child(m)


func _toughness(node) -> float:
	if not is_instance_valid(node):
		return 0.0
	var h = node.get("max_hull")
	var a = node.get("max_armor")
	return (float(h) if h != null else 0.0) + (float(a) if a != null else 0.0)


## The radar wedge while it sweeps, with a reticle on each lock.
func _draw_swarm_sweep() -> void:
	for gun in _guns:
		var sweep := float(gun.get("sweep", -1.0))
		if sweep < 0.0:
			continue
		var weapon: Dictionary = GD.WEAPONS[gun["weapon"]]
		var t := clampf(sweep / float(weapon["sweep"]), 0.0, 1.0)
		var reach := _range_of(weapon) * GD.UNIT
		var half := deg_to_rad(float(weapon["wedge"])) * 0.5
		var centre: Vector2 = gun["sweep_dir"]
		var yours := faction == GD.Faction.UNE
		var col := Color(0.35, 1.0, 0.5) if yours else Color(1.0, 0.25, 0.2)
		var beam := lerpf(-half, half, t)
		# A faint outline of the wedge.
		draw_arc(Vector2.ZERO, reach, centre.angle() - half, centre.angle() + half, 32, Color(col, 0.05), 1.5)
		# The beam, with a short fading afterglow behind it.
		var trail := 0.35
		for j: int in 6:
			var a1 := maxf(-half, beam - trail * float(j + 1) / 6.0)
			var a0 := maxf(-half, beam - trail * float(j) / 6.0)
			if a0 <= a1:
				continue
			var slice := PackedVector2Array([Vector2.ZERO, centre.rotated(a1) * reach, centre.rotated(a0) * reach])
			draw_colored_polygon(slice, Color(col, 0.03 * (1.0 - float(j) / 6.0)))
		draw_line(Vector2.ZERO, centre.rotated(beam) * reach, Color(col, 0.14), 1.5)
		# Locked targets: four bold corner brackets, impossible to miss.
		var blink := 1.0 if fmod(Time.get_ticks_msec() / 110.0, 2.0) < 1.4 else 0.55
		for node in Array(gun["locks"]):
			if not is_instance_valid(node):
				continue
			var tgt := node as Node2D
			var at: Vector2 = tgt.position - position
			var tr := GD.ship_pixels(str(tgt.get("type_id"))) if GD.SHIPS.has(str(tgt.get("type_id"))) else 18.0
			var half_box := tr * 1.35
			var arm := maxf(9.0, tr * 0.55)
			var c := Color(col.lightened(0.25), blink)
			for sx: float in [-1.0, 1.0]:
				for sy: float in [-1.0, 1.0]:
					var corner := at + Vector2(sx * half_box, sy * half_box)
					draw_line(corner, corner - Vector2(sx * arm, 0), Color(0, 0, 0, 0.6), 7.0)
					draw_line(corner, corner - Vector2(0, sy * arm), Color(0, 0, 0, 0.6), 7.0)
					draw_line(corner, corner - Vector2(sx * arm, 0), c, 4.0)
					draw_line(corner, corner - Vector2(0, sy * arm), c, 4.0)


## Torpedo: launched along the ship's heading, then it turns and hunts its target.
func _launch_torpedo(weapon: Dictionary, target: Node2D, aim_px: Vector2) -> void:
	var torp := Torpedo.new()
	var facing := Vector2.RIGHT.rotated(heading)
	# Out of the tube roughly forward, angled a little towards the aim point.
	var aim_dir := (aim_px - position).normalized() if aim_px.distance_to(position) > 1.0 else facing
	var out_dir := facing.slerp(aim_dir, 0.35)
	var w := weapon.duplicate()
	if faction == GD.Faction.UNE:
		w["damage"] = float(w["damage"]) * _amp("torpedo")
		w["splash"] = float(w.get("splash", 5.0)) * GD.torpedo_splash_mult
	torp.setup(position + _muzzle, position + out_dir * 100.0, target, w, self, GD.damage_bonus if faction == GD.Faction.UNE else 0.0)
	get_parent().add_child(torp)


func _fire_free(weapon: Dictionary, at: Vector2 = Vector2.INF) -> void:
	var aimed := at == Vector2.INF   # by the reticle (else: at a given point)
	var point := aim_point if aimed else at
	if weapon.has("torpedo"):
		# Hand-aimed: locks on to the enemy ship nearest the reticle, if there is one.
		var lock := _nearest_hostile(6.0 * GD.UNIT, aim_point, true)
		_launch_torpedo(weapon, lock, aim_point)
		return
	var damage := float(weapon["damage"])
	if faction == GD.Faction.UNE:
		damage = (damage + GD.damage_bonus) * _amp(_cur_weapon)
	var jitter := Vector2.RIGHT.rotated(randf() * TAU) * sqrt(randf()) * (GD.AIM_JITTER + float(weapon.get("spread", 0.3))) * GD.UNIT
	var shot := Projectile.new()
	get_parent().add_child(shot)
	shot.reticle = aimed
	shot.setup_free(position + _muzzle, point + jitter, damage, float(weapon["speed"]) * GD.UNIT, Color(String(weapon["colour"])), self, _range_of(weapon) * GD.UNIT)
	if bool(weapon.get("flak", false)):
		# Hand-aimed flak bursts at the reticle (or at the end of its range).
		var to_aim := minf((point + jitter).distance_to(position + _muzzle), _range_of(weapon) * GD.UNIT)
		shot.call("make_flak", to_aim, float(weapon["splash"]) * GD.UNIT)
	_style_shot(shot, weapon)


func _style_shot(shot: Node2D, weapon: Dictionary) -> void:
	_shot_count += 1
	shot.set("vs_small", float(weapon.get("vs_small", 1.0)))
	shot.set("vs_big", float(weapon.get("vs_big", 1.0)))
	shot.set("weapon_name", String(weapon["name"]))
	var weapon_name := String(weapon["name"])
	if weapon_name == "K9 Gatling Gun":
		# One bright tracer in five rounds; the rest fade fast. Rarely a tracer flies on a bit.
		var tracer := _shot_count % 5 == 0
		shot.call("set_style", tracer, not tracer, false)
		if tracer and randf() < 0.08:
			shot.call("make_long", 1.5)
	elif weapon_name == "Mini MAG":
		shot.call("set_style", false, false, true, true)
	elif weapon.has("charge"):
		shot.call("set_style", false, false, false, true)


# --- drawing -------------------------------------------------------------------

func _draw() -> void:
	if fog_mode == "hidden":
		return
	if fog_mode == "dot":
		# Seen only by sensors: a slowly breathing red dot.
		var kk := GD.screen_scale(self)
		var breathe := 0.55 + 0.35 * sin(_time * 2.0)
		draw_circle(Vector2.ZERO, 14.0 * kk, Color(0.9, 0.28, 0.3, 0.25 * breathe))
		draw_circle(Vector2.ZERO, 6.0 * kk, Color(0.9, 0.28, 0.3, breathe))
		return
	var r := GD.ship_pixels(type_id)
	_draw_contrail(r)
	_draw_heat(r)
	_draw_swarm_sweep()
	_draw_mag_reload(r)
	# The hull: each class has its own model, in the Starbase's design language.
	var jitter := Vector2.ZERO
	if _shake > 0.0:
		jitter = Vector2(randf_range(-3.0, 3.0), randf_range(-3.0, 3.0))
	ShipModels.draw(self, type_id, r, heading, jitter, faction, _flash, _time)
	_draw_charges(r)   # MAG barrels sit on top of the hull
	if role == "fighter":
		return   # too small for a label, health bar or range ring
	_draw_shield_bubble(r)   # (Philip's frontal shield replaces the old gold phalanx arc)
	var k := GD.screen_scale(self)
	if GD.show_ranges and not _guns.is_empty():
		_draw_range_rings(k)
	# Health bar once damaged (armour then hull).
	var total := max_armor + max_hull
	var hurt := total > 0.0 and armor + hull < total
	if hurt:
		var w := 40.0 * k
		var top := r + 6.0 * k
		draw_rect(Rect2(Vector2(-w / 2.0, top), Vector2(w, 5.0 * k)), Color(0.02, 0.03, 0.05, 0.8))
		draw_rect(Rect2(Vector2(-w / 2.0, top), Vector2(w * (armor + hull) / total, 5.0 * k)), Color("e5484d") if faction != GD.Faction.UNE else Color("3dd17a"))

	# Label: full names while Space (info) is held; short codes all the time only with
	# Settings > Abbreviated Ship Names (off by default: the models say enough).
	# (The red "!" over charging enemies was removed in v0.9.111; their label still turns red.)
	var label := GD.ship_label(type_id) if (GD.show_full_names or GD.show_abbrev_names) else ""
	if label == "":
		return
	var size := 13 if r < 20.0 else 16
	var width := _font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	draw_set_transform(Vector2(0, -r - 4.0 * k), 0.0, Vector2(k, k))
	draw_string_outline(_font, Vector2(-width / 2.0, 0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 4, Color("0b0e14"))
	draw_string(_font, Vector2(-width / 2.0, 0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color("e5484d") if _charging else Color("f4efe2"))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _gun_reaches() -> Array:
	var reaches: Array = []
	for gun in _guns:
		var weapon: Dictionary = GD.WEAPONS[gun["weapon"]]
		var reach := _range_of(weapon) * GD.UNIT
		if not reaches.has(reach):
			reaches.append(reach)
	return reaches


## Range rings, merged with nearby ships of the same faction: only the outer edge of
## overlapping rings is drawn, so a formation shows one clean outline per weapon range.
func _draw_range_rings(k: float) -> void:
	var ring := GD.ring_colour(faction)
	var others: Array = []
	for child in get_parent().get_children():
		if child == self or not child.is_in_group("ships") or not (child.get("alive") == true):
			continue
		if int(child.get("faction")) != faction or String(child.get("fog_mode")) != "full":
			continue
		others.append(child)
	const SEGMENTS := 96
	for reach in _gun_reaches():
		var r: float = reach
		var covers: Array = []
		for other in others:
			var o := other as Node2D
			if (o.call("_gun_reaches") as Array).has(r) and position.distance_to(o.position) < r * 2.0:
				covers.append(o.position - position)
		if covers.is_empty():
			draw_circle(Vector2.ZERO, r, Color(ring, 0.035))
			draw_arc(Vector2.ZERO, r, 0.0, TAU, SEGMENTS, Color(ring, 0.28), 1.5 * k)
			continue
		for i in SEGMENTS:
			var a0 := TAU * i / SEGMENTS
			var a1 := TAU * (i + 1) / SEGMENTS
			var mid := Vector2.RIGHT.rotated((a0 + a1) * 0.5) * r
			var hidden := false
			for c in covers:
				var centre: Vector2 = c
				if mid.distance_to(centre) < r - 1.0:
					hidden = true
					break
			if not hidden:
				draw_arc(Vector2.ZERO, r, a0, a1, 2, Color(ring, 0.28), 1.5 * k)


func _track_motion(delta: float) -> void:
	if delta <= 0.0:
		return
	# A jump of more than 20 units in one frame is a teleport (arriving through a warp
	# lane, a reparent): forget the old contrail and speed, or the trail draws a white
	# line right across the screen to where it was, and guns lead it wildly (v0.9.236).
	if _prev_pos != Vector2.ZERO and position.distance_to(_prev_pos) > 20.0 * GD.UNIT:
		_trail.clear()
		motion = Vector2.ZERO
		_prev_pos = position
	if _prev_pos != Vector2.ZERO:
		motion = motion.lerp((position - _prev_pos) / delta, 0.3)
	_prev_pos = position
	if not _trail.is_empty():
		_redraw()
	_trail_timer -= delta
	if _trail_timer > 0.0:
		return
	_trail_timer = 0.05
	if motion.length() > 1.5 * GD.UNIT:
		_trail.append(position)
		if _trail.size() > 14:
			_trail.pop_front()
	elif not _trail.is_empty():
		_trail.pop_front()


## A thin fading contrail behind a moving ship, and a flickering flame at its exhaust.
func _draw_contrail(r: float) -> void:
	var n := _trail.size()
	if n >= 2:
		for i in range(n - 1):
			var a: Vector2 = _trail[i]
			var b: Vector2 = _trail[i + 1]
			var t := float(i + 1) / float(n)
			draw_line(a - position, b - position, Color(0.85, 0.9, 1.0, 0.22 * t), maxf(1.5, r * 0.16) * (0.4 + 0.6 * t) * (1.8 if GD.boosting and driven else 1.0))
		var last: Vector2 = _trail[n - 1]
		draw_line(last - position, Vector2.ZERO, Color(0.85, 0.9, 1.0, 0.22), maxf(1.5, r * 0.16))
	var speed := motion.length()
	if speed > 1.5 * GD.UNIT:
		var back := Vector2.LEFT.rotated(heading)
		var side := back.orthogonal()
		var length := r * (0.35 + 0.35 * clampf(speed / (speed_units * GD.UNIT), 0.0, 1.5)) * randf_range(0.8, 1.15)
		var base := back * r * 0.85   # the stern of the new models
		var boost := GD.boosting and faction == GD.Faction.UNE and driven
		if boost:
			_draw_afterburner(r, base, back, side)
			return
		var flame := PackedVector2Array([base + side * r * 0.16, base - side * r * 0.16, base + back * length])
		draw_colored_polygon(flame, Color(1.0, 0.55, 0.2, 0.85))
		var core := PackedVector2Array([base + side * r * 0.08, base - side * r * 0.08, base + back * length * 0.55])
		draw_colored_polygon(core, Color(1.0, 0.92, 0.6, 0.95))


## Boosting: a roaring afterburner off the stern. A wide blue-white plume, a hot
## orange flame inside it, a white core, shock diamonds and a glow on the hull.
func _draw_afterburner(r: float, base: Vector2, back: Vector2, side: Vector2) -> void:
	var flicker := randf_range(0.85, 1.15)
	var length := r * 2.4 * flicker
	# Heat glow round the engines.
	draw_circle(base, r * 0.55, Color(0.45, 0.75, 1.0, 0.18))
	draw_circle(base, r * 0.32, Color(0.75, 0.9, 1.0, 0.3))
	# Outer plume: wide, blue and soft.
	var plume := PackedVector2Array([base + side * r * 0.34, base + back * length * 0.35 + side * r * 0.28, base + back * length, base + back * length * 0.35 - side * r * 0.28, base - side * r * 0.34])
	draw_colored_polygon(plume, Color(0.35, 0.65, 1.0, 0.45))
	# The flame: hot orange, then a white core.
	var flame := PackedVector2Array([base + side * r * 0.24, base + back * length * 0.72, base - side * r * 0.24])
	draw_colored_polygon(flame, Color(1.0, 0.6, 0.25, 0.9))
	var core := PackedVector2Array([base + side * r * 0.12, base + back * length * 0.45, base - side * r * 0.12])
	draw_colored_polygon(core, Color(1.0, 0.97, 0.85, 1.0))
	# Shock diamonds down the plume.
	for i: int in 3:
		var at := base + back * length * (0.3 + i * 0.18)
		var w := r * (0.1 - i * 0.022)
		draw_colored_polygon(PackedVector2Array([at + back * w * 1.6, at + side * w, at - back * w * 1.6, at - side * w]), Color(1, 1, 1, 0.7 - i * 0.15))


## A glow building at the muzzle of each charging MAG.
func _draw_charges(r: float) -> void:
	var fwd := Vector2.RIGHT.rotated(heading)
	var side := fwd.orthogonal()
	for gun in _guns:
		var weapon: Dictionary = GD.WEAPONS[gun["weapon"]]
		if not weapon.has("charge"):
			continue
		# The barrel: a gunmetal tube out through the nose, with a muzzle brake on the end.
		# On the ship's centreline from the middle of the hull (extra MAGs sit beside it).
		var mount := Vector2(0.0, float(gun.get("barrel_y", 0.0)))
		var heavy := String(weapon["name"]) != "Mini MAG"
		var width := clampf(r * (0.11 if heavy else 0.08), 2.0, 7.0)
		var base := mount.rotated(heading)
		var tip := _barrel_tip(gun, r)
		draw_line(base, tip, Color("0b0e14"), width + 2.0)
		draw_line(base, tip, Color("6b747e"), width)
		draw_line(base - side * width * 0.25, tip - side * width * 0.25, Color("a7b0b8"), maxf(1.0, width * 0.3))
		var brake := tip - fwd * width * 1.1
		draw_line(brake + side * width * 0.95, brake - side * width * 0.95, Color("0b0e14"), width * 1.2 + 2.0)
		draw_line(brake + side * width * 0.85, brake - side * width * 0.85, Color("8a939c"), width * 1.2)
		var total := float(gun.get("charge_total", 0.0))
		if total <= 0.0 or int(gun["burst_left"]) <= 0:
			continue
		var left := float(gun["burst_timer"])
		if left <= 0.0:
			continue
		var t := 1.0 - left / total
		var colour := Color(String(weapon["colour"]))
		var bright := colour.lightened(0.5)
		# Lines of power run up from the rear of the ship into the barrel, faster and
		# brighter as the charge builds.
		var rails := 3 if heavy else 2
		for k: int in rails:
			var off := (float(k) - float(rails - 1) / 2.0) * r * 0.34
			var a := Vector2(-r * 0.6, mount.y + off).rotated(heading)
			draw_line(a, base, Color(colour, (0.12 + 0.4 * t) * 0.7), 1.2)
			var count := 1 + int(t * 2.0)
			for j: int in count:
				var u := fmod(_time * (1.2 + 3.5 * t) + float(j) / float(count) + k * 0.17, 1.0)
				draw_line(a.lerp(base, u), a.lerp(base, minf(1.0, u + 0.12)), Color(bright, (0.45 + 0.55 * t) * 0.7), 2.0)
		# The charge creeping up the barrel.
		draw_line(base, base.lerp(tip, t), Color(bright, 0.7), maxf(1.0, width * 0.5))
		# Light flooding out of the muzzle: a wash over the hull, a big layered halo,
		# rays turning round it and a long lens-flare streak, all swelling with the
		# charge and flickering harder towards the end.
		var glow := 1.6 if heavy else 1.0
		var flicker := 0.8 + 0.2 * sin(Time.get_ticks_msec() / (40.0 - 25.0 * t))
		var tt := t * t
		draw_circle(Vector2.ZERO, r * (1.1 + 0.4 * t), Color(colour, 0.05 + 0.18 * tt))
		for layer: int in 4:
			var rad := (6.0 + 46.0 * t) * glow * flicker * (1.0 - layer * 0.22)
			draw_circle(tip, rad, Color(colour.lightened(0.15 * layer), (0.05 + 0.12 * t) * (1.0 + layer * 0.6)))
		var ray_len := (14.0 + 70.0 * tt) * glow * 0.7
		for k: int in 6:
			var d := Vector2.RIGHT.rotated(_time * 1.5 + k * TAU / 6.0)
			draw_line(tip + d * 4.0, tip + d * ray_len * (0.7 if k % 2 else 1.0), Color(bright, (0.08 + 0.3 * tt) * 0.7), 2.5 if k % 2 else 1.8)
		var streak := side * (20.0 + 140.0 * tt) * glow * 0.7
		draw_line(tip - streak, tip + streak, Color(bright, (0.15 + 0.45 * tt) * 0.7), 1.5 + 1.5 * t)
		draw_line(tip - streak * 0.5, tip + streak * 0.5, Color(1, 1, 1, (0.2 + 0.5 * tt) * 0.7), 1.5)
		draw_circle(tip, (3.0 + 9.0 * t) * glow * flicker, Color(bright, 0.6 + 0.4 * t))
		draw_circle(tip, (1.5 + 5.0 * t) * glow, Color(1, 1, 1, 0.5 + 0.5 * t))
		if t > 0.93:
			# The instant before the shot: a white-hot flash.
			draw_circle(tip, (16.0 + 30.0 * (t - 0.93) / 0.07) * glow, Color(1, 1, 1, 0.55))
		# A sparkle at the barrel just before the shot.
		if t > 0.78:
			var s := (t - 0.78) / 0.22
			var spin := _time * 5.0
			var long := (7.0 + 16.0 * s) * glow * randf_range(0.8, 1.2) * 0.7
			for m: int in 2:
				var d := Vector2.RIGHT.rotated(spin + m * PI * 0.5)
				draw_line(tip - d * long, tip + d * long, Color(1, 1, 1, 0.95), 1.6)
				var dd := Vector2.RIGHT.rotated(spin + PI * 0.25 + m * PI * 0.5)
				draw_line(tip - dd * long * 0.45, tip + dd * long * 0.45, Color(bright, 0.9), 1.2)
			draw_circle(tip, 2.5 + 2.0 * s, Color(1, 1, 1))


## Where a MAG-family barrel ends: straight out of the nose, on the ship's centreline.
func _barrel_tip(gun: Dictionary, r: float) -> Vector2:
	return Vector2(r * 1.2, float(gun.get("barrel_y", 0.0))).rotated(heading)


## The shot leaves the barrel like artillery: blasts of air out of the muzzle brake's sides.
func _muzzle_blast(tip_local: Vector2, heavy: bool) -> void:
	if not is_visible_in_tree():
		return
	var at := position + tip_local
	var fwd := Vector2.RIGHT.rotated(heading)
	var side := fwd.orthogonal()
	for sgn: float in [-1.0, 1.0]:
		for i: int in (3 if heavy else 2):
			var puff := Smoke.new()
			get_parent().add_child(puff)
			var drift := (side * sgn * randf_range(60.0, 110.0) + fwd * randf_range(-10.0, 25.0)) * (1.3 if heavy else 1.0)
			puff.setup(at + side * sgn * 4.0, randf_range(3.0, 5.0) * (1.4 if heavy else 1.0), Color(0.85, 0.87, 0.9, 0.55), randf_range(0.35, 0.6), drift, 2.2)
	var front := Smoke.new()
	get_parent().add_child(front)
	front.setup(at + fwd * 6.0, 4.0 * (1.4 if heavy else 1.0), Color(1.0, 0.95, 0.85, 0.6), 0.25, fwd * 40.0, 2.5)
	# A big bright muzzle flash that blooms and fades in a blink.
	var flash := Smoke.new()
	get_parent().add_child(flash)
	flash.setup(at, 16.0 * (1.6 if heavy else 1.0), Color(0.85, 0.95, 1.0, 0.85), 0.18, Vector2.ZERO, 3.0)


## Big single shots get a reload ring: MAG-family guns, Torpedoes and Swarm Missiles.
## (Gatlings, PDCs and Flak stream, so they don't.)
func _has_reload_ring(weapon: Dictionary) -> bool:
	return weapon.has("charge") or weapon.has("torpedo") or weapon.has("swarm")


## After a big shot, a ring beside the ship fills back up as the gun reloads. The rings
## sit off the upper-right corner, clear of the hull however the ship is turned (the
## model never reaches past its radius), in a row going right, one per gun.
func _draw_mag_reload(r: float) -> void:
	var k := GD.screen_scale(self)
	var slot := 0
	var corner := Vector2(0.72, -0.72) * (r * 1.12) + Vector2(12.0, -6.0) * k
	for gun in _guns:
		var weapon: Dictionary = GD.WEAPONS[gun["weapon"]]
		if not _has_reload_ring(weapon) or int(gun["burst_left"]) > 0:
			continue
		var left := float(gun["cooldown"])
		if left <= 0.0 or float(gun.get("sweep", -1.0)) >= 0.0:
			continue
		var total := float(gun.get("cooldown_total", weapon["cooldown"]))
		var t := clampf(1.0 - left / maxf(total, 0.01), 0.0, 1.0)
		var c := corner + Vector2(slot * 21.0 * k, 0)
		var colour := Color(String(weapon["colour"]))
		draw_circle(c, 8.5 * k, Color(0.04, 0.05, 0.08, 0.8))
		draw_arc(c, 8.5 * k, 0.0, TAU, 24, Color(colour, 0.25), 1.2 * k)
		draw_arc(c, 6.5 * k, -PI / 2.0, -PI / 2.0 + TAU * t, 24, colour, 3.0 * k)
		slot += 1


## A soft blue force field around a shielded ship, fading as the shield drains, that
## flares where it's struck.
func _draw_shield_bubble(r: float) -> void:
	if max_shields <= 0.0 or shields <= 0.5:
		return
	var strength := clampf(shields / max_shields, 0.0, 1.0)
	var radius := r * 1.25
	var blue := Color(0.36, 0.63, 1.0)
	if shield_front_only:
		# Philip's shield wall: a bright curved plate across the front arc only.
		var arc := deg_to_rad(GD.SONS_SHIELD_ARC)
		var r2 := r * 1.45
		for i in 4:
			var t := float(i) / 4.0
			draw_arc(Vector2.ZERO, r2 * (0.9 + 0.1 * t), heading - arc, heading + arc, 24, Color(blue, (0.08 + 0.05 * t) * strength), 5.0)
		draw_arc(Vector2.ZERO, r2, heading - arc, heading + arc, 24, Color(blue.lightened(0.3), 0.35 + 0.4 * strength), 3.0)
		for h in _shield_hits:
			var angle: float = h[0]
			var fade := 1.0 - float(h[1]) / 0.45
			draw_arc(Vector2.ZERO, r2, angle - 0.35, angle + 0.35, 10, Color(blue.lightened(0.5), 0.8 * fade), 5.0)
		return
	# Fuzzy fill: stacked rings, faint in the middle, a little brighter toward the edge.
	for i in 6:
		var t := float(i + 1) / 6.0
		draw_circle(Vector2.ZERO, radius * t, Color(blue, 0.045 * strength))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 40, Color(blue, 0.22 + 0.25 * strength), 3.0)
	draw_arc(Vector2.ZERO, radius * 0.96, 0.0, TAU, 40, Color(blue.lightened(0.3), 0.2 * strength), 2.0)
	# Where it was hit: a bright patch on the edge that fades out.
	for h in _shield_hits:
		var angle: float = h[0]
		var fade := 1.0 - float(h[1]) / 0.45
		draw_arc(Vector2.ZERO, radius, angle - 0.45, angle + 0.45, 10, Color(blue.lightened(0.5), 0.75 * fade), 4.0)
		draw_circle(Vector2.RIGHT.rotated(angle) * radius * 0.92, r * 0.28 * fade, Color(blue.lightened(0.4), 0.25 * fade))


func _alert_pack(attacker: Node2D) -> void:
	var reach := GD.GROUP_AGGRO * GD.UNIT
	for child in get_parent().get_children():
		var mate := child as Node2D
		if mate == null or mate == self or not mate.is_in_group("ships") or not (mate.get("alive") == true):
			continue
		if int(mate.get("faction")) != faction or mate.get("_charging") == true:
			continue
		if mate.position.distance_to(position) > reach:
			continue
		if String(mate.get("role")) == "anchor":
			continue   # the Mars home guard never leaves its post
		if String(mate.get("role")) == "hideout":
			mate.set("role", "")
		mate.set("hold_fire", false)
		mate.call("attack", attacker)



## Hot Exit and the like: move at a fraction of normal speed for a while.
func slow(seconds: float, factor: float) -> void:
	_slow_left = maxf(_slow_left, seconds)
	_slow_factor = minf(_slow_factor, factor)
