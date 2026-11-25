extends RefCounted
## Player settings kept between runs in user://settings.cfg: volumes, damage numbers,
## fullscreen. Loaded by the main menu and by a run, saved whenever one changes.

const GD = preload("res://scripts/game_data.gd")
const PATH := "user://settings.cfg"

static var music := 0.5
static var sfx := 0.8
static var damage_numbers := true
static var fullscreen := false
static var noob_mode := true     # Noob Mode: Xander and the start-of-run tutorial
static var xp_popups := false     # "+3 XP" over a ship when it scores a kill
static var abbrev_names := false  # short codes (C, F, D...) over ships all the time
static var skip_intro := false    # skip the MarkoLabs developer intro at launch
static var advisor_on := true          # Xander pops up with warnings
static var advisor_muted := false      # his voice blips
static var advisor_dismissed: Array = []   # warnings the player asked him to drop
static var _loaded := false


static func load_settings() -> void:
	if _loaded:
		return
	_loaded = true
	var config := ConfigFile.new()
	if config.load(PATH) != OK:
		return
	music = float(config.get_value("audio", "music", music))
	sfx = float(config.get_value("audio", "sfx", sfx))
	damage_numbers = bool(config.get_value("gameplay", "damage_numbers", damage_numbers))
	fullscreen = bool(config.get_value("display", "fullscreen", fullscreen))
	noob_mode = bool(config.get_value("gameplay", "noob_mode", noob_mode))
	xp_popups = bool(config.get_value("gameplay", "xp_popups", xp_popups))
	abbrev_names = bool(config.get_value("gameplay", "abbrev_names", abbrev_names))
	skip_intro = bool(config.get_value("display", "skip_intro", skip_intro))
	advisor_on = bool(config.get_value("advisor", "on", advisor_on))
	advisor_muted = bool(config.get_value("advisor", "muted", advisor_muted))
	advisor_dismissed = Array(config.get_value("advisor", "dismissed", []))


## Xander only speaks up in Noob Mode, and only if he hasn't been sent away.
static func xander_on() -> bool:
	return noob_mode and advisor_on


static func save_settings() -> void:
	var config := ConfigFile.new()
	config.load(PATH)   # keep other keys (like the economy guide's) as they are
	config.set_value("audio", "music", music)
	config.set_value("audio", "sfx", sfx)
	config.set_value("gameplay", "damage_numbers", damage_numbers)
	config.set_value("display", "fullscreen", fullscreen)
	config.set_value("gameplay", "noob_mode", noob_mode)
	config.set_value("gameplay", "xp_popups", xp_popups)
	config.set_value("gameplay", "abbrev_names", abbrev_names)
	config.set_value("display", "skip_intro", skip_intro)
	config.set_value("advisor", "on", advisor_on)
	config.set_value("advisor", "muted", advisor_muted)
	config.set_value("advisor", "dismissed", advisor_dismissed)
	config.save(PATH)


## Puts the settings into effect. Audio buses that don't exist yet are skipped; the
## music and sound players read these values themselves when they start.
static func apply() -> void:
	_bolder_font()
	GD.show_damage_numbers = damage_numbers
	GD.show_abbrev_names = abbrev_names
	var music_bus := AudioServer.get_bus_index("Music")
	if music_bus != -1:
		AudioServer.set_bus_volume_db(music_bus, linear_to_db(maxf(music, 0.0001)))
		AudioServer.set_bus_mute(music_bus, music <= 0.001)
	var sfx_bus := AudioServer.get_bus_index("SFX")
	if sfx_bus != -1:
		AudioServer.set_bus_volume_db(sfx_bus, linear_to_db(maxf(sfx, 0.0001)))
		AudioServer.set_bus_mute(sfx_bus, sfx <= 0.001)
	var mode := DisplayServer.window_get_mode()
	var is_full := mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	if fullscreen and not is_full:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	elif not fullscreen and is_full:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)


## Every label and drawn string uses the default font: make it a touch heavier so text
## stays crisp when the window scales the game down (helps with anti-aliasing).
static func _bolder_font() -> void:
	if ThemeDB.fallback_font is FontVariation:
		return
	var heavier := FontVariation.new()
	heavier.base_font = ThemeDB.fallback_font
	heavier.variation_embolden = 0.4
	ThemeDB.fallback_font = heavier
