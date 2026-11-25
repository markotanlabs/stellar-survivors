extends Node
## Placeholder music: plays the tracks in res://music as a shuffled playlist,
## crossfading from one to the next. Keeps playing while the game is paused.

const TRACKS := [
	"res://music/whoa_whoa.ogg",
	"res://music/tanz_zimmer.ogg",
	"res://music/three_of_diamonds.ogg",
	"res://music/timeless.ogg",
	"res://music/quick_silver.ogg",
]
const Settings = preload("res://scripts/settings.gd")
const FADE := 3.0          # seconds of crossfade between tracks
const VOLUME_DB := -8.0

var _players: Array = []
var _current := 0          # which of the two players is playing
var _queue: Array = []
var _fading := false
var now_playing := ""
var paused := false
var volume := 0.5          # 0..1, applied to the Music bus (Settings will share it)
var _history: Array = []
var _tween: Tween = null


## One music player for the whole game, kept on the scene tree's root so the music
## carries on from the title screen into a run and through restarts.
static func shared(tree: SceneTree) -> Node:
	var existing := tree.root.get_node_or_null("SharedMusic")
	if existing != null:
		return existing
	var player = load("res://scripts/music.gd").new()
	player.name = "SharedMusic"
	tree.root.add_child.call_deferred(player)
	return player


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if AudioServer.get_bus_index("Music") == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, "Music")
	for i in 2:
		var player := AudioStreamPlayer.new()
		player.bus = "Music"
		player.volume_db = -80.0
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(player)
		_players.append(player)
	Settings.load_settings()
	volume = Settings.music
	set_volume(volume)
	# The game always opens on Whoa Whoa at the main menu; after that, the shuffled playlist.
	_play_path(String(TRACKS[0]), false)


func set_volume(value: float) -> void:
	volume = clampf(value, 0.0, 1.0)
	var bus := AudioServer.get_bus_index("Music")
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(volume, 0.0001)))
	AudioServer.set_bus_mute(bus, volume <= 0.001)


func next_track() -> void:
	paused = false
	_play_next(true)


func previous_track() -> void:
	paused = false
	if _history.size() >= 2:
		_history.pop_back()
		var path := String(_history.pop_back())
		_play_path(path, true)
	else:
		_play_path(now_playing, true)


func play_track(index: int) -> void:
	paused = false
	_play_path(String(TRACKS[index]), true)


func toggle_pause() -> void:
	paused = not paused
	var player: AudioStreamPlayer = _players[_current]
	player.stream_paused = paused


func track_names() -> Array:
	var names: Array = []
	for t in TRACKS:
		names.append(_title_of(String(t)))
	return names


func _title_of(path: String) -> String:
	return path.get_file().get_basename().replace("_", " ").capitalize()


func _next_track() -> String:
	if _queue.is_empty():
		_queue = TRACKS.duplicate()
		_queue.shuffle()
		# Don't repeat the track that just ended.
		if _queue.size() > 1 and String(_queue[0]) == now_playing:
			_queue.push_back(_queue.pop_front())
	return String(_queue.pop_front())


func _play_next(crossfade: bool) -> void:
	_play_path(_next_track(), crossfade)


func _play_path(path: String, crossfade: bool) -> void:
	if path == "" or not ResourceLoader.exists(path):
		return
	var stream := load(path) as AudioStream
	if stream == null:
		return
	now_playing = path
	_history.append(path)
	if _history.size() > 20:
		_history.pop_front()
	# Cut any crossfade still running, so a quick skip can't stop the new song.
	if _tween != null and _tween.is_valid():
		_tween.kill()
	var old: AudioStreamPlayer = _players[_current]
	old.stream_paused = false
	_current = 1 - _current
	var other: AudioStreamPlayer = _players[_current]
	other.stop()
	var fresh: AudioStreamPlayer = _players[_current]
	fresh.stream = stream
	fresh.volume_db = -40.0 if crossfade else VOLUME_DB
	fresh.play()
	_fading = true
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(fresh, "volume_db", VOLUME_DB, FADE if crossfade else 0.01)
	if crossfade and old.playing:
		_tween.tween_property(old, "volume_db", -60.0, FADE)
	else:
		old.stop()
	_tween.chain().tween_callback(_after_fade.bind(old, crossfade))


func _after_fade(old: AudioStreamPlayer, _crossfade: bool) -> void:
	if old != _players[_current]:
		old.stop()
	_fading = false


func _process(_delta: float) -> void:
	if _fading or paused:
		return
	var player: AudioStreamPlayer = _players[_current]
	if player.stream == null:
		return
	var length := player.stream.get_length()
	var left := length - player.get_playback_position()
	# Only move on near the real end of a song (or if it has actually stopped).
	if (not player.playing and not player.stream_paused) or (length > FADE * 2.0 and left <= FADE):
		_play_next(true)


## A short, readable name for the track that's playing, e.g. "Tanz Zimmer".
func track_title() -> String:
	return _title_of(now_playing)
