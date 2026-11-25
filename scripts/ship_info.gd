extends RefCounted
## Ship and station info for tooltips: names, roles, a short description, traits,
## stats and weapons, plus a tiny looping animation of how each one fights.
## Used by the build menu (hover a button) and the fleet status panel (hover a ship).

const GD = preload("res://scripts/game_data.gd")

## Silhouettes, nose up, matching the in-game models (ship_models.gd).
const SHAPES := {
	"corvette": [[0.0, -0.95], [-0.171, -0.684], [-0.285, -0.342], [-0.285, -0.152], [-0.437, -0.095], [-0.437, 0.247], [-0.285, 0.304], [-0.285, 0.741], [-0.209, 0.855], [0.0, 0.855], [0.209, 0.855], [0.285, 0.741], [0.285, 0.304], [0.437, 0.247], [0.437, -0.095], [0.285, -0.152], [0.285, -0.342], [0.171, -0.684]],
	"frigate": [[0.0, -0.399], [-0.133, -0.494], [-0.133, -0.95], [-0.418, -0.95], [-0.494, -0.285], [-0.38, 0.095], [-0.456, 0.665], [-0.285, 0.874], [0.0, 0.874], [0.285, 0.874], [0.456, 0.665], [0.38, 0.095], [0.494, -0.285], [0.418, -0.95], [0.133, -0.95], [0.133, -0.494]],
	"destroyer": [[0.0, -0.931], [-0.085, -0.931], [-0.104, -0.817], [-0.142, -0.76], [-0.142, -0.589], [-0.104, -0.532], [-0.104, -0.399], [-0.152, -0.342], [-0.152, -0.114], [-0.285, -0.019], [-0.323, 0.304], [-0.532, 0.522], [-0.532, 0.741], [-0.285, 0.684], [-0.228, 0.931], [0.0, 0.931], [0.228, 0.931], [0.285, 0.684], [0.532, 0.741], [0.532, 0.522], [0.323, 0.304], [0.285, -0.019], [0.152, -0.114], [0.152, -0.342], [0.104, -0.399], [0.104, -0.532], [0.142, -0.589], [0.142, -0.76], [0.104, -0.817], [0.085, -0.931]],
	"cruiser": [[0.0, -0.95], [-0.19, -0.589], [-0.247, -0.399], [-0.589, -0.399], [-0.589, 0.399], [-0.304, 0.456], [-0.285, 0.817], [-0.152, 0.912], [0.0, 0.912], [0.152, 0.912], [0.285, 0.817], [0.304, 0.456], [0.589, 0.399], [0.589, -0.399], [0.247, -0.399], [0.19, -0.589]],
	"carrier": [[-0.342, -0.95], [0.342, -0.95], [0.475, -0.779], [0.475, -0.228], [0.665, -0.19], [0.665, 0.342], [0.475, 0.38], [0.475, 0.902], [-0.475, 0.902], [-0.475, -0.779]],
	"battleship": [[0.0, -0.95], [-0.152, -0.95], [-0.38, -0.722], [-0.418, -0.304], [-0.608, -0.228], [-0.608, 0.399], [-0.418, 0.494], [-0.399, 0.855], [-0.209, 0.95], [0.0, 0.95], [0.209, 0.95], [0.399, 0.855], [0.418, 0.494], [0.608, 0.399], [0.608, -0.228], [0.418, -0.304], [0.38, -0.722], [0.152, -0.95]],
	"capital": [[0.0, -0.95], [-0.19, -0.798], [-0.285, -0.418], [-0.456, -0.342], [-0.456, 0.342], [-0.323, 0.418], [-0.342, 0.741], [-0.513, 0.893], [-0.513, 0.95], [0.0, 0.95], [0.513, 0.95], [0.513, 0.893], [0.342, 0.741], [0.323, 0.418], [0.456, 0.342], [0.456, -0.342], [0.285, -0.418], [0.19, -0.798]],
	"colony": [[0, -0.8], [0.35, -0.4], [0.35, 0.6], [0, 0.85], [-0.35, 0.6], [-0.35, -0.4]],
}
const SIZES := {"corvette": 0.55, "frigate": 0.65, "destroyer": 0.75, "cruiser": 0.82, "carrier": 0.88, "battleship": 0.92, "capital": 1.0, "colony": 0.55}

const ROLES := {
	"corvette": ["Raider", "Cheap, quick and fragile. Swarms in for close attack runs, then peels away.", ["Fast", "Small: Gatlings deal +50% to it", "Attack runs"]],
	"frigate": ["Anti Large", "Launches a slow homing torpedo that hits hard on contact. Its PDC swats fighters and missiles up close.", ["Small", "Torpedo: 500 blast at the centre", "Torpedoes can be shot down"]],
	"destroyer": ["Big-Ship Hunter", "Charges a Mini MAG for one big, accurate shot that hits bigger ships hardest. A PDC swats fighters and missiles.", ["Medium", "Mini MAG: 250, +50% vs Medium and Large", "Point defence"]],
	"cruiser": ["Swarm Missiles & Flak", "Radar-sweeps a wedge, locks on and fires a salvo of Swarm Missiles from long range. A Flak cannon guards it up close.", ["Medium", "+50% range on every weapon", "4 big-blast missiles a salvo"]],
	"carrier": ["What do you think it does???", "Launches a wing of 4 VALK Zero fighters from its bay. Hold Alt and click to send them at a target.", ["Large", "1 wing of 4 fighters", "Needs Gas"]],
	"battleship": ["Tank & MAG", "A MAG cannon that hits for 500, four Gatlings and a mountain of armor. Slow, and worth it.", ["Large", "Very heavy armor", "Needs Gas"]],
	"capital": ["Flagship", "The Kharkiv. Your command ship: lose it and the run is over.", ["Large", "Armor hardening: 1 less damage per hit", "Leads the fleet"]],
	"colony": ["Colony Ship", "Carries settlers to an empty planet. Unarmed, so keep it out of trouble.", ["Unarmed", "Slow"]],
	"fighter": ["Fighter", "VALK Zero: launched in wings of 3, dodges half of all direct shots.", ["Small", "50% dodge"]],
}

const STATIONS := {
	"starbase": ["Space station", "Collects alloys and gas from asteroids inside its orbit (Haulers carry them home). Heavily armed at double range.", ["2 Gatlings, 4 PDCs", "1 fighter wing", "Repairs itself out of combat"]],
	"shipyard": ["Ship factory", "Builds ships from the build menu, and repairs your ships inside its green ring.", ["Repairs nearby ships", "Builds in parallel with more Space Elevators"]],
	"mag": ["Siege gun", "One huge cannon: charges, then fires an 800-damage piercing slug at the strongest enemy ship in the system, every 8 s.", ["Reaches the whole system", "Big outer blast", "Uses a station slot"]],
}

## Everything else you can find in a system: [title, role, description, traits].
## (Silver and gold asteroids are left out on purpose. Some things stay a mystery.)
const ENTITIES := {
	"asteroid_plain": ["ASTEROID", "Plain rock", "Nothing worth mining here. Shoot it if it's in the way: nobody will miss it.", ["No yield", "Only focus fire hurts it"]],
	"asteroid_alloys": ["ALLOY ASTEROID", "Resource rock", "Rich in Alloys. Inside a Starbase's orbit it pays out every day, and Haulers carry the haul home.", ["Mined by Starbases", "Shoot it and the Alloys are gone", "A new rock drifts in to replace it"]],
	"asteroid_gas": ["GAS ASTEROID", "Resource rock", "Vents Gas, the rare resource big ships and stations need. Mine it with a Starbase.", ["Mined by Starbases", "Shoot it and the Gas is gone", "A new rock drifts in to replace it"]],
	"rebel_base": ["THE REBEL ROCK", "Roid Rebels' stronghold", "A giant asteroid fortress with a Mini MAG and 8 Gatlings. Hit it once and every Rebel in the system comes for you.", ["Wakes the whole system", "Destroy it to break the Rebels"]],
	"tech_base": ["DERELICT TECH LAB", "Abandoned research base", "Glass-dome labs on a drifting rock. Order an attack on it to crack it open for a Tech reward.", ["Only hit when you target it", "Drops a Tech reward"]],
	"hauler": ["HAULER", "Civilian freighter", "Carries a Starbase's haul to your nearest planet, warping between systems if it has to.", ["Unarmed", "Lost with its cargo if destroyed"]],
	"colony_ship": ["COLONY SHIP", "Settlers", "Carrying pops to a new world. Once it lands, settling takes a while.", ["Unarmed", "Slow"]],
	"construction_ship": ["CONSTRUCTION SHIP", "Civilian builder", "Launches from a Shipyard and welds your placed stations together, one after another.", ["Unarmed", "Corvette-tough"]],
	"mine": ["MINE", "From the Kharkiv's Mine Layer", "Arms after a second, then launches at the first enemy ship that comes close.", ["150-damage blast", "Hurts every enemy in the blast"]],
	"arms_dealer": ["ARMS DEALER", "Neutral trader", "Sells Fleet cards for Credits, no questions asked. Fly your fleet into its orbit to shop.", ["Neutral", "Restocks for a price"]],
	"pickup_fleet": ["FLEET CARD", "Salvage", "A Fleet card floating free. Fly the fleet over it to pick it up (it costs Credits).", ["Collect by flying over it"]],
	"pickup_tech": ["TECH CHIP", "Salvage", "A Tech card on a data chip. Fly the fleet over it to pick it up, free.", ["Collect by flying over it"]],
	"pd_mag": ["PD MAG FORTRESS", "Planetary defence", "A planet-mounted MAG: charges, then fires 650-damage shots at enemies up to 56 units away.", ["Leads moving ships", "Never wastes a shot on missiles"]],
	"planet_earth": ["EARTH", "UNE capital", "Home. It grows pops, earns income every day and offers Growth Rewards as it grows.", ["Your capital", "Grows pops"]],
	"planet_mars": ["MARS", "Sons of Philip stronghold", "Philip's fortress world: 3,000 health and a PD MAG. Take it to win the run.", ["Fires a PD MAG", "Taking it wins the run"]],
	"planet_yours": ["PLANET", "Your colony", "One of your worlds: it grows pops, earns income every day and offers Growth Rewards.", ["Grows pops", "Pick a building as it grows"]],
	"planet_enemy": ["PLANET", "Enemy world", "Held by the enemy and defended. Take it back.", ["Defended"]],
	"planet_open": ["PLANET", "Uncolonized", "Empty and habitable. Fly the Kharkiv into the rocket button above it to settle it.", ["Can be colonized", "Costs 1 pop, Alloys and Credits"]],
	"planet_dead": ["PLANET", "Uninhabitable", "Nothing can live here. Lovely view, though.", ["Can't be colonized"]],
	"gas_giant": ["GAS GIANT", "Gas source", "A huge ball of gas. A Starbase in orbit can siphon Gas from it.", ["Starbases here give Gas"]],
}

const WEAPON_NOTES := {
	"gatling": "rapid fire, +50% vs small",
	"torpedo": "homing, big blast",
	"mini_mag": "charged heavy shot",
	"pdc": "point defence",
	"flak": "airburst shells",
	"swarm": "radar-locked salvo",
	"mag": "500 dmg charged slug",
	"fighter_gun": "fighter cannon",
}


## Rough damage per second of a ship type's loadout (for the build-card meters).
static func ship_dps(type_id: String) -> float:
	var total := 0.0
	var loadout: Array = GD.LOADOUTS.get(type_id, []).duplicate()
	loadout.append_array(Array(GD.extra_weapons.get(type_id, [])))
	for w in loadout:
		var weapon: Dictionary = GD.WEAPONS[w]
		if weapon.has("swarm"):
			total += float(weapon["damage"]) * float(weapon["missiles"]) / (float(weapon["cooldown"]) + float(weapon["sweep"]))
		elif weapon.has("damage"):
			total += float(weapon["damage"]) * float(weapon.get("burst", 1)) / maxf(float(weapon["cooldown"]), 0.1)
	if type_id == "carrier":
		total += 2.0 * 40.0   # two fighter wings, roughly
	return total


static func ship_toughness(type_id: String) -> float:
	var s := GD.ship_stats(type_id)
	return float(s["hull"]) + float(s["armor"])


static func ship_range(type_id: String) -> float:
	var best := 0.0
	for w in GD.LOADOUTS.get(type_id, []):
		best = maxf(best, float(GD.WEAPONS[w].get("range", 0.0)) * float(GD.SHIP_RANGE_MULT.get(type_id, 1.0)))
	if type_id == "carrier":
		best = maxf(best, float(GD.WEAPONS["bay"]["range"]))
	return best


## A ship's rating out of 10 for one stat, next to the other warships.
static func meter(type_id: String, stat: String) -> int:
	var best := 0.0
	var mine := 0.0
	for t in ["corvette", "frigate", "destroyer", "cruiser", "carrier", "battleship", "capital"]:
		var v := _stat(t, stat)
		best = maxf(best, v)
		if t == type_id:
			mine = v
	if type_id not in ["corvette", "frigate", "destroyer", "cruiser", "carrier", "battleship", "capital"]:
		mine = _stat(type_id, stat)
	return clampi(int(ceil(10.0 * mine / maxf(best, 0.01))), 1, 10)


static func _stat(type_id: String, stat: String) -> float:
	match stat:
		"firepower":
			return ship_dps(type_id)
		"toughness":
			return ship_toughness(type_id)
		"speed":
			return float(GD.ship_stats(type_id)["speed"])
		"range":
			return ship_range(type_id)
	return 0.0


## The weapons a ship type carries (with refit extras): [[count, name, note], ...].
static func weapon_entries(type_id: String) -> Array:
	var counts := {}
	var order: Array = []
	var loadout: Array = GD.LOADOUTS.get(type_id, []).duplicate()
	loadout.append_array(Array(GD.extra_weapons.get(type_id, [])))
	for w in loadout:
		if not counts.has(w):
			counts[w] = 0
			order.append(w)
		counts[w] = int(counts[w]) + 1
	var out: Array = []
	for w in order:
		out.append([int(counts[w]), String(GD.WEAPONS[w]["name"]), String(WEAPON_NOTES.get(w, ""))])
	if type_id == "carrier":
		out.append([2, "Fighter Bay", "wings of 3 VALK Zeros"])
	return out


## The weapon list as "2x K9 Gatling Gun (rapid fire...)".
static func weapon_lines(type_id: String) -> Array:
	var counts := {}
	var order: Array = []
	for w in GD.LOADOUTS.get(type_id, []):
		if not counts.has(w):
			counts[w] = 0
			order.append(w)
		counts[w] = int(counts[w]) + 1
	var out: Array = []
	for w in order:
		var weapon: Dictionary = GD.WEAPONS[w]
		var line := "%s%s" % ["%dx " % int(counts[w]) if int(counts[w]) > 1 else "", String(weapon["name"])]
		if WEAPON_NOTES.has(w):
			line += "  ·  " + String(WEAPON_NOTES[w])
		out.append(line)
	if type_id == "carrier":
		out.append("2x Fighter Bay  ·  wings of 3 VALK Zeros")
	return out


## A tooltip card for a ship type or station. live: a ship in your fleet, for its
## current health (null for the build menu, which shows the full numbers).
class Card extends PanelContainer:
	const GDATA = preload("res://scripts/game_data.gd")
	var _demo: Control = null

	## extra: {"title": "...", "lines": ["...", ...]} for things like planets.
	func _init(item_id: String, live: Node = null, with_demo: bool = true, extra: Dictionary = {}) -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		z_index = 50
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.1, 0.115, 0.13, 0.97)
		style.set_border_width_all(2)
		style.border_width_top = 3
		style.border_color = Color("8a939c")
		style.set_corner_radius_all(4)
		style.shadow_color = Color(0, 0, 0, 0.55)
		style.shadow_size = 14
		style.shadow_offset = Vector2(0, 6)
		style.content_margin_left = 18
		style.content_margin_right = 18
		style.content_margin_top = 14
		style.content_margin_bottom = 16
		add_theme_stylebox_override("panel", style)
		custom_minimum_size = Vector2(300, 0)
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 11)
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(box)
		var data = load("res://scripts/ship_info.gd")
		var is_ship := GDATA.SHIPS.has(item_id)
		var is_station := GDATA.STRUCTURES.has(item_id)
		var has_live := live != null and is_instance_valid(live)
		var role: Array = ["", "", []]
		var title := ""
		if is_ship:
			role = data.ROLES.get(item_id, role)
			var info: Dictionary = GDATA.SHIPS[item_id]
			title = String(info["kind"]).to_upper()
			if String(info["name"]) != "":
				title += "  \"%s\"" % String(info["name"])
		elif is_station:
			role = data.STATIONS.get(item_id, role)
			title = String(GDATA.STRUCTURES[item_id]["name"]).to_upper()
		else:
			var e: Array = data.ENTITIES.get(item_id, ["?", "", "", []])
			title = String(e[0])
			role = [e[1], e[2], e[3]]
		if extra.has("title"):
			title = String(extra["title"])
		_add(box, title, 18, Color("f0c35a"))
		var role_text := String(role[0])
		if has_live and (is_ship or is_station) and live.get("faction") != null:
			# Whose it is.
			var f := int(live.get("faction"))
			if f != GDATA.Faction.NEUTRAL:
				var owner := "Yours" if f == GDATA.Faction.UNE else ("Sons of Philip" if f == GDATA.Faction.SONS else "Rebels")
				role_text += "  ·  " + owner
		_add(box, role_text, 17, Color("8fb4e3"))
		if with_demo and (is_ship or is_station):
			_demo = data.Demo.new()
			_demo.set("kind", item_id)
			_demo.custom_minimum_size = Vector2(272, 92)
			box.add_child(_demo)
		var blurb := _add(box, String(role[1]), 14, Color("d5dbe0"))
		blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		blurb.custom_minimum_size = Vector2(272, 0)
		blurb.add_theme_constant_override("line_spacing", 6)
		# How it stacks up against the other warships, out of ten.
		if is_ship and item_id != "fighter" and item_id != "colony":
			var meters := VBoxContainer.new()
			meters.add_theme_constant_override("separation", 6)
			meters.mouse_filter = Control.MOUSE_FILTER_IGNORE
			box.add_child(meters)
			for stat in [["firepower", "Firepower"], ["toughness", "Toughness"], ["speed", "Speed"], ["range", "Range"]]:
				var m = data.Meter.new()
				m.set("label", String(stat[1]))
				m.set("stat", String(stat[0]))
				m.set("value", int(data.meter(item_id, String(stat[0]))))
				m.custom_minimum_size = Vector2(272, 20)
				meters.add_child(m)
		# Stats.
		var stats_line := ""
		if is_ship:
			if has_live:
				stats_line = "Hull %d/%d   Armor %d/%d" % [int(live.get("hull")), int(live.get("max_hull")), int(live.get("armor")), int(live.get("max_armor"))]
				if float(live.get("max_shields")) > 0.0:
					stats_line += "   Shields %d" % int(live.get("shields"))
				stats_line += "   Speed %.0f" % float(live.get("speed_units"))
			else:
				var s := GDATA.ship_stats(item_id)
				stats_line = "Hull %d   Armor %d   Speed %.0f" % [int(float(s["hull"]) * GDATA.hull_mult), int(float(s["armor"]) * GDATA.armor_mult), float(s["speed"]) * GDATA.speed_mult]
				if GDATA.shield_bonus > 0.0:
					stats_line += "   Shields %d" % int(GDATA.shield_bonus)
		elif has_live and live.get("health") != null and live.get("max_health") != null:
			stats_line = "Health %d/%d" % [int(maxf(0.0, float(live.get("health")))), int(live.get("max_health"))]
		elif is_station:
			stats_line = "Health %d" % int(GDATA.STRUCTURES[item_id].get("health", GDATA.STARBASE_HEALTH))
		if stats_line != "":
			_add(box, stats_line, 13, Color("3dd17a"))
		# Traits: Armor Hardening gets its own shiny badge and a plain-words line.
		if is_ship:
			var hard := float(GDATA.ship_stats(item_id).get("armor_hardening", 0.0))
			if hard > 0.0:
				_add_trait(box, data.HardeningIcon.new(), "ARMOR HARDENING +%d" % int(hard),
					"Every hit on its armor does %d less damage. Shrugs off small, fast guns like Gatlings, PDCs and flak." % int(hard))
		# Your ships' record: kills and the damage they've actually landed on enemy ships.
		if is_ship and has_live and live.get("kills") != null and live.get("faction") == GDATA.Faction.UNE:
			var record := "Kills %d   ·   Damage dealt %s" % [int(live.get("kills")), _thousands(int(float(live.get("damage_done"))))]
			_add(box, record, 14, Color("f0c35a"))
		for line in Array(extra.get("lines", [])):
			_add(box, String(line), 13, Color("e9e6dc"))
		if is_ship:
			# Weapons get their own block: a header, then one bold row per weapon.
			var entries: Array = data.weapon_entries(item_id)
			if not entries.is_empty():
				var block := PanelContainer.new()
				var inset := StyleBoxFlat.new()
				inset.bg_color = Color(0.05, 0.06, 0.08, 0.95)
				inset.border_color = Color("8a939c")
				inset.border_width_left = 3
				inset.set_corner_radius_all(3)
				inset.content_margin_left = 10
				inset.content_margin_right = 8
				inset.content_margin_top = 6
				inset.content_margin_bottom = 8
				block.add_theme_stylebox_override("panel", inset)
				block.mouse_filter = Control.MOUSE_FILTER_IGNORE
				box.add_child(block)
				var rows := VBoxContainer.new()
				rows.add_theme_constant_override("separation", 8)
				rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
				block.add_child(rows)
				# Your ships list each weapon's damage dealt on the right.
				var split = null
				if has_live and live.get("faction") == GDATA.Faction.UNE:
					split = live.get("damage_by_weapon")
				_add(rows, "WEAPONS" + ("   ·   DAMAGE DEALT" if split is Dictionary else ""), 12, Color("8a939c"))
				for e in entries:
					var row := HBoxContainer.new()
					row.add_theme_constant_override("separation", 8)
					row.mouse_filter = Control.MOUSE_FILTER_IGNORE
					rows.add_child(row)
					var count := _add(row, "%dx" % int(e[0]), 17, Color("f0c35a"))
					count.custom_minimum_size = Vector2(30, 0)
					var name_box := VBoxContainer.new()
					name_box.add_theme_constant_override("separation", 0)
					name_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
					row.add_child(name_box)
					_add(name_box, String(e[1]), 17, Color("f4efe2"))
					if String(e[2]) != "":
						_add(name_box, String(e[2]), 12, Color("93a3ad"))
					# Your ships: what this weapon has actually landed on enemy ships.
					if split is Dictionary and String(e[1]) != "Fighter Bay":   # fighters keep their own records
						var gap := Control.new()
						gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
						gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
						row.add_child(gap)
						var dealt := _add(row, _thousands(int(float((split as Dictionary).get(String(e[1]), 0.0)))), 16, Color("f0c35a"))
						dealt.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
				if split is Dictionary and float((split as Dictionary).get("Other", 0.0)) >= 1.0:
					_add(rows, "Other (rams, blasts): %s" % _thousands(int(float((split as Dictionary)["Other"]))), 12, Color("93a3ad"))
		for t in Array(role[2]):
			_add(box, "◆ " + String(t), 12, Color("aeb9c6"))

	## A trait row: badge on the left, gold name and a short grey description beside it.
	## Hovering the row (when the card can be hovered) shows the description as a tooltip.
	func _add_trait(box: Control, icon: Control, title: String, words: String) -> void:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		row.tooltip_text = "%s\n%s" % [title, words]
		row.mouse_filter = Control.MOUSE_FILTER_PASS
		box.add_child(row)
		icon.custom_minimum_size = Vector2(34, 38)
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(icon)
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 1)
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(col)
		_add(col, title, 14, Color("f0c35a"))
		var line := _add(col, words, 12, Color("aeb9c6"))
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		line.custom_minimum_size = Vector2(250, 0)

	## 12345 -> "12,345".
	func _thousands(n: int) -> String:
		var digits := str(absi(n))
		var out := ""
		while digits.length() > 3:
			out = "," + digits.substr(digits.length() - 3) + out
			digits = digits.substr(0, digits.length() - 3)
		return ("-" if n < 0 else "") + digits + out

	func _add(box: Control, text: String, size: int, colour: Color) -> Label:
		var label := Label.new()
		label.text = text
		label.add_theme_font_size_override("font_size", size)
		label.add_theme_color_override("font_color", colour)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(label)
		return label


## A tiny looping cartoon of how a ship or station fights.
class Demo extends Control:
	var kind := ""
	var _t := 0.0
	const BLUE := Color("5b8fd6")
	const RED := Color("e5484d")
	const GOLD := Color("f0c35a")
	const AMBER := Color("ffb347")

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _ship(at: Vector2, length: float, facing: float, colour: Color) -> void:
		var d := Vector2.RIGHT.rotated(facing)
		var n := d.orthogonal()
		var pts := PackedVector2Array([at + d * length, at - d * length * 0.7 + n * length * 0.5, at - d * length * 0.4, at - d * length * 0.7 - n * length * 0.5])
		draw_colored_polygon(pts, colour)
		pts.append(pts[0])
		draw_polyline(pts, Color(0, 0, 0, 0.8), 2.0)

	func _boom(at: Vector2, t: float, r: float) -> void:
		if t < 0.0 or t > 1.0:
			return
		draw_circle(at, r * (0.3 + t), Color(1.0, 0.6, 0.25, 0.8 * (1.0 - t)))
		draw_circle(at, r * 0.5 * (1.0 - t), Color(1.0, 0.95, 0.8, 1.0 - t))

	func _draw() -> void:
		var w := size.x
		var h := size.y
		draw_rect(Rect2(Vector2.ZERO, size), Color("0b1018"))
		for i: int in 7:
			draw_line(Vector2(0, i * 16.0), Vector2(w, i * 16.0), Color(0.3, 0.5, 0.7, 0.06), 1.5)
		var mid := h * 0.5
		var cyc := 4.0   # slow, readable loops
		var t := fmod(_t, cyc) / cyc
		match kind:
			"corvette":
				# Attack runs: dart in, burst, peel away.
				var foe := Vector2(w - 40, mid)
				_ship(foe, 14, PI, RED)
				var a := t * TAU
				var at := foe + Vector2(-70 * cos(a) - 20, 28 * sin(a))
				_ship(at, 8, (foe - at).angle() if cos(a) > 0.0 else a + PI * 0.5, BLUE)
				if cos(a) > 0.6:
					for i: int in 3:
						var p := at.lerp(foe, fmod(_t * 3.0 + i * 0.33, 1.0))
						draw_line(p, p + (foe - at).normalized() * 5.0, GOLD, 2.0)
			"frigate":
				var me := Vector2(40, mid + 10)
				var foe := Vector2(w - 40, mid - 10)
				_ship(me, 12, 0.0, BLUE)
				_ship(foe, 14, PI, RED)
				if t < 0.7:
					var u := t / 0.7
					var p := me.lerp(foe, u) + Vector2(0, -sin(u * PI) * 28.0)
					draw_circle(p, 3.0, Color("ff6a3d"))
					draw_circle(p, 6.0, Color(1.0, 0.4, 0.2, 0.3))
				else:
					_boom(foe, (t - 0.7) / 0.3, 22.0)
			"destroyer":
				var me := Vector2(40, mid)
				var foe := Vector2(w - 40, mid)
				_ship(me, 13, 0.0, BLUE)
				_ship(foe, 14, PI, RED)
				if t < 0.6:
					draw_circle(me + Vector2(14, 0), 2.0 + 6.0 * t / 0.6, Color(0.55, 0.8, 1.0, 0.7))
				elif t < 0.75:
					draw_line(me + Vector2(14, 0), foe, Color(0.75, 0.9, 1.0), 3.0)
				else:
					_boom(foe, (t - 0.75) / 0.25, 14.0)
				# PDC swatting a small craft.
				var bug := Vector2(70 + 30 * sin(_t * 3.0), mid - 30)
				draw_circle(bug, 2.5, RED)
				if fmod(_t, 0.5) < 0.1:
					draw_line(me, bug, Color(0.8, 0.8, 0.85, 0.7), 1.5)
			"cruiser":
				var me := Vector2(36, mid)
				_ship(me, 13, 0.0, BLUE)
				var foes := [Vector2(w - 50, mid - 26), Vector2(w - 30, mid), Vector2(w - 56, mid + 26)]
				for f in foes:
					_ship(f, 8, PI, RED)
				if t < 0.4:
					var beam := lerpf(-0.6, 0.6, t / 0.4)
					var pts := PackedVector2Array([me])
					for j: int in 9:
						pts.append(me + Vector2.RIGHT.rotated(lerpf(-0.6, beam, float(j) / 8.0)) * (w - 40))
					draw_colored_polygon(pts, Color(0.35, 1.0, 0.5, 0.06))
					draw_line(me, me + Vector2.RIGHT.rotated(beam) * (w - 40), Color(0.35, 1.0, 0.5, 0.4), 1.5)
				else:
					var u := (t - 0.4) / 0.6
					for i: int in 6:
						var f: Vector2 = foes[i % 3]
						var side := -1.0 if i % 2 == 0 else 1.0
						var p := me.lerp(f, u) + Vector2(0, side * sin(u * PI) * (14.0 + i * 3.0))
						if u < 0.95:
							draw_circle(p, 1.8, Color(0.62, 0.88, 1.0))
					for f in foes:
						draw_arc(f, 11, 0, TAU, 16, Color(0.35, 1.0, 0.5, 0.5), 1.5)
			"carrier":
				var me := Vector2(40, mid)
				var foe := Vector2(w - 40, mid)
				draw_rect(Rect2(me - Vector2(18, 9), Vector2(36, 18)), BLUE)
				_ship(foe, 14, PI, RED)
				for i: int in 3:
					var a := _t * 2.0 + i * 0.5
					var p := foe + Vector2(cos(a) * 30, sin(a) * 22)
					if t < 0.3:
						p = me.lerp(p, t / 0.3)
					_ship(p, 4, a + PI * 0.5, Color("8fd1ff"))
			"battleship", "capital":
				var me := Vector2(56, mid)
				_ship(me, 22 if kind == "capital" else 19, 0.0, BLUE)
				if kind == "capital":
					for o in [Vector2(30, -22), Vector2(30, 22), Vector2(-10, -30), Vector2(-10, 30)]:
						_ship(me + Vector2(o), 6, 0.0, Color("8fb4e3"))
				var foe := Vector2(w - 36, mid)
				_ship(foe, 13, PI, RED)
				for i: int in 4:
					var p := me.lerp(foe, fmod(_t * 1.5 + i * 0.25, 1.0)) + Vector2(0, (i - 1.5) * 4.0)
					draw_line(p, p + Vector2(6, 0), GOLD, 2.0)
				if t > 0.5 and t < 0.6:
					draw_line(me + Vector2(20, 0), foe, Color(0.75, 0.9, 1.0), 3.5)
				_boom(foe, (t - 0.6) / 0.3, 18.0)
			"colony":
				var planet := Vector2(w - 46, mid)
				draw_circle(planet, 26, Color("2a78b8"))
				draw_circle(planet + Vector2(-6, -5), 9, Color("4f9a48"))
				_ship(Vector2(30, mid).lerp(planet - Vector2(30, 0), t), 8, 0.0, Color("d9a441"))
			"starbase":
				# Rocks slowly circling inside the orbit; a Hauler eases one load home.
				var c := Vector2(w * 0.58, mid)
				draw_circle(c, 36, Color(0.35, 0.55, 1.0, 0.05))
				draw_arc(c, 36, 0, TAU, 40, Color(0.35, 0.55, 1.0, 0.45), 2.0)
				draw_arc(c, 10, 0, TAU, 20, Color("8e98a3"), 4.0)
				draw_circle(c, 5, BLUE)
				for i: int in 4:
					var a := TAU * i / 4.0 + 0.6 + _t * 0.12
					draw_circle(c + Vector2(cos(a), sin(a)) * 25, 4, Color("8e8478"))
				var e := t * t * (3.0 - 2.0 * t)   # ease in and out
				var hauler := (c + Vector2(-20, 6)).lerp(Vector2(16, mid + 6), e)
				var fade := 1.0 - clampf((t - 0.85) / 0.15, 0.0, 1.0)
				draw_rect(Rect2(hauler - Vector2(5, 3), Vector2(10, 6)), Color(0.85, 0.64, 0.25, fade))
				draw_rect(Rect2(hauler + Vector2(5, -2), Vector2(5, 4)), Color(0.68, 0.73, 0.78, fade))
			"shipyard":
				# Left: a hull being built in the dock, a steady welding spark along it.
				var dock := Vector2(w * 0.3, mid)
				draw_rect(Rect2(dock - Vector2(44, 17), Vector2(88, 4)), Color("8e98a3"))
				draw_rect(Rect2(dock + Vector2(-44, 13), Vector2(88, 4)), Color("8e98a3"))
				var built := clampf(t / 0.85, 0.0, 1.0)
				_ship(dock, 6.0 + 14.0 * built, 0.0, Color(BLUE, 0.35 + 0.65 * built))
				if built < 1.0:
					var spark := dock + Vector2(-12.0 + 24.0 * built, -5.0 + 3.0 * sin(_t * 2.0))
					draw_circle(spark, 3.5, Color(1.0, 0.75, 0.35, 0.35))
					draw_circle(spark, 1.8, Color(1.0, 0.95, 0.75))
				# Right: a damaged ship inside the green repair ring, "+" signs rising.
				var yard := Vector2(w * 0.76, mid)
				draw_circle(yard, 34, Color(0.24, 0.82, 0.48, 0.07))
				draw_arc(yard, 34, 0, TAU, 40, Color(0.24, 0.82, 0.48, 0.55), 2.0)
				_ship(yard, 11, -0.3, BLUE)
				for i: int in 3:
					var u := fmod(_t * 0.45 + i / 3.0, 1.0)
					var at := yard + Vector2(-12.0 + i * 12.0, 4.0 - 30.0 * u)
					var c := Color(0.24, 0.82, 0.48, 1.0 - u)
					draw_line(at - Vector2(3.5, 0), at + Vector2(3.5, 0), c, 2.0)
					draw_line(at - Vector2(0, 3.5), at + Vector2(0, 3.5), c, 2.0)
			"mag":
				var c := Vector2(40, mid)
				draw_circle(c, 14, Color("3a434d"))
				draw_line(c, c + Vector2(24, 0), Color("c3cad1"), 5.0)
				var foe := Vector2(w - 40, mid)
				_ship(foe, 18, PI, RED)
				if t < 0.6:
					draw_circle(c + Vector2(24, 0), 3.0 + 8.0 * t / 0.6, Color(0.55, 0.8, 1.0, 0.7))
				elif t < 0.72:
					draw_line(c + Vector2(24, 0), foe, Color(0.8, 0.92, 1.0), 6.0)
				else:
					_boom(foe, (t - 0.72) / 0.28, 30.0)
			_:
				pass
		draw_rect(Rect2(Vector2.ZERO, size), Color("3a4552"), false, 1.0)


## A small silhouette for build buttons: ships nose-up, stations as little glyphs.
class Icon extends Control:
	var kind := ""
	var holo := false   # build menu: drawn as a green tactical-display wireframe (v0.9.193)

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var c := size / 2.0
		var r := minf(size.x, size.y) * 0.45
		var ink := Color("c9d2d8")
		if holo:
			_draw_holo(c, r)
			return
		var data = load("res://scripts/ship_info.gd")
		var shapes: Dictionary = data.SHAPES
		var sizes: Dictionary = data.SIZES
		if shapes.has(kind):
			var s := r * float(sizes.get(kind, 0.7))
			var pts := PackedVector2Array()
			for p in shapes[kind]:
				pts.append(c + Vector2(float(p[0]), float(p[1])) * s)
			draw_colored_polygon(pts, Color(0.36, 0.56, 0.84, 0.45))
			pts.append(pts[0])
			draw_polyline(pts, ink, 2.0)
		elif kind == "starbase":
			draw_arc(c, r * 0.8, 0, TAU, 24, ink, 3.0)
			draw_circle(c, r * 0.3, Color(0.36, 0.56, 0.84))
			for i: int in 4:
				var d := Vector2.RIGHT.rotated(PI * 0.25 + i * PI * 0.5)
				draw_line(c + d * r * 0.3, c + d * r * 0.8, ink, 2.0)
		elif kind == "shipyard":
			draw_rect(Rect2(c + Vector2(-r, -r * 0.55), Vector2(r * 2.0, r * 0.25)), ink)
			draw_rect(Rect2(c + Vector2(-r, r * 0.3), Vector2(r * 2.0, r * 0.25)), ink)
			draw_rect(Rect2(c + Vector2(-r * 1.1, -r * 0.6), Vector2(r * 0.35, r * 1.2)), Color("f0c35a"))
		elif kind == "mag":
			draw_circle(c + Vector2(-r * 0.2, r * 0.2), r * 0.55, Color("3a434d"))
			draw_arc(c + Vector2(-r * 0.2, r * 0.2), r * 0.55, 0, TAU, 20, ink, 2.0)
			draw_line(c + Vector2(-r * 0.2, r * 0.2), c + Vector2(r, -r * 0.7), ink, 4.0)

	## Like the title screen's tactical display: a soft green glow, a faint fill and a
	## crisp green outline.
	func _draw_holo(c: Vector2, r: float) -> void:
		var g := Color("3dd17a")
		var fill := Color(g, 0.16)
		var glow := Color(g, 0.22)
		var data = load("res://scripts/ship_info.gd")
		var shapes: Dictionary = data.SHAPES
		var sizes: Dictionary = data.SIZES
		if shapes.has(kind):
			var s := r * float(sizes.get(kind, 0.7))
			var pts := PackedVector2Array()
			for p in shapes[kind]:
				pts.append(c + Vector2(float(p[0]), float(p[1])) * s)
			draw_colored_polygon(pts, fill)
			pts.append(pts[0])
			draw_polyline(pts, glow, 6.0, true)
			draw_polyline(pts, g, 1.8, true)
			draw_line(c + Vector2(0, -0.8) * s, c + Vector2(0, 0.8) * s, Color(g, 0.55), 1.2, true)
		elif kind == "starbase":
			draw_circle(c, r * 0.8, fill)
			draw_arc(c, r * 0.8, 0, TAU, 32, glow, 6.0, true)
			draw_arc(c, r * 0.8, 0, TAU, 32, g, 1.8, true)
			for i: int in 4:
				var d := Vector2.RIGHT.rotated(PI * 0.25 + i * PI * 0.5)
				draw_line(c + d * r * 0.3, c + d * r * 0.8, Color(g, 0.6), 1.5, true)
			draw_circle(c, r * 0.25, Color(g, 0.9))
		elif kind == "shipyard":
			for y in [-0.55, 0.3]:
				var bar := Rect2(c + Vector2(-r, r * float(y)), Vector2(r * 2.0, r * 0.25))
				draw_rect(bar, fill)
				draw_rect(bar, g, false, 1.5)
			var gantry := Rect2(c + Vector2(-r * 1.1, -r * 0.6), Vector2(r * 0.35, r * 1.2))
			draw_rect(gantry, Color(g, 0.3))
			draw_rect(gantry, g, false, 1.5)
		elif kind == "mag":
			var hub := c + Vector2(-r * 0.2, r * 0.2)
			draw_circle(hub, r * 0.55, fill)
			draw_arc(hub, r * 0.55, 0, TAU, 24, glow, 6.0, true)
			draw_arc(hub, r * 0.55, 0, TAU, 24, g, 1.8, true)
			draw_line(hub, c + Vector2(r, -r * 0.7), g, 3.5, true)


## One stat row on a ship card: the name, then a segmented bar out of ten, like a
## MOBA health bar (dark trough, coloured filled segments, thin dividers, a sheen).
class Meter extends Control:
	var label := ""
	var stat := ""
	var value := 0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var font := ThemeDB.fallback_font
		draw_string(font, Vector2(0, 15), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("aeb9c6"))
		var bar := Rect2(Vector2(92, 3), Vector2(size.x - 96, 14))
		var colour := Color("3dd17a")   # green, the same for every stat
		# Trough with a dark frame.
		draw_rect(Rect2(bar.position - Vector2(2, 2), bar.size + Vector2(4, 4)), Color("05070a"))
		draw_rect(bar, Color(0.09, 0.1, 0.12))
		var seg := bar.size.x / 10.0
		for i in 10:
			var r := Rect2(bar.position + Vector2(i * seg, 0), Vector2(seg, bar.size.y))
			if i < value:
				draw_rect(r, colour.darkened(0.15))
				draw_rect(Rect2(r.position, Vector2(r.size.x, r.size.y * 0.45)), colour.lightened(0.2))   # sheen
			if i > 0:
				draw_line(r.position, r.position + Vector2(0, r.size.y), Color(0, 0, 0, 0.85), 1.5)
		draw_rect(bar, Color(0, 0, 0, 0.6), false, 1.0)



## Armor Hardening badge: a polished steel shield with a gold rim, a bright bevel, a
## "+" stamped in the middle and a glint that sweeps across it every couple of seconds.
class HardeningIcon extends Control:
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _shield(w: float, h: float, inset: float) -> PackedVector2Array:
		var pts := PackedVector2Array()
		var cx := w / 2.0
		var top := inset
		var side := w / 2.0 - inset
		# Flat-ish top with rounded shoulders, sides curving in to a point at the bottom.
		pts.append(Vector2(cx, top + 2.0))
		pts.append(Vector2(cx + side * 0.55, top))
		pts.append(Vector2(cx + side, top + h * 0.08))
		for i in 9:
			var t := float(i + 1) / 9.0
			var x := cx + side * (1.0 - t * t)
			var y := top + h * 0.08 + (h - inset * 2.0 - h * 0.08) * t
			pts.append(Vector2(x, y))
		for i in range(1, 10):   # back up the left side (skipping the shared bottom point)
			var t := 1.0 - float(i) / 9.0
			var x := cx - side * (1.0 - t * t)
			var y := top + h * 0.08 + (h - inset * 2.0 - h * 0.08) * t
			pts.append(Vector2(x, y))
		pts.append(Vector2(cx - side * 0.55, top))
		return pts

	func _draw() -> void:
		var w := size.x
		var h := size.y
		var outer := _shield(w, h, 1.0)
		var inner := _shield(w, h, 4.0)
		# Gold rim, then the steel face: lit on the left, darker on the right.
		draw_colored_polygon(outer, Color("b8892e"))
		draw_colored_polygon(inner, Color("5f7a93"))
		var half := PackedVector2Array([Vector2(w / 2.0, -1.0), Vector2(w + 1.0, -1.0), Vector2(w + 1.0, h + 1.0), Vector2(w / 2.0, h + 1.0)])
		for poly in Geometry2D.intersect_polygons(inner, half):
			draw_colored_polygon(poly, Color("3f5468"))
		# Bevel highlight down the left shoulder.
		var bevel := PackedVector2Array([Vector2(w * 0.5, 6.0), Vector2(w * 0.22, 7.0), Vector2(w * 0.2, h * 0.45), Vector2(w * 0.32, h * 0.62), Vector2(w * 0.5, h * 0.8)])
		draw_colored_polygon(bevel, Color(1, 1, 1, 0.18))
		# The "+" plate.
		var c := Vector2(w / 2.0, h * 0.44)
		draw_rect(Rect2(c - Vector2(2.5, 8.0), Vector2(5.0, 16.0)), Color("f4efe2"))
		draw_rect(Rect2(c - Vector2(8.0, 2.5), Vector2(16.0, 5.0)), Color("f4efe2"))
		draw_rect(Rect2(c - Vector2(2.5, 8.0), Vector2(5.0, 16.0)), Color("b8892e"), false, 1.0)
		draw_rect(Rect2(c - Vector2(8.0, 2.5), Vector2(16.0, 5.0)), Color("b8892e"), false, 1.0)
		# The glint: a bright diagonal band sweeping across, clipped to the face.
		var phase := fmod(_t, 2.4) / 1.0
		if phase < 1.0:
			var x := lerpf(-w * 0.4, w * 1.2, phase)
			var strip := PackedVector2Array([Vector2(x - 4.0, 0.0), Vector2(x + 4.0, 0.0), Vector2(x - 6.0, h), Vector2(x - 14.0, h)])
			var clipped := Geometry2D.intersect_polygons(inner, strip)
			for poly in clipped:
				draw_colored_polygon(poly, Color(1, 1, 1, 0.55 * sin(phase * PI)))
		draw_polyline(outer + PackedVector2Array([outer[0]]), Color("f0c35a"), 1.5, true)
