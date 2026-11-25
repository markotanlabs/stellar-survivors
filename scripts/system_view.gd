extends Node2D
## Draws one system: boundary, centre glow, planets, gas giants, asteroid fields,
## silver and gold asteroids, structures and warplane exits. Ships are child nodes.

signal exit_clicked(target_index: int)
signal planet_clicked(planet: Dictionary)
signal tech_base_destroyed(system_index: int, pos_px: Vector2)
signal rich_destroyed(system_index: int, pos_px: Vector2, gold: bool)
signal rebel_base_hit(system_index: int, attacker: Node2D)
signal rebel_base_destroyed(system_index: int)
signal bubble_clicked(planet: Dictionary)
signal planet_fallen(system_index: int, planet: Dictionary)
signal planet_hit(system_index: int, pos_px: Vector2, faction: int, planet: Dictionary)
signal starbase_hit(system_index: int, pos_px: Vector2, faction: int)
signal starbase_destroyed(system_index: int, structure: Dictionary)
signal rock_destroyed(system_index: int, pos_px: Vector2, kind: String, valuable: bool, alloys: int, gas: int)

const GD = preload("res://scripts/game_data.gd")
const ShipScript = preload("res://scripts/ship.gd")
const TechBase = preload("res://scripts/tech_base.gd")
const Asteroid = preload("res://scripts/asteroid.gd")
const RebelBase = preload("res://scripts/rebel_base.gd")
const FighterBay = preload("res://scripts/fighter_bay.gd")
const ResIcon = preload("res://scripts/res_icon.gd")
const PlanetSiege = preload("res://scripts/planet_siege.gd")
const StarbaseNode = preload("res://scripts/starbase.gd")
const ArmsDealer = preload("res://scripts/arms_dealer.gd")
const PlanetBody = preload("res://scripts/planet_body.gd")
const Smoke = preload("res://scripts/smoke.gd")
const PlanetGun = preload("res://scripts/planet_gun.gd")

var sys: Dictionary = {}
var wormhole_pos := Vector2.ZERO     # pixels
var wormhole_strength := 0.0         # 0 = closed, 1 = fully open
var focus_node: Node2D = null        # drawn with target brackets
var allow_planet_clicks := true      # off in Fleet Mode
var dealer: Node2D = null
var visited := false     # fog of war: terrain known once one of your ships has been here
var presence := false    # one of your ships or Starbases is here now
var sensed := false      # one jump from your presence: enemies show as red dots
var _fog: Node2D
var _shield_layer: Node2D = null   # planetary shields, drawn over the planet spheres
var _time := 0.0
var _font: Font


func setup(new_sys: Dictionary) -> void:
	sys = new_sys
	_font = ThemeDB.fallback_font
	# Planets and gas giants: spinning pixel-art spheres (added first, so ships and
	# stations draw over them). Shields go on a layer above.
	for g in Array(sys["gas_giants"]):
		var giant_body := PlanetBody.new()
		add_child(giant_body)
		giant_body.setup(g, true)
	for p in Array(sys["planets"]):
		var planet_body := PlanetBody.new()
		add_child(planet_body)
		planet_body.setup(p, false)
	_shield_layer = Node2D.new()
	add_child(_shield_layer)
	_shield_layer.draw.connect(_draw_shields)
	var ships: Array = sys["ships"]
	for s in ships:
		var ship := ShipScript.new()
		add_child(ship)
		var pos_units: Vector2 = s["pos"]
		ship.setup(s["type"], s["faction"], pos_units * GD.UNIT, s["facing"], String(s.get("role", "")))
		var route_px: Array = []
		for w in Array(s.get("route", [])):
			var w_units: Vector2 = w
			route_px.append(w_units * GD.UNIT)
		ship.route = route_px
	# Every asteroid is its own node, so it can be shot, bumped and replaced.
	var fields: Array = sys["fields"]
	for fi in fields.size():
		var f: Dictionary = fields[fi]
		var centre: Vector2 = f["pos"]
		var kind := "gas" if bool(f["gas"]) else "rock"
		for r in Array(f["rocks"]):
			var offset: Vector2 = r["offset"]
			_spawn_rock(kind, (centre + offset) * GD.UNIT, float(r["size"]), r["shape"], float(r["spin"]), int(r["alloys"]), int(r["gas"]), fi)
	for rich in Array(sys["rich"]):
		var pos: Vector2 = rich["pos"]
		_spawn_rock("gold" if bool(rich["gold"]) else "silver", pos * GD.UNIT, float(rich["size"]), rich["shape"], float(rich["spin"]), 0, 0, -1)
	var giant: Dictionary = sys["giant"]
	if not giant.is_empty():
		var rebel_base := RebelBase.new()
		add_child(rebel_base)
		var giant_pos: Vector2 = giant["pos"]
		rebel_base.setup(giant_pos * GD.UNIT, giant["shape"])
		rebel_base.first_hit.connect(func(attacker: Node2D) -> void: rebel_base_hit.emit(int(sys["index"]), attacker))
		rebel_base.base_destroyed.connect(func(_b: Node2D) -> void: rebel_base_destroyed.emit(int(sys["index"])))
	# Every planet gets a health pool (3,000, like a Starbase). It only counts while
	# someone owns the planet; Mars also fires a PD MAG.
	for p in Array(sys["planets"]):
		var siege := PlanetSiege.new()
		siege.planet = p
		siege.armed = String(p["kind"]) == "mars"
		var p_pos: Vector2 = p["pos"]
		siege.setup(p_pos * GD.UNIT, float(p["radius"]), int(p["owner"]), String(p["name"]))
		add_child(siege)
		siege.fallen.connect(_on_planet_fallen.bind(p))
		siege.hit.connect(func(s: Node2D) -> void: planet_hit.emit(int(sys["index"]), s.position, int(s.get("faction")), p))
	# Stand-in Starbase defences: 2 Gatlings each, until PDCs and drones exist.
	for st in Array(sys["structures"]):
		_spawn_station(st)
	_fog = Node2D.new()
	_fog.z_index = 15
	add_child(_fog)
	_fog.draw.connect(_draw_fog)
	var dealer_data: Dictionary = sys["dealer"]
	if not dealer_data.is_empty():
		dealer = ArmsDealer.new()
		add_child(dealer)
		var dealer_pos: Vector2 = dealer_data["pos"]
		dealer.setup(dealer_pos * GD.UNIT)
	var bases: Array = sys["tech_bases"]
	for b in bases:
		var base := TechBase.new()
		add_child(base)
		var base_pos: Vector2 = b["pos"]
		base.setup(base_pos * GD.UNIT)
		base.base_destroyed.connect(_on_base_destroyed)
	queue_redraw()


## A station finished by a Construction Ship joins the system.
func add_structure(st: Dictionary) -> void:
	var structures: Array = sys["structures"]
	structures.append(st)
	_spawn_station(st)
	queue_redraw()


## Every station can be shot down. Starbases carry 2 Gatlings, 2 PDCs and 2 Fighter Bays,
## all at double range.
func _spawn_station(st: Dictionary) -> void:
	if st["type"] != "starbase" and st["type"] != "shipyard" and st["type"] != "mag":
		return
	var st_pos: Vector2 = st["pos"]
	var guns: Array = []
	if st["type"] == "starbase":
		# Bastion loadout: 2 Gatlings and 4 PDCs around the hull, all at double range.
		var corners := [Vector2(-0.8, -0.8), Vector2(0.8, -0.8), Vector2(-0.8, 0.8), Vector2(0.8, 0.8), Vector2(0, -0.9), Vector2(0, 0.9)]
		for i in GD.STARBASE_GUNS.size():
			var gun := PlanetGun.new()
			add_child(gun)
			gun.setup((st_pos + Vector2(corners[i % corners.size()]) * GD.STATION_SCALE) * GD.UNIT, int(st["faction"]), String(GD.STARBASE_GUNS[i]), GD.STARBASE_RANGE_MULT)
			guns.append(gun)
		# Mini MAG Batteries (tech card): 1 Mini MAG per card taken, up to 3.
		if GD.starbase_mini_mags > 0 and int(st["faction"]) == GD.Faction.UNE:
			guns.append_array(_add_mini_mags(st_pos, 0, GD.starbase_mini_mags))
			st["mini_mags"] = GD.starbase_mini_mags
	if st["type"] == "mag":
		# MAG Cannon: one huge gun that charges up and fires a piercing slug at the
		# strongest enemy ship anywhere in the system (v0.9.154: system-wide reach).
		var cannon := PlanetGun.new()
		add_child(cannon)
		cannon.setup(st_pos * GD.UNIT, int(st["faction"]), "mag_cannon", GD.MAG_CANNON_REACH / float(GD.WEAPONS["mag_cannon"]["range"]))
		cannon.target_strongest = true
		guns.append(cannon)
	if st["type"] == "starbase":
		# Fighter Bays: one wing of 4 fighters each, launching at enemy ships in range.
		for i in GD.STARBASE_BAYS:
			var bay := FighterBay.new()
			add_child(bay)
			bay.setup((st_pos + Vector2(-1.2 + 2.4 * i, 0)) * GD.UNIT, int(st["faction"]), GD.STARBASE_RANGE_MULT)
			guns.append(bay)
	# The Starbase itself can be shot down.
	var body := StarbaseNode.new()
	add_child(body)
	body.setup(st)
	body.set_meta("guns", guns)
	body.set_meta("mini_mags", int(st.get("mini_mags", 0)))
	body.hit.connect(func(b: Node2D) -> void: starbase_hit.emit(int(sys["index"]), b.position, int(b.get("faction"))))
	body.base_destroyed.connect(_on_starbase_destroyed)


## Mini MAG mounts on a Starbase: left, right, then top (mounts have..want-1).
const MINI_MAG_MOUNTS := [Vector2(-1.1, 0.0), Vector2(1.1, 0.0), Vector2(0.0, -1.2)]


func _add_mini_mags(st_pos: Vector2, have: int, want: int) -> Array:
	var made: Array = []
	for i in range(have, mini(want, MINI_MAG_MOUNTS.size())):
		var gun := PlanetGun.new()
		add_child(gun)
		gun.setup((st_pos + Vector2(MINI_MAG_MOUNTS[i]) * GD.STATION_SCALE) * GD.UNIT, GD.Faction.UNE, "mini_mag", GD.STARBASE_MINI_MAG_RANGE)
		made.append(gun)
	return made


## Mini MAG Batteries just taken: every Starbase of yours in this system tops up to the
## current number of Mini MAGs.
func arm_starbases() -> void:
	for child in get_children():
		if child.get_script() != StarbaseNode or child.get("alive") == false:
			continue
		if int(child.get("faction")) != GD.Faction.UNE or int(child.get_meta("mini_mags", 0)) >= GD.starbase_mini_mags:
			continue
		var structure = child.get("structure")
		if not (structure is Dictionary) or String(structure.get("type", "")) != "starbase":
			continue   # Shipyards and MAG Cannons use the same body; only Starbases get the pair
		var have := int(child.get_meta("mini_mags", 0))
		child.set_meta("mini_mags", GD.starbase_mini_mags)
		var guns: Array = child.get_meta("guns", [])
		guns.append_array(_add_mini_mags((child as Node2D).position / GD.UNIT, have, GD.starbase_mini_mags))
		child.set_meta("guns", guns)


func _on_starbase_destroyed(body: Node2D) -> void:
	for gun in Array(body.get_meta("guns", [])):
		if is_instance_valid(gun):
			gun.queue_free()
	var st: Dictionary = body.get("structure")
	var structures: Array = sys["structures"]
	structures.erase(st)
	queue_redraw()   # the station's drawing goes with it
	starbase_destroyed.emit(int(sys["index"]), st)


func _on_planet_fallen(_siege: Node2D, planet: Dictionary) -> void:
	planet_fallen.emit(int(sys["index"]), planet)


func _on_base_destroyed(base: Node2D) -> void:
	tech_base_destroyed.emit(int(sys["index"]), base.position)


func _spawn_rock(kind: String, home_px: Vector2, size: float, shape: PackedVector2Array, spin: float, alloys: int, gas: int, field: int) -> Node2D:
	var rock := Asteroid.new()
	add_child(rock)
	rock.setup(kind, home_px, size, shape, spin, alloys, gas, field)
	rock.asteroid_destroyed.connect(_on_rock_destroyed)
	return rock


func _on_rock_destroyed(rock: Node2D) -> void:
	var kind := String(rock.get("kind"))
	if rock.get("last_hit_une") == true:
		rock_destroyed.emit(int(sys["index"]), rock.position, kind, int(rock.get("yield_alloys")) > 0 or int(rock.get("yield_gas")) > 0, int(rock.get("yield_alloys")), int(rock.get("yield_gas")))
	if kind == "silver" or kind == "gold":
		rich_destroyed.emit(int(sys["index"]), rock.position, kind == "gold")
		return
	# Asteroid Fields are mined out for good: nothing ever drifts back in.
	if String(sys.get("type", "")) == "asteroid_field":
		return
	# After a short random wait, a replacement with the same yield drifts in from the edge.
	var delay := randf_range(GD.RESPAWN_DELAY_MIN, GD.RESPAWN_DELAY_MAX)
	# You cashed its load in by shooting it: its replacement takes longer to turn up.
	if rock.get("last_hit_une") == true and (int(rock.get("yield_alloys")) > 0 or int(rock.get("yield_gas")) > 0):
		delay *= GD.SHOT_ROCK_RESPAWN_MULT
	var info := {
		"kind": kind,
		"home": rock.get("home"),
		"size": float(rock.get("size")) / GD.ASTEROID_SCALE,   # setup scales it again (fix: respawns grew 20% each time)
		"alloys": int(rock.get("yield_alloys")),
		"gas": int(rock.get("yield_gas")),
		"field": int(rock.get("field_id")),
	}
	get_tree().create_timer(delay, false).timeout.connect(_respawn_rock.bind(info))


func _respawn_rock(info: Dictionary) -> void:
	var kind := String(info["kind"])
	var home: Vector2 = info["home"]
	var dir := home.normalized() if home.length() > 1.0 else Vector2.RIGHT
	var edge := dir.rotated(randf_range(-0.6, 0.6)) * GD.SYSTEM_RADIUS * GD.UNIT
	var shape := PackedVector2Array()
	for i in 7:
		shape.append(Vector2.RIGHT.rotated(TAU * i / 7.0) * randf_range(0.7, 1.0))
	var fresh := _spawn_rock(kind, home, float(info["size"]), shape, randf_range(-0.6, 0.6), int(info["alloys"]), int(info["gas"]), int(info["field"]))
	fresh.call("start_drift", edge, GD.DRIFT_SECONDS)


## Live asteroid nodes in this system.
## The living asteroids in this system. Built once a frame and shared (v0.9.241): guns
## ask for it every time they check a firing line, and walking every child each time
## (ships, shots, smoke...) added up fast with the bigger belts.
var _rocks_cache: Array = []
var _rocks_frame := -1


func asteroids() -> Array:
	var frame := Engine.get_process_frames()
	if frame != _rocks_frame:
		_rocks_frame = frame
		_rocks_cache = []
		for child in get_children():
			if child.is_in_group("asteroids") and (child.get("alive") == true) and not child.is_queued_for_deletion():
				_rocks_cache.append(child)
	return _rocks_cache


const GRID_CELL := 4.0 * 32.0   # px
var _grid := {}
var _grid_frame := -1


## Targets near a point, from a grid rebuilt once a frame, so each shot only checks
## what's around it instead of every rock and ship in the system.
func targets_near(pos: Vector2, rings: int = 1) -> Array:
	var frame := Engine.get_process_frames()
	if frame != _grid_frame:
		_grid_frame = frame
		_rebuild_grid()
	var cx := int(floor(pos.x / GRID_CELL))
	var cy := int(floor(pos.y / GRID_CELL))
	var out: Array = []
	for dx in range(-rings, rings + 1):
		for dy in range(-rings, rings + 1):
			var key := Vector2i(cx + dx, cy + dy)
			if _grid.has(key):
				out.append_array(_grid[key])
	return out


func _rebuild_grid() -> void:
	_grid.clear()
	for child in get_children():
		var node := child as Node2D
		if node == null or not (node.is_in_group("targets") or node.is_in_group("asteroids")):
			continue   # rocks left "targets" for speed (v0.9.241) but shots still hit them
		var r = node.get("radius")
		var reach := float(r) * GD.UNIT if r != null else 0.0
		var x0 := int(floor((node.position.x - reach) / GRID_CELL))
		var x1 := int(floor((node.position.x + reach) / GRID_CELL))
		var y0 := int(floor((node.position.y - reach) / GRID_CELL))
		var y1 := int(floor((node.position.y + reach) / GRID_CELL))
		for x in range(x0, x1 + 1):
			for y in range(y0, y1 + 1):
				var key := Vector2i(x, y)
				if not _grid.has(key):
					_grid[key] = []
				_grid[key].append(node)


var _giant_puff_t := 1.5   # seconds until a gas giant vents again


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_time += delta
	# Gas giants vent big, slow plumes from their edge every few seconds.
	_giant_puff_t -= delta
	if _giant_puff_t <= 0.0:
		_giant_puff_t = randf_range(1.5, 3.5)
		for g in Array(sys["gas_giants"]):
			if randf() < 0.7:
				var r: float = float(g["radius"]) * GD.UNIT
				var c: Vector2 = Vector2(g["pos"]) * GD.UNIT
				var dir := Vector2.RIGHT.rotated(randf() * TAU)
				for i in randi_range(3, 5):
					var puff := Smoke.new()
					add_child(puff)
					puff.setup(c + dir * r * randf_range(0.92, 1.02) + Vector2(randf_range(-10.0, 10.0), randf_range(-10.0, 10.0)),
						r * randf_range(0.05, 0.09), Color(0.55, 0.78, 0.38, 0.3), randf_range(2.5, 4.0),   # gas is always green
						dir * randf_range(20.0, 40.0) + Vector2(randf_range(-8.0, 8.0), randf_range(-8.0, 8.0)), 2.6)
	queue_redraw()
	if _fog != null:
		_fog.queue_redraw()
	if _shield_layer != null:
		_shield_layer.queue_redraw()


func _bubble_pos(p: Dictionary) -> Vector2:
	var pos: Vector2 = p["pos"]
	var r: float = p["radius"]
	return pos * GD.UNIT + Vector2(0, -r * GD.UNIT - 70.0 * GD.screen_scale(self))


func _draw_fog() -> void:
	if visited:
		return
	var radius := GD.SYSTEM_RADIUS * GD.UNIT
	_fog.draw_circle(Vector2.ZERO, radius + 40.0, Color(0.02, 0.03, 0.05, 0.96))
	var faction: int = sys["faction"]
	_fog.draw_arc(Vector2.ZERO, radius, 0.0, TAU, 256, Color(GD.ring_colour(faction), 0.35), 6.0)
	var k := GD.screen_scale(self)
	var title := "UNEXPLORED"
	var sub := "Sensors show contacts as red dots" if sensed else "Send a ship to reveal this system"
	var tw := _font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 34).x
	var sw := _font.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
	_fog.draw_set_transform(Vector2(0, -20.0 * k), 0.0, Vector2(k, k))
	_fog.draw_string(_font, Vector2(-tw / 2.0, 0), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Color("93a3ad"))
	_fog.draw_string(_font, Vector2(-sw / 2.0, 34), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("6f8c93"))
	_fog.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Exits stay visible so you can still find your way.
	_draw_exits_on(_fog)


func _unhandled_input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	var click := event as InputEventMouseButton
	if click == null or not click.pressed or click.button_index != MOUSE_BUTTON_LEFT:
		return
	var mouse := get_global_mouse_position()
	if not allow_planet_clicks:
		return
	var planets: Array = sys["planets"]
	for p in planets:
		if int(p.get("pending_cards", 0)) > 0 and mouse.distance_to(_bubble_pos(p)) < 34.0 * GD.screen_scale(self):
			bubble_clicked.emit(p)
			get_viewport().set_input_as_handled()
			return
	var clicked := planet_at(mouse)
	if not clicked.is_empty():
		planet_clicked.emit(clicked)
		get_viewport().set_input_as_handled()
		return
	var exits: Array = sys["exits"]
	for e in exits:
		var p: Vector2 = e["pos"]
		if mouse.distance_to(p * GD.UNIT) < 4.0 * GD.UNIT:
			exit_clicked.emit(e["to"])
			get_viewport().set_input_as_handled()
			return


# --- drawing -------------------------------------------------------------------

func _draw() -> void:
	if sys.is_empty():
		return
	var u := GD.UNIT
	var radius := GD.SYSTEM_RADIUS * u
	# Centre glow: no star body, just light.
	for i in 10:
		var t := float(i) / 10.0
		draw_circle(Vector2.ZERO, radius * 0.22 * (1.0 - t), Color(0.957, 0.914, 0.784, 0.03 + t * 0.05))
	# Faint orbit rings for scale.
	for ring in [35.0, 70.0, 100.0]:
		draw_arc(Vector2.ZERO, ring * u, 0.0, TAU, 128, Color(0.435, 0.549, 0.576, 0.18), 2.0)
	# System boundary, coloured by owner.
	var faction: int = sys["faction"]
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 256, GD.ring_colour(faction), 6.0)
	_draw_field_labels()
	_draw_gas_giants()
	# _draw_daily_total(): the system's daily total shows on the galaxy map only (v0.9.215)
	_draw_planets()
	_draw_structures()
	_draw_exits()
	_draw_wormhole()
	_draw_focus()
	_draw_bubbles()
	_draw_colonizing()
	_draw_colony_buttons()


## Where a planet's colonize button floats: above it (to the side if a reward bubble is there).
func _colony_button_pos(p: Dictionary) -> Vector2:
	var k := GD.screen_scale(self)
	var centre: Vector2 = Vector2(p["pos"]) * GD.UNIT
	var r := float(p["radius"]) * GD.UNIT
	var pos := centre + Vector2(0, -r - 56.0 * k)
	if int(p.get("pending_cards", 0)) > 0:
		pos.x += 76.0 * k
	return pos


## The rocket-landing button over planets you can colonize: fly the Kharkiv into it.
func _draw_colony_buttons() -> void:
	var k := GD.screen_scale(self)
	for p in Array(sys["planets"]):
		if not p.has("colony_button"):
			continue
		var can_go := bool(p["colony_button"])
		var c := _colony_button_pos(p)
		var breathe := 1.0 + (0.06 * sin(_time * 2.4) if can_go else 0.0)
		var r := 26.0 * k * breathe
		var fill := Color("2f8f57") if can_go else Color("3a444e")
		var ink := Color("e9e6dc") if can_go else Color("8a96a0")
		if can_go:
			_glow_behind(c, r, Color(0.24, 0.82, 0.48))
			draw_circle(c, r * 1.3, Color(0.24, 0.82, 0.48, 0.16 + 0.08 * sin(_time * 2.4)))
		draw_circle(c, r, fill)
		draw_arc(c, r, 0.0, TAU, 32, Color("0b0e14"), 3.0 * k)
		# Planet surface along the bottom of the button.
		draw_arc(c + Vector2(0, r * 1.55), r * 1.05, -PI * 0.78, -PI * 0.22, 20, ink, 3.0 * k)
		# A rocket coming down to land, flame underneath.
		var body := Rect2(c + Vector2(-3.5, -12.0) * k, Vector2(7.0, 14.0) * k)
		draw_rect(body, ink)
		draw_colored_polygon(PackedVector2Array([c + Vector2(-3.5, -12.0) * k, c + Vector2(3.5, -12.0) * k, c + Vector2(0, -18.0) * k]), ink)
		draw_colored_polygon(PackedVector2Array([c + Vector2(-3.5, -1.0) * k, c + Vector2(-7.5, 3.0) * k, c + Vector2(-3.5, 2.0) * k]), ink)
		draw_colored_polygon(PackedVector2Array([c + Vector2(3.5, -1.0) * k, c + Vector2(7.5, 3.0) * k, c + Vector2(3.5, 2.0) * k]), ink)
		var flame := 4.0 + 2.0 * sin(_time * 18.0)
		draw_colored_polygon(PackedVector2Array([c + Vector2(-2.5, 2.0) * k, c + Vector2(2.5, 2.0) * k, c + Vector2(0, 2.0 + flame) * k]), Color("f08a2a"))
		var cost := "1 POP · {alloys}%d · {credits}%d" % [GD.colony_alloys(), GD.COLONY_CREDITS]
		# Big enough to read at a glance: the cost (or COLONIZE) under the button.
		_label(c + Vector2(0, r + 24.0 * k), "COLONIZE" if can_go else cost, 20, Color(GD.GAIN_COLOUR) if can_go else Color("c9d2dc"))
		if can_go and GD.show_full_names:
			_label(c + Vector2(0, r + 48.0 * k), cost, 18, Color("c9d2dc"))


## A green bar over a planet that a Colony Ship is settling.
func _draw_colonizing() -> void:
	var k := GD.screen_scale(self)
	for p in Array(sys["planets"]):
		if not p.has("colony_progress"):
			continue
		var t := clampf(float(p["colony_progress"]), 0.0, 1.0)
		var centre: Vector2 = Vector2(p["pos"]) * GD.UNIT
		var r := float(p["radius"]) * GD.UNIT
		var w := 150.0 * k
		var top := centre + Vector2(-w / 2.0, -r - 30.0 * k)
		draw_rect(Rect2(top - Vector2(2, 2) * k, Vector2(w, 12.0 * k) + Vector2(4, 4) * k), Color("0b0e14"))
		draw_rect(Rect2(top, Vector2(w, 12.0 * k)), Color(0.05, 0.12, 0.08))
		draw_rect(Rect2(top, Vector2(w * t, 12.0 * k)), Color(GD.GAIN_COLOUR))
		_label(top + Vector2(w / 2.0, -10.0 * k), "COLONIZING  %d%%" % int(t * 100.0), int(14), Color(GD.GAIN_COLOUR))
	# The Sons of Philip settling a planet: a gold bar, so you can race them to it.
	for p in Array(sys["planets"]):
		if not p.has("sons_progress"):
			continue
		var t := clampf(float(p["sons_progress"]), 0.0, 1.0)
		var centre: Vector2 = Vector2(p["pos"]) * GD.UNIT
		var r := float(p["radius"]) * GD.UNIT
		var w := 150.0 * k
		var top := centre + Vector2(-w / 2.0, -r - 30.0 * k)
		draw_rect(Rect2(top - Vector2(2, 2) * k, Vector2(w, 12.0 * k) + Vector2(4, 4) * k), Color("0b0e14"))
		draw_rect(Rect2(top, Vector2(w, 12.0 * k)), Color(0.12, 0.1, 0.04))
		draw_rect(Rect2(top, Vector2(w * t, 12.0 * k)), Color("d9a441"))
		_label(top + Vector2(w / 2.0, -10.0 * k), "SONS OF PHILIP SETTLING  %d%%" % int(t * 100.0), int(14), Color("d9a441"))


func _draw_bubbles() -> void:
	var planets: Array = sys["planets"]
	var k := GD.screen_scale(self)
	for p in planets:
		var pending := int(p.get("pending_cards", 0))
		if pending <= 0:
			continue
		var c := _bubble_pos(p)
		var breathe := 1.0 + 0.08 * sin(_time * 2.2)
		var r := 30.0 * k * breathe
		_glow_behind(c, r, Color(0.91, 0.77, 0.28))
		draw_circle(c, r * 1.35, Color(0.91, 0.77, 0.28, 0.18 + 0.1 * sin(_time * 2.2)))
		draw_circle(c, r, Color("e8c547"))
		draw_arc(c, r, 0.0, TAU, 32, Color("8a6a2a"), 3.0 * k)
		# A simple green pop: head and shoulders.
		draw_circle(c + Vector2(-4, -6) * k, 6.0 * k, Color("3dd17a"))
		draw_rect(Rect2(c + Vector2(-13, 2) * k, Vector2(18, 10) * k), Color("3dd17a"))
		# The plus.
		draw_rect(Rect2(c + Vector2(9, -9) * k, Vector2(12, 4) * k), Color("0b0e14"))
		draw_rect(Rect2(c + Vector2(13, -13) * k, Vector2(4, 12) * k), Color("0b0e14"))
		draw_line(c + Vector2(0, r), c + Vector2(0, r + 26.0 * k), Color("e8c547"), 3.0 * k)
		if pending > 1:
			var badge := c + Vector2(r * 0.75, -r * 0.75)
			draw_circle(badge, 13.0 * k, Color("e5484d"))
			var text := str(pending)
			var tw := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
			draw_set_transform(badge + Vector2(-tw / 2.0 * k, 6.0 * k), 0.0, Vector2(k, k))
			draw_string(_font, Vector2.ZERO, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_wormhole() -> void:
	if wormhole_strength <= 0.01:
		return
	var s := wormhole_strength
	var r := 4.0 * GD.UNIT * s
	draw_circle(wormhole_pos, r * 1.6, Color(0.24, 0.55, 0.9, 0.12 * s))
	draw_circle(wormhole_pos, r, Color(0.02, 0.02, 0.06, 0.95 * s))
	for i in 5:
		var spin := _time * (2.0 + i * 0.6) + i * 1.3
		var rr := r * (0.45 + i * 0.16)
		draw_arc(wormhole_pos, rr, spin, spin + PI * 1.2, 32, Color(0.55, 0.85, 1.0, 0.75 * s), 3.0)
	draw_arc(wormhole_pos, r, 0.0, TAU, 48, Color(0.85, 0.95, 1.0, s), 4.0)


func _draw_focus() -> void:
	if focus_node == null or not is_instance_valid(focus_node) or focus_node.get_parent() != self:
		return
	var k := GD.screen_scale(self)
	var c := focus_node.position
	var h := 30.0 * k
	var l := 10.0 * k
	var col := Color("e5484d")
	for sx in [-1.0, 1.0]:
		for sy in [-1.0, 1.0]:
			var corner := c + Vector2(sx * h, sy * h)
			draw_line(corner, corner - Vector2(sx * l, 0), col, 3.0 * k)
			draw_line(corner, corner - Vector2(0, sy * l), col, 3.0 * k)


## Draws centred text that stays the same size on screen at any zoom.
var muted_label := false   # draw the next labels' resource icons greyed out


func _label(pos: Vector2, text: String, size: int, colour: Color) -> void:
	var k := GD.screen_scale(self)
	# "{alloys}40" and friends draw as resource icons (res_icon.gd).
	var w := ResIcon.text_width(_font, text, size)
	draw_set_transform(pos, 0.0, Vector2(k, k))
	ResIcon.draw_text(self, _font, Vector2(-w / 2.0, 0), text, size, colour, 4, muted_label)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _dashed_circle(centre: Vector2, r: float, colour: Color, width: float) -> void:
	var segments := 48
	for i in segments:
		if i % 2 == 0:
			var a := TAU * i / segments
			draw_arc(centre, r, a, a + TAU / segments, 4, colour, width)


func _rock(centre: Vector2, size_px: float, shape: PackedVector2Array, angle: float, fill: Color) -> void:
	var pts := PackedVector2Array()
	for p in shape:
		pts.append(centre + p.rotated(angle) * size_px)
	draw_colored_polygon(pts, fill)
	var outline := pts.duplicate()
	outline.append(pts[0])
	draw_polyline(outline, Color("0b0e14"), 2.0)


## The centre (units) of your Starbase whose orbit covers this point, or INF.
## (Asteroids use it to keep their info labels inside the orbit.)
func _une_base_covering(point: Vector2) -> Vector2:
	var orbit := GD.STARBASE_ORBIT * GD.orbit_multiplier
	for st in Array(sys["structures"]):
		if st["type"] == "starbase" and int(st["faction"]) == GD.Faction.UNE and point.distance_to(Vector2(st["pos"])) <= orbit:
			return Vector2(st["pos"])
	return Vector2.INF


func _draw_field_labels() -> void:
	var u := GD.UNIT
	var fields: Array = sys["fields"]
	var alloys: Array = []
	var gas: Array = []
	for i in fields.size():
		alloys.append(0)
		gas.append(0)
	for rock in asteroids():
		var fi := int(rock.get("field_id"))
		if fi < 0 or not (rock.get("arrived") == true):
			continue
		alloys[fi] = int(alloys[fi]) + int(rock.get("yield_alloys"))
		gas[fi] = int(gas[fi]) + int(rock.get("yield_gas"))
	for i in fields.size():
		var f: Dictionary = fields[i]
		var centre: Vector2 = f["pos"]
		var amount := int(gas[i]) if bool(f["gas"]) else int(alloys[i])
		if amount <= 0:
			continue
		var worked := bool(f.get("worked", false))
		var text := ("{gas}%d" if bool(f["gas"]) else "{alloys}%d") % amount
		var colour := Color(0.24, 0.82, 0.48, 0.95) if worked else Color(0.79, 0.82, 0.85, 0.75)
		var at := centre + Vector2(0, 8.0)
		muted_label = not worked
		_label(at * u, text, 20, colour)
		muted_label = false


## Zoomed well out: a plate over the system with everything it makes each day.
func _draw_daily_total() -> void:
	var k := GD.screen_scale(self)
	if k < 2.0:   # only when zoomed out (zoom 0.5 or less)
		return
	var text := GD.daily_text(int(sys["index"]))
	if text == "":
		return
	var at := Vector2(0, -(GD.SYSTEM_RADIUS - 6.0) * GD.UNIT)
	_label(at, "PER DAY   " + text, 22, Color("f4efe2"))


func _draw_gas_giants() -> void:
	var u := GD.UNIT
	var giants: Array = sys["gas_giants"]
	for g in giants:
		var pos: Vector2 = g["pos"]
		var r: float = g["radius"]
		# The sphere itself is a PlanetBody child.
		_label((pos + Vector2(0, r + 2.0)) * u, "GAS GIANT", 13, Color(0.79, 0.82, 0.85, 0.8))


func _draw_planets() -> void:
	var u := GD.UNIT
	var planets: Array = sys["planets"]
	for p in planets:
		var pos: Vector2 = p["pos"]
		var r: float = p["radius"]
		var centre := pos * u
		# The sphere is a PlanetBody child and the shield is on the shield layer.
		_draw_planet_banner(p, centre, r * u)


func _draw_structures() -> void:
	var u := GD.UNIT
	var structures: Array = sys["structures"]
	for s in structures:
		var pos: Vector2 = s["pos"]
		var faction: int = s["faction"]
		var kind: String = s["type"]
		var centre := pos * u
		if kind == "starbase":
			var orbit_r := GD.STARBASE_ORBIT * GD.orbit_multiplier * u
			_dashed_circle(centre, orbit_r, Color(GD.ring_colour(faction), 0.7), 3.0)
			if GD.show_full_names:   # only while Info (Space) is held
				_label(centre + Vector2(0, orbit_r + 14.0 * GD.screen_scale(self)), "COLLECTION", 12, Color(GD.ring_colour(faction), 0.8))
			if GD.show_ranges:
				# Same range ring as ships, for the Starbase's longest-reaching weapon only.
				var longest := 0.0
				for w in GD.STARBASE_GUNS:
					longest = maxf(longest, float(GD.WEAPONS[w]["range"]))
				var reach := longest * GD.STARBASE_RANGE_MULT * (GD.station_range_mult if faction == GD.Faction.UNE else 1.0) * u
				var ring := GD.ring_colour(faction)
				draw_circle(centre, reach, Color(ring, 0.035))
				draw_arc(centre, reach, 0.0, TAU, 128, Color(ring, 0.28), 1.5 * GD.screen_scale(self))
			_station_scale_on(centre)
			_draw_starbase_model(centre, faction)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			_label(centre + Vector2(0, -1.45 * u * GD.STATION_SCALE - 8.0), GD.structure_label("starbase"), 15, Color("f4efe2"))
		elif kind == "mag":
			# MAG Cannon: a huge gun platform (its turret and barrel draw themselves).
			var base_r := 2.3 * u * GD.STATION_SCALE
			_station_scale_on(centre)
			_draw_mag_platform(centre, faction)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			if GD.show_ranges:
				var reach := float(GD.WEAPONS["mag_cannon"]["range"]) * GD.STARBASE_RANGE_MULT * (GD.station_range_mult if faction == GD.Faction.UNE else 1.0) * u
				var ring := GD.ring_colour(faction)
				draw_circle(centre, reach, Color(ring, 0.03))
				draw_arc(centre, reach, 0.0, TAU, 128, Color(ring, 0.28), 1.5 * GD.screen_scale(self))
			_label(centre + Vector2(0, -base_r - 8.0), GD.structure_label("mag"), 15, Color("f4efe2"))
		elif kind == "shipyard":
			if faction == GD.Faction.UNE:
				# Repair radius: ships inside it are patched up.
				var repair_r := GD.STARBASE_ORBIT * GD.orbit_multiplier * GD.shipyard_repair_mult * u
				draw_circle(centre, repair_r, Color(0.24, 0.82, 0.48, 0.04))
				_dashed_circle(centre, repair_r, Color(0.24, 0.82, 0.48, 0.55), 2.5)
				if GD.show_full_names:   # only while Info (Space) is held
					_label(centre + Vector2(0, repair_r + 14.0), "REPAIRS", 12, Color(0.24, 0.82, 0.48, 0.8))
			var size := Vector2(2.6, 1.5) * u * GD.STATION_SCALE
			var queue: Array = s.get("queue", [])
			_station_scale_on(centre)
			_draw_shipyard_model(centre, faction, not queue.is_empty())
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			_label(centre + Vector2(0, -size.y / 2.0 - 8.0), GD.structure_label("shipyard"), 15, Color("f4efe2"))
			# Ships in the build queue: the one in progress, with a bar, and how many wait behind it.
			if not queue.is_empty():
				var k := GD.screen_scale(self)
				var active := mini(GD.shipyard_lines, queue.size())
				var y := size.y / 2.0 + 16.0 * k
				for i in active:
					var item: Dictionary = queue[i]
					var type_id := String(item["type"])
					var left := float(item["left"])
					var total := float(GD.ship_stats(type_id)["build_time"])
					var line := "BUILDING %s %d:%02d" % [String(GD.SHIPS[type_id]["kind"]).to_upper(), int(ceil(left)) / 60, int(ceil(left)) % 60]
					if i == active - 1 and queue.size() > active:
						line += "  +%d" % (queue.size() - active)
					_label(centre + Vector2(0, y), line, 13, Color(GD.GAIN_COLOUR))
					var w := 70.0 * k
					var bar := centre + Vector2(-w / 2.0, y + 5.0 * k)
					draw_rect(Rect2(bar, Vector2(w, 4.0 * k)), Color(0.02, 0.03, 0.05, 0.8))
					draw_rect(Rect2(bar, Vector2(w * clampf(1.0 - left / maxf(total, 0.01), 0.0, 1.0), 4.0 * k)), Color(GD.GAIN_COLOUR))
					y += 24.0 * k


const HULL := Color("8e98a3")
const HULL_LIGHT := Color("c3cad1")
const HULL_DARK := Color("4a535d")
const INK := Color("0b0e14")


## Starbase: a heavy armoured ring on four spokes around a lit command core, with
## solar wings either side, a turning sensor dish and blinking navigation lights.
## The guns (corners and top/bottom) and the fighter bay sit on the ring.
## Station models draw 25% bigger, scaled about their own centre.
func _station_scale_on(centre: Vector2) -> void:
	draw_set_transform(centre * (1.0 - GD.STATION_SCALE), 0.0, Vector2.ONE * GD.STATION_SCALE)


func _draw_starbase_model(centre: Vector2, faction: int) -> void:
	var u := GD.UNIT
	var colour := GD.faction_colour(faction)
	# Soft shadow under the whole station, offset down, for depth.
	draw_circle(centre + Vector2(0.12, 0.18) * u, 1.32 * u, Color(0.0, 0.0, 0.0, 0.35))
	# Solar wings: a strut out each side and a panel with cell lines.
	for side: float in [-1.0, 1.0]:
		draw_line(centre + Vector2(side * 1.15, 0) * u, centre + Vector2(side * 1.55, 0) * u, HULL_DARK, 0.18 * u)
		var panel := Rect2(centre + Vector2(side * 1.55 - (0.0 if side > 0.0 else 0.75), -0.42) * u, Vector2(0.75, 0.84) * u)
		draw_rect(panel, Color("1d3550"))
		for i: int in 4:
			var x := panel.position.x + panel.size.x * float(i + 1) / 5.0
			draw_line(Vector2(x, panel.position.y), Vector2(x, panel.end.y), Color("2f5a85"), 1.5)
		draw_line(Vector2(panel.position.x, panel.get_center().y), Vector2(panel.end.x, panel.get_center().y), Color("2f5a85"), 1.5)
		draw_rect(panel, INK, false, 2.0)
	# Four spokes from the core to the ring.
	for i: int in 4:
		var dir := Vector2.RIGHT.rotated(PI * 0.25 + i * PI * 0.5)
		draw_line(centre + dir * 0.4 * u, centre + dir * 0.95 * u, HULL_DARK, 0.2 * u)
		draw_line(centre + dir * 0.4 * u, centre + dir * 0.95 * u, HULL, 0.1 * u)
	# The armoured ring: dark underside, lit top edge, armour plate seams.
	draw_arc(centre, 1.05 * u, 0.0, TAU, 48, INK, 0.36 * u)
	draw_arc(centre, 1.05 * u, 0.0, TAU, 48, HULL, 0.28 * u)
	draw_arc(centre + Vector2(0, -0.05) * u, 1.08 * u, PI * 1.1, PI * 1.9, 24, HULL_LIGHT, 0.08 * u)
	draw_arc(centre + Vector2(0, 0.05) * u, 1.02 * u, PI * 0.1, PI * 0.9, 24, HULL_DARK, 0.08 * u)
	for i: int in 12:
		var dir := Vector2.RIGHT.rotated(i * TAU / 12.0)
		draw_line(centre + dir * 0.92 * u, centre + dir * 1.18 * u, Color(INK, 0.6), 2.0)
	# Habitat windows along the ring, in the faction colour.
	for i: int in 24:
		if i % 3 == 0:
			continue
		var dir := Vector2.RIGHT.rotated((i + 0.5) * TAU / 24.0)
		draw_circle(centre + dir * 1.05 * u, 1.6, Color(colour.lightened(0.45), 0.85))
	# Command core: an armoured octagon with a glowing centre.
	var core := PackedVector2Array()
	for i: int in 8:
		core.append(centre + Vector2.RIGHT.rotated(PI / 8.0 + i * TAU / 8.0) * 0.5 * u)
	draw_colored_polygon(core, HULL_LIGHT)
	core.append(core[0])
	draw_polyline(core, INK, 2.5)
	draw_circle(centre, 0.3 * u, HULL_DARK)
	draw_circle(centre, 0.24 * u, colour)
	draw_circle(centre, 0.24 * u * (0.55 + 0.1 * sin(_time * 2.0)), Color(colour.lightened(0.5), 0.8))
	# A sensor dish on the core, slowly sweeping round.
	var dish_dir := Vector2.RIGHT.rotated(_time * 0.6)
	draw_line(centre, centre + dish_dir * 0.42 * u, HULL_LIGHT, 2.0)
	draw_arc(centre + dish_dir * 0.42 * u, 0.12 * u, dish_dir.angle() - 1.1, dish_dir.angle() + 1.1, 8, HULL_LIGHT, 2.0)
	# Navigation lights at the wing tips: red to port, green to starboard, blinking.
	var blink := 1.0 if fmod(_time, 1.6) < 0.25 else 0.25
	draw_circle(centre + Vector2(-2.3, 0) * u, 3.0, Color(1.0, 0.3, 0.25, blink))
	draw_circle(centre + Vector2(2.3, 0) * u, 3.0, Color(0.3, 1.0, 0.45, blink))


## The MAG Cannon's platform: a massive octagonal emplacement, the biggest gun base in
## the game. Heavy armour with plate seams and hazard stripes, four bracing pylons out
## to the diagonals carrying glowing capacitor banks, and a bolted turret ring.
func _draw_mag_platform(centre: Vector2, faction: int) -> void:
	var u := GD.UNIT
	var colour := GD.faction_colour(faction)
	var glow := Color(String(GD.WEAPONS["mag_cannon"]["colour"]))
	var octagon := PackedVector2Array()
	var shadow := PackedVector2Array()
	for i: int in 8:
		var p := Vector2.RIGHT.rotated(PI / 8.0 + i * TAU / 8.0) * 1.9 * u
		octagon.append(centre + p)
		shadow.append(centre + p + Vector2(0.2, 0.3) * u)
	# Bracing pylons with capacitor banks, out to the four diagonals (under the platform).
	for i: int in 4:
		var d := Vector2.RIGHT.rotated(PI * 0.25 + i * PI * 0.5)
		var side := d.orthogonal()
		draw_colored_polygon(PackedVector2Array([centre + d * 1.4 * u + side * 0.35 * u, centre + d * 2.9 * u + side * 0.22 * u, centre + d * 2.9 * u - side * 0.22 * u, centre + d * 1.4 * u - side * 0.35 * u]), Color(0, 0, 0, 0.3))
		var pylon := PackedVector2Array([centre + d * 1.4 * u + side * 0.32 * u, centre + d * 2.8 * u + side * 0.2 * u, centre + d * 2.8 * u - side * 0.2 * u, centre + d * 1.4 * u - side * 0.32 * u])
		draw_colored_polygon(pylon, HULL_DARK)
		var closed := pylon.duplicate()
		closed.append(pylon[0])
		draw_polyline(closed, INK, 2.0)
		# The capacitor bank on the end: three cells pulsing in turn.
		for c: int in 3:
			var at := centre + d * (2.1 + c * 0.28) * u
			var pulse := 0.35 + 0.65 * clampf(sin(_time * 3.0 - c * 0.9 - i * 1.4), 0.0, 1.0)
			draw_circle(at, 0.16 * u, INK)
			draw_circle(at, 0.12 * u, Color(glow, 0.35 + 0.6 * pulse))
		draw_circle(centre + d * 2.9 * u, 0.2 * u, HULL)
		draw_arc(centre + d * 2.9 * u, 0.2 * u, 0.0, TAU, 12, INK, 2.0)
	# The platform itself.
	draw_colored_polygon(shadow, Color(0, 0, 0, 0.35))
	draw_colored_polygon(octagon, HULL.darkened(0.15).lerp(colour, 0.2))
	# Armour plates: a ring of panels with seams.
	for i: int in 8:
		var a0 := PI / 8.0 + i * TAU / 8.0
		var p0 := centre + Vector2.RIGHT.rotated(a0) * 1.9 * u
		draw_line(centre + Vector2.RIGHT.rotated(a0) * 1.25 * u, p0, Color(INK, 0.5), 2.0)
	# Hazard stripes round the rim, on alternate faces.
	for i: int in 8:
		if i % 2 == 1:
			continue
		var a0 := PI / 8.0 + i * TAU / 8.0
		var a1 := a0 + TAU / 8.0
		for k: int in 6:
			var t0 := float(k) / 6.0
			var t1 := (k + 0.5) / 6.0
			var o0 := centre + Vector2.RIGHT.rotated(a0).lerp(Vector2.RIGHT.rotated(a1), t0) * 1.9 * u
			var o1 := centre + Vector2.RIGHT.rotated(a0).lerp(Vector2.RIGHT.rotated(a1), t1) * 1.9 * u
			var i0 := centre + Vector2.RIGHT.rotated(a0).lerp(Vector2.RIGHT.rotated(a1), t0 + 0.06) * 1.7 * u
			var i1 := centre + Vector2.RIGHT.rotated(a0).lerp(Vector2.RIGHT.rotated(a1), t1 + 0.06) * 1.7 * u
			draw_colored_polygon(PackedVector2Array([o0, o1, i1, i0]), Color("d9a441"))
	# Lit top rim and outline.
	for i: int in 8:
		if i >= 4 and i <= 7:
			draw_line(octagon[i], octagon[(i + 1) % 8], HULL_LIGHT, 3.0)
	var outline := octagon.duplicate()
	outline.append(octagon[0])
	draw_polyline(outline, INK, 3.5)
	# The turret ring: a dark bolted race the gun turns on.
	draw_circle(centre, 1.3 * u, INK)
	draw_circle(centre, 1.2 * u, HULL_DARK)
	for i: int in 16:
		draw_circle(centre + Vector2.RIGHT.rotated(i * TAU / 16.0) * 1.12 * u, 2.5, HULL_LIGHT)
	# Blinking warning beacons on the rim.
	var blink := 1.0 if fmod(_time, 1.2) < 0.2 else 0.25
	for i: int in 4:
		draw_circle(centre + Vector2.RIGHT.rotated(i * PI * 0.5) * 1.75 * u, 4.0, Color(1.0, 0.35, 0.2, blink))


## Shipyard: a long drydock of two truss girders joined by a command block, with
## gantry cranes over the bay. While it's building, a hull sits in the dock with
## welding sparks flickering along it.
func _draw_shipyard_model(centre: Vector2, faction: int, building: bool) -> void:
	var u := GD.UNIT
	var colour := GD.faction_colour(faction)
	var length := 2.6 * u
	var gap := 0.5 * u          # half the width of the bay
	var beam := 0.22 * u
	var left := centre.x - length / 2.0
	# Shadow underneath, for depth.
	draw_rect(Rect2(Vector2(left, centre.y - gap - beam) + Vector2(0.12, 0.18) * u, Vector2(length, (gap + beam) * 2.0)), Color(0.0, 0.0, 0.0, 0.35))
	# The bay floor: dark, with faint guide lights.
	draw_rect(Rect2(Vector2(left + 0.4 * u, centre.y - gap), Vector2(length - 0.4 * u, gap * 2.0)), Color(0.05, 0.07, 0.1, 0.75))
	for i: int in 6:
		var x := left + 0.6 * u + i * 0.35 * u
		var on := 0.25 + 0.6 * clampf(sin(_time * 3.0 - i * 0.6), 0.0, 1.0)
		draw_circle(Vector2(x, centre.y), 1.8, Color(colour.lightened(0.4), on))
	# A hull under construction: a ship's outline in the dock, sparks along it.
	if building:
		var hull := PackedVector2Array([
			Vector2(left + 2.3 * u, centre.y), Vector2(left + 1.5 * u, centre.y - 0.3 * u),
			Vector2(left + 0.7 * u, centre.y - 0.32 * u), Vector2(left + 0.6 * u, centre.y),
			Vector2(left + 0.7 * u, centre.y + 0.32 * u), Vector2(left + 1.5 * u, centre.y + 0.3 * u)])
		draw_colored_polygon(hull, Color(HULL_DARK, 0.85))
		var outline := hull.duplicate()
		outline.append(hull[0])
		draw_polyline(outline, Color(colour.lightened(0.3), 0.7), 2.0)
		for i: int in 3:
			var at := hull[i + 1].lerp(hull[(i + 2) % hull.size()], fmod(_time * 0.7 + i * 0.37, 1.0))
			if fmod(_time * 7.0 + i * 1.3, 1.0) < 0.5:
				draw_circle(at, 3.0, Color(1.0, 0.85, 0.5, 0.9))
				draw_circle(at, 6.0, Color(1.0, 0.7, 0.3, 0.25))
	# The two girders, with truss cross-bracing.
	for side: float in [-1.0, 1.0]:
		var top := centre.y + side * gap - (beam if side < 0.0 else 0.0)
		var girder := Rect2(Vector2(left, top), Vector2(length, beam))
		draw_rect(girder, HULL)
		draw_line(Vector2(left, top + 1.0), Vector2(left + length, top + 1.0), HULL_LIGHT, 2.0)
		var steps := 10
		for i: int in steps:
			var x0 := left + length * float(i) / float(steps)
			var x1 := left + length * float(i + 1) / float(steps)
			draw_line(Vector2(x0, top + beam), Vector2(x1, top), Color(HULL_DARK, 0.9), 2.0)
		draw_rect(girder, INK, false, 2.0)
	# Command block across the back of the dock, with lit windows.
	var block := Rect2(Vector2(left - 0.15 * u, centre.y - gap - beam - 0.1 * u), Vector2(0.55 * u, (gap + beam + 0.1 * u) * 2.0))
	draw_rect(block, HULL_LIGHT)
	draw_rect(Rect2(block.position + Vector2(0.1, 0.12) * u, Vector2(0.35 * u, block.size.y - 0.24 * u)), colour)
	for i: int in 4:
		draw_rect(Rect2(block.position + Vector2(0.17 * u, 0.2 * u + i * 0.22 * u), Vector2(0.2, 0.08) * u), Color(colour.lightened(0.6), 0.9))
	draw_rect(block, INK, false, 2.5)
	# Two gantry cranes across the bay, gliding back and forth while it builds.
	for i: int in 2:
		var slide := 0.0
		if building:
			slide = sin(_time * 0.8 + i * 2.1) * 0.25 * u
		var x := left + (1.1 + i * 0.85) * u + slide
		draw_line(Vector2(x, centre.y - gap), Vector2(x, centre.y + gap), INK, 0.14 * u)
		draw_line(Vector2(x, centre.y - gap), Vector2(x, centre.y + gap), Color("d9a441"), 0.08 * u)
		draw_rect(Rect2(Vector2(x - 0.08 * u, centre.y - 0.08 * u), Vector2(0.16, 0.16) * u), Color("d9a441"))
	# Beacons at the open end of the dock.
	var blink := 1.0 if fmod(_time + 0.5, 1.2) < 0.2 else 0.3
	for side: float in [-1.0, 1.0]:
		draw_circle(Vector2(left + length, centre.y + side * (gap + beam * 0.5)), 3.0, Color(1.0, 0.75, 0.25, blink))


func _draw_exits() -> void:
	_draw_exits_on(self)


func _draw_exits_on(canvas: CanvasItem) -> void:
	var u := GD.UNIT
	var exits: Array = sys["exits"]
	var green := Color("3dd17a")
	var k := GD.screen_scale(self)
	for e in exits:
		var pos: Vector2 = e["pos"]
		var dir: Vector2 = e["dir"]
		var c := pos * u
		var side_dir := dir.orthogonal()
		var pulse := 0.5 + 0.5 * sin(_time * 2.4)
		# A blue whirlpool round the arrow (v0.9.200), slow and liquid (v0.9.203): just big
		# enough to hold the arrow (the charge still starts at WARP_TRIGGER). Wavy layers
		# of water, spiral arms that wobble as they wind into a dark eye, drifting specks.
		var pull := 4.4 * u
		var blue := Color("5b9bff")
		var ice := Color("8fd1ff")
		var tt := _time
		# Water: three wavy discs, each rippling at its own pace.
		for layer in 3:
			var lr := pull * (1.0 - layer * 0.28)
			var poly := PackedVector2Array()
			for j in 48:
				var th := TAU * j / 48.0
				var wob := 0.06 * sin(th * 5.0 + tt * (0.9 + layer * 0.3)) + 0.04 * sin(th * 3.0 - tt * 0.7 + layer)
				poly.append(c + Vector2.from_angle(th) * lr * (1.0 + wob))
			canvas.draw_colored_polygon(poly, Color(blue, 0.06 + layer * 0.03))
		canvas.draw_circle(c, pull * 0.2, Color(0.01, 0.02, 0.05, 0.6))
		# Ripples drifting inward, wavy rather than perfect rings.
		for i in 3:
			var ph := fmod(tt * 0.22 + i / 3.0, 1.0)
			var rr := pull * (1.0 - ph * 0.75)
			var ring := PackedVector2Array()
			for j in 49:
				var th := TAU * j / 48.0
				ring.append(c + Vector2.from_angle(th) * rr * (1.0 + 0.05 * sin(th * 6.0 + tt * 1.1 + i * 2.0)))
			canvas.draw_polyline(ring, Color(ice, 0.35 * ph * (1.0 - ph) * 4.0 * 0.6), 1.6 * k, true)
		var arms := 4
		var spin := tt * 0.45
		for arm in arms:
			var a0 := spin + arm * TAU / arms
			var pts := PackedVector2Array()
			var cols := PackedColorArray()
			for j in 33:
				var sf := j / 32.0                       # 0 at the rim, 1 at the eye
				var sr := pull * (1.0 - sf * 0.8) * (1.0 + 0.05 * sin(sf * 9.0 - tt * 1.6 + arm))
				var sa := a0 + sf * sf * 3.2 + 0.12 * sin(sf * 6.0 + tt * 1.2 + arm * 1.7)
				pts.append(c + Vector2.from_angle(sa) * sr)
				cols.append(Color(ice if sf > 0.6 else blue, 0.5 * sin(sf * PI) + 0.05))
			canvas.draw_polyline_colors(pts, cols, 2.5 * k, true)
			# Specks drifting down the arm, quickening near the eye.
			for d in 2:
				var sf := fmod(tt * 0.16 + d / 2.0 + arm * 0.13, 1.0)
				var sff := sf * sf
				var sr := pull * (1.0 - sff * 0.8)
				var sa := a0 + sff * sff * 3.2
				canvas.draw_circle(c + Vector2.from_angle(sa) * sr, (2.2 - sff * 1.0) * k, Color(ice, 0.8 * sin(sf * PI)))
		# The whirlpool sits inside the system; the green arrow sits just outside the
		# boundary ring (v0.9.208). The dotted course runs from the whirlpool, under the
		# arrow and on out, dashes marching outward.
		var ac := dir * (GD.SYSTEM_RADIUS + GD.EXIT_OUT) * u
		var start := c + dir * (pull / u + 0.3) * u
		var reach := (ac - start).length() + 30.0 * u
		var dash := 2.2 * u
		var march := fmod(_time * 1.6 * u, dash * 2.0)
		var s := march
		while s < reach:
			var a := start + dir * s
			var b := start + dir * minf(s + dash, reach)
			var fade_out := 1.0 - clampf(s / reach, 0.0, 1.0) * 0.7
			canvas.draw_line(a, b, Color(green, 0.75 * fade_out), 2.5 * k, true)
			s += dash * 2.0
		# The arrow: a glow, the solid head, and two chevrons pulsing ahead of it.
		var tip := ac + dir * 3.0 * u
		var back := ac - dir * 1.8 * u
		var wing := side_dir * 2.3 * u
		canvas.draw_colored_polygon(PackedVector2Array([tip + dir * 1.2 * u, back + wing * 1.35 - dir * 0.6 * u, back - wing * 1.35 - dir * 0.6 * u]), Color(green, 0.18 + 0.1 * pulse))
		canvas.draw_colored_polygon(PackedVector2Array([tip, back + wing, back - wing]), green.lightened(0.15 * pulse))
		canvas.draw_polyline(PackedVector2Array([tip, back + wing, back - wing, tip]), Color(0.04, 0.05, 0.08, 0.8), 2.0 * k, true)
		for i in 2:
			var at := tip + dir * (1.4 + i * 1.6 + pulse * 0.6) * u
			canvas.draw_polyline(PackedVector2Array([at - dir * 1.0 * u + side_dir * 1.2 * u, at, at - dir * 1.0 * u - side_dir * 1.2 * u]), Color(green, 0.8 - i * 0.3), 3.0 * k, true)
		# The label rides along the course line, just past the system's edge, kept upright.
		var name_text: String = e["name"]
		var text := "TO %s" % name_text.to_upper()
		var w := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
		var anchor := ac + dir * 9.0 * u    # past the chevrons
		var ang := dir.angle()
		var flip := absf(wrapf(ang, -PI, PI)) > PI * 0.5
		if flip:
			ang += PI
		canvas.draw_set_transform(anchor, ang, Vector2(k, k))
		var x0 := 0.0 if not flip else -w
		canvas.draw_string_outline(_font, Vector2(x0, -8.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, 5, Color(0.04, 0.05, 0.08))
		canvas.draw_string(_font, Vector2(x0, -8.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, green)
		canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## A one-line banner under a planet, like a city label in Total War: name, happiness,
## pops and what it yields per tick.
func _draw_planet_banner(p: Dictionary, centre: Vector2, r_px: float) -> void:
	var k := GD.screen_scale(self)
	var owner: int = p["owner"]
	var pops: int = p["pops"]
	var name_text := String(p["name"])
	var size := 15
	var parts: Array = []   # [kind, text, colour]
	parts.append(["name", name_text, Color("f4efe2")])
	if owner != GD.Faction.NEUTRAL and pops > 0:
		var stability := int(p.get("stability", 10))
		var mood := Color("3dd17a") if stability >= 7 else (Color("e8c547") if stability >= 4 else Color("e5484d"))
		parts.append(["smile", "", mood])
		parts.append(["pop", str(pops), Color("3dd17a")])
		var y: Dictionary = p.get("yield", {})
		# Income per day, each with its resource icon.
		if int(y.get("credits", 0)) > 0:
			parts.append(["res", "+%d" % int(y["credits"]), Color("e8c547"), "credits"])
		if int(y.get("alloys", 0)) > 0:
			parts.append(["res", "+%d" % int(y["alloys"]), Color("c79bff"), "alloys"])
		if int(y.get("gas", 0)) > 0:
			parts.append(["res", "+%d" % int(y["gas"]), Color("8fd14f"), "gas"])
	elif owner == GD.Faction.NEUTRAL:
		parts.append(["text", "uninhabitable" if int(p["capacity"]) <= 0 else "uncolonized", Color("8a96a0")])
	# Measure, then draw a dark pill with a faction stripe.
	var gap := 8.0
	var width := 0.0
	for part in parts:
		match String(part[0]):
			"res":
				width += 22.0 + gap + _font.get_string_size(String(part[1]), HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
			"smile", "pop":
				width += 16.0 + gap + (_font.get_string_size(String(part[1]), HORIZONTAL_ALIGNMENT_LEFT, -1, size).x if String(part[1]) != "" else 0.0)
			_:
				width += _font.get_string_size(String(part[1]), HORIZONTAL_ALIGNMENT_LEFT, -1, size).x + gap
	width += 14.0
	var top := centre + Vector2(0, r_px + 12.0 * k)
	draw_set_transform(top, 0.0, Vector2(k, k))
	var box := Rect2(Vector2(-width / 2.0, 0), Vector2(width, 24))
	draw_rect(box, Color(0.04, 0.05, 0.08, 0.85))
	var stripe := GD.ring_colour(owner) if owner != GD.Faction.NEUTRAL else Color("4a5862")
	draw_rect(Rect2(box.position, Vector2(4, 24)), stripe)
	draw_rect(box, Color(stripe, 0.6), false, 1.5)
	var x := -width / 2.0 + 10.0
	for part in parts:
		var kind := String(part[0])
		var text := String(part[1])
		var colour: Color = part[2]
		match kind:
			"smile":
				var c := Vector2(x + 7, 12)
				draw_circle(c, 7.0, colour)
				draw_circle(c + Vector2(-2.5, -2), 1.2, Color("0b0e14"))
				draw_circle(c + Vector2(2.5, -2), 1.2, Color("0b0e14"))
				var stability := int(p.get("stability", 10))
				if stability >= 7:
					draw_arc(c + Vector2(0, 0.5), 3.5, 0.3, PI - 0.3, 8, Color("0b0e14"), 1.4)
				elif stability >= 4:
					draw_line(c + Vector2(-3, 2.5), c + Vector2(3, 2.5), Color("0b0e14"), 1.4)
				else:
					draw_arc(c + Vector2(0, 5), 3.5, PI + 0.3, TAU - 0.3, 8, Color("0b0e14"), 1.4)
				x += 16.0 + gap
			"res":
				ResIcon.draw(self, String(part[3]), Vector2(x + 9, 12), 9.5)
				x += 22.0
				draw_string(_font, Vector2(x, 18), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, colour)
				x += _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x + gap
			"pop":
				draw_circle(Vector2(x + 7, 8), 3.5, colour)
				draw_rect(Rect2(Vector2(x + 2, 12.5), Vector2(10, 6)), colour)
				x += 16.0
				draw_string(_font, Vector2(x, 18), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, colour)
				x += _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x + gap
			_:
				draw_string(_font, Vector2(x, 18), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, colour)
				x += _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x + gap
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## The planet under a point (its body or its banner), for clicks.
func planet_at(pos: Vector2) -> Dictionary:
	var k := GD.screen_scale(self)
	for p in Array(sys["planets"]):
		var centre: Vector2 = Vector2(p["pos"]) * GD.UNIT
		var r := float(p["radius"]) * GD.UNIT
		if pos.distance_to(centre) < r + GD.UNIT:
			return p
		var below := pos - centre
		if below.y > r and below.y < r + 40.0 * k and absf(below.x) < 130.0 * k:
			return p
	return {}


## A planet under Planetary Shields: the same soft force field as a ship's, thrown up by
## a small ground generator at the south pole. Hits flare where they land (drawn by the siege).
## The shield layer: every planet's shield, over the planet spheres.
func _draw_shields() -> void:
	for p in Array(sys["planets"]):
		_draw_planet_shield(p, Vector2(p["pos"]) * GD.UNIT, float(p["radius"]) * GD.UNIT)


func _draw_planet_shield(p: Dictionary, centre: Vector2, r: float) -> void:
	var max_sh := float(p.get("max_shields", 0.0))
	var sh := float(p.get("shields", 0.0))
	if max_sh <= 0.0 or sh <= 0.5:
		return
	var strength := clampf(sh / max_sh, 0.0, 1.0)
	var blue := Color(0.36, 0.63, 1.0)
	var radius := r * 1.2
	for i in 6:
		var t := float(i + 1) / 6.0
		_shield_layer.draw_circle(centre, radius * t, Color(blue, 0.03 * strength))
	_shield_layer.draw_arc(centre, radius, 0.0, TAU, 64, Color(blue, 0.22 + 0.25 * strength), 3.0)
	_shield_layer.draw_arc(centre, radius * 0.97, 0.0, TAU, 64, Color(blue.lightened(0.3), 0.2 * strength), 2.0)
	# The generator: a small station on the surface feeding the field.
	var gen := centre + Vector2(0, r * 0.95)
	_shield_layer.draw_circle(gen, 9.0, Color(blue, 0.3 * strength))
	_shield_layer.draw_rect(Rect2(gen - Vector2(5, 4), Vector2(10, 8)), Color("c9d2d8"))
	_shield_layer.draw_rect(Rect2(gen - Vector2(1.5, 10), Vector2(3, 6)), blue.lightened(0.3))



## A soft glow with slowly turning rays behind a notification bubble, so it stands out.
func _glow_behind(c: Vector2, r: float, colour: Color) -> void:
	var pulse := 0.5 + 0.5 * sin(_time * 2.0)
	for i in 5:
		draw_circle(c, r * (1.5 + i * 0.35 + 0.15 * pulse), Color(colour, 0.035 + 0.015 * pulse))
	for i in 8:
		var a := _time * 0.4 + TAU * i / 8.0
		var tip := c + Vector2.RIGHT.rotated(a) * r * (2.4 + 0.3 * pulse)
		var left := c + Vector2.RIGHT.rotated(a - 0.12) * r * 1.1
		var right := c + Vector2.RIGHT.rotated(a + 0.12) * r * 1.1
		draw_colored_polygon(PackedVector2Array([left, tip, right]), Color(colour, 0.07 + 0.04 * pulse))
