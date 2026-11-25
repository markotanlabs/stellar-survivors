extends RefCounted
## Tuning numbers for the prototype, taken from the design brief.
## Change values here rather than in the other scripts.

const UNIT := 32.0             # pixels per range unit at default zoom
const SYSTEM_RADIUS := 120.0   # units from centre to boundary
const EXIT_OUT := 6.0          # the green warp arrows are drawn this far outside the boundary (v0.9.208)
const MIN_SPACING := 40.0      # units between points of interest (bigger planets need more room)
const TICK_SECONDS := 10.0     # economy tick
const STARBASE_LIMIT := 3   # was 5 (v0.9.227): you start with 2 of 3
const STARBASE_ORBIT := 15.6   # units; covers most of one asteroid field (was 12, +30% in v0.9.234)
const ROCK_ARMOR := 3.0   # asteroids: every hit does 3 less damage, never below 1 (v0.9.145)
const ALLOY_SCALE := 5     # v0.9.237: every Alloy number x5 (income, yields, prices) so whole-number upkeep stays fair
const START_ALLOYS := 20 * ALLOY_SCALE   # 100 (was 20)
## Testing: start every run with TEST_START of Alloys, Gas and $ (set to 0 for normal starts).
const TEST_START := 0

enum Faction { UNE, REBELS, SONS, NEUTRAL }

## True while Space is held: labels show full names instead of short codes.
static var show_full_names := false
## True while Space (info) is held: ships draw faint weapon range rings.
static var show_ranges := false

## Grows with the Extended Orbits Tech card.
static var orbit_multiplier := 1.0

## Fleet-wide bonuses for UNE ships, from Fleet cards and Fleet Academies.
static var armor_mult := 1.0
static var hull_mult := 1.0
static var shield_bonus := 0.0
static var speed_mult := 1.0
static var cooldown_mult := 1.0
static var damage_bonus := 0.0
static var starbase_mini_mags := 0   # Mini MAG Batteries: Mini MAGs on each of your Starbases (1 per card, up to 3)
static var starbase_repairs := false   # Starbases don't repair ships by default (a future card can turn it on)

const GROWTH_BASE := 3            # a new pop costs GROWTH_BASE + current pops growth steps
const RAM_DAMAGE := 0.5           # share of max health the smaller ship loses when hostile ships collide
const ROCK_CASH := {"rock": 1, "gas": 1, "silver": 25, "gold": 50}
const STARBASE_HEALTH := 3000.0
# Planet traits (v0.9.219): shown in the planet window. More (rarer, stranger) ones later;
# for now every planet is Hard as Rock.
const PLANET_TRAITS := {
	"Hard as Rock": "Takes 50% less damage from every hit, shields or not.",
}
const HARD_AS_ROCK := 0.5      # damage multiplier on planets with Hard as Rock
# Ships get pricier the more of a type you have (v0.9.219): +10% Alloys and Gas for every
# one of that type you own or have queued. Losing ships brings the price back down.
const SHIP_PRICE_STEP := 0.10
const SHIP_PRICE_EASE := 45.0   # seconds for the price to drop by one ship's worth after you lose one (v0.9.228)
# Fleet upkeep: whole Alloys per warship per day (v0.9.230). The Kharkiv, fighters and
# civilian ships are free. (The -30% Alloy cut of v0.9.228 was reverted.)
const SHIP_UPKEEP := {"corvette": 1, "frigate": 2, "destroyer": 2, "cruiser": 3, "carrier": 4, "battleship": 5}   # v0.9.235
const PLANET_HEALTH := STARBASE_HEALTH   # every settled planet (Earth, colonies, Mars); Earth falling loses the run
const STARBASE_RANGE_MULT := 2.0   # Starbases are bastions: every Starbase weapon reaches twice as far
const STARBASE_MINI_MAG_RANGE := 1.5   # ...except Mini MAGs: +50% range (was x2, v0.9.154)
const MAG_CANNON_REACH := 240.0   # units: the MAG Cannon reaches across its whole system (SYSTEM_RADIUS x2; was 90)
const STARBASE_GUNS := ["gatling", "gatling", "pdc", "pdc", "pdc", "pdc"]
const STARBASE_BAYS := 1           # Fighter Bays per Starbase: one wing of 4 fighters
const CARRIER_BAYS := 1            # Fighter Bays per Carrier (was 2, v0.9.118; same 80-unit reach as a Starbase bay)
const FIGHTER_GROUP := 4            # fighters per wing, every bay alike: Carriers and Starbases (was 3, v0.9.118)
const FIGHTER_REBUILD := 15.0      # seconds to rebuild each lost fighter (was 5)
const FIGHTER_EVADE := 0.5         # chance a direct shot misses a fighter (explosions, splash and mines always hit)
const FIGHTER_AMMO := 10           # attacks (bursts) per sortie; then the fighter flies home to rearm
const FIGHTER_SORTIE := 40.0       # safety cap: no sortie lasts longer than this
const STARBASE_HARDNESS := 1.0
const SELF_REPAIR := 0.025         # space stations and planets repair 2.5% of max health a second with no enemies in the system (ships repair at Shipyards)
const DAMAGE_NUMBER_MIN := 0.0    # every hit pops a number (a Settings toggle will turn them off)
static var show_damage_numbers := true
static var show_abbrev_names := false   # Settings > Abbreviated Ship Names: codes over ships all the time
static var show_damage_taken := false   # numbers for damage YOU take (off by default; Settings later)
const REPAIR_KIT_CHANCE := 0.25   # a rich (silver/gold) asteroid drops a Repair Kit instead of a Fleet Card
const PLANET_SHIELDS := 500.0
const GROUP_AGGRO := 14.0        # units: enemies this close to a ship that's hit join the fight
const DAMAGE_TALLY := 0.35       # seconds: small hits on one target add up into one number
const AUTO_SPREAD := 1.8          # automatic fire scatters this much more than hand-aimed fire
## Philip's shield wall (Destroyers v0.9.131, Battleships v0.9.132): a big shield that
## only covers an arc in front of the ship, hardened 50% (5 points). Hits from outside
## the arc skip it. MAGs punch straight through it into armor and hull, though the
## hardening still halves them while the shield is up.
const SONS_DESTROYER_SHIELDS := 600.0     # was 300 (v0.9.132)
const SONS_BATTLESHIP_SHIELDS := 600.0
const SONS_DESTROYER_SHIELD_HARDENING := 5.0
const SONS_SHIELD_ARC := 70.0             # degrees either side of the nose (a 140-degree arc)
const SHIELD_HARDENING_STEP := 0.1  # each point of shield hardening cuts damage 10% while shields are up
const SLUG_SPLASH := 1.0           # units: MAG-family slugs splash the edges of the hit (was 1.5; ships got bigger, v0.9.150)
const SLUG_HITBOX := 1.5           # MAG-family slug hitbox vs a normal shot's (was 2.0, v0.9.150)
const SLUG_SPLASH_SHARE := 0.3     # splash does 30% of the hit to anything else nearby     # flat damage taken off every hit on a Starbase
const SHOT_REACH := 1.3            # missed shots fly on to 1.3x their weapon range, then vanish (was 2.5)
const MAG_TRAVEL_MULT := 2.0       # MAG-family slugs (Mini MAG, MAG, MAG Cannon, PD MAG) fly twice as far; engagement range unchanged
const RESPAWN_DELAY_MIN := 4.5    # seconds before a destroyed asteroid starts drifting back in (x1.5, v0.9.240)
const RESPAWN_DELAY_MAX := 15.0
const SHOT_ROCK_RESPAWN_MULT := 1.3   # a mining rock you shot (and cashed in) takes 30% longer to come back
const AIM_JITTER := 0.25          # units of extra scatter on hand-aimed shots
const NOTIFY_SECONDS := 10.0
const COLONY_ALLOYS := 50         # colonizing costs 1 pop from the launching planet, 50 Alloys and $20 (x5, v0.9.237)
const COLONY_CREDITS := 20
const COLONY_SPEED := 6.0         # units per second: slower than any warship
const COLONY_SETTLE := 30.0       # seconds to settle once it arrives (can't be interrupted for now)
const COLONY_MARK_RANGE := 8.0    # how close to a planet's surface the Kharkiv must be to mark it
const WAVE_FIRST := 120.0         # Rebel waves: the first at 2:00, then every 2 minutes,
const WAVE_GAP := 120.0           # each up to 20 s late (never early), 6 Corvettes +3 per wave
const WAVE_LATE := 20.0
const WAVE_BASE := 6
const WAVE_STEP := 3
const WAVE_START := 6       # Rebel wave 1 (was 8)
const WAVE_GROWTH := 4      # wave 2 adds 4, wave 3 adds 5, wave 4 adds 6... (v0.9.223 balance pass;
							# was doubling twice then +12: 8, 16, 32, 44, 56)
const WAVE_FRIGATE_SHARE := 0.25   # Frigates per Corvette in a wave (was 0.35)
const ASTEROID_SCALE := 1.2   # every asteroid drawn and collided 20% bigger (v0.9.223)
const PHILIP_OPENER := 24    # points in Philip's first wave; each wave after doubles
const PHILIP_FIRST_AT := 600.0   # Philip wakes and strikes at 10:00, or earlier if Rebel Rock falls first


## Corvettes in Rebel wave n (0 = the first): 6, 10, 15, 21, 28, 36, 45, 55...
## A steadily steeper ramp instead of the old early doublings (v0.9.223).
static func rebel_wave_count(n: int) -> int:
	return WAVE_START + WAVE_GROWTH * n + n * (n - 1) / 2


## Corvettes in Rebel wave n: the base count (8, 16, 32, 44, 56...).
static func rebel_wave_corvettes(n: int) -> int:
	return rebel_wave_count(n)


## Frigates mixed into Rebel wave n. They make up the firepower the Corvettes lost when
## they went down to one Gatling (about a third of a Frigate per Corvette), and teach
## torpedoes from the first wave: 3, 6, 11, 15, 20...
static func rebel_wave_frigates(n: int) -> int:
	return maxi(1, int(round(rebel_wave_count(n) * WAVE_FRIGATE_SHARE)))   # 2, 3, 4, 5, 7, 9, 11, 14...
const WARN_SECONDS := 8.0         # how long an off-screen warning stays up
const XP_FIRST := 15              # XP for the first Fleet card, doubling after
const HAULER_SPEED := 9.0         # units per second (half a Small ship)
const HAULER_CAPACITY := 5        # containers per Hauler
# Civilian ships (Haulers, Colony Ships, Construction Ships) are as tough as a Corvette.
const CIVILIAN_HULL := 50.0
const CIVILIAN_ARMOR := 100.0
const CONSTRUCTION_SPEED := 9.0   # units per second, like a Hauler
const CONSTRUCTION_RESPAWN := 5.0 # seconds before a lost Construction Ship is replaced
const PLACE_GAP := 4.0            # units kept clear between stations
# Space stations you can place from the build menu (B).
const STRUCTURES := {
	"starbase": {"name": "Starbase", "alloys": 200, "gas": 0, "time": 20.0, "health": STARBASE_HEALTH},
	"shipyard": {"name": "Shipyard", "alloys": 125, "gas": 0, "time": 15.0, "health": 500.0},
	"mag": {"name": "MAG Cannon", "alloys": 250, "gas": 10, "time": 20.0, "health": 1500.0},   # uses a station slot (was 30 Alloys + 1 Gas; v0.9.182)
}
const SHIELD_RECHARGE := 3.0      # shields per second...
const SHIELD_DELAY := 10.0        # ...after this long without taking damage
const CHARGE_AFTER := 3.0         # seconds under unanswered fire before an AI ship charges

const GAIN_COLOUR := "3dd17a"   # floating "+3 ALLOYS" text

# size: 0 = Small, 1 = Medium, 2 = Large
const SHIPS := {
	"corvette":   {"code": "C",  "name": "Greyhound",  "kind": "Corvette",     "tier": 1, "size": 0},
	"frigate":    {"code": "F",  "name": "Kris",       "kind": "Frigate",      "tier": 2, "size": 0},
	"destroyer":  {"code": "D",  "name": "Ghost",      "kind": "Destroyer",    "tier": 3, "size": 1},
	"cruiser":    {"code": "CR", "name": "Myles",      "kind": "Cruiser",      "tier": 4, "size": 1},
	"carrier":    {"code": "CA", "name": "Akagi",      "kind": "Carrier",      "tier": 5, "size": 2},
	"battleship": {"code": "B",  "name": "MAGnus",     "kind": "Battleship",   "tier": 6, "size": 2},
	"capital":    {"code": "K",  "name": "Kharkiv",    "kind": "Capital Ship", "tier": 0, "size": 2},
	"colony":     {"code": "CO", "name": "",           "kind": "Colony Ship",  "tier": 0, "size": 0},
	"fighter":    {"code": "FT", "name": "VALK Zero",  "kind": "Fighter",      "tier": 0, "size": 0},
}

const SIZE_SPEED := [22.5, 14.4, 11.7]   # units per second (tripled in the speed rework)

# Booster (hold Shift in Fleet Mode)
const BOOST_MULT := 2.0      # speed multiplier while boosting
const BOOST_MAX := 6.0       # seconds of boost in a full meter (was 3)
const BOOST_DELAY := 2.0     # seconds after letting go before it refills
const BOOST_REFILL := 2.0    # seconds to refill from empty (was 4)

# Warp travel
const AMBUSH_REACH := 16.0   # units: hidden Rebels spring on your ships this close
const WARP_TRIGGER := 7.0    # units from a warp arrow that starts a charge
const WARP_GRACE := 1.5      # seconds you can still move (and cancel)
const WARP_LOCK := 1.5       # seconds locked in place before the jump
const WARP_TRANSIT := 3.0    # seconds flying the warplane between systems
const REDRAW_BASE := 50   # credits for the first card Redraw in a run; doubles each time

## Space stations (Starbase, Shipyard, MAG Cannon) drawn and hit 25% bigger (v0.9.137).
const STATION_SCALE := 1.25

## Some hulls reach further with every weapon they carry (Cruiser: +50%, v0.9.116).
const SHIP_RANGE_MULT := {"cruiser": 1.5}

const SIZE_PIXELS := [24.5, 38.4, 54.9]   # +15% again (v0.9.136; was 21.3 / 33.4 / 47.7)


static func ship_stats(type_id: String) -> Dictionary:
	var info: Dictionary = SHIPS[type_id]
	var tier: int = info["tier"]
	var size: int = info["size"]
	var stats := {
		"hull": 50.0 * tier,
		"armor": 100.0 * tier,
		"speed": SIZE_SPEED[size],
		"cost_alloys": 5 * tier,
		"cost_gas": 0,
		"build_time": 5.0 * tier,
	}
	match type_id:
		"corvette":
			stats["cost_alloys"] = 3   # a cheap swarm ship (was 5, v0.9.107)
			stats["hull"] = 30.0    # swarm fodder: 90 health, two Gatling bursts
			stats["armor"] = 60.0
		"cruiser":
			stats["cost_gas"] = 2   # missile fuel (v0.9.117): the first warship that needs Gas
		"carrier":
			stats["armor"] = 500.0
			stats["cost_gas"] = 5   # was 1 (v0.9.81): big ships are a real Gas commitment
		"battleship":
			stats["armor"] = 1200.0
			stats["armor_hardening"] = 1.0   # v0.9.120: every hit on its armor does 1 less damage
			stats["cost_gas"] = 5   # was 1 (v0.9.81)
		"capital":
			stats["hull"] = 360.0
			stats["armor"] = 1440.0
			stats["armor_hardening"] = 1.0   # every hit on its armor does 1 less damage
		"fighter":
			stats["hull"] = 5.0
			stats["armor"] = 5.0
			stats["speed"] = 36.0   # about 60% faster than a Corvette (22.5)
			stats["cost_alloys"] = 0
			stats["build_time"] = 0.0
		"colony":
			stats["hull"] = CIVILIAN_HULL
			stats["armor"] = CIVILIAN_ARMOR
			stats["speed"] = 6.0
	stats["cost_alloys"] = int(stats["cost_alloys"]) * ALLOY_SCALE   # x5 economy (v0.9.237)
	return stats


## Growth steps a planet needs for its next pop: quick early, slower as it fills up.
static func growth_needed(pops: int) -> int:
	return GROWTH_BASE + pops


static func ship_pixels(type_id: String) -> float:
	if type_id == "capital":
		return 68.8   # +15% again (v0.9.136; was 59.8)
	if type_id == "fighter":
		return 13.9   # +15% again (v0.9.136; was 12.1)
	var info: Dictionary = SHIPS[type_id]
	var size: int = info["size"]
	return SIZE_PIXELS[size]


static func faction_colour(faction: int) -> Color:
	match faction:
		Faction.UNE:
			return Color("3e6fb0")
		Faction.REBELS:
			return Color("a2402f")
		Faction.SONS:
			return Color("2b2b31")
		_:
			return Color("8e8478")


static func faction_trim(faction: int) -> Color:
	match faction:
		Faction.UNE:
			return Color("e9e6dc")
		Faction.REBELS:
			return Color("d0703a")
		Faction.SONS:
			return Color("d4aa3e")
		_:
			return Color("c9ced6")


static func ring_colour(faction: int) -> Color:
	match faction:
		Faction.UNE:
			return Color("4c8dff")
		Faction.REBELS:
			return Color("e5484d")
		Faction.SONS:
			return Color("d4aa3e")
		_:
			return Color("e8c547")


## Label for a ship: short code, or the full name while Space is held.
static func ship_label(type_id: String) -> String:
	var info: Dictionary = SHIPS[type_id]
	if not show_full_names:
		return info["code"]
	var class_name_text: String = info["name"]
	var kind: String = info["kind"]
	if class_name_text == "":
		return kind
	return "%s %s" % [class_name_text, kind]


## Label for a structure: short code, or the full name while Space is held.
## Station name labels follow the ship ones: full names while Info (Space) is held,
## short codes only with Settings > Abbreviated Ship Names, otherwise nothing.
static func structure_label(kind: String) -> String:
	if not show_full_names and not show_abbrev_names:
		return ""
	match kind:
		"starbase":
			return "Starbase" if show_full_names else "SB"
		"shipyard":
			return "Shipyard" if show_full_names else "SY"
		"mag":
			return "MAG Cannon" if show_full_names else "MAG"
	return kind


## "{alloys}+12  {gas}+3  {credits}+8" for a system's daily take ("" if it makes nothing).
static func daily_text(system_index: int) -> String:
	var d: Dictionary = system_dailies.get(system_index, {})
	var parts: Array = []
	for key in ["alloys", "gas", "credits"]:
		var n := int(d.get(key, 0))
		if n > 0:
			parts.append("{%s}+%d" % [key, n])
	return "  ".join(PackedStringArray(parts))


## Text that stays the same size on screen at any zoom.
static func screen_scale(item: CanvasItem) -> float:
	var cam := item.get_viewport().get_camera_2d()
	if cam == null:
		return 1.0
	return 1.0 / cam.zoom.x


## What a planet's pops make, by world type. Terran (green and blue) worlds pay
## credits, desert worlds dig Alloys, ice worlds freeze out Gas. Dead and molten
## worlds (no capacity) and gas giants make nothing from pops.
const POP_YIELDS := {
	"terran": {"resource": "credits", "per": 2, "name": "Terran world", "unit": "¢1"},
	"desert": {"resource": "alloys", "per": 3, "name": "Desert world", "unit": "5 Alloys"},
	"ice":    {"resource": "gas", "per": 3, "name": "Ice world", "unit": "1 Gas"},
}


## terran, desert, ice, or "" for worlds whose pops make nothing.
static func planet_type(p: Dictionary) -> String:
	if int(p.get("capacity", 0)) <= 0:
		return ""
	match String(p.get("kind", "random")):
		"earth", "continental":
			return "terran"
		"mars":
			return "desert"
		"molten":
			return ""
	match Color(p.get("colour", Color("6f9a5a"))).to_html(false):
		"c27a4a", "b8a27a":
			return "desert"
		"8a7fb0":
			return "ice"
	return "terran"


## How many pops apart a planet's Growth Rewards are: the same as its pop ratio
## (every 2nd pop on terran worlds, every 3rd on desert and ice worlds).
static func reward_every(p: Dictionary) -> int:
	var kind := planet_type(p)
	return int(POP_YIELDS[kind]["per"]) if kind != "" else 2


## What this planet's pops make each tick: {resource, amount, per, next} (empty if nothing).
## next: the pop count that earns the next unit.
@warning_ignore("integer_division")
static func pop_yield(p: Dictionary) -> Dictionary:
	var kind := planet_type(p)
	if kind == "":
		return {}
	var info: Dictionary = POP_YIELDS[kind]
	var per := int(info["per"])
	var pops := int(p.get("pops", 0))
	var out := info.duplicate()
	out["type"] = kind
	out["amount"] = pops / per * (ALLOY_SCALE if String(info["resource"]) == "alloys" else 1)
	out["next"] = (pops / per + 1) * per
	return out


## Performance: true when a node (and margin_px of screen pixels around it) is on screen.
## Things that animate by redrawing skip the redraw while they're out of view.
static func on_screen(item: Node2D, margin_px: float = 160.0) -> bool:
	var p := item.get_global_transform_with_canvas().origin
	var r := item.get_viewport_rect()
	return p.x > -margin_px and p.y > -margin_px and p.x < r.size.x + margin_px and p.y < r.size.y + margin_px


# --- weapons (ranges x3, projectile speeds x3, cooldowns halved) ---------------

const WEAPONS := {
	"gatling":  {"name": "K9 Gatling Gun", "damage": 3.0, "burst": 10, "gap": 0.04, "cooldown": 1.8, "range": 30.0, "speed": 85.0, "colour": "f0c060", "spread": 0.5, "vs_small": 1.5},   # +50% vs Small craft
	"mini_mag": {"name": "Mini MAG", "vs_big": 1.5, "damage": 250.0, "burst": 1, "gap": 0.0, "cooldown": 7.0, "range": 30.0, "speed": 180.0, "colour": "8fd1ff", "spread": 0.25, "charge": 2.5},
	"mag":      {"name": "MAG", "damage": 500.0, "burst": 1, "gap": 0.0, "cooldown": 6.2, "range": 55.0, "speed": 210.0, "colour": "b8e4ff", "charge": 2.5},
	"rock_gatling": {"name": "K9 Gatling Gun", "damage": 3.0, "burst": 10, "gap": 0.04, "cooldown": 2.2, "range": 120.0, "speed": 85.0, "colour": "ff8a3d", "spread": 1.2, "vs_small": 1.5},
	"flak":     {"name": "Flak Cannon", "flak": true, "damage": 6.0, "burst": 3, "gap": 0.08, "cooldown": 1.0, "range": 21.0, "speed": 60.0, "colour": "ffb347", "spread": 1.2, "splash": 1.5},   # shells burst at the aim point and hit everything close
	"torpedo":  {"name": "Torpedo", "torpedo": true, "damage": 500.0, "burst": 1, "gap": 0.0, "cooldown": 10.0, "range": 32.0, "speed": 21.5, "colour": "ff6a3d", "splash": 5.0, "edge": 0.25, "fuel": 9.0},   # prototype: slow, homing, big blast on contact
	"swarm":    {"name": "Swarm Missiles", "swarm": true, "missiles": 4, "damage": 62.0, "burst": 1, "gap": 0.0, "cooldown": 6.0, "range": 30.0, "speed": 24.0, "colour": "9fe0ff", "splash": 2.0, "fuel": 3.2, "wedge": 180.0, "sweep": 1.2, "retry": 1.5},   # prototype: radar sweep locks, then a fanned salvo
	"pdc":      {"name": "PDC", "damage": 1.0, "burst": 4, "gap": 0.05, "cooldown": 0.5, "range": 18.0, "speed": 220.0, "colour": "c9ced6", "spread": 0.06, "precise": true, "vs_small": 1.5},   # point defence: fast, light, anti-small; fire-controlled, so it hits (v0.9.213: speed 120 -> 220, spread 0.3 -> 0.06, no auto-fire scatter; v0.9.221: range 12 -> 18)
	"fighter_gun": {"name": "VALK cannon", "damage": 20.0, "burst": 3, "gap": 0.08, "cooldown": 2.0, "range": 6.0, "speed": 60.0, "colour": "8fd1ff", "spread": 0.1},
	"bay":      {"name": "Fighter Bay", "range": 40.0},   # Starbase bays: launch range (x Starbase range)
	"mag_cannon": {"name": "MAG Cannon", "damage": 800.0, "burst": 1, "gap": 0.0, "cooldown": 8.0, "range": 45.0, "speed": 230.0, "colour": "b8e4ff", "spread": 0.2, "charge": 2.5},   # station: x2 range, aims at the strongest enemy, pierces
	"pd_mag":   {"name": "PD MAG", "damage": 650.0, "burst": 1, "gap": 0.0, "cooldown": 8.0, "range": 56.0, "speed": 210.0, "colour": "b8e4ff", "charge": 2.5},
}

## Prototype loadouts. Missiles, Torpedoes, Flak, PDCs and fighters come later.
const LOADOUTS := {
	"corvette": ["gatling"],             # one Gatling, fed to both sponsons (was two, v0.9.106)
	"frigate": ["torpedo", "pdc"],       # PDC for close defence (was a Gatling, v0.9.106)
	"destroyer": ["mini_mag", "pdc"],
	"cruiser": ["swarm", "gatling", "flak"],   # one Flak cannon (was three, v0.9.106)
	"carrier": ["flak"],
	"battleship": ["mag", "gatling", "gatling", "gatling", "gatling"],
	"capital": ["mag", "gatling", "gatling", "gatling", "gatling"],
	"colony": [],
	"fighter": ["fighter_gun"],
}

const TECH_BASE_HEALTH := 800.0
const GUARD_AGGRO := 25.0    # units from its post at which a guard attacks
const GUARD_LEASH := 45.0    # units from its post before it gives up

## Starter Tech cards (from the design brief).
const TECH_CARDS := [
	{"name": "Deep Core Mining", "text": "Each Starbase mining asteroids gives +10 extra Alloys per day"},
	{"name": "Gas Giant Siphons", "text": "Starbases on Gas Giants give +1 extra Gas per day"},
	{"name": "Trade Networks", "text": "Each City gives +¢1 per day"},
	{"name": "Urban Sprawl", "text": "No limit on Cities: a planet can build as many as it has slots", "limit": 1},
	{"name": "Advanced Logistics", "text": "+1 Starbase slot"},
	{"name": "Extended Orbits", "text": "Starbase orbits are 60% larger", "limit": 2},   # was 20%, unlimited (v0.9.211)
	{"name": "Long-Range Sensors", "text": "Your Starbases sense enemies 2 jumps away instead of 1", "limit": 1},
	{"name": "Warp Drive Tuning", "text": "+50% warp speed: your fleet's jumps take a third less time", "limit": 1},
	{"name": "Colony Pods", "text": "New colonies settle twice as fast", "limit": 1},
	{"name": "Orbital Habitats", "text": "+2 pop capacity on every planet"},
	{"name": "Planetary Shields", "text": "Planets gain 500 shields, recharging like ship shields"},
	{"name": "Fortified Starbases", "text": "+25% Starbase health"},
	{"name": "Damage Control", "text": "Out of combat for 5 s, your ships repair 1% of hull and armor per second", "limit": 1},
	# Movement tech. "limit": copies you can own; "requires": another card you need first.
	{"name": "Blink Drive", "text": "Boost blinks the fleet half a boost's distance ahead. Uses half the meter", "limit": 1},
	{"name": "Blink Drive II", "text": "Blinks cost no boost (5 s cooldown), and you can boost right after", "limit": 1, "requires": "Blink Drive"},
	{"name": "Afterimage", "text": "For 1 s after a blink, enemy fire hits a ghost of your fleet where it was", "limit": 1, "requires": "Blink Drive"},
	{"name": "Slipstream", "text": "While boosting, your ships take 50% less damage from shots behind them", "limit": 1},
	{"name": "Tightened Logistics", "text": "No boost drain in a system with your Starbase and no enemies", "limit": 1},
	{"name": "Ram Plating", "text": "Boosting into enemies damages them, more the faster you go. No crash damage", "limit": 1},
	{"name": "Afterburner Wake", "text": "Boosting leaves a burning trail that damages enemy ships flying through it", "limit": 1},
	{"name": "Quick Spool", "text": "Warp charge time halved", "limit": 1},
	{"name": "Hot Exit", "text": "Leaving warp: a pulse deals 150 damage and slows nearby enemies 50% for 4 s", "limit": 1},
	{"name": "Overdrive Tanks", "text": "Boost meter 50% bigger, and it refills 25% faster", "limit": 1},
	{"name": "Drift Thrusters", "text": "Full speed through turns, and the formation swings round fast", "limit": 1},
	{"name": "Asteroid Force Fields", "text": "Asteroids with yields in your Starbase orbits can't be destroyed", "limit": 1},
]

## Planned, not in the card pool yet: needs ship building so a second fleet can exist.
const PLANNED_TECH_CARDS := [
	{"name": "Second Command", "text": "Unlocks a second fleet. Tab switches fleets in Fleet Mode"},
]


## A short reference code for a card, like a collector number: F3 (Fleet), T12 (Tech),
## P5 (planet building). Shown on cards while Info (Space) is held.
static func card_code(card_name: String) -> String:
	for pair in [["F", FLEET_CARDS], ["T", TECH_CARDS], ["P", PLANET_CARDS]]:
		var list: Array = pair[1]
		for i in list.size():
			if String(list[i]["name"]) == card_name:
				return "%s%d" % [String(pair[0]), i + 1]
	return ""


## Alloys a Colony Ship costs, after Colony Office discounts.
static func colony_alloys() -> int:
	return maxi(0, COLONY_ALLOYS - colony_discount)


static func is_hostile(a: int, b: int) -> bool:
	if a == b or a == Faction.NEUTRAL or b == Faction.NEUTRAL:
		return false
	# Every faction is hostile to the UNE; the AI factions leave each other alone for now.
	return a == Faction.UNE or b == Faction.UNE


## Planet cards: each one is a planet building. limit 0 = no limit.
const PLANET_CARDS := [
	{"name": "City", "text": "+5 pop capacity on this planet", "limit": 1},   # Urban Sprawl (tech) lifts the limit
	{"name": "PD MAG", "text": "A planet fortress MAG: 650-damage shots at enemies up to 56 units away", "limit": 1},
	{"name": "Fleet Academy", "text": "+1 damage to all your ships' attacks", "limit": 1},
	{"name": "Tech Lab", "text": "+1 option on every Tech card choice", "limit": 1},
	{"name": "Cryo Medicals", "text": "+50% pop growth on this planet", "limit": 1},
	{"name": "Logistics Hub", "text": "+1 to the Starbase limit", "limit": 0},
	{"name": "Mining Corp", "text": "+15 Alloys per day", "limit": 0},
	{"name": "Gas Refineries", "text": "+1 Gas", "limit": 1},
	{"name": "Space Elevators", "text": "Every Shipyard builds one more ship at the same time", "limit": 0},
	{"name": "Orbital Drydocks", "text": "Ships build 15% faster", "limit": 0},
	{"name": "Construction Yards", "text": "Construction Ships build stations 25% faster", "limit": 0},
	{"name": "Shipwright Guild", "text": "+1 Construction Ship: build one more station at the same time", "limit": 1, "early": true},   # v0.9.226; offered more often early on
	{"name": "Repair Gantries", "text": "Shipyard repair rings are 50% bigger and heal 50% faster", "limit": 1},
	{"name": "Tractor Arrays", "text": "Starbase orbits are 10% larger", "limit": 0},
	{"name": "Bunker Foundry", "text": "+15% Starbase health", "limit": 0},
	{"name": "Drone Docks", "text": "Starbases repair your ships inside their orbit", "limit": 1},
	{"name": "Long-Range Batteries", "text": "Station guns reach 25% further", "limit": 1},
	{"name": "Mini MAG Batteries", "text": "+1 Mini MAG on every Starbase. Max 3", "limit": 3},
	{"name": "Hangar Crews", "text": "Starbase fighters rebuild in 10 s instead of 15", "limit": 1},
	{"name": "Customs Office", "text": "+¢1 per day for every Starbase you own", "limit": 0},
	{"name": "Hauler Depot", "text": "Haulers fly 30% faster", "limit": 1},
	{"name": "Colony Office", "text": "Colony Ships settle 30% faster and cost 10 fewer Alloys", "limit": 1},
	{"name": "Trade Port", "text": "Arms Dealer cards and paid pickups cost 20% less", "limit": 1},
]

## Starter Fleet cards (from the design brief).
const FLEET_CARDS := [
	{"name": "Hardened Plating", "text": "All ships +10% armor"},
	{"name": "Reinforced Hulls", "text": "All ships +15% hull"},
	{"name": "Shield Emitters", "text": "All ships +25 shields"},
	{"name": "Overclocked Thrusters", "text": "+10% speed, turn speed and acceleration"},
	{"name": "Rapid Loaders", "text": "-10% weapon cooldowns"},
	{"name": "Missile Racks", "text": "+2 missiles on ships that carry missiles", "disabled": true},
	{"name": "Drone Bay Expansion", "text": "+1 drone group limit (max 2 copies)", "disabled": true},
	{"name": "Efficient Shipyards", "text": "-10% ship build time"},
	{"name": "Sustained Fire", "text": "Gatling bursts last 0.5 s longer (about 22 rounds instead of 10)", "limit": 1},
	# Kharkiv weapons: each one takes a hardpoint (4 different types at most); picking it again upgrades it.
	{"name": "Mine Layer", "text": "Drops mines that launch at nearby enemies. 3 at a time", "weapon": true},
	# Refits: bolt more weapons onto a ship type (every ship of that type, built or not).
	{"name": "Flak Retrofit", "text": "+1 Flak Cannon on every Corvette"},
	{"name": "Twin MAG Mount", "text": "+1 MAG on the Kharkiv", "limit": 2},
	# Kharkiv refits (v0.9.225): one more gun of each type on the flagship per pick.
	{"name": "Kharkiv Gatling", "text": "+1 K9 Gatling Gun on the Kharkiv", "limit": 3},
	{"name": "Kharkiv PDC", "text": "+1 PDC on the Kharkiv", "limit": 3},
	{"name": "Kharkiv Flak", "text": "+1 Flak Cannon on the Kharkiv", "limit": 3},
	{"name": "Kharkiv Mini MAG", "text": "+1 Mini MAG on the Kharkiv", "limit": 2},
	{"name": "Kharkiv Torpedo Tube", "text": "+1 Torpedo on the Kharkiv", "limit": 2},
	{"name": "Kharkiv Missile Pod", "text": "+1 Swarm Missiles launcher on the Kharkiv", "limit": 2},
	{"name": "Broadside Battery", "text": "+1 MAG on every Battleship"},
	{"name": "Extra Torpedo Tubes", "text": "+1 Torpedo on every Frigate"},
	{"name": "PDC Nest", "text": "+1 PDC on every Destroyer"},
	{"name": "Missile Pods", "text": "+1 Swarm Missiles launcher on every Cruiser"},
	{"name": "Gun Deck", "text": "+2 Gatlings on every Carrier"},
	# Weapon specialists: lean into a weapon type.
	{"name": "Hot-Loaded MAGs", "text": "MAG and Mini MAG shots deal +20% damage"},
	{"name": "Shaped Warheads", "text": "Torpedoes deal +30% damage with a 20% bigger blast"},
	{"name": "Bigger Swarms", "text": "+1 missile in every Swarm salvo"},
	{"name": "Proximity Fuses", "text": "Flak deals +30% damage"},
	{"name": "PDC Overdrive", "text": "PDCs fire 25% faster"},
	{"name": "Long-Range PDCs", "text": "PDCs reach twice as far", "limit": 1},   # v0.9.212
	{"name": "Wingmen", "text": "+1 fighter in every fighter wing", "limit": 2},
]
const KHARKIV_WEAPON_TYPES := 4

# Movement tech numbers
const BLINK_DISTANCE := 12.0      # units (unused since v0.9.84: a blink now covers a full boost's distance)
const BLINK_REACH := 0.4          # a blink covers 40% of a full boost's distance (was 0.5; -20%, v0.9.179)
const BLINK_KEEP := 0.5           # Blink Drive: half the boost meter is left after a blink
const BLINK_COOLDOWN := 5.0       # seconds, Blink Drive II (was 3; blinks got much longer in v0.9.84)
const AFTERIMAGE_SECONDS := 1.0
const RAM_PLATING_DAMAGE := 10.0  # per unit/s of fleet speed at impact
const WAKE_DAMAGE := 8.0          # per burn tick (every 0.4 s) while inside the trail
const WAKE_SECONDS := 3.0
const HOT_EXIT_DAMAGE := 150.0
const HOT_EXIT_RANGE := 25.0      # units
const MINE_CAP := 3
const MINE_CAP_MAX := 11
const MINE_DAMAGE := 150.0
const MINE_EVERY := 2.5           # seconds between drops while moving


# --- rarity, prices, economy rules ---------------------------------------------

## Arms Dealer card prices ($) by rarity, before the +50%-per-purchase markup.
const RARITY_PRICE := {"Good": 90, "Rare": 180, "ULTRA": 300}   # was 15 / 35 / 75 (v0.9.83)
const SILVER_ODDS := [70, 25, 5]
const GOLD_ODDS := [40, 45, 15]
const PICKUP_COST := 20           # $ for the first Fleet Card pickup, +25% each after
const SHOP_REFRESH := 100         # $ to reroll an Arms Dealer
const DRIFT_SECONDS := 112.5      # replacement asteroid drift-in time (was 75, x1.5 in v0.9.240)
const REPAIR_RATE := 0.1          # fraction of max armour and hull per second in a Starbase orbit
const BUMP_DAMAGE := 0.1          # fraction of max hull lost hitting an asteroid


static func rarity_colour(rarity: String) -> Color:
	match rarity:
		"Rare":
			return Color("5aa0ff")
		"ULTRA":
			return Color("b266ff")
	return Color("c9ced6")


static func rarity_mult(rarity: String) -> int:
	match rarity:
		"Rare":
			return 2
		"ULTRA":
			return 3
	return 1


## Rolls Good / Rare / ULTRA from percentages like [70, 25, 5].
static func roll_rarity(odds: Array) -> String:
	var roll := randi() % 100
	if roll < int(odds[0]):
		return "Good"
	if roll < int(odds[0]) + int(odds[1]):
		return "Rare"
	return "ULTRA"


## Rolls one regular asteroid's Alloy yield: mostly 0-1, 2 uncommon, 3 very rare.
static func roll_alloy_yield(rng: RandomNumberGenerator) -> int:
	# v0.9.239 (x5 economy): 1 to 8 Alloys, 8 rare. 45% of rocks are plain; of the rest:
	# 1: 24%  2: 22%  3: 18%  4: 13%  5: 10%  6: 7%  7: 4%  8: 2%. (Averages ~1.7 a rock,
	# with about twice as many rocks as before.)
	if rng.randf() < 0.45:
		return 0
	var weights := [24, 22, 18, 13, 10, 7, 4, 2]
	var roll := rng.randi() % 100
	for i in weights.size():
		roll -= int(weights[i])
		if roll < 0:
			return i + 1
	return 1


# --- milestone 4 -------------------------------------------------------------------

const PHALANX_RANGE := 8.0        # units: Sons of Philip Destroyers this close count as in formation
## How fast ships swing round (higher = snappier). Large hulls and the Kharkiv turn at
## half the rate of everything else (v0.9.126, under test).
const TURN_RATE := 5.0
const TURN_RATE_LARGE := 2.5


## Heavy hitters that Alt (secondary fire) takes control of: MAGs and Mini MAGs,
## torpedoes, and Swarm Missiles. Everything else (Gatling, PDC, Flak, fighter guns)
## holds fire while Alt is down.
static func is_special(weapon: Dictionary) -> bool:
	return weapon.has("charge") or weapon.has("torpedo") or weapon.has("swarm")


static func turn_rate(type_id: String) -> float:
	if type_id == "capital":
		return TURN_RATE_LARGE
	if SHIPS.has(type_id) and int(SHIPS[type_id]["size"]) >= 2:
		return TURN_RATE_LARGE
	return TURN_RATE


const PHALANX_TURN := 0.35        # radians per second: slow, so you can get behind the line
const RETREAT_AT := 0.2           # beta: ships below 20% health pull back to formation

## Ship names. The flagship keeps its own name (Kharkiv).
const UNE_NAMES := ["Weight of Consensus", "Mandate of Iron", "Order and Resolve", "Shadow of Doubt", "Hand of the Assembly", "Will of the Many", "Peace Through Order"]
const REBEL_NAMES := ["Rust Bucket", "Snake Eyes", "Bathtub Gin", "Last Chip", "Double Down", "Bad Idea"]
const SONS_NAMES := ["Sarissa", "Companion's Oath", "Pella's Wrath", "Sun of Vergina", "Chaeronea", "Philip's Eye", "Debt of Olynthus"]

static var _name_counters := {}


static func next_ship_name(faction: int) -> String:
	var list: Array = UNE_NAMES
	if faction == Faction.REBELS:
		list = REBEL_NAMES
	elif faction == Faction.SONS:
		list = SONS_NAMES
	var n := int(_name_counters.get(faction, 0))
	_name_counters[faction] = n + 1
	var base: String = list[n % list.size()]
	var round_no := n / list.size()
	return base if round_no == 0 else "%s %s" % [base, ["", "II", "III", "IV", "V"][mini(round_no, 4)]]


## Puts every static setting back to its starting value (for a restart).
const VERSION := "0.9.241"
static var menu_passed := false   # the title screen comes first; Start Run sets this
static var intro_seen := false    # the MarkoLabs intro plays once per launch
static var damage_dealt := 0.0   # by your ships this run, for the final score
static var sons_mods := {}   # the Sons of Philip's card bonuses (set by their AI)
static var sons_waves_at := {}   # system index -> ships in Philip's waves there (galaxy map)
# Card effects
static var blink_level := 0
static var afterimage := false
static var slipstream := false
static var ram_plating := false
static var afterburner_wake := false
static var hot_exit := false
static var drift_thrusters := false
static var warp_charge_mult := 1.0
static var boost_capacity_mult := 1.0
static var boost_refill_mult := 1.0
static var gatling_extra_seconds := 0.0
static var mine_cap := 0
static var mine_damage := 0.0
static var system_dailies := {}   # system index -> {alloys, gas, credits} it makes each day
static var hit_hardened := false   # set by take_damage when armor or shield hardening cut the hit (grey damage numbers)
static var hit_weapon := ""   # set by a shot just before it deals damage: which weapon (for ships' per-weapon damage records)
static var boosting := false   # the fleet is boosting right now (set every frame by main)
static var shipyard_lines := 1   # ships each Shipyard builds at once (+1 per Space Elevators)
static var asteroid_shields := false
static var damage_control := false
static var build_time_mult := 1.0
static var starbase_health_mult := 1.0
static var warp_time_mult := 1.0
static var colony_settle_mult := 1.0
static var long_sensors := false
static var construct_mult := 1.0        # Construction Yards: station building speed
static var construction_ships := 1      # Shipwright Guild: Construction Ships working at once
static var shipyard_repair_mult := 1.0  # Repair Gantries: Shipyard ring size and repair speed
static var station_range_mult := 1.0    # Long-Range Batteries: station gun reach
static var starbase_rebuild := FIGHTER_REBUILD   # Hangar Crews: Starbase fighter rebuild time
static var hauler_speed_mult := 1.0     # Hauler Depot
static var colony_discount := 0         # Colony Office: Alloys off a Colony Ship
static var trade_mult := 1.0            # Trade Port: Arms Dealer and pickup prices
static var extra_weapons := {}          # Fleet card refits: ship type -> extra weapon ids
static var weapon_damage_mult := {}    # weapon id -> damage multiplier (your ships)
static var weapon_cooldown_mult := {}  # weapon id -> cooldown multiplier (your ships)
static var pdc_range_mult := 1.0       # Long-Range PDCs: your ships' PDC reach
static var ship_owned := {}            # type -> how many you own + have queued, eased down slowly after losses (prices scale with it)
static var swarm_bonus := 0            # extra missiles per Swarm salvo
static var torpedo_splash_mult := 1.0
static var fighter_group_bonus := 0    # extra fighters per wing


static func reset_run() -> void:
	construction_ships = 1
	damage_dealt = 0.0
	sons_mods = {}
	sons_waves_at = {}
	blink_level = 0
	afterimage = false
	slipstream = false
	ram_plating = false
	afterburner_wake = false
	hot_exit = false
	drift_thrusters = false
	warp_charge_mult = 1.0
	boost_capacity_mult = 1.0
	boost_refill_mult = 1.0
	gatling_extra_seconds = 0.0
	mine_cap = 0
	mine_damage = 0.0
	boosting = false
	shipyard_lines = 1
	asteroid_shields = false
	damage_control = false
	build_time_mult = 1.0
	starbase_health_mult = 1.0
	warp_time_mult = 1.0
	colony_settle_mult = 1.0
	long_sensors = false
	construct_mult = 1.0
	shipyard_repair_mult = 1.0
	station_range_mult = 1.0
	starbase_rebuild = FIGHTER_REBUILD
	hauler_speed_mult = 1.0
	colony_discount = 0
	trade_mult = 1.0
	extra_weapons = {}
	weapon_damage_mult = {}
	weapon_cooldown_mult = {}
	pdc_range_mult = 1.0
	ship_owned = {}
	swarm_bonus = 0
	torpedo_splash_mult = 1.0
	fighter_group_bonus = 0
	show_full_names = false
	show_ranges = false
	orbit_multiplier = 1.0
	armor_mult = 1.0
	hull_mult = 1.0
	shield_bonus = 0.0
	speed_mult = 1.0
	cooldown_mult = 1.0
	damage_bonus = 0.0
	starbase_repairs = false
	starbase_mini_mags = 0
	_name_counters = {}


## A planet's traits (every planet is Hard as Rock unless it says otherwise).
static func planet_traits(p: Dictionary) -> Array:
	return Array(p.get("traits", ["Hard as Rock"]))


## What your next ship of this type costs: base x (1 + 10% per one you own or have queued).
static func ship_price(type_id: String) -> Vector2i:
	var stats := ship_stats(type_id)
	var mult := 1.0 + SHIP_PRICE_STEP * float(ship_owned.get(type_id, 0.0))
	return Vector2i(int(ceil(float(stats["cost_alloys"]) * mult - 0.001)), int(ceil(float(stats["cost_gas"]) * mult - 0.001)))


## A ship's Alloy upkeep per day, in whole Alloys (see SHIP_UPKEEP).
static func ship_upkeep(type_id: String) -> int:
	return int(SHIP_UPKEEP.get(type_id, 0))
