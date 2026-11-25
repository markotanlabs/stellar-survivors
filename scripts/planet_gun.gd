extends Node2D
## A fixed gun mount: the PD MAG on a planet, or a Starbase's stand-in Gatlings.
## Fires at the nearest enemy in range.

const GD = preload("res://scripts/game_data.gd")
const Sfx = preload("res://scripts/sfx.gd")
const Projectile = preload("res://scripts/projectile.gd")

var faction := GD.Faction.UNE
var weapon_id := "pd_mag"
var _cooldown := 2.0
var _burst_left := 0
var _burst_timer := 0.0
var _target: Node2D = null
var _charging := false
var _shots := 0
var active := true   # dormant guns (the Rebel Rock's) wait until switched on
var range_mult := 1.0   # Starbase guns reach further (GD.STARBASE_RANGE_MULT)
var target_strongest := false   # MAG Cannon: aim at the toughest enemy ship in reach
var _aim := -PI / 2.0           # barrel angle (MAG Cannon)
var _recoil := 0.0              # MAG Cannon: the barrel kicks back when it fires, then runs out again
var draw_base := false          # a MAG on a planet: draws its fortress base, turret and barrel


var _was_idle := true


func setup(pos_px: Vector2, owner_faction: int, new_weapon: String = "pd_mag", new_range_mult: float = 1.0) -> void:
	range_mult = new_range_mult
	position = pos_px
	faction = owner_faction
	weapon_id = new_weapon
	# Start somewhere random in the reload, so guns built together don't fire as one.
	_cooldown = randf_range(0.5, maxf(2.0, float(GD.WEAPONS[new_weapon].get("cooldown", 2.0))))


func _process(delta: float) -> void:
	if not active:
		return
	if weapon_id == "mag_cannon" or draw_base or weapon_id == "mini_mag":
		queue_redraw()   # the barrel turns every frame
	_recoil = maxf(0.0, _recoil - delta * 1.4)
	var weapon: Dictionary = GD.WEAPONS[weapon_id]
	if _burst_left > 0:
		_burst_timer -= delta
		if _charging:
			queue_redraw()
		if _burst_timer <= 0.0:
			if is_instance_valid(_target):
				_shoot(weapon, _target)
			_burst_left -= 1
			_burst_timer = float(weapon["gap"])
		return
	_cooldown -= delta
	if _cooldown > 0.0:
		return
	var reach := float(weapon["range"]) * GD.UNIT * range_mult * _station_bonus()
	var best: Node2D = null
	var best_d := reach
	var best_score := -1.0
	for t in get_tree().get_nodes_in_group("targets"):
		var node := t as Node2D
		if node == null or node.get_parent() != get_parent() or not node.visible:
			continue
		if not (node.get("alive") == true) or not GD.is_hostile(faction, int(node.get("faction"))):
			continue
		if weapon.has("charge") and node.is_in_group("ordnance"):
			continue   # a MAG never wastes its shot on a torpedo or missile
		var d := position.distance_to(node.position)
		if target_strongest:
			# Strongest = most total health; ships only, anything in reach.
			if d > reach or not node.is_in_group("ships") or _rock_in_the_way(node):
				continue
			var toughness := float(node.get("max_hull")) + float(node.get("max_armor"))
			if best == null or toughness > best_score:
				best_score = toughness
				best = node
		elif d <= best_d and not _rock_in_the_way(node):
			best_d = d
			best = node
	if best == null:
		_cooldown = 0.15   # performance: an idle gun looks around a few times a second
		_was_idle = true
		return
	# A heavy gun waking from idle waits a random part of its reload first, so the
	# guns on one station don't all open up on the same frame when an enemy arrives.
	# (Not the MAG Cannon: it's the only gun on its platform, so it starts charging at once.)
	if _was_idle and float(weapon["cooldown"]) >= 2.0 and not target_strongest:
		_was_idle = false
		_cooldown = randf_range(0.0, float(weapon["cooldown"]) * 0.6)
		return
	_was_idle = false
	_cooldown = float(weapon["cooldown"]) * randf_range(0.92, 1.08)   # a little jitter keeps neighbours out of step
	_target = best
	_burst_left = int(weapon["burst"])
	_burst_timer = float(weapon.get("charge", 0.0))
	_charging = _burst_timer > 0.0
	Sfx.play("mag_charge" if _charging else "gatling", self, -12.0 if _charging else (-15.0 if weapon_id == "pdc" else -10.0))


func _shoot(weapon: Dictionary, target: Node2D) -> void:
	if weapon.has("charge"):
		Sfx.play("mag_fire", self)
	if weapon_id == "mag_cannon":
		_recoil = 1.0
	_charging = false
	queue_redraw()
	var shot := Projectile.new()
	get_parent().add_child(shot)
	var spread := float(weapon.get("spread", 0.3)) * GD.UNIT
	var scatter := Vector2.RIGHT.rotated(randf() * TAU) * sqrt(randf()) * spread
	# Long shots lead moving targets so they still land at range.
	var lead := Vector2.ZERO
	var vel = target.get("motion")   # ships measure their own velocity as "motion"
	if vel is Vector2:
		lead = (vel as Vector2) * position.distance_to(target.position) / (float(weapon["speed"]) * GD.UNIT)
	var origin := position
	if weapon_id == "mini_mag":
		origin = position + Vector2.RIGHT.rotated(_aim) * 0.95 * GD.UNIT * GD.STATION_SCALE
	if draw_base or weapon_id == "mag_cannon":
		origin = position + Vector2.RIGHT.rotated(_aim) * _barrel_length()
	shot.setup_free(origin, target.position + lead + scatter, float(weapon["damage"]), float(weapon["speed"]) * GD.UNIT, Color(String(weapon["colour"])), self, float(weapon["range"]) * GD.UNIT * range_mult * _station_bonus() * 1.2)
	shot.weapon_name = String(weapon.get("name", ""))   # so MAG shots from stations count as MAGs
	shot.intended = target
	shot.vs_small = float(weapon.get("vs_small", 1.0))
	_shots += 1
	if weapon.has("charge"):
		shot.set_style(false, false, false, true)
		if weapon_id == "mag_cannon":
			shot.slug_scale = 1.8   # thick slug, wide hitbox, big strong splash
	elif String(weapon["name"]) == "K9 Gatling Gun":
		shot.set_style(_shots % 5 == 0, _shots % 5 != 0, false)


func _draw() -> void:
	if draw_base:
		_draw_fortress()
	if weapon_id == "mini_mag":
		# A Starbase's Mini MAG mount (v0.9.222): a small turret with twin rails that
		# tracks its target, so you can see the guns the card gave you.
		if is_instance_valid(_target):
			_aim = lerp_angle(_aim, (_target.position - position).angle(), 0.15)
		var d := Vector2.RIGHT.rotated(_aim)
		var n := d.orthogonal()
		var u := GD.UNIT * GD.STATION_SCALE
		draw_circle(Vector2.ZERO, 0.34 * u, Color("0b0e14"))
		draw_circle(Vector2.ZERO, 0.28 * u, Color("5d666f"))
		for s: float in [-1.0, 1.0]:
			draw_line(n * s * 0.09 * u, d * 0.95 * u + n * s * 0.09 * u, Color("0b0e14"), 4.0)
			draw_line(n * s * 0.09 * u, d * 0.95 * u + n * s * 0.09 * u, Color("b9c2cc"), 2.0)
		draw_circle(Vector2.ZERO, 0.12 * u, GD.faction_colour(faction))
	if weapon_id == "mag_cannon" and not draw_base:
		if is_instance_valid(_target):
			_aim = lerp_angle(_aim, (_target.position - position).angle(), 0.15)
		_draw_mag_cannon()
	elif weapon_id == "mag_cannon" or draw_base:
		# The cannon's long barrel, turning to follow its target.
		if is_instance_valid(_target):
			_aim = lerp_angle(_aim, (_target.position - position).angle(), 0.15)
		var dir := Vector2.RIGHT.rotated(_aim)
		var length := _barrel_length()
		draw_line(Vector2.ZERO, dir * length, Color("0b0e14"), 11.0)
		draw_line(Vector2.ZERO, dir * length, Color("9aa6b2"), 7.0)
		draw_line(dir.orthogonal() * -1.5, dir * length + dir.orthogonal() * -1.5, Color("c9ced6"), 2.0)
		draw_circle(dir * length, 4.5, Color("c9ced6"))
		if draw_base:
			# The turret it turns on.
			draw_circle(Vector2.ZERO, 0.42 * GD.UNIT, Color("0b0e14"))
			draw_circle(Vector2.ZERO, 0.36 * GD.UNIT, Color("5d666f"))
			draw_circle(Vector2.ZERO, 0.16 * GD.UNIT, GD.faction_colour(faction))
	if not _charging:
		return
	var weapon: Dictionary = GD.WEAPONS[weapon_id]
	var total := float(weapon.get("charge", 1.0))
	var t := clampf(1.0 - _burst_timer / total, 0.0, 1.0)
	var glow := Color(String(weapon["colour"]))
	var at := Vector2.ZERO
	if weapon_id == "mini_mag":
		at = Vector2.RIGHT.rotated(_aim) * 0.95 * GD.UNIT * GD.STATION_SCALE
	if draw_base or weapon_id == "mag_cannon":
		at = Vector2.RIGHT.rotated(_aim) * _barrel_length()   # the charge builds at the muzzle
	draw_circle(at, 4.0 + 14.0 * t, Color(glow, 0.15 + 0.25 * t))
	draw_circle(at, 2.0 + 6.0 * t, Color(glow.lightened(0.5), 0.5 + 0.5 * t))


## Long-Range Batteries: your station guns (the ones with a range multiplier) reach further.
func _station_bonus() -> float:
	return GD.station_range_mult if range_mult > 1.0 and faction == GD.Faction.UNE else 1.0


func _barrel_length() -> float:
	return (3.5 * GD.STATION_SCALE if weapon_id == "mag_cannon" and not draw_base else 1.7) * GD.UNIT


## The MAG Cannon station's gun: the biggest in the game. A massive armoured turret
## with a counterweight at the back, twin rails over three units long with coils
## between them that light up one by one as it charges, a huge muzzle brake, and a
## heavy recoil kick when it fires. Drawn in the gun's own frame (x = along the barrel).
func _draw_mag_cannon() -> void:
	var u := GD.UNIT * GD.STATION_SCALE   # the station gun grows with its platform
	var ink := Color("0b0e14")
	var steel := Color("6f7a86")
	var steel_dark := Color("3d454f")
	var steel_light := Color("b9c2cc")
	var colour := GD.faction_colour(faction)
	var weapon: Dictionary = GD.WEAPONS["mag_cannon"]
	var glow := Color(String(weapon["colour"]))
	var charge := 0.0
	if _charging:
		charge = clampf(1.0 - _burst_timer / float(weapon.get("charge", 1.0)), 0.0, 1.0)
	var kick := -0.45 * u * ease(_recoil, 0.4)   # the barrel slides back along its cradle
	draw_set_transform(Vector2.ZERO, _aim, Vector2.ONE)
	# Shadow under the whole gun.
	draw_rect(Rect2(Vector2(-1.3 * u, -0.75 * u) + Vector2(0.15, 0.25) * u, Vector2(4.9 * u, 1.5 * u)), Color(0, 0, 0, 0.3))
	# Rails: two heavy slabs with a dark gap between, coils across the gap.
	var rail_start := 0.6 * u + kick
	var rail_end := 3.2 * u + kick
	for s: float in [-1.0, 1.0]:
		var rail := Rect2(Vector2(rail_start, (0.08 if s > 0.0 else -0.36) * u), Vector2(rail_end - rail_start, 0.28 * u))
		draw_rect(rail, steel)
		draw_line(Vector2(rail.position.x, rail.position.y + 2.0), Vector2(rail.end.x, rail.position.y + 2.0), steel_light, 2.0)
		draw_rect(rail, ink, false, 2.5)
	draw_rect(Rect2(Vector2(rail_start, -0.08 * u), Vector2(rail_end - rail_start, 0.16 * u)), Color(0.04, 0.05, 0.08))
	var coils := 9
	for i: int in coils:
		var x := rail_start + (rail_end - rail_start) * (i + 0.5) / float(coils)
		var lit := clampf(charge * float(coils) - float(i), 0.0, 1.0)
		draw_rect(Rect2(Vector2(x - 0.06 * u, -0.42 * u), Vector2(0.12 * u, 0.84 * u)), steel_dark)
		draw_rect(Rect2(Vector2(x - 0.04 * u, -0.07 * u), Vector2(0.08 * u, 0.14 * u)), Color(glow, 0.2 + 0.8 * lit))
		if lit > 0.0:
			draw_circle(Vector2(x, 0), (0.1 + 0.12 * lit) * u, Color(glow, 0.25 * lit))
	# The muzzle brake: a massive block with vents out the sides.
	var brake := Rect2(Vector2(rail_end - 0.1 * u, -0.5 * u), Vector2(0.5 * u, 1.0 * u))
	draw_rect(brake, steel_dark)
	for k: int in 3:
		var vx := brake.position.x + 0.08 * u + k * 0.13 * u
		draw_rect(Rect2(Vector2(vx, -0.5 * u), Vector2(0.06 * u, 0.22 * u)), ink)
		draw_rect(Rect2(Vector2(vx, 0.28 * u), Vector2(0.06 * u, 0.22 * u)), ink)
	draw_rect(brake, ink, false, 2.5)
	# The turret housing: an armoured block with a counterweight out the back.
	var housing := PackedVector2Array([Vector2(1.0, -0.75) * u, Vector2(1.0, 0.75) * u, Vector2(-0.6, 0.85) * u, Vector2(-1.0, 0.5) * u, Vector2(-1.0, -0.5) * u, Vector2(-0.6, -0.85) * u])
	draw_colored_polygon(housing, steel.lerp(colour, 0.25))
	draw_rect(Rect2(Vector2(-1.35, -0.45) * u, Vector2(0.4, 0.9) * u), steel_dark)   # counterweight
	draw_rect(Rect2(Vector2(-1.35, -0.45) * u, Vector2(0.4, 0.9) * u), ink, false, 2.5)
	for x: float in [-0.5, 0.0, 0.5]:
		draw_line(Vector2(x, -0.78) * u, Vector2(x, 0.78) * u, Color(ink, 0.45), 2.0)
	draw_line(housing[5], housing[0], steel_light, 3.0)
	var closed := housing.duplicate()
	closed.append(housing[0])
	draw_polyline(closed, ink, 3.5)
	# The gunner's viewport and a faction stripe.
	draw_rect(Rect2(Vector2(-0.75, -0.62) * u, Vector2(0.2, 1.24) * u), colour)
	draw_rect(Rect2(Vector2(0.35, -0.2) * u, Vector2(0.4, 0.4) * u), Color(glow, 0.35 + 0.5 * charge))
	draw_rect(Rect2(Vector2(0.35, -0.2) * u, Vector2(0.4, 0.4) * u), ink, false, 2.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## A planet-mounted MAG's base: a squat little military fortress. Eight-sided
## armoured walls with crenellations, a corner tower at each side, firing slits,
## and the turret in the middle.
func _draw_fortress() -> void:
	var u := GD.UNIT
	var wall := Color("4a535d")
	var dark := Color("0b0e14")
	draw_circle(Vector2(0.1, 0.18) * u, 1.15 * u, Color(0, 0, 0, 0.35))
	var octo := PackedVector2Array()
	for i: int in 8:
		octo.append(Vector2.RIGHT.rotated(PI / 8.0 + i * TAU / 8.0) * 1.0 * u)
	draw_colored_polygon(octo, wall)
	var rim := octo.duplicate()
	rim.append(octo[0])
	draw_polyline(rim, dark, 3.0)
	# Crenellations along the top of the wall.
	for i: int in 16:
		var a := i * TAU / 16.0
		var c := Vector2.RIGHT.rotated(a) * 0.98 * u
		var d := Vector2.RIGHT.rotated(a)
		var n := d.orthogonal() * 0.09 * u
		draw_colored_polygon(PackedVector2Array([c - n, c + n, c + n + d * 0.14 * u, c - n + d * 0.14 * u]), Color("6b747e"))
	# Inner courtyard, lit slightly on its top-left edge.
	draw_circle(Vector2.ZERO, 0.72 * u, Color("2b3138"))
	draw_arc(Vector2.ZERO, 0.72 * u, PI * 1.05, PI * 1.75, 12, Color(1, 1, 1, 0.12), 2.0)
	# Four squat towers with firing slits.
	for i: int in 4:
		var at := Vector2.RIGHT.rotated(PI * 0.25 + i * PI * 0.5) * 0.98 * u
		draw_rect(Rect2(at - Vector2(0.2, 0.2) * u, Vector2(0.4, 0.4) * u), Color("5d666f"))
		draw_rect(Rect2(at - Vector2(0.2, 0.2) * u, Vector2(0.4, 0.4) * u), dark, false, 2.0)
		draw_line(at - Vector2(0.1, 0.0) * u, at + Vector2(0.1, 0.0) * u, dark, 2.0)
	# A little flag on the top-left tower.
	var pole := Vector2.RIGHT.rotated(PI * 1.25) * 0.98 * u
	draw_line(pole, pole + Vector2(0, -0.55) * u, Color("c9ced6"), 2.0)
	draw_colored_polygon(PackedVector2Array([pole + Vector2(0, -0.55) * u, pole + Vector2(0.32, -0.46) * u, pole + Vector2(0, -0.37) * u]), GD.faction_colour(faction))


## Starbase guns won't fire through an asteroid that's worth resources.
func _rock_in_the_way(target: Node2D) -> bool:
	if faction == GD.Faction.NEUTRAL or not get_parent().has_method("asteroids"):
		return false
	var seg_min := Vector2(minf(position.x, target.position.x), minf(position.y, target.position.y))
	var seg_max := Vector2(maxf(position.x, target.position.x), maxf(position.y, target.position.y))
	for r in get_parent().call("asteroids"):
		var rock := r as Node2D
		if rock == null or rock == target or not is_instance_valid(rock) or not (rock.get("alive") == true):
			continue
		# Cheap box test first: rocks nowhere near the firing line are skipped (v0.9.241).
		var pad := 4.0 * GD.UNIT
		if rock.position.x < seg_min.x - pad or rock.position.x > seg_max.x + pad or rock.position.y < seg_min.y - pad or rock.position.y > seg_max.y + pad:
			continue
		var worth := int(rock.get("yield_alloys")) > 0 or int(rock.get("yield_gas")) > 0 or String(rock.get("kind")) in ["silver", "gold"]
		if not worth:
			continue
		var closest := Geometry2D.get_closest_point_to_segment(rock.position, position, target.position)
		if closest.distance_to(rock.position) <= float(rock.call("radius_px")) + 6.0:
			return true
	return false
