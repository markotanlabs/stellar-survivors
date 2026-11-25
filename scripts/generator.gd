extends RefCounted
## Builds the six systems of the prototype tutorial map.
## Positions inside a system are in range units, with (0, 0) at the centre glow.

const GD = preload("res://scripts/game_data.gd")

# Galaxy view positions, from the tutorial map drawing.
const GALAXY_POSITIONS := [
	Vector2(175, 445),  # 0 colony system
	Vector2(268, 350),  # 1 home (Earth)
	Vector2(395, 332),  # 2 Roid Rebels
	Vector2(750, 320),  # 3 neutral (upper)
	Vector2(556, 425),  # 4 neutral (lower)
	Vector2(808, 445),  # 5 Sons of Philip (Mars)
]
const LINKS := [[0, 1], [1, 2], [2, 3], [2, 4], [3, 4], [4, 5]]

const SOL_ALLOYS := 45   # Alloys in Sol's rocks (x5 economy; was 9)

## Real stars near Earth, by a simple one-word name, for neutral systems.
const STAR_NAMES := [
	"Sirius", "Vega", "Altair", "Procyon", "Fomalhaut", "Arcturus", "Pollux", "Capella",
	"Castor", "Denebola", "Proxima", "Barnard", "Kapteyn", "Lalande", "Luyten", "Teegarden",
	"Kruger", "Gliese", "Wolf", "Ross", "Lacaille", "Groombridge", "Trappist", "Ceti",
	"Eridani", "Centauri", "Draconis", "Pavonis", "Reticuli", "Indi", "Cygni", "Hydri",
]
const NUMERALS := ["II", "III", "IV", "V", "VI", "VII"]


## A few different star names for this run, so neutral systems change every time.
static func _star_names(rng: RandomNumberGenerator, count: int) -> Array:
	var pool: Array = STAR_NAMES.duplicate()
	var picked: Array = []
	for i: int in count:
		var at := rng.randi() % pool.size()
		picked.append(pool[at])
		pool.remove_at(at)
	return picked

static func _planet_colour(rng: RandomNumberGenerator) -> Color:
	var options := ["c27a4a", "6f9a5a", "8a7fb0", "b8a27a", "5f8fa8"]
	var hex: String = options[rng.randi() % options.size()]
	return Color(hex)


static func build_map(rng: RandomNumberGenerator) -> Array:
	var systems: Array = []
	systems.append(_colony_system(rng))
	systems.append(_home_system(rng))
	systems.append(_rebel_system(rng))
	var names := _star_names(rng, 2)
	systems.append(_random_system(rng, String(names[0]), GD.Faction.NEUTRAL))
	systems.append(_random_system(rng, String(names[1]), GD.Faction.NEUTRAL))
	for i in [3, 4]:
		var neutral: Dictionary = systems[i]
		neutral["dealer"] = {"pos": _place(rng, neutral, 30.0, 90.0)}
	systems.append(_mars_system(rng))
	for i in systems.size():
		systems[i]["index"] = i
		systems[i]["galaxy_pos"] = GALAXY_POSITIONS[i]
	_add_exits(systems)
	# Sol always holds exactly SOL_ALLOYS Alloys in its rocks, to push expansion.
	_set_field_alloys(rng, systems[1], SOL_ALLOYS)
	_trim_field_alloys(rng, systems[2], 2 * _field_alloys(systems[1]))
	_add_rebel_defenders(systems[2])
	_add_tech_base(systems[1], 2)
	return systems


static func _empty_system(name: String, faction: int) -> Dictionary:
	return {
		"name": name,
		"faction": faction,
		"planets": [],
		"gas_giants": [],
		"fields": [],
		"rich": [],
		"giant": {},
		"structures": [],
		"ships": [],
		"exits": [],
		"taken": [],
		"tech_bases": [],
		"dealer": {},
		"type": "",   # "asteroid_field": far more asteroids, and none ever come back
	}


# --- placement helpers -------------------------------------------------------

static func _place(rng: RandomNumberGenerator, sys: Dictionary, min_r: float, max_r: float) -> Vector2:
	var taken: Array = sys["taken"]
	for _attempt in 300:
		var p := Vector2.RIGHT.rotated(rng.randf() * TAU) * rng.randf_range(min_r, max_r)
		var ok := true
		for q in taken:
			var other: Vector2 = q
			if p.distance_to(other) < GD.MIN_SPACING:
				ok = false
				break
		if ok:
			taken.append(p)
			return p
	var fallback := Vector2.RIGHT.rotated(rng.randf() * TAU) * max_r
	taken.append(fallback)
	return fallback


static func _reserve(sys: Dictionary, p: Vector2) -> Vector2:
	var taken: Array = sys["taken"]
	taken.append(p)
	return p


static func _rock_shape(rng: RandomNumberGenerator) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var n := 7
	for i in n:
		var a := TAU * i / n
		pts.append(Vector2.RIGHT.rotated(a) * rng.randf_range(0.7, 1.0))
	return pts


## A group of asteroids strung along an orbit (v0.9.239): the rocks lie on an arc of the
## circle round orbit_centre (the star, or a planet / gas giant / giant rock they circle)
## that passes through centre, like a stretch of a real asteroid belt.
static func _make_field(rng: RandomNumberGenerator, centre: Vector2, is_gas: bool, extra_rocks: int = 0, orbit_centre: Vector2 = Vector2.ZERO) -> Dictionary:
	var rocks: Array = []
	var count := rng.randi_range(4, 8) + extra_rocks   # more rocks, each leaner (was 2-5)
	# A gas pack always has 1 Gas rock, sometimes 2, very rarely 3; its other rocks can
	# still carry Alloys.
	var gas_rocks := 0
	if is_gas:
		var roll := rng.randf()
		gas_rocks = 3 if roll < 0.03 else (2 if roll < 0.2 else 1)
		gas_rocks = mini(gas_rocks, count)
	for i in count:
		var alloys := 0
		var gas := 0
		if i < gas_rocks:
			gas = 1
		elif not is_gas or rng.randf() < 0.6:
			alloys = GD.roll_alloy_yield(rng)
		rocks.append({
			"offset": Vector2.ZERO,
			"size": rock_size(rng, alloys, gas),
			"spin": rng.randf_range(-0.6, 0.6),
			"shape": _rock_shape(rng),
			"alloys": alloys,
			"gas": gas,
		})
	_keep_a_plain_rock(rocks)
	# Lay them along the orbit: an arc about 2.6 units per rock, jittered in and out.
	var rel := centre - orbit_centre
	var orbit_r := maxf(rel.length(), 8.0)
	var mid := rel.angle()
	var span := minf(count * 2.6 / orbit_r, 1.4)
	var far := 4.0
	for i in rocks.size():
		var t := (float(i) + rng.randf_range(-0.35, 0.35)) / maxf(1.0, float(rocks.size() - 1)) - 0.5
		var a := mid + t * span
		var r := orbit_r + rng.randf_range(-1.8, 1.8)
		var spot := orbit_centre + Vector2.RIGHT.rotated(a) * r
		rocks[i]["offset"] = spot - centre
		far = maxf(far, (spot - centre).length() + 1.5)
	rocks.shuffle()   # so the rich ones aren't always at one end
	return {"pos": centre, "gas": is_gas, "rocks": rocks, "radius": far}


## A rock's size follows its Alloys (v0.9.239): 1 is small, 8 is a big lump. Plain rocks
## stay smallish; Gas rocks keep a random size.
static func rock_size(rng: RandomNumberGenerator, alloys: int, gas: int) -> float:
	if gas > 0:
		return rng.randf_range(0.6, 1.2)
	if alloys <= 0:
		return rng.randf_range(0.45, 0.85)
	return 0.55 + 0.13 * float(alloys) + rng.randf_range(-0.05, 0.05)


## A point on one of the system's orbit rings (35, 70 or 100 units, the faint circles),
## keeping clear of other points of interest. Belts follow those "gravity lines".
static func _place_on_ring(rng: RandomNumberGenerator, sys: Dictionary, rings: Array = [35.0, 70.0, 100.0]) -> Vector2:
	var taken: Array = sys["taken"]
	for _attempt in 300:
		var r := float(rings[rng.randi() % rings.size()]) + rng.randf_range(-2.5, 2.5)
		var p := Vector2.RIGHT.rotated(rng.randf() * TAU) * r
		var ok := true
		for q in taken:
			if p.distance_to(Vector2(q)) < GD.MIN_SPACING * 0.7:
				ok = false
				break
		if ok:
			taken.append(p)
			return p
	return _place(rng, sys, 30.0, 100.0)


## Every field keeps at least one plain rock: if all of them carry Alloys, the poorest
## hands its Alloys to the others (same total), so rich rocks stand out against plain ones.
static func _keep_a_plain_rock(rocks: Array) -> void:
	var poorest: Dictionary = {}
	for rock in rocks:
		if int(rock["alloys"]) <= 0 and int(rock["gas"]) <= 0:
			return
		if int(rock["gas"]) <= 0 and (poorest.is_empty() or int(rock["alloys"]) < int(poorest["alloys"])):
			poorest = rock
	if poorest.is_empty() or rocks.size() < 2:
		return
	var spare := int(poorest["alloys"])
	poorest["alloys"] = 0
	for rock in rocks:
		while spare > 0 and not is_same(rock, poorest) and int(rock["gas"]) <= 0 and int(rock["alloys"]) < 8:
			rock["alloys"] = int(rock["alloys"]) + 1
			spare -= 1
	poorest["alloys"] = spare   # nowhere to put it: keep it rather than lose Alloys


## Asteroid groups loosely orbiting a planet or gas giant (not bound by the spacing rule).
static func _orbit_fields(rng: RandomNumberGenerator, sys: Dictionary, body_pos: Vector2, body_radius: float, count: int) -> void:
	var fields: Array = sys["fields"]
	for i in count:
		var p := body_pos + Vector2.RIGHT.rotated(rng.randf() * TAU) * (body_radius + rng.randf_range(7.0, 12.0))
		if p.length() > GD.SYSTEM_RADIUS - 10.0:
			continue
		fields.append(_make_field(rng, p, rng.randf() < 0.15, 0, body_pos))   # a ring arc round the body


static func _make_rich(rng: RandomNumberGenerator, pos: Vector2) -> Dictionary:
	var gold := rng.randf() < 0.25
	var size := rng.randf_range(2.1, 2.8)   # bigger than regular rocks
	return {
		"pos": pos,
		"gold": gold,
		"size": size,
		"health": 25.0 * size,
		"shape": _rock_shape(rng),
		"spin": rng.randf_range(-0.3, 0.3),
	}


static func _random_planet(rng: RandomNumberGenerator, name: String, pos: Vector2) -> Dictionary:
	return {
		"name": name,
		"pos": pos,
		"radius": 9.0,
		"colour": _planet_colour(rng),
		"owner": GD.Faction.NEUTRAL,
		"pops": 0,
		"health": 2000.0,
		"kind": "random",
		"capacity": 10,
		"growth_progress": 0,
		"stability": 10,
		"devastation": 0,
		"buildings": [],
	}


static func _add_ship(sys: Dictionary, type_id: String, faction: int, pos: Vector2, facing: float, role: String = "", route: Array = []) -> void:
	var ships: Array = sys["ships"]
	ships.append({"type": type_id, "faction": faction, "pos": pos, "facing": facing, "role": role, "route": route})


# --- systems -------------------------------------------------------------------

static func _random_system(rng: RandomNumberGenerator, name: String, faction: int) -> Dictionary:
	var sys := _empty_system(name, faction)
	var planets: Array = sys["planets"]
	var n_planets := 2 if rng.randf() < 0.15 else 1
	# Planets take Roman numerals in orbit order, like "Tau Ceti IV": a random first one.
	var first := rng.randi() % (NUMERALS.size() - 1)
	for i in n_planets:
		var numeral: String = NUMERALS[first + i]
		planets.append(_random_planet(rng, "%s %s" % [name, numeral], _place(rng, sys, 25.0, 100.0)))
	var giants: Array = sys["gas_giants"]
	var n_giants := 2 if rng.randf() < 0.15 else 1
	for i in n_giants:
		giants.append({"pos": _place(rng, sys, 25.0, 100.0), "radius": 14.0, "colour": Color("9c8a5e")})
	var fields: Array = sys["fields"]
	for i in rng.randi_range(3, 5):
		fields.append(_make_field(rng, _place_on_ring(rng, sys), rng.randf() < 0.15))
	for p in planets:
		_orbit_fields(rng, sys, p["pos"], p["radius"], rng.randi_range(1, 2))
	for gg in giants:
		_orbit_fields(rng, sys, gg["pos"], gg["radius"], 1)
	var rich: Array = sys["rich"]
	for i in (2 if rng.randf() < 0.4 else 1):
		rich.append(_make_rich(rng, _place(rng, sys, 25.0, 105.0)))
	return sys


static func _home_system(rng: RandomNumberGenerator) -> Dictionary:
	var sys := _empty_system("Sol", GD.Faction.UNE)
	var earth_pos := _reserve(sys, Vector2(-34, 18))
	# Sol's gas giant always sits at the far left of the system.
	var giant_pos := _reserve(sys, Vector2(-98, rng.randf_range(-12.0, 4.0)))
	var planets: Array = sys["planets"]
	planets.append({
		"name": "Earth",
		"pos": earth_pos,
		"radius": 9.5,
		"colour": Color("2f6fb4"),
		"owner": GD.Faction.UNE,
		"pops": 1,
		"health": 2000.0,
		"kind": "earth",
		"capacity": 10,
		"growth_progress": 0,
		"stability": 10,
		"devastation": 0,
		"buildings": [],
	})
	# The first Starbase sits below the star, about halfway to the edge, with its rocks.
	var sb_pos := _reserve(sys, Vector2(0, 58))
	var structures: Array = sys["structures"]
	structures.append({"type": "starbase", "faction": GD.Faction.UNE, "pos": sb_pos, "health": GD.STARBASE_HEALTH})
	# The Shipyard sits in orbit by Earth, so flying home to Earth repairs the fleet.
	# Far enough right that its repair ring doesn't overlap Earth.
	structures.append({"type": "shipyard", "faction": GD.Faction.UNE, "pos": earth_pos + Vector2(25.0, -4.0), "health": 500.0})
	# The starting fleet waits halfway between Earth and the Starbase.
	var fleet_pos := (earth_pos + sb_pos) * 0.5
	_add_ship(sys, "capital", GD.Faction.UNE, fleet_pos, 0.0)
	for i in 3:
		_add_ship(sys, "corvette", GD.Faction.UNE, fleet_pos + Vector2(6, -3.5 + i * 3.5), 0.0)
	var giants: Array = sys["gas_giants"]
	giants.append({"pos": giant_pos, "radius": 14.0, "colour": Color("9c8a5e")})
	var fields: Array = sys["fields"]
	# One clean rock group inside the starting Starbase's orbit: 25 Alloys a day.
	var starter := _make_field(rng, sb_pos + Vector2(6, 5), false)
	var rocks: Array = []
	var starter_alloys := [5, 0, 4, 6, 0, 3, 2, 5]   # 25 Alloys a day (v0.9.239: more, leaner rocks)
	var s_rel := sb_pos + Vector2(6, 5)
	for i in starter_alloys.size():
		var a := s_rel.angle() + (float(i) / 7.0 - 0.5) * 0.3   # a short arc, all inside the Starbase's reach
		var spot := Vector2.RIGHT.rotated(a) * (s_rel.length() + rng.randf_range(-1.6, 1.6))
		rocks.append({
			"offset": spot - s_rel,
			"size": rock_size(rng, int(starter_alloys[i]), 0),
			"spin": rng.randf_range(-0.6, 0.6),
			"shape": _rock_shape(rng),
			"alloys": int(starter_alloys[i]),
			"gas": 0,
		})
	starter["rocks"] = rocks
	starter["radius"] = 11.0
	starter["starter"] = true
	fields.append(starter)
	for i in 3:
		fields.append(_make_field(rng, _place_on_ring(rng, sys, [70.0, 100.0]), i == 2))
	var g0: Dictionary = giants[0]
	_orbit_fields(rng, sys, g0["pos"], g0["radius"], 1)
	var rich: Array = sys["rich"]
	rich.append(_make_rich(rng, _place(rng, sys, 40.0, 105.0)))
	rich.append(_make_rich(rng, _place(rng, sys, 40.0, 105.0)))
	return sys


static func _colony_system(rng: RandomNumberGenerator) -> Dictionary:
	var sys := _empty_system("Haven", GD.Faction.NEUTRAL)
	var planets: Array = sys["planets"]
	var planet := _random_planet(rng, "Haven (continental)", _reserve(sys, Vector2(10, -20)))
	planet["colour"] = Color("4f8a3a")
	planet["kind"] = "continental"
	planets.append(planet)
	# The hiding Rebels' asteroid field sits on the outer edge.
	var hideout := _reserve(sys, Vector2(-92, 48))
	var fields: Array = sys["fields"]
	fields.append(_make_field(rng, hideout, false, 2))
	for i in 3:
		_add_ship(sys, "corvette", GD.Faction.REBELS, hideout + Vector2(-2 + i * 2.0, -1 + (i % 2) * 2.0), 0.0, "hideout")
	# A second hideout: 3 Rebel Frigates lying in another cluster (v0.9.175).
	var frigate_den := _place(rng, sys, 40.0, 90.0)
	fields.append(_make_field(rng, frigate_den, false, 2))
	for i in 3:
		_add_ship(sys, "frigate", GD.Faction.REBELS, frigate_den + Vector2(-2.5 + i * 2.5, -1.0 + (i % 2) * 2.0), 0.0, "hideout")
	# A molten world nobody can live on, a gas giant, more rocks, and one of each rich asteroid.
	var molten := _random_planet(rng, "Haven II (molten)", _place(rng, sys, 45.0, 100.0))
	molten["colour"] = Color("c8552c")
	molten["kind"] = "molten"
	molten["capacity"] = 0
	planets.append(molten)
	var giants: Array = sys["gas_giants"]
	giants.append({"pos": _place(rng, sys, 45.0, 100.0), "radius": 14.0, "colour": Color("7f9ab0")})
	for i in 3:
		fields.append(_make_field(rng, _place_on_ring(rng, sys), i == 0))
	var rich: Array = sys["rich"]
	var silver := _make_rich(rng, _place(rng, sys, 30.0, 105.0))
	silver["gold"] = false
	rich.append(silver)
	var gold := _make_rich(rng, _place(rng, sys, 30.0, 105.0))
	gold["gold"] = true
	rich.append(gold)
	return sys


static func _rebel_system(rng: RandomNumberGenerator) -> Dictionary:
	var sys := _empty_system("Rebel Rocks", GD.Faction.REBELS)
	sys["type"] = "asteroid_field"
	var giant_pos := _reserve(sys, Vector2(18, 4))
	sys["giant"] = {"pos": giant_pos, "radius": 6.0, "health": 1200.0, "shape": _rock_shape(rng)}
	# More asteroids than average, orbiting the giant asteroid.
	var fields: Array = sys["fields"]
	# Packed: an inner and outer ring around the giant, plus belts scattered across the system.
	# Asteroid Field: roughly twice the rocks of a regular system.
	for i in 9:
		var p := giant_pos + Vector2.RIGHT.rotated(TAU * i / 9.0 + rng.randf_range(-0.2, 0.2)) * rng.randf_range(14.0, 21.0)
		fields.append(_make_field(rng, p, rng.randf() < 0.12, 3, giant_pos))
	var ambush_spots: Array = []
	for i in 11:
		var p := giant_pos + Vector2.RIGHT.rotated(TAU * i / 11.0 + rng.randf_range(-0.2, 0.2)) * rng.randf_range(27.0, 40.0)
		fields.append(_make_field(rng, p, rng.randf() < 0.12, 2, giant_pos))
		if i == 1 or i == 5 or i == 8:
			ambush_spots.append(p)
	# Three packs of 3 Frigates lying in wait in the outer rocks (hidden by the field),
	# springing on anything that comes close (v0.9.174).
	for spot in ambush_spots:
		for i in 3:
			_add_ship(sys, "frigate", GD.Faction.REBELS, spot + Vector2(-2.5 + i * 2.5, -1.0 + (i % 2) * 2.0), 0.0, "hideout")
	for i in 14:
		var p := Vector2.RIGHT.rotated(rng.randf() * TAU) * rng.randf_range(50.0, 108.0)
		if p.distance_to(giant_pos + Vector2(0, -34)) < 12.0:
			continue
		fields.append(_make_field(rng, p, rng.randf() < 0.15, 0))
	var structures: Array = sys["structures"]
	var sb_pos := giant_pos + Vector2(0, -34)
	_reserve(sys, sb_pos)
	structures.append({"type": "starbase", "faction": GD.Faction.REBELS, "pos": sb_pos, "health": GD.STARBASE_HEALTH})
	structures.append({"type": "shipyard", "faction": GD.Faction.REBELS, "pos": sb_pos + Vector2(4.5, 1.5), "health": 500.0})
	var rich: Array = sys["rich"]
	rich.append(_make_rich(rng, _place(rng, sys, 60.0, 105.0)))
	# One patrol pack of 3 Corvettes looping through Rebel space (was two, v0.9.174: the
	# Frigate ambushes took the other one's place).
	for pack in 1:
		var route: Array = []
		for w in 4:
			route.append(Vector2.RIGHT.rotated(TAU * w / 4.0 + pack * 0.8) * (55.0 + pack * 25.0))
		var start: Vector2 = route[0]
		for i in 3:
			_add_ship(sys, "corvette", GD.Faction.REBELS, start + Vector2(i * 2.5, (i % 2) * 2.5), 0.0, "patrol", route)
	return sys


static func _mars_system(rng: RandomNumberGenerator) -> Dictionary:
	var sys := _empty_system("Mars", GD.Faction.SONS)
	var mars_pos := _reserve(sys, Vector2(30, 10))
	var planets: Array = sys["planets"]
	planets.append({
		"name": "Mars",
		"pos": mars_pos,
		"radius": 9.0,
		"colour": Color("b4583a"),
		"owner": GD.Faction.SONS,
		"pops": 8,
		"health": 2000.0,
		"kind": "mars",
		"capacity": 10,
		"growth_progress": 0,
		"stability": 10,
		"devastation": 0,
		"buildings": [],
	})
	var structures: Array = sys["structures"]
	var sb_pos := mars_pos + Vector2(-14, -12)
	structures.append({"type": "starbase", "faction": GD.Faction.SONS, "pos": sb_pos, "health": GD.STARBASE_HEALTH})
	structures.append({"type": "shipyard", "faction": GD.Faction.SONS, "pos": sb_pos + Vector2(4.5, 1.5), "health": 500.0})
	# The phalanx: two lines of Destroyers in front of Mars, facing the way in.
	# Shields nearly touching, like a pike phalanx.
	var step := GD.ship_pixels("destroyer") * 1.15 / GD.UNIT
	for i in 6:
		_add_ship(sys, "destroyer", GD.Faction.SONS, mars_pos + Vector2(-26, (i - 2.5) * step), PI, "phalanx")
	for i in 5:
		_add_ship(sys, "destroyer", GD.Faction.SONS, mars_pos + Vector2(-26 + step * 1.2, (i - 2.0) * step), PI, "phalanx")
	# The Mars garrison: heavy ships close to the planet, and a screen of small ships
	# around the Starbase, so slipping past the Rebels doesn't mean an easy Mars.
	_add_ship(sys, "battleship", GD.Faction.SONS, mars_pos + Vector2(-12, 0), PI, "guard")
	# The Mars home guard (v0.9.174): Battleships and Destroyers anchored round the planet
	# that never leave it ("anchor": they turn and fight where they stand), and more
	# Destroyers out on the flanks that do give chase.
	for at in [Vector2(-4, -22), Vector2(-4, 22), Vector2(22, 0)]:
		_add_ship(sys, "battleship", GD.Faction.SONS, mars_pos + at, PI, "anchor")
	for at in [Vector2(-16, -14), Vector2(-16, 14), Vector2(12, -18), Vector2(12, 18)]:
		_add_ship(sys, "destroyer", GD.Faction.SONS, mars_pos + at, PI, "anchor")
	for at in [Vector2(-20, -30), Vector2(-20, 30), Vector2(0, -32), Vector2(0, 32)]:
		_add_ship(sys, "destroyer", GD.Faction.SONS, mars_pos + at, PI, "guard")
	_add_ship(sys, "carrier", GD.Faction.SONS, mars_pos + Vector2(4, 14), PI, "guard")
	for i in 2:
		_add_ship(sys, "cruiser", GD.Faction.SONS, mars_pos + Vector2(-14, -10 + i * 20), PI, "guard")
	for i in 3:
		_add_ship(sys, "frigate", GD.Faction.SONS, mars_pos + Vector2(14, -14 + i * 14), PI, "guard")
	for i in 6:
		_add_ship(sys, "corvette", GD.Faction.SONS, sb_pos + Vector2.RIGHT.rotated(TAU * i / 6.0) * 6.0, PI, "guard")
	var fields: Array = sys["fields"]
	for i in 2:
		fields.append(_make_field(rng, _place_on_ring(rng, sys), false))
	return sys


static func _add_exits(systems: Array) -> void:
	for link in LINKS:
		var a: int = link[0]
		var b: int = link[1]
		_add_exit(systems[a], systems[b])
		_add_exit(systems[b], systems[a])


static func _add_exit(from_sys: Dictionary, to_sys: Dictionary) -> void:
	var from_g: Vector2 = from_sys["galaxy_pos"]
	var to_g: Vector2 = to_sys["galaxy_pos"]
	var dir := (to_g - from_g).normalized()
	var exits: Array = from_sys["exits"]
	exits.append({"to": to_sys["index"], "name": to_sys["name"], "dir": dir, "pos": dir * (GD.SYSTEM_RADIUS - 5.0)})


static func _add_rebel_defenders(sys: Dictionary) -> void:
	# 12 Corvettes parked at the back of the system, away from the way in from Earth.
	var exits: Array = sys["exits"]
	var entry_dir := Vector2.LEFT
	for e in exits:
		if e["to"] == 1:
			entry_dir = e["dir"]
	var back := -entry_dir * 80.0
	var side := entry_dir.orthogonal()
	for i in 12:
		var row := i / 4
		var col := i % 4
		var p := back + side * (col - 1.5) * 3.0 - entry_dir * row * 3.0
		_add_ship(sys, "corvette", GD.Faction.REBELS, p, entry_dir.angle())


static func _add_tech_base(sys: Dictionary, toward_index: int) -> void:
	# A hidden tech base just before the warp lane to another system, with one guard.
	var exits: Array = sys["exits"]
	for e in exits:
		if e["to"] != toward_index:
			continue
		var e_pos: Vector2 = e["pos"]
		var dir: Vector2 = e["dir"]
		var base_pos := e_pos - dir * 24.0
		var bases: Array = sys["tech_bases"]
		bases.append({"pos": base_pos})
		# Three guards hold the mouth of the warp lane, well away from the lab itself,
		# so shots at them don't hit the lab by accident.
		var post := e_pos - dir * 9.0
		for i in 3:
			_add_ship(sys, "corvette", GD.Faction.REBELS, post + dir.orthogonal() * (-3.0 + i * 3.0), (-dir).angle(), "guard")



## Trims or tops up a system's rock Alloys so they add up to exactly target.
## The starter rocks by the first Starbase are the last to lose Alloys.
static func _set_field_alloys(rng: RandomNumberGenerator, sys: Dictionary, target: int) -> void:
	var total := _field_alloys(sys)
	for pass_starter in [false, true]:
		var pool: Array = []
		for field in Array(sys["fields"]):
			if bool(field.get("starter", false)) != pass_starter:
				continue
			for rock in Array(field["rocks"]):
				if int(rock["alloys"]) > 0:
					pool.append(rock)
		while total > target and not pool.is_empty():
			var i := _poorest_index(rng, pool)
			var cut: Dictionary = pool[i]
			cut["alloys"] = int(cut["alloys"]) - 1
			total -= 1
			if int(cut["alloys"]) <= 0:
				pool.remove_at(i)
	var rocks: Array = []
	for field in Array(sys["fields"]):
		for rock in Array(field["rocks"]):
			if int(rock.get("gas", 0)) == 0:
				rocks.append(rock)
	if rocks.is_empty():
		return
	# Topping up favours rocks that already carry 1-2 Alloys (making 2s and 3s), then plain
	# rocks get 2 at once, so few 1-Alloy rocks are left.
	var guard := 0
	while total < target and guard < 10000:
		guard += 1
		var growing: Array = []
		var plain: Array = []
		for r in rocks:
			if int(r["alloys"]) > 0 and int(r["alloys"]) < 5:
				growing.append(r)
			elif int(r["alloys"]) == 0:
				plain.append(r)
		if not growing.is_empty():
			var rock: Dictionary = growing[rng.randi() % growing.size()]
			rock["alloys"] = int(rock["alloys"]) + 1
			total += 1
		elif not plain.is_empty():
			var rock: Dictionary = plain[rng.randi() % plain.size()]
			var add := mini(2, target - total)
			rock["alloys"] = add
			total += add
		else:
			var rock: Dictionary = rocks[rng.randi() % rocks.size()]
			rock["alloys"] = int(rock["alloys"]) + 1
			total += 1


## The index of a rock with the fewest Alloys (ties picked at random).
static func _poorest_index(rng: RandomNumberGenerator, pool: Array) -> int:
	var low := 999
	var picks: Array = []
	for i in pool.size():
		var a := int(pool[i]["alloys"])
		if a < low:
			low = a
			picks = [i]
		elif a == low:
			picks.append(i)
	return int(picks[rng.randi() % picks.size()])


## Alloys a system's asteroids yield in all (one pass of every rock).
static func _field_alloys(sys: Dictionary) -> int:
	var total := 0
	for field in Array(sys["fields"]):
		for rock in Array(field["rocks"]):
			total += int(rock["alloys"])
	return total


## Rebel Rocks never respawns its asteroids, so it gets plenty of rocks but only about
## twice Sol's Alloys: yields are worn down one point at a time, spread across the rocks.
static func _trim_field_alloys(rng: RandomNumberGenerator, sys: Dictionary, target: int) -> void:
	var rocks: Array = []
	for field in Array(sys["fields"]):
		for rock in Array(field["rocks"]):
			if int(rock["alloys"]) > 0:
				rocks.append(rock)
	var total := _field_alloys(sys)
	var guard := 0
	while total > target and not rocks.is_empty() and guard < 100000:
		guard += 1
		var i := _poorest_index(rng, rocks)
		var rock: Dictionary = rocks[i]
		rock["alloys"] = int(rock["alloys"]) - 1
		total -= 1
		if int(rock["alloys"]) <= 0:
			rocks.remove_at(i)
