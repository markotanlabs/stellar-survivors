extends Node2D
## Prototype milestone 1c: tutorial map, galaxy and system views, camera,
## Fleet Mode with booster, warp travel, economy tick with floating gains,
## population growth, planet panel, top bar, hotkey bar and build menu.

const GD = preload("res://scripts/game_data.gd")
const Sfx = preload("res://scripts/sfx.gd")
const Generator = preload("res://scripts/generator.gd")
const SystemView = preload("res://scripts/system_view.gd")
const GalaxyView = preload("res://scripts/galaxy_view.gd")
const Hud = preload("res://scripts/hud.gd")
const FloatText = preload("res://scripts/float_text.gd")
const ShipScript = preload("res://scripts/ship.gd")
const FleetOverlay = preload("res://scripts/fleet_overlay.gd")
const Hyperspace = preload("res://scripts/hyperspace.gd")
const PlanetGun = preload("res://scripts/planet_gun.gd")
const Hauler = preload("res://scripts/hauler.gd")
const Pickup = preload("res://scripts/pickup.gd")
const RepairPlus = preload("res://scripts/repair_plus.gd")
const JetPuff = preload("res://scripts/jet_puff.gd")
const ColonyShip = preload("res://scripts/colony_ship.gd")
const MusicPlayer = preload("res://scripts/music.gd")
const Settings = preload("res://scripts/settings.gd")
const PausedInput = preload("res://scripts/paused_input.gd")
const SfxPlayer = preload("res://scripts/sfx.gd")
const BuildSite = preload("res://scripts/build_site.gd")
const ConstructionShip = preload("res://scripts/construction_ship.gd")
const BlinkFlash = preload("res://scripts/blink_flash.gd")
const Afterimage = preload("res://scripts/afterimage.gd")
const WakeFire = preload("res://scripts/wake_fire.gd")
const Mine = preload("res://scripts/mine.gd")
const SonsAI = preload("res://scripts/sons_ai.gd")
const FeedbackPanel = preload("res://scripts/feedback.gd")

const PAN_SPEED := 1400.0   # pixels per second at zoom 1
const PAN_BOOST := 1.6      # RTS camera with Shift held (v0.9.137)
const ZOOM_MIN := 0.25      # fully zoomed out (about 4x; back from 0.3, v0.9.143)
const ZOOM_MIN_FLEET := 0.3125   # in Fleet Mode you can zoom out 20% less (v0.9.178)
const ZOOM_MAX := 1.5
const HOME := 1

enum Warp { NONE, CHARGING, LOCKED, TRANSIT }

var systems: Array = []
var current := HOME
var in_galaxy := false
var fleet_mode := false

var amounts := {"alloys": GD.TEST_START if GD.TEST_START > 0 else GD.START_ALLOYS, "gas": GD.TEST_START, "credits": GD.TEST_START}
var tick_left := GD.TICK_SECONDS
var starbase_limit := GD.STARBASE_LIMIT
var tech_cards: Array = []
var fleet_cards: Array = []
var xp := 0
var xp_need := GD.XP_FIRST
var tick_count := 0
var card_queue: Array = []
var card_open: Dictionary = {}

# Floaty fleet movement, escorts and shopping.
var fleet_velocity := Vector2.ZERO
var _last_dir := Vector2.ZERO
var _escorts_out := false
var returning: Array = []
var pickup_cost := float(GD.PICKUP_COST)
var dealer_price_mult := 1.0   # arms dealer cards cost 50% more after every purchase
var pickups: Array = []
var shop_dealer: Node2D = null
var _dealer_cooldown: Node2D = null
var rebels_alerted := false
var fleet_heading := 0.0
var autopilot := false
var _pilot_planet: Dictionary = {}   # autopilot goal: a planet's Growth Reward bubble (empty: nearest Starbase)
var _pilot_system := -1
var _fog_timer := 0.0
var _planet_cycle := 0
var _bubble_hint_shown := false
var game_over := false
var _aim_settle := 0.0
var pursuers: Array = []
var _side_jet_at := -9.0
var warp_watch := false     # true: the camera rides this jump (you were in Fleet Mode when it began)
var _fade_started := false
var music: Node
var wave_n := 0
var wave_at := 0.0
var waves_over := false
var colony_ships: Array = []
var warnings: Array = []     # {kind, system, pos, until}
var _colony_target: Dictionary = {}
var _last_aim := Vector2.ZERO
var run_time := 0.0
var enemies_destroyed := 0
var peak_pop := 0
var alloys_mined := 0
var systems_conquered := 0
var kills_by_name := {}
var fleet_level := 1   # goes up each time the Fleet XP bar fills
var stations_built := 0
var _stockpiles := {}
var _toast_cooldown := 0.0
var hyperspace: Hyperspace

var camera: Camera2D
var galaxy_view: GalaxyView
var system_views: Array = []
var hud: Hud

# The Kharkiv and the ships travelling with it.
var kharkiv: ShipScript
var fleet_system := HOME
var fleet: Array = []
var fleet_offsets: Array = []
var _form_state := {}   # escort instance id -> {vel, seen, delay, phase}: loose formation flying
var _k_prev := Vector2.INF   # the Kharkiv's position last frame, for the escorts to match its speed
var _k_vel := Vector2.ZERO
var overlay: FleetOverlay

# Booster.
var boost_meter := 1.0
var boost_delay := 0.0
var boosting := false
var _free_boost := false      # Tightened Logistics active right now
var _logistics_check := 0.0
var _auto_boost_wait := false
var _boost_spent := false   # meter ran dry: Shift must be released and pressed again

# Building: placing station ghosts, the Construction Ship, Shipyard queues.
var placing := ""                  # structure being placed, "" when not placing
var _place_ghost: BuildSite = null
var _click_block := false          # the click that placed something doesn't also fire
var _right_block := false          # the right-click that cancelled a ghost doesn't send escorts
var build_sites: Array = []        # placed ghosts, in build order
# Construction crews (v0.9.226): one per Construction Ship you're allowed (1 + Shipwright
# Guild cards). Each takes the next site in line, so several stations can go up at once.
# A crew: {"ship": ConstructionShip or null, "job": BuildSite or null, "home": bool,
#          "dock": {} (where it's recycled when idle), "respawn": seconds until relaunch}
var _crews: Array = []
var recruits: Array = []           # new ships waiting at their Shipyard for the fleet
var _civilian_said_at := -99.0

# Movement tech and Kharkiv weapons.
var _blink_cd := 0.0
var _wake_timer := 0.0
var _mine_timer := 0.0
var mines: Array = []
var sons: SonsAI = null   # the Sons of Philip's AI (wakes when the Rebels are broken)
var _shield_timer := 0.0

# Warp.
var warp_state := Warp.NONE
var warp_time := 0.0
var warp_exit: Dictionary = {}
# Riding a jump (v0.9.204): the fleet flies out along the exit's course line, swaps
# systems at the peak of the warp, and flies in along the entry's line. No galaxy map.
const WARP_FLY := 140.0          # units flown off the edge (and in from it) during a jump
var _transit_half := 0           # 1: leaving the old system, 2: arriving in the new one
var _transit_zoom := Vector2.ZERO


func _ready() -> void:
	# The title screen comes first (after the MarkoLabs intro, at launch).
	if not GD.menu_passed:
		process_mode = Node.PROCESS_MODE_DISABLED
		get_tree().change_scene_to_file.call_deferred("res://scenes/intro.tscn")
		return
	Settings.load_settings()
	GD.reset_run()
	_setup_input()
	add_child(FeedbackPanel.new())   # Enter anywhere: send feedback
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	systems = Generator.build_map(rng)
	for s in systems:
		var planets: Array = s["planets"]
		for p in planets:
			p["card_base"] = p["pops"]

	camera = Camera2D.new()
	add_child(camera)
	camera.make_current()

	for s in systems:
		var view := SystemView.new()
		add_child(view)
		view.setup(s)
		view.visible = false
		view.exit_clicked.connect(_open_system)
		view.planet_clicked.connect(_on_planet_clicked)
		view.tech_base_destroyed.connect(_on_tech_base_destroyed)
		view.rich_destroyed.connect(_on_rich_destroyed)
		view.rebel_base_hit.connect(_on_rebel_base_hit)
		view.rebel_base_destroyed.connect(_on_rebel_base_destroyed)
		view.bubble_clicked.connect(_on_bubble_clicked)
		view.rock_destroyed.connect(_on_rock_cash)
		view.planet_fallen.connect(_on_planet_fallen)
		view.planet_hit.connect(_on_planet_hit)
		view.starbase_hit.connect(_on_starbase_hit)
		view.starbase_destroyed.connect(_on_starbase_destroyed)
		system_views.append(view)

	galaxy_view = GalaxyView.new()
	add_child(galaxy_view)
	galaxy_view.setup(systems, Generator.LINKS)
	galaxy_view.visible = false
	galaxy_view.system_clicked.connect(_open_system)
	galaxy_view.flagship_clicked.connect(func() -> void: _set_fleet_mode(true))

	hud = Hud.new()
	add_child(hud)
	hud.build_requested.connect(_on_build_requested)
	hud.unqueue_requested.connect(_on_unqueue_requested)
	hud.card_picked.connect(_on_card_picked)
	hud.redraw_requested.connect(_on_redraw)
	hud.shop_buy.connect(_on_shop_buy)
	hud.shop_refresh.connect(_on_shop_refresh)
	hud.shop_leave.connect(_on_shop_leave)
	hud.restart_requested.connect(_on_restart)
	hud.collection_requested.connect(_show_collection)
	hud.menu_requested.connect(_on_main_menu)
	hud.pause_blocked = func() -> bool: return placing != ""
	hud.notification_clicked.connect(_on_notification_clicked)
	hud.reward_slot_clicked.connect(_claim_bubble)
	hyperspace = Hyperspace.new()
	add_child(hyperspace)

	_find_starting_fleet()
	for view in system_views:
		for child in view.get_children():
			var ship := child as ShipScript
			if ship != null and ship.faction != GD.Faction.UNE:
				ship.destroyed.connect(_on_enemy_destroyed)
	overlay = FleetOverlay.new()
	system_views[fleet_system].add_child(overlay)
	_open_system(HOME)
	_refresh_hud()
	hud.show_xp(xp, xp_need, fleet_level)
	_set_fleet_mode(true)
	for s in systems:
		for p in Array(s["planets"]):
			p["reward_peak"] = int(p["pops"])
	wave_at = GD.WAVE_FIRST + randf() * GD.WAVE_LATE
	music = MusicPlayer.shared(get_tree())
	hud.set_music(music)
	add_child(SfxPlayer.new())
	Settings.apply()
	var paused_input := PausedInput.new()
	paused_input.main = self
	add_child(paused_input)
	hud.guide_closed.connect(_on_guide_closed)
	sons = SonsAI.new()
	sons.main = self
	add_child(sons)
	if not Hud.guide_hidden():
		call_deferred("_show_guide")


func _find_starting_fleet() -> void:
	var home_view: Node2D = system_views[HOME]
	for child in home_view.get_children():
		var ship := child as ShipScript
		if ship == null or ship.faction != GD.Faction.UNE:
			continue
		if ship.type_id == "capital":
			kharkiv = ship
		ship.driven = true
		fleet.append(ship)
		ship.destroyed.connect(_on_fleet_ship_destroyed)
	_remember_formation()
	fleet_heading = kharkiv.heading
	for i in fleet.size():
		var ship: ShipScript = fleet[i]
		ship.position = _slot_of(i)


func _on_fleet_ship_destroyed(ship: Node2D) -> void:
	# The Sons earn XP for your ships they destroy.
	var killer = ship.get("_attacker")
	if sons != null and is_instance_valid(killer) and killer.get("faction") == GD.Faction.SONS:
		sons.add_xp(maxi(1, int(GD.SHIPS[String(ship.get("type_id"))]["tier"])))
	var i := fleet.find(ship)
	if i >= 0:
		fleet.remove_at(i)
		fleet_offsets.remove_at(i)
	if ship == kharkiv:
		_death_report = _last_hits(ship)
		SfxPlayer.death_bleed(hud)
		fleet_mode = false
		hud.set_fleet_mode(false)
		warp_state = Warp.NONE
		overlay.visible = false
		kharkiv = null
		autopilot = false
		hud.set_low_health(1.0)
		game_over = true
		call_deferred("_show_game_over")


## A realistic-ish strike group, in the flagship's own frame (x = forward):
## Corvettes picket out front, Destroyers hug the flanks, Frigates and Cruisers
## form an outer ring, big ships sit in the centre with the flagship.
func _remember_formation() -> void:
	fleet_offsets.clear()
	var groups := {"picket": [], "flank": [], "ring": [], "centre": []}
	for ship in fleet:
		match String(ship.type_id):
			"capital":
				pass
			"corvette":
				groups["picket"].append(ship)
			"destroyer":
				groups["flank"].append(ship)
			"frigate", "cruiser":
				groups["ring"].append(ship)
			_:
				groups["centre"].append(ship)
	var slots := {}
	var picket: Array = groups["picket"]
	for i in picket.size():
		slots[picket[i]] = Vector2(8.0, (i - (picket.size() - 1) / 2.0) * 4.0)
	var flank: Array = groups["flank"]
	for i in flank.size():
		var side := -1.0 if i % 2 == 0 else 1.0
		slots[flank[i]] = Vector2(-1.0 - float(i / 2) * 3.0, side * 6.0)
	var ring: Array = groups["ring"]
	for i in ring.size():
		# Spread around the sides and rear (45° to 315°); the front belongs to the picket.
		var a: float = PI * 0.25 + PI * 1.5 * (float(i) + 0.5) / float(ring.size())
		slots[ring[i]] = Vector2.RIGHT.rotated(a) * 11.0
	var centre: Array = groups["centre"]
	for i in centre.size():
		slots[centre[i]] = Vector2(-6.0 - float(i / 2) * 5.0, (-1.0 if i % 2 == 0 else 1.0) * 3.0)
	for ship in fleet:
		var local: Vector2 = slots.get(ship, Vector2.ZERO)
		fleet_offsets.append(local * GD.UNIT)


func _slot_of(i: int) -> Vector2:
	var offset: Vector2 = fleet_offsets[i]
	return kharkiv.position + offset.rotated(fleet_heading)


# --- input ---------------------------------------------------------------------

func _setup_input() -> void:
	_add_action("move_up", [KEY_W])
	_add_action("move_down", [KEY_S])
	_add_action("move_left", [KEY_A])
	_add_action("move_right", [KEY_D])
	_add_action("pan_up", [KEY_UP])
	_add_action("pan_down", [KEY_DOWN])
	_add_action("pan_left", [KEY_LEFT])
	_add_action("pan_right", [KEY_RIGHT])
	_add_action("fleet_mode", [KEY_F])
	_add_action("galaxy", [KEY_TAB])
	_add_action("build", [KEY_B])
	_add_action("full_names", [KEY_SPACE])
	_add_action("boost", [KEY_SHIFT])
	_add_action("fullscreen", [KEY_F11])
	_add_action("close_panel", [KEY_ESCAPE])
	_add_action("home", [KEY_H])
	# Planet cycling (_on_cycle_key) is switched off for now: no key bound.
	_add_action("cycle", [])
	_add_action("colonize", [KEY_C])
	_add_action("secondary", [KEY_ALT])


func _add_action(action: String, keys: Array) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	for k in keys:
		var e := InputEventKey.new()
		e.physical_keycode = k
		InputMap.action_add_event(action, e)


## Attached to feedback notes (FeedbackPanel).
func feedback_context() -> Dictionary:
	var secs := int(run_time)
	var where := "galaxy map" if in_galaxy else ("fleet mode" if fleet_mode else "flagship")
	var sys_name := ""
	if current >= 0 and current < systems.size():
		sys_name = String(systems[current].get("name", str(current)))
	return {"day": tick_count + 1, "time": "%d:%02d" % [secs / 60, secs % 60], "system": sys_name, "view": where}


func _unhandled_input(event: InputEvent) -> void:
	if FeedbackPanel.is_open:
		return   # typing feedback (Enter panel)
	if event.is_action_pressed("fullscreen"):
		_toggle_fullscreen()
		get_viewport().set_input_as_handled()
		return
	if warp_state == Warp.TRANSIT and warp_watch:
		return   # riding the jump: no input until you arrive
	if warp_state == Warp.TRANSIT and event.is_action_pressed("fleet_mode"):
		_set_fleet_mode(true)
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("galaxy"):
		if in_galaxy:
			_open_system(current)
		else:
			_set_fleet_mode(false)
			_open_galaxy()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("fleet_mode"):
		_set_fleet_mode(not fleet_mode)
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("home"):
		_on_home_key()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("colonize"):
		_try_colonize()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("cycle"):
		_on_cycle_key()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("build"):
		hud.toggle_build_menu()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("close_panel"):
		if placing != "":
			_cancel_placing()
		elif hud.is_planet_open():
			hud.hide_planet()
		elif hud.is_build_open():
			hud.toggle_build_menu()
		elif card_open.is_empty() and not game_over:
			hud.open_pause_menu()
		get_viewport().set_input_as_handled()
		return
	var button := event as InputEventMouseButton
	if button != null and button.pressed and fleet_mode and not in_galaxy:
		if button.button_index == MOUSE_BUTTON_LEFT:
			_focus_at(get_global_mouse_position())
			get_viewport().set_input_as_handled()
			return
	# No zooming or dragging the view while a card screen (or the Arms Dealer) is up,
	# or while Xander is talking (v0.9.181).
	var picking := not card_open.is_empty() or shop_dealer != null or hud.has_card_screen() or _xander_up()
	if button != null and button.pressed and not picking:
		if button.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_by(1.1)
		elif button.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_by(1.0 / 1.1)
	var motion := event as InputEventMouseMotion
	if motion != null and not fleet_mode and not picking and (motion.button_mask & (MOUSE_BUTTON_MASK_RIGHT | MOUSE_BUTTON_MASK_MIDDLE)) != 0:
		camera.position -= motion.relative / camera.zoom.x
		_clamp_camera()


func _toggle_fullscreen() -> void:
	var mode := DisplayServer.window_get_mode()
	if mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


## Xander has a message or lesson on screen.
func _xander_up() -> bool:
	return hud != null and hud.xander != null and is_instance_valid(hud.xander) and hud.xander.visible


func _zoom_by(factor: float) -> void:
	var z := clampf(camera.zoom.x * factor, ZOOM_MIN_FLEET if fleet_mode else ZOOM_MIN, ZOOM_MAX)
	camera.zoom = Vector2(z, z)
	get_tree().call_group("ships", "queue_redraw")


func _process(delta: float) -> void:
	if game_over:
		return
	run_time += delta
	if run_time > 6.0 and run_time - delta <= 6.0:
		hud.xander.call("say", "hello", "Hi Commander, I'm Xander! SPACE is your best friend: hold it to see everything.\n\nI'm also around when you do something... creative.", "", false, ["SPACE"])
	_fog_timer -= delta
	if _fog_timer <= 0.0:
		_fog_timer = 0.3
		_update_fog()
	_update_full_names()
	_update_info_tip()
	_update_waves()
	_update_wave_jumps()
	_update_colonize_prompt()
	_update_colonizing(delta)
	_update_warnings()
	_update_boost(delta)
	_update_warp(delta)
	if fleet_mode and kharkiv != null and not in_galaxy and current != fleet_system and warp_state != Warp.TRANSIT:
		_open_system(fleet_system)
	if kharkiv != null and (fleet_mode or autopilot):
		_steer_fleet(delta)
	else:
		_coast_fleet(delta)
	_fly_escorts(delta)
	_update_aim(delta)
	_update_placing()
	_update_mines(delta)
	if sons != null:
		# Philip strikes at whichever comes first: Rebel Rock falling, or the 10:00 mark.
		# Xander warns 30 seconds ahead: Philip is his estranged dad.
		var warn_at := GD.PHILIP_FIRST_AT - 30.0
		if not bool(sons.get("active")) and run_time >= warn_at and run_time - delta < warn_at:
			hud.xander.call("say", "philip",
				"Heads up, Commander. In 30 seconds the Sons of Philip strike from Mars. Philip is...my...HEY! Let's focus on the more important things here!",
				"His waves keep getting bigger. Dig in, and take Mars to end it.", true)
		if not bool(sons.get("active")) and run_time >= GD.PHILIP_FIRST_AT:
			sons.activate()
		sons.update(delta)
	_update_station_sound()
	_shield_timer -= delta
	if _shield_timer <= 0.0:
		_shield_timer = 1.0
		_refresh_rock_shields()
	_update_construction(delta)
	_update_shipyards(delta)
	_update_recruits()
	if kharkiv != null:
		_update_escorts(delta)
		_world_update(delta)
	# No WASD panning while a card screen (or the arms dealer) is open: pick first.
	if not fleet_mode and not in_galaxy and card_open.is_empty() and shop_dealer == null and not hud.has_card_screen() and not _xander_up():
		var dir := Input.get_vector("pan_left", "pan_right", "pan_up", "pan_down")
		dir += Input.get_vector("move_left", "move_right", "move_up", "move_down")
		if dir != Vector2.ZERO:
			# Holding Shift (Boost) pans the RTS camera a bit faster.
			var pan_boost := PAN_BOOST if Input.is_action_pressed("boost") else 1.0
			camera.position += dir.limit_length(1.0) * PAN_SPEED * pan_boost * delta / camera.zoom.x
			_clamp_camera()
	if kharkiv != null:
		overlay.position = kharkiv.position
		overlay.free_boost = _free_boost
		overlay.show_boost = fleet_mode and (boost_meter < 0.999 or (boosting and _free_boost))
		overlay.boost = boost_meter
	tick_left -= delta
	if tick_left <= 0.0:
		tick_left += GD.TICK_SECONDS
		_economy_tick()
	hud.show_tick(tick_left, tick_count + 1)


## Info mode (Space held): hovering anything in the system (ships, stations, rocks,
## bases, planets...) shows a detailed card about it.
func _update_info_tip() -> void:
	var key := ""
	var found: Node2D = null
	var extra := {}
	var ident := ""
	if GD.show_full_names and not in_galaxy:
		var view: Node2D = system_views[current]
		var mouse := view.get_local_mouse_position()
		var best := INF
		for child in view.get_children():
			var node := child as Node2D
			if node == null or not node.is_visible_in_tree() or node.get("alive") == false:
				continue
			if node.get("fog_mode") == "hidden" or node.get("fog_mode") == "dot":
				continue
			var k := _info_key(node)
			if k == "":
				continue
			var reach := _hover_radius(node) + 0.6 * GD.UNIT
			var d := node.position.distance_to(mouse)
			if d <= reach and d < best:
				best = d
				found = node
				key = k
		if found != null:
			ident = str(found.get_instance_id())
			extra = _info_extra(key, found)
		else:
			var p: Dictionary = view.call("planet_at", mouse)
			if not p.is_empty():
				key = _planet_key(p)
				ident = "planet:" + String(p["name"])
				extra = _planet_extra(p)
				# Info mode shows the same planet window you get by clicking it.
				extra["planet"] = p
				extra["income"] = _planet_income(p)
			else:
				for g in Array(systems[current].get("gas_giants", [])):
					if mouse.distance_to(Vector2(g["pos"]) * GD.UNIT) <= float(g["radius"]) * GD.UNIT:
						key = "gas_giant"
						ident = "giant:%s" % str(g["pos"])
						break
	hud.show_info_tip(key, found, extra, ident)


## Which info card a thing in the system gets ("" for none).
func _info_key(node: Node2D) -> String:
	var st = node.get("structure")
	if st is Dictionary and not (st as Dictionary).is_empty():
		return String((st as Dictionary).get("type", ""))
	if node.is_in_group("ships"):
		return String(node.get("type_id"))
	var scr = node.get_script()
	var file := String(scr.resource_path).get_file().get_basename() if scr != null else ""
	match file:
		"asteroid":
			var kind := String(node.get("kind"))
			if kind == "gas":
				return "asteroid_gas"
			if kind == "rock":
				return "asteroid_alloys" if int(node.get("yield_alloys")) > 0 else "asteroid_plain"
			return ""   # silver and gold stay a mystery
		"rebel_base", "tech_base", "hauler", "colony_ship", "construction_ship", "mine", "arms_dealer":
			return file
		"pickup":
			var pk := String(node.get("kind"))
			return "pickup_" + pk if pk == "fleet" or pk == "tech" else ""
		"planet_gun":
			if node.get("draw_base") == true and String(node.get("weapon_id")) == "pd_mag":
				return "pd_mag"
	return ""


func _hover_radius(node: Node2D) -> float:
	if node.has_method("radius_px"):
		return float(node.call("radius_px"))
	var t = node.get("type_id")
	if t != null and GD.SHIPS.has(String(t)):
		return GD.ship_pixels(String(t))
	var r = node.get("radius")
	if r != null:
		return float(r) * GD.UNIT
	return 1.2 * GD.UNIT


func _info_extra(key: String, node: Node2D) -> Dictionary:
	var lines: Array = []
	if key.begins_with("asteroid_"):
		var parts := PackedStringArray()
		if int(node.get("yield_alloys")) > 0:
			parts.append("%d Alloys" % int(node.get("yield_alloys")))
		if int(node.get("yield_gas")) > 0:
			parts.append("%d Gas" % int(node.get("yield_gas")))
		if not parts.is_empty():
			lines.append("Yield: " + ", ".join(parts) + " per day")
	elif key == "hauler":
		var cargo = node.get("cargo")
		if cargo is Dictionary and not (cargo as Dictionary).is_empty():
			var parts := PackedStringArray()
			for res in (cargo as Dictionary).keys():
				parts.append("%d %s" % [int(cargo[res]), String(res).capitalize()])
			lines.append("Cargo: " + ", ".join(parts))
	elif key == "colony_ship":
		lines.append("Pops aboard: %d" % int(node.get("pops")))
	return {"lines": lines}


func _planet_key(p: Dictionary) -> String:
	var kind := String(p.get("kind", ""))
	if kind == "earth":
		return "planet_earth"
	if kind == "mars":
		return "planet_mars"
	var owner := int(p["owner"])
	if owner == GD.Faction.UNE:
		return "planet_yours"
	if owner != GD.Faction.NEUTRAL:
		return "planet_enemy"
	return "planet_dead" if int(p["capacity"]) <= 0 else "planet_open"


func _planet_extra(p: Dictionary) -> Dictionary:
	var lines: Array = []
	if int(p["capacity"]) > 0:
		lines.append("Pops: %d / %d" % [int(p["pops"]), int(p["capacity"])])
	var buildings: Array = p.get("buildings", [])
	if not buildings.is_empty():
		var names := PackedStringArray()
		for b in buildings:
			if String(b) != "":
				names.append(String(b))
		if not names.is_empty():
			lines.append("Buildings: " + ", ".join(names))
	return {"title": String(p["name"]).to_upper(), "lines": lines}


func _update_full_names() -> void:
	var held := Input.is_action_pressed("full_names")
	if held == GD.show_full_names:
		return
	GD.show_full_names = held
	GD.show_ranges = held   # Space is the info button: full names and weapon ranges
	hud.set_key_active("SPACE", held)
	get_tree().call_group("ships", "queue_redraw")


func _clamp_camera() -> void:
	if in_galaxy:
		return
	var limit := (GD.SYSTEM_RADIUS + 40.0) * GD.UNIT   # room to see the warp arrows outside
	if camera.position.length() > limit:
		camera.position = camera.position.normalized() * limit


# --- Fleet Mode and booster -------------------------------------------------------

func _set_fleet_mode(on: bool) -> void:
	if kharkiv == null:
		return
	if warp_state == Warp.TRANSIT:
		# Mid-jump you can step into the ride (F), but not out of it.
		if on and not warp_watch:
			warp_watch = true
			fleet_mode = true
			hud.set_fleet_mode(true)
			_watch_transit()
		return
	if fleet_mode != on:
		SfxPlayer.ui("blip", -6.0)
	fleet_mode = on
	hud.set_fleet_mode(on)
	for view in system_views:
		view.allow_planet_clicks = not on
	if on:
		hud.hide_planet()
	if on:
		Input.set_custom_mouse_cursor(_reticle_texture(), Input.CURSOR_ARROW, Vector2(16, 16))
	else:
		Input.set_custom_mouse_cursor(null)
	if on and (in_galaxy or current != fleet_system):
		_open_system(fleet_system)
	if on and not in_galaxy and camera.zoom.x < ZOOM_MIN_FLEET:
		camera.zoom = Vector2(ZOOM_MIN_FLEET, ZOOM_MIN_FLEET)   # Fleet Mode's closer limit


func _fleet_in_asteroid_field() -> bool:
	var sys: Dictionary = systems[fleet_system]
	var fields: Array = sys["fields"]
	for f in fields:
		var f_pos: Vector2 = f["pos"]
		var radius: float = f["radius"]
		if (kharkiv.position / GD.UNIT).distance_to(f_pos) <= radius:
			return true
	return false


func _update_boost(delta: float) -> void:
	var wants := fleet_mode and kharkiv != null and Input.is_action_pressed("boost")
	var allowed := warp_state == Warp.NONE or warp_state == Warp.CHARGING
	var moving := Input.get_vector("move_left", "move_right", "move_up", "move_down") != Vector2.ZERO
	var was_boosting := boosting
	_blink_cd = maxf(0.0, _blink_cd - delta)
	# Blink Drive: tapping Boost jumps the fleet a short way instead.
	if GD.blink_level > 0 and fleet_mode and kharkiv != null and warp_state == Warp.NONE and moving \
			and Input.is_action_just_pressed("boost") and not _fleet_in_asteroid_field():
		if GD.blink_level >= 2 and _blink_cd <= 0.0:
			_blink()
			_blink_cd = GD.BLINK_COOLDOWN
		elif GD.blink_level == 1 and boost_meter >= 0.999:
			_blink()
			boost_meter = GD.BLINK_KEEP   # half the meter stays for boosting (v0.9.123)
			boost_delay = GD.BOOST_DELAY
	# Running dry ends the boost until Shift is let go; holding it doesn't stop the refill.
	if not Input.is_action_pressed("boost"):
		_boost_spent = false
	boosting = wants and allowed and moving and boost_meter > 0.0 and not _boost_spent and not _fleet_in_asteroid_field()
	# Autopilot boosts the whole way, to a Growth Reward or home with H (v0.9.199);
	# pressing Shift hands control back.
	var auto := autopilot and kharkiv != null and fleet_mode
	if auto and Input.is_action_just_pressed("boost"):
		autopilot = false
		_pilot_planet = {}
		auto = false
		hud.show_toast("Autopilot off", 1.5)
	if auto:
		# Run the meter dry, then wait for a full refill before boosting again (no stutter).
		if boost_meter <= 0.0:
			_auto_boost_wait = true
		elif _auto_boost_wait and boost_meter >= 0.999:
			_auto_boost_wait = false
		boosting = allowed and not _auto_boost_wait and boost_meter > 0.0 and not _fleet_in_asteroid_field()
	else:
		_auto_boost_wait = false
	GD.boosting = boosting
	if boosting != was_boosting:
		SfxPlayer.set_boost(boosting)
	# Cruising engines: a soft rumble that follows the flagship's speed.
	if kharkiv != null and is_instance_valid(kharkiv):
		var top := maxf(kharkiv.speed_units * GD.UNIT, 1.0)
		SfxPlayer.set_cruise(kharkiv.velocity.length() / top)
	_logistics_check -= delta
	if _logistics_check <= 0.0:
		_logistics_check = 0.5
		_free_boost = _logistics_free()
	if boosting:
		if not _free_boost:
			boost_meter = maxf(0.0, boost_meter - delta / (GD.BOOST_MAX * GD.boost_capacity_mult))
		if boost_meter <= 0.0:
			_boost_spent = true
		if GD.afterburner_wake:
			_wake_timer -= delta
			if _wake_timer <= 0.0:
				_wake_timer = 0.12
				var wake := WakeFire.new()
				system_views[fleet_system].add_child(wake)
				var behind := -fleet_velocity.normalized() if fleet_velocity.length() > 1.0 else Vector2.ZERO
				wake.setup(kharkiv.position + behind * GD.ship_pixels("capital") * 0.8)
		boost_delay = GD.BOOST_DELAY
	elif boost_delay > 0.0:
		boost_delay -= delta
	else:
		boost_meter = minf(1.0, boost_meter + delta * GD.boost_refill_mult / GD.BOOST_REFILL)
	hud.set_key_active("SHIFT", boosting)
	hud.show_boost_meter(boost_meter, boosting)
	# Boost only affects ships in formation; escorts sent out with right-click keep fighting.
	for ship in fleet:
		if is_instance_valid(ship):
			ship.hold_fire = false


func _steer_fleet(delta: float) -> void:
	if warp_state == Warp.LOCKED or warp_state == Warp.TRANSIT:
		return
	var dir := Vector2.ZERO
	if fleet_mode:
		dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if autopilot and dir != Vector2.ZERO:
		autopilot = false
		hud.show_toast("Autopilot off", 1.5)
	elif autopilot:
		dir = _autopilot_dir()
	var max_speed := kharkiv.speed_units * GD.UNIT * (GD.BOOST_MULT if boosting else 1.0)
	var accel := kharkiv.speed_units * GD.UNIT * 2.5
	if dir != Vector2.ZERO:
		# Drift Thrusters: swing the whole velocity round to the new heading, keeping speed.
		if GD.drift_thrusters and fleet_velocity.length() > 1.0:
			var keep := fleet_velocity.length()
			var angle := lerp_angle(fleet_velocity.angle(), dir.angle(), clampf(delta * 8.0, 0.0, 1.0))
			fleet_velocity = Vector2.from_angle(angle) * keep
		fleet_velocity = fleet_velocity.move_toward(dir.limit_length(1.0) * max_speed, accel * (3.0 if boosting else 1.0) * delta)
	else:
		fleet_velocity = fleet_velocity.move_toward(Vector2.ZERO, accel * 0.45 * delta)
	# Letting go of a direction fires a counter-thrust jet from the nose; pushing off
	# from slow fires one out the back.
	if _last_dir != Vector2.ZERO and dir == Vector2.ZERO and fleet_velocity.length() > max_speed * 0.25:
		_brake_jets(fleet_velocity.normalized())
	elif _last_dir == Vector2.ZERO and dir != Vector2.ZERO and fleet_velocity.length() < max_speed * 0.5:
		_brake_jets(-dir.normalized())
	elif _last_dir != Vector2.ZERO and dir != Vector2.ZERO and fleet_velocity.length() > max_speed * 0.3:
		# Turning: puff from the outside of the turn.
		var turn := _last_dir.normalized().angle_to(dir.normalized())
		if absf(turn) > 0.6 and run_time - _side_jet_at > 0.25:
			_side_jet_at = run_time
			_turn_jets(turn > 0.0)
	_last_dir = dir
	if fleet_velocity.length() > 1.0:
		_move_fleet(kharkiv.position + fleet_velocity * delta, fleet_velocity.angle(), delta)
	# The camera follows the Kharkiv (only in Fleet Mode; autopilot alone leaves it free).
	if fleet_mode:
		var weight := 1.0 - exp(-6.0 * delta)
		camera.position = camera.position.lerp(kharkiv.position, weight)


## Outside Fleet Mode the fleet keeps drifting and slows to a stop.
func _coast_fleet(delta: float) -> void:
	if kharkiv == null or fleet_velocity.length() < 1.0 or warp_state == Warp.TRANSIT or warp_state == Warp.LOCKED:
		return
	fleet_velocity = fleet_velocity.move_toward(Vector2.ZERO, kharkiv.speed_units * GD.UNIT * 1.1 * delta)
	_move_fleet(kharkiv.position + fleet_velocity * delta, fleet_velocity.angle(), delta)


## One narrow jet per ship, pointing along `out` (forward when braking, backward when pushing off).
func _brake_jets(out: Vector2) -> void:
	SfxPlayer.play("jet", kharkiv, -13.0, 0.1)
	var view: Node2D = system_views[fleet_system]
	for ship in fleet:
		if not is_instance_valid(ship) or not ship.driven or not ship.visible:
			continue
		var r := GD.ship_pixels(ship.type_id)
		var puff := JetPuff.new()
		view.add_child(puff)
		puff.setup(ship.position + out * r * 0.8, out, r * 0.45, 0.1)


## Turning, like the ships in The Expanse (v0.9.216): sharp RCS bursts fired sideways
## from right at the hull near each ship's nose (pushing it round), with a smaller
## answering burst at the stern on the other side.
func _turn_jets(turning_right: bool) -> void:
	SfxPlayer.play("jet", kharkiv, -14.0, 0.12)
	var view: Node2D = system_views[fleet_system]
	for ship in fleet:
		if not is_instance_valid(ship) or not ship.driven or not ship.visible:
			continue
		var r := GD.ship_pixels(ship.type_id)
		var fwd := Vector2.from_angle(ship.heading)
		var side := fwd.orthogonal() * (-1.0 if turning_right else 1.0)   # the turn's inside (y points down)
		var hull := r * 0.32   # half the hull's width, roughly
		# Bow thruster on the outside of the turn, blowing outward.
		var bow := JetPuff.new()
		view.add_child(bow)
		bow.setup(ship.position + fwd * r * 0.78 - side * hull, -side, r * 0.28, 0.05, 0.3)
		# Stern thruster on the inside, blowing inward: the pair spins the hull.
		var stern := JetPuff.new()
		view.add_child(stern)
		stern.setup(ship.position - fwd * r * 0.7 + side * hull, side, r * 0.2, 0.05, 0.26)


## Moves the whole fleet so the Kharkiv ends up at next_pos, keeping formation.
func _move_fleet(next_pos: Vector2, facing: float, delta: float) -> void:
	var limit := (GD.SYSTEM_RADIUS - 4.0) * GD.UNIT
	if next_pos.length() > limit:
		next_pos = next_pos.normalized() * limit
		fleet_velocity = fleet_velocity.slide(next_pos.normalized())
	# The formation turns with the fleet, a little behind the flagship's nose.
	# It swings round slowly, and each ship noses the way it is actually moving,
	# so turns read as a group manoeuvre instead of everyone snapping to the flagship.
	fleet_heading = lerp_angle(fleet_heading, facing, clampf(delta * (3.0 if GD.drift_thrusters else 0.9), 0.0, 1.0))
	kharkiv.position = next_pos
	kharkiv.heading = lerp_angle(kharkiv.heading, facing, clampf(delta * GD.turn_rate("capital"), 0.0, 1.0))   # half rate (v0.9.126)
	kharkiv.queue_redraw()


## Loose formation flying. Each escort flies itself to its slot instead of being pinned
## to it: it sees the slot move a beat late (its own reaction time), steers there with
## its own speed and acceleration, turns at its class's own rate, and once inside its
## slot's bubble it stops correcting and just drifts with the fleet, swaying a little.
## Small ships snap into place; big ones lumber after and catch up.
const FORM_TURN := {"corvette": 4.0, "frigate": 3.5, "destroyer": 2.5, "cruiser": 2.5, "carrier": 1.0, "battleship": 1.0, "colony": 2.0}   # large hulls turn slower (were 1.6, v0.9.126)
const FORM_ACCEL := [4.0, 3.0, 2.2]    # x top speed per second, by size (small, medium, large)
const FORM_BUBBLE := [1.5, 2.0, 2.5]   # units: inside this, a ship is in its slot


## Every frame, moving or not, the ships in formation fly themselves towards their slots.
func _fly_escorts(delta: float) -> void:
	if kharkiv == null or delta <= 0.0 or warp_state == Warp.TRANSIT:
		return
	# How the flagship is actually moving (steering, coasting or drifting onto a warp arrow).
	var moved := kharkiv.position - _k_prev if _k_prev != Vector2.INF else Vector2.ZERO
	_k_prev = kharkiv.position
	_k_vel = moved / delta if moved.length() < 20.0 * GD.UNIT else Vector2.ZERO   # a jump (warp) isn't speed
	for i in fleet.size():
		var ship: ShipScript = fleet[i]
		if not is_instance_valid(ship) or not ship.driven or ship == kharkiv:
			continue
		_fly_in_formation(ship, _slot_of(i), kharkiv.heading, delta)


func _form_size(ship: ShipScript) -> int:
	var info: Dictionary = GD.SHIPS.get(ship.type_id, {})
	return int(info.get("size", 0))


func _form_bubble(ship: ShipScript) -> float:
	return float(FORM_BUBBLE[_form_size(ship)]) * GD.UNIT


func _fly_in_formation(ship: ShipScript, slot: Vector2, facing: float, delta: float) -> void:
	var id := ship.get_instance_id()
	var st: Dictionary = _form_state.get(id, {})
	# New to the formation, or jumped (a warp): start settled in the slot.
	if st.is_empty() or ship.position.distance_to(slot) > 25.0 * GD.UNIT:
		st = {"vel": _k_vel, "seen": slot, "delay": randf_range(0.1, 0.3), "phase": randf() * TAU}
		_form_state[id] = st
		ship.position = slot if ship.position.distance_to(slot) > 25.0 * GD.UNIT else ship.position
	var phase := float(st["phase"])
	# A gentle sway round the slot so nobody sits dead still.
	var sway := Vector2(cos(run_time * 0.6 + phase) * 0.2, sin(run_time * 0.9 + phase * 1.3) * 0.3).rotated(fleet_heading) * GD.UNIT
	var seen: Vector2 = st["seen"]
	seen = seen.lerp(slot + sway, 1.0 - exp(-delta / float(st["delay"])))
	st["seen"] = seen
	var to := seen - ship.position
	var dist := to.length()
	var bubble := _form_bubble(ship)
	var top := ship.speed_units * GD.UNIT * (GD.BOOST_MULT if boosting else 1.0)
	# A soft drift towards the (swaying) slot, and a firm pull back once it has
	# wandered off the middle of its bubble.
	var desired: Vector2 = _k_vel + to * 0.6
	if dist > bubble * 0.35:
		desired += to / dist * (dist - bubble * 0.35) * 2.2
	# Far behind: up to 25% over top speed to catch up.
	var catch_up := 1.0 + 0.25 * clampf((dist - bubble) / (bubble * 2.0), 0.0, 1.0)
	desired = desired.limit_length(maxf(top * catch_up, _k_vel.length() * 1.05))
	var vel: Vector2 = st["vel"]
	vel = vel.move_toward(desired, top * float(FORM_ACCEL[_form_size(ship)]) * delta)
	st["vel"] = vel
	ship.position += vel * delta
	# Turn at the class's own rate: towards where it's going, or the fleet's facing at rest.
	var want := facing
	if vel.length() > 0.6 * GD.UNIT:
		want = vel.angle()
	var rate := float(FORM_TURN.get(ship.type_id, 2.5))
	var diff := wrapf(want - ship.heading, -PI, PI)
	ship.heading += clampf(diff, -rate * delta, rate * delta)
	ship.queue_redraw()


# --- warp ----------------------------------------------------------------------

func _nearest_exit() -> Dictionary:
	var sys: Dictionary = systems[fleet_system]
	var exits: Array = sys["exits"]
	for e in exits:
		var e_pos: Vector2 = e["pos"]
		if (kharkiv.position / GD.UNIT).distance_to(e_pos) <= GD.WARP_TRIGGER:
			return e
	return {}


func _update_warp(delta: float) -> void:
	if kharkiv == null:
		return
	match warp_state:
		Warp.NONE:
			var exit := _nearest_exit()
			if not exit.is_empty():
				warp_state = Warp.CHARGING
				SfxPlayer.play("warp_charge", kharkiv, -7.0, 0.0)
				warp_time = 0.0
				warp_exit = exit
				hud.show_toast("Charging warp to %s..." % String(exit["name"]), (GD.WARP_GRACE + GD.WARP_LOCK) * GD.warp_charge_mult)
		Warp.CHARGING:
			if _nearest_exit().is_empty():
				warp_state = Warp.NONE
				warp_time = 0.0
				hud.show_toast("Warp cancelled", 1.5)
			else:
				# With no input, the fleet drifts onto the arrow.
				var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
				if not fleet_mode or dir == Vector2.ZERO or autopilot:
					var target: Vector2 = warp_exit["pos"]
					var to := target * GD.UNIT - kharkiv.position
					var step := kharkiv.speed_units * GD.UNIT * delta
					if to.length() > step:
						_move_fleet(kharkiv.position + to.normalized() * step, to.angle(), delta)
				warp_time += delta
				if warp_time >= GD.WARP_GRACE * GD.warp_charge_mult:
					warp_state = Warp.LOCKED
					fleet_velocity = Vector2.ZERO
					hud.show_toast("Locked in. Warping to %s" % String(warp_exit["name"]), GD.WARP_LOCK * GD.warp_charge_mult + 0.5)
		Warp.LOCKED:
			warp_time += delta
			# Fade into the jump for the last moment of the lock (Fleet Mode only).
			if fleet_mode and not _fade_started and warp_time >= (GD.WARP_GRACE + GD.WARP_LOCK) * GD.warp_charge_mult - 0.3:
				_fade_started = true
				hud.warp_fade(0.3, 0.45)
			if warp_time >= (GD.WARP_GRACE + GD.WARP_LOCK) * GD.warp_charge_mult:
				_fade_started = false
				_start_transit()
		Warp.TRANSIT:
			warp_time += delta
			_update_transit()
			if warp_time >= GD.WARP_TRANSIT * GD.warp_time_mult:
				_arrive()
	overlay.warp_locked = warp_state == Warp.LOCKED
	var fleet_view: Node2D = system_views[fleet_system]
	if (warp_state == Warp.CHARGING or warp_state == Warp.LOCKED) and not warp_exit.is_empty():
		var exit_pos: Vector2 = warp_exit["pos"]
		fleet_view.set("wormhole_pos", exit_pos * GD.UNIT)
		fleet_view.set("wormhole_strength", clampf(warp_time / 1.2, 0.0, 1.0))
	else:
		fleet_view.set("wormhole_strength", 0.0)
	if warp_state == Warp.CHARGING or warp_state == Warp.LOCKED:
		overlay.warp_progress = clampf(warp_time / ((GD.WARP_GRACE + GD.WARP_LOCK) * GD.warp_charge_mult), 0.0, 1.0)
	else:
		overlay.warp_progress = 0.0


func _start_transit() -> void:
	SfxPlayer.ui("warp_jump", -6.1)   # 30% quieter than before (-3 dB)
	warp_state = Warp.TRANSIT
	warp_time = 0.0
	fleet_velocity = Vector2.ZERO
	_escorts_out = false
	returning.clear()
	for ship in fleet:
		ship.escorting = false
		ship.driven = true
		ship.velocity = Vector2.ZERO
		ship.visible = false
	overlay.visible = false
	_gather_pursuers()
	galaxy_view.show_fleet = true
	_transit_half = 1
	_transit_zoom = camera.zoom
	# Only ride the jump if you were in Fleet Mode when it began; otherwise the fleet
	# jumps in the background and you keep your view.
	warp_watch = fleet_mode
	if warp_watch:
		_watch_transit()
	_update_transit()


## Riding the jump: no galaxy map and no zoom; the camera stays on the fleet as it flies
## out along the course line, through a screen-wide warp, and in along the next system's.
func _watch_transit() -> void:
	hud.hide_planet()
	if _transit_zoom == Vector2.ZERO:
		_transit_zoom = camera.zoom
	var target_sys: Dictionary = systems[int(warp_exit["to"])]
	hud.show_location("IN WARP TO %s" % String(target_sys["name"]).to_upper())


## Where the fleet is at progress t (0..1) of a jump: [view index, centre, heading].
func _transit_point(t: float) -> Array:
	var from_index := fleet_system
	var to_index: int = warp_exit["to"]
	if t < 0.5:
		var e_pos: Vector2 = warp_exit["pos"]
		var e_dir: Vector2 = warp_exit["dir"]
		var k := t / 0.5
		var along := WARP_FLY * k * k * k   # ease in: pulled faster and faster
		return [from_index, (e_pos + e_dir * along) * GD.UNIT, e_dir.angle()]
	var entry := Vector2.ZERO
	var inward := Vector2.RIGHT
	for e in Array(systems[to_index]["exits"]):
		if int(e["to"]) == from_index:
			entry = e["pos"]
			inward = -Vector2(e["dir"])
	var arrival := entry + inward * (GD.WARP_TRIGGER + 6.0)
	var k2 := (t - 0.5) / 0.5
	var left := 1.0 - k2
	var back := WARP_FLY * left * left * left   # ease out: braking into the system
	return [to_index, (arrival - inward * back) * GD.UNIT, inward.angle()]


func _update_transit() -> void:
	var total := GD.WARP_TRANSIT * GD.warp_time_mult
	var t := clampf(warp_time / total, 0.0, 1.0)
	# The background marker on the galaxy map (when you aren't riding along).
	var from_sys: Dictionary = systems[fleet_system]
	var to_sys: Dictionary = systems[int(warp_exit["to"])]
	var ga: Vector2 = Vector2(from_sys["galaxy_pos"]) * GalaxyView.SCALE
	var gb: Vector2 = Vector2(to_sys["galaxy_pos"]) * GalaxyView.SCALE
	galaxy_view.fleet_pos = ga.lerp(gb, smoothstep(0.0, 1.0, t))
	galaxy_view.fleet_angle = (gb - ga).angle()
	galaxy_view.queue_redraw()
	if not warp_watch:
		hyperspace.intensity = 0.0
		return
	var half := 1 if t < 0.5 else 2
	var point := _transit_point(t)
	var view_index: int = point[0]
	var centre: Vector2 = point[1]
	var heading: float = point[2]
	var view: Node2D = system_views[view_index]
	# The flash peaks right as the fleet crosses into the next system.
	if not _fade_started and warp_time >= total * 0.5 - 0.22:
		_fade_started = true
		hud.warp_fade(0.22, 0.4)
	if half != _transit_half or current != view_index or in_galaxy:
		_transit_half = half
		_open_system(view_index)
		camera.zoom = _transit_zoom
		_update_fog()
		var to_name := String(to_sys["name"]).to_upper()
		hud.show_location("IN WARP TO %s" % to_name)
	fleet_heading = heading
	for i in fleet.size():
		var ship: ShipScript = fleet[i]
		if not is_instance_valid(ship):
			continue
		if ship.get_parent() != view:
			ship.reparent(view, false)
		var offset: Vector2 = fleet_offsets[i]
		ship.position = centre + offset.rotated(heading)
		ship.heading = heading
		ship.visible = true
		ship.queue_redraw()
	camera.position = centre
	# Screen-wide warp: streaks build as the fleet is pulled away, peak at the crossing,
	# and fade as it brakes in.
	hyperspace.intensity = clampf(sin(t * PI) * 1.25, 0.0, 1.0)


func _arrive() -> void:
	var from_index := fleet_system
	var to_index: int = warp_exit["to"]
	var target_sys: Dictionary = systems[to_index]
	# Arrive at the warp point in the new system that leads back where we came from.
	var entry := Vector2.ZERO
	var inward := Vector2.ZERO
	var exits: Array = target_sys["exits"]
	for e in exits:
		if e["to"] == from_index:
			var e_pos: Vector2 = e["pos"]
			var e_dir: Vector2 = e["dir"]
			entry = e_pos
			inward = -e_dir
	var arrival := (entry + inward * (GD.WARP_TRIGGER + 6.0)) * GD.UNIT
	galaxy_view.show_fleet = false
	hyperspace.intensity = 0.0
	var target_view: Node2D = system_views[to_index]
	fleet_heading = inward.angle()
	for i in fleet.size():
		var ship: ShipScript = fleet[i]
		var offset: Vector2 = fleet_offsets[i]
		if ship.get_parent() != target_view:
			ship.reparent(target_view, false)
		ship.position = arrival + offset.rotated(fleet_heading)
		ship.heading = inward.angle()
		ship.visible = true
		ship.queue_redraw()
	overlay.reparent(target_view, false)
	overlay.position = arrival
	overlay.visible = true
	overlay.flash()
	if GD.hot_exit:
		_hot_exit(target_view, arrival)
	fleet_system = to_index
	if String(target_sys.get("type", "")) == "asteroid_field":
		# Lift the fog straight away and let the player take in the rocks before
		# Xander freezes the game to talk about them.
		call_deferred("_update_fog")
		get_tree().create_timer(1.5, false).timeout.connect(_teach_fields)
	if to_index == 2 and not rebels_alerted:
		rebels_alerted = true
		call_deferred("_rebels_intercept")
	# Haven: Xander warns about the Rebels lying in its rocks (only there, v0.9.192).
	if String(target_sys["name"]) == "Haven" and hud.xander != null:
		hud.xander.call("say", "rebel_hideouts", "Careful, Commander: Rebels hide in the rocks here. Fly too close and they'll jump you!", "", true)
	warp_state = Warp.NONE
	warp_time = 0.0
	warp_exit = {}
	_fade_started = false
	_transit_half = 0
	if warp_watch:
		_open_system(to_index)   # names the system in the location bar
		camera.position = arrival
		if _transit_zoom != Vector2.ZERO:
			camera.zoom = _transit_zoom   # no zoom change on arrival (v0.9.204)
		hud.show_toast("Arrived at %s" % String(target_sys["name"]), 2.0)
	else:
		if in_galaxy:
			galaxy_view.queue_redraw()
		hud.notify("Fleet arrived at %s." % String(target_sys["name"]), to_index, arrival)
	_transit_zoom = Vector2.ZERO
	warp_watch = false
	if not pursuers.is_empty():
		get_tree().create_timer(2.5, false).timeout.connect(_pursuers_arrive.bind(to_index, entry, inward))


# --- views ---------------------------------------------------------------------

func _open_system(index: int) -> void:
	current = index
	in_galaxy = false
	galaxy_view.visible = false
	for i in system_views.size():
		var view: Node2D = system_views[i]
		view.visible = i == index
	camera.position = Vector2.ZERO
	if index == fleet_system and kharkiv != null:
		camera.position = kharkiv.position
	camera.zoom = Vector2(0.5, 0.5)
	get_tree().call_group("ships", "queue_redraw")
	var sys: Dictionary = systems[index]
	var system_kind := "ASTEROID FIELD" if String(sys.get("type", "")) == "asteroid_field" else "SYSTEM"
	hud.show_location("%s: %s" % [system_kind, String(sys["name"]).to_upper()])


func _open_galaxy() -> void:
	in_galaxy = true
	hud.hide_planet()
	for view in system_views:
		view.visible = false
	galaxy_view.current = fleet_system
	galaxy_view.flagship_system = fleet_system if kharkiv != null else -1
	galaxy_view.visible = true
	galaxy_view.queue_redraw()
	camera.position = galaxy_view.centre()
	camera.zoom = Vector2(1, 1)
	hud.show_location("GALAXY VIEW")


# --- planets and build menu ----------------------------------------------------------

func _on_planet_clicked(planet: Dictionary) -> void:
	hud.show_planet(planet, _planet_income(planet))


## What a planet earns by itself per tick: capital income plus its buildings.
func _planet_income(planet: Dictionary, _count_gas: bool = false) -> Dictionary:
	if planet["owner"] != GD.Faction.UNE:
		return {}
	var income := {"credits": 0, "alloys": 0, "tech": 0, "gas": 0}
	if planet["kind"] == "earth":
		income["credits"] += 1   # the capital's own +$1 (its free +1 Alloy was removed in v0.9.97)
	# Pops at work: $1 per 2 pops on terran worlds, 1 Alloy per 2 on desert
	# worlds, 1 Gas per 3 on ice worlds.
	var made := GD.pop_yield(planet)
	if not made.is_empty():
		income[String(made["resource"])] += int(made["amount"])
	var buildings: Array = planet["buildings"]
	var city_value := _count_in(tech_cards, "Trade Networks")   # Cities pay only with Trade Networks
	for b in buildings:
		match String(b):
			"City":
				income["credits"] += city_value
			"Mining Corp":
				income["alloys"] += 15   # buffed for the x5 economy (v0.9.239)
			"Gas Refineries":
				income["gas"] += 1
			"Customs Office":
				income["credits"] += _count_une_starbases_only()
	return income




# --- economy -------------------------------------------------------------------

## Every source of income this tick: where it is and what it gives.
## Planet income ("immediate") arrives at once; asteroid and gas giant income
## collected by a Starbase is loaded onto a Hauler ("haul").
## With roll_gas false, rolls are skipped (for the "+per tick" preview).
func _income_sources(roll_gas: bool) -> Array:
	var sources: Array = []
	for s in systems:
		var index: int = s["index"]
		var planets: Array = s["planets"]
		for p in planets:
			var own := _planet_income(p, roll_gas and tick_count % 3 == 0)
			if not own.is_empty():
				sources.append({"system": index, "pos": p["pos"], "haul": false, "planet": true, "alloys": int(own.get("alloys", 0)), "gas": int(own.get("gas", 0)), "credits": int(own.get("credits", 0)), "tech": int(own.get("tech", 0))})
		var structures: Array = s["structures"]
		var view: Node2D = system_views[index]
		for st in structures:
			if st["type"] != "starbase" or st["faction"] != GD.Faction.UNE:
				continue
			var sb_pos: Vector2 = st["pos"]
			var orbit := GD.STARBASE_ORBIT * GD.orbit_multiplier
			var haul := {"system": index, "pos": sb_pos, "haul": true, "alloys": 0, "gas": 0, "credits": 0, "tech": 0}
			var mining := false
			for rock in view.call("asteroids"):
				var kind := String(rock.get("kind"))
				if not (rock.get("arrived") == true) or (kind != "rock" and kind != "gas"):
					continue
				var rock_pos: Vector2 = rock.position / GD.UNIT
				if rock_pos.distance_to(sb_pos) > orbit:
					continue
				haul["alloys"] += int(rock.get("yield_alloys"))
				var gas_yield := int(rock.get("yield_gas"))
				if gas_yield > 0 and roll_gas and randf() < 0.1:
					gas_yield += 1
				haul["gas"] += gas_yield
				if int(rock.get("yield_alloys")) > 0:
					mining = true
			if mining and tech_cards.has("Deep Core Mining"):
				haul["alloys"] += _count_in(tech_cards, "Deep Core Mining") * 10   # buffed (v0.9.239)
			var giants: Array = s["gas_giants"]
			var siphoned: Array = []
			for g in giants:
				var g_pos: Vector2 = g["pos"]
				# The orbit only has to touch the giant's edge.
				if g_pos.distance_to(sb_pos) <= orbit + float(g.get("radius", 0.0)):
					var gas := 1 + _count_in(tech_cards, "Gas Giant Siphons")
					haul["gas"] += gas
					siphoned.append({"pos": g_pos, "gas": gas})
			haul["giants"] = siphoned
			sources.append(haul)
			# A planet in the orbit gives $1 straight away.
			for p in planets:
				var p_pos: Vector2 = p["pos"]
				if p_pos.distance_to(sb_pos) <= orbit:
					sources.append({"system": index, "pos": sb_pos, "haul": false, "alloys": 0, "gas": 0, "credits": 1, "tech": 0})
	return sources


func _income_totals(sources: Array) -> Dictionary:
	var totals := {"alloys": 0, "gas": 0, "credits": 0}
	for src in sources:
		for key in totals.keys():
			totals[key] += int(src[key])
	return totals


func _economy_tick() -> void:
	tick_count += 1
	var sources := _income_sources(true)
	for src in sources:
		if bool(src["haul"]):
			for g in Array(src.get("giants", [])):
				_spawn_text(int(src["system"]), g["pos"], ["+%d GAS" % int(g["gas"])])
			_load_haul(src)
			continue
		for key in amounts.keys():
			amounts[key] += int(src[key])
		alloys_mined += int(src["alloys"])
		_show_gain(src)
		if bool(src.get("planet", false)):
			_gather_sound(int(src["system"]), Vector2(src["pos"]) * GD.UNIT)
	_pay_upkeep()
	_grow_population()
	if sons != null:
		sons.day()
	_refresh_hud()
	var open_planet := hud.current_planet()
	if not open_planet.is_empty():
		hud.refresh_planet(_planet_income(open_planet))


## Base growth: 1 per tick on owned planets; a new pop every 10.
func _grow_population() -> void:
	for s in systems:
		var index: int = s["index"]
		var planets: Array = s["planets"]
		for p in planets:
			if p["owner"] != GD.Faction.UNE or int(p["pops"]) <= 0:
				continue
			if int(p["pops"]) >= int(p["capacity"]):
				continue
			var buildings: Array = p["buildings"]
			var rate := 1.5 if buildings.has("Cryo Medicals") else 1.0
			p["growth_progress"] = float(p["growth_progress"]) + rate
			var needed := GD.growth_needed(int(p["pops"]))
			if float(p["growth_progress"]) >= needed:
				p["growth_progress"] = float(p["growth_progress"]) - needed
				p["pops"] = int(p["pops"]) + 1
				_spawn_text(index, p["pos"], ["+1 POP"])
				# Rewards come only at new highs: regrowing to an old threshold pays nothing.
				# Every 2nd pop on terran worlds, every 3rd on desert and ice worlds.
				if int(p["pops"]) % GD.reward_every(p) == 0 and int(p["pops"]) > int(p.get("reward_peak", 0)):
					p["reward_peak"] = int(p["pops"])
					# A reward bubble waits over the planet until you click it.
					p["pending_cards"] = int(p.get("pending_cards", 0)) + 1
					SfxPlayer.ui("reward", -2.0)
					hud.notify("%s has a Growth Reward. Fly your Flagship into its gold bubble (click here to fly there)." % String(p["name"]), index, Vector2(p["pos"]) * GD.UNIT, "growth:%d:%s" % [index, String(p["name"])])
	var total := 0
	for s in systems:
		for p in Array(s["planets"]):
			if p["owner"] == GD.Faction.UNE:
				total += int(p["pops"])
	peak_pop = maxi(peak_pop, total)


func _show_gain(src: Dictionary) -> void:
	var lines: Array = []
	if int(src["alloys"]) > 0:
		lines.append("+%d ALLOYS" % int(src["alloys"]))
	if int(src["gas"]) > 0:
		lines.append("+%d GAS" % int(src["gas"]))
	if int(src["credits"]) > 0:
		lines.append("+¢%d" % int(src["credits"]))
	if int(src["tech"]) > 0:
		lines.append("+%d TECH" % int(src["tech"]))
	if not lines.is_empty():
		_spawn_text(int(src["system"]), src["pos"], lines)


var _texts_this_frame := {}   # "system:x:y" -> FloatText spawned this frame
var _texts_frame := -1


func _spawn_text(system_index: int, pos_units: Vector2, lines: Array) -> void:
	# Texts from the same spot in the same moment (a planet's income and its "+1 POP")
	# join one stack instead of drawing over each other.
	var frame := Engine.get_process_frames()
	if frame != _texts_frame:
		_texts_frame = frame
		_texts_this_frame.clear()
	var key := "%d:%d:%d" % [system_index, roundi(pos_units.x), roundi(pos_units.y)]
	var same: Variant = _texts_this_frame.get(key)
	if same != null and is_instance_valid(same):
		(same as FloatText).lines.append_array(lines)
		return
	var view: Node2D = system_views[system_index]
	var text := FloatText.new()
	view.add_child(text)
	text.setup(pos_units * GD.UNIT, lines.duplicate())
	_texts_this_frame[key] = text


func _count_une_starbases() -> int:
	var count := 0
	for s in systems:
		var structures: Array = s["structures"]
		for st in structures:
			# Space Stations: Starbases, Shipyards and MAG Cannons all count.
			if (st["type"] == "starbase" or st["type"] == "shipyard" or st["type"] == "mag") and st["faction"] == GD.Faction.UNE:
				count += 1
	return count


func _refresh_hud() -> void:
	var sources := _income_sources(false)
	var income := _income_totals(sources)
	# Each system's own daily take, for the zoomed-out map labels.
	var per := {}
	for src in sources:
		var i := int(src["system"])
		if not per.has(i):
			per[i] = {"alloys": 0, "gas": 0, "credits": 0}
		for key in ["alloys", "gas", "credits"]:
			per[i][key] = int(per[i][key]) + int(src[key])
	GD.system_dailies = per
	# Fleet upkeep (v0.9.229): the top bar shows Alloy income after upkeep.
	income["alloys"] = int(income["alloys"]) - _fleet_upkeep()
	_count_owned()
	hud.set_ship_prices()
	hud.show_resources(amounts, income, _count_une_starbases(), starbase_limit)
	hud.show_build_queue(_queue_counts())


## How many of each ship type are queued across all your Shipyards.
## Fleet upkeep (v0.9.230): every warship you own costs whole Alloys each day
## (Corvette, Frigate, Destroyer 1; Cruiser, Carrier 2; Battleship 3). The Kharkiv,
## fighters and civilian ships are free.
func _fleet_upkeep() -> int:
	var total := 0
	for node in get_tree().get_nodes_in_group("ships"):
		var ship := node as ShipScript
		if ship == null or not ship.alive or ship.faction != GD.Faction.UNE or not GD.SHIPS.has(ship.type_id):
			continue
		total += GD.ship_upkeep(ship.type_id)
	return total


func _pay_upkeep() -> void:
	var pay := _fleet_upkeep()
	if pay <= 0:
		return
	amounts["alloys"] = maxi(0, int(amounts["alloys"]) - pay)   # can't go below zero


## How many of each ship type you own or have queued: ship prices scale with it.
## After losses the count eases down slowly (one ship's worth every 45 s), so losing
## ships doesn't make the next ones cheap straight away (v0.9.228).
var _price_memory := {}   # type -> [count, run_time]


func _count_owned() -> void:
	var owned := _queue_counts()
	for node in get_tree().get_nodes_in_group("ships"):
		var ship := node as ShipScript
		if ship == null or not ship.alive or ship.faction != GD.Faction.UNE:
			continue
		owned[ship.type_id] = int(owned.get(ship.type_id, 0)) + 1
	var eased := {}
	var types := owned.keys()
	for t in _price_memory.keys():
		if not types.has(t):
			types.append(t)
	for t in types:
		var now := float(owned.get(t, 0))
		var mem: Array = _price_memory.get(t, [0.0, run_time])
		var remembered := float(mem[0]) - (run_time - float(mem[1])) / GD.SHIP_PRICE_EASE
		var count := maxf(now, remembered)
		_price_memory[t] = [count, run_time]
		if count > 0.0:
			eased[t] = count
	GD.ship_owned = eased


func _queue_counts() -> Dictionary:
	var counts := {}
	for s in systems:
		for st in Array(s["structures"]):
			if st["type"] != "shipyard" or int(st["faction"]) != GD.Faction.UNE:
				continue
			for item in Array(st.get("queue", [])):
				var t := String(item["type"])
				counts[t] = int(counts.get(t, 0)) + 1
	return counts


## Right-clicking a ship's build button: the last one of that type queued comes back
## out (a waiting one if there is one, otherwise one being built), with a full refund.
func _on_unqueue_requested(type_id: String) -> void:
	var best_queue: Array = []
	var best_index := -1
	var best_waiting := false
	for s in systems:
		for st in Array(s["structures"]):
			if st["type"] != "shipyard" or int(st["faction"]) != GD.Faction.UNE:
				continue
			var queue: Array = st.get("queue", [])
			for i in range(queue.size() - 1, -1, -1):
				if String(queue[i]["type"]) != type_id:
					continue
				var waiting := i >= GD.shipyard_lines
				if best_index < 0 or (waiting and not best_waiting):
					best_queue = queue
					best_index = i
					best_waiting = waiting
				break
	if best_index < 0:
		SfxPlayer.ui("deny", -6.0)
		return
	var removed: Dictionary = best_queue[best_index]
	best_queue.remove_at(best_index)
	var stats := GD.ship_stats(type_id)
	# Refund what was actually paid (prices scale, v0.9.219).
	var back_alloys := int(removed.get("paid_alloys", stats["cost_alloys"]))
	var back_gas := int(removed.get("paid_gas", stats["cost_gas"]))
	amounts["alloys"] = int(amounts["alloys"]) + back_alloys
	amounts["gas"] = int(amounts["gas"]) + back_gas
	SfxPlayer.ui("click")
	hud.show_toast("%s removed from the queue: refunded %s." % [String(GD.SHIPS[type_id]["kind"]), _cost_text(back_alloys, back_gas)], 2.0)
	_refresh_hud()


# --- XP, focus fire --------------------------------------------------------------

func _on_enemy_destroyed(ship: Node2D) -> void:
	enemies_destroyed += 1
	var killer = ship.get("_attacker")
	if killer != null and is_instance_valid(killer) and killer is ShipScript:
		var credited: ShipScript = killer
		if credited.faction == GD.Faction.UNE:
			credited.kills += 1
			kills_by_name[credited.ship_name] = credited.kills
	var tier: int = GD.SHIPS[String(ship.get("type_id"))]["tier"]
	if tier <= 0:
		return
	xp += tier
	hud.xp_popup(tier)
	var view := ship.get_parent() as Node2D
	var index := system_views.find(view)
	if index >= 0:
		if Settings.xp_popups:   # off by default (Settings)
			_spawn_text(index, ship.position / GD.UNIT, ["+%d XP" % tier])
	while xp >= xp_need:
		xp -= xp_need
		xp_need *= 2
		fleet_level += 1
		_queue_card({"type": "fleet", "reason": "Fleet XP bar full."})
	hud.show_xp(xp, xp_need, fleet_level)


func _reticle_texture() -> ImageTexture:
	var size := 32
	var img := Image.create_empty(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var c := Vector2(15.5, 15.5)
	var col := Color("e5484d")
	for y in size:
		for x in size:
			var d := Vector2(x, y).distance_to(c)
			var on_ring := absf(d - 11.0) < 1.2
			var on_cross := (absi(x - 15) <= 0 or absi(x - 16) <= 0 or absi(y - 15) <= 0 or absi(y - 16) <= 0) and d > 4.0 and d < 15.0 and (absi(x - 15) <= 1 or absi(y - 15) <= 1)
			if on_ring or on_cross:
				img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)


func _focus_at(world: Vector2) -> void:
	# Anything that isn't ours can be focused: ships, bases and asteroids of every kind.
	var view: Node2D = system_views[fleet_system]
	var best: Node2D = null
	var best_d := 6.0 * GD.UNIT
	var pool: Array = get_tree().get_nodes_in_group("targets")
	pool.append_array(view.call("asteroids"))   # rocks aren't "targets" any more (v0.9.241)
	for t in pool:
		var node := t as Node2D
		if node == null or node.get_parent() != view or not (node.get("alive") == true):
			continue
		if int(node.get("faction")) == GD.Faction.UNE:
			continue
		var d := world.distance_to(node.position)
		if node.has_method("radius_px"):
			d -= float(node.call("radius_px"))
		if d < best_d:
			best_d = d
			best = node
	_set_focus(best)


func _set_focus(target: Node2D) -> void:
	# (Xander's plain "shoot the asteroid" line is gone, v0.9.167: his animated ASTEROIDS
	# lesson covers it when a rock worth mining is broken.)
	for ship in fleet:
		if is_instance_valid(ship):
			ship.focus = target
	var view: Node2D = system_views[fleet_system]
	view.set("focus_node", target)


# --- cards ------------------------------------------------------------------------

func _on_tech_base_destroyed(system_index: int, pos_px: Vector2) -> void:
	# The reward drops as a pickup; fly the fleet to it to collect it.
	var pickup := Pickup.new()
	var view: Node2D = system_views[system_index]
	view.add_child(pickup)
	pickup.setup(pos_px, "secret" if randf() < 0.1 else "tech", "Good")
	pickups.append(pickup)


func _queue_card(entry: Dictionary) -> void:
	card_queue.append(entry)
	call_deferred("_show_next_card")


func _count_in(list: Array, card_name: String) -> int:
	var n := 0
	for item in list:
		if String(item) == card_name:
			n += 1
	return n


## Can this card be offered? Respects "limit", "requires" and the Kharkiv's 4 weapon types.
func _card_ok(card: Dictionary, owned: Array) -> bool:
	# Cards for systems that aren't in the game yet (missiles, drones) stay out of the pool.
	if bool(card.get("disabled", false)):
		return false
	var have := _count_in(owned, String(card["name"]))
	if card.has("limit") and int(card["limit"]) > 0 and have >= int(card["limit"]):
		return false   # "limit": 0 means no limit
	if card.has("requires") and _count_in(owned, String(card["requires"])) == 0:
		return false
	if bool(card.get("weapon", false)) and have == 0 and _weapon_types() >= GD.KHARKIV_WEAPON_TYPES:
		return false
	if String(card["name"]) == "Mine Layer" and GD.mine_cap >= GD.MINE_CAP_MAX:
		return false
	return true


## Different Kharkiv weapon cards owned (Fleet cards marked "weapon").
func _weapon_types() -> int:
	var n := 0
	for card in GD.FLEET_CARDS:
		if bool(card.get("weapon", false)) and fleet_cards.has(String(card["name"])):
			n += 1
	return n


func _pick_three(pool: Array, owned: Array, rarity: String = "Good", how_many: int = 3) -> Array:
	var eligible: Array = []
	for card in pool:
		if _card_ok(card, owned):
			eligible.append(card)
	# Cards marked "early" (Shipwright Guild) come up more often in the opening minutes:
	# 4x as likely at the start, fading to normal by 10:00 (v0.9.226).
	var early_weight := lerpf(4.0, 1.0, clampf(run_time / 600.0, 0.0, 1.0))
	var shuffled: Array = []
	var bag := eligible.duplicate()
	while not bag.is_empty():
		var total := 0.0
		for c in bag:
			total += early_weight if bool((c as Dictionary).get("early", false)) else 1.0
		var roll := randf() * total
		var pick := bag.size() - 1
		for j in bag.size():
			roll -= early_weight if bool((bag[j] as Dictionary).get("early", false)) else 1.0
			if roll <= 0.0:
				pick = j
				break
		shuffled.append(bag[pick])
		bag.remove_at(pick)
	var choice: Array = []
	for card in shuffled:
		if choice.size() >= how_many:
			break
		var c: Dictionary = (card as Dictionary).duplicate()
		c["count"] = _count_in(owned, String(c["name"]))
		c["rarity"] = rarity
		choice.append(c)
	return choice


func _show_next_card() -> void:
	if not card_open.is_empty() or card_queue.is_empty() or shop_dealer != null:
		return
	hud.redraw_cost = redraw_cost
	hud.redraw_ok = int(amounts["credits"]) >= redraw_cost
	var entry: Dictionary = card_queue.pop_front()
	match String(entry["type"]):
		"planet":
			var p: Dictionary = entry["planet"]
			var buildings: Array = p["buildings"]
			if buildings.size() >= 6:
				hud.show_toast("%s is full: all 6 building slots used." % String(p["name"]), 3.0)
				call_deferred("_show_next_card")
				return
			var pool: Array = []
			for base_card in GD.PLANET_CARDS:
				var card: Dictionary = base_card
				var limit := int(card["limit"])
				if String(card["name"]) == "City" and tech_cards.has("Urban Sprawl"):
					limit = 0   # Urban Sprawl: as many Cities as there are slots
					card = card.duplicate()
					card["limit"] = 0
				if limit > 0 and _count_in(buildings, String(card["name"])) >= limit:
					continue
				# Mini MAG Batteries arm every Starbase at once, so the 3-gun cap is for the
				# whole empire, not per planet: once all 3 are fitted it stops being offered
				# (v0.9.222; it used to keep coming up and do nothing).
				if String(card["name"]) == "Mini MAG Batteries" and GD.starbase_mini_mags >= 3:
					continue
				pool.append(card)
			var choice := _pick_three(pool, buildings)
			card_open = entry
			get_tree().paused = true
			var names: Array = []
			for b in buildings:
				names.append(String(b))
			var side := [
				String(p["name"]).to_upper(),
				"Grew to %d pops (capacity %d)" % [int(p["pops"]), int(p["capacity"])],
				"Buildings %d / 6" % buildings.size(),
				", ".join(PackedStringArray(names)) if not names.is_empty() else "No buildings yet",
			]
			hud.fly_target = _screen_pos(int(entry["system"]), Vector2(p["pos"]) * GD.UNIT)
			hud.show_card_choice("GROWTH REWARD · %s" % String(p["name"]).to_upper(), "Pick a building for this planet.", choice, Color("b89a4a"), side, p)
			# First Growth Reward: Xander explains it right there in the card window.
			if hud.xander != null and bool(hud.xander.call("would_teach", "lesson_growth")):
				hud.add_card_advice("lesson_growth", "Your planet grew! Pick a building.",
					"Grow it more to get more picks.", "growth")
		"fleet":
			var choice := _pick_three(GD.FLEET_CARDS, fleet_cards, String(entry.get("rarity", "Good")))
			card_open = entry
			get_tree().paused = true
			hud.fly_target = _screen_pos(fleet_system, kharkiv.position if kharkiv != null else Vector2.ZERO)
			hud.show_card_choice("FLEET REWARD", String(entry["reason"]) + "  Pick a Fleet card.", choice, Color("a4504a"))
		"tech":
			var choice := _pick_three(GD.TECH_CARDS, tech_cards, "Good", 3 + _count_buildings("Tech Lab"))
			card_open = entry
			get_tree().paused = true
			hud.fly_target = _earth_screen_pos()
			hud.show_card_choice("TECH REWARD", String(entry["reason"]) + "  Pick a Tech card.", choice, Color("3e6690"))


## Redraw: pay, the price doubles, and the same reward deals three fresh cards.
var redraw_cost := GD.REDRAW_BASE


func _on_redraw() -> void:
	if card_open.is_empty() or int(amounts["credits"]) < redraw_cost:
		SfxPlayer.ui("deny", -6.0)
		return
	amounts["credits"] = int(amounts["credits"]) - redraw_cost
	redraw_cost *= 2
	var entry := card_open
	card_open = {}
	card_queue.push_front(entry)
	_refresh_hud()
	_show_next_card()


## The card fan: every Fleet and Tech card picked, and every building on your planets.
func _show_collection() -> void:
	if not card_open.is_empty() or shop_dealer != null or game_over:
		return
	var buildings := {}
	for s in systems:
		for p in Array(s["planets"]):
			if p["owner"] != GD.Faction.UNE:
				continue
			for b in Array(p["buildings"]):
				if String(b) != "":
					buildings[String(b)] = int(buildings.get(String(b), 0)) + 1
	hud.show_collection(fleet_cards, tech_cards, buildings)


func _on_card_picked(card_name: String) -> void:
	get_tree().paused = false
	var entry := card_open
	card_open = {}
	var applied := true
	match String(entry.get("type", "")):
		"planet":
			var p: Dictionary = entry["planet"]
			var buildings: Array = p["buildings"]
			buildings.append(card_name)
			applied = _apply_building(p, int(entry["system"]), card_name)
			var open_planet := hud.current_planet()
			if not open_planet.is_empty():
				hud.refresh_planet(_planet_income(open_planet))
		"fleet":
			var times := GD.rarity_mult(String(entry.get("rarity", "Good")))
			for i in times:
				fleet_cards.append(card_name)
				applied = _apply_fleet_card(card_name)
		"tech":
			tech_cards.append(card_name)
			applied = _apply_tech_card(card_name)
	_refresh_hud()
	# No toast after picking a card: the card flying in says enough.
	if not applied:
		push_warning("Card %s has no effect yet." % card_name)
	call_deferred("_show_next_card")


## Pop capacity each City adds to its planet.
const CITY_CAPACITY := 5   # was 6 (v0.9.125)


func _apply_building(p: Dictionary, system_index: int, building: String) -> bool:
	match building:
		"City":
			p["capacity"] = int(p["capacity"]) + CITY_CAPACITY
			return true
		"Tech Lab", "Mining Corp", "Gas Refineries", "Cryo Medicals":
			return true   # read every tick from the planet's building list
		"Logistics Hub":
			starbase_limit += 1
			return true
		"Fleet Academy":
			GD.damage_bonus += 1.0
			return true
		"Customs Office":
			return true   # read every tick from the planet's building list
		"Orbital Drydocks":
			GD.build_time_mult *= 0.85
			return true
		"Construction Yards":
			GD.construct_mult *= 1.25
			return true
		"Shipwright Guild":
			GD.construction_ships += 1
			return true
		"Repair Gantries":
			GD.shipyard_repair_mult = 1.5
			return true
		"Tractor Arrays":
			GD.orbit_multiplier *= 1.1
			return true
		"Bunker Foundry":
			_toughen_starbases(1.15)
			return true
		"Drone Docks":
			GD.starbase_repairs = true
			return true
		"Long-Range Batteries":
			GD.station_range_mult = 1.25
			return true
		"Mini MAG Batteries":
			GD.starbase_mini_mags = mini(GD.starbase_mini_mags + 1, 3)
			for view in system_views:
				view.call("arm_starbases")   # the ones you already have get the new gun now
			return true
		"Hangar Crews":
			GD.starbase_rebuild = 10.0
			return true
		"Hauler Depot":
			GD.hauler_speed_mult = 1.3
			return true
		"Colony Office":
			GD.colony_settle_mult *= 0.7
			GD.colony_discount += 2 * GD.ALLOY_SCALE
			return true
		"Trade Port":
			GD.trade_mult = 0.8   # dealer prices are worked out when the shop opens
			return true
		"Space Elevators":
			GD.shipyard_lines += 1
			return true
		"PD MAG":
			# A fortress on the planet's rim with a turning MAG barrel.
			var gun := PlanetGun.new()
			var view: Node2D = system_views[system_index]
			view.add_child(gun)
			var pos_units: Vector2 = p["pos"]
			var rim := pos_units + Vector2(0.62, -0.62) * float(p.get("radius", 9.0))
			gun.setup(rim * GD.UNIT, GD.Faction.UNE)
			gun.draw_base = true
			gun.set_meta("planet_name", String(p["name"]))   # falls with the planet
			gun.z_index = 1
			return true
	return false


func _apply_fleet_card(card_name: String) -> bool:
	match card_name:
		"Tightened Logistics":
			pass   # checked in _update_boost
		"Hardened Plating":
			GD.armor_mult *= 1.1
		"Reinforced Hulls":
			GD.hull_mult *= 1.15
		"Shield Emitters":
			GD.shield_bonus += 25.0
		"Overclocked Thrusters":
			GD.speed_mult *= 1.1
		"Rapid Loaders":
			GD.cooldown_mult *= 0.9
		"Efficient Shipyards":
			GD.build_time_mult *= 0.9
		"Sustained Fire":
			GD.gatling_extra_seconds = 0.5
		"Flak Retrofit":
			_bolt_on("corvette", "flak", 1)
		"Twin MAG Mount":
			_bolt_on("capital", "mag", 1)
		"Kharkiv Gatling":
			_bolt_on("capital", "gatling", 1)
		"Kharkiv PDC":
			_bolt_on("capital", "pdc", 1)
		"Kharkiv Flak":
			_bolt_on("capital", "flak", 1)
		"Kharkiv Mini MAG":
			_bolt_on("capital", "mini_mag", 1)
		"Kharkiv Torpedo Tube":
			_bolt_on("capital", "torpedo", 1)
		"Kharkiv Missile Pod":
			_bolt_on("capital", "swarm", 1)
		"Broadside Battery":
			_bolt_on("battleship", "mag", 1)
		"Extra Torpedo Tubes":
			_bolt_on("frigate", "torpedo", 1)
		"PDC Nest":
			_bolt_on("destroyer", "pdc", 1)
		"Missile Pods":
			_bolt_on("cruiser", "swarm", 1)
		"Gun Deck":
			_bolt_on("carrier", "gatling", 2)
		"Hot-Loaded MAGs":
			for w in ["mag", "mini_mag"]:
				GD.weapon_damage_mult[w] = float(GD.weapon_damage_mult.get(w, 1.0)) * 1.2
		"Shaped Warheads":
			GD.weapon_damage_mult["torpedo"] = float(GD.weapon_damage_mult.get("torpedo", 1.0)) * 1.3
			GD.torpedo_splash_mult *= 1.2
		"Bigger Swarms":
			GD.swarm_bonus += 1   # salvos are 4 big missiles now (v0.9.116)
		"Proximity Fuses":
			GD.weapon_damage_mult["flak"] = float(GD.weapon_damage_mult.get("flak", 1.0)) * 1.3
		"PDC Overdrive":
			GD.weapon_cooldown_mult["pdc"] = float(GD.weapon_cooldown_mult.get("pdc", 1.0)) * 0.75
		"Long-Range PDCs":
			GD.pdc_range_mult = 2.0
		"Wingmen":
			GD.fighter_group_bonus += 1
		"Mine Layer":
			if GD.mine_cap == 0:
				GD.mine_cap = GD.MINE_CAP
				GD.mine_damage = GD.MINE_DAMAGE
			else:
				GD.mine_cap = mini(GD.MINE_CAP_MAX, GD.mine_cap + 2)
				GD.mine_damage *= 1.25
			return true
		_:
			return false
	get_tree().call_group("ships", "apply_fleet_bonuses")
	return true


## A refit card: every ship of a type gets more weapons, the ones flying now included.
func _bolt_on(type_id: String, weapon_id: String, count: int) -> void:
	var extra: Array = GD.extra_weapons.get(type_id, [])
	for i in count:
		extra.append(weapon_id)
	GD.extra_weapons[type_id] = extra
	for view in system_views:
		for child in view.get_children():
			var ship := child as ShipScript
			if ship != null and ship.alive and ship.faction == GD.Faction.UNE and ship.type_id == type_id:
				for i in count:
					ship.add_weapon(weapon_id)


## Starbase health up by a factor: new ones, and the ones you already have (keeping
## their damage share).
func _toughen_starbases(factor: float) -> void:
	GD.starbase_health_mult *= factor
	for view in system_views:
		for child in view.get_children():
			var structure = child.get("structure")
			if structure is Dictionary and int(child.get("faction")) == GD.Faction.UNE and String(structure.get("type", "")) == "starbase":
				child.set("max_health", float(child.get("max_health")) * factor)
				child.set("health", float(child.get("health")) * factor)


## Your Starbases (not Shipyards or MAG Cannons), for the Customs Office.
func _count_une_starbases_only() -> int:
	var count := 0
	for s in systems:
		for st in Array(s["structures"]):
			if st["type"] == "starbase" and st["faction"] == GD.Faction.UNE:
				count += 1
	return count


func _apply_tech_card(card_name: String) -> bool:
	match card_name:
		"Advanced Logistics":
			starbase_limit += 1
		"Extended Orbits":
			GD.orbit_multiplier *= 1.6   # was 1.2 (v0.9.211)
		"Orbital Habitats":
			for s in systems:
				var planets: Array = s["planets"]
				for p in planets:
					if int(p["capacity"]) > 0:   # dead worlds stay dead
						p["capacity"] = int(p["capacity"]) + 2
		"Planetary Shields":
			for s in systems:
				for p in Array(s["planets"]):
					if p["owner"] == GD.Faction.UNE:
						p["shields"] = GD.PLANET_SHIELDS
						p["max_shields"] = GD.PLANET_SHIELDS
		"Deep Core Mining", "Gas Giant Siphons", "Trade Networks":
			pass
		"Blink Drive":
			GD.blink_level = maxi(GD.blink_level, 1)
		"Blink Drive II":
			GD.blink_level = 2
		"Afterimage":
			GD.afterimage = true
		"Slipstream":
			GD.slipstream = true
		"Ram Plating":
			GD.ram_plating = true
		"Afterburner Wake":
			GD.afterburner_wake = true
		"Quick Spool":
			GD.warp_charge_mult = 0.5
		"Hot Exit":
			GD.hot_exit = true
		"Overdrive Tanks":
			GD.boost_capacity_mult = 1.5
			GD.boost_refill_mult = 1.25   # was 2.0 (v0.9.189): refilling a bigger meter twice as fast was too much
		"Drift Thrusters":
			GD.drift_thrusters = true
		"Damage Control":
			GD.damage_control = true
		"Long-Range Sensors":
			GD.long_sensors = true
		"Warp Drive Tuning":
			GD.warp_time_mult = 1.0 / 1.5
		"Colony Pods":
			GD.colony_settle_mult = 0.5
		"Fortified Starbases":
			_toughen_starbases(1.25)
		"Asteroid Force Fields":
			GD.asteroid_shields = true
			_refresh_rock_shields()
		_:
			return false
	return true


# --- escorts, repairs, bumps, pickups, dealers, Rebels ------------------------------

## Hold right-click in Fleet Mode: every ship but the Kharkiv flies to the reticle and fights.
## Release: they come straight back and re-form.
func _update_escorts(delta: float) -> void:
	if _right_block and not Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		_right_block = false
	var holding := fleet_mode and not in_galaxy and warp_state != Warp.TRANSIT and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) \
		and placing == "" and not _right_block
	var point := get_global_mouse_position()
	if holding:
		_escorts_out = true
		var slot_i := 0
		for ship in fleet:
			if ship == kharkiv:
				continue
			# Ships on their way back answer a new order straight away. Ships fight on
			# whatever their health: pulling them out is up to you.
			if returning.has(ship):
				returning.erase(ship)
			ship.driven = false
			ship.escorting = true
			# Each escort gets its own spot around the reticle (a sunflower spiral) so they spread out.
			var spot := Vector2.RIGHT.rotated(slot_i * 2.39996) * (2.5 + 1.6 * sqrt(float(slot_i))) * GD.UNIT
			ship.escort_point = point + spot
			slot_i += 1
	elif _escorts_out:
		_escorts_out = false
		for ship in fleet:
			if ship != kharkiv and ship.escorting:
				ship.escorting = false
				returning.append(ship)
	for ship in returning.duplicate():
		if not is_instance_valid(ship):
			returning.erase(ship)
			continue
		var i := fleet.find(ship)
		if i < 0:
			returning.erase(ship)
			continue
		var slot := _slot_of(i)
		var gap: float = ship.position.distance_to(slot)
		if gap < _form_bubble(ship) * 2.0:
			# Close enough: it rejoins the formation and flies the last bit itself.
			ship.stop()
			ship.velocity = Vector2.ZERO
			ship.driven = true
			ship.set_meta("retreating", false)
			returning.erase(ship)
			_form_state[ship.get_instance_id()] = {"vel": fleet_velocity, "seen": slot, "delay": randf_range(0.1, 0.3), "phase": randf() * TAU}
		else:
			ship.move_to(slot + fleet_velocity * 0.4)


func _world_update(delta: float) -> void:
	_toast_cooldown -= delta
	var view: Node2D = system_views[fleet_system]
	_starbase_repairs(delta)
	_damage_control(delta)
	_asteroid_bumps(view)
	_check_pickups(view)
	_ship_contacts(view, delta)
	_check_bubbles(view)
	var total := kharkiv.max_armor + kharkiv.max_hull
	var health_left := (kharkiv.armor + kharkiv.hull) / total if total > 0.0 else 1.0
	hud.set_low_health(health_left)
	if health_left < 0.2:
		SfxPlayer.say("kharkiv", "Flagship critical.", 20.0)
		SfxPlayer.ui("alarm", -8.0)
	_check_dealer(view)


func _hostiles_in(view: Node2D) -> bool:
	for child in view.get_children():
		var ship := child as ShipScript
		if ship != null and ship.alive and ship.faction != GD.Faction.UNE:
			return true
	return false


## Ships inside any of your Starbase orbits repair 10% per second, if no enemies are in the system.
func _starbase_repairs(delta: float) -> void:
	for s in systems:
		var index: int = s["index"]
		var view: Node2D = system_views[index]
		var bases: Array = []
		var yard_boost: Array = []   # Repair Gantries: Shipyards reach further and heal faster
		for st in Array(s["structures"]):
			if (st["type"] == "shipyard" or (st["type"] == "starbase" and GD.starbase_repairs)) and st["faction"] == GD.Faction.UNE:
				var sb_pos: Vector2 = st["pos"]
				bases.append(sb_pos * GD.UNIT)
				yard_boost.append(GD.shipyard_repair_mult if st["type"] == "shipyard" else 1.0)
		if bases.is_empty():
			continue
		var orbit := GD.STARBASE_ORBIT * GD.orbit_multiplier * GD.UNIT
		# A base stops repairing only while hostile ships are close to it (a lurker on the
		# far side of the system, or a neutral ship, no longer shuts every repair off).
		var hostiles: Array = []
		for child in view.get_children():
			var enemy := child as ShipScript
			if enemy != null and enemy.alive and GD.is_hostile(GD.Faction.UNE, enemy.faction):
				hostiles.append(enemy.position)
		for b_i in range(bases.size() - 1, -1, -1):
			var base_at: Vector2 = bases[b_i]
			for h in hostiles:
				if base_at.distance_to(h) <= orbit * 2.0:
					bases.remove_at(b_i)
					yard_boost.remove_at(b_i)
					break
		if bases.is_empty():
			continue
		for child in view.get_children():
			var ship := child as ShipScript
			if ship == null or ship.faction != GD.Faction.UNE or not ship.is_damaged():
				continue
			for b_i in bases.size():
				var base_px: Vector2 = bases[b_i]
				var boost := float(yard_boost[b_i])
				if ship.position.distance_to(base_px) <= orbit * boost:
					ship.repair(GD.REPAIR_RATE * boost * delta)
					var t := float(ship.get_meta("plus_t", 0.0)) + delta
					if t >= 0.45 and ship.visible:
						t = 0.0
						var plus := RepairPlus.new()
						view.add_child(plus)
						var r := GD.ship_pixels(ship.type_id)
						plus.setup(ship.position + Vector2(randf_range(-r, r) * 0.6, -r * 0.6))
					ship.set_meta("plus_t", t)
					break


## Medium and Large fleet ships that hit an asteroid shake, flash red and lose hull;
## the asteroid is knocked away and drifts back.
func _asteroid_bumps(view: Node2D) -> void:
	var rocks: Array = view.call("asteroids")
	for ship in fleet:
		if not is_instance_valid(ship) or not ship.visible:
			continue
		var info: Dictionary = GD.SHIPS[ship.type_id]
		if int(info["size"]) < 1:
			continue
		var r := GD.ship_pixels(ship.type_id) * 0.6
		for rock in rocks:
			var rock_node := rock as Node2D
			var reach := r + float(rock_node.call("radius_px"))
			var ship_pos: Vector2 = ship.position
			var gap := rock_node.position - ship_pos
			if gap.length() < reach:
				if not (GD.ram_plating and boosting):
					ship.bump()
				rock_node.call("knock", gap.normalized() * 220.0)
				if ship == kharkiv:
					fleet_velocity *= -0.3


func _on_rich_destroyed(system_index: int, pos_px: Vector2, gold: bool) -> void:
	var view: Node2D = system_views[system_index]
	var pickup := Pickup.new()
	view.add_child(pickup)
	# One drop per rich rock: 25% a Repair Kit, otherwise a Fleet Card.
	if randf() < GD.REPAIR_KIT_CHANCE:
		pickup.setup(pos_px, "repair", "Good")
	else:
		pickup.setup(pos_px, "fleet", GD.roll_rarity(GD.GOLD_ODDS if gold else GD.SILVER_ODDS))
	pickups.append(pickup)


func _check_pickups(view: Node2D) -> void:
	for pickup in pickups.duplicate():
		if not is_instance_valid(pickup):
			pickups.erase(pickup)
			continue
		# Touching the pickup's glow picks it up, not just the icon in the middle.
		var reach := maxf(2.2 * GD.UNIT, float(pickup.call("glow_radius")) + GD.ship_pixels("capital") * 0.5)
		if pickup.get_parent() != view or kharkiv.position.distance_to(pickup.position) > reach:
			continue
		if String(pickup.kind) == "repair":
			# Repair Kit: free, fully restores every ship flying in the formation
			# (ships off escorting or heading home miss out).
			pickups.erase(pickup)
			pickup.queue_free()
			SfxPlayer.ui("pickup")
			var mended := 0
			for ship in fleet:
				if not is_instance_valid(ship) or not ship.alive or not ship.driven or ship.get_parent() != kharkiv.get_parent():
					continue
				ship.armor = ship.max_armor
				ship.hull = ship.max_hull
				ship.shields = ship.max_shields
				ship.queue_redraw()
				mended += 1
				if ship != kharkiv:
					_spawn_text(fleet_system, ship.position / GD.UNIT, ["+REPAIRED"])
			_spawn_text(fleet_system, kharkiv.position / GD.UNIT, ["FLEET REPAIRED" if mended > 1 else "FULLY REPAIRED"])
			continue
		if String(pickup.kind) != "fleet":
			# Tech pickups are free.
			var secret := String(pickup.kind) == "secret"
			var reason := "SECRET TECH! Super rare rewards will live here later." if secret else "You recovered tech from a hidden base!"
			pickups.erase(pickup)
			pickup.queue_free()
			SfxPlayer.ui("pickup")
			_queue_card({"type": "tech", "reason": reason, "tip": true})
			continue
		var cost := int(round(pickup_cost * GD.trade_mult))
		if int(amounts["credits"]) >= cost:
			amounts["credits"] = int(amounts["credits"]) - cost
			pickup_cost *= 1.25
			pickups.erase(pickup)
			SfxPlayer.ui("pickup")
			_queue_card({"type": "fleet", "rarity": pickup.rarity, "reason": "Fleet Card pickup bought."})
			pickup.queue_free()
			_refresh_hud()
		elif _toast_cooldown <= 0.0:
			_toast_cooldown = 3.0
			SfxPlayer.ui("deny", -2.0)
			hud.show_toast("This Fleet Card pickup costs {credits}%d. You have {credits}%d." % [cost, int(amounts["credits"])], 2.5)


# --- Arms Dealer ------------------------------------------------------------------

func _check_dealer(view: Node2D) -> void:
	var dealer: Node2D = view.get("dealer")
	if dealer == null or shop_dealer != null or not card_open.is_empty():
		return
	var inside := kharkiv.position.distance_to(dealer.position) <= 12.0 * GD.UNIT
	if not inside:
		if _dealer_cooldown == dealer:
			_dealer_cooldown = null
		return
	if _dealer_cooldown == dealer:
		return
	if Array(dealer.get("stock")).is_empty():
		dealer.set("stock", _roll_shop())
	shop_dealer = dealer
	get_tree().paused = true
	_show_shop()


func _roll_shop() -> Array:
	var stock: Array = []
	for i in 6:
		var is_fleet := randf() < 0.5
		var owned: Array = fleet_cards if is_fleet else tech_cards
		var pool: Array = []
		for c in (GD.FLEET_CARDS if is_fleet else GD.TECH_CARDS):
			if _card_ok(c, owned):
				pool.append(c)
		if pool.is_empty():
			continue
		var card: Dictionary = (pool[randi() % pool.size()] as Dictionary).duplicate()
		var rarity := GD.roll_rarity([70, 25, 5])
		card["rarity"] = rarity
		card["type"] = "fleet" if is_fleet else "tech"
		card["base_price"] = int(GD.RARITY_PRICE[rarity])
		card["price"] = int(round(float(card["base_price"]) * dealer_price_mult * GD.trade_mult))
		card["count"] = _count_in(fleet_cards if is_fleet else tech_cards, String(card["name"]))
		stock.append(card)
	return stock


func _show_shop() -> void:
	hud.fly_target = _screen_pos(fleet_system, kharkiv.position if kharkiv != null else Vector2.ZERO)
	hud.earth_target = _earth_screen_pos()
	for c in Array(shop_dealer.get("stock")):
		var card: Dictionary = c
		if card.has("base_price"):
			card["price"] = int(round(float(card["base_price"]) * dealer_price_mult * GD.trade_mult))
	hud.show_shop(Array(shop_dealer.get("stock")), int(amounts["credits"]), GD.SHOP_REFRESH)


func _on_shop_buy(slot: int) -> void:
	if shop_dealer == null:
		return
	var stock: Array = shop_dealer.get("stock")
	var card: Dictionary = stock[slot]
	if card.is_empty():
		return
	if int(amounts["credits"]) < int(card["price"]):
		SfxPlayer.ui("deny", -2.0)
		return
	amounts["credits"] = int(amounts["credits"]) - int(card["price"])
	dealer_price_mult *= 1.5
	var name_text := String(card["name"])
	var times := GD.rarity_mult(String(card["rarity"]))
	for i in times:
		if String(card["type"]) == "fleet":
			fleet_cards.append(name_text)
			_apply_fleet_card(name_text)
		else:
			tech_cards.append(name_text)
			_apply_tech_card(name_text)
	stock[slot] = {}
	_refresh_hud()
	hud.show_toast("Bought %s %s." % [String(card["rarity"]), name_text], 2.5)
	_show_shop()


func _on_shop_refresh() -> void:
	if shop_dealer == null or int(amounts["credits"]) < GD.SHOP_REFRESH:
		return
	amounts["credits"] = int(amounts["credits"]) - GD.SHOP_REFRESH
	shop_dealer.set("stock", _roll_shop())
	_refresh_hud()
	_show_shop()


func _on_shop_leave() -> void:
	hud.close_overlay()
	_dealer_cooldown = shop_dealer
	shop_dealer = null
	get_tree().paused = false
	call_deferred("_show_next_card")


# --- Haulers ----------------------------------------------------------------------

func _owns_planet(system_index: int) -> Dictionary:
	var sys: Dictionary = systems[system_index]
	for p in Array(sys["planets"]):
		if p["owner"] == GD.Faction.UNE:
			return p
	return {}


## The systems to fly through to reach the nearest system with a planet you own.
func _route_to_owned(start: int) -> Array:
	var previous := {start: -1}
	var queue: Array = [start]
	while not queue.is_empty():
		var here: int = queue.pop_front()
		if not _owns_planet(here).is_empty():
			var path: Array = []
			var step := here
			while step != -1:
				path.push_front(step)
				step = int(previous[step])
			return path
		for link in Generator.LINKS:
			var a: int = link[0]
			var b: int = link[1]
			var next := b if a == here else (a if b == here else -1)
			if next >= 0 and not previous.has(next):
				previous[next] = here
				queue.append(next)
	return []


func _exit_between(from_index: int, to_index: int) -> Dictionary:
	var sys: Dictionary = systems[from_index]
	for e in Array(sys["exits"]):
		if int(e["to"]) == to_index:
			return e
	return {}


func _send_hauler(src: Dictionary) -> bool:
	var start: int = src["system"]
	var path := _route_to_owned(start)
	if path.is_empty():
		return false   # nowhere to deliver yet: the Starbase keeps it
	var legs: Array = []
	for i in range(path.size() - 1):
		var here: int = path[i]
		var there: int = path[i + 1]
		var out := _exit_between(here, there)
		var back := _exit_between(there, here)
		var out_pos: Vector2 = out["pos"]
		var back_pos: Vector2 = back["pos"]
		var back_dir: Vector2 = back["dir"]
		legs.append({"kind": "exit", "pos": out_pos * GD.UNIT, "to": there, "entry": (back_pos - back_dir * 6.0) * GD.UNIT})
	var planet := _owns_planet(int(path[-1]))
	var planet_pos: Vector2 = planet["pos"]
	var planet_r: float = planet["radius"]
	var sb_pos: Vector2 = src["pos"]
	# Land on the near side of the planet.
	var approach := planet_pos + (sb_pos - planet_pos).normalized() * (planet_r + 1.0) if path.size() == 1 else planet_pos
	legs.append({"kind": "planet", "pos": approach * GD.UNIT})
	var hauler := Hauler.new()
	var view: Node2D = system_views[start]
	view.add_child(hauler)
	hauler.setup(system_views, start, sb_pos * GD.UNIT, legs, {"alloys": int(src["alloys"]), "gas": int(src["gas"])})
	hauler.delivered.connect(_on_hauler_delivered)
	hauler.destroyed.connect(_on_hauler_destroyed)
	hauler.hit.connect(_on_civilian_hit)
	return true


func _on_hauler_delivered(_hauler: Node2D, cargo: Dictionary, system_index: int, pos_px: Vector2) -> void:
	amounts["alloys"] = int(amounts["alloys"]) + int(cargo.get("alloys", 0))
	alloys_mined += int(cargo.get("alloys", 0))
	amounts["gas"] = int(amounts["gas"]) + int(cargo.get("gas", 0))
	var lines: Array = []
	if int(cargo.get("alloys", 0)) > 0:
		lines.append("+%d ALLOYS" % int(cargo["alloys"]))
	if int(cargo.get("gas", 0)) > 0:
		lines.append("+%d GAS" % int(cargo["gas"]))
	_spawn_text(system_index, pos_px / GD.UNIT, lines)
	_gather_sound(system_index, pos_px)
	_refresh_hud()


## A small bubbly "gather" where resources come in at a planet. It's a world sound, so
## it's loudest when you're looking at that planet, fades with distance, and stays
## silent for systems you aren't viewing.
func _gather_sound(system_index: int, pos_px: Vector2) -> void:
	if system_index < 0 or system_index >= system_views.size():
		return
	var marker := Node2D.new()
	(system_views[system_index] as Node2D).add_child(marker)
	marker.position = pos_px
	SfxPlayer.play("gather", marker, -4.0, 0.08)   # was -8 before v0.9.103
	marker.queue_free()


# --- Roid Rebels ------------------------------------------------------------------

func _rebels_intercept() -> void:
	# Entering Rebel space: a pack of 4 breaks off from the home defence.
	var view: Node2D = system_views[2]
	var sent := 0
	for child in view.get_children():
		var ship := child as ShipScript
		if ship == null or ship.faction != GD.Faction.REBELS or ship.role != "":
			continue
		ship.attack(kharkiv)
		sent += 1
		if sent >= 4:
			break
	if sent > 0:
		hud.show_toast("Rebel interceptors incoming!", 3.0)


func _on_rebel_base_hit(system_index: int, attacker: Node2D) -> void:
	var view: Node2D = system_views[system_index]
	var target: Node2D = attacker if attacker != null and is_instance_valid(attacker) else kharkiv
	for child in view.get_children():
		var ship := child as ShipScript
		if ship != null and ship.faction == GD.Faction.REBELS:
			ship.attack(target)
	hud.show_toast("You attacked the Rebel Rock. Every Rebel in the system is coming for you, and its Gatlings are firing across the whole system!", 4.0)


func _on_rebel_base_destroyed(system_index: int) -> void:
	# Rebel Rock drops one random pickup where it stood.
	var giant: Dictionary = systems[system_index].get("giant", {})
	if not giant.is_empty():
		var drop := Pickup.new()
		system_views[system_index].add_child(drop)
		var roll := randf()
		var at := Vector2(giant["pos"]) * GD.UNIT
		if roll < 0.4:
			drop.setup(at, "fleet", GD.roll_rarity(GD.GOLD_ODDS))
		elif roll < 0.7:
			drop.setup(at, "tech", "Good")
		elif roll < 0.9:
			drop.setup(at, "repair", "Good")
		else:
			drop.setup(at, "secret", "Good")
		pickups.append(drop)
	systems_conquered += 1
	hud.set_objective_done(0)
	waves_over = true
	hud.show_wave("", false)
	hud.show_toast("The Rebel Rock is destroyed. The Roid Rebels are broken! Next: the Sons of Philip on Mars.", 8.0)
	if sons != null:
		if not bool(sons.get("active")):
			# Breaking the Rock early wakes Philip early: Xander takes it personally.
			hud.xander.call("say", "philip",
				"You broke the Rebel Rock, so... Da— Philip is awake. The Sons are coming. Now.",
				"I'd say he means well. He doesn't. Take Mars to end it.", true)
		sons.activate()



## Where a point in a system appears on screen (off to one side if that system isn't shown).
func _screen_pos(system_index: int, pos_px: Vector2) -> Vector2:
	var size := get_viewport().get_visible_rect().size
	if in_galaxy or system_index != current:
		return Vector2(size.x * 0.5, size.y * 0.15)
	return get_viewport().get_canvas_transform() * pos_px



func _count_buildings(building: String) -> int:
	var n := 0
	for s in systems:
		for p in Array(s["planets"]):
			if p["owner"] == GD.Faction.UNE:
				n += _count_in(Array(p["buildings"]), building)
	return n


func _earth_screen_pos() -> Vector2:
	var home: Dictionary = systems[HOME]
	var earth: Dictionary = Array(home["planets"])[0]
	var earth_pos: Vector2 = earth["pos"]
	return _screen_pos(HOME, earth_pos * GD.UNIT)


## A Starbase's collected resources wait in its stockpile; Haulers take up to 5 containers each.
func _load_haul(src: Dictionary) -> void:
	var key := "%d:%s" % [int(src["system"]), str(src["pos"])]
	var pile: Dictionary = _stockpiles.get(key, {"alloys": 0, "gas": 0})
	pile["alloys"] = int(pile["alloys"]) + int(src["alloys"])
	pile["gas"] = int(pile["gas"]) + int(src["gas"])
	var sent := 0
	while int(pile["alloys"]) + int(pile["gas"]) > 0 and sent < 3:
		# A container holds 5 Alloys or 1 Gas (x5 economy, v0.9.237).
		var alloys := mini(int(pile["alloys"]), GD.HAULER_CAPACITY * GD.ALLOY_SCALE)
		var gas := mini(int(pile["gas"]), GD.HAULER_CAPACITY - int(ceil(float(alloys) / GD.ALLOY_SCALE)))
		var shipment := src.duplicate()
		shipment["alloys"] = alloys
		shipment["gas"] = gas
		if not _send_hauler(shipment):
			break
		pile["alloys"] = int(pile["alloys"]) - alloys
		pile["gas"] = int(pile["gas"]) - gas
		sent += 1
	_stockpiles[key] = pile


# --- reward bubbles ----------------------------------------------------------------

func _on_bubble_clicked(planet: Dictionary) -> void:
	if fleet_mode:
		return
	_claim_bubble(planet)


## In Fleet Mode, flying the Kharkiv into a Growth Reward bubble claims it.
func _check_bubbles(view: Node2D) -> void:
	if kharkiv == null or not card_open.is_empty():
		return
	var sys: Dictionary = systems[fleet_system]
	for p in Array(sys["planets"]):
		if int(p.get("pending_cards", 0)) <= 0:
			continue
		var bubble: Vector2 = view.call("_bubble_pos", p)
		if kharkiv.position.distance_to(bubble) < 3.0 * GD.UNIT:
			_claim_bubble(p)
			return


func _claim_bubble(planet: Dictionary) -> void:
	if int(planet.get("pending_cards", 0)) <= 0:
		return
	planet["pending_cards"] = int(planet["pending_cards"]) - 1
	var index := -1
	for s in systems:
		if Array(s["planets"]).has(planet):
			index = int(s["index"])
	hud.clear_notification("growth:%d:%s" % [index, String(planet["name"])])   # picked up: no stale link
	_queue_card({"type": "planet", "planet": planet, "system": index})


# --- H and Tab -----------------------------------------------------------------------

func _on_home_key() -> void:
	if fleet_mode and kharkiv != null:
		if autopilot:
			autopilot = false
			hud.show_toast("Autopilot off", 1.5)
			return
		# H always heads home to Earth (v0.9.214; was the nearest Starbase).
		if _route_to(HOME).is_empty():
			SfxPlayer.ui("deny", -2.0)
			hud.show_toast("No route back to Earth.", 2.0)
			return
		autopilot = true
		_pilot_planet = {}
		hud.show_toast("Autopilot: boosting home to Earth. Shift or WASD to take back control.", 3.0)
		return
	# Outside Fleet Mode: camera back to Earth.
	_open_system(HOME)
	var sys: Dictionary = systems[HOME]
	var earth: Dictionary = Array(sys["planets"])[0]
	camera.position = Vector2(earth["pos"]) * GD.UNIT


func _on_cycle_key() -> void:
	if fleet_mode:
		hud.show_toast("Second Command isn't unlocked yet. A future Tech card lets you run a second fleet.", 3.0)
		return
	var owned: Array = []
	for s in systems:
		for p in Array(s["planets"]):
			if p["owner"] == GD.Faction.UNE:
				owned.append([int(s["index"]), p])
	if owned.is_empty():
		return
	_planet_cycle = (_planet_cycle + 1) % owned.size()
	var pick: Array = owned[_planet_cycle]
	var p: Dictionary = pick[1]
	_open_system(int(pick[0]))
	camera.position = Vector2(p["pos"]) * GD.UNIT
	_clamp_camera()
	_on_planet_clicked(p)


func _has_une_starbase(system_index: int) -> Vector2:
	var sys: Dictionary = systems[system_index]
	for st in Array(sys["structures"]):
		if st["type"] == "starbase" and st["faction"] == GD.Faction.UNE:
			return Vector2(st["pos"])
	return Vector2.INF


## Systems from the fleet's system to the nearest one with a friendly Starbase.
func _starbase_route() -> Array:
	var previous := {fleet_system: -1}
	var queue: Array = [fleet_system]
	while not queue.is_empty():
		var here: int = queue.pop_front()
		if _has_une_starbase(here) != Vector2.INF:
			var path: Array = []
			var step := here
			while step != -1:
				path.push_front(step)
				step = int(previous[step])
			return path
		for link in Generator.LINKS:
			var a: int = link[0]
			var b: int = link[1]
			var next := b if a == here else (a if b == here else -1)
			if next >= 0 and not previous.has(next):
				previous[next] = here
				queue.append(next)
	return []


## Systems from the fleet's system to the goal system (shortest by jumps).
func _route_to(goal: int) -> Array:
	var previous := {fleet_system: -1}
	var queue: Array = [fleet_system]
	while not queue.is_empty():
		var here: int = queue.pop_front()
		if here == goal:
			var path: Array = []
			var step := here
			while step != -1:
				path.push_front(step)
				step = int(previous[step])
			return path
		for link in Generator.LINKS:
			var a: int = link[0]
			var b: int = link[1]
			var next := b if a == here else (a if b == here else -1)
			if next >= 0 and not previous.has(next):
				previous[next] = here
				queue.append(next)
	return []


## Autopilot to a planet's Growth Reward bubble: through warp lanes, then into the bubble.
func _bubble_pilot_dir() -> Vector2:
	if int(_pilot_planet.get("pending_cards", 0)) <= 0 or _pilot_planet["owner"] != GD.Faction.UNE:
		autopilot = false
		_pilot_planet = {}
		return Vector2.ZERO
	var route := _route_to(_pilot_system)
	if route.is_empty():
		autopilot = false
		_pilot_planet = {}
		return Vector2.ZERO
	var target: Vector2
	if route.size() == 1:
		# Flying into the bubble claims it (see _check_bubbles).
		target = system_views[fleet_system].call("_bubble_pos", _pilot_planet)
	else:
		var exit := _exit_between(fleet_system, int(route[1]))
		if exit.is_empty():
			autopilot = false
			return Vector2.ZERO
		target = Vector2(exit["pos"]) * GD.UNIT
	var to := target - kharkiv.position
	return to.normalized() * clampf(to.length() / (6.0 * GD.UNIT), 0.35, 1.0)


func _autopilot_dir() -> Vector2:
	if not _pilot_planet.is_empty():
		return _bubble_pilot_dir()
	# Home autopilot: back to Earth (v0.9.214), parking just off the planet.
	var route := _route_to(HOME)
	if route.is_empty():
		autopilot = false
		return Vector2.ZERO
	var target: Vector2
	if route.size() == 1:
		var earth: Dictionary = Array(systems[HOME]["planets"])[0]
		var r := float(earth.get("radius", 4.0))
		target = (Vector2(earth["pos"]) + Vector2(-(r + 8.0), 6.0)) * GD.UNIT
		if kharkiv.position.distance_to(target) < 3.0 * GD.UNIT:
			autopilot = false
			hud.show_toast("Home: arrived at Earth.", 2.0)
			return Vector2.ZERO
	else:
		var exit := _exit_between(fleet_system, int(route[1]))
		if exit.is_empty():
			autopilot = false
			return Vector2.ZERO
		target = Vector2(exit["pos"]) * GD.UNIT
	var to := target - kharkiv.position
	# Ease off near the target so the fleet doesn't overshoot.
	return to.normalized() * clampf(to.length() / (8.0 * GD.UNIT), 0.25, 1.0)


# --- fog of war ----------------------------------------------------------------------

func _neighbours(index: int) -> Array:
	var out: Array = []
	for link in Generator.LINKS:
		if int(link[0]) == index:
			out.append(int(link[1]))
		elif int(link[1]) == index:
			out.append(int(link[0]))
	return out


func _update_fog() -> void:
	var present := {}
	for i in systems.size():
		if (kharkiv != null and fleet_system == i and warp_state != Warp.TRANSIT) or _has_une_starbase(i) != Vector2.INF:
			present[i] = true
	# Riding a jump, the fleet still sees the system it's flying through (v0.9.204).
	if kharkiv != null and warp_state == Warp.TRANSIT and warp_watch and not warp_exit.is_empty():
		present[fleet_system if _transit_half <= 1 else int(warp_exit["to"])] = true
	# Long-Range Sensors: Starbases also sense two jumps out.
	var far := {}
	if GD.long_sensors:
		for i in systems.size():
			if _has_une_starbase(i) != Vector2.INF:
				for n in _neighbours(i):
					for m in _neighbours(n):
						far[m] = true
	for i in systems.size():
		var view: Node2D = system_views[i]
		var here := present.has(i)
		var near := far.has(i)
		for n in _neighbours(i):
			if present.has(n):
				near = true
		view.set("presence", here)
		view.set("sensed", near and not here)
		if here:
			view.set("visited", true)
			galaxy_view.visited[i] = true
		_fog_ships(i, view, here, near)
		_mark_worked(i, view)
		for p in Array(systems[i]["planets"]):
			p["yield"] = _planet_income(p, false)
	if in_galaxy:
		galaxy_view.queue_redraw()


func _fog_ships(index: int, view: Node2D, here: bool, near: bool) -> void:
	var sys: Dictionary = systems[index]
	var observers: Array = []
	if here:
		for child in view.get_children():
			var own := child as ShipScript
			if own != null and own.faction == GD.Faction.UNE and own.alive and own.visible:
				observers.append(own.position)
		for st in Array(sys["structures"]):
			if st["type"] == "starbase" and st["faction"] == GD.Faction.UNE:
				observers.append(Vector2(st["pos"]) * GD.UNIT)
	var bodies: Array = []
	for p in Array(sys["planets"]):
		bodies.append([Vector2(p["pos"]) * GD.UNIT, float(p["radius"]) * GD.UNIT])
	for g in Array(sys["gas_giants"]):
		bodies.append([Vector2(g["pos"]) * GD.UNIT, float(g["radius"]) * GD.UNIT])
	for child in view.get_children():
		var ship := child as ShipScript
		if ship == null or ship.faction == GD.Faction.UNE or not ship.alive:
			continue
		var hidden := _in_field(sys, ship.position) or (not observers.is_empty() and _behind_planets(ship.position, observers, bodies))
		ship.concealed = hidden
		var mode := "hidden"
		if here and not hidden:
			mode = "full"
		elif near and not hidden:
			mode = "dot"
		if mode != ship.fog_mode:
			ship.fog_mode = mode
			ship.queue_redraw()


func _in_field(sys: Dictionary, pos_px: Vector2) -> bool:
	for f in Array(sys["fields"]):
		if (pos_px / GD.UNIT).distance_to(Vector2(f["pos"])) < 6.0:
			return true
	return false


## True when a planet blocks the line of sight from every observer.
func _behind_planets(pos_px: Vector2, observers: Array, bodies: Array) -> bool:
	for eye in observers:
		var blocked := false
		for b in bodies:
			var centre: Vector2 = b[0]
			var radius: float = b[1]
			var closest := Geometry2D.get_closest_point_to_segment(centre, eye, pos_px)
			if closest.distance_to(centre) < radius:
				blocked = true
				break
		if not blocked:
			return false
	return true


# --- game over -----------------------------------------------------------------------

func _show_game_over() -> void:
	_show_results("THE KHARKIV IS LOST")


var _death_report: Dictionary = {}

## What hit the flagship in its last 10 seconds: {"total": n, "rows": [[weapon, hits,
## damage, "from ..."], ...]} biggest first.
func _last_hits(ship: Node2D) -> Dictionary:
	var hits_log: Array = ship.get("damage_log")
	var now := Time.get_ticks_msec() / 1000.0
	var by_weapon := {}
	var total := 0.0
	for e in hits_log:
		if now - float(e[0]) > 10.0:
			continue
		var w := String(e[2])
		if not by_weapon.has(w):
			by_weapon[w] = {"hits": 0, "damage": 0.0, "who": {}}
		var b: Dictionary = by_weapon[w]
		b["hits"] = int(b["hits"]) + 1
		b["damage"] = float(b["damage"]) + float(e[1])
		var who: Dictionary = b["who"]
		who[String(e[3])] = int(who.get(String(e[3]), 0)) + 1
		total += float(e[1])
	var rows: Array = []
	for w in by_weapon.keys():
		var b: Dictionary = by_weapon[w]
		var names: Array = (b["who"] as Dictionary).keys()
		names.sort_custom(func(a, c) -> bool: return int(b["who"][a]) > int(b["who"][c]))
		rows.append([String(w), int(b["hits"]), float(b["damage"]), "from " + ", ".join(PackedStringArray(names.slice(0, 3)))])
	rows.sort_custom(func(a, c) -> bool: return float(a[2]) > float(c[2]))
	return {"total": total, "rows": rows}


func _show_results(title: String) -> void:
	get_tree().paused = true
	Input.set_custom_mouse_cursor(null)
	var won := title.contains("VICTORY")
	var held := 0
	for s in systems:
		for p in Array(s["planets"]):
			if p["owner"] == GD.Faction.UNE:
				held += 1
	var best_name := ""
	var best := 0
	for n in kills_by_name.keys():
		if int(kills_by_name[n]) > best:
			best = int(kills_by_name[n])
			best_name = String(n)
	var clock := "%d:%02d" % [int(run_time) / 60, int(run_time) % 60]
	# Final score, most important first: [what, the stat, points].
	var outcome_points := 0
	var outcome := ""
	if won:
		# Victory is worth the most, plus 10 points for every second under 20 minutes.
		outcome_points = 10000 + maxi(0, int(1200.0 - run_time)) * 10
		outcome = "Victory on day %d (%s)" % [tick_count + 1, clock]
	else:
		# Time survived is counted in days (one economy tick each): 50 points a day.
		outcome_points = tick_count * 50
		outcome = "Survived %d day%s" % [tick_count, "" if tick_count == 1 else "s"]
	var rows := [
		[outcome, "", outcome_points],
		["Enemy ships destroyed", str(enemies_destroyed), enemies_destroyed * 100],
		["Systems conquered", str(systems_conquered), systems_conquered * 2500],
		["Planets held", str(held), held * 750],
		["Peak population", str(peak_pop), peak_pop * 200],
		["Stations built", str(stations_built), stations_built * 300],
		["Damage dealt", str(int(GD.damage_dealt)), int(GD.damage_dealt / 10.0)],
	]
	var total := 0
	for r in rows:
		total += int(r[2])
	var footer := "Top ship: %s (%d kills)" % [best_name, best] if best > 0 else ""
	hud.show_score(title, rows, total, footer, won, {} if won else _death_report)


func _on_main_menu() -> void:
	SfxPlayer.reset_death_audio()
	get_tree().paused = false
	GD.menu_passed = false
	get_tree().change_scene_to_file("res://scenes/menu.tscn")


func _on_restart() -> void:
	SfxPlayer.reset_death_audio()
	get_tree().paused = false
	get_tree().reload_current_scene()


# --- free fire, collisions, rock cash, notifications -----------------------------------

## Fleet Mode, left mouse held: every ship fires at the reticle. Each ship's aim starts
## offset by its place in the fleet and pulls in toward the reticle while you hold steady,
## flank ships taking longest, so volleys start wide and tighten.
func _update_aim(delta: float) -> void:
	# Clicking the HUD (top bar, panels, music player) never fires the fleet.
	var over_ui := get_viewport().gui_get_hovered_control() != null
	if _click_block and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_click_block = false
	var holding := fleet_mode and not in_galaxy and kharkiv != null and warp_state != Warp.TRANSIT \
		and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and card_open.is_empty() and not over_ui \
		and placing == "" and not _click_block
	var mouse := get_global_mouse_position()
	# Alt selects the heavy weapons (MAGs, Mini MAGs, torpedoes, Swarm Missiles); they
	# fire at the reticle only when you click. With Alt held, the light guns hold fire.
	var alt_held := fleet_mode and not in_galaxy and kharkiv != null and warp_state != Warp.TRANSIT \
		and Input.is_action_pressed("secondary") and card_open.is_empty()
	var secondary := alt_held and holding
	if alt_held:
		holding = false
	hud.show_reticle_label(_secondary_name() if alt_held else "")
	hud.set_key_active("ALT", alt_held)
	if not holding and not secondary:
		_aim_settle = 0.0
		for ship in fleet:
			if is_instance_valid(ship):
				ship.aiming = false
				ship.aiming_secondary = false
		_last_aim = mouse
		return
	# Sweeping the reticle around loosens the aim again.
	var swept := mouse.distance_to(_last_aim) / GD.UNIT
	_last_aim = mouse
	_aim_settle = maxf(0.0, _aim_settle + delta - swept * 0.08)
	for ship in fleet:
		if not is_instance_valid(ship):
			continue
		var offset: Vector2 = ship.position - kharkiv.position
		var tau := 0.25 + offset.length() / GD.UNIT * 0.06
		var spread := exp(-_aim_settle / tau)
		ship.aiming = holding
		ship.aiming_secondary = secondary
		ship.aim_point = mouse + offset * spread * 0.7


## Ships steer clear of each other. If hostile ships actually collide, the bigger one wins
## and the smaller loses half its health (same size: both lose a quarter).
func _ship_contacts(view: Node2D, delta: float) -> void:
	var ships: Array = []
	for child in view.get_children():
		var ship := child as ShipScript
		# Fighters weave through everything: no bumping or ramming.
		if ship != null and ship.alive and ship.visible and ship.type_id != "fighter":
			ships.append(ship)
			ship.set_meta("ram_cd", maxf(0.0, float(ship.get_meta("ram_cd", 0.0)) - delta))
	var shove := clampf(delta * 6.0, 0.0, 1.0)
	# Performance: radii worked out once, and far-apart pairs rejected with one cheap
	# squared-distance test before anything else (this runs for every pair of ships).
	var radii: Array = []
	for ship in ships:
		radii.append(GD.ship_pixels((ship as ShipScript).type_id) * 0.6)
	var elbow := 2.5 * GD.UNIT
	for i in ships.size():
		var a: ShipScript = ships[i]
		var ra: float = radii[i]
		for j in range(i + 1, ships.size()):
			var b: ShipScript = ships[j]
			var rb: float = radii[j]
			var gap: Vector2 = b.position - a.position
			var reach := maxf((ra + rb) * 1.3, elbow)
			if gap.length_squared() >= reach * reach:
				continue
			if not a.alive or not b.alive:
				continue
			var d := gap.length()
			var want := (ra + rb) * 1.3
			if a.faction == b.faction and not a.driven and not b.driven:
				if a.faction == GD.Faction.SONS and a.type_id == "destroyer" and b.type_id == "destroyer":
					want = (ra + rb) * 1.05   # Sons Destroyers: shields nearly touching, a pike phalanx
				else:
					want = maxf(want, 2.5 * GD.UNIT)   # free-flying allies keep some elbow room
			if d >= want:
				continue
			var n: Vector2 = gap / d if d > 0.01 else Vector2.RIGHT.rotated(randf() * TAU)
			if GD.is_hostile(a.faction, b.faction) and d < (ra + rb) * 0.85:
				_ram(a, b)
			# The smaller ship gives way; ships held in formation don't move.
			var wa := 0.0 if a.driven else rb / (ra + rb)
			var wb := 0.0 if b.driven else ra / (ra + rb)
			if a.driven and not b.driven:
				wb = 1.0
			elif b.driven and not a.driven:
				wa = 1.0
			var overlap := (want - d) * shove
			a.position -= n * overlap * wa
			b.position += n * overlap * wb


func _ship_weight(ship: ShipScript) -> int:
	if ship.type_id == "capital":
		return 99
	var info: Dictionary = GD.SHIPS[ship.type_id]
	return int(info["size"]) * 10 + int(info["tier"])


func _ram(a: ShipScript, b: ShipScript) -> void:
	if float(a.get_meta("ram_cd", 0.0)) > 0.0 or float(b.get_meta("ram_cd", 0.0)) > 0.0:
		return
	# Ram Plating: a boosting formation ship smashes the enemy and takes nothing back.
	if GD.ram_plating and boosting:
		var ours: ShipScript = null
		if a.faction == GD.Faction.UNE and a.driven:
			ours = a
		elif b.faction == GD.Faction.UNE and b.driven:
			ours = b
		if ours != null:
			var them: ShipScript = b if ours == a else a
			a.set_meta("ram_cd", 1.0)
			b.set_meta("ram_cd", 1.0)
			var smash := maxf(fleet_velocity.length() / GD.UNIT, 1.0) * GD.RAM_PLATING_DAMAGE
			them.take_damage(smash, ours)
			GD.damage_dealt += smash
			SfxPlayer.play("mag_fire", them, -8.0)
			return
	a.set_meta("ram_cd", 1.0)
	b.set_meta("ram_cd", 1.0)
	var wa := _ship_weight(a)
	var wb := _ship_weight(b)
	if wa == wb:
		a.take_damage((a.max_hull + a.max_armor) * GD.RAM_DAMAGE * 0.5, b)
		if b.alive:
			b.take_damage((b.max_hull + b.max_armor) * GD.RAM_DAMAGE * 0.5, a)
	elif wa > wb:
		b.take_damage((b.max_hull + b.max_armor) * GD.RAM_DAMAGE, a)
	else:
		a.take_damage((a.max_hull + a.max_armor) * GD.RAM_DAMAGE, b)


func _on_rock_cash(system_index: int, pos_px: Vector2, kind: String, valuable: bool = false, alloys: int = 0, gas: int = 0) -> void:
	var cash := int(GD.ROCK_CASH.get(kind, 1))
	amounts["credits"] = int(amounts["credits"]) + cash
	# Shooting a mining rock cashes its load in at once (it just comes back slower).
	amounts["alloys"] = int(amounts["alloys"]) + alloys
	amounts["gas"] = int(amounts["gas"]) + gas
	alloys_mined += alloys
	var lines: Array = ["+¢%d" % cash]
	if alloys > 0:
		lines.append("+%d ALLOYS" % alloys)
	if gas > 0:
		lines.append("+%d GAS" % gas)
	_spawn_text(system_index, pos_px / GD.UNIT, lines)
	_refresh_hud()
	# Xander only scolds you for breaking a rock worth mining (Alloys or Gas).
	if valuable:
		_teach_rocks()


## Xander's lessons, each at the moment it matters, with a little animated diagram.
## Kept short: one line and one tip each.
## Breaking any rock.
func _teach_rocks() -> void:
	if hud == null or hud.xander == null:
		return
	hud.xander.call("teach", "lesson_rocks", [
		{"title": "ASTEROIDS", "art": "asteroids",
			"text": "Nice shot! But you'll only get its resources once, instead of every day.",
			"tip": "Build a Starbase near the rocks to get their resources daily."},
	])


## Arriving in an Asteroid Field system.
func _teach_fields() -> void:
	if hud == null or hud.xander == null:
		return
	hud.xander.call("teach", "lesson_fields", [
		{"title": "ASTEROID FIELD SYSTEM", "art": "fields",
			"text": "Careful here Commander, destroyed rocks in Asteroid fields never respawn, but there's alot of'm!",
			"tip": ""},
	])


## The first time the Kharkiv is beside a planet it could settle.
func _teach_colonize() -> void:
	# Called every frame while the colonize prompt is up, so bail out cheaply.
	if hud == null or hud.xander == null or not bool(hud.xander.call("would_teach", "lesson_colonize")):
		return
	hud.xander.call("teach", "lesson_colonize", [
		{"title": "COLONIZATION", "art": "colonize",
			"text": "Ooh, real estate! But first you need a Starbase in this system. Then fly into the rocket button to settle the planet.",
			"tip": "No Starbase here, no colony. Settling costs 1 pop, %d Alloys and ¢%d." % [GD.colony_alloys(), GD.COLONY_CREDITS]},
		{"title": "WHAT PLANETS MAKE", "art": "colonize",
			"text": "Every planet puts its people to work. Green and blue worlds pay ¢1 for every 2 pops, desert worlds dig 5 Alloys per 3 pops, and icy purple worlds make 1 Gas per 3 pops.",
			"tip": "Growth Rewards follow the same count: every 2nd pop on green worlds, every 3rd on the others."},
	])


func _on_notification_clicked(system_index: int, pos_px: Vector2) -> void:
	# A Growth Reward notice: the flagship flies to the planet's bubble on autopilot.
	if fleet_mode and kharkiv != null and system_index >= 0:
		for p in Array(systems[system_index]["planets"]):
			if int(p.get("pending_cards", 0)) > 0 and (Vector2(p["pos"]) * GD.UNIT).distance_to(pos_px) < 1.0:
				_pilot_planet = p
				_pilot_system = system_index
				autopilot = true
				hud.show_toast("Autopilot: boosting to %s's Growth Reward. Shift or WASD to take back control." % String(p["name"]), 3.0)
				return
	if fleet_mode:
		_set_fleet_mode(false)
	_open_system(system_index)
	camera.position = pos_px
	_clamp_camera()


## Rocks and fields inside a friendly Starbase's orbit show their yields in green.
func _mark_worked(index: int, view: Node2D) -> void:
	var sys: Dictionary = systems[index]
	var bases: Array = []
	for st in Array(sys["structures"]):
		if st["type"] == "starbase" and st["faction"] == GD.Faction.UNE:
			bases.append(Vector2(st["pos"]))
	var orbit := GD.STARBASE_ORBIT * GD.orbit_multiplier
	for rock in view.call("asteroids"):
		var node := rock as Node2D
		var at: Vector2 = node.position / GD.UNIT
		var worked := false
		for b in bases:
			if at.distance_to(Vector2(b)) <= orbit:
				worked = true
		node.set("worked", worked)
	for f in Array(sys["fields"]):
		var worked := false
		for b in bases:
			if Vector2(f["pos"]).distance_to(Vector2(b)) <= orbit:
				worked = true
		f["worked"] = worked


# --- pursuit through the warp -----------------------------------------------------------

## Enemies that were fighting your fleet when it warped out follow it through.
func _gather_pursuers() -> void:
	pursuers.clear()
	var view: Node2D = system_views[fleet_system]
	for child in view.get_children():
		var ship := child as ShipScript
		if ship == null or ship.faction == GD.Faction.UNE or not ship.alive:
			continue
		if ship.role == "anchor" or ship.role == "phalanx":
			continue   # Mars's home guard and shield wall never leave
		var target = ship.get("_attacker")
		var chasing: bool = target != null and is_instance_valid(target) and fleet.has(target)
		if chasing or ship.get("_charging") == true:
			pursuers.append(ship)
			ship.visible = false
			ship.process_mode = Node.PROCESS_MODE_DISABLED


func _pursuers_arrive(to_index: int, entry: Vector2, inward: Vector2) -> void:
	var view: Node2D = system_views[to_index]
	var came := 0
	for ship in pursuers:
		if not is_instance_valid(ship) or not ship.alive:
			continue
		var spot := entry + inward * (GD.WARP_TRIGGER + 1.0) + Vector2(randf_range(-4.0, 4.0), randf_range(-4.0, 4.0))
		ship.reparent(view, false)
		ship.position = spot * GD.UNIT
		ship.heading = inward.angle()
		ship.velocity = inward * ship.speed_units * GD.UNIT
		ship.role = ""
		ship.route = []
		ship.visible = true
		ship.process_mode = Node.PROCESS_MODE_INHERIT
		if kharkiv != null:
			ship.attack(kharkiv)
		came += 1
	pursuers.clear()
	if came > 0:
		_warn("fleet", to_index, entry * GD.UNIT)
		hud.notify("%d enemy ship%s followed you through the warp!" % [came, "s" if came > 1 else ""], to_index, entry * GD.UNIT)


# --- Rebel waves -------------------------------------------------------------------

func _update_waves() -> void:
	if waves_over:
		return
	var left := wave_at - run_time
	var count := GD.rebel_wave_corvettes(wave_n)
	var frigates := GD.rebel_wave_frigates(wave_n)
	var shown := maxf(left, 0.0)
	# Once Philip is awake, his pill shows both timers.
	if sons == null or not bool(sons.get("active")):
		hud.show_wave("REBEL WAVE %d  ·  %d CORVETTES + %d FRIGATE%s  ·  %d:%02d" % [wave_n + 1, count, frigates, "" if frigates == 1 else "S", int(shown) / 60, int(shown) % 60], left <= 15.0)
	if left <= 0.0:
		_spawn_wave(count, frigates)
		wave_n += 1
		# Every 2 minutes after the first, up to 20 seconds late (never early).
		wave_at = GD.WAVE_FIRST + wave_n * GD.WAVE_GAP + randf() * GD.WAVE_LATE


## A Rebel wave launches from the Rebel Rock (v0.9.173: never out of thin air at Sol's
## lane). It crosses Rebel Rocks to the lane toward Sol, jumps, then comes out of the
## lane in Sol and heads for Earth.
const REBEL_SYSTEM := 2
const WAVE_LANE_TIME := 4.0    # seconds in the lane between Rebel Rocks and Sol
const WAVE_JUMP_REACH := 16.0  # units from the lane mouth at which a Rebel jumps

var _wave_out: Array = []      # Rebels still crossing Rebel Rocks toward the lane

func _spawn_wave(count: int, frigates: int = 0) -> void:
	var out_exit := _exit_between(REBEL_SYSTEM, HOME)
	var in_exit := _exit_between(HOME, REBEL_SYSTEM)
	var giant: Dictionary = systems[REBEL_SYSTEM].get("giant", {})
	if out_exit.is_empty() or in_exit.is_empty() or giant.is_empty():
		return
	var rock: Vector2 = giant["pos"]
	var lane: Vector2 = out_exit["pos"]
	var away := (lane - rock).normalized()
	var launch := rock + away * (float(giant.get("radius", 6.0)) + 6.0)
	# Out of the Rock in groups a couple of seconds apart (easier on the frame rate),
	# Frigates in their own group at the back.
	var types: Array = []
	for i in count:
		types.append("corvette")
	for i in frigates:
		types.append("frigate")
	var groups := 0
	var start := 0
	while start < types.size():
		var chunk := types.slice(start, mini(start + WAVE_CHUNK, types.size()))
		if chunk.has("frigate") and chunk.has("corvette"):
			chunk = chunk.slice(0, chunk.find("frigate"))
		start += chunk.size()
		var delay := groups * WAVE_CHUNK_GAP
		groups += 1
		if delay <= 0.0:
			_spawn_wave_group(chunk, launch, away, lane)
		else:
			get_tree().create_timer(delay, false).timeout.connect(_spawn_wave_group.bind(chunk, launch, away, lane))
	_warn("fleet", REBEL_SYSTEM, launch * GD.UNIT)
	hud.notify("A Rebel wave is launching from the Rebel Rock: %d Corvettes and %d Frigate%s, bound for Sol." % [count, frigates, "" if frigates == 1 else "s"], REBEL_SYSTEM, launch * GD.UNIT)


const WAVE_CHUNK := 8          # ships per group as a Rebel wave launches
const WAVE_CHUNK_GAP := 2.0    # seconds between groups


## One group of a Rebel wave leaves the Rock and makes for the lane to Sol.
func _spawn_wave_group(types: Array, launch: Vector2, away: Vector2, lane: Vector2) -> void:
	if game_over:
		return
	var view: Node2D = system_views[REBEL_SYSTEM]
	for t in types:
		var ship := ShipScript.new()
		view.add_child(ship)
		var spot := launch + Vector2(randf_range(-5.0, 5.0), randf_range(-5.0, 5.0))
		ship.setup(String(t), GD.Faction.REBELS, spot * GD.UNIT, away.angle(), "raid")
		ship.raid_target = lane * GD.UNIT
		ship.velocity = away * ship.speed_units * GD.UNIT
		ship.destroyed.connect(_on_enemy_destroyed)
		_wave_out.append(ship)


## Rebels that reach the lane mouth jump, and come out in Sol a few seconds later.
func _update_wave_jumps() -> void:
	if _wave_out.is_empty():
		return
	var out_exit := _exit_between(REBEL_SYSTEM, HOME)
	if out_exit.is_empty():
		return
	var lane_px: Vector2 = Vector2(out_exit["pos"]) * GD.UNIT
	for ship in _wave_out.duplicate():
		if not is_instance_valid(ship) or ship.get("alive") != true:
			_wave_out.erase(ship)
			continue
		var s: Node2D = ship
		if s.get_parent() != system_views[REBEL_SYSTEM]:
			_wave_out.erase(ship)
			continue
		if s.position.distance_to(lane_px) < WAVE_JUMP_REACH * GD.UNIT:
			_wave_out.erase(ship)
			s.visible = false
			s.process_mode = Node.PROCESS_MODE_DISABLED
			get_tree().create_timer(WAVE_LANE_TIME, false).timeout.connect(_wave_arrives.bind(s))


func _wave_arrives(ship: Node2D) -> void:
	if game_over or not is_instance_valid(ship) or ship.get("alive") != true:
		return
	var in_exit := _exit_between(HOME, REBEL_SYSTEM)
	if in_exit.is_empty():
		return
	var e_pos: Vector2 = in_exit["pos"]
	var e_dir: Vector2 = in_exit["dir"]
	var entry := e_pos - e_dir * (GD.WARP_TRIGGER + 4.0)
	var earth: Dictionary = Array(systems[HOME]["planets"])[0]
	ship.reparent(system_views[HOME], false)
	ship.position = (entry + Vector2(randf_range(-5.0, 5.0), randf_range(-5.0, 5.0))) * GD.UNIT
	ship.set("heading", (-e_dir).angle())
	ship.set("raid_target", Vector2(earth["pos"]) * GD.UNIT)
	ship.set("velocity", -e_dir * float(ship.get("speed_units")) * GD.UNIT)
	ship.visible = true
	ship.process_mode = Node.PROCESS_MODE_INHERIT
	ship.queue_redraw()
	# One warning per wave as the first of it comes out of the lane.
	if run_time - _wave_warned_at > 20.0:
		_wave_warned_at = run_time
		_warn("fleet", HOME, entry * GD.UNIT)
		SfxPlayer.say("enemy_fleet", "Enemy fleet entering Sol, Commander.", 5.0)
		hud.notify("The Rebel wave is coming out of the lane into Sol!", HOME, entry * GD.UNIT)
	# The first Frigates to arrive: Xander explains torpedoes.
	if String(ship.get("type_id")) == "frigate" and hud.xander != null:
		hud.xander.call("say", "torpedoes", "Rebel Frigates! They fire big, slow homing torpedoes. Shoot them down, or BOOST out of the way!", "", true, ["SHIFT"])


var _wave_warned_at := -99.0


# --- victory -----------------------------------------------------------------------

func _on_planet_fallen(system_index: int, planet: Dictionary) -> void:
	var was_yours := int(planet["owner"]) == GD.Faction.UNE
	var pos_px: Vector2 = Vector2(planet["pos"]) * GD.UNIT
	# Earth is the one thing you can't lose: it falls, the run is over.
	if String(planet["kind"]) == "earth" and not game_over:
		game_over = true
		call_deferred("_show_results", "EARTH HAS FALLEN")
		return
	planet["owner"] = GD.Faction.NEUTRAL
	planet["pops"] = 0
	# Its Cities go with it, and so does the room they made.
	var cities := Array(planet["buildings"]).count("City")
	planet["capacity"] = maxi(0, int(planet["capacity"]) - cities * CITY_CAPACITY)
	planet["buildings"] = []
	if was_yours:
		# Any PD MAG fortress on it goes down with it.
		for child in system_views[system_index].get_children():
			if child.get("draw_base") == true and child.has_meta("planet_name") and String(child.get_meta("planet_name")) == String(planet["name"]):
				child.queue_free()
		hud.notify("%s has fallen! Its people and buildings are lost." % String(planet["name"]), system_index, pos_px)
		_refresh_hud()
	if String(planet["kind"]) == "mars":
		hud.set_objective_done(1)
		systems_conquered += 1
		game_over = true
		call_deferred("_show_results", "MARS HAS FALLEN  ·  VICTORY")


# --- colonization ------------------------------------------------------------------

## The planet the Kharkiv is close enough to mark, if any.
func _colonize_candidate() -> Dictionary:
	if not fleet_mode or kharkiv == null or warp_state != Warp.NONE:
		return {}
	var sys: Dictionary = systems[fleet_system]
	for p in Array(sys["planets"]):
		if p["owner"] != GD.Faction.NEUTRAL or int(p["pops"]) > 0 or int(p["capacity"]) <= 0:
			continue
		if String(p["kind"]) == "mars" or p.has("colonizing"):
			continue
		var reach := (float(p["radius"]) + GD.COLONY_MARK_RANGE) * GD.UNIT
		if kharkiv.position.distance_to(Vector2(p["pos"]) * GD.UNIT) <= reach:
			return p
	return {}


## The nearest planet you own that can spare a pop (it must keep at least 1).
func _colony_source(target_system: int) -> Dictionary:
	var best := {}
	var best_len := 99
	for s in systems:
		for p in Array(s["planets"]):
			if p["owner"] != GD.Faction.UNE or int(p["pops"]) < 2:
				continue
			var path := _path_between(int(s["index"]), target_system)
			if path.is_empty():
				continue
			if path.size() < best_len or (path.size() == best_len and int(p["pops"]) > int(best["planet"]["pops"])):
				best_len = path.size()
				best = {"system": int(s["index"]), "planet": p}
	return best


func _path_between(from_index: int, to_index: int) -> Array:
	var previous := {from_index: -1}
	var queue: Array = [from_index]
	while not queue.is_empty():
		var here: int = queue.pop_front()
		if here == to_index:
			var path: Array = []
			var step := here
			while step != -1:
				path.push_front(step)
				step = int(previous[step])
			return path
		for n in _neighbours(here):
			if not previous.has(n):
				previous[n] = here
				queue.append(n)
	return []


## Legs for a ship flying from one system to a planet in another, warping on the way.
func _legs_to_planet(from_index: int, from_px: Vector2, to_index: int, planet: Dictionary) -> Array:
	var path := _path_between(from_index, to_index)
	var legs: Array = []
	var last := from_px / GD.UNIT
	for i in range(path.size() - 1):
		var here: int = path[i]
		var there: int = path[i + 1]
		var out := _exit_between(here, there)
		var back := _exit_between(there, here)
		var back_pos: Vector2 = back["pos"]
		var back_dir: Vector2 = back["dir"]
		legs.append({"kind": "exit", "pos": Vector2(out["pos"]) * GD.UNIT, "to": there, "entry": (back_pos - back_dir * 6.0) * GD.UNIT})
		last = back_pos
	var planet_pos: Vector2 = planet["pos"]
	var approach := planet_pos + (last - planet_pos).normalized() * (float(planet["radius"]) + 1.5)
	legs.append({"kind": "planet", "pos": approach * GD.UNIT})
	return legs


func _update_colonize_prompt() -> void:
	_mark_colony_buttons()
	var p := _colonize_candidate()
	_colony_target = p
	if p.is_empty():
		hud.show_prompt("")
		return
	# Tutorial: colonizing only opens up once Earth has grown to 2 pops.
	var earth: Dictionary = Array(systems[HOME]["planets"])[0]
	if not _colonizing_unlocked():
		hud.show_prompt("")
		return
	_teach_colonize()
	var missing := _colony_missing(fleet_system)
	if missing == "":
		# Ready: the COLONIZE button over the planet says it all; no banner.
		hud.show_prompt("")
	else:
		# Only when you can't yet: a small note saying what's missing.
		hud.show_prompt("Can't colonize %s yet: %s" % [String(p["name"]), missing])


func _colony_missing(target_system: int) -> String:
	var parts: Array = []
	# Colonies need a finished Starbase of yours in the same system.
	if _has_une_starbase(target_system) == Vector2.INF:
		parts.append("needs a Starbase in this system")
	if _colony_source(target_system).is_empty():
		parts.append("needs a planet with 2+ pops")
	if int(amounts["alloys"]) < GD.colony_alloys():
		parts.append("needs {alloys}%d" % GD.colony_alloys())
	if int(amounts["credits"]) < GD.COLONY_CREDITS:
		parts.append("needs {credits}%d" % GD.COLONY_CREDITS)
	return ", ".join(PackedStringArray(parts))


func _try_colonize() -> void:
	if _colonizing_unlocked():
		if not _colony_target.is_empty() and _colony_missing(fleet_system) != "":
			SfxPlayer.ui("deny", -2.0)
		_colonize(_colony_target, fleet_system)


func _colonize(p: Dictionary, target_system: int) -> void:
	if p.is_empty() or p.has("colonizing") or _colony_missing(target_system) != "":
		return
	var source := _colony_source(target_system)
	var src_planet: Dictionary = source["planet"]
	var src_system: int = source["system"]
	amounts["alloys"] = int(amounts["alloys"]) - GD.colony_alloys()
	amounts["credits"] = int(amounts["credits"]) - GD.COLONY_CREDITS
	src_planet["pops"] = int(src_planet["pops"]) - 1
	p["colonizing"] = true
	var start := Vector2(src_planet["pos"]) * GD.UNIT + Vector2(float(src_planet["radius"]) + 1.5, 0) * GD.UNIT
	var ship := ColonyShip.new()
	var view: Node2D = system_views[src_system]
	view.add_child(ship)
	ship.setup(system_views, src_system, start, _legs_to_planet(src_system, start, target_system, p))
	ship.source_planet = src_planet
	ship.source_system = src_system
	ship.target_planet = p
	ship.target_system = target_system
	ship.arrived.connect(_on_colony_arrived)
	ship.returned.connect(_on_colony_returned)
	ship.destroyed.connect(_on_colony_destroyed)
	ship.cancel_requested.connect(_on_colony_cancel)
	SfxPlayer.ui("launch", -2.0)
	ship.hit.connect(_on_civilian_hit)
	colony_ships.append(ship)
	_refresh_hud()
	hud.notify("Colony Ship launched from %s to %s." % [String(src_planet["name"]), String(p["name"])], src_system, start)
	p.erase("colony_button")
	# Anyone hiding near the planet wakes up.
	for child in system_views[target_system].get_children():
		var lurker := child as ShipScript
		if lurker != null and lurker.alive and lurker.role == "hideout":
			lurker.role = ""
			lurker.hold_fire = false
			lurker.attack(kharkiv if kharkiv != null else ship)


func _on_colony_arrived(ship: Node2D) -> void:
	var p: Dictionary = ship.get("target_planet")
	p["colony_progress"] = 0.0
	# It has landed: it can't be shot while it settles.
	ship.remove_from_group("targets")
	ship.visible = false


func _update_colonizing(delta: float) -> void:
	for ship in colony_ships.duplicate():
		if not is_instance_valid(ship):
			colony_ships.erase(ship)
			continue
		var p: Dictionary = ship.get("target_planet")
		if not p.has("colony_progress"):
			continue
		p["colony_progress"] = float(p["colony_progress"]) + delta / (GD.COLONY_SETTLE * GD.colony_settle_mult)
		if float(p["colony_progress"]) >= 1.0:
			p.erase("colony_progress")
			p.erase("colonizing")
			p["owner"] = GD.Faction.UNE
			p["pops"] = int(ship.get("pops"))
			p["growth_progress"] = 0
			p["reward_peak"] = int(p["pops"])
			if tech_cards.has("Planetary Shields"):
				p["shields"] = GD.PLANET_SHIELDS
				p["max_shields"] = GD.PLANET_SHIELDS
			var index := int(ship.get("target_system"))
			_spawn_text(index, p["pos"], ["COLONIZED", "+%d POP" % int(p["pops"])])
			hud.notify("%s is colonized!" % String(p["name"]), index, Vector2(p["pos"]) * GD.UNIT)
			SfxPlayer.ui("fanfare")
			colony_ships.erase(ship)
			ship.queue_free()
			_refresh_hud()
			if hud.current_planet() == p:
				hud.refresh_planet(_planet_income(p))


func _on_colony_cancel(ship: Node2D) -> void:
	var src: Dictionary = ship.get("source_planet")
	var here := int(ship.get("system_index"))
	var p: Dictionary = ship.get("target_planet")
	p.erase("colonizing")
	ship.call("turn_back", _legs_to_planet(here, ship.position, int(ship.get("source_system")), src))
	hud.notify("Colony Ship turning back to %s." % String(src["name"]), here, ship.position)


func _on_colony_returned(ship: Node2D) -> void:
	var src: Dictionary = ship.get("source_planet")
	src["pops"] = mini(int(src["pops"]) + int(ship.get("pops")), int(src["capacity"]))
	_spawn_text(int(ship.get("source_system")), src["pos"], ["+%d POP" % int(ship.get("pops"))])
	colony_ships.erase(ship)
	ship.queue_free()
	_refresh_hud()


func _on_colony_destroyed(ship: Node2D) -> void:
	var p: Dictionary = ship.get("target_planet")
	if not bool(ship.get("returning")):
		p.erase("colonizing")
	colony_ships.erase(ship)
	hud.notify("A Colony Ship was destroyed. Its colonists are lost.", int(ship.get("system_index")), ship.position)


func _on_hauler_destroyed(hauler: Node2D) -> void:
	SfxPlayer.say("convoy", "Our convoys are being raided.", 10.0)
	hud.notify("Our convoys are being raided. A Hauler and its cargo are lost.", int(hauler.get("system_index")), hauler.position)


# --- off-screen warnings -----------------------------------------------------------

func _warn(kind: String, system_index: int, pos_px: Vector2) -> void:
	for w in warnings:
		if String(w["kind"]) == kind and int(w["system"]) == system_index:
			w["pos"] = pos_px
			w["until"] = run_time + GD.WARN_SECONDS
			return
	warnings.append({"kind": kind, "system": system_index, "pos": pos_px, "until": run_time + GD.WARN_SECONDS})
	var cue := {"fleet": "warn_fleet", "hauler": "warn_convoy", "civilian": "warn_convoy"}
	SfxPlayer.ui(String(cue.get(kind, "warn_hit")), -3.0)


func _update_warnings() -> void:
	var size := get_viewport().get_visible_rect().size
	var centre := size * 0.5
	var margin := 70.0
	var shown: Array = []
	for w in warnings.duplicate():
		if float(w["until"]) < run_time:
			warnings.erase(w)
			continue
		var index := int(w["system"])
		var dir := Vector2.ZERO
		if not in_galaxy and index == current:
			var sp := get_viewport().get_canvas_transform() * Vector2(w["pos"])
			if Rect2(Vector2(margin, margin), size - Vector2(margin, margin) * 2.0).has_point(sp):
				continue   # it's on screen: no arrow needed
			dir = sp - centre
		else:
			var here: Vector2 = systems[current]["galaxy_pos"]
			var there: Vector2 = systems[index]["galaxy_pos"]
			dir = there - here if there != here else Vector2.UP
		if dir.length() < 1.0:
			dir = Vector2.UP
		# Push it out to the screen edge along that direction.
		var half := centre - Vector2(margin, margin)
		var stretch := minf(half.x / maxf(absf(dir.x), 0.001), half.y / maxf(absf(dir.y), 0.001))
		shown.append({"kind": w["kind"], "screen": centre + dir * stretch, "angle": dir.angle(), "system": index, "pos": w["pos"]})
	hud.set_warnings(shown)


## Tutorial: colonizing only opens up once Earth has grown to 2 pops.
func _colonizing_unlocked() -> bool:
	var earth: Dictionary = Array(systems[HOME]["planets"])[0]
	return int(earth.get("reward_peak", 0)) >= 2 or int(earth["pops"]) >= 2


## Puts a rocket-landing button over every planet you could colonize (green if you can
## afford it). In Fleet Mode, flying the Kharkiv into it launches the Colony Ship.
func _mark_colony_buttons() -> void:
	var unlocked := _colonizing_unlocked()
	for s in systems:
		var index := int(s["index"])
		var affordable: bool = _colony_missing(index) == "" if unlocked else false
		for p in Array(s["planets"]):
			var eligible: bool = unlocked and p["owner"] == GD.Faction.NEUTRAL and int(p["pops"]) == 0 \
				and int(p["capacity"]) > 0 and String(p["kind"]) != "mars" and not p.has("colonizing")
			if eligible:
				p["colony_button"] = affordable
			else:
				p.erase("colony_button")
	if not fleet_mode or kharkiv == null or warp_state != Warp.NONE:
		return
	var view: Node2D = system_views[fleet_system]
	for p in Array(systems[fleet_system]["planets"]):
		if p.get("colony_button", false) == true:
			var button: Vector2 = view.call("_colony_button_pos", p)
			if kharkiv.position.distance_to(button) < 3.0 * GD.UNIT:
				_colonize(p, fleet_system)
				return


# --- Starbases under attack -------------------------------------------------------

var _starbase_alert_at := -99.0


func _on_starbase_hit(system_index: int, pos_px: Vector2, faction: int) -> void:
	if faction != GD.Faction.UNE:
		return
	_warn("starbase", system_index, pos_px)
	if run_time - _starbase_alert_at > 15.0:
		_starbase_alert_at = run_time
		hud.notify("Space station under attack!", system_index, pos_px)
		SfxPlayer.say("station", "Space station under attack.", 15.0)


var _planet_alert_at := -99.0

## One of your planets is being shot: a warning arrow, and a notice now and then.
func _on_planet_hit(system_index: int, pos_px: Vector2, faction: int, planet: Dictionary) -> void:
	if faction != GD.Faction.UNE:
		return
	_warn("starbase", system_index, pos_px)
	if run_time - _planet_alert_at > 15.0:
		_planet_alert_at = run_time
		var earth := String(planet["kind"]) == "earth"
		hud.notify(("EARTH IS UNDER ATTACK! If it falls, the run is over." if earth else "%s is under attack!" % String(planet["name"])), system_index, pos_px)
		if earth and hud.xander != null:
			hud.xander.call("say", "earth_attack", "Earth is taking fire! If Earth falls, it's game over. Get back there!", "", true)


func _on_starbase_destroyed(system_index: int, structure: Dictionary) -> void:
	_refresh_hud()
	var pos_px: Vector2 = Vector2(structure["pos"]) * GD.UNIT
	var yard := String(structure["type"]) == "shipyard"
	if int(structure["faction"]) == GD.Faction.UNE:
		if yard:
			hud.notify("A Shipyard has been destroyed. Its build queue and repairs are gone.", system_index, pos_px)
		else:
			hud.notify("A Starbase has been destroyed. Its mining and repairs are gone.", system_index, pos_px)
	else:
		hud.notify("Enemy %s destroyed!" % ("Shipyard" if yard else "Starbase"), system_index, pos_px)


## The Kharkiv's secondary weapon name, shown under the reticle while Alt is held.
func _secondary_name() -> String:
	if kharkiv == null:
		return ""
	# Every heavy weapon type in the driven fleet, plus fighters if there's a Carrier.
	var names: Array = []
	var fighters := false
	for ship in fleet:
		if not is_instance_valid(ship) or not ship.driven:
			continue
		if ship.type_id == "carrier":
			fighters = true
		for w in GD.LOADOUTS.get(ship.type_id, []):
			var weapon: Dictionary = GD.WEAPONS[w]
			if GD.is_special(weapon):
				var label := "MAG" if String(weapon["name"]) == "MAG" else ("TORPEDOES" if weapon.has("torpedo") else ("MISSILES" if weapon.has("swarm") else String(weapon["name"]).to_upper()))
				if not names.has(label):
					names.append(label)
	if fighters:
		names.append("FIGHTERS")
	return " + ".join(PackedStringArray(names))



# --- building: station ghosts, the Construction Ship, Shipyard queues ------------------

func _on_build_requested(item_id: String) -> void:
	if GD.STRUCTURES.has(item_id):
		_start_placing(item_id)
	else:
		_order_ship(item_id)


func _input(event: InputEvent) -> void:
	# Placing a station, or right-clicking a ghost to cancel it, comes before everything
	# else on the map (planet clicks, targeting, firing). Clicks on the HUD are left alone.
	var button := event as InputEventMouseButton
	if button == null or not button.pressed or in_galaxy or get_tree().paused:
		return
	if get_viewport().gui_get_hovered_control() != null:
		return
	if placing != "":
		if button.button_index == MOUSE_BUTTON_LEFT:
			_click_block = true
			_place_here()
			get_viewport().set_input_as_handled()
		elif button.button_index == MOUSE_BUTTON_RIGHT:
			_right_block = true
			_cancel_placing()
			get_viewport().set_input_as_handled()
		return
	if button.button_index == MOUSE_BUTTON_RIGHT:
		var site: BuildSite = _site_at(get_global_mouse_position())
		if site != null:
			_right_block = true
			_cancel_site(site)
			get_viewport().set_input_as_handled()


func _cost_text(alloys: int, gas: int) -> String:
	# Shown as resource icons by the HUD and in-world labels.
	var text := "{alloys}%d" % alloys
	if gas > 0:
		text += " {gas}%d" % gas
	return text


func _can_pay(alloys: int, gas: int) -> bool:
	return int(amounts["alloys"]) >= alloys and int(amounts["gas"]) >= gas


func _pay(alloys: int, gas: int) -> void:
	amounts["alloys"] = int(amounts["alloys"]) - alloys
	amounts["gas"] = int(amounts["gas"]) - gas
	_refresh_hud()


func _start_placing(kind: String) -> void:
	_cancel_placing()
	if in_galaxy:
		hud.show_toast("Open a system to place a station.", 2.5)
		return
	var item: Dictionary = GD.STRUCTURES[kind]
	if not _can_pay(int(item["alloys"]), int(item["gas"])):
		SfxPlayer.ui("deny", -2.0)
		hud.show_toast("A %s costs %s." % [item["name"], _cost_text(int(item["alloys"]), int(item["gas"]))], 2.5)
		return
	if _count_une_starbases() + build_sites.size() >= starbase_limit:
		hud.show_toast("Space Station limit reached (%d)." % starbase_limit, 2.5)
		return
	placing = kind
	_place_ghost = BuildSite.new()
	_place_ghost.preview = true
	system_views[current].add_child(_place_ghost)
	_place_ghost.setup(kind, current, get_global_mouse_position())
	if hud.is_build_open():
		hud.toggle_build_menu()
	SfxPlayer.ui("click")


func _cancel_placing() -> void:
	placing = ""
	if _place_ghost != null and is_instance_valid(_place_ghost):
		_place_ghost.queue_free()
	_place_ghost = null


func _update_placing() -> void:
	if placing == "":
		return
	if in_galaxy or _place_ghost == null or not is_instance_valid(_place_ghost) or _place_ghost.get_parent() != system_views[current]:
		_cancel_placing()
		return
	var mouse := get_global_mouse_position()
	_place_ghost.position = mouse
	var problem := _place_problem(placing, current, mouse / GD.UNIT)
	_place_ghost.valid = problem == ""
	_place_ghost.reason = problem


## Tightened Logistics: no boost drain where you have a Starbase and nothing hostile.
func _logistics_free() -> bool:
	if not fleet_cards.has("Tightened Logistics") or kharkiv == null:
		return false
	if _has_une_starbase(fleet_system) == Vector2.INF or _enemy_presence(fleet_system):
		return false
	for child in system_views[fleet_system].get_children():
		if not child.is_in_group("ships") or not (child.get("alive") == true):
			continue
		if child.get("concealed") == true:
			continue
		if GD.is_hostile(GD.Faction.UNE, int(child.get("faction"))):
			return false
	return true


## Enemy stations or planets in a system (Rebel Rock counts until it falls).
## Hidden tech labs don't count: they're secrets, not a claim on the system.
func _enemy_presence(index: int) -> bool:
	var sys: Dictionary = systems[index]
	for st in Array(sys["structures"]):
		if GD.is_hostile(GD.Faction.UNE, int(st["faction"])):
			return true
	for p in Array(sys["planets"]):
		if GD.is_hostile(GD.Faction.UNE, int(p["owner"])):
			return true
	if not Dictionary(sys.get("giant", {})).is_empty() and not waves_over:
		return true
	return false


## Systems you hold: you own a planet or a station there.
func _system_is_ours(index: int) -> bool:
	if not _owns_planet(index).is_empty():
		return true
	for st in Array(systems[index]["structures"]):
		if int(st["faction"]) == GD.Faction.UNE:
			return true
	return false


## Why a station can't go here ("" when it can).
func _place_problem(kind: String, index: int, pos: Vector2) -> String:
	var item: Dictionary = GD.STRUCTURES[kind]
	if not _can_pay(int(item["alloys"]), int(item["gas"])):
		return "NEEDS %s" % _cost_text(int(item["alloys"]), int(item["gas"]))
	if _count_une_starbases() + build_sites.size() >= starbase_limit:
		return "SPACE STATION LIMIT REACHED"
	if _enemy_presence(index):
		return "ENEMY STATIONS OR PLANETS IN THIS SYSTEM"
	if pos.length() < 8.0:
		return "TOO CLOSE TO THE STAR"
	if pos.length() > GD.SYSTEM_RADIUS - 6.0:
		return "TOO CLOSE TO THE EDGE"
	var sys: Dictionary = systems[index]
	for p in Array(sys["planets"]):
		if pos.distance_to(Vector2(p["pos"])) < float(p["radius"]) + 3.0:
			return "TOO CLOSE TO A PLANET"
	for st in Array(sys["structures"]):
		if pos.distance_to(Vector2(st["pos"])) < GD.PLACE_GAP:
			return "TOO CLOSE TO ANOTHER STATION"
	for site in build_sites:
		if int(site.system_index) == index and pos.distance_to(site.position / GD.UNIT) < GD.PLACE_GAP:
			return "TOO CLOSE TO ANOTHER STATION"
	for e in Array(sys["exits"]):
		if pos.distance_to(Vector2(e["pos"])) < GD.WARP_TRIGGER + 2.0:
			return "TOO CLOSE TO A WARP LANE"
	return ""


func _place_here() -> void:
	var mouse := get_global_mouse_position()
	var problem := _place_problem(placing, current, mouse / GD.UNIT)
	if problem != "":
		SfxPlayer.ui("deny", -2.0)
		hud.show_toast(problem.left(1) + problem.substr(1).to_lower(), 2.0)
		return
	var item: Dictionary = GD.STRUCTURES[placing]
	_pay(int(item["alloys"]), int(item["gas"]))
	var site: BuildSite = BuildSite.new()
	system_views[current].add_child(site)
	site.setup(placing, current, mouse)
	site.paid = {"alloys": int(item["alloys"]), "gas": int(item["gas"])}
	build_sites.append(site)
	SfxPlayer.ui("card_land", -4.0)
	hud.show_toast("%s placed. A Construction Ship is on its way." % item["name"], 2.5)
	# Hold Shift to keep placing more of the same.
	var kind := placing
	_cancel_placing()
	if Input.is_key_pressed(KEY_SHIFT):
		_start_placing(kind)


func _site_at(point: Vector2) -> BuildSite:
	for site in build_sites:
		if is_instance_valid(site) and int(site.system_index) == current and site.position.distance_to(point) < 1.6 * GD.UNIT:
			return site
	return null


## Right-click a ghost: full refund before building starts, half after.
func _cancel_site(site: BuildSite) -> void:
	var paid: Dictionary = site.paid
	var share := 1.0 if float(site.progress) <= 0.0 else 0.5
	var alloys := int(floor(int(paid.get("alloys", 0)) * share))
	var gas := int(floor(int(paid.get("gas", 0)) * share))
	amounts["alloys"] = int(amounts["alloys"]) + alloys
	amounts["gas"] = int(amounts["gas"]) + gas
	build_sites.erase(site)
	_release_crew(site)
	site.queue_free()
	_refresh_hud()
	SfxPlayer.ui("click")
	hud.show_toast("%s cancelled. Refunded %s." % [GD.STRUCTURES[site.kind]["name"], _cost_text(alloys, gas)], 2.5)


## Legs for a civilian ship flying from one point to another, warping on the way.
func _legs_to_point(from_index: int, to_index: int, to_px: Vector2) -> Array:
	var path := _path_between(from_index, to_index)
	var legs: Array = []
	for i in range(path.size() - 1):
		var here: int = path[i]
		var there: int = path[i + 1]
		var out := _exit_between(here, there)
		var back := _exit_between(there, here)
		var back_pos: Vector2 = back["pos"]
		var back_dir: Vector2 = back["dir"]
		legs.append({"kind": "exit", "pos": Vector2(out["pos"]) * GD.UNIT, "to": there, "entry": (back_pos - back_dir * 6.0) * GD.UNIT})
	legs.append({"kind": "point", "pos": to_px})
	return legs


## Your Shipyard fewest jumps away from a system: {"system": i, "st": structure}, or {}.
## With several Shipyards, new orders go to the one with the shortest queue
## (nearest to the fleet on a tie), so construction is spread across all of them.
func _least_busy_shipyard() -> Dictionary:
	var best := {}
	var best_len := 999999
	var best_jumps := 999
	for s in systems:
		for st in Array(s["structures"]):
			if st["type"] != "shipyard" or int(st["faction"]) != GD.Faction.UNE:
				continue
			var i := int(s["index"])
			var jumps := 0 if i == fleet_system else _path_between(i, fleet_system).size()
			if i != fleet_system and jumps == 0:
				jumps = 500   # no known route: last choice
			var length := Array(st.get("queue", [])).size()
			if length < best_len or (length == best_len and jumps < best_jumps):
				best_len = length
				best_jumps = jumps
				best = {"system": i, "st": st}
	return best


func _nearest_shipyard(index: int) -> Dictionary:
	var best := {}
	var best_jumps := 999
	for s in systems:
		for st in Array(s["structures"]):
			if st["type"] != "shipyard" or int(st["faction"]) != GD.Faction.UNE:
				continue
			var i := int(s["index"])
			var jumps := 0 if i == index else _path_between(i, index).size()
			if i != index and jumps == 0:
				continue
			if jumps < best_jumps:
				best_jumps = jumps
				best = {"system": i, "st": st}
	return best


func _update_construction(delta: float) -> void:
	for site in build_sites.duplicate():
		if not is_instance_valid(site):
			build_sites.erase(site)
	while _crews.size() < GD.construction_ships:
		_crews.append({"ship": null, "job": null, "home": false, "dock": {}, "respawn": 0.0})
	for crew in _crews:
		if crew["ship"] != null and not is_instance_valid(crew["ship"]):
			crew["ship"] = null
		if crew["job"] != null and (not is_instance_valid(crew["job"]) or not build_sites.has(crew["job"])):
			crew["job"] = null
	# The first N sites in line are worked (N = Construction Ships); the rest wait.
	var active := build_sites.slice(0, mini(build_sites.size(), _crews.size()))
	for i in build_sites.size():
		var later: BuildSite = build_sites[i]
		later.place_in_line = i + 1
		if i >= _crews.size():
			later.status = "waiting"
	for site in active:
		var taken := false
		for crew in _crews:
			if crew["job"] == site:
				taken = true
		if taken:
			continue
		for crew in _crews:
			if crew["job"] == null:
				crew["job"] = site
				crew["home"] = false
				crew["fresh"] = true
				break
	for crew in _crews:
		_run_crew(crew, delta)


## One Construction Ship: launch (after any respawn wait), fly to its site and build it;
## with no job, head back to the nearest Shipyard (or Earth) and be recycled.
func _run_crew(crew: Dictionary, delta: float) -> void:
	var ship: ConstructionShip = crew["ship"]
	var site: BuildSite = crew["job"]
	if site == null:
		if ship != null and not bool(crew["home"]):
			var from := ship.route_from()
			var home := _nearest_shipyard(from)
			var dock := {}
			if not home.is_empty():
				dock = {"system": int(home["system"]), "pos": (Vector2(home["st"]["pos"]) + Vector2(0, 2.0)) * GD.UNIT}
			else:
				var earth: Dictionary = Array(systems[HOME]["planets"])[0]
				if earth["owner"] == GD.Faction.UNE:
					dock = {"system": HOME, "pos": (Vector2(earth["pos"]) + Vector2(0, float(earth["radius"]) + 2.0)) * GD.UNIT}
			crew["dock"] = dock
			if not dock.is_empty():
				ship.go(_legs_to_point(from, int(dock["system"]), Vector2(dock["pos"])))
			crew["home"] = true
		if ship != null and bool(crew["home"]):
			var dock: Dictionary = crew["dock"]
			if dock.is_empty() or ship.is_idle_at(int(dock["system"]), Vector2(dock["pos"])):
				ship.queue_free()   # back home: recycled
				crew["ship"] = null
				crew["home"] = false
		return
	if ship == null:
		if float(crew["respawn"]) > 0.0:
			crew["respawn"] = float(crew["respawn"]) - delta
			site.status = "lost"
			site.respawn_left = float(crew["respawn"])
			return
		var yard := _nearest_shipyard(int(site.system_index))
		var from_system := -1
		var from_pos := Vector2.ZERO
		if not yard.is_empty():
			from_system = int(yard["system"])
			from_pos = Vector2(yard["st"]["pos"]) + Vector2(0, 2.0)
		else:
			# No Shipyard left: Earth sends one instead (as long as Earth is yours).
			var earth: Dictionary = Array(systems[HOME]["planets"])[0]
			if earth["owner"] == GD.Faction.UNE:
				from_system = HOME
				from_pos = Vector2(earth["pos"]) + Vector2(0, float(earth["radius"]) + 2.0)
		if from_system < 0:
			site.status = "no_yard"
			return
		ship = ConstructionShip.new()
		system_views[from_system].add_child(ship)
		ship.setup(system_views, from_system, from_pos * GD.UNIT)
		ship.hit.connect(_on_civilian_hit)
		ship.destroyed.connect(_on_constructor_destroyed)
		crew["ship"] = ship
		crew["fresh"] = true
		SfxPlayer.ui("launch", -4.0)
	crew["home"] = false
	var spot: Vector2 = site.position + Vector2(0, 2.2) * GD.UNIT
	if bool(crew.get("fresh", true)):
		crew["fresh"] = false
		ship.building = false
		ship.go(_legs_to_point(ship.route_from(), int(site.system_index), spot))
	if ship.is_idle_at(int(site.system_index), spot):
		site.status = "building"
		ship.building = true
		ship.site_pos = site.position
		site.progress = float(site.progress) + delta * GD.construct_mult
		if float(site.progress) >= float(site.build_time):
			_finish_site(site)
	else:
		site.status = "enroute"
		site.eta = ship.eta()


func _finish_site(site: BuildSite) -> void:
	var kind := String(site.kind)
	var item: Dictionary = GD.STRUCTURES[kind]
	var index := int(site.system_index)
	var health := float(item["health"]) * (GD.starbase_health_mult if kind == "starbase" else 1.0)
	var st := {"type": kind, "faction": GD.Faction.UNE, "pos": site.position / GD.UNIT, "health": health}
	system_views[index].add_structure(st)
	stations_built += 1
	if kind == "shipyard":
		_share_queues(st)
	build_sites.erase(site)
	site.queue_free()
	_release_crew(site)
	SfxPlayer.ui("reward", -4.0)
	hud.notify("%s complete in %s." % [item["name"], String(systems[index]["name"])], index, st["pos"] * GD.UNIT)
	_refresh_hud()


## The crew working this site lets it go (built or cancelled).
func _release_crew(site: BuildSite) -> void:
	for crew in _crews:
		if crew["job"] == site:
			crew["job"] = null
			var ship: ConstructionShip = crew["ship"]
			if ship != null and is_instance_valid(ship):
				ship.building = false


func _on_constructor_destroyed(ship: Node2D) -> void:
	for crew in _crews:
		if crew["ship"] == ship:
			crew["ship"] = null
			crew["fresh"] = true
			crew["respawn"] = GD.CONSTRUCTION_RESPAWN
	hud.notify("Our Construction Ship was destroyed. A new one launches in %d s." % int(GD.CONSTRUCTION_RESPAWN), int(ship.get("system_index")), ship.position)


## Civilian ships (Haulers, Colony Ships, Construction Ships) under fire.
func _on_civilian_hit(ship: Node2D) -> void:
	var index := int(ship.get("system_index"))
	_warn("civilian", index, ship.position)
	if run_time - _civilian_said_at > 20.0:
		_civilian_said_at = run_time
		SfxPlayer.say("civilian", "Our civilian ships are under attack, commander!", 20.0)
		hud.notify("Our civilian ships are under attack, commander!", index, ship.position)


## Ships ordered from the build menu go into a Shipyard's queue.
func _order_ship(type_id: String) -> void:
	var yard := _least_busy_shipyard()
	if yard.is_empty():
		SfxPlayer.ui("deny", -2.0)
		hud.show_toast("You need a Shipyard to build ships.", 2.5)
		return
	var stats := GD.ship_stats(type_id)
	_count_owned()
	var price := GD.ship_price(type_id)   # scales with how many you have (v0.9.219)
	var alloys := price.x
	var gas := price.y
	var kind := String(GD.SHIPS[type_id]["kind"])
	if not _can_pay(alloys, gas):
		SfxPlayer.ui("deny", -2.0)
		hud.show_toast("A %s costs %s." % [kind, _cost_text(alloys, gas)], 2.5)
		return
	_pay(alloys, gas)
	var st: Dictionary = yard["st"]
	if not st.has("queue"):
		st["queue"] = []
	var queue: Array = st["queue"]
	queue.append({"type": type_id, "left": float(stats["build_time"]) * GD.build_time_mult, "paid_alloys": alloys, "paid_gas": gas})
	_refresh_hud()
	SfxPlayer.ui("click")
	var where := String(systems[int(yard["system"])]["name"])
	if queue.size() <= GD.shipyard_lines:
		hud.show_toast("%s queued at the Shipyard in %s." % [kind, where], 2.0)
	else:
		hud.show_toast("%s queued at the Shipyard in %s (%d waiting)." % [kind, where, queue.size() - GD.shipyard_lines], 2.0)


## A new Shipyard takes over waiting ships from busy Shipyards, so queues even out.
## Ships already being built stay where they are.
func _share_queues(new_yard: Dictionary) -> void:
	if not new_yard.has("queue"):
		new_yard["queue"] = []
	var mine: Array = new_yard["queue"]
	var moved := 0
	var busy := true
	while busy:
		busy = false
		# Take one waiting ship from the yard with the longest queue, if it's worth moving.
		var longest: Array = []
		for s in systems:
			for st in Array(s["structures"]):
				if is_same(st, new_yard) or st["type"] != "shipyard" or int(st["faction"]) != GD.Faction.UNE:
					continue
				var q: Array = st.get("queue", [])
				if q.size() > GD.shipyard_lines and q.size() > longest.size():
					longest = q
		if not longest.is_empty() and longest.size() - mine.size() > 1:
			mine.append(longest.pop_back())
			moved += 1
			busy = true
	if moved > 0:
		hud.show_toast("The new Shipyard took %d ship%s from the other queues." % [moved, "" if moved == 1 else "s"], 3.0)


func _update_shipyards(delta: float) -> void:
	for s in systems:
		var index := int(s["index"])
		for st in Array(s["structures"]):
			if st["type"] != "shipyard" or int(st["faction"]) != GD.Faction.UNE:
				continue
			var queue: Array = st.get("queue", [])
			if queue.is_empty():
				continue
			system_views[index].queue_redraw()
			# The first few ships build side by side: one line, +1 per Space Elevators.
			var done: Array = []
			for i in mini(GD.shipyard_lines, queue.size()):
				var item: Dictionary = queue[i]
				item["left"] = float(item["left"]) - delta
				if float(item["left"]) <= 0.0:
					done.append(item)
			for item in done:
				queue.erase(item)
				_launch_ship(String(item["type"]), index, Vector2(st["pos"]))
			if not done.is_empty():
				hud.show_build_queue(_queue_counts())


## A finished ship rolls out of the Shipyard and waits there until the fleet is in the system.
func _launch_ship(type_id: String, index: int, yard_pos: Vector2) -> void:
	var ship := ShipScript.new()
	system_views[index].add_child(ship)
	var spot := yard_pos + Vector2(randf_range(-2.0, 2.0), 2.5 + randf_range(0.0, 1.5))
	if index == fleet_system:
		# The fleet is here: wait by the Shipyard a moment and join it.
		ship.setup(type_id, GD.Faction.UNE, spot * GD.UNIT, PI * 0.5, "guard")
	else:
		# No fleet here: patrol this system's stations and fight whatever shows up,
		# until the Flagship arrives and picks the ship up.
		ship.setup(type_id, GD.Faction.UNE, spot * GD.UNIT, PI * 0.5, "squad")
	recruits.append({"ship": ship, "system": index})
	# No sound or notification: the Shipyard queue shows progress.


## A loop past every friendly station in the system (pixels). One station: circle it.
func _patrol_route(index: int) -> Array:
	var points: Array = []
	for st in Array(systems[index]["structures"]):
		if int(st["faction"]) == GD.Faction.UNE and (st["type"] == "starbase" or st["type"] == "shipyard"):
			points.append(Vector2(st["pos"]))
	if points.is_empty():
		return []
	if points.size() == 1:
		var c: Vector2 = points[0]
		points.clear()
		for i in 4:
			points.append(c + Vector2.RIGHT.rotated(TAU * i / 4.0) * 10.0)
	else:
		# Visit them in order around the star so the loop doesn't zigzag.
		points.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.angle() < b.angle())
	var route: Array = []
	for p in points:
		route.append(Vector2(p) * GD.UNIT)
	return route


var _patrol_refresh := 0.0
var _squads := {}   # system index -> {"anchor": px, "angle": rad, "heading": rad, "wp": int}


## The main colony a squadron circles: your planet with the most pops in the system.
func _squad_planet(index: int) -> Dictionary:
	var best := {}
	for p in Array(systems[index]["planets"]):
		if p["owner"] == GD.Faction.UNE and (best.is_empty() or int(p["pops"]) > int(best["pops"])):
			best = p
	return best


## Patrol squadrons: every patrol ship in a system flies one triangle (wedge) formation,
## the biggest ship at the point. The formation circles the system's main colony at
## half speed (or loops the stations if there's no colony), pausing while anyone fights.
func _update_squads(delta: float) -> void:
	var by_system := {}
	for r in recruits:
		var ship: ShipScript = r["ship"] if is_instance_valid(r["ship"]) else null
		if ship == null or not ship.alive or ship.role != "squad":
			continue
		var index := int(r["system"])
		if not by_system.has(index):
			by_system[index] = []
		by_system[index].append(ship)
	for index in _squads.keys():
		if not by_system.has(index):
			_squads.erase(index)
	for index in by_system.keys():
		var ships: Array = by_system[index]
		# Biggest first (the point of the wedge); joining order breaks ties.
		ships.sort_custom(func(a: ShipScript, b: ShipScript) -> bool:
			return int(GD.SHIPS[a.type_id]["tier"]) > int(GD.SHIPS[b.type_id]["tier"]))
		var slowest := INF
		var fighting := false
		for s in ships:
			slowest = minf(slowest, float((s as ShipScript).speed_units))
			if (s as ShipScript).is_fighting():
				fighting = true
		var lead: ShipScript = ships[0]
		var planet := _squad_planet(int(index))
		if not _squads.has(index):
			var start := lead.position
			var ang := 0.0
			if not planet.is_empty():
				ang = (start - Vector2(planet["pos"]) * GD.UNIT).angle()
			_squads[index] = {"anchor": start, "angle": ang, "heading": lead.heading, "wp": 0}
		var sq: Dictionary = _squads[index]
		var speed := slowest * GD.UNIT * 0.4   # a little under half so the wings keep up
		if not fighting:
			if not planet.is_empty():
				var centre := Vector2(planet["pos"]) * GD.UNIT
				var radius := (float(planet["radius"]) + 14.0) * GD.UNIT
				sq["angle"] = float(sq["angle"]) + speed * delta / radius
				var a := float(sq["angle"])
				sq["anchor"] = centre + Vector2.RIGHT.rotated(a) * radius
				sq["heading"] = a + PI * 0.5
			else:
				var route := _patrol_route(int(index))
				if not route.is_empty():
					var wp := int(sq["wp"]) % route.size()
					var goal: Vector2 = route[wp]
					var anchor: Vector2 = sq["anchor"]
					var to := goal - anchor
					if to.length() < 2.0 * GD.UNIT:
						sq["wp"] = wp + 1
					elif to.length() > 0.0:
						sq["anchor"] = anchor + to.normalized() * minf(speed * delta, to.length())
						sq["heading"] = lerp_angle(float(sq["heading"]), to.angle(), clampf(delta * 2.0, 0.0, 1.0))
		var anchor_px: Vector2 = sq["anchor"]
		var fwd := Vector2.RIGHT.rotated(float(sq["heading"]))
		var side := fwd.orthogonal()
		var spacing := 4.0 * GD.UNIT
		for i in ships.size():
			var row := floori((i + 1) / 2.0)
			var side_sign := -1.0 if i % 2 == 1 else 1.0
			var offset := Vector2.ZERO if i == 0 else (-fwd * row * spacing + side * side_sign * row * spacing * 0.8)
			(ships[i] as ShipScript).squad_slot = anchor_px + offset


func _update_recruits() -> void:
	_update_squads(get_process_delta_time())
	# Patrol routes follow stations being built or lost.
	_patrol_refresh -= get_process_delta_time()
	if _patrol_refresh <= 0.0:
		_patrol_refresh = 3.0
		for r in recruits:
			var patroller = r["ship"]
			if is_instance_valid(patroller) and String(patroller.role) == "patrol":
				patroller.route = _patrol_route(int(r["system"]))
	if kharkiv == null or warp_state != Warp.NONE:
		return
	var joined := false
	for r in recruits.duplicate():
		var ship: ShipScript = r["ship"] if is_instance_valid(r["ship"]) else null
		if ship == null or not ship.alive:
			recruits.erase(r)
			continue
		if int(r["system"]) != fleet_system:
			continue
		recruits.erase(r)
		ship.role = ""
		ship.cruise = 1.0
		ship.squad_slot = Vector2.INF
		ship.driven = false
		fleet.append(ship)
		ship.destroyed.connect(_on_fleet_ship_destroyed)
		returning.append(ship)
		joined = true
	if joined:
		_remember_formation()
		# Everyone eases into the new formation instead of snapping.
		for ship in fleet:
			if ship != kharkiv and ship.driven and not ship.escorting:
				ship.driven = false
				if not returning.has(ship):
					returning.append(ship)



# --- movement tech and Kharkiv weapons ------------------------------------------------

## Blink Drive: the formation jumps the way it's moving, as far as a full boost would take it.
func _blink() -> void:
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if dir == Vector2.ZERO:
		return
	var view: Node2D = system_views[fleet_system]
	var from := kharkiv.position
	# Half as far as a full boost would have flown the fleet (boosted top speed for a
	# whole meter, bigger with boost-capacity cards). Was the full distance before v0.9.123.
	var reach := kharkiv.speed_units * GD.UNIT * GD.BOOST_MULT * GD.BOOST_MAX * GD.boost_capacity_mult * GD.BLINK_REACH
	var to := from + dir.normalized() * reach
	var limit := (GD.SYSTEM_RADIUS - 4.0) * GD.UNIT
	if to.length() > limit:
		to = to.normalized() * limit
	var shift := to - from
	var ghosts: Array = []
	for ship in fleet:
		if is_instance_valid(ship) and ship.driven:
			ghosts.append([ship.position, ship.heading, GD.ship_pixels(ship.type_id)])
			ship.position += shift
	overlay.position = kharkiv.position
	fleet_velocity = dir.normalized() * maxf(fleet_velocity.length(), kharkiv.speed_units * GD.UNIT)
	for at in [from, to]:
		var flash := BlinkFlash.new()
		view.add_child(flash)
		flash.setup(at, 5.0 * GD.UNIT, Color("8fd1ff"))
	SfxPlayer.play("warp_jump", kharkiv, -9.0, 0.05)
	if GD.afterimage:
		var ghost := Afterimage.new()
		view.add_child(ghost)
		ghost.setup(from, ghosts)
		# Enemies already shooting at the fleet switch to the ghost for a moment.
		for child in view.get_children():
			var enemy := child as ShipScript
			if enemy != null and enemy.alive and GD.is_hostile(GD.Faction.UNE, enemy.faction) and enemy.position.distance_to(from) < 60.0 * GD.UNIT:
				enemy.attack(ghost)


## Hot Exit: a pulse when the fleet drops out of warp.
func _hot_exit(view: Node2D, centre: Vector2) -> void:
	var flash := BlinkFlash.new()
	view.add_child(flash)
	flash.setup(centre, GD.HOT_EXIT_RANGE * GD.UNIT, Color("ff8a3d"), 0.7)
	SfxPlayer.play("mag_fire", null, -6.0)
	for child in view.get_children():
		var enemy := child as ShipScript
		if enemy == null or not enemy.alive or not GD.is_hostile(GD.Faction.UNE, enemy.faction):
			continue
		if enemy.position.distance_to(centre) <= GD.HOT_EXIT_RANGE * GD.UNIT:
			enemy.take_damage(GD.HOT_EXIT_DAMAGE, kharkiv)
			GD.damage_dealt += GD.HOT_EXIT_DAMAGE
			enemy.slow(4.0, 0.5)


## Mine Layer: the Kharkiv drops a mine behind it every few seconds while moving.
## Too many out at once: the oldest fizzles.
func _update_mines(delta: float) -> void:
	if GD.mine_cap <= 0 or kharkiv == null or warp_state == Warp.TRANSIT or warp_state == Warp.LOCKED:
		return
	_mine_timer -= delta
	if _mine_timer > 0.0 or fleet_velocity.length() < 2.0 * GD.UNIT:
		return
	_mine_timer = GD.MINE_EVERY
	for m in mines.duplicate():
		if not is_instance_valid(m):
			mines.erase(m)
	while mines.size() >= GD.mine_cap:
		var oldest: Node2D = mines.pop_front()
		oldest.call("fizzle")
	var mine := Mine.new()
	system_views[fleet_system].add_child(mine)
	mine.setup(kharkiv.position - fleet_velocity.normalized() * GD.ship_pixels("capital"), GD.mine_damage)
	mines.append(mine)



## Asteroid Force Fields: yielding asteroids inside your Starbase orbits can't be destroyed.
## Re-checked every second, so new Starbases and lost ones take effect quickly.
func _refresh_rock_shields() -> void:
	if not GD.asteroid_shields:
		return
	for s in systems:
		var index := int(s["index"])
		var bases: Array = []
		for st in Array(s["structures"]):
			if st["type"] == "starbase" and int(st["faction"]) == GD.Faction.UNE:
				bases.append(Vector2(st["pos"]))
		var orbit := GD.STARBASE_ORBIT * GD.orbit_multiplier
		for rock in system_views[index].call("asteroids"):
			var yields := int(rock.get("yield_alloys")) + int(rock.get("yield_gas")) > 0
			var inside := false
			if yields:
				var at: Vector2 = rock.position / GD.UNIT
				for b in bases:
					if at.distance_to(b) <= orbit:
						inside = true
						break
			if rock.get("shielded") != inside:
				rock.set("shielded", inside)



## The economy guide, as a big card at the start of the run.
func _show_guide() -> void:
	card_open = {"type": "guide"}
	get_tree().paused = true
	hud.show_economy_guide()


func _on_guide_closed() -> void:
	card_open = {}
	get_tree().paused = false
	call_deferred("_show_next_card")



## Zoomed in near a Starbase or Shipyard: faint beeps and machinery.
func _update_station_sound() -> void:
	var level := 0.0
	if not in_galaxy and camera.zoom.x > 0.7:
		var zoom_part := clampf((camera.zoom.x - 0.7) / 0.6, 0.0, 1.0)
		var centre := camera.position / GD.UNIT
		for st in Array(systems[current]["structures"]):
			if st["type"] != "starbase" and st["type"] != "shipyard":
				continue
			var d := centre.distance_to(Vector2(st["pos"]))
			var near := clampf(1.0 - (d - 8.0) / 20.0, 0.0, 1.0)
			level = maxf(level, near * zoom_part)
	SfxPlayer.set_station_level(level)



## Damage Control: ships out of the fight patch themselves up wherever they are.
func _damage_control(delta: float) -> void:
	if not GD.damage_control:
		return
	for ship in fleet:
		if not is_instance_valid(ship) or not ship.alive or not ship.is_damaged() or ship._since_hit < 5.0:
			continue
		ship.repair(0.01 * delta)
		var t := float(ship.get_meta("dc_plus_t", 0.0)) + delta
		if t >= 0.6 and ship.visible:
			t = 0.0
			var plus := RepairPlus.new()
			ship.get_parent().add_child(plus)
			var r := GD.ship_pixels(ship.type_id)
			plus.setup(ship.position + Vector2(randf_range(-r, r) * 0.6, -r * 0.6))
		ship.set_meta("dc_plus_t", t)
