extends CanvasLayer
## Press Enter anywhere: the game pauses and a small feedback panel opens.
## Sends straight to the MarkoLabs Google Form (a plain form POST, no account needed).
## If the player is offline, the note is kept in user://feedback_outbox.json and sent next time.

# --- Google Form wiring -------------------------------------------------------------------
# FORM_ID is the long id in the form's public link: docs.google.com/forms/d/e/<FORM_ID>/viewform
# The entry ids come from the form's "Get pre-filled link" (entry.123456789=...).
const FORM_ID := "1FAIpQLSfYO7JDTvxaGt6BWfYpingsADwuaQLbb9UXPp2ij6CFgl7A2A"
const ENTRY_TEXT := "entry.1005726730"     # "What happened?" (paragraph)
const ENTRY_KIND := "entry.719166205"     # "Type" (Bug / Idea / Balance / Other)
const ENTRY_FUN := "entry.1066107716"      # "How fun is it right now?" (1-5)
const ENTRY_INFO := "entry.256211927"     # "Game info" (filled in by the game)
# ------------------------------------------------------------------------------------------

const GD = preload("res://scripts/game_data.gd")
const Sfx = preload("res://scripts/sfx.gd")

const OUTBOX := "user://feedback_outbox.json"
const KINDS := ["Bug", "Idea", "Balance", "Other"]
const GOLD := Color("e8c547")
const TEXT := Color("e9e6dc")
const DIM := Color("93a3ad")

static var is_open := false
static var shared: CanvasLayer = null   # the live panel node, for buttons that open it
static var _flushed := false

var _root: Control
var _text: TextEdit
var _kind := ""
var _fun := 0
var _kind_buttons: Array = []
var _fun_buttons: Array = []
var _status: Label
var _send_button: Button
var _was_paused := false
var _http: HTTPRequest
var _sending: Array = []     # the notes in flight (each a Dictionary of fields)
var _closing := false


func _ready() -> void:
	shared = self
	layer = 120
	process_mode = Node.PROCESS_MODE_ALWAYS
	_http = HTTPRequest.new()
	_http.timeout = 12.0
	add_child(_http)
	_http.request_completed.connect(_on_sent)
	if not _flushed:
		_flushed = true
		_flush_outbox.call_deferred()


func _exit_tree() -> void:
	if shared == self:
		shared = null
	if _root != null:
		is_open = false


static func configured() -> bool:
	return FORM_ID != "" and ENTRY_TEXT != ""


func _input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	var enter: bool = key.keycode == KEY_ENTER or key.keycode == KEY_KP_ENTER
	if _root == null:
		if enter and not key.ctrl_pressed and not key.alt_pressed:
			var focus := get_viewport().gui_get_focus_owner()
			if focus is LineEdit or focus is TextEdit:
				return
			open()
			get_viewport().set_input_as_handled()
		return
	if key.keycode == KEY_ESCAPE:
		close()
		get_viewport().set_input_as_handled()
	elif enter and (key.ctrl_pressed or key.meta_pressed):
		_send()
		get_viewport().set_input_as_handled()


func open() -> void:
	if _root != null:
		return
	is_open = true
	_closing = false
	_was_paused = get_tree().paused
	get_tree().paused = true
	Sfx.ui("blip")
	_kind = ""
	_fun = 0
	_kind_buttons.clear()
	_fun_buttons.clear()

	_root = ColorRect.new()
	(_root as ColorRect).color = Color(0.02, 0.03, 0.05, 0.72)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var centre := CenterContainer.new()
	_root.add_child(centre)
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.14, 0.18, 0.23, 0.97)
	style.set_border_width_all(2)
	style.border_width_top = 4
	style.border_color = GOLD
	style.content_margin_left = 30
	style.content_margin_right = 30
	style.content_margin_top = 24
	style.content_margin_bottom = 24
	panel.add_theme_stylebox_override("panel", style)
	panel.custom_minimum_size = Vector2(620, 0)
	centre.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	panel.add_child(col)

	var title := _label(col, GOLD, 32)
	title.text = "SEND FEEDBACK"
	var sub := _label(col, DIM, 15)
	sub.text = "Bugs, ideas, anything. It goes straight to the developer."

	_text = TextEdit.new()
	_text.custom_minimum_size = Vector2(0, 170)
	_text.placeholder_text = "What happened? What did you expect?"
	_text.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_text.add_theme_font_size_override("font_size", 18)
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.043, 0.071, 0.094, 0.95)
	box.border_color = Color("3a4a56")
	box.set_border_width_all(1)
	box.set_corner_radius_all(3)
	box.content_margin_left = 10
	box.content_margin_right = 10
	box.content_margin_top = 8
	box.content_margin_bottom = 8
	_text.add_theme_stylebox_override("normal", box)
	var box_focus := box.duplicate() as StyleBoxFlat
	box_focus.border_color = GOLD
	_text.add_theme_stylebox_override("focus", box_focus)
	col.add_child(_text)

	var kind_row := HBoxContainer.new()
	kind_row.add_theme_constant_override("separation", 8)
	col.add_child(kind_row)
	var kl := _label(kind_row, TEXT, 17)
	kl.text = "Type"
	kl.custom_minimum_size = Vector2(150, 0)
	for k in KINDS:
		var b := _chip(kind_row, String(k))
		var kind_name := String(k)
		b.pressed.connect(func() -> void: _pick_kind(kind_name))
		_kind_buttons.append(b)

	var fun_row := HBoxContainer.new()
	fun_row.add_theme_constant_override("separation", 8)
	col.add_child(fun_row)
	var fl := _label(fun_row, TEXT, 17)
	fl.text = "Fun so far"
	fl.custom_minimum_size = Vector2(150, 0)
	for i in range(1, 6):
		var b := _chip(fun_row, str(i))
		b.custom_minimum_size = Vector2(46, 38)
		var n := i
		b.pressed.connect(func() -> void: _pick_fun(n))
		_fun_buttons.append(b)

	var info := _label(col, DIM, 13)
	info.text = "Attached automatically: " + _context_line()
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 12)
	col.add_child(bottom)
	_status = _label(bottom, DIM, 15)
	_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status.text = "Ctrl+Enter to send · Esc to close"
	var cancel := _chip(bottom, "Cancel")
	cancel.pressed.connect(close)
	_send_button = _chip(bottom, "Send")
	_send_button.pressed.connect(_send)
	_gold(_send_button)

	_root.modulate.a = 0.0
	var tw := _root.create_tween()
	tw.tween_property(_root, "modulate:a", 1.0, 0.12)
	_text.grab_focus.call_deferred()


func close() -> void:
	if _root == null or _closing:
		return
	_closing = true
	var root := _root
	var tw := root.create_tween()
	tw.tween_property(root, "modulate:a", 0.0, 0.1)
	var done := func() -> void:
		root.queue_free()
		if _root == root:
			_root = null
			is_open = false
			get_tree().paused = _was_paused
	tw.tween_callback(done)


# --- Sending ---------------------------------------------------------------------------

func _send() -> void:
	if _root == null or _closing:
		return
	var body := _text.text.strip_edges()
	if body == "":
		_status.text = "Write a line or two first."
		_status.add_theme_color_override("font_color", Color("ff8a6a"))
		return
	var note := {
		"text": body,
		"kind": _kind if _kind != "" else "Other",
		"fun": str(_fun) if _fun > 0 else "",
		"info": _context_line(),
	}
	Sfx.ui("click")
	var outbox := _load_outbox()
	outbox.append(note)
	_save_outbox(outbox)
	if configured():
		_flush_outbox()
		_status.text = "Thanks! Sent."
	else:
		_status.text = "Thanks! Saved (sending isn't set up yet)."
	_status.add_theme_color_override("font_color", Color("8fd18a"))
	_send_button.disabled = true
	var tw := _root.create_tween()
	tw.tween_interval(0.9)
	tw.tween_callback(close)


func _flush_outbox() -> void:
	if not configured() or not _sending.is_empty():
		return
	var outbox := _load_outbox()
	if outbox.is_empty():
		return
	var note: Dictionary = outbox[0]
	_sending = [note]
	var url := "https://docs.google.com/forms/d/e/%s/formResponse" % FORM_ID
	var fields := {ENTRY_TEXT: note.get("text", "")}
	if ENTRY_KIND != "":
		fields[ENTRY_KIND] = note.get("kind", "")
	if ENTRY_FUN != "" and String(note.get("fun", "")) != "":
		fields[ENTRY_FUN] = note.get("fun", "")
	if ENTRY_INFO != "":
		fields[ENTRY_INFO] = note.get("info", "")
	var parts := PackedStringArray()
	for k in fields.keys():
		parts.append("%s=%s" % [String(k), String(fields[k]).uri_encode()])
	var headers := PackedStringArray(["Content-Type: application/x-www-form-urlencoded"])
	var err := _http.request(url, headers, HTTPClient.METHOD_POST, "&".join(parts))
	if err != OK:
		_sending.clear()


func _on_sent(result: int, code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	var ok: bool = result == HTTPRequest.RESULT_SUCCESS and code >= 200 and code < 400
	var sent: Array = _sending
	_sending = []
	if not ok:
		return   # stays in the outbox; tried again next launch or next note
	var outbox := _load_outbox()
	if not sent.is_empty() and not outbox.is_empty():
		outbox.remove_at(0)   # the oldest note is the one that was in flight
	_save_outbox(outbox)
	if not outbox.is_empty():
		_flush_outbox.call_deferred()


func _load_outbox() -> Array:
	if not FileAccess.file_exists(OUTBOX):
		return []
	var f := FileAccess.open(OUTBOX, FileAccess.READ)
	if f == null:
		return []
	var data: Variant = JSON.parse_string(f.get_as_text())
	if data is Array:
		return data
	return []


func _save_outbox(list: Array) -> void:
	var f := FileAccess.open(OUTBOX, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(list))


# --- Context ---------------------------------------------------------------------------

func _context_line() -> String:
	var parts := PackedStringArray(["v" + GD.VERSION])
	var scene := get_tree().current_scene
	if scene != null and scene.has_method("feedback_context"):
		var ctx: Dictionary = scene.call("feedback_context")
		for k in ["day", "time", "system", "view"]:
			if ctx.has(k):
				parts.append("%s %s" % [k, str(ctx[k])])
	elif scene != null:
		parts.append("scene " + str(scene.name))
	parts.append("%d fps" % Engine.get_frames_per_second())
	parts.append(OS.get_name())
	return " · ".join(parts)


# --- Widgets ---------------------------------------------------------------------------

func _pick_kind(k: String) -> void:
	_kind = k
	for b in _kind_buttons:
		(b as Button).button_pressed = (b as Button).text == k


func _pick_fun(n: int) -> void:
	_fun = n
	for i in _fun_buttons.size():
		(_fun_buttons[i] as Button).button_pressed = i + 1 == n


func _label(parent: Control, colour: Color, size: int) -> Label:
	var label := Label.new()
	label.add_theme_color_override("font_color", colour)
	label.add_theme_font_size_override("font_size", size)
	parent.add_child(label)
	return label


func _chip(parent: Control, text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.toggle_mode = true
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 38)
	b.add_theme_font_size_override("font_size", 17)
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.043, 0.071, 0.094, 0.9)
	st.border_color = Color("3a4a56")
	st.set_border_width_all(1)
	st.set_corner_radius_all(3)
	st.content_margin_left = 14
	st.content_margin_right = 14
	var hv := st.duplicate() as StyleBoxFlat
	hv.border_color = Color("7d8f9b")
	var on := st.duplicate() as StyleBoxFlat
	on.bg_color = Color("2a2414")
	on.border_color = GOLD
	b.add_theme_stylebox_override("normal", st)
	b.add_theme_stylebox_override("hover", hv)
	b.add_theme_stylebox_override("pressed", on)
	b.add_theme_stylebox_override("hover_pressed", on)
	b.add_theme_color_override("font_color", TEXT)
	b.add_theme_color_override("font_pressed_color", Color("f0d27a"))
	b.add_theme_color_override("font_hover_pressed_color", Color("f0d27a"))
	parent.add_child(b)
	return b


func _gold(b: Button) -> void:
	b.toggle_mode = false
	var st := StyleBoxFlat.new()
	st.bg_color = Color("1a1408")
	st.border_color = Color("c9a55a")
	st.set_border_width_all(2)
	st.set_corner_radius_all(4)
	st.content_margin_left = 22
	st.content_margin_right = 22
	var hv := st.duplicate() as StyleBoxFlat
	hv.bg_color = Color("2a2414")
	hv.border_color = Color("f0d27a")
	b.add_theme_stylebox_override("normal", st)
	b.add_theme_stylebox_override("hover", hv)
	b.add_theme_stylebox_override("pressed", hv)
	b.add_theme_color_override("font_color", Color("f0d27a"))
	b.add_theme_color_override("font_hover_color", Color("fff1c2"))
