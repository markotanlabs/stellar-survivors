extends Control
## Xander, Fleet Advisor (Philip's lost, estranged son): a jolly, sarcastic brain in a
## jar who pops up in the top-right corner to warn new players about risky moves.
## He only appears in Noob Mode.
## X turns him off (Settings can bring him back), the speaker mutes his voice blips,
## "Don't warn me about this" silences one warning for good.

const Sprite = preload("res://scripts/xander_sprite.gd")
const Sfx = preload("res://scripts/sfx.gd")
const Settings = preload("res://scripts/settings.gd")
const Lesson = preload("res://scripts/xander_lesson.gd")

const GOLD := Color("c9a55a")
const GOLD_TEXT := Color("f0d27a")
const SCALE := 1.6          # sprite pixels on screen
const WIDTH := 470.0        # the whole pop-up, portrait included
const LESSON_WIDTH := 620.0 # wider while he's teaching with an infographic
const TYPE_SPEED := 45.0    # characters per second

var _queue: Array = []      # [{key, text, tip, alert}]
var _current := {}
var _shown := 0.0           # characters revealed
var _t := 0.0
var _panel: PanelContainer
var _portrait: Control
var _frame: Control         # the small portrait beside one-liners
var _big_frame: Control     # lessons: a twice-size Xander in the top-left of the panel
var _big_portrait: Control
var _text: Label
var _tip: Label
var _mute: Button
var _said := {}             # keys already said this run
var _row: HBoxContainer
var _keys_row: HBoxContainer      # 3D keycaps for keys he mentions (e.g. SPACE)
var _key_caps: Array = []
var _art: Control           # the animated infographic (lessons only)
var _title: Label           # lesson page title
var _pager: Label           # "2 / 4"
var _ok: Button             # GOT IT / NEXT
var _back: Button
var _lesson: Array = []     # pages: [{title, art, text, tip}]
var _page := 0
var _paused_game := false   # we paused the game for a lesson and owe an unpause


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Top right, under the top bar (the HUD keeps it beside the notifications).
	anchor_left = 1.0
	anchor_right = 1.0
	anchor_top = 0.0
	anchor_bottom = 0.0
	offset_left = -16.0 - WIDTH
	offset_right = -16.0
	offset_top = 60.0
	offset_bottom = 60.0
	_build()
	visible = false


## Queue a line. key: one warning type (said once per run, and never again once the
## player asks not to be warned). alert: the red-eyed, twitchy pose.
## keys: hotkeys to show as 3D keycaps under the line, like the key bar's (e.g. ["SPACE"]).
func say(key: String, text: String, tip: String = "", alert: bool = true, keys: Array = []) -> void:
	if not Settings.xander_on() or Settings.advisor_dismissed.has(key) or _said.has(key):
		return
	_said[key] = true
	_queue.append({"key": key, "text": text, "tip": tip, "alert": alert, "keys": keys})
	if _current.is_empty():
		_next()


## Queue a lesson: several pages, each with an animated infographic. The game pauses
## while he teaches. Same rules as say(): once per run, never again once dismissed.
## done (optional) runs when the lesson closes however it closes, e.g. to open the
## card screen a Growth bubble was holding back.
func teach(key: String, pages: Array, done: Callable = Callable()) -> void:
	if not would_teach(key):
		if done.is_valid():
			done.call()
		return
	_said[key] = true
	_queue.append({"key": key, "lesson": pages, "alert": false, "done": done})
	if _current.is_empty():
		_next()


## Counts a tip as given this run (used when it's shown somewhere else, like a card window).
func mark_said(key: String) -> void:
	_said[key] = true


## True if this lesson would show now (Noob Mode on, not dismissed, not yet given this run).
func would_teach(key: String) -> bool:
	return Settings.xander_on() and not Settings.advisor_dismissed.has(key) and not _said.has(key)


func _next() -> void:
	_end_lesson()
	_finish_current()
	if _queue.is_empty():
		_current = {}
		visible = false
		return
	_current = _queue.pop_front()
	if _current.has("lesson"):
		_lesson = _current["lesson"]
		_page = 0
		_pause_for_lesson()
		_show_page()
	else:
		_lesson = []
		_pause_for_lesson()   # his one-line advice pauses the game too (v0.9.209)
		_set_lesson_layout(false)
		_show_line(String(_current["text"]), String(_current["tip"]))
		_set_keys(_current.get("keys", []))
	visible = true
	Sfx.ui("card_appear", -6.0)


func _show_line(text: String, tip: String) -> void:
	_shown = 0.0
	_text.text = text
	_text.visible_characters = 0
	_tip.text = tip
	_tip.visible = _tip.text != ""
	_tip.modulate.a = 0.0


## Shows the given keys as 3D keycaps (the HUD's own key style) under his line.
func _set_keys(keys: Array) -> void:
	for cap in _key_caps:
		(cap as Node).queue_free()
	_key_caps.clear()
	var hud := get_parent()
	_keys_row.visible = not keys.is_empty() and hud != null and hud.has_method("_keycap")
	if not _keys_row.visible:
		return
	for k in keys:
		var cap: Control = hud.call("_keycap", String(k), false)
		_keys_row.add_child(cap)
		_key_caps.append(cap)


func _show_page() -> void:
	_set_keys([])
	_set_lesson_layout(true)
	var pg: Dictionary = _lesson[_page]
	_title.text = "  ·  " + String(pg.get("title", ""))
	_pager.text = "%d / %d" % [_page + 1, _lesson.size()]
	_pager.visible = _lesson.size() > 1
	_art.call("set_page", String(pg.get("art", "")))
	_show_line(String(pg.get("text", "")), String(pg.get("tip", "")))
	_back.visible = _page > 0
	_ok.text = "  " + ("GOT IT" if _page == _lesson.size() - 1 else "NEXT  >") + "  "


func _set_lesson_layout(on: bool) -> void:
	_art.visible = on
	_title.visible = on
	_pager.visible = on
	_back.visible = on and _page > 0
	if not on:
		_ok.text = "  GOT IT  "
	# Lessons: the big Xander takes over from the small side portrait.
	_frame.visible = not on
	_big_frame.visible = on
	var w := 360.0 if on else 330.0
	_text.custom_minimum_size = Vector2(w, 0)
	_tip.custom_minimum_size = Vector2(w, 0)


func _pause_for_lesson() -> void:
	if not get_tree().paused:
		get_tree().paused = true
		_paused_game = true


## Runs the closing lesson's done callback, once.
func _finish_current() -> void:
	if _current.is_empty() or not _current.has("done"):
		return
	var done: Callable = _current["done"]
	_current.erase("done")
	if done.is_valid():
		done.call()


## Unpause only if the lesson paused the game and nothing else wants it paused.
func _end_lesson() -> void:
	if not _paused_game:
		return
	_paused_game = false
	var hud := get_parent()
	if hud != null:
		if hud.has_method("has_card_screen") and bool(hud.call("has_card_screen")):
			return
		if hud.has_method("is_pause_menu_open") and bool(hud.call("is_pause_menu_open")):
			return
		if bool(hud.get("_paused_by_player")):
			return
	get_tree().paused = false


func _process(delta: float) -> void:
	if not visible:
		return
	_t += delta
	var total := _text.text.length()
	if _shown < total:
		var before := int(_shown)
		_shown = minf(float(total), _shown + TYPE_SPEED * delta)
		_text.visible_characters = int(_shown)
		# A little blip every few letters: his voice.
		if not Settings.advisor_muted and int(_shown) / 3 != before / 3:
			Sfx.ui("blip", -14.0)
	elif _tip.modulate.a < 1.0:
		_tip.modulate.a = minf(1.0, _tip.modulate.a + delta * 3.0)
	_portrait.queue_redraw()
	# The keycaps tap down now and then, like someone pressing them.
	if not _key_caps.is_empty():
		var hud := get_parent()
		var pressed := fmod(_t, 1.4) < 0.25
		for cap in _key_caps:
			(cap as Control).add_theme_stylebox_override("panel", hud.call("_keycap_style", pressed))
	if _big_frame.visible:
		_big_portrait.queue_redraw()


# --- buttons ---------------------------------------------------------------------

func _got_it() -> void:
	Sfx.ui("click")
	if not _lesson.is_empty() and _page < _lesson.size() - 1:
		_page += 1
		_show_page()
		return
	_next()


func _go_back() -> void:
	Sfx.ui("click")
	if _page > 0:
		_page -= 1
		_show_page()


func _dont_warn() -> void:
	Sfx.ui("click")
	if not _current.is_empty():
		Settings.advisor_dismissed.append(String(_current["key"]))
		Settings.save_settings()
	_next()


func _close() -> void:
	# X: Xander goes quiet for good (turn him back on in Settings).
	Sfx.ui("click")
	Settings.advisor_on = false
	Settings.save_settings()
	hush()


## Drops whatever he was saying (Noob Mode or Xander switched off mid-run).
func hush() -> void:
	_end_lesson()
	_finish_current()
	for item in _queue:
		var done: Callable = (item as Dictionary).get("done", Callable())
		if done.is_valid():
			done.call()
	_queue.clear()
	_current = {}
	_lesson = []
	visible = false


func width() -> float:
	return LESSON_WIDTH if (visible and not _lesson.is_empty()) else WIDTH


func height() -> float:
	return _row.size.y if _row != null else 0.0


func _toggle_mute() -> void:
	Settings.advisor_muted = not Settings.advisor_muted
	Settings.save_settings()
	_mute.text = "MUTED" if Settings.advisor_muted else "SOUND"
	_mute.tooltip_text = "Unmute Xander" if Settings.advisor_muted else "Mute Xander"
	Sfx.ui("click")


# --- layout ----------------------------------------------------------------------

func _build() -> void:
	# One compact strip: small portrait on the left, the message beside it.
	var row := HBoxContainer.new()
	_row = row
	row.add_theme_constant_override("separation", -6)
	row.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	row.grow_vertical = Control.GROW_DIRECTION_END   # longer messages grow downward
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)
	# Portrait: a dark teal frame with the animated sprite.
	var frame := PanelContainer.new()
	_frame = frame
	frame.z_index = 1
	var fs := StyleBoxFlat.new()
	fs.bg_color = Color("0c2129")
	fs.border_color = GOLD
	fs.set_border_width_all(2)
	fs.set_corner_radius_all(4)
	fs.shadow_color = Color(0.37, 0.81, 0.75, 0.18)
	fs.shadow_size = 8
	frame.add_theme_stylebox_override("panel", fs)
	frame.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(frame)
	_portrait = Portrait.new()
	_portrait.custom_minimum_size = Vector2(84, 104)
	_portrait.set("owner_popup", self)
	frame.add_child(_portrait)
	# The message box.
	_panel = PanelContainer.new()
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.035, 0.05, 0.1, 0.94)
	ps.border_color = GOLD
	ps.set_border_width_all(2)
	ps.set_corner_radius_all(4)
	ps.shadow_color = Color(0, 0, 0, 0.5)
	ps.shadow_size = 10
	ps.content_margin_left = 18
	ps.content_margin_right = 10
	ps.content_margin_top = 6
	ps.content_margin_bottom = 10
	_panel.add_theme_stylebox_override("panel", ps)
	_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	row.add_child(_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 5)
	_panel.add_child(column)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 2)
	column.add_child(head)
	_label(head, "XANDER", 14, GOLD_TEXT)
	_title = _label(head, "", 14, Color("f4efe2"))
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_child(gap)
	_pager = _label(head, "", 12, Color("8fa3b8"))
	_mute = _small_button(head, "SOUND" if not Settings.advisor_muted else "MUTED", _toggle_mute)
	_mute.tooltip_text = "Mute Xander" if not Settings.advisor_muted else "Unmute Xander"
	var x := _small_button(head, "X", _close)
	x.tooltip_text = "Turn Xander off (Settings brings him back)"
	# Body: (lessons only) a big framed Xander top-left, his words beside him.
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 14)
	column.add_child(body)
	var big := PanelContainer.new()
	_big_frame = big
	big.add_theme_stylebox_override("panel", fs.duplicate() as StyleBoxFlat)
	big.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	big.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(big)
	_big_portrait = Portrait.new()
	_big_portrait.custom_minimum_size = Vector2(168, 208)
	_big_portrait.set("owner_popup", self)
	big.add_child(_big_portrait)
	var words := VBoxContainer.new()
	words.add_theme_constant_override("separation", 8)
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	body.add_child(words)
	_art = Lesson.new()
	_art.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(_art)
	_text = _label(words, "", 16, Color("f4efe2"))
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.custom_minimum_size = Vector2(330, 0)
	_text.add_theme_constant_override("line_spacing", 2)
	_text.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	_text.add_theme_constant_override("outline_size", 2)
	_keys_row = HBoxContainer.new()
	_keys_row.add_theme_constant_override("separation", 8)
	_keys_row.visible = false
	words.add_child(_keys_row)
	_tip = _label(words, "", 13, Color("9fb6c8"))
	_tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tip.custom_minimum_size = Vector2(330, 0)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 8)
	column.add_child(buttons)
	_back = _wide_button(buttons, "<  BACK", _go_back, false)
	_ok = _wide_button(buttons, "GOT IT", _got_it, true)
	_wide_button(buttons, "DON'T WARN ME AGAIN", _dont_warn, false)
	_set_lesson_layout(false)


func _label(parent: Control, text: String, size: int, colour: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", colour)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l


func _small_button(parent: Control, text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	# Bigger targets (v0.9.156): the X especially.
	b.custom_minimum_size = Vector2(44, 38) if text.length() == 1 else Vector2(40, 32)
	b.add_theme_font_size_override("font_size", 13 if text.length() > 1 else 22)
	b.add_theme_color_override("font_color", Color("c9d2d8"))
	b.add_theme_color_override("font_hover_color", GOLD_TEXT)
	b.pressed.connect(action)
	parent.add_child(b)
	return b


func _wide_button(parent: Control, text: String, action: Callable, primary: bool) -> Button:
	var b := Button.new()
	b.text = "  " + text + "  "
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(130 if primary else 0, 38)   # bigger targets (v0.9.156; was 26 tall)
	b.add_theme_font_size_override("font_size", 16 if primary else 13)
	var st := StyleBoxFlat.new()
	st.bg_color = Color("1a1408") if primary else Color(0, 0, 0, 0)
	st.border_color = GOLD if primary else Color("3a4658")
	st.set_border_width_all(2)
	var hv := st.duplicate() as StyleBoxFlat
	hv.bg_color = Color("2a2414")
	hv.border_color = GOLD_TEXT
	b.add_theme_stylebox_override("normal", st)
	b.add_theme_stylebox_override("hover", hv)
	b.add_theme_stylebox_override("pressed", hv)
	b.add_theme_color_override("font_color", GOLD_TEXT if primary else Color("aab8c6"))
	b.pressed.connect(action)
	parent.add_child(b)
	return b


func is_alert() -> bool:
	return not _current.is_empty() and bool(_current.get("alert", false))


## The animated sprite: bobbing jar, swaying eyestalks, crackling electric eyebrows.
class Portrait extends Control:
	const Spr = preload("res://scripts/xander_sprite.gd")
	var owner_popup: Control = null
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta

	func _draw() -> void:
		# Scales with the box: 1.6 in the small side portrait, 3.2 in the big lesson one.
		var k := size.x / 52.5
		var alert := owner_popup != null and bool(owner_popup.call("is_alert"))
		var glow := Color(0.37, 0.81, 0.75, 0.22)
		draw_circle(size / 2.0 + Vector2(0, 2.5 * k), 21.0 * k, glow)
		var origin := Vector2((size.x - Spr.W * k) / 2.0, size.y - Spr.H * k - 2.0 * k + sin(_t * 2.0) * k)
		var sway := 4.0 if alert else 1.0
		var speed := 9.0 if alert else 2.2
		for i in 2:
			var base: Vector2 = Spr.STALK_BASES[i]
			var angle := deg_to_rad(5.0 * sway) * sin(_t * speed + i * 1.3)
			var pivot := origin + base * k
			draw_set_transform(pivot, angle, Vector2.ONE)
			var layer: Array = Spr.STALK0_ALERT if (i == 0 and alert) else (Spr.STALK0 if i == 0 else (Spr.STALK1_ALERT if alert else Spr.STALK1))
			_runs(layer, -base * k, k)
			var eye: Vector2 = Spr.EYES[i]
			_brows((eye - Vector2(0.5, 0.5) - base) * k, i, alert, k)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		_runs(Spr.BODY, origin, k)

	func _runs(layer: Array, at: Vector2, k: float) -> void:
		for r in layer:
			draw_rect(Rect2(at + Vector2(float(r[0]), float(r[1])) * k, Vector2(float(r[2]) * k, k)), Spr.PALETTE[int(r[3])])

	## Electric eyebrows: a zig-zag of white-and-cyan pixels that flips every few
	## frames. Jolly arch (left), sarcastic cocked brow (right), angry when alerting.
	func _brows(eye: Vector2, i: int, alert: bool, k: float) -> void:
		var pts: Array
		if alert:
			pts = [[-3, -7], [-2, -7], [-1, -6], [0, -6], [1, -5], [2, -5]] if i == 0 else [[-2, -5], [-1, -5], [0, -6], [1, -6], [2, -7], [3, -7]]
		elif i == 0:
			pts = [[-3, -5], [-2, -6], [-1, -7], [0, -7], [1, -6], [2, -5]]
		else:
			pts = [[-3, -6], [-2, -6], [-1, -7], [0, -8], [1, -8], [2, -9], [3, -9]]
		var frame := int(_t * 12.0) % 2
		var origin := eye
		for n in pts.size():
			var p: Array = pts[n]
			var dy := 1 - (1 if (n + frame) % 2 == 1 else 0)
			var at := origin + Vector2(float(p[0]), float(p[1]) + dy) * k
			draw_rect(Rect2(at, Vector2(k, k)), Color.WHITE)
			draw_rect(Rect2(at + Vector2(0, k), Vector2(k, k)), Color("46c8e8"))
		draw_circle(origin + Vector2(0, -6.5 * k), 2.2 * k, Color(0.5, 0.95, 1.0, 0.18))
