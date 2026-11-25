extends Node2D

const GD = preload("res://scripts/game_data.gd")
const Smoke = preload("res://scripts/smoke.gd")
const Trail = preload("res://scripts/trail.gd")
const DamageNumber = preload("res://scripts/damage_number.gd")
const MagImpact = preload("res://scripts/mag_impact.gd")
## A shot that flies to its target and deals damage on arrival.
## Prototype shots always home in; real hit chances come with the full armory.

var _target: Node2D
var _damage := 0.0
var _speed := 1000.0
var _colour := Color.WHITE
var _dir := Vector2.RIGHT
var _life := 4.0
var _shooter: Node2D
var _free := false         # free fire: flies straight and hits whatever it touches
var _travel_left := 0.0
var _faction := -1
var _age := 0.0
var _tracer := false       # Gatling: every few rounds a bright tracer
var _fades := false        # other Gatling rounds fade out of sight in flight
var _smoky := false        # Mini MAG: leaves a smoke trail
var _smoke_timer := 0.0
var _streak: Node2D = null   # MAG rounds leave a lingering streak
var vs_small := 1.0          # damage multiplier against Small ships (K9 Gatling: 1.5)
var vs_big := 1.0            # damage multiplier against Medium and Large ships (Mini MAG: 1.5)
var _dodged: Array = []     # fighters that already dodged this shot (one roll each)
var weapon_name := ""      # which weapon fired it (for the shooter's damage record)
var slug_scale := 1.0      # MAG Cannon: a thicker slug with a wider hitbox and a bigger, stronger splash
var _heavy := false          # MAG-family slug: bigger, easier to land, splashes the edges, pierces
var _pierced: Array = []     # what a MAG slug has already gone through
var _holes: Array = []       # [entry, exit, dir, length, state 0 before / 1 inside / 2 out] for each hull it went through
var _hidden := false         # inside a hull right now: the slug and its streak aren't drawn
var _since_exit := INF       # px flown since it last came out of a hull (clips its tail)
var _normal_range := 0.0
var _travelled := 0.0
var intended: Node2D = null   # what this shot was aimed at
var reticle := false          # fired by hand at the reticle (free fire)
var _burst_dist := -1.0   # flak: bursts after flying this far (px)
var _burst_r := 0.0       # flak: blast radius (px)
var _long := false        # a long tracer: flies on far past its range, doing 1 damage out there


func setup(from_px: Vector2, target: Node2D, damage: float, speed_px: float, colour: Color, shooter: Node2D = null) -> void:
	_shooter = shooter
	position = from_px
	_target = target
	_damage = damage
	_speed = speed_px
	_colour = colour
	if is_instance_valid(target):
		_dir = (target.position - from_px).normalized()


## Free fire at a point: flies straight on for its weapon's range and hits the first
## non-friendly target it touches (ships, bases, asteroids).
func setup_free(from_px: Vector2, point_px: Vector2, damage: float, speed_px: float, colour: Color, shooter: Node2D, range_px: float) -> void:
	_free = true
	_shooter = shooter
	_faction = int(shooter.get("faction")) if shooter != null else -1
	position = from_px
	_damage = damage
	_speed = speed_px
	_colour = colour
	_travel_left = range_px * GD.SHOT_REACH
	_normal_range = range_px
	var to := point_px - from_px
	_dir = to.normalized() if to.length() > 1.0 else Vector2.RIGHT


## Looks: called right after setup.
func set_style(tracer: bool, fades: bool, smoky: bool, streak: bool = false) -> void:
	_tracer = tracer
	_fades = fades
	_smoky = smoky
	# MAG-family slugs fly twice as far before they vanish. Only the flight: the range
	# a gun starts shooting from is the weapon's own and doesn't change.
	if streak and not _heavy:
		_travel_left *= GD.MAG_TRAVEL_MULT
	_heavy = streak
	if streak and _streak == null:
		_streak = Trail.new()
		_streak.set("colour", _colour)
		get_parent().add_child(_streak)
		_streak.call("add_point", position)


func _exit_tree() -> void:
	if _streak != null and is_instance_valid(_streak):
		_streak.call("add_point", position)
		_streak.call("owner_gone")


func make_long(multiplier: float) -> void:
	_long = true
	_travel_left = _normal_range * multiplier * GD.SHOT_REACH


func _trail(delta: float) -> void:
	_age += delta
	_since_exit += _speed * delta
	_pass_holes()
	if _streak != null and is_instance_valid(_streak):
		_streak.call("add_point", position, _hidden)
	if not _smoky:
		return
	_smoke_timer -= delta
	if _smoke_timer <= 0.0:
		_smoke_timer = 0.025
		var puff := Smoke.new()
		get_parent().add_child(puff)
		var side := _dir.orthogonal() * randf_range(-3.0, 3.0)
		puff.setup(position - _dir * 10.0 + side, randf_range(4.0, 6.0), Color(0.72, 0.74, 0.78, 0.45), randf_range(1.2, 1.8), side * 2.0, 2.5)


## A MAG slug goes *through* what it hits: while it's inside a hull it disappears, and
## its streak breaks at the entry hole and picks up again at the exit hole.
func _pass_holes() -> void:
	if _holes.is_empty():
		return
	var trail_ok := _streak != null and is_instance_valid(_streak)
	_hidden = false
	for h in _holes:
		var entry: Vector2 = h[0]
		var d: Vector2 = h[2]
		var length: float = h[3]
		var s := (position - entry).dot(d)
		var state := 0 if s <= 0.0 else (1 if s < length else 2)
		var prev: int = h[4]
		if state > prev:
			if prev == 0 and trail_ok:
				_streak.call("add_point", entry, false)
				_streak.call("add_point", entry + d * 0.5, true)
			if state == 2:
				var out: Vector2 = h[1]
				if trail_ok:
					_streak.call("add_point", out - d * 0.5, true)
					_streak.call("add_point", out, false)
				_since_exit = (position - out).dot(d)
			h[4] = state
		if state == 1:
			_hidden = true


## Where the slug's line crosses a hull: [entry, exit] (the hull a bit smaller than the hitbox).
func _chord(node: Node2D) -> Array:
	var r := _hit_radius(node) * 0.75
	var off := position - node.position
	var along := off.dot(_dir)
	var perp := off - _dir * along
	var pd := perp.length()
	r = maxf(r, pd + 2.0)
	var half := sqrt(r * r - pd * pd)
	var mid := node.position + perp
	return [mid - _dir * half, mid + _dir * half]


func _hit_radius(node: Node2D) -> float:
	if node.has_method("radius_px"):
		return float(node.call("radius_px"))
	var type_id = node.get("type_id")
	if type_id != null:
		return GD.ship_pixels(String(type_id)) * 0.8
	var r = node.get("radius")
	if r != null:
		return float(r) * GD.UNIT
	return 2.5 * GD.UNIT


func _process_free(delta: float) -> void:
	_trail(delta)
	var step := _speed * delta
	position += _dir * step
	_travel_left -= step
	_travelled += step
	if _long and _travelled > _normal_range * GD.SHOT_REACH:
		_damage = 1.0
	if _travel_left <= 0.0:
		if _burst_r > 0.0:
			_airburst()
			return
		queue_free()
		return
	# Flak: the shell bursts at the aim point.
	if _burst_dist > 0.0 and _travelled >= _burst_dist:
		_airburst()
		return
	var view := get_parent()
	var candidates: Array = view.call("targets_near", position) if view.has_method("targets_near") else get_tree().get_nodes_in_group("targets")
	for t in candidates:
		var node := t as Node2D
		if node == null or not is_instance_valid(node) or node.get_parent() != view or not (node.get("alive") == true):
			continue
		var f = node.get("faction")
		if f != null and int(f) == _faction:
			continue
		# Some things (the derelict tech lab) only take hits you meant to land.
		if node.get("only_on_purpose") == true and not reticle and node != intended:
			continue
		if _heavy and _pierced.has(node):
			continue
		var reach := _hit_radius(node) + 4.0
		if _heavy:
			reach = (reach + 0.6 * GD.UNIT) * GD.SLUG_HITBOX * slug_scale   # MAG slugs: a wider hitbox
		if position.distance_to(node.position) <= reach:
			# Flak bursts on contact too, and its blast can't be dodged.
			if _burst_r > 0.0:
				_airburst()
				return
			# Fighters jink: half of all direct shots fly past them (explosions still hit).
			if node.get("type_id") == "fighter":
				if _dodged.has(node):
					continue
				if randf() < GD.FIGHTER_EVADE:
					_dodged.append(node)
					continue
			var source: Node2D = _shooter if is_instance_valid(_shooter) else null
			if node.has_method("take_damage"):
				var dealt := _damage
				var tint := ""
				var type_id = node.get("type_id")
				if vs_small != 1.0 and type_id != null and GD.SHIPS.has(String(type_id)) and int(GD.SHIPS[String(type_id)]["size"]) == 0:
					dealt *= vs_small
					tint = "bonus"
				# Mini MAG: +50% against Medium and Large ships (the Destroyer's job).
				if vs_big != 1.0 and type_id != null and GD.SHIPS.has(String(type_id)) and int(GD.SHIPS[String(type_id)]["size"]) >= 1:
					dealt *= vs_big
					tint = "bonus"
				GD.hit_weapon = weapon_name
				GD.hit_hardened = false
				node.call("take_damage", dealt, source)
				GD.hit_weapon = ""
				if GD.hit_hardened:
					tint = "hardened"
				if _faction == GD.Faction.UNE:
					GD.damage_dealt += dealt
				_show_number(node, dealt, tint)
			if _heavy:
				# MAG slugs punch through everything in their path and keep going:
				# sparks and debris at the entry hole, fire and ejecta out of the exit.
				var hole := _chord(node)
				_holes.append([hole[0], hole[1], _dir, (hole[1] as Vector2).distance_to(hole[0]), 0])
				if GD.on_screen(node, 200.0):
					var fx := MagImpact.new()
					get_parent().add_child(fx)
					fx.setup(hole[0], hole[1], _dir, slug_scale * clampf(_damage / 400.0, 0.6, 1.6))
				_splash(candidates, node, source)
				_pierced.append(node)
				continue
			queue_free()
			return
	if GD.on_screen(self, 240.0):   # performance: shots out of view don't redraw
		queue_redraw()


## Heavy hits (100+) pop a number: white when you dealt it, red when you took it.
func _show_number(node: Node2D, amount: float, tint: String = "") -> void:
	if not GD.show_damage_numbers or amount < GD.DAMAGE_NUMBER_MIN or amount <= 0.0 or not is_instance_valid(node) or not node.is_visible_in_tree():
		return
	var yours := _faction == GD.Faction.UNE
	if not yours and not GD.show_damage_taken:
		return
	var number := DamageNumber.new()
	get_parent().add_child(number)
	number.setup(node.position, amount, yours, tint)


## A slug's hit spills over onto anything else close by.
func _splash(candidates: Array, struck: Node2D, source: Node2D) -> void:
	# A MAG Cannon slug (slug_scale above 1) blasts a wider ring and harder than other
	# slugs: about 2.4x the radius and 40% of the hit (was 3.2x and 50%, v0.9.93 nerf).
	var reach := GD.SLUG_SPLASH * GD.UNIT * (slug_scale * 1.35 if slug_scale > 1.0 else 1.0)
	var share := GD.SLUG_SPLASH_SHARE if slug_scale <= 1.0 else 0.4
	for t in candidates:
		var node := t as Node2D
		if node == null or node == struck or not is_instance_valid(node) or not (node.get("alive") == true):
			continue
		var f = node.get("faction")
		if f != null and int(f) == _faction:
			continue
		if node.get("only_on_purpose") == true:
			continue
		if position.distance_to(node.position) <= reach + _hit_radius(node) and node.has_method("take_damage"):
			GD.hit_weapon = weapon_name
			node.call("take_damage", _damage * share, source)
			GD.hit_weapon = ""
			if _faction == GD.Faction.UNE:
				GD.damage_dealt += _damage * share
			_show_number(node, _damage * share)


func _process(delta: float) -> void:
	if _free:
		_process_free(delta)
		return
	_trail(delta)
	_life -= delta
	if _life <= 0.0 or not is_instance_valid(_target):
		queue_free()
		return
	var to := _target.position - position
	var step := _speed * delta
	if to.length() <= step + 6.0:
		if _target.get("type_id") == "fighter" and randf() < GD.FIGHTER_EVADE:
			queue_free()   # dodged
			return
		if _target.has_method("take_damage"):
			var source: Node2D = _shooter if is_instance_valid(_shooter) else null
			GD.hit_weapon = weapon_name
			_target.call("take_damage", _damage, source)
			GD.hit_weapon = ""
			if _faction == GD.Faction.UNE:
				GD.damage_dealt += _damage
		queue_free()
		return
	_dir = to.normalized()
	position += _dir * step
	if GD.on_screen(self, 240.0):   # performance: shots out of view don't redraw
		queue_redraw()


## How far the shot has flown, so its streak grows out of the muzzle instead of
## poking backwards over the ship on the first frames.
func _flown() -> float:
	return _age * _speed


func _draw() -> void:
	var flown := _flown()
	if _tracer:
		# Bright tracer: a long hot streak with a glow.
		draw_line(-_dir * minf(32.0, flown), Vector2.ZERO, Color(_colour, 0.3), 6.0)
		draw_line(-_dir * minf(28.0, flown), Vector2.ZERO, _colour.lightened(0.5), 2.5)
		draw_circle(Vector2.ZERO, 3.5, Color(1, 1, 0.9))
		return
	if _heavy:
		if _hidden:
			return   # inside the hull it's punching through
		# A fat glowing slug (much fatter from a MAG Cannon).
		var t := slug_scale
		if t > 1.0:
			draw_circle(Vector2.ZERO, 9.0 * t * 1.6, Color(_colour, 0.12))
		draw_line(-_dir * minf(26.0 * t, minf(flown, _since_exit)), Vector2.ZERO, Color(_colour, 0.5), 9.0 * t)
		draw_circle(Vector2.ZERO, 9.0 * t, Color(_colour, 0.3))
		draw_circle(Vector2.ZERO, 6.0 * t, _colour.lightened(0.4))
		return
	var alpha := 1.0
	if _fades:
		alpha = clampf(1.0 - _age / 0.25, 0.0, 1.0)   # gone quickly: less clutter
		if alpha <= 0.0:
			return
	draw_line(-_dir * minf(18.0, flown), Vector2.ZERO, Color(_colour, alpha), 3.0)
	draw_circle(Vector2.ZERO, 3.0, Color(_colour.lightened(0.4), alpha))


## Flak: the shell bursts at the aim point (or on contact) and hurts every enemy close by.
## A blast, not a direct hit, so fighters can't dodge it.
func make_flak(burst_after_px: float, radius_px: float) -> void:
	_burst_dist = maxf(burst_after_px, 10.0)
	_burst_r = radius_px


func _airburst() -> void:
	var view := get_parent()
	var source: Node2D = _shooter if is_instance_valid(_shooter) else null
	var nearby: Array = view.call("targets_near", position) if view.has_method("targets_near") else []
	for t in nearby:
		var node := t as Node2D
		if node == null or not is_instance_valid(node) or node.get_parent() != view or not (node.get("alive") == true):
			continue
		var f = node.get("faction")
		if f == null or not GD.is_hostile(_faction, int(f)) or node.get("only_on_purpose") == true:
			continue
		if position.distance_to(node.position) <= _burst_r + _hit_radius(node) * 0.5 and node.has_method("take_damage"):
			GD.hit_weapon = weapon_name
			node.call("take_damage", _damage, source)
			GD.hit_weapon = ""
			if _faction == GD.Faction.UNE:
				GD.damage_dealt += _damage
	# A flak puff, not a fireball (v0.9.185).
	var puff_script: GDScript = load("res://scripts/flak_burst.gd")
	var puff: Node2D = puff_script.new()
	view.add_child(puff)
	puff.call("setup", position, _burst_r * 0.9)
	queue_free()
