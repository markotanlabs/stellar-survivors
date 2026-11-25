extends Node2D
## Placeholder sound: generated effects, positional in the world and flat for the UI,
## with throttling so a big fight doesn't turn into noise. Also the space ambience and
## the UNE announcer (text-to-speech placeholder for recorded lines).
## Call from anywhere: Sfx.play("gatling", node) or Sfx.ui("click") or Sfx.say("key", "Line.").

const SOUNDS := [
	"gatling", "mag_charge", "mag_fire", "mini_mag_fire", "hit", "shield_hit",
	"explosion_small", "explosion_large", "boost", "jet", "warp_charge", "warp_jump",
	"pickup", "reward", "notify", "click", "hover", "card_appear", "card_pick", "card_land",
	"cash", "blip", "launch", "fanfare", "warn_fleet", "warn_hit", "warn_convoy", "alarm",
	"deny", "gather",
]
# name: [minimum seconds between plays, most playing at once]
const LIMITS := {
	"gatling": [0.06, 6], "hit": [0.07, 3], "shield_hit": [0.09, 3], "mag_charge": [0.1, 4],
	"explosion_small": [0.05, 5], "explosion_large": [0.1, 3], "jet": [0.1, 2], "hover": [0.04, 2],
	"alarm": [4.0, 1], "warp_charge": [1.0, 1], "boost": [0.3, 1], "notify": [3.0, 1], "warn_fleet": [2.0, 1], "warn_hit": [2.0, 1], "warn_convoy": [2.0, 1],
	"deny": [0.25, 1], "gather": [0.12, 3],
}
const WORLD_VOICES := 28
const UI_VOICES := 10

static var _inst: Node2D = null

var volume := 0.8
var _streams := {}
var _world: Array = []
var _flat: Array = []
var _last := {}
var _said := {}
var _ambience: AudioStreamPlayer
var _boost: AudioStreamPlayer
var _boost_on := false
var _cruise: AudioStreamPlayer = null
var _cruise_level := 0.0   # 0 = still, 1 = full cruising speed
var _voice := ""


func _ready() -> void:
	_inst = self
	process_mode = Node.PROCESS_MODE_ALWAYS
	if AudioServer.get_bus_index("SFX") == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, "SFX")
	set_volume(volume)
	for n in SOUNDS:
		var path := "res://sounds/%s.wav" % n
		if ResourceLoader.exists(path):
			_streams[n] = load(path)
	for i in WORLD_VOICES:
		var p := AudioStreamPlayer2D.new()
		p.bus = "SFX"
		p.max_distance = 3200.0
		p.attenuation = 1.3
		add_child(p)
		_world.append(p)
	for i in UI_VOICES:
		var q := AudioStreamPlayer.new()
		q.bus = "SFX"
		add_child(q)
		_flat.append(q)
	_start_ambience()
	_boost = _looping_player("res://sounds/boost_loop.wav")
	_boost.play()   # always running, silent until you boost: no restarts, no audible loop point
	# Cruising engines: the same rush, pitched way down into a soft rumble, that swells
	# with your flagship's speed when you're not boosting.
	_cruise = _looping_player("res://sounds/boost_loop.wav")
	if _cruise != null:
		_cruise.pitch_scale = 0.55
		_cruise.play()
	_station = _looping_player("res://sounds/station_hum.wav")
	if _station != null:
		_station.play()
	_pick_voice()


## The flagship dies: the whole game winds down like a record when the turntable is
## switched off (v0.9.207). All sound and music drop in speed and pitch, with a slight
## warped-vinyl wobble, grit creeping in and the top end closing, then it all sinks away.
## No separate scratch sample any more (it was too loud). Runs while paused.
static var _death_filter: AudioEffectLowPassFilter = null
static var _death_grit: AudioEffectDistortion = null

static func death_bleed(host: Node) -> void:
	reset_death_audio()
	var master := AudioServer.get_bus_index("Master")
	_death_grit = AudioEffectDistortion.new()
	_death_grit.mode = AudioEffectDistortion.MODE_OVERDRIVE
	_death_grit.drive = 0.0
	_death_grit.pre_gain = 0.0
	_death_grit.post_gain = 0.0
	AudioServer.add_bus_effect(master, _death_grit)
	_death_filter = AudioEffectLowPassFilter.new()
	_death_filter.cutoff_hz = 20000.0
	AudioServer.add_bus_effect(master, _death_filter)
	var grit := _death_grit
	var filt := _death_filter
	var wind_down := func(p: float) -> void:
		# Speed falls slowly at first, then faster, the way a platter coasts to a stop.
		var wobble := 1.0 + 0.035 * sin(p * 38.0) * p
		AudioServer.playback_speed_scale = maxf(0.08, lerpf(1.0, 0.1, p * p) * wobble)
		grit.drive = 0.55 * p
		grit.post_gain = -7.0 * p          # grit without getting louder
		filt.cutoff_hz = 20000.0 * pow(0.06, p)   # 20 kHz down to about 1.2 kHz
		AudioServer.set_bus_volume_db(master, -6.0 * p if p < 0.7 else lerpf(-4.2, -45.0, (p - 0.7) / 0.3))
	var tw := host.create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_interval(0.15)
	tw.tween_method(wind_down, 0.0, 1.0, 3.2).set_trans(Tween.TRANS_LINEAR)


## Puts the sound back to normal (a new run, the main menu).
static func reset_death_audio() -> void:
	AudioServer.playback_speed_scale = 1.0
	var master := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(master, 0.0)
	for i in range(AudioServer.get_bus_effect_count(master) - 1, -1, -1):
		var fx := AudioServer.get_bus_effect(master, i)
		if fx is AudioEffectLowPassFilter or fx is AudioEffectDistortion:
			AudioServer.remove_bus_effect(master, i)
	_death_filter = null
	_death_grit = null


static func play(sound: String, at: Node2D = null, volume_db: float = 0.0, pitch_var: float = 0.06) -> void:
	if _inst != null and is_instance_valid(_inst):
		_inst.call("_play", sound, at, volume_db, pitch_var)


## The boost rush loops for as long as the fleet is boosting.
## Station busywork (beeps, clanks, machinery): 0 = silent, 1 = right beside one, zoomed in.
static func set_station_level(level: float) -> void:
	if _inst != null and is_instance_valid(_inst):
		_inst.call("_set_station", level)


## Engine rumble while cruising: 0 = still, 1 = full speed (not boosting).
static func set_cruise(level: float) -> void:
	if _inst != null and is_instance_valid(_inst):
		_inst.set("_cruise_level", clampf(level, 0.0, 1.0))


static func set_boost(on: bool) -> void:
	if _inst != null and is_instance_valid(_inst):
		_inst.call("_set_boost", on)


static func ui(sound: String, volume_db: float = 0.0) -> void:
	if _inst != null and is_instance_valid(_inst):
		_inst.call("_play", sound, null, volume_db, 0.0)


## A spoken announcer line, at most once per `cooldown` seconds for each key.
static func say(key: String, line: String, cooldown: float = 5.0) -> void:
	if _inst != null and is_instance_valid(_inst):
		_inst.call("_say", key, line, cooldown)


func set_volume(value: float) -> void:
	volume = clampf(value, 0.0, 1.0)
	var bus := AudioServer.get_bus_index("SFX")
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(volume, 0.0001)))


func _play(sound: String, at: Node2D, volume_db: float, pitch_var: float) -> void:
	if not _streams.has(sound):
		return
	# Sounds from systems you aren't looking at stay silent.
	if at != null and (not is_instance_valid(at) or not at.is_visible_in_tree()):
		return
	var now := Time.get_ticks_msec() / 1000.0
	var limit: Array = LIMITS.get(sound, [0.03, 4])
	if now - float(_last.get(sound, -99.0)) < float(limit[0]):
		return
	var pool: Array = _flat if at == null else _world
	var playing := 0
	var free_player: Node = null
	for p in pool:
		if p.playing:
			if p.stream == _streams[sound]:
				playing += 1
		elif free_player == null:
			free_player = p
	if playing >= int(limit[1]) or free_player == null:
		return
	_last[sound] = now
	free_player.stream = _streams[sound]
	free_player.volume_db = volume_db
	free_player.pitch_scale = 1.0 + randf_range(-pitch_var, pitch_var)
	if at != null:
		(free_player as AudioStreamPlayer2D).global_position = at.global_position
	free_player.play()


func _start_ambience() -> void:
	var stream := load("res://sounds/ambience_space.wav") as AudioStreamWAV
	if stream == null:
		return
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = int(stream.get_length() * stream.mix_rate)
	_ambience = AudioStreamPlayer.new()
	_ambience.stream = stream
	_ambience.bus = "SFX"
	_ambience.volume_db = -16.0
	add_child(_ambience)
	_ambience.play()


func _looping_player(path: String) -> AudioStreamPlayer:
	var stream := load(path) as AudioStreamWAV
	if stream == null:
		return null
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = int(stream.get_length() * stream.mix_rate)
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.bus = "SFX"
	player.volume_db = -60.0
	add_child(player)
	return player


func _set_boost(on: bool) -> void:
	if _boost == null:
		return
	_boost_on = on
	if not _boost.playing:
		_boost.play()


## The boost rush fades in while boosting and out when you stop. It also goes silent
## whenever the game is paused (a card screen, the pause menu), since the fleet isn't
## moving then, and comes back if you're still boosting when play resumes.
func _update_boost_sound(delta: float) -> void:
	if _boost == null:
		return
	var loud := _boost_on and not get_tree().paused
	var target := -14.0 if loud else -60.0
	var rate := 46.0 / 0.2 if loud else 46.0 / 0.3   # dB per second: ~0.2 s in, ~0.3 s out
	_boost.volume_db = move_toward(_boost.volume_db, target, rate * delta)
	if _cruise != null:
		# Quiet under the boost, silent when paused or stopped.
		var level := 0.0 if (_boost_on or get_tree().paused) else _cruise_level
		var want := -60.0 if level < 0.05 else lerpf(-34.0, -23.0, level)
		_cruise.volume_db = move_toward(_cruise.volume_db, want, 40.0 * delta)


func _pick_voice() -> void:
	if not ProjectSettings.get_setting("audio/general/text_to_speech", false):
		return
	var voices := DisplayServer.tts_get_voices_for_language("en")
	if not voices.is_empty():
		_voice = voices[0]


func _say(key: String, line: String, cooldown: float) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if now - float(_said.get(key, -99.0)) < cooldown:
		return
	_said[key] = now
	_play("blip", null, -4.0, 0.0)
	if _voice != "":
		# Lines wait their turn instead of cutting each other off: interrupting the
		# speech engine blocks the game for a moment (the stutter with toasts).
		if _voice_queue.size() < 2:
			_voice_queue.append(line)


var _voice_queue: Array = []
var _voice_check := 0.0


func _process(delta: float) -> void:
	_update_boost_sound(delta)
	if _voice_queue.is_empty():
		return
	_voice_check -= delta
	if _voice_check > 0.0:
		return
	_voice_check = 0.3
	if DisplayServer.tts_is_speaking():
		return
	var line := String(_voice_queue.pop_front())
	# Low and slow for a cold, robotic UNE announcer (placeholder for recorded lines).
	DisplayServer.tts_speak(line, _voice, int(volume * 80.0), 0.6, 0.92, 0, false)



var _station: AudioStreamPlayer = null
var _station_level := 0.0


func _set_station(level: float) -> void:
	if _station == null:
		return
	# Ease toward the new level so it fades in and out as you pan and zoom.
	_station_level = lerpf(_station_level, clampf(level, 0.0, 1.0), 0.08)
	_station.volume_db = -60.0 if _station_level < 0.01 else lerpf(-42.0, -24.0, _station_level)
