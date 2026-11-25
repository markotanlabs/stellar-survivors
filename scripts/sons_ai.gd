extends Node
## The Sons of Philip, a rival that plays by your rules. Dormant until the Roid Rebels are
## broken (their base destroyed). Then, once a day, they:
##   1. collect income from their planets and Starbases,
##   2. build ships at their Shipyard (mostly Destroyers for the phalanx),
##   3. expand: Starbases on asteroid fields in nearby systems, then colonies on empty planets,
##   4. send waves: every 2 minutes, picking up where the Rebel waves left off, plus every
##      ship their Shipyard has built since. Waves leave Mars and travel lane by lane,
##      attacking your nearest station on the way until they reach Earth,
##   5. pick cards: XP from your ships they destroy plus a slow trickle, dealt 3 and picked
##      to their taste (armor, shields, hulls), announced so you can see them snowball.

const GD = preload("res://scripts/game_data.gd")
const ShipScript = preload("res://scripts/ship.gd")
const BuildSite = preload("res://scripts/build_site.gd")
const Sfx = preload("res://scripts/sfx.gd")

const HOME := 5                 # Mars
const START_ALLOYS := 60
const PLANET_INCOME := 4        # Alloys per day per planet they own
const STARBASE_INCOME := 3      # Alloys per day per Starbase
const WAVE_GAP := 120.0         # seconds between Philip's waves
const WAVE_WARP := 4.0          # seconds a wave spends in the lane between systems
const MOVE_TIMEOUT := 45.0      # seconds a wave crossing a system takes at most
# Strength points per ship, for wave sizes (a Rebel Corvette wave of 15 = 15 points).
const POINTS := {"corvette": 1, "frigate": 2, "destroyer": 3, "cruiser": 4, "battleship": 6}
const CARD_XP := 12             # XP per card (doubles like yours, gently)
const CARD_TRICKLE_DAYS := 5    # a free card every so many active days
const MAX_STARBASES := 4
const SETTLE_SECONDS := 30.0

# What the Sons like in a card (higher = picked more often). Speed means little to a phalanx.
const CARD_TASTE := {
	"Hardened Plating": 3.0, "Reinforced Hulls": 3.0, "Shield Emitters": 3.0,
	"Fortified Starbases": 2.0, "Rapid Loaders": 2.0, "Efficient Shipyards": 1.0,
	"Overclocked Thrusters": 0.5,
}

var main: Node = null
var active := false
var alloys := START_ALLOYS
var xp := 0
var xp_needed := CARD_XP
var cards: Array = []
var _days := 0
var _queue: Array = []          # [{"type", "left"}]
var _sites: Array = []          # [{"node": BuildSite, "system", "left"}]
var _settling: Array = []       # [{"planet", "system", "left"}]
var _wave_left := WAVE_GAP
var _base_points := 0   # first wave's strength (GD.PHILIP_OPENER)
var _waves_sent := 0
var _groups: Array = []         # waves on the move (see _update_groups)

# The Sons' own card bonuses: their cards buff only their ships.
var mods := {"armor_mult": 1.0, "hull_mult": 1.0, "shield_bonus": 0.0, "speed_mult": 1.0, "cooldown_mult": 1.0, "build_mult": 1.0, "starbase_mult": 1.0}


func activate() -> void:
	if active:
		return
	active = true
	GD.sons_mods = mods
	# The ships already at Mars are its garrison: they stay home and never join a strike.
	for child in main.system_views[HOME].get_children():
		var ship := child as ShipScript
		if ship != null and ship.faction == GD.Faction.SONS:
			ship.set_meta("garrison", true)
	# Pacing: Philip wakes at whichever comes first, Rebel Rock falling or the 10:00 mark,
	# and his first wave leaves at once. Then he doubles every wave: a sudden-death clock.
	_base_points = GD.PHILIP_OPENER
	_wave_left = 0.0
	main.hud.notify("The Sons of Philip are mobilizing. Expect them to expand, build and strike back.", HOME, Vector2.ZERO)
	Sfx.say("sons_awake", "The Sons of Philip are on the move, Commander.", 5.0)


## Once a day (the economy tick).
func day() -> void:
	if not active:
		return
	_days += 1
	var systems: Array = main.systems
	for s in systems:
		for p in Array(s["planets"]):
			if p["owner"] == GD.Faction.SONS:
				alloys += PLANET_INCOME
		for st in Array(s["structures"]):
			if st["type"] == "starbase" and int(st["faction"]) == GD.Faction.SONS:
				alloys += STARBASE_INCOME
	if _days % CARD_TRICKLE_DAYS == 0:
		_earn_card()
	_plan()


## Every frame: build timers, Starbase sites and colonies settling.
func update(delta: float) -> void:
	if not active:
		return
	_update_wave_timer(delta)
	_update_groups(delta)
	if not _queue.is_empty():
		var item: Dictionary = _queue[0]
		item["left"] = float(item["left"]) - delta
		if float(item["left"]) <= 0.0:
			_queue.pop_front()
			_launch_ship(String(item["type"]))
	for site in _sites.duplicate():
		var node: BuildSite = site["node"]
		if not is_instance_valid(node):
			_sites.erase(site)
			continue
		node.progress = float(node.progress) + delta
		if float(node.progress) >= float(node.build_time):
			_finish_site(site)
	for c in _settling.duplicate():
		var planet: Dictionary = c["planet"]
		if planet["owner"] != GD.Faction.NEUTRAL or int(planet["pops"]) > 0:
			_settling.erase(c)
			continue
		c["left"] = float(c["left"]) - delta
		planet["sons_progress"] = 1.0 - float(c["left"]) / SETTLE_SECONDS
		if float(c["left"]) <= 0.0:
			_settling.erase(c)
			planet.erase("sons_progress")
			planet["owner"] = GD.Faction.SONS
			planet["pops"] = 1
			main.hud.notify("The Sons of Philip colonized %s." % String(planet["name"]), int(c["system"]), Vector2(planet["pos"]) * GD.UNIT)
			main.system_views[int(c["system"])].queue_redraw()


func add_xp(amount: int) -> void:
	if not active:
		return
	xp += amount
	while xp >= xp_needed:
		xp -= xp_needed
		xp_needed = int(xp_needed * 1.5)
		_earn_card()


# --- decisions ---------------------------------------------------------------------

func _plan() -> void:
	# Expand: a Starbase on a nearby asteroid field, then a colony.
	if alloys >= 40 and _starbase_count() + _sites.size() < MAX_STARBASES and _queue.size() < 2:
		if _place_starbase():
			return
	if alloys >= 30 and _settling.is_empty():
		if _colonize():
			return
	# Otherwise build ships: mostly Battleships and Destroyers, a few others.
	if _queue.size() < 3 and _has_shipyard():
		var roll := randf()
		var type_id := "destroyer"
		if roll < 0.35:
			type_id = "battleship"
		elif roll < 0.8:
			type_id = "destroyer"
		elif roll < 0.92:
			type_id = "frigate"
		else:
			type_id = "corvette"
		var cost := int(GD.ship_stats(type_id)["cost_alloys"]) / GD.ALLOY_SCALE   # Philip's budget is in the old units
		if alloys >= cost:
			alloys -= cost
			_queue.append({"type": type_id, "left": float(GD.ship_stats(type_id)["build_time"]) * float(mods["build_mult"])})


func _home_ships() -> Array:
	var out: Array = []
	for child in main.system_views[HOME].get_children():
		var ship := child as ShipScript
		if ship != null and ship.alive and ship.faction == GD.Faction.SONS and ship.role == "guard" and not ship.has_meta("garrison"):
			out.append(ship)
	return out


func _has_shipyard() -> bool:
	for st in Array(main.systems[HOME]["structures"]):
		if st["type"] == "shipyard" and int(st["faction"]) == GD.Faction.SONS:
			return true
	return false


func _starbase_count() -> int:
	var n := 0
	for s in main.systems:
		for st in Array(s["structures"]):
			if st["type"] == "starbase" and int(st["faction"]) == GD.Faction.SONS:
				n += 1
	return n


## Nearby systems first: Mars, then its neighbours, then further out. Never Sol.
func _expansion_systems() -> Array:
	var order: Array = [HOME]
	var paths := {}
	for s in main.systems:
		var i := int(s["index"])
		if i == HOME or i == 1:
			continue
		var path: Array = main.call("_path_between", HOME, i)
		if path.is_empty():
			continue
		paths[i] = path.size()
	var rest := paths.keys()
	rest.sort_custom(func(a, b) -> bool: return int(paths[a]) < int(paths[b]))
	order.append_array(rest)
	return order


func _spot_free(sys: Dictionary, pos: Vector2) -> bool:
	for p in Array(sys["planets"]):
		if pos.distance_to(Vector2(p["pos"])) < float(p["radius"]) + 3.0:
			return false
	for st in Array(sys["structures"]):
		if pos.distance_to(Vector2(st["pos"])) < GD.PLACE_GAP * 2.0:
			return false
	for site in _sites:
		if int(site["system"]) == int(sys["index"]) and pos.distance_to(site["node"].position / GD.UNIT) < GD.PLACE_GAP * 2.0:
			return false
	return pos.length() > 8.0 and pos.length() < GD.SYSTEM_RADIUS - 6.0


func _place_starbase() -> bool:
	for i in _expansion_systems():
		var sys: Dictionary = main.systems[i]
		# Not where you already have a Starbase.
		var contested := false
		for st in Array(sys["structures"]):
			if st["type"] == "starbase" and int(st["faction"]) == GD.Faction.UNE:
				contested = true
		if contested:
			continue
		for field in Array(sys["fields"]):
			var spot: Vector2 = Vector2(field["pos"]) + Vector2(2.0, 2.0)
			if not _spot_free(sys, spot):
				continue
			alloys -= 40
			var node := BuildSite.new()
			main.system_views[i].add_child(node)
			node.setup("starbase", i, spot * GD.UNIT)
			node.status = "building"
			node.tint = Color("d9a441")
			node.owner_text = "SONS OF PHILIP"
			_sites.append({"node": node, "system": i})
			main.hud.notify("The Sons of Philip are building a Starbase in %s." % String(sys["name"]), i, spot * GD.UNIT)
			return true
	return false


func _finish_site(site: Dictionary) -> void:
	var node: BuildSite = site["node"]
	var i := int(site["system"])
	var st := {"type": "starbase", "faction": GD.Faction.SONS, "pos": node.position / GD.UNIT, "health": GD.STARBASE_HEALTH * float(mods["starbase_mult"])}
	main.system_views[i].add_structure(st)
	_sites.erase(site)
	node.queue_free()
	main.hud.notify("The Sons of Philip finished a Starbase in %s." % String(main.systems[i]["name"]), i, Vector2(st["pos"]) * GD.UNIT)


func _colonize() -> bool:
	for i in _expansion_systems():
		var sys: Dictionary = main.systems[i]
		for p in Array(sys["planets"]):
			if p["owner"] != GD.Faction.NEUTRAL or int(p["pops"]) > 0 or int(p.get("capacity", 0)) <= 0:
				continue
			if float(p.get("colony_progress", 0.0)) > 0.0:
				continue   # you're already settling it
			alloys -= 30
			_settling.append({"planet": p, "system": i, "left": SETTLE_SECONDS})
			main.hud.notify("The Sons of Philip are settling %s. Get there first?" % String(p["name"]), i, Vector2(p["pos"]) * GD.UNIT)
			return true
	return false


func _launch_ship(type_id: String) -> void:
	var view: Node2D = main.system_views[HOME]
	var yard := Vector2.ZERO
	for st in Array(main.systems[HOME]["structures"]):
		if st["type"] == "shipyard" and int(st["faction"]) == GD.Faction.SONS:
			yard = Vector2(st["pos"])
	var ship := ShipScript.new()
	view.add_child(ship)
	ship.setup(type_id, GD.Faction.SONS, (yard + Vector2(randf_range(-3.0, 3.0), randf_range(2.0, 5.0))) * GD.UNIT, PI, "guard")
	ship.destroyed.connect(Callable(main, "_on_enemy_destroyed"))


## Where to hit in a system: your planet, else your station. INF when you hold nothing there.
func _une_target(sys: Dictionary) -> Vector2:
	for p in Array(sys["planets"]):
		if p["owner"] == GD.Faction.UNE:
			return Vector2(p["pos"])
	for st in Array(sys["structures"]):
		if int(st["faction"]) == GD.Faction.UNE:
			return Vector2(st["pos"])
	return Vector2.INF


# --- cards ---------------------------------------------------------------------------

## Deal 3 cards the Sons can use and pick one to their taste.
func _earn_card() -> void:
	var pool: Array = []
	for card_name in CARD_TASTE.keys():
		pool.append(card_name)
	pool.shuffle()
	var hand := pool.slice(0, 3)
	var total := 0.0
	for card_name in hand:
		total += float(CARD_TASTE[card_name])
	var roll := randf() * total
	var pick := String(hand[0])
	for card_name in hand:
		roll -= float(CARD_TASTE[card_name])
		if roll <= 0.0:
			pick = String(card_name)
			break
	_apply(pick)
	cards.append(pick)
	main.hud.notify("The Sons of Philip gained %s (%d cards)." % [pick, cards.size()], HOME, Vector2.ZERO)


func _apply(card: String) -> void:
	match card:
		"Hardened Plating":
			mods["armor_mult"] = float(mods["armor_mult"]) * 1.1
		"Reinforced Hulls":
			mods["hull_mult"] = float(mods["hull_mult"]) * 1.15
		"Shield Emitters":
			mods["shield_bonus"] = float(mods["shield_bonus"]) + 25.0
		"Overclocked Thrusters":
			mods["speed_mult"] = float(mods["speed_mult"]) * 1.1
		"Rapid Loaders":
			mods["cooldown_mult"] = float(mods["cooldown_mult"]) * 0.9
		"Efficient Shipyards":
			mods["build_mult"] = float(mods["build_mult"]) * 0.9
		"Fortified Starbases":
			mods["starbase_mult"] = float(mods["starbase_mult"]) * 1.25
			for view in main.system_views:
				for child in view.get_children():
					var structure = child.get("structure")
					if structure is Dictionary and int(child.get("faction")) == GD.Faction.SONS and String(structure.get("type", "")) == "starbase":
						child.set("max_health", float(child.get("max_health")) * 1.25)
						child.set("health", float(child.get("health")) * 1.25)
	GD.sons_mods = mods
	# Every Sons ship gets the new bonus straight away.
	for view in main.system_views:
		for child in view.get_children():
			var ship := child as ShipScript
			if ship != null and ship.alive and ship.faction == GD.Faction.SONS:
				ship.apply_fleet_bonuses()



# --- Philip's waves -------------------------------------------------------------------

func _update_wave_timer(delta: float) -> void:
	_wave_left -= delta
	var built := _home_ships().size()
	var shown := maxf(_wave_left, 0.0)
	var text := "PHILIP'S WAVE %d  ·  STRENGTH %d  +%d BUILT  ·  %d:%02d" % [_waves_sent + 1, _wave_strength(), built, floori(shown / 60.0), int(shown) % 60]
	var urgent := _wave_left <= 15.0
	# Rebel Rock still standing: its waves keep coming too, so show both.
	if not bool(main.get("waves_over")):
		var rebel_left := maxf(0.0, float(main.get("wave_at")) - float(main.get("run_time")))
		text = "REBEL WAVE %d  ·  %d:%02d     |     " % [int(main.get("wave_n")) + 1, floori(rebel_left / 60.0), int(rebel_left) % 60] + text
		urgent = urgent or rebel_left <= 15.0
	main.hud.show_wave(text, urgent)
	if _wave_left <= 0.0:
		_wave_left = WAVE_GAP
		_launch_wave()


## 24, 48, 96, 192... points: each wave doubles the one before (sudden death).
func _wave_strength() -> int:
	return _base_points * int(pow(2, _waves_sent))


## Builds a wave from strength points (mostly Battleships and Destroyers), adds every
## ship the Shipyard has built since the last one, and sends it out of Mars.
func _launch_wave() -> void:
	var points := _wave_strength()
	var types: Array = []
	while points > 0:
		var roll := randf()
		if points >= 6 and roll < 0.3:
			types.append("battleship")
		elif points >= 3 and roll < 0.85:
			types.append("destroyer")
		elif points >= 2:
			types.append("frigate")
		else:
			types.append("corvette")
		points -= int(POINTS[types.back()])
	for ship in _home_ships():
		types.append(String(ship.type_id))
		ship.queue_free()
	_waves_sent += 1
	var group := {"id": _waves_sent, "types": types, "nodes": [], "system": HOME, "phase": "", "next": -1, "exit_px": Vector2.ZERO, "move_t": 0.0, "warp_left": 0.0, "came_from": -1}
	_groups.append(group)
	var yard := Vector2.ZERO
	for st in Array(main.systems[HOME]["structures"]):
		if st["type"] == "starbase" and int(st["faction"]) == GD.Faction.SONS:
			yard = Vector2(st["pos"])
	_spawn_group(group, yard * GD.UNIT, Vector2.LEFT)
	_plan_group(group)
	main.hud.notify("Philip's wave %d left Mars: %d ships." % [group["id"], types.size()], HOME, yard * GD.UNIT)
	Sfx.say("sons_wave", "The Sons of Philip have launched a wave, Commander.", 5.0)


## Puts a wave's ships into its current system: Destroyers in a tight line up front,
## shields nearly touching, Battleships behind them, the rest around.
func _spawn_group(group: Dictionary, at_px: Vector2, facing: Vector2) -> void:
	var view: Node2D = main.system_views[int(group["system"])]
	var side := facing.orthogonal()
	var destroyers: Array = []
	var others: Array = []
	for t in group["types"]:
		if String(t) == "destroyer":
			destroyers.append(t)
		else:
			others.append(t)
	var nodes: Array = []
	var spacing := GD.ship_pixels("destroyer") * 1.15
	for i in destroyers.size():
		var offset := side * (i - (destroyers.size() - 1) / 2.0) * spacing
		nodes.append(_spawn_ship(view, "destroyer", at_px + facing * 2.0 * GD.UNIT + offset, facing))
	for i in others.size():
		var t := String(others[i])
		var back := -facing * (3.0 if t == "battleship" else 5.0) * GD.UNIT
		var offset := side * (i - (others.size() - 1) / 2.0) * 2.5 * GD.UNIT
		nodes.append(_spawn_ship(view, t, at_px + back + offset, facing))
	group["nodes"] = nodes


func _spawn_ship(view: Node2D, type_id: String, pos_px: Vector2, facing: Vector2) -> Node2D:
	var ship := ShipScript.new()
	view.add_child(ship)
	ship.setup(type_id, GD.Faction.SONS, pos_px, facing.angle(), "raid")
	ship.raid_target = pos_px
	ship.destroyed.connect(Callable(main, "_on_enemy_destroyed"))
	return ship


## Decides what a wave does in the system it's in: hit your nearest station here; in Sol,
## go for Earth; otherwise head for the next lane toward your nearest station (or Sol).
func _plan_group(group: Dictionary) -> void:
	var here := int(group["system"])
	var sys: Dictionary = main.systems[here]
	var centre := _group_centre(group)
	var best := Vector2.INF
	for st in Array(sys["structures"]):
		if int(st["faction"]) == GD.Faction.UNE:
			var p: Vector2 = Vector2(st["pos"]) * GD.UNIT
			if best == Vector2.INF or centre.distance_to(p) < centre.distance_to(best):
				best = p
	group["kind"] = "station"
	if best == Vector2.INF and here == 1:
		var earth: Dictionary = Array(sys["planets"])[0]
		best = Vector2(earth["pos"]) * GD.UNIT
		group["kind"] = "earth"
	if best != Vector2.INF:
		group["phase"] = "fighting"
		_set_target(group, best)
		return
	# Nothing of yours here: on to the nearest system that has something (or Sol).
	var goal := 1
	var goal_len := 999
	for s in main.systems:
		var i := int(s["index"])
		if i == here:
			continue
		var has := false
		for st in Array(s["structures"]):
			if int(st["faction"]) == GD.Faction.UNE:
				has = true
		if not has and i != 1:
			continue
		var path: Array = main.call("_path_between", here, i)
		if path.size() >= 2 and path.size() < goal_len:
			goal_len = path.size()
			goal = i
	var route: Array = main.call("_path_between", here, goal)
	if route.size() < 2:
		group["phase"] = "fighting"
		return
	var next := int(route[1])
	var exit: Dictionary = main.call("_exit_between", here, next)
	group["next"] = next
	group["phase"] = "moving"
	group["move_t"] = 0.0
	group["exit_px"] = Vector2(exit["pos"]) * GD.UNIT
	_set_target(group, group["exit_px"])


func _set_target(group: Dictionary, target_px: Vector2) -> void:
	for ship in group["nodes"]:
		if is_instance_valid(ship):
			ship.raid_target = target_px


func _group_centre(group: Dictionary) -> Vector2:
	var total := Vector2.ZERO
	var n := 0
	for ship in group["nodes"]:
		if is_instance_valid(ship) and ship.alive:
			total += ship.position
			n += 1
	return total / n if n > 0 else Vector2.ZERO


func _update_groups(delta: float) -> void:
	var map := {}
	for group in _groups.duplicate():
		if String(group["phase"]) == "warping":
			group["warp_left"] = float(group["warp_left"]) - delta
			map[int(group["next"])] = int(map.get(int(group["next"]), 0)) + Array(group["types"]).size()
			if float(group["warp_left"]) <= 0.0:
				_arrive(group)
			continue
		var alive: Array = []
		for ship in group["nodes"]:
			if is_instance_valid(ship) and ship.alive:
				alive.append(ship)
		group["nodes"] = alive
		if alive.is_empty():
			_groups.erase(group)
			main.hud.notify("Philip's wave %d was destroyed." % group["id"], int(group["system"]), Vector2.ZERO)
			continue
		map[int(group["system"])] = int(map.get(int(group["system"]), 0)) + alive.size()
		if String(group["phase"]) == "fighting":
			# Its station is gone (or never was, in Sol): plan again.
			if String(group.get("kind", "")) == "station" and _station_gone(group):
				_plan_group(group)
			continue
		# Crossing a system: count time only while nobody is fighting.
		var busy := false
		for ship in alive:
			var foe = ship.get("_attacker")
			if is_instance_valid(foe) and foe.get_parent() == ship.get_parent():
				busy = true
				break
		if not busy:
			group["move_t"] = float(group["move_t"]) + delta
		var exit_px: Vector2 = group["exit_px"]
		if _group_centre(group).distance_to(exit_px) < 18.0 * GD.UNIT or float(group["move_t"]) > MOVE_TIMEOUT:
			# Into the lane: the ships leave this system and arrive in the next.
			var types: Array = []
			for ship in alive:
				types.append(String(ship.type_id))
				ship.queue_free()
			group["types"] = types
			group["nodes"] = []
			group["came_from"] = int(group["system"])
			group["phase"] = "warping"
			group["warp_left"] = WAVE_WARP
	GD.sons_waves_at = map


func _station_gone(group: Dictionary) -> bool:
	var target: Vector2 = Vector2.INF
	for ship in group["nodes"]:
		if is_instance_valid(ship):
			target = ship.raid_target
			break
	for st in Array(main.systems[int(group["system"])]["structures"]):
		if int(st["faction"]) == GD.Faction.UNE and (Vector2(st["pos"]) * GD.UNIT).distance_to(target) < 1.0:
			return false
	return true


func _arrive(group: Dictionary) -> void:
	var here := int(group["next"])
	var from := int(group["came_from"])
	group["system"] = here
	var exit: Dictionary = main.call("_exit_between", here, from)
	var e_pos: Vector2 = exit["pos"]
	var e_dir: Vector2 = exit["dir"]
	var entry := (e_pos - e_dir * (GD.WARP_TRIGGER + 4.0)) * GD.UNIT
	_spawn_group(group, entry, -e_dir)
	_plan_group(group)
	# Warn when it comes somewhere you have something.
	var yours := here == 1 or here == int(main.get("fleet_system"))
	for st in Array(main.systems[here]["structures"]):
		if int(st["faction"]) == GD.Faction.UNE:
			yours = true
	for p in Array(main.systems[here]["planets"]):
		if p["owner"] == GD.Faction.UNE:
			yours = true
	if yours:
		main.call("_warn", "fleet", here, entry)
		Sfx.say("sons_incoming", "Sons of Philip fleet incoming, Commander.", 5.0)
	main.hud.notify("Philip's wave %d (%d ships) entered %s." % [group["id"], Array(group["types"]).size(), String(main.systems[here]["name"])], here, entry)
