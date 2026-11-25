extends CanvasLayer
## Top bar (resources with their per-tick income, Starbase count, next tick),
## the hotkey bar drawn as keyboard keys, the Fleet Mode banner and the build menu.

signal build_requested(item_id: String)
signal unqueue_requested(item_id: String)   # right-click a ship's build button: take one out of the queue
signal card_picked(card_name: String)
signal redraw_requested   # the gold Redraw button on a card reward screen
signal shop_buy(slot: int)
signal shop_refresh
signal shop_leave
signal restart_requested
signal menu_requested
signal notification_clicked(system_index: int, pos_px: Vector2)
signal reward_slot_clicked(planet: Dictionary)
signal guide_closed
signal collection_requested   # the card fan next to the XP bar was clicked

const GD = preload("res://scripts/game_data.gd")
const Sfx = preload("res://scripts/sfx.gd")
const Settings = preload("res://scripts/settings.gd")
const ResIconControl = preload("res://scripts/res_icon_control.gd")
const IconText = preload("res://scripts/icon_text.gd")
const DealerPortrait = preload("res://scripts/dealer_portrait.gd")
const IconWrap = preload("res://scripts/icon_wrap.gd")
const WreckHolo = preload("res://scripts/wreck_holo.gd")
const FleetStatus = preload("res://scripts/fleet_status.gd")
const CardArt = preload("res://scripts/card_art.gd")
const ShipInfo = preload("res://scripts/ship_info.gd")
const Xander = preload("res://scripts/xander.gd")
const PlanetBody = preload("res://scripts/planet_body.gd")
const FeedbackPanel = preload("res://scripts/feedback.gd")

const BUILD_STRUCTURES := ["starbase", "shipyard", "mag"]
const BUILD_SHIPS := ["corvette", "frigate", "destroyer", "cruiser", "carrier", "battleship"]

var _values := {}
var _gains := {}
var _starbases: Label
var _tick: Label
var _location: Label
var _fleet_banner: Label
var _fleet_mode_on := false
var _keys := {}
var _key_labels := {}
var _paused_by_player := false
var _pause_menu: Control = null
var _pause_settings: Control = null
var pause_blocked: Callable = Callable()   # main: true while Esc has something else to close
var _pause_label: Label
var _pause_frame: PanelContainer = null   # the glowing frame round PAUSED
var _pause_style: StyleBoxFlat = null
var _build_panel: PanelContainer
var _build_buttons := {}
var _build_open := false
var _glow_f := false
var _f_glow_style: StyleBoxFlat = null
var _f_was_glowing := false
var _glow_time := 0.0
var _toast: IconText
var _toast_time := 0.0
var _planet_panel: PanelContainer
var _planet_box: VBoxContainer
var _planet: Dictionary = {}
var _planet_income: Dictionary = {}
var _card_layer: Control
var fly_target := Vector2.ZERO   # screen position the picked card flies to
var earth_target := Vector2.ZERO # where Tech cards bought at a shop fly to
var _flying := false
var _card_column: VBoxContainer = null   # the open card window's column (Xander's advice strip goes in it)
var _xp_fill: ColorRect
var _xp_label: Label
var _xp_frame: PanelContainer
var _xp_frame_style: StyleBoxFlat
var _xp_back: Control
var _xp_gleam: ColorRect
var _xp_glow := 0.0
var _notify_box: VBoxContainer
var _vignette: ColorRect
var _wave_label: Label
var _prompt_label: IconText
var _prompt_plate: PanelContainer = null   # the dark plate the prompt sits on
var _warn_layer: Control
var _warn_buttons: Array = []
var _warnings: Array = []     # [{kind, screen: Vector2, angle: float, system, pos}]
var _card_popup: Control
var _names_shown := false
var _top_row: HBoxContainer
var _reticle_label: Label
var _fade: ColorRect
var _wave_pill: PanelContainer
var _music: Node = null
var _music_ticker: Label
var _music_clip: Control
var _music_play: Button
var _music_list: PanelContainer
var _ticker_x := 0.0
var _low_health := 1.0
var fleet_status: Control = null   # the ship-status wireframes, bottom right
var xander: Control = null         # the Fleet Advisor pop-up, top right
var _pulse := 0.0


## Guide only: the title screen borrows the HUD just to show the start-of-run
## tutorial pages (clicking the Space 4 Dummies book). Nothing else is built.
var guide_only := false


func _ready() -> void:
	layer = 2
	process_mode = Node.PROCESS_MODE_ALWAYS
	if guide_only:
		layer = 6
		set_process(false)
		set_process_unhandled_input(false)
		return
	_make_top_bar()
	_make_objectives()
	_make_hotkey_bar()
	fleet_status = FleetStatus.new()
	add_child(fleet_status)
	xander = Xander.new()
	add_child(xander)
	_make_build_panel()
	_make_planet_panel()
	_make_xp_bar()
	_fleet_banner = Label.new()
	_fleet_banner.text = "FLEET MODE  ·  WASD steer  ·  hold left-click to fire  ·  F to leave"
	_fleet_banner.add_theme_font_size_override("font_size", 22)
	_fleet_banner.add_theme_color_override("font_color", Color("8fb4e3"))
	_fleet_banner.add_theme_color_override("font_outline_color", Color("0b0e14"))
	_fleet_banner.add_theme_constant_override("outline_size", 6)
	_fleet_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_fleet_banner)
	_fleet_banner.anchor_left = 0.0
	_fleet_banner.anchor_right = 1.0
	_fleet_banner.offset_top = 64.0
	_fleet_banner.offset_bottom = 96.0
	_fleet_banner.visible = false
	_toast = IconText.new(20, Color("e8c547"), 6)   # "{alloys}40" shows as an icon
	add_child(_toast)
	_toast.anchor_right = 1.0
	_toast.offset_top = 142.0
	_toast.offset_bottom = 172.0
	# PAUSED: big gold text in a dark frame with a glowing, breathing gold border.
	_pause_frame = PanelContainer.new()
	_pause_style = StyleBoxFlat.new()
	_pause_style.bg_color = Color(0.02, 0.03, 0.05, 0.88)
	_pause_style.border_color = Color("e8c547")
	_pause_style.set_border_width_all(3)
	_pause_style.set_corner_radius_all(10)
	_pause_style.content_margin_left = 48
	_pause_style.content_margin_right = 48
	_pause_style.content_margin_top = 12
	_pause_style.content_margin_bottom = 14
	_pause_style.shadow_color = Color(0.91, 0.77, 0.28, 0.45)
	_pause_style.shadow_size = 18
	_pause_frame.add_theme_stylebox_override("panel", _pause_style)
	_pause_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_pause_frame)
	_pause_frame.anchor_left = 0.5
	_pause_frame.anchor_right = 0.5
	_pause_frame.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_pause_frame.offset_top = 170.0
	_pause_frame.visible = false
	var pause_column := VBoxContainer.new()
	pause_column.add_theme_constant_override("separation", 2)
	pause_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pause_frame.add_child(pause_column)
	_pause_label = Label.new()
	_pause_label.text = "PAUSED"
	_pause_label.add_theme_font_size_override("font_size", 48)
	_pause_label.add_theme_color_override("font_color", Color("f0d27a"))
	_pause_label.add_theme_color_override("font_outline_color", Color("0b0e14"))
	_pause_label.add_theme_constant_override("outline_size", 8)
	_pause_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_column.add_child(_pause_label)
	var resume := Label.new()
	resume.text = "Press P to resume"
	resume.add_theme_font_size_override("font_size", 18)
	resume.add_theme_color_override("font_color", Color("c9d2d8"))
	resume.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_column.add_child(resume)
	_make_wave_and_prompt()
	_make_warning_layer()
	# Every button in the HUD clicks and ticks on hover.
	get_tree().node_added.connect(_on_node_added)
	# Low Kharkiv health: a faint red glow at the screen edges.
	_vignette = ColorRect.new()
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_vignette)
	move_child(_vignette, 0)
	_vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shader := Shader.new()
	shader.code = """shader_type canvas_item;
uniform float strength = 0.0;
void fragment() {
	vec2 uv = UV - vec2(0.5);
	float d = length(uv * vec2(1.0, 0.75));
	// Wider band that reaches further in as the strength rises.
	float edge = smoothstep(0.36 - 0.14 * strength, 0.68, d);
	COLOR = vec4(0.85, 0.03, 0.04, clamp(edge * strength, 0.0, 0.95));
}"""
	var material := ShaderMaterial.new()
	material.shader = shader
	_vignette.material = material
	_vignette.visible = false
	# Notification shade: event cards stacked in the top right.
	_notify_box = VBoxContainer.new()
	_notify_box.add_theme_constant_override("separation", 8)
	add_child(_notify_box)
	_notify_box.anchor_left = 1.0
	_notify_box.anchor_right = 1.0
	_notify_box.offset_left = -380.0
	_notify_box.offset_right = -16.0
	_notify_box.offset_top = 60.0
	# Xander draws over the notifications (they stay put behind him while he talks).
	move_child(xander, -1)


## Xander sits in the top-right corner, over the notifications, and steps aside with
## them when the build sidebar is out.
func _place_xander() -> void:
	if xander == null or _notify_box == null:
		return
	xander.offset_right = _notify_box.offset_right
	xander.offset_left = _notify_box.offset_right - float(xander.call("width"))


func _process(delta: float) -> void:
	_age_notifications(delta)
	if _pause_frame != null and _pause_frame.visible:
		# The frame's glow breathes while paused.
		var breathe := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 380.0)
		_pause_style.shadow_size = int(12.0 + 16.0 * breathe)
		_pause_style.shadow_color = Color(0.91, 0.77, 0.28, 0.3 + 0.35 * breathe)
		_pause_style.border_color = Color(0.91, 0.77, 0.28, 0.7 + 0.3 * breathe)
	# Card collector numbers show while Info (Space) is held, even on paused card screens.
	var info := Input.is_action_pressed("full_names")
	for badge in get_tree().get_nodes_in_group("card_numbers"):
		(badge as CanvasItem).visible = info
	if fleet_status != null and _build_panel != null:
		fleet_status.visible = not _build_panel.visible
	if _hotkey_grid != null:
		_hotkey_grid.visible = Settings.noob_mode   # the key reminders are for learners
	_place_xander()
	_update_xp_glow(delta)
	# Out of Fleet Mode, the F key glows to remind you how to take the helm.
	if _keys.has("F"):
		var cap: Control = _keys["F"]
		if _glow_f:
			_glow_time += delta
			var pulse := 0.5 + 0.5 * sin(_glow_time * 5.0)
			# A strong gold beacon: bright tint, a big pulsing halo and a slight swell.
			cap.modulate = Color(1.3, 1.2, 0.8).lerp(Color(2.2, 1.8, 0.6), pulse)
			if _f_glow_style == null:
				_f_glow_style = (_keycap_style(false) as StyleBoxFlat).duplicate() as StyleBoxFlat
				_f_glow_style.border_color = Color("e8c547")
				_f_glow_style.set_border_width_all(3)
			_f_glow_style.shadow_color = Color(0.91, 0.77, 0.28, 0.45 + 0.45 * pulse)
			_f_glow_style.shadow_size = int(8.0 + 16.0 * pulse)
			cap.add_theme_stylebox_override("panel", _f_glow_style)
			# Twice the size. It grows up and to the right from near its bottom-left corner
			# (it sits at the screen's left edge), and its "Fleet Mode" label moves over to
			# make room.
			cap.pivot_offset = Vector2(cap.size.x * 0.35, cap.size.y)
			cap.scale = Vector2.ONE * 2.0 * (1.0 + 0.12 * pulse)
			cap.z_index = 5
			var row := cap.get_parent() as HBoxContainer
			if row != null:
				row.add_theme_constant_override("separation", int(6.0 + cap.size.x * 0.95))
			_f_was_glowing = true
		elif _f_was_glowing:
			_f_was_glowing = false
			cap.modulate = Color(1, 1, 1)
			cap.scale = Vector2.ONE
			cap.z_index = 0
			var row := cap.get_parent() as HBoxContainer
			if row != null:
				row.add_theme_constant_override("separation", 6)
			cap.add_theme_stylebox_override("panel", _keycap_style(false))
	if _reticle_label != null and _reticle_label.visible:
		_reticle_label.position = get_viewport().get_mouse_position() + Vector2(-_reticle_label.size.x / 2.0, 26)
	_update_music_player(delta)
	if _warn_layer != null:
		_warn_layer.queue_redraw()
	if _objectives != null:
		_objectives.visible = GD.show_full_names
		if _objectives.visible:
			_objectives.position = Vector2(18.0, _top_row.get_global_rect().end.y + 18.0)
	if GD.show_full_names != _names_shown:
		_names_shown = GD.show_full_names
		if _planet_panel.visible:
			_fill_planet_panel()
	_update_vignette(delta)
	if _toast_time > 0.0:
		_toast_time -= delta
		_toast.modulate.a = clampf(_toast_time, 0.0, 1.0)


# --- objectives (top left, while Info is held) ------------------------------------

var _objectives: VBoxContainer = null
var _objective_rows: Array = []

func _make_objectives() -> void:
	_objectives = VBoxContainer.new()
	_objectives.add_theme_constant_override("separation", 4)
	_objectives.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_objectives.visible = false
	add_child(_objectives)
	var head := _make_label(_objectives, Color("f0d27a"), 13)
	head.text = "OBJECTIVES"
	head.add_theme_color_override("font_outline_color", Color("0b0e14"))
	head.add_theme_constant_override("outline_size", 4)
	for words in ["Destroy the Rock Rebels", "Retake Mars"]:
		var row := ObjectiveRow.new()
		row.text = words
		_objectives.add_child(row)
		_objective_rows.append(row)


## Ticks an objective off: 0 = the Rock Rebels, 1 = Mars.
func set_objective_done(index: int) -> void:
	if index >= 0 and index < _objective_rows.size():
		(_objective_rows[index] as Control).set("done", true)
		(_objective_rows[index] as Control).queue_redraw()


## One objective: a small box (ticked green when done) and the words.
class ObjectiveRow extends Control:
	var text := ""
	var done := false

	func _init() -> void:
		custom_minimum_size = Vector2(240, 20)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var font := ThemeDB.fallback_font
		var box := Rect2(1, 4, 13, 13)
		draw_rect(box, Color(0.04, 0.05, 0.08, 0.75))
		draw_rect(box, Color("5be38f") if done else Color("8fa3b8"), false, 1.5)
		if done:
			draw_polyline(PackedVector2Array([Vector2(3.5, 10.5), Vector2(6.5, 14), Vector2(12.5, 6)]), Color("5be38f"), 2.2)
		var col := Color("8fbf9f") if done else Color("f4efe2")
		draw_string_outline(font, Vector2(22, 15), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, 4, Color("0b0e14"))
		draw_string(font, Vector2(22, 15), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, col)
		if done:   # struck through
			var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
			draw_line(Vector2(22, 10), Vector2(22 + w, 10), Color(col, 0.8), 1.5)


# --- top bar -------------------------------------------------------------------

func _make_top_bar() -> void:
	var bar := PanelContainer.new()
	add_child(bar)
	bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	bar.add_theme_stylebox_override("panel", _panel_style())
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 30)
	bar.add_child(row)
	_top_row = row
	_add_resource(row, "alloys", "ALLOYS", Color("aeb9c6"))
	_add_resource(row, "gas", "GAS", Color("8fd14f"))
	_add_resource(row, "credits", "¢", Color("e8c14a"))
	_starbases = TipLabel.new()
	_starbases.add_theme_font_size_override("font_size", 22)
	_starbases.add_theme_color_override("font_color", Color("8fb4e3"))
	row.add_child(_starbases)
	_starbases.mouse_filter = Control.MOUSE_FILTER_STOP
	_hook_top_tip(_starbases, 3)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	_location = _make_label(row, Color("f4efe2"), 22)
	_tick = _make_label(row, Color("93a3ad"), 22)
	_hook_top_tip(_tick, 6)


## Plain-words descriptions for the top bar, shown when you hover each item.
const TOP_LEGEND := [
	["alloys", "ALLOYS", "Build ships and stations. Colonies need some too."],
	["gas", "GAS", "Fuel for the big guns: Carriers, Battleships and MAG Cannons."],
	["credits", "CREDITS", "Buy cards at the Arms Dealer, rerolls and new colonies."],
	["", "SPACE STATIONS", "Starbases and Shipyards you own, out of your limit."],
	["", "FLEET XP", "Destroy enemy ships to fill it. Full bar: a Fleet Card."],
	["", "CARDS", "Every card you've taken. Click to look through them."],
	["", "DAY", "Every day your planets and Starbases pay out."],
]



## Hovering an item in the top bar: a small box under it saying, in plain words, what
## it is (resources say what they're spent on). Only while the mouse is on it.
func _hook_top_tip(item: Control, entry_index: int) -> void:
	if item.mouse_filter == Control.MOUSE_FILTER_IGNORE:
		item.mouse_filter = Control.MOUSE_FILTER_PASS
	# Its insides don't catch the mouse, so the tip doesn't flicker moving across them.
	for child in item.find_children("*", "Control", true, false):
		(child as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	item.mouse_entered.connect(_show_top_tip.bind(item, entry_index))
	item.mouse_exited.connect(_hide_top_tip.bind(item))


func _show_top_tip(item: Control, entry_index: int) -> void:
	_hide_top_tip(null)
	if guide_only:
		return
	var entry: Array = TOP_LEGEND[entry_index]
	var box := PanelContainer.new()
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.035, 0.05, 0.07, 0.96)
	st.border_color = Color("3a4650")
	st.set_border_width_all(1)
	st.border_width_top = 3
	st.set_corner_radius_all(6)
	st.shadow_color = Color(0, 0, 0, 0.45)
	st.shadow_size = 8
	st.content_margin_left = 12
	st.content_margin_right = 12
	st.content_margin_top = 8
	st.content_margin_bottom = 9
	box.add_theme_stylebox_override("panel", st)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.z_index = 60
	add_child(box)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 3)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(col)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 6)
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(head)
	if String(entry[0]) != "":
		var icon := ResIconControl.new(String(entry[0]), 16.0)
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		head.add_child(icon)
	var title := _make_label(head, Color("f0c35a"), 15)
	title.text = String(entry[1])
	var words := _make_label(col, Color("d5dbe0"), 14)
	words.text = String(entry[2])
	words.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	words.custom_minimum_size = Vector2(230, 0)
	if String(entry[0]) == "alloys":
		_upkeep_table(col)
	# Under the item, kept on screen.
	var r := item.get_global_rect()
	var screen := get_viewport().get_visible_rect().size
	box.position = Vector2(clampf(r.position.x, 8.0, screen.x - 270.0), _top_row.get_global_rect().end.y + 14.0)
	_top_tip = box
	_top_tip_owner = item


func _hide_top_tip(item: Control) -> void:
	if item != null and item != _top_tip_owner:
		return
	if _top_tip != null and is_instance_valid(_top_tip):
		_top_tip.queue_free()
	_top_tip = null
	_top_tip_owner = null


var _top_tip: Control = null
var _top_tip_owner: Control = null


## Under the Alloys tip: fleet upkeep by ship type (count x Alloys a day each) and the
## total paid every day (v0.9.231).
func _upkeep_table(col: VBoxContainer) -> void:
	var counts := {}
	for node in get_tree().get_nodes_in_group("ships"):
		if not (node.get("alive") == true) or int(node.get("faction")) != GD.Faction.UNE:
			continue
		var t := String(node.get("type_id"))
		if GD.SHIPS.has(t) and t != "fighter":   # fighters come with their bays, no upkeep
			counts[t] = int(counts.get(t, 0)) + 1
	var rule := ColorRect.new()
	rule.color = Color("3a4650")
	rule.custom_minimum_size = Vector2(0, 1)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(rule)
	var head := _make_label(col, Color("f0c35a"), 14)
	head.text = "FLEET UPKEEP"
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 2)
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(grid)
	var cells := func(texts: Array, colour: Color) -> void:
		for i in texts.size():
			var lab := _make_label(grid, colour, 14)
			lab.text = String(texts[i])
			lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if i == 0 else HORIZONTAL_ALIGNMENT_RIGHT
	cells.call(["Ship", "Owned", "Each", "Total"], Color("93a3ad"))
	var total := 0
	for t in GD.SHIPS.keys():
		var n := int(counts.get(t, 0))
		if n <= 0:
			continue
		var each := GD.ship_upkeep(String(t))
		total += n * each
		cells.call([String(GD.SHIPS[t]["kind"]), "x%d" % n, "free" if each == 0 else "%d" % each, "-" if each == 0 else "%d" % (n * each)], Color("d5dbe0"))
	if counts.is_empty():
		var none := _make_label(col, Color("93a3ad"), 14)
		none.text = "No ships yet."
	var sum := _make_label(col, Color("f0c35a"), 15)
	sum.text = "Total upkeep: %d" % total


func _add_resource(parent: Control, key: String, title: String, colour: Color) -> void:
	var group := HBoxContainer.new()
	group.add_theme_constant_override("separation", 6)
	parent.add_child(group)
	# Stellaris-style resource icon in place of the word.
	var icon := ResIconControl.new(key, 30.0)   # was 24 (v0.9.148)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	group.add_child(icon)
	_hook_top_tip(group, ["alloys", "gas", "credits"].find(key))
	var value := _make_label(group, colour, 22)
	value.set_meta("title", title)
	var gain := _make_label(group, Color(GD.GAIN_COLOUR), 18)
	_values[key] = value
	_gains[key] = gain


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.043, 0.071, 0.094, 0.92)
	style.border_color = Color("22303a")
	style.border_width_bottom = 2
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style


func _make_label(parent: Control, colour: Color, size: int) -> Label:
	var label := Label.new()
	label.add_theme_color_override("font_color", colour)
	label.add_theme_font_size_override("font_size", size)
	parent.add_child(label)
	return label


func show_resources(amounts: Dictionary, income: Dictionary, starbases: int, limit: int) -> void:
	for key in _values.keys():
		var value: Label = _values[key]
		var gain: Label = _gains[key]
		var now_amount := int(amounts.get(key, 0))
		if _last_amounts.has(key) and now_amount > int(_last_amounts[key]):
			_pop_gain(key, value, now_amount - int(_last_amounts[key]))
		_last_amounts[key] = now_amount
		value.text = "%d" % now_amount
		var per_tick := int(income.get(key, 0))
		gain.text = "+%d" % per_tick if per_tick > 0 else ("%d" % per_tick if per_tick < 0 else "")
		# Upkeep can push Alloys below zero per day: shown plain, not red (v0.9.235).
		gain.add_theme_color_override("font_color", Color("c9d2d8") if per_tick < 0 else Color(GD.GAIN_COLOUR))
	_starbases.text = "SPACE STATIONS %d/%d" % [starbases, limit]
	_refresh_build_buttons(amounts)


var _last_amounts := {}   # what each top bar resource showed last time (to spot gains)
var _gain_pops := {}      # key -> the "+N" still rising, so quick gains add up in one number

## A little "+N" that floats up from a top bar resource whenever it goes up.
func _pop_gain(key: String, value: Label, amount: int) -> void:
	var live: Dictionary = _gain_pops.get(key, {})
	var now := Time.get_ticks_msec()
	if not live.is_empty() and is_instance_valid(live["label"]) and now - int(live["at"]) < 300:
		# Several gains in a blink (a rock burst, a payday) count up in the same number.
		live["amount"] = int(live["amount"]) + amount
		(live["label"] as Label).text = "+%d" % int(live["amount"])
		return
	var pop := Label.new()
	pop.text = "+%d" % amount
	pop.add_theme_font_size_override("font_size", 18)
	pop.add_theme_color_override("font_color", Color(GD.GAIN_COLOUR))
	pop.add_theme_color_override("font_outline_color", Color("0b0e14"))
	pop.add_theme_constant_override("outline_size", 5)
	pop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pop.z_index = 5
	value.add_child(pop)
	# Starts just under the number and rises past it, fading out.
	var start := Vector2(value.size.x - 4.0, value.size.y * 0.45)
	pop.position = start
	var tw := pop.create_tween()
	tw.set_parallel(true)
	tw.tween_property(pop, "position:y", start.y - 30.0, 1.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(pop, "modulate:a", 0.0, 0.5).set_delay(0.6)
	tw.chain().tween_callback(pop.queue_free)
	_gain_pops[key] = {"label": pop, "amount": amount, "at": now}


func _make_xp_bar() -> void:
	# A small golden Fleet XP bar living in the top bar.
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	_top_row.add_child(box)
	_top_row.move_child(box, _starbases.get_index() + 1)
	_xp_label = Label.new()
	_xp_label.add_theme_font_size_override("font_size", 17)
	_xp_label.add_theme_color_override("font_color", Color("e8c547"))
	box.add_child(_xp_label)
	# Bigger, thicker bar inside a frame that glows when XP comes in.
	_xp_frame = PanelContainer.new()
	_xp_frame_style = StyleBoxFlat.new()
	_xp_frame_style.bg_color = Color(0.18, 0.14, 0.04)
	_xp_frame_style.border_color = Color(0.55, 0.44, 0.15)
	_xp_frame_style.set_border_width_all(1)
	_xp_frame_style.set_corner_radius_all(3)
	_xp_frame_style.shadow_color = Color(0.91, 0.77, 0.28, 0.0)
	_xp_frame.add_theme_stylebox_override("panel", _xp_frame_style)
	box.add_child(_xp_frame)
	var back := Control.new()
	back.custom_minimum_size = Vector2(380, 18)
	back.clip_contents = true
	_xp_frame.add_child(back)
	_xp_back = back
	_xp_fill = ColorRect.new()
	_xp_fill.color = Color("e8c547")
	back.add_child(_xp_fill)
	_xp_fill.anchor_bottom = 1.0
	_xp_fill.anchor_right = 0.0
	# The newly earned stretch of the bar flashes bright, then fades.
	_xp_gleam = ColorRect.new()
	_xp_gleam.color = Color(1.0, 0.97, 0.75, 0.0)
	_xp_gleam.mouse_filter = Control.MOUSE_FILTER_IGNORE
	back.add_child(_xp_gleam)
	_xp_gleam.anchor_bottom = 1.0
	_hook_top_tip(box, 4)   # after the bar's parts exist, so they're made mouse-transparent too
	# Your card collection: a little fan of three cards beside the XP bar.
	var deck := DeckButton.new()
	deck.custom_minimum_size = Vector2(74, 52)
	_top_row.add_child(deck)
	_top_row.move_child(deck, box.get_index() + 1)
	_hook_top_tip(deck, 5)
	deck.clicked.connect(func() -> void:
		Sfx.ui("card_appear")
		collection_requested.emit())


func show_xp(xp: int, need: int, level: int = 1) -> void:
	var frac := clampf(float(xp) / float(max(1, need)), 0.0, 1.0)
	var before := _xp_fill.anchor_right
	if frac != before:
		# Gleam over the part that just filled (from 0 after a level-up).
		_xp_gleam.anchor_left = before if frac > before else 0.0
		_xp_gleam.anchor_right = frac
		_xp_gleam.offset_left = 0.0
		_xp_gleam.offset_right = 0.0
		_xp_glow = 1.0
	_xp_fill.anchor_right = frac
	_xp_label.text = "FLEET LEVEL %d   ·   XP %d / %d" % [level, xp, need]


## "+1 XP" rising from the XP bar when a kill earns XP.
func xp_popup(amount: int) -> void:
	if _xp_back == null:
		return
	var pop := Label.new()
	pop.text = "+%d XP" % amount
	pop.add_theme_font_size_override("font_size", 18)
	pop.add_theme_color_override("font_color", Color("ffe27a"))
	pop.add_theme_color_override("font_outline_color", Color("0b0e14"))
	pop.add_theme_constant_override("outline_size", 5)
	pop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(pop)
	var bar := _xp_back.get_global_rect()
	var start := Vector2(bar.position.x + bar.size.x * _xp_fill.anchor_right - 14.0, bar.end.y + 2.0)
	pop.position = start
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(pop, "position", start + Vector2(0, 26), 0.9).set_ease(Tween.EASE_OUT)
	tween.tween_property(pop, "modulate:a", 0.0, 0.9).set_delay(0.3)
	tween.chain().tween_callback(pop.queue_free)


func _update_xp_glow(delta: float) -> void:
	if _xp_gleam == null or _xp_glow <= 0.0:
		return
	_xp_glow = maxf(0.0, _xp_glow - delta * 1.4)
	_xp_gleam.color.a = 0.9 * _xp_glow
	_xp_fill.modulate = Color(1, 1, 1).lerp(Color(1.6, 1.45, 1.0), _xp_glow)
	_xp_frame_style.shadow_color = Color(0.91, 0.77, 0.28, 0.6 * _xp_glow)
	_xp_frame_style.shadow_size = int(10.0 * _xp_glow)


func show_tick(seconds_left: float, day: int = 1) -> void:
	_tick.text = "DAY %d · NEXT %ds" % [day, int(ceil(seconds_left))]


func show_location(text: String) -> void:
	_location.text = text


func show_toast(text: String, seconds: float = 2.5) -> void:
	_toast.text = text
	_toast_time = seconds
	_toast.modulate.a = 1.0


## Kharkiv health as a fraction; below 20% the screen edges glow faintly red.
func set_low_health(fraction: float) -> void:
	_low_health = fraction


func _update_vignette(delta: float) -> void:
	if _vignette == null:
		return
	var on := _low_health < 0.2
	_vignette.visible = on
	if not on:
		return
	_pulse += delta
	var depth := 1.0 - _low_health / 0.2
	# Much stronger than before (was 0.18-0.35), pulsing faster and harder near death.
	var beat := 3.0 + 4.0 * depth
	var strength := (0.4 + 0.45 * depth) * (0.65 + 0.35 * sin(_pulse * beat))
	(_vignette.material as ShaderMaterial).set_shader_parameter("strength", strength)


# --- notification shade -------------------------------------------------------------

## A card in the top right for 10 seconds, then it blinks and fades. Clicking it
## sends the camera to the place it's about.
var _notify_style: StyleBoxFlat = null
var _notify_hover: StyleBoxFlat = null
var _empty_focus := StyleBoxEmpty.new()


func notify(text: String, system_index: int = -1, pos_px: Vector2 = Vector2.ZERO, tag: String = "") -> void:
	Sfx.ui("notify", -15.0)   # quieter still (was -10 before v0.9.100); at most one ping every 3 s (sfx LIMITS)
	var card := Button.new()
	card.text = text
	card.alignment = HORIZONTAL_ALIGNMENT_LEFT
	card.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card.custom_minimum_size = Vector2(364, 0)
	card.add_theme_font_size_override("font_size", 18)
	card.add_theme_color_override("font_color", Color("f4efe2"))
	card.add_theme_color_override("font_hover_color", Color("ffffff"))
	# Styles are made once and shared by every notification card.
	if _notify_style == null:
		_notify_style = _panel_style()
		_notify_style.border_color = Color("b89a4a")
		_notify_style.set_border_width_all(0)
		_notify_style.border_width_left = 4
		_notify_style.content_margin_top = 10
		_notify_style.content_margin_bottom = 10
		_notify_hover = _notify_style.duplicate() as StyleBoxFlat
		_notify_hover.bg_color = Color(0.09, 0.13, 0.17, 0.95)
	card.add_theme_stylebox_override("normal", _notify_style)
	card.add_theme_stylebox_override("hover", _notify_hover)
	card.add_theme_stylebox_override("pressed", _notify_hover)
	card.add_theme_stylebox_override("focus", _empty_focus)
	card.set_meta("age", 0.0)
	card.set_meta("system", system_index)
	card.set_meta("pos", pos_px)
	card.set_meta("tag", tag)
	card.tooltip_text = "Click to go there · Right-click to dismiss"
	card.pressed.connect(_on_notification_pressed.bind(card))
	# Right-click dismisses it (v0.9.216).
	var dismiss := func(event: InputEvent) -> void:
		var mb := event as InputEventMouseButton
		if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_RIGHT and is_instance_valid(card):
			Sfx.ui("click", -6.0)
			card.queue_free()
			card.accept_event()
	card.gui_input.connect(dismiss)
	_notify_box.add_child(card)
	# At most 3 on screen (was 5): the oldest makes way for the newest.
	var live: Array = []
	for child in _notify_box.get_children():
		if not child.is_queued_for_deletion():
			live.append(child)
	while live.size() > 3:
		(live.pop_front() as Node).free()


## Removes the oldest notification with this tag (e.g. a Growth Reward once its bubble
## has been picked up, so it can't be clicked any more). v0.9.210
func clear_notification(tag: String) -> void:
	if tag == "" or _notify_box == null:
		return
	for child in _notify_box.get_children():
		if not child.is_queued_for_deletion() and String(child.get_meta("tag", "")) == tag:
			child.queue_free()
			return


func _on_notification_pressed(card: Button) -> void:
	var index := int(card.get_meta("system"))
	if index >= 0:
		notification_clicked.emit(index, Vector2(card.get_meta("pos")))
	card.queue_free()


func _age_notifications(delta: float) -> void:
	if _notify_box == null or get_tree().paused:
		return
	for child in _notify_box.get_children():
		var card := child as Control
		var age := float(card.get_meta("age")) + delta
		card.set_meta("age", age)
		var over := age - GD.NOTIFY_SECONDS
		if over <= 0.0:
			card.modulate.a = 1.0
		elif over < 1.5:
			card.modulate.a = 0.35 + 0.65 * absf(cos(over * 7.0))
		elif over < 2.5:
			card.modulate.a = 1.0 - (over - 1.5)
		else:
			card.queue_free()


# --- hotkey bar ----------------------------------------------------------------

func _make_hotkey_bar() -> void:
	# Compact key grid in the bottom-left corner (two rows), Boost on its own in the middle.
	var grid := GridContainer.new()
	_hotkey_grid = grid
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 6)
	add_child(grid)
	grid.anchor_top = 1.0
	grid.anchor_bottom = 1.0
	grid.offset_left = 16.0
	grid.offset_bottom = -14.0
	grid.grow_vertical = Control.GROW_DIRECTION_BEGIN
	for entry in [[["F"], "Fleet Mode"], [["B"], "Build"], [["TAB"], "Galaxy"], [["H"], "Home"],
			[["ALT"], "Secondary"], [["SPACE"], "Info"], [["P"], "Pause"]]:
		var cell := HBoxContainer.new()
		cell.add_theme_constant_override("separation", 6)
		grid.add_child(cell)
		_add_hotkey(cell, Array(entry[0]), String(entry[1]), true)
	# Boost: in the grid with the rest (v0.9.134), with a little meter under it.
	var boost_cell := VBoxContainer.new()
	boost_cell.add_theme_constant_override("separation", 3)
	grid.add_child(boost_cell)
	var boost := HBoxContainer.new()
	boost.add_theme_constant_override("separation", 6)
	boost_cell.add_child(boost)
	_add_hotkey(boost, ["SHIFT"], "Boost", true)
	var back := ColorRect.new()
	back.color = Color(0.06, 0.08, 0.11, 0.9)
	back.custom_minimum_size = Vector2(96, 5)
	back.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boost_cell.add_child(back)
	_boost_fill = ColorRect.new()
	_boost_fill.color = Color("5b9bff")
	_boost_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	back.add_child(_boost_fill)
	_boost_fill.anchor_bottom = 1.0
	_boost_fill.anchor_right = 1.0


var _boost_fill: ColorRect = null
var _hotkey_grid: Control = null   # hidden when Noob Mode is off (v0.9.193)


## The little boost meter under the Boost key: 0 empty, 1 full. Glows while boosting.
func show_boost_meter(level: float, active: bool) -> void:
	if _boost_fill == null:
		return
	_boost_fill.anchor_right = clampf(level, 0.0, 1.0)
	_boost_fill.offset_right = 0.0
	_boost_fill.color = Color("8fd1ff") if active else (Color("5b9bff") if level >= 0.999 else Color("3e6fb0"))


func _add_hotkey(parent: Control, keys: Array, text: String, compact: bool = false) -> void:
	for k in keys:
		var key_name: String = k
		var cap := _keycap(key_name, compact)
		parent.add_child(cap)
		_keys[key_name] = cap
	var label := _make_label(parent, Color("c9d2d8"), 14 if compact else 17)
	label.text = text + "   "
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_key_labels[String(keys[0])] = label


func _keycap_style(active: bool) -> StyleBoxFlat:
	# A raised key: lighter top edge, thick dark bottom edge, rounded corners.
	var style := StyleBoxFlat.new()
	style.bg_color = Color("3e6fb0") if active else Color("2c3642")
	style.border_color = Color("1b3050") if active else Color("12171e")
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 3 if active else 7
	style.corner_radius_top_left = 7
	style.corner_radius_top_right = 7
	style.corner_radius_bottom_left = 7
	style.corner_radius_bottom_right = 7
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 6 if active else 4
	style.content_margin_bottom = 4
	style.shadow_color = Color(0, 0, 0, 0.45)
	style.shadow_size = 3
	style.shadow_offset = Vector2(0, 3)
	return style


func _keycap(text: String, compact: bool = false) -> PanelContainer:
	var cap := PanelContainer.new()
	cap.add_theme_stylebox_override("panel", _keycap_style(false))
	if compact:
		cap.custom_minimum_size = Vector2(34 if text.length() <= 1 else (48 if text.length() <= 3 else 76), 34)
	else:
		cap.custom_minimum_size = Vector2(44 if text.length() <= 1 else (60 if text.length() <= 3 else 110), 44)
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 14 if compact else 18)
	label.add_theme_color_override("font_color", Color("e9e6dc"))
	cap.add_child(label)
	return cap


## Lights a key up, e.g. while Fleet Mode is on or Space is held.
func set_key_active(key_name: String, active: bool) -> void:
	if not _keys.has(key_name):
		return
	var cap: PanelContainer = _keys[key_name]
	cap.add_theme_stylebox_override("panel", _keycap_style(active))


func set_fleet_mode(on: bool) -> void:
	_fleet_mode_on = on
	# The Fleet Mode control-hint banner is retired: it stays hidden.
	_fleet_banner.visible = false
	set_key_active("F", false)   # plain key in Fleet Mode; it glows gold outside it
	_glow_f = not on
	# The bar changes with the mode.
	var tab: Label = _key_labels.get("G")
	var home: Label = _key_labels.get("H")
	if tab != null:
		# No second fleet yet, so the Planets key (G) has nothing to do in Fleet Mode: hide it.
		tab.text = "Planets   "
		tab.visible = not on
		if _keys.has("G"):
			(_keys["G"] as Control).visible = not on
	if home != null:
		home.text = "Home   "   # always just Home (v0.9.198)
	var f_label: Label = _key_labels.get("F")
	if f_label != null:
		# In Fleet Mode, F takes you out to the free (RTS) camera.
		f_label.text = ("RTS Cam" if on else "Fleet Mode") + "   "


# --- build menu ----------------------------------------------------------------

func _make_build_panel() -> void:
	# A C&C-style sidebar: a gritty gunmetal slab that slides in from the right with
	# a two-column grid of build cameos, with green wireframe icons (v0.9.205).
	_build_panel = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.13, 0.145, 0.16, 0.98)
	style.border_color = Color("5d666f")
	style.border_width_left = 4
	style.border_width_top = 2
	style.border_width_bottom = 4
	style.border_color = Color("4d555d")
	style.corner_radius_bottom_left = 3
	style.shadow_color = Color(0, 0, 0, 0.7)
	style.shadow_size = 20
	style.shadow_offset = Vector2(-6, 6)
	style.content_margin_left = 14
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 14
	_build_panel.add_theme_stylebox_override("panel", style)
	add_child(_build_panel)
	_build_panel.anchor_left = 1.0
	_build_panel.anchor_right = 1.0
	_build_panel.offset_top = 64.0
	_build_panel.offset_bottom = 64.0
	_build_panel.grow_vertical = Control.GROW_DIRECTION_END
	_build_panel.offset_left = BUILD_HIDDEN_X
	_build_panel.offset_right = BUILD_HIDDEN_X + BUILD_PANEL_W
	_build_panel.visible = false
	_build_panel.draw.connect(func() -> void: _draw_gunmetal(_build_panel))

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	_build_panel.add_child(column)
	var title_row := HBoxContainer.new()
	column.add_child(title_row)
	var title := _make_label(title_row, Color("e0a640"), 24)
	title.text = "BUILD"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	title.add_theme_constant_override("outline_size", 4)
	var close := Button.new()
	close.text = "X"
	close.focus_mode = Control.FOCUS_NONE
	close.custom_minimum_size = Vector2(38, 32)
	_metal_button(close)
	close.pressed.connect(toggle_build_menu)
	title_row.add_child(close)
	var stations := _build_section(column, "STATIONS")
	for item_id in BUILD_STRUCTURES:
		var item: Dictionary = GD.STRUCTURES[item_id]
		var cost := "%d Alloys" % int(item["alloys"])
		if int(item["gas"]) > 0:
			cost += " + %d Gas" % int(item["gas"])
		_add_build_button(stations, item_id, String(item["name"]), cost, item["alloys"], item["gas"], float(item["time"]), false)
	var ships := _build_section(column, "SHIPS")
	for type_id in BUILD_SHIPS:
		var info: Dictionary = GD.SHIPS[type_id]
		var stats := GD.ship_stats(type_id)
		var cost := "%d Alloys" % int(stats["cost_alloys"])
		if int(stats["cost_gas"]) > 0:
			cost += " + %d Gas" % int(stats["cost_gas"])
		_add_build_button(ships, type_id, String(info["kind"]), cost, stats["cost_alloys"], stats["cost_gas"], float(stats["build_time"]), true)


const BUILD_PANEL_W := 336.0
const BUILD_SHOWN_X := -BUILD_PANEL_W - 10.0   # offset_left when open
const BUILD_HIDDEN_X := 12.0                    # offset_left when tucked away off the right edge


## A captioned two-column grid of build cameos, set into a dark recess.
func _build_section(parent: Control, caption: String) -> GridContainer:
	var label := _make_label(parent, Color("8a939c"), 14)
	label.text = "▸ " + caption
	var recess := PanelContainer.new()
	var inset := StyleBoxFlat.new()
	inset.bg_color = Color(0.06, 0.07, 0.08, 0.9)
	inset.border_color = Color(0, 0, 0, 0.85)
	inset.border_width_top = 3
	inset.border_width_left = 3
	inset.border_width_right = 1
	inset.border_width_bottom = 1
	inset.set_content_margin_all(5)
	recess.add_theme_stylebox_override("panel", inset)
	parent.add_child(recess)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 7)
	grid.add_theme_constant_override("v_separation", 7)
	recess.add_child(grid)
	return grid


## Faint teal grid lines over the build sidebar, like a tactical display.
func _draw_tactical_grid(panel: Control) -> void:
	var w := panel.size.x
	var h := panel.size.y
	var line := Color(0.37, 0.81, 0.75, 0.05)
	var x := 16.0
	while x < w:
		panel.draw_line(Vector2(x, 2), Vector2(x, h - 2), line, 1.0)
		x += 24.0
	var y := 16.0
	while y < h:
		panel.draw_line(Vector2(2, y), Vector2(w, y), line, 1.0)
		y += 24.0


## A flat grid cell: dark glass, a thin cool border, gold border on hover.
func _grid_cell_style(button: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.05, 0.075, 0.11, 0.95)
	normal.border_color = Color("2a3a4a")
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(2)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.08, 0.11, 0.15, 0.98)
	hover.border_color = Color("c9a55a")
	hover.set_border_width_all(2)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.03, 0.05, 0.08, 1.0)
	pressed.border_color = Color("f0d27a")
	pressed.set_border_width_all(2)
	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.bg_color = Color(0.04, 0.05, 0.07, 0.9)
	disabled.border_color = Color("1c252e")
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.add_theme_color_override("font_color", Color("c9d2d8"))
	button.add_theme_color_override("font_hover_color", Color("f0d27a"))


## Grit over the sidebar's steel: speckle, scratches, grime, a few rivets.
func _draw_gunmetal(panel: Control) -> void:
	var w := panel.size.x
	var h := panel.size.y
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for i: int in 260:
		var at := Vector2(rng.randf_range(0, w), rng.randf_range(0, h))
		panel.draw_rect(Rect2(at, Vector2(1, 1)), Color(1, 1, 1, 0.05) if rng.randf() < 0.5 else Color(0, 0, 0, 0.25))
	for i: int in 7:
		var at := Vector2(rng.randf_range(0, w), rng.randf_range(0, h))
		panel.draw_circle(at, rng.randf_range(10.0, 26.0), Color(0.05, 0.04, 0.03, 0.12))
	for i: int in 14:
		var at := Vector2(rng.randf_range(4, w - 4), rng.randf_range(4, h - 4))
		var d := Vector2.RIGHT.rotated(rng.randf_range(-0.6, 0.6)) * rng.randf_range(8.0, 30.0)
		panel.draw_line(at, at + d, Color(1, 1, 1, 0.06), 1.5)
	# Worn bevel on the left edge.
	panel.draw_line(Vector2(5, 0), Vector2(5, h), Color(1, 1, 1, 0.06), 1.5)
	for y in [16.0, h * 0.5, h - 14.0]:
		_rivet(panel, Vector2(9, y))
	_rivet(panel, Vector2(w - 9, h - 14))


func _rivet(panel: Control, at: Vector2) -> void:
	panel.draw_circle(at + Vector2(0, 1), 3.0, Color(0, 0, 0, 0.5))
	panel.draw_circle(at, 2.5, Color("5d666f"))
	panel.draw_circle(at - Vector2(0.8, 0.8), 1.0, Color(1, 1, 1, 0.25))


## A bevelled steel plate button: lit top edge, heavy dark bottom edge, amber on hover.
func _metal_button(button: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("353c44")
	normal.border_color = Color("15181c")
	normal.border_width_left = 1
	normal.border_width_right = 1
	normal.border_width_top = 1
	normal.border_width_bottom = 5
	normal.set_corner_radius_all(4)
	normal.shadow_color = Color(0, 0, 0, 0.4)
	normal.shadow_size = 4
	normal.shadow_offset = Vector2(0, 3)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("434b55")
	hover.border_color = Color("e8a33a")
	hover.border_width_left = 2
	hover.border_width_right = 2
	hover.border_width_top = 2
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color("2b3138")
	pressed.border_width_bottom = 2
	pressed.border_width_top = 3
	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.bg_color = Color("262b31")
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


## A build cameo: a big silhouette, the build time in the corner, then the name
## and the cost.
func _add_build_button(parent: Control, item_id: String, name_text: String, cost: String, alloys: int, gas: int, base_time: float, is_ship: bool) -> void:
	var button := Button.new()
	button.set_meta("name", name_text)
	button.set_meta("cost", cost)
	button.set_meta("time", base_time)
	button.set_meta("ship", is_ship)
	button.custom_minimum_size = Vector2(136, 126)
	button.set_meta("alloys", alloys)
	button.set_meta("gas", gas)
	_metal_button(button)
	var content := VBoxContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 0)
	button.add_child(content)
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.offset_top = 4
	content.offset_bottom = -6
	var icon := ShipInfo.Icon.new()
	icon.kind = item_id
	icon.holo = true
	icon.custom_minimum_size = Vector2(0, 58)
	content.add_child(icon)
	var name_label := _make_label(content, Color("e6e1d3"), 16)
	name_label.text = name_text.to_upper()
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	name_label.add_theme_constant_override("outline_size", 3)
	var costs := HBoxContainer.new()
	costs.alignment = BoxContainer.ALIGNMENT_CENTER
	costs.add_theme_constant_override("separation", 2)
	costs.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(costs)
	var cost_labels := {}
	for pair in [["alloys", alloys], ["gas", gas]]:
		if int(pair[1]) <= 0:
			continue
		costs.add_child(ResIconControl.new(String(pair[0]), 19.0))
		var amount := _make_label(costs, Color("d9d3c4"), 17)
		amount.text = "%d " % int(pair[1])
		amount.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cost_labels[String(pair[0])] = amount
	button.set_meta("cost_labels", cost_labels)
	# Ships: their Alloy upkeep per day, under the price (v0.9.232).
	if is_ship and GD.ship_upkeep(item_id) > 0:
		button.custom_minimum_size = Vector2(136, 140)
		var upkeep := HBoxContainer.new()
		upkeep.alignment = BoxContainer.ALIGNMENT_CENTER
		upkeep.add_theme_constant_override("separation", 3)
		upkeep.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(upkeep)
		var up_word := _make_label(upkeep, Color("93a3ad"), 12)
		up_word.text = "UPKEEP"
		up_word.mouse_filter = Control.MOUSE_FILTER_IGNORE
		up_word.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var up_icon := ResIconControl.new("alloys", 14.0)
		up_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		upkeep.add_child(up_icon)
		var up_amount := _make_label(upkeep, Color("c9d2d8"), 13)
		up_amount.text = "-%d" % GD.ship_upkeep(item_id)   # daily is implied (v0.9.238)
		up_amount.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Build time, small, in the top-left corner.
	var time_label := _make_label(button, Color("93a3ad"), 13)
	time_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	time_label.position = Vector2(6, 3)
	button.set_meta("time_label", time_label)
	button.set_meta("content", content)
	time_label.text = _build_button_text(button)
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(func() -> void: build_requested.emit(item_id))
	if is_ship:
		# How many of this ship are queued, in a badge on the top-right corner.
		var badge := PanelContainer.new()
		var bs := StyleBoxFlat.new()
		bs.bg_color = Color("e8a33a")
		bs.border_color = Color("15181c")
		bs.set_border_width_all(2)
		bs.set_corner_radius_all(11)
		bs.content_margin_left = 6
		bs.content_margin_right = 6
		bs.content_margin_top = 0
		bs.content_margin_bottom = 1
		badge.add_theme_stylebox_override("panel", bs)
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var count := _make_label(badge, Color("15181c"), 15)
		count.mouse_filter = Control.MOUSE_FILTER_IGNORE
		count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		count.custom_minimum_size = Vector2(10, 0)
		button.add_child(badge)
		badge.anchor_left = 1.0
		badge.anchor_right = 1.0
		badge.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		badge.offset_right = -4.0
		badge.offset_top = 4.0
		badge.visible = false
		button.set_meta("queue_badge", badge)
		button.set_meta("queue_label", count)
		# Right-click: take one back out of the queue (full refund). Works even when
		# the button is greyed out for lack of money.
		button.gui_input.connect(func(event: InputEvent) -> void:
			var mb := event as InputEventMouseButton
			if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_RIGHT:
				unqueue_requested.emit(item_id)
				button.accept_event())
	button.mouse_entered.connect(func() -> void: _show_build_tip(item_id, button))
	button.mouse_exited.connect(_hide_build_tip)
	parent.add_child(button)
	_build_buttons[item_id] = button


var _build_tip: Control = null
var _struct_tip: Control = null
var _struct_node: Object = null
var _struct_age := 0.0
var _struct_ident := ""


## Info mode (Space held) over anything in the system: a detailed card beside the
## mouse. key "" hides it. ident tells one hovered thing from another (planets have no node).
func show_info_tip(key: String, node: Node, extra: Dictionary, ident: String) -> void:
	var stale := _struct_node != null and not is_instance_valid(_struct_node)
	_struct_age += get_process_delta_time()
	if stale or ident != _struct_ident or (key != "" and _struct_age > 0.5):
		_struct_ident = ident
		_struct_node = node
		_struct_age = 0.0
		if _struct_tip != null:
			_struct_tip.queue_free()
			_struct_tip = null
		if key != "" and extra.has("planet"):
			# Planets: the same window you get by clicking one, just to look at.
			var tip := PanelContainer.new()
			tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
			tip.z_index = 50
			var planet: Dictionary = extra["planet"]
			tip.add_theme_stylebox_override("panel", _planet_frame_style(int(planet["owner"])))
			var tip_box := VBoxContainer.new()
			tip_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
			tip.add_child(tip_box)
			_fill_planet_view(tip_box, planet, Dictionary(extra.get("income", {})), false)
			_struct_tip = tip
			add_child(_struct_tip)
		elif key != "":
			_struct_tip = ShipInfo.Card.new(key, node, true, extra)
			add_child(_struct_tip)
	if _struct_tip != null:
		var tip_size := _struct_tip.get_combined_minimum_size()
		var view := get_viewport().get_visible_rect().size
		var mouse := get_viewport().get_mouse_position()
		var at := mouse + Vector2(28, 20)
		if at.x + tip_size.x > view.x - 8.0:
			at.x = mouse.x - tip_size.x - 28.0
		at.y = clampf(at.y, 8.0, view.y - tip_size.y - 8.0)
		_struct_tip.position = at


## Hovering a build button: a card above it with a description, stats, weapons,
## traits and a tiny animation of how it fights.
func _show_build_tip(item_id: String, button: Control) -> void:
	_hide_build_tip()
	if not _build_open:
		return
	_build_tip = ShipInfo.Card.new(item_id, null, true)
	add_child(_build_tip)
	var tip_size := _build_tip.get_combined_minimum_size()
	var view := get_viewport().get_visible_rect().size
	# To the left of the sidebar, level with the button.
	var y := clampf(button.global_position.y, 8.0, view.y - tip_size.y - 8.0)
	_build_tip.position = Vector2(_build_panel.global_position.x - tip_size.x - 12.0, y)


func _hide_build_tip() -> void:
	if _build_tip != null:
		_build_tip.queue_free()
		_build_tip = null


func _build_button_text(button: Button) -> String:
	var seconds := float(button.get_meta("time"))
	# Ships use the live build speed (cards can change it).
	if bool(button.get_meta("ship")):
		seconds *= GD.build_time_mult
	return "%ds" % int(ceil(seconds))   # just the time (v0.9.232)


## Queue counts on the ship build buttons: {type_id: how many queued, all Shipyards}.
func show_build_queue(counts: Dictionary) -> void:
	for item_id in _build_buttons.keys():
		var button: Button = _build_buttons[item_id]
		if not button.has_meta("queue_badge"):
			continue
		var n := int(counts.get(item_id, 0))
		(button.get_meta("queue_badge") as Control).visible = n > 0
		(button.get_meta("queue_label") as Label).text = str(n)


## Ship cards show the current (scaled) price; it climbs as you build more of a type.
func set_ship_prices() -> void:
	for item_id in _build_buttons.keys():
		var button: Button = _build_buttons[item_id]
		if not bool(button.get_meta("ship", false)) or not GD.SHIPS.has(item_id):
			continue
		var price := GD.ship_price(String(item_id))
		var base := GD.ship_stats(String(item_id))
		button.set_meta("alloys", price.x)
		button.set_meta("gas", price.y)
		var labels: Dictionary = button.get_meta("cost_labels", {})
		for key in labels.keys():
			var lab: Label = labels[key]
			var now := price.x if String(key) == "alloys" else price.y
			var was := int(base["cost_alloys"]) if String(key) == "alloys" else int(base["cost_gas"])
			lab.text = "%d " % now
			lab.add_theme_color_override("font_color", Color("e8a33a") if now > was else Color("d9d3c4"))


func _refresh_build_buttons(amounts: Dictionary) -> void:
	for item_id in _build_buttons.keys():
		var button: Button = _build_buttons[item_id]
		(button.get_meta("time_label") as Label).text = _build_button_text(button)
		var need_alloys: int = button.get_meta("alloys")
		var need_gas: int = button.get_meta("gas")
		button.disabled = int(amounts.get("alloys", 0)) < need_alloys or int(amounts.get("gas", 0)) < need_gas
		# Can't afford it: dim the whole card, icons included.
		(button.get_meta("content") as Control).modulate.a = 0.45 if button.disabled else 1.0


func toggle_build_menu() -> void:
	_build_open = not _build_open
	_build_panel.visible = true
	set_key_active("B", _build_open)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	var to_x := BUILD_SHOWN_X if _build_open else BUILD_HIDDEN_X
	tween.parallel().tween_property(_build_panel, "offset_left", to_x, 0.18 if _build_open else 0.15)
	tween.parallel().tween_property(_build_panel, "offset_right", to_x + BUILD_PANEL_W, 0.18 if _build_open else 0.15)
	# Notifications step aside while the sidebar is out.
	if _notify_box != null:
		tween.parallel().tween_property(_notify_box, "offset_right", -16.0 - (BUILD_PANEL_W + 12.0 if _build_open else 0.0), 0.18)
		tween.parallel().tween_property(_notify_box, "offset_left", -380.0 - (BUILD_PANEL_W + 12.0 if _build_open else 0.0), 0.18)
	if not _build_open:
		_hide_build_tip()
		tween.tween_callback(func() -> void: _build_panel.visible = _build_open)


## A card choice, the shop, a reward screen or the end screen is showing (or a picked
## card is still flying away).
func has_card_screen() -> bool:
	return _card_layer != null or _flying


func is_build_open() -> bool:
	return _build_open


# --- planet panel --------------------------------------------------------------

func _make_planet_panel() -> void:
	_planet_panel = PanelContainer.new()
	_planet_panel.add_theme_stylebox_override("panel", _planet_frame_style(GD.Faction.UNE))
	add_child(_planet_panel)
	_planet_panel.anchor_left = 0.0
	_planet_panel.anchor_right = 0.0
	_planet_panel.offset_left = 18.0
	_planet_panel.offset_right = 450.0
	_planet_panel.offset_top = 72.0
	_planet_box = VBoxContainer.new()
	_planet_box.add_theme_constant_override("separation", 8)
	_planet_panel.add_child(_planet_box)
	_planet_panel.visible = false


## Opens the planet panel. income is what this planet itself earns per tick.
func show_planet(planet: Dictionary, income: Dictionary) -> void:
	_planet = planet
	_planet_income = income
	_planet_panel.visible = true
	_fill_planet_panel()


func refresh_planet(income: Dictionary) -> void:
	if _planet_panel.visible:
		_planet_income = income
		_fill_planet_panel()


func current_planet() -> Dictionary:
	return _planet if _planet_panel.visible else {}


func hide_planet() -> void:
	_hide_trait_tip()
	_planet_panel.visible = false
	_planet = {}


func is_planet_open() -> bool:
	return _planet_panel.visible


func _row(parent: Control, left: String, right: String, colour: Color = Color("e9e6dc")) -> void:
	var line := HBoxContainer.new()
	parent.add_child(line)
	var a := _make_label(line, Color("93a3ad"), 17)
	a.text = left
	a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var b := _make_label(line, colour, 17)
	b.text = right


func _fill_planet_panel() -> void:
	_hide_trait_tip()
	for child in _planet_box.get_children():
		child.queue_free()
	_hide_building_card()
	_planet_panel.add_theme_stylebox_override("panel", _planet_frame_style(int(_planet["owner"])))
	_fill_planet_view(_planet_box, _planet, _planet_income, true)


## The planet window's frame: the same dark glass, drop shadow and coloured top edge
## as the info cards and the card window, tinted by who owns the planet.
func _planet_frame_style(owner: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.05, 0.07, 0.96)
	var edge := GD.ring_colour(owner) if owner != GD.Faction.NEUTRAL else Color("8a939c")
	style.border_color = Color(edge, 0.85)
	style.set_border_width_all(2)
	style.border_width_top = 4
	style.set_corner_radius_all(8)
	style.shadow_color = Color(0, 0, 0, 0.55)
	style.shadow_size = 14
	style.shadow_offset = Vector2(0, 6)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 14
	style.content_margin_bottom = 16
	return style


## A darker inset block with a small grey heading, like the WEAPONS block on ship cards.
func _planet_inset(parent: Control, heading: String) -> VBoxContainer:
	var block := PanelContainer.new()
	var inset := StyleBoxFlat.new()
	inset.bg_color = Color(0.02, 0.03, 0.045, 0.9)
	inset.border_color = Color("3a4650")
	inset.border_width_left = 3
	inset.set_corner_radius_all(4)
	inset.content_margin_left = 10
	inset.content_margin_right = 10
	inset.content_margin_top = 6
	inset.content_margin_bottom = 8
	block.add_theme_stylebox_override("panel", inset)
	block.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(block)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 6)
	rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	block.add_child(rows)
	if heading != "":
		var label := _make_label(rows, Color("8a939c"), 12)
		label.text = heading
	return rows


## Everything about one planet, built into box. Used by the planet window (click a
## planet) and by the info-mode card (hold Space over one), so both look the same.
## interactive: the window has a close button, building cards on hover and clickable
## Growth Reward slots; the info card is just to look at.
var _trait_tip: Control = null


func _show_trait_tip(chip: Control, text: String) -> void:
	_hide_trait_tip()
	var panel := PanelContainer.new()
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.02, 0.03, 0.05, 0.97)
	st.border_color = Color("b08a52")
	st.set_border_width_all(1)
	st.set_corner_radius_all(4)
	st.content_margin_left = 10
	st.content_margin_right = 10
	st.content_margin_top = 7
	st.content_margin_bottom = 7
	panel.add_theme_stylebox_override("panel", st)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.z_index = 50
	var lab := Label.new()
	lab.text = text
	lab.add_theme_font_size_override("font_size", 15)
	lab.add_theme_color_override("font_color", Color("e9e6dc"))
	lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lab.custom_minimum_size = Vector2(260, 0)
	panel.add_child(lab)
	add_child(panel)
	panel.global_position = chip.global_position + Vector2(0, chip.size.y + 6)
	_trait_tip = panel


func _hide_trait_tip() -> void:
	if _trait_tip != null and is_instance_valid(_trait_tip):
		_trait_tip.queue_free()
	_trait_tip = null


## TRAITS: small chips under the planet's name (v0.9.219). Hover one for what it does.
func _traits_row(box: VBoxContainer, p: Dictionary) -> void:
	var traits := GD.planet_traits(p)
	if traits.is_empty():
		return
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	box.add_child(row)
	var head := _make_label(row, Color("93a3ad"), 13)
	head.text = "TRAITS"
	head.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	for t in traits:
		var name_text := String(t)
		var chip := PanelContainer.new()
		var st := StyleBoxFlat.new()
		st.bg_color = Color(0.12, 0.1, 0.07, 0.95)
		st.border_color = Color("b08a52")
		st.set_border_width_all(1)
		st.set_corner_radius_all(10)
		st.content_margin_left = 6
		st.content_margin_right = 10
		st.content_margin_top = 2
		st.content_margin_bottom = 2
		chip.add_theme_stylebox_override("panel", st)
		chip.mouse_filter = Control.MOUSE_FILTER_STOP
		# A basic tooltip of our own, shown straight away under the chip (v0.9.220).
		var tip_text := "%s\n%s" % [name_text.to_upper(), String(GD.PLANET_TRAITS.get(name_text, ""))]
		chip.mouse_entered.connect(_show_trait_tip.bind(chip, tip_text))
		chip.mouse_exited.connect(_hide_trait_tip)
		row.add_child(chip)
		var inner := HBoxContainer.new()
		inner.add_theme_constant_override("separation", 5)
		inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chip.add_child(inner)
		var icon := Control.new()   # a little faceted rock
		icon.custom_minimum_size = Vector2(16, 16)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var draw_rock := func() -> void:
			var pts := PackedVector2Array([Vector2(2, 12), Vector2(5, 4), Vector2(10, 2), Vector2(14, 6), Vector2(14, 13), Vector2(7, 15)])
			icon.draw_colored_polygon(pts, Color("8a7a62"))
			icon.draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[4], pts[5], pts[0]]), Color("e0c68f"), 1.2, true)
			icon.draw_line(Vector2(5, 4), Vector2(8, 10), Color("e0c68f", 0.6), 1.0, true)
			icon.draw_line(Vector2(8, 10), Vector2(14, 6), Color("e0c68f", 0.6), 1.0, true)
			icon.draw_line(Vector2(8, 10), Vector2(7, 15), Color("e0c68f", 0.6), 1.0, true)
		icon.draw.connect(draw_rock)
		inner.add_child(icon)
		var lab := _make_label(inner, Color("f0d9a8"), 14)
		lab.text = name_text
		lab.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _fill_planet_view(box: VBoxContainer, p: Dictionary, income: Dictionary, interactive: bool) -> void:
	var owner: int = p["owner"]
	var pops: int = p["pops"]
	var capacity: int = p["capacity"]
	box.add_theme_constant_override("separation", 10)

	# Header: the planet itself, spinning, beside its name, owner and world type.
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 14)
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(header)
	var globe_box := Control.new()
	globe_box.custom_minimum_size = Vector2(84, 84)
	globe_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(globe_box)
	var globe := PlanetBody.new()
	globe_box.add_child(globe)
	globe.setup(p, false)
	globe.size = Vector2(84, 84)
	globe.position = Vector2.ZERO
	globe.smooth()
	var names := VBoxContainer.new()
	names.add_theme_constant_override("separation", 2)
	names.alignment = BoxContainer.ALIGNMENT_CENTER
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	names.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(names)
	var title := _make_label(names, Color("f4efe2"), 26)
	title.text = String(p["name"]).to_upper()
	var owner_text := "Uncolonized"
	match owner:
		GD.Faction.UNE:
			owner_text = "United Nations of Earth"
		GD.Faction.REBELS:
			owner_text = "Roid Rebels"
		GD.Faction.SONS:
			owner_text = "Sons of Philip"
	if p["kind"] == "earth":
		owner_text += "  ·  Capital"
	var owner_label := _make_label(names, GD.ring_colour(owner) if owner != GD.Faction.NEUTRAL else Color("aeb9c6"), 15)
	owner_label.text = owner_text
	# What its pops make: "Desert world: 1 Alloy per 3 pops".
	var made := GD.pop_yield(p)
	var type_label := _make_label(names, Color("c9d6dd"), 14)
	if made.is_empty():
		type_label.text = "Dead world: nothing grows here"
	else:
		type_label.text = "%s  ·  %s per %d pops" % [String(made["name"]), String(made["unit"]), int(made["per"])]
	if interactive:
		var close := Button.new()
		close.text = "X"
		close.focus_mode = Control.FOCUS_NONE
		close.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		close.pressed.connect(hide_planet)
		header.add_child(close)
	# A short gold rule, like the card window's heading.
	var rule := ColorRect.new()
	rule.color = Color("e8c547")
	rule.custom_minimum_size = Vector2(120, 3)
	rule.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(rule)
	_traits_row(box, p)

	if capacity > 0:
		# Pop track: a head per pop up to capacity, growth dots, reward thresholds.
		var pop_head := "POPULATION  %d / %d" % [pops, capacity]
		if owner == GD.Faction.UNE and not made.is_empty() and pops < capacity and int(made["next"]) <= capacity:
			pop_head += "   ·   next income and reward at %d" % int(made["next"])
		var pop_block := _planet_inset(box, pop_head)
		var track := PopTrack.new()
		track.pops = pops
		track.capacity = capacity
		track.peak = int(p.get("reward_peak", pops))
		track.every = GD.reward_every(p)
		track.progress = 0.0 if pops >= capacity or pops <= 0 else clampf(float(p["growth_progress"]) / float(GD.growth_needed(pops)), 0.0, 1.0)
		pop_block.add_child(track)
		if GD.show_full_names:
			var legend := _make_label(pop_block, Color("93a3ad"), 12)
			legend.text = "dots: growth to the next pop  ·  gold tick: Growth Reward earned"

	# Status and income as small icons with numbers (hold Space for their names).
	var stat_block := _planet_inset(box, "STATUS  ·  PER DAY")
	var stats := HFlowContainer.new()
	stats.add_theme_constant_override("h_separation", 14)
	stats.add_theme_constant_override("v_separation", 6)
	stats.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stat_block.add_child(stats)
	if pops > 0:
		var rate := 1.5 if Array(p["buildings"]).has("Cryo Medicals") else 1.0
		_stat(stats, "growth", "Full" if pops >= capacity else "+%s" % str(rate), "Growth", Color(GD.GAIN_COLOUR))
		# Stability is hidden for now (still tracked); it comes back later.
		_stat(stats, "devastation", "%d" % int(p["devastation"]), "Devastation", Color("e0823a"))
	_stat(stats, "health", "%d" % int(p["health"]), "Health", Color("e5484d"))
	if int(income.get("credits", 0)) > 0:
		_stat(stats, "credits", "+%d" % int(income["credits"]), "per day", Color("e8c547"))
	if int(income.get("alloys", 0)) > 0:
		_stat(stats, "alloys", "+%d" % int(income["alloys"]), "per day", Color("c79bff"))
	if int(income.get("gas", 0)) > 0:
		_stat(stats, "gas", "+%d" % int(income["gas"]), "per day", Color("8fd14f"))
	if pops <= 0 and owner == GD.Faction.NEUTRAL and capacity <= 0:
		var hostile := _make_label(stat_block, Color("e0823a"), 14)
		hostile.text = "Uninhabitable: it can't be colonized."
	elif pops <= 0 and owner == GD.Faction.NEUTRAL:
		var how := _make_label(stat_block, Color("93a3ad"), 14)
		how.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		how.custom_minimum_size = Vector2(340, 0)
		how.text = "To colonize, fly the Kharkiv into the rocket button above this planet. It costs:"
		var price := IconText.new(14, Color("c9d2d8"), 3)
		price.alignment = BoxContainer.ALIGNMENT_BEGIN
		stat_block.add_child(price)
		price.text = "1 pop   {alloys}%d   {credits}%d" % [GD.colony_alloys(), GD.COLONY_CREDITS]

	# The six building slots: the heart of the panel.
	if capacity <= 0:
		return
	var buildings: Array = p["buildings"]
	var slot_block := _planet_inset(box, "BUILDINGS  %d / 6" % buildings.size())
	var slots := GridContainer.new()
	slots.columns = 3
	slots.add_theme_constant_override("h_separation", 8)
	slots.add_theme_constant_override("v_separation", 8)
	slots.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot_block.add_child(slots)
	var pending := int(p.get("pending_cards", 0))
	for i in 6:
		var tile := _building_tile(String(buildings[i]) if i < buildings.size() else "", interactive)
		# Growth Rewards waiting: the next empty slots glow gold and can be clicked to pick.
		if i >= buildings.size() and i < buildings.size() + pending:
			_make_reward_slot(tile, interactive)
		slots.add_child(tile)


func _stat(parent: Control, kind: String, value: String, title: String, colour: Color) -> void:
	var icon := StatIcon.new()
	icon.kind = kind
	icon.value = value
	icon.title = title if GD.show_full_names else ""
	icon.colour = colour
	parent.add_child(icon)


const BUILDING_ICONS := {
	"City": "¢", "PD MAG": "PD", "Fleet Academy": "FA", "Tech Lab": "TL",
	"Cryo Medicals": "CM", "Logistics Hub": "LH", "Mining Corp": "MC", "Gas Refineries": "GR",
	"Space Elevators": "SE", "Orbital Drydocks": "OD", "Construction Yards": "CY", "Shipwright Guild": "SG", "Repair Gantries": "RG",
	"Tractor Arrays": "TA", "Bunker Foundry": "BF", "Drone Docks": "DD", "Long-Range Batteries": "LB",
	"Hangar Crews": "HC", "Customs Office": "CO", "Hauler Depot": "HD", "Colony Office": "CL", "Trade Port": "TP",
}


func _building_tile(building: String, interactive: bool = true) -> Control:
	var tile := PanelContainer.new()
	var style := StyleBoxFlat.new()
	var filled := building != ""
	style.bg_color = Color("1c2733") if filled else Color(0.05, 0.07, 0.09, 0.6)
	style.border_color = Color("e8c547") if filled else Color("3a444e")
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	tile.add_theme_stylebox_override("panel", style)
	tile.custom_minimum_size = Vector2(120, 96)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.add_child(box)
	if filled:
		# The building's own wobbly card art, animating in the slot.
		var art := CardArt.new()
		art.card_name = building
		art.custom_minimum_size = Vector2(108, 58)
		box.add_child(art)
	else:
		var icon := Label.new()
		icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon.add_theme_font_size_override("font_size", 34)
		icon.add_theme_color_override("font_color", Color("3a444e"))
		icon.text = "+"
		box.add_child(icon)
	var name_label := Label.new()
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 13)
	name_label.add_theme_color_override("font_color", Color("e9e6dc") if filled else Color("4a5862"))
	name_label.text = building if filled else "Empty"
	box.add_child(name_label)
	if filled and interactive:
		# Hover anywhere on the slot (art or name) to see the full card.
		tile.mouse_filter = Control.MOUSE_FILTER_STOP
		tile.tooltip_text = ""
		tile.mouse_entered.connect(_show_building_card.bind(building, tile))
		tile.mouse_exited.connect(_hide_building_card)
	return tile


## Hovering a filled slot pops up that building's card beside the panel.
func _show_building_card(building: String, tile: Control) -> void:
	_hide_building_card()
	var card := {}
	for c in GD.PLANET_CARDS:
		if String(c["name"]) == building:
			card = c
	if card.is_empty():
		return
	var shown := card.duplicate()
	shown["count"] = Array(_planet.get("buildings", [])).count(building)
	var button := _card_button(shown, Color("b89a4a"))
	button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(button)
	button.size = button.custom_minimum_size
	# The panel sits on the left, so the card pops out to its right.
	var at := Vector2(_planet_panel.global_position.x + _planet_panel.size.x + 16.0, tile.global_position.y - button.size.y * 0.35)
	at.y = clampf(at.y, 70.0, get_viewport().get_visible_rect().size.y - button.size.y - 8.0)
	button.position = at
	_card_popup = button


func _hide_building_card() -> void:
	if _card_popup != null and is_instance_valid(_card_popup):
		_card_popup.queue_free()
	_card_popup = null


## The row of pop heads on the planet panel.
class PopTrack extends Control:
	var pops := 0
	var capacity := 10
	var peak := 0
	var every := 2   # pops between Growth Rewards
	var progress := 0.0

	func _init() -> void:
		custom_minimum_size = Vector2(372, 50)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var n := maxi(capacity, 1)
		var step := size.x / float(n)
		var green := Color("3dd17a")
		var empty := Color("2e3a44")
		for i in n:
			var x := (float(i) + 0.5) * step
			var filled := i < pops
			var col := green if filled else empty
			draw_circle(Vector2(x, 20), 5.5, col)
			draw_rect(Rect2(Vector2(x - 7.5, 27), Vector2(15, 9)), col)
			if not filled:
				draw_arc(Vector2(x, 20), 5.5, 0.0, TAU, 16, Color("4a5862"), 1.5)
		# Growth dots toward the next pop.
		if pops > 0 and pops < n:
			var x0 := (float(pops) - 0.5) * step
			for d in 3:
				var dx := x0 + step * (0.3 + 0.2 * d)
				var lit := progress >= (float(d) + 1.0) / 4.0
				draw_circle(Vector2(dx, 28), 2.2, green if lit else Color("4a5862"))
		# Reward thresholds every 2nd (or 3rd) pop, with a check once earned.
		var t := every
		while t <= n:
			var x := minf(float(t) * step, size.x - 2.0)
			var earned := peak >= t
			draw_line(Vector2(x, 8), Vector2(x, 42), Color("e8c547") if earned else Color("4a5862"), 2.0)
			if earned:
				draw_polyline(PackedVector2Array([Vector2(x - 5, 4), Vector2(x - 1, 8), Vector2(x + 6, 0)]), Color("e8c547"), 2.0)
			t += every


## A small stat icon with its number (and its name while Space is held).
class StatIcon extends Control:
	var kind := ""
	var value := ""
	var title := ""
	var colour := Color.WHITE
	var _font: Font

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _ready() -> void:
		_font = ThemeDB.fallback_font
		var text := value + ("  " + title if title != "" else "")
		custom_minimum_size = Vector2(26 + _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x, 24)

	func _draw() -> void:
		var c := Vector2(10, 12)
		match kind:
			"growth":
				draw_colored_polygon(PackedVector2Array([c + Vector2(0, -8), c + Vector2(7, 0), c + Vector2(2.5, 0), c + Vector2(2.5, 8), c + Vector2(-2.5, 8), c + Vector2(-2.5, 0), c + Vector2(-7, 0)]), colour)
			"stability":
				draw_colored_polygon(PackedVector2Array([c + Vector2(-7, -7), c + Vector2(7, -7), c + Vector2(7, 1), c + Vector2(0, 8), c + Vector2(-7, 1)]), colour)
			"devastation":
				draw_polyline(PackedVector2Array([c + Vector2(-2, -8), c + Vector2(3, -2), c + Vector2(-3, 1), c + Vector2(2, 8)]), colour, 2.5)
				draw_arc(c, 8.0, 0.0, TAU, 16, colour, 2.0)
			"health":
				draw_rect(Rect2(c + Vector2(-2.5, -8), Vector2(5, 16)), colour)
				draw_rect(Rect2(c + Vector2(-8, -2.5), Vector2(16, 5)), colour)
			"credits", "alloys", "gas":
				preload("res://scripts/res_icon.gd").draw(self, kind, c, 8.0)
		var text := value + ("  " + title if title != "" else "")
		draw_string(_font, Vector2(24, 18), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("e9e6dc"))


# --- wave countdown, prompts, off-screen warnings --------------------------------------

func _make_wave_and_prompt() -> void:
	_wave_pill = PanelContainer.new()
	var pill := _panel_style()
	pill.set_corner_radius_all(14)
	pill.content_margin_left = 18
	pill.content_margin_right = 18
	pill.content_margin_top = 3
	pill.content_margin_bottom = 3
	_wave_pill.add_theme_stylebox_override("panel", pill)
	_wave_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_wave_pill)
	_wave_pill.anchor_left = 0.5
	_wave_pill.anchor_right = 0.5
	_wave_pill.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_wave_pill.offset_top = 102.0   # under the Fleet Mode banner
	_wave_label = Label.new()
	_wave_label.add_theme_font_size_override("font_size", 20)
	_wave_label.add_theme_color_override("font_outline_color", Color("0b0e14"))
	_wave_label.add_theme_constant_override("outline_size", 6)
	_wave_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_wave_label.add_theme_font_size_override("font_size", 17)
	_wave_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_wave_pill.add_child(_wave_label)
	_wave_pill.visible = false
	# Prompts ("Colonize Kruger III: needs a Starbase in this system") sit well up the
	# screen, big and bright on a dark plate, so you can't miss why something won't work.
	_prompt_plate = PanelContainer.new()
	var plate := StyleBoxFlat.new()
	plate.bg_color = Color(0.02, 0.04, 0.05, 0.82)
	plate.border_color = Color("3dd17a")
	plate.set_border_width_all(2)
	plate.set_corner_radius_all(8)
	plate.content_margin_left = 16
	plate.content_margin_right = 16
	plate.content_margin_top = 5
	plate.content_margin_bottom = 5
	plate.shadow_color = Color(0, 0, 0, 0.5)
	plate.shadow_size = 12
	_prompt_plate.add_theme_stylebox_override("panel", plate)
	_prompt_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_prompt_plate)
	_prompt_plate.anchor_left = 0.5
	_prompt_plate.anchor_right = 0.5
	_prompt_plate.anchor_top = 1.0
	_prompt_plate.anchor_bottom = 1.0
	_prompt_plate.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_prompt_plate.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_prompt_plate.offset_bottom = -150.0   # just above the hotkey bar, out of the middle
	_prompt_plate.visible = false
	_prompt_label = IconText.new(19, Color("5be38f"), 6)
	_prompt_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prompt_plate.add_child(_prompt_label)


## The next Rebel wave countdown; red and flashing in its last 15 seconds.
func show_wave(text: String, urgent: bool) -> void:
	_wave_pill.visible = text != ""
	_wave_label.text = text
	var flash := urgent and int(Time.get_ticks_msec() / 300) % 2 == 0
	_wave_label.add_theme_color_override("font_color", Color("e5484d") if urgent else Color("d0703a"))
	_wave_label.modulate.a = 1.0 if not urgent or flash else 0.55


func show_prompt(text: String) -> void:
	_prompt_label.text = text
	if _prompt_plate != null:
		_prompt_plate.visible = text != ""
		# A gentle pulse on the plate's border while it's up.
		var plate := _prompt_plate.get_theme_stylebox("panel") as StyleBoxFlat
		if plate != null:
			plate.border_color = Color(0.24, 0.82, 0.48, 0.55 + 0.45 * absf(sin(Time.get_ticks_msec() / 400.0)))


func _make_warning_layer() -> void:
	_warn_layer = Control.new()
	_warn_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_warn_layer)
	_warn_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_warn_layer.draw.connect(_draw_warnings)


## Off-screen warnings from main: each sits at the screen edge, pointing at the trouble.
func set_warnings(list: Array) -> void:
	_warnings = list
	while _warn_buttons.size() < _warnings.size():
		var button := Button.new()
		button.flat = true
		button.focus_mode = Control.FOCUS_NONE
		button.custom_minimum_size = Vector2(64, 64)
		button.size = Vector2(64, 64)
		var index := _warn_buttons.size()
		button.pressed.connect(_on_warning_pressed.bind(index))
		_warn_layer.add_child(button)
		_warn_buttons.append(button)
	for i in _warn_buttons.size():
		var button: Button = _warn_buttons[i]
		button.visible = i < _warnings.size()
		if button.visible:
			var w: Dictionary = _warnings[i]
			button.position = Vector2(w["screen"]) - Vector2(32, 32)


func _on_warning_pressed(index: int) -> void:
	if index < _warnings.size():
		var w: Dictionary = _warnings[index]
		notification_clicked.emit(int(w["system"]), Vector2(w["pos"]))


func _draw_warnings() -> void:
	var pulse := 0.55 + 0.45 * absf(sin(Time.get_ticks_msec() / 1000.0 * 4.0))
	var red := Color(0.9, 0.28, 0.3, pulse)
	for w in _warnings:
		var c: Vector2 = w["screen"]
		var angle: float = w["angle"]
		_warn_layer.draw_circle(c, 26.0, Color(0.04, 0.05, 0.08, 0.85))
		_warn_layer.draw_arc(c, 26.0, 0.0, TAU, 32, red, 3.0)
		# Arrow pointing toward the trouble.
		var dir := Vector2.RIGHT.rotated(angle)
		var tip := c + dir * 40.0
		_warn_layer.draw_colored_polygon(PackedVector2Array([tip, c + dir * 29.0 + dir.orthogonal() * 8.0, c + dir * 29.0 - dir.orthogonal() * 8.0]), red)
		match String(w["kind"]):
			"fleet":
				for j in 3:
					var o := c + Vector2(-10.0 + j * 10.0, 4.0 if j != 1 else -4.0)
					_warn_layer.draw_colored_polygon(PackedVector2Array([o + Vector2(0, -6), o + Vector2(5, 5), o + Vector2(-5, 5)]), red)
			"planet":
				_warn_layer.draw_circle(c, 11.0, red)
				_warn_layer.draw_arc(c, 16.0, -0.4, PI + 0.4, 16, red, 2.0)
			"starbase":
				_warn_layer.draw_rect(Rect2(c - Vector2(9, 9), Vector2(18, 18)), red)
				_warn_layer.draw_rect(Rect2(c - Vector2(4, 4), Vector2(8, 8)), Color(0.04, 0.05, 0.08))
			"hauler", "civilian":
				_warn_layer.draw_rect(Rect2(c - Vector2(10, 7), Vector2(20, 14)), red)
				_warn_layer.draw_line(c + Vector2(-10, 0), c + Vector2(10, 0), Color(0.04, 0.05, 0.08), 2.0)
			_:
				_warn_layer.draw_circle(c, 9.0, red)


# --- card choice ---------------------------------------------------------------

## Shows a pick-1-of-N card choice over a dimmed screen. The game pauses meanwhile.
func show_card_choice(title: String, subtitle: String, cards: Array, frame: Color, side_lines: Array = [], planet: Dictionary = {}) -> void:
	Sfx.ui("card_appear")
	if _card_layer != null:
		_card_layer.queue_free()
	_card_layer = ColorRect.new()
	(_card_layer as ColorRect).color = Color(0.015, 0.022, 0.04, 0.84)
	add_child(_card_layer)
	_card_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_card_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	# A soft band of the reward's colour behind the cards, so the screen isn't flat black.
	var band := ColorRect.new()
	band.color = Color(frame, 0.07)
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card_layer.add_child(band)
	band.set_anchors_and_offsets_preset(Control.PRESET_HCENTER_WIDE)
	band.offset_top = -260
	band.offset_bottom = 300

	var centre := CenterContainer.new()
	_card_layer.add_child(centre)
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	centre.add_child(column)
	_card_column = column

	# Heading: the title, a short gold rule, and the instruction under it.
	var heading := _make_label(column, Color("f4efe2"), 38)
	heading.text = title
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	heading.add_theme_constant_override("outline_size", 6)
	var rule_box := CenterContainer.new()
	column.add_child(rule_box)
	var rule := ColorRect.new()
	rule.color = Color("e8c547")
	rule.custom_minimum_size = Vector2(220, 3)
	rule_box.add_child(rule)
	var sub := _make_label(column, Color("a9b4c0"), 18)
	sub.text = subtitle
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# Extra room so the heading sits clear of the cards' glow.
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 34)
	column.add_child(gap)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 56)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_child(row)
	if not side_lines.is_empty():
		# Planet rewards: the planet itself, spinning, with its details on a card in
		# front of it, out on the left edge of the screen. It sits outside the card row
		# so the cards stay centred.
		var side := Control.new()
		side.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_card_layer.add_child(side)
		side.set_anchors_preset(Control.PRESET_CENTER_LEFT)
		side.offset_left = 70.0
		side.offset_right = 390.0
		side.offset_top = -170.0
		side.offset_bottom = 190.0
		if not planet.is_empty():
			var globe := PlanetBody.new()
			side.add_child(globe)
			globe.setup(planet, false)
			globe.size = Vector2(380, 380)
			globe.position = Vector2(-30, -60)
		var info := PanelContainer.new()
		var info_style := _panel_style()
		info_style.bg_color = Color(0.03, 0.045, 0.07, 0.82)
		info_style.border_color = Color(frame, 0.9)
		info_style.set_border_width_all(2)
		info_style.border_width_top = 4
		info_style.set_corner_radius_all(8)
		info_style.content_margin_top = 14
		info_style.content_margin_bottom = 14
		info.add_theme_stylebox_override("panel", info_style)
		info.custom_minimum_size = Vector2(300, 0)
		side.add_child(info)
		info.position = Vector2(10, 190)
		info.size = Vector2(300, 0)
		var lines_box := VBoxContainer.new()
		lines_box.add_theme_constant_override("separation", 8)
		info.add_child(lines_box)
		for i in side_lines.size():
			var line := _make_label(lines_box, Color("f4efe2") if i == 0 else Color("c9d2d8"), 26 if i == 0 else 17)
			line.text = String(side_lines[i])
			line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			line.custom_minimum_size = Vector2(264, 0)
	for card in cards:
		row.add_child(_card_button(card, frame))
	if redraw_cost > 0:
		# Down near the bottom of the screen, away from the cards (v0.9.153).
		var redraw_box := CenterContainer.new()
		_card_layer.add_child(redraw_box)
		redraw_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
		redraw_box.grow_horizontal = Control.GROW_DIRECTION_BOTH
		redraw_box.grow_vertical = Control.GROW_DIRECTION_BEGIN
		redraw_box.offset_bottom = -70.0
		redraw_box.add_child(_redraw_button())


## Set by main before a card screen opens: what a Redraw costs now, and whether you
## can pay it.
var redraw_cost := 0
var redraw_ok := true


## A small gold button: a circling arrow, REDRAW, and the price in credits. Draws three
## new cards in place of these. Greyed out when you can't afford it.
func _redraw_button() -> Button:
	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(190, 44)
	var gold := Color("e8c547")
	for state in ["normal", "hover", "pressed", "disabled"]:
		var st := StyleBoxFlat.new()
		match state:
			"normal":
				st.bg_color = Color("3a2e10")
				st.border_color = gold
			"hover":
				st.bg_color = Color("54421a")
				st.border_color = Color("fff0a8")
			"pressed":
				st.bg_color = Color("2a2108")
				st.border_color = gold
			"disabled":
				st.bg_color = Color(0.12, 0.12, 0.13, 0.9)
				st.border_color = Color("4a4f55")
		st.set_border_width_all(2)
		st.border_width_bottom = 4
		st.set_corner_radius_all(8)
		st.shadow_color = Color(0.91, 0.77, 0.28, 0.25) if state != "disabled" else Color(0, 0, 0, 0)
		st.shadow_size = 8
		st.content_margin_left = 14
		st.content_margin_right = 14
		button.add_theme_stylebox_override(state, st)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(row)
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var colour := Color("f4e3a1") if redraw_ok else Color("6f767d")
	var label := _make_label(row, colour, 18)
	label.text = "↻  REDRAW"
	var price := IconText.new(18, Color("ffd23f") if redraw_ok else Color("6f767d"), 3)
	price.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(price)
	price.text = "{credits}%d" % redraw_cost
	button.disabled = not redraw_ok
	button.tooltip_text = "Draw three new cards instead of these. The price doubles each time." if redraw_ok else "Not enough credits."
	button.pressed.connect(func() -> void: redraw_requested.emit())
	return button


## Xander inside a card choice window: a strip at the bottom of the screen with his portrait,
## a line and tip, and an animated diagram. Picking a card closes it with the window.
func add_card_advice(key: String, text: String, tip: String, art_id: String) -> void:
	if _card_column == null or not is_instance_valid(_card_column) or xander == null:
		return
	xander.call("mark_said", key)
	var strip := PanelContainer.new()
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.035, 0.05, 0.1, 0.94)
	st.border_color = Color("c9a55a")
	st.set_border_width_all(2)
	st.set_corner_radius_all(6)
	st.content_margin_left = 14
	st.content_margin_right = 14
	st.content_margin_top = 12
	st.content_margin_bottom = 12
	strip.add_theme_stylebox_override("panel", st)
	# At the very bottom of the screen, over the Redraw button, so the cards keep
	# their place and his words don't crowd them (v0.9.156; was under the cards).
	var dock := CenterContainer.new()
	_card_layer.add_child(dock)
	dock.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	dock.grow_horizontal = Control.GROW_DIRECTION_BOTH
	dock.grow_vertical = Control.GROW_DIRECTION_BEGIN
	dock.offset_bottom = -18.0
	dock.add_child(strip)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	strip.add_child(row)
	# His portrait, in the teal frame.
	var frame := PanelContainer.new()
	var fs := StyleBoxFlat.new()
	fs.bg_color = Color("0c2129")
	fs.border_color = Color("c9a55a")
	fs.set_border_width_all(2)
	fs.set_corner_radius_all(4)
	frame.add_theme_stylebox_override("panel", fs)
	frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(frame)
	var portrait: Control = Xander.Portrait.new()
	portrait.custom_minimum_size = Vector2(126, 156)
	frame.add_child(portrait)
	# His words.
	var words := VBoxContainer.new()
	words.add_theme_constant_override("separation", 8)
	words.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(words)
	var name_label := _make_label(words, Color("f0d27a"), 14)
	name_label.text = "XANDER"
	var line := _make_label(words, Color("f4efe2"), 18)
	line.text = text
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	line.custom_minimum_size = Vector2(340, 0)
	var tip_label := _make_label(words, Color("9fb6c8"), 15)
	tip_label.text = tip
	tip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tip_label.custom_minimum_size = Vector2(340, 0)
	var hush := Button.new()
	hush.text = "  DON'T WARN ME AGAIN  "
	hush.flat = true
	hush.focus_mode = Control.FOCUS_NONE
	hush.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	hush.add_theme_font_size_override("font_size", 11)
	hush.add_theme_color_override("font_color", Color("8fa3b8"))
	hush.add_theme_color_override("font_hover_color", Color("f0d27a"))
	words.add_child(hush)
	hush.pressed.connect(func() -> void:
		Sfx.ui("click")
		Settings.advisor_dismissed.append(key)
		Settings.save_settings()
		dock.queue_free())
	# The animated diagram.
	var art: Control = Xander.Lesson.new()
	art.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(art)
	art.call("set_page", art_id)


func _card_button(card: Dictionary, frame: Color) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(250, 340)
	button.focus_mode = Control.FOCUS_NONE
	var rarity := String(card.get("rarity", "Good"))
	var glow := GD.rarity_colour(rarity)
	var normal := StyleBoxFlat.new()
	normal.bg_color = frame
	normal.border_color = glow
	normal.set_border_width_all(4)
	normal.set_corner_radius_all(6)
	normal.shadow_color = Color(glow, 0.45)
	normal.shadow_size = 18
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = frame.lightened(0.15)
	hover.shadow_size = 28
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)

	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 6)
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(inner)
	inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inner.offset_left = 10
	inner.offset_right = -10
	inner.offset_top = 10
	inner.offset_bottom = -10

	var name_panel := PanelContainer.new()
	var name_style := StyleBoxFlat.new()
	name_style.bg_color = Color("0b0e14")
	name_style.content_margin_left = 8
	name_style.content_margin_right = 8
	name_style.content_margin_top = 5
	name_style.content_margin_bottom = 5
	# The title gets its own plate: a rarity-coloured underline, rounded top corners.
	var title_style := name_style.duplicate() as StyleBoxFlat
	title_style.content_margin_top = 5
	title_style.content_margin_bottom = 5
	title_style.border_width_bottom = 3
	title_style.border_color = glow
	title_style.corner_radius_top_left = 4
	title_style.corner_radius_top_right = 4
	name_panel.add_theme_stylebox_override("panel", title_style)
	name_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(name_panel)
	var name_label := Label.new()
	name_label.text = String(card["name"]).to_upper()
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# The biggest size (up to 24) that fits the card on one line, smaller for long names (v0.9.169).
	var title_font := name_label.get_theme_font("font")
	var title_size := 24
	while title_size > 11 and title_font.get_string_size(name_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size).x + 6.0 > 206.0:
		title_size -= 1
	name_label.add_theme_font_size_override("font_size", title_size)
	name_label.add_theme_color_override("font_color", Color("f4efe2"))
	name_label.add_theme_color_override("font_outline_color", Color("000000"))
	name_label.add_theme_constant_override("outline_size", 4)
	name_label.add_theme_color_override("font_shadow_color", Color(glow, 0.45))
	name_label.add_theme_constant_override("shadow_offset_x", 0)
	name_label.add_theme_constant_override("shadow_offset_y", 2)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_panel.add_child(name_label)

	var count := int(card.get("count", 0))
	var info_row := HBoxContainer.new()
	info_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info_row.add_theme_constant_override("separation", 10)
	inner.add_child(info_row)
	var dots := Label.new()
	dots.text = "Picked x%d" % count if count > 0 else "New"
	if rarity != "Good":
		dots.text += "   %s: x%d effect" % [rarity.to_upper(), GD.rarity_mult(rarity)]
	dots.add_theme_font_size_override("font_size", 13)
	dots.add_theme_color_override("font_color", Color("0b0e14"))
	dots.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dots.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_row.add_child(dots)
	if card.has("price"):
		# Arms dealer price as the $ icon and the number, on the same row.
		var price := IconText.new(20, Color("0b0e14"), 0)   # was 16
		price.alignment = BoxContainer.ALIGNMENT_END
		info_row.add_child(price)
		price.text = "{credits}%d" % int(card["price"])

	# Scribbled card art (card_art.gd): a silly little doodle per card. The star of
	# the card: it takes the room, and the text below stays short.
	var art := CardArt.new()
	art.card_name = String(card["name"])
	art.zoom = 1.18   # zoomed in past "fit": the drawing fills the frame edge to edge
	art.custom_minimum_size = Vector2(0, 130)   # about the drawing's own shape: no paper bands
	inner.add_child(art)

	var text_panel := PanelContainer.new()
	text_panel.add_theme_stylebox_override("panel", name_style)
	text_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(text_panel)
	# Resource words and ¢ amounts show as their icons (v0.9.162).
	var text := IconWrap.new()
	text.font_size = 17   # was 15 (v0.9.166)
	text.set_text(String(card["text"]))
	text_panel.add_child(text)

	# Collector number in a little circle at the bottom, shown while Info (Space) is held.
	var code := GD.card_code(String(card["name"]))
	if code != "":
		var badge := CardNumber.new()
		badge.code = code
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge.visible = Input.is_action_pressed("full_names")
		badge.add_to_group("card_numbers")
		button.add_child(badge)
		badge.anchor_left = 0.5
		badge.anchor_right = 0.5
		badge.anchor_top = 1.0
		badge.anchor_bottom = 1.0
		badge.offset_left = -22
		badge.offset_right = 22
		badge.offset_top = -26
		badge.offset_bottom = 18
	if bool(card.get("view", false)):
		button.focus_mode = Control.FOCUS_NONE   # the collection: look, don't pick
	elif card.has("slot"):
		button.disabled = bool(card.get("locked", false))
		button.pressed.connect(func() -> void: _shop_card_pressed(button, card))
	else:
		button.pressed.connect(func() -> void: _on_card_pressed(String(card["name"]), button))
	return button


var _collection_open := false


## Every card you've picked this run (Fleet, Tech and every planet building), in a
## scrolling gallery. Opened from the card fan beside the XP bar; Esc or Close shuts it.
func show_collection(fleet: Array, tech: Array, buildings: Dictionary) -> void:
	if _card_layer != null or _flying:
		return
	_collection_open = true
	get_tree().paused = true
	_card_layer = ColorRect.new()
	(_card_layer as ColorRect).color = Color(0.02, 0.03, 0.05, 0.9)
	add_child(_card_layer)
	_card_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_card_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	var centre := CenterContainer.new()
	_card_layer.add_child(centre)
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	var style := _guide_shell_style()
	style.bg_color = Color(0.11, 0.14, 0.18, 0.97)
	panel.add_theme_stylebox_override("panel", style)
	centre.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	panel.add_child(column)
	var head := HBoxContainer.new()
	column.add_child(head)
	var title := _make_label(head, Color("e8c547"), 34)
	title.text = "YOUR CARDS"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label_shadow(title, 3)
	var close := Button.new()
	close.text = "   Close   "
	close.focus_mode = Control.FOCUS_NONE
	close.custom_minimum_size = Vector2(0, 44)
	close.add_theme_font_size_override("font_size", 20)
	close.pressed.connect(close_collection)
	head.add_child(close)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(1480, 720)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 18)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(body)
	var sections := [
		["FLEET", _tally(fleet), GD.FLEET_CARDS, Color("a4504a")],
		["TECH", _tally(tech), GD.TECH_CARDS, Color("3e6690")],
		["PLANET BUILDINGS", buildings, GD.PLANET_CARDS, Color("b89a4a")],
	]
	var any := false
	for sec in sections:
		var counts: Dictionary = sec[1]
		if counts.is_empty():
			continue
		any = true
		var total := 0
		for k in counts.keys():
			total += int(counts[k])
		var caption := _make_label(body, Color("8fb4e3"), 20)
		caption.text = "%s  ·  %d" % [String(sec[0]), total]
		var grid := GridContainer.new()
		grid.columns = 7
		grid.add_theme_constant_override("h_separation", 12)
		grid.add_theme_constant_override("v_separation", 12)
		body.add_child(grid)
		for def in Array(sec[2]):
			var card_name := String(def["name"])
			if not counts.has(card_name):
				continue
			var shown: Dictionary = (def as Dictionary).duplicate()
			shown["count"] = int(counts[card_name])
			shown["view"] = true
			# Cards drawn at 80% so seven fit across.
			var holder := Control.new()
			holder.custom_minimum_size = Vector2(200, 272)
			grid.add_child(holder)
			var card := _card_button(shown, Color(sec[3]))
			card.scale = Vector2(0.8, 0.8)
			holder.add_child(card)
	if not any:
		var none := _make_label(body, Color("93a3ad"), 20)
		none.text = "No cards yet. Earn Fleet XP, grow your planets and find Tech to fill this up."


func close_collection() -> void:
	if not _collection_open:
		return
	_collection_open = false
	Sfx.ui("click")
	if _card_layer != null:
		_card_layer.queue_free()
		_card_layer = null
	get_tree().paused = _paused_by_player


## How many of each card name a list holds.
func _tally(names: Array) -> Dictionary:
	var out := {}
	for n in names:
		out[String(n)] = int(out.get(String(n), 0)) + 1
	return out


func _on_card_pressed(card_name: String, button: Button) -> void:
	if _flying:
		return
	Sfx.ui("card_pick")
	_flying = true
	var rect := button.get_global_rect()
	var frame_style := button.get_theme_stylebox("normal") as StyleBoxFlat
	var flyer := _make_flyer(rect, frame_style.bg_color if frame_style != null else Color("3e6690"), frame_style.border_color if frame_style != null else Color.WHITE, card_name)
	if _card_layer != null:
		_card_layer.queue_free()
		_card_layer = null
	# Pop, then fly to whatever got the card, then vanish. The game stays paused meanwhile.
	var tween := create_tween()
	tween.tween_property(flyer, "scale", Vector2(1.15, 1.15), 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(flyer, "modulate", Color(1.6, 1.6, 1.6, 1.0), 0.06)
	tween.tween_property(flyer, "modulate", Color.WHITE, 0.06)
	tween.set_parallel(true)
	tween.tween_property(flyer, "position", fly_target - rect.size * 0.125 - Vector2(0, 60), 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT).set_delay(0.12)
	tween.tween_property(flyer, "scale", Vector2(0.25, 0.25), 0.35).set_delay(0.12)
	tween.set_parallel(false)
	tween.tween_property(flyer, "modulate:a", 0.0, 0.12)
	tween.tween_callback(_finish_fly.bind(flyer, card_name))


func _finish_fly(flyer: Control, card_name: String) -> void:
	Sfx.ui("card_land")
	flyer.queue_free()
	_flying = false
	card_picked.emit(card_name)


## A simple copy of the picked card that can fly around the screen.
func _make_flyer(rect: Rect2, fill: Color, border: Color, card_name: String) -> Panel:
	var flyer := Panel.new()
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(4)
	style.set_corner_radius_all(6)
	style.shadow_color = Color(border, 0.6)
	style.shadow_size = 20
	flyer.add_theme_stylebox_override("panel", style)
	flyer.position = rect.position
	flyer.size = rect.size
	flyer.pivot_offset = rect.size / 2.0
	flyer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flyer)
	var label := Label.new()
	label.text = card_name
	label.add_theme_font_size_override("font_size", 22)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	flyer.add_child(label)
	return flyer


# --- Arms Dealer shop -----------------------------------------------------------

## Shows the Arms Dealer's 6 slots. Each stock entry is a card dictionary or {} once bought.
func show_shop(stock: Array, credits: int, refresh_cost: int) -> void:
	if _card_layer != null:
		_card_layer.queue_free()
	_card_layer = ColorRect.new()
	(_card_layer as ColorRect).color = Color(0.02, 0.03, 0.05, 0.82)
	add_child(_card_layer)
	_card_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_card_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	var centre := CenterContainer.new()
	_card_layer.add_child(centre)
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	centre.add_child(column)
	var heading := _make_label(column, Color("e8c14a"), 36)
	heading.text = "ARMS DEALER"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var sub := IconText.new(18, Color("93a3ad"), 0)
	column.add_child(sub)
	sub.text = "Fleet and Tech cards of every rarity. You have {credits}%d" % credits
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 40)
	grid.add_theme_constant_override("v_separation", 24)
	column.add_child(grid)
	for i in stock.size():
		var entry: Dictionary = stock[i]
		if entry.is_empty():
			var sold := Label.new()
			sold.text = "SOLD"
			sold.custom_minimum_size = Vector2(250, 340)
			sold.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			sold.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			sold.add_theme_color_override("font_color", Color("4a5058"))
			sold.add_theme_font_size_override("font_size", 28)
			grid.add_child(sold)
			continue
		var card := entry.duplicate()
		card["slot"] = i
		card["locked"] = credits < int(card["price"])
		var frame := Color("a4504a") if String(card["type"]) == "fleet" else Color("3e6690")
		grid.add_child(_card_button(card, frame))
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 30)
	column.add_child(buttons)
	var refresh := Button.new()
	refresh.text = "Refresh offers  %d" % refresh_cost
	# The $ icon on the button.
	var coin := ResIconControl.new("credits", 22.0)
	coin.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	coin.position.x -= 30.0
	refresh.add_child(coin)
	refresh.disabled = credits < refresh_cost
	refresh.focus_mode = Control.FOCUS_NONE
	refresh.add_theme_font_size_override("font_size", 20)
	refresh.pressed.connect(func() -> void: shop_refresh.emit())
	buttons.add_child(refresh)
	var leave := Button.new()
	leave.text = "Leave"
	leave.focus_mode = Control.FOCUS_NONE
	leave.add_theme_font_size_override("font_size", 20)
	leave.pressed.connect(func() -> void: shop_leave.emit())
	buttons.add_child(leave)
	# The dealer himself, on his scrap pile at the left of the screen.
	var dealer := DealerPortrait.new()
	_card_layer.add_child(dealer)
	dealer.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT)
	dealer.offset_left = 40.0
	dealer.offset_right = 460.0
	dealer.offset_top = -260.0
	dealer.offset_bottom = 300.0


func close_overlay() -> void:
	if _card_layer != null:
		_card_layer.queue_free()
		_card_layer = null


func _shop_card_pressed(button: Button, card: Dictionary) -> void:
	Sfx.ui("cash")
	# The bought card flies to the fleet (Fleet cards) or the TECH counter (Tech cards).
	var rect := button.get_global_rect()
	var frame_style := button.get_theme_stylebox("normal") as StyleBoxFlat
	var flyer := _make_flyer(rect, frame_style.bg_color, frame_style.border_color, String(card["name"]))
	var target := fly_target if String(card["type"]) == "fleet" else earth_target
	var tween := create_tween()
	tween.tween_property(flyer, "scale", Vector2(1.15, 1.15), 0.1)
	tween.set_parallel(true)
	tween.tween_property(flyer, "position", target - rect.size * 0.125 - Vector2(0, 60), 0.35).set_delay(0.1)
	tween.tween_property(flyer, "scale", Vector2(0.25, 0.25), 0.35).set_delay(0.1)
	tween.set_parallel(false)
	tween.tween_property(flyer, "modulate:a", 0.0, 0.12)
	tween.tween_callback(flyer.queue_free)
	shop_buy.emit(int(card["slot"]))


# --- pause and score screen --------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if FeedbackPanel.is_open:
		return   # typing feedback (Enter panel)
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.physical_keycode == KEY_ESCAPE:
		_on_escape()
		return
	if key.physical_keycode != KEY_P or _pause_menu != null:
		return
	# Card choices and the shop already pause the game; P only works outside them.
	if _card_layer != null or _flying:
		return
	if get_tree().paused and not _paused_by_player:
		return
	_paused_by_player = not _paused_by_player
	get_tree().paused = _paused_by_player
	Sfx.ui("blip")
	_pause_frame.visible = _paused_by_player
	set_key_active("P", _paused_by_player)
	get_viewport().set_input_as_handled()


## Game over: the run's numbers, and a button to start again.
## End screen: the score breakdown, revealed row by row, then the total counts up.
## rows: [label, stat, points], most important first.
func show_score(title: String, rows: Array, total: int, footer: String, won: bool, death: Dictionary = {}) -> void:
	if _card_layer != null:
		_card_layer.queue_free()
	_card_layer = ColorRect.new()
	(_card_layer as ColorRect).color = Color(0.02, 0.03, 0.05, 0.9)
	add_child(_card_layer)
	_card_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_card_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	# The flagship lost: its red hologram breaks in two and drifts apart behind
	# everything, and the panels fade in over it after a few seconds (v0.9.188).
	var wrecked := death.has("total")
	var intro_wait := 0.0
	if wrecked:
		(_card_layer as ColorRect).color = Color(0.01, 0.015, 0.03, 0.96)
		_card_layer.add_child(WreckHolo.new())
		intro_wait = 2.8
	var centre := CenterContainer.new()
	_card_layer.add_child(centre)
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if wrecked:
		centre.modulate.a = 0.0
		var fade_in := create_tween()
		fade_in.tween_interval(intro_wait)
		fade_in.tween_property(centre, "modulate:a", 1.0, 1.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
		centre.offset_top = 70.0   # clear of FLAGSHIP OFFLINE
	# Feedback, bottom right (Enter works here too, but players won't know that).
	var fb := Button.new()
	fb.text = "Send feedback"
	fb.focus_mode = Control.FOCUS_NONE
	fb.add_theme_font_size_override("font_size", 18)
	_gold_frame(fb)
	_card_layer.add_child(fb)
	fb.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	fb.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	fb.grow_vertical = Control.GROW_DIRECTION_BEGIN
	fb.offset_right = -32.0
	fb.offset_bottom = -28.0
	fb.tooltip_text = "Or press Enter at any time"
	var open_fb := func() -> void:
		Sfx.ui("click")
		if FeedbackPanel.shared != null:
			FeedbackPanel.shared.call("open")
	fb.pressed.connect(open_fb)
	if wrecked:
		fb.modulate.a = 0.0
		var fb_in := create_tween()
		fb_in.tween_interval(intro_wait)
		fb_in.tween_property(fb, "modulate:a", 1.0, 1.2)
	# Same family as the pause menu and the tutorial: the gold-trimmed shell with a
	# drop shadow (a red top edge when the run is lost), rows set into a dark tray.
	var panel := PanelContainer.new()
	var style := _guide_shell_style()
	style.bg_color = Color(0.14, 0.18, 0.23, 0.97)
	style.border_width_top = 4
	style.border_color = Color("e8c547")
	if not won:
		style.border_color = Color("b89a4a")
	style.content_margin_left = 48
	style.content_margin_right = 48
	style.content_margin_top = 34
	style.content_margin_bottom = 34
	panel.add_theme_stylebox_override("panel", style)
	# Lost the flagship: what killed it, beside the score (v0.9.187).
	if wrecked and not Array(death.get("rows", [])).is_empty():
		var pair := HBoxContainer.new()
		pair.add_theme_constant_override("separation", 24)
		centre.add_child(pair)
		pair.add_child(panel)
		pair.add_child(_death_panel(death))
	else:
		centre.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	panel.add_child(column)
	if not won:
		var stripe := ColorRect.new()
		stripe.color = Color("e5484d")
		stripe.custom_minimum_size = Vector2(0, 4)
		column.add_child(stripe)
	var heading := _make_label(column, Color("e8c547") if won else Color("e5484d"), 42)
	heading.text = title
	heading.visible = not wrecked   # FLAGSHIP OFFLINE says it already
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_shadow(heading, 3)
	var sub := _make_label(column, Color("8fb4e3"), 16)
	sub.text = "FINAL SCORE"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var tray := PanelContainer.new()
	var inset := StyleBoxFlat.new()
	inset.bg_color = Color(0.06, 0.08, 0.11, 0.9)
	inset.border_color = Color(0, 0, 0, 0.7)
	inset.border_width_top = 3
	inset.border_width_left = 2
	inset.border_width_right = 1
	inset.border_width_bottom = 1
	inset.set_corner_radius_all(6)
	inset.content_margin_left = 18
	inset.content_margin_right = 18
	inset.content_margin_top = 12
	inset.content_margin_bottom = 12
	tray.add_theme_stylebox_override("panel", inset)
	column.add_child(tray)
	var rows_box := VBoxContainer.new()
	rows_box.add_theme_constant_override("separation", 8)
	tray.add_child(rows_box)
	var lines: Array = []
	for row in rows:
		var line := HBoxContainer.new()
		line.custom_minimum_size = Vector2(600, 0)
		line.modulate.a = 0.0
		rows_box.add_child(line)
		var a := _make_label(line, Color("c9ced6"), 22)
		a.text = String(row[0])
		a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var stat := _make_label(line, Color("93a3ad"), 20)
		stat.text = String(row[1])
		stat.custom_minimum_size = Vector2(110, 0)
		stat.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		var pts := _make_label(line, Color("f4efe2"), 22)
		pts.text = _thousands(int(row[2]))
		pts.custom_minimum_size = Vector2(130, 0)
		pts.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		lines.append(line)
	var rule := ColorRect.new()
	rule.color = Color("3a4a5a")
	rule.custom_minimum_size = Vector2(600, 2)
	column.add_child(rule)
	var total_row := HBoxContainer.new()
	column.add_child(total_row)
	var total_name := _make_label(total_row, Color("e8c547"), 30)
	total_name.text = "TOTAL"
	total_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label_shadow(total_name)
	var total_label := _make_label(total_row, Color("e8c547"), 36)
	total_label.text = "0"
	_label_shadow(total_label)
	# Best score, kept between runs.
	var best := 0
	var config := ConfigFile.new()
	if config.load("user://scores.cfg") == OK:
		best = int(config.get_value("scores", "best", 0))
	var record := total > best
	if record:
		config.set_value("scores", "best", total)
		config.save("user://scores.cfg")
	var best_label := _make_label(column, Color("3dd17a") if record else Color("93a3ad"), 18)
	best_label.text = "NEW BEST SCORE!" if record else "Best: %s" % _thousands(best)
	best_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	best_label.modulate.a = 0.0
	if footer != "":
		var foot := _make_label(column, Color("93a3ad"), 16)
		foot.text = footer
		foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 20)
	column.add_child(buttons)
	for pair in [["   Start a new run   ", func() -> void: restart_requested.emit()], ["   Main menu   ", func() -> void: menu_requested.emit()]]:
		var b := Button.new()
		b.text = String(pair[0])
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(0, 52)
		b.add_theme_font_size_override("font_size", 24)
		var act: Callable = pair[1]
		b.pressed.connect(func() -> void:
			Sfx.ui("click")
			act.call())
		buttons.add_child(b)
	# Reveal top to bottom, then count the total up.
	var tween := create_tween()
	tween.tween_interval(0.4 + intro_wait)
	for line in lines:
		tween.tween_callback(func() -> void: Sfx.ui("card_pick", -6.0))
		tween.tween_property(line, "modulate:a", 1.0, 0.25)
		tween.tween_interval(0.12)
	tween.tween_callback(func() -> void: Sfx.ui("reward", -2.0))
	tween.tween_method(func(v: float) -> void: total_label.text = _thousands(int(v)), 0.0, float(total), 1.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func() -> void: Sfx.ui("fanfare" if record else "cash", -4.0))
	tween.tween_property(best_label, "modulate:a", 1.0, 0.3)


static func _thousands(value: int) -> String:
	var digits := str(absi(value))
	var out := ""
	while digits.length() > 3:
		out = "," + digits.substr(digits.length() - 3) + out
		digits = digits.substr(0, digits.length() - 3)
	return ("-" if value < 0 else "") + digits + out


# --- music player (beta) --------------------------------------------------------------

## A small player in the top right: scrolling track name, previous / play-pause / next,
## a track list and a volume slider for the Music channel.
func set_music(player: Node) -> void:
	_music = player
	# Lives at the right end of the top bar.
	var style := _panel_style()
	style.set_corner_radius_all(6)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)
	row.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_top_row.add_child(row)
	var note := _make_label(row, Color("e8c547"), 11)
	note.text = "MUSIC"
	_music_clip = Control.new()
	_music_clip.clip_contents = true
	_music_clip.custom_minimum_size = Vector2(96, 22)
	_music_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(_music_clip)
	_music_ticker = Label.new()
	_music_ticker.add_theme_font_size_override("font_size", 14)
	_music_ticker.add_theme_color_override("font_color", Color("e9e6dc"))
	_music_clip.add_child(_music_ticker)
	_music_button(row, "<<", func() -> void: _music.call("previous_track"))
	_music_play = _music_button(row, "||", func() -> void: _music.call("toggle_pause"))
	_music_button(row, ">>", func() -> void: _music.call("next_track"))
	_music_button(row, "List", _toggle_track_list)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.value = float(_music.get("volume"))
	slider.custom_minimum_size = Vector2(46, 18)
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.focus_mode = Control.FOCUS_NONE
	slider.value_changed.connect(func(v: float) -> void:
		_music.call("set_volume", v)
		Settings.music = v
		Settings.save_settings())
	row.add_child(slider)
	# The track list drops down under the player.
	_music_list = PanelContainer.new()
	_music_list.add_theme_stylebox_override("panel", style.duplicate())
	add_child(_music_list)
	_music_list.anchor_left = 1.0
	_music_list.anchor_right = 1.0
	_music_list.offset_left = -380.0
	_music_list.offset_right = -16.0
	_music_list.offset_top = 56.0
	var list := VBoxContainer.new()
	_music_list.add_child(list)
	var names: Array = _music.call("track_names")
	for i in names.size():
		var b := Button.new()
		b.text = String(names[i])
		b.flat = true
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(_pick_track.bind(i))
		list.add_child(b)
	_music_list.visible = false


func _music_button(parent: Control, text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(24, 22)
	b.add_theme_font_size_override("font_size", 12)
	b.pressed.connect(action)
	parent.add_child(b)
	return b


func _toggle_track_list() -> void:
	_music_list.visible = not _music_list.visible


func _pick_track(index: int) -> void:
	_music.call("play_track", index)
	_music_list.visible = false


func _update_music_player(delta: float) -> void:
	if _music == null or _music_ticker == null:
		return
	_music_play.text = ">" if bool(_music.get("paused")) else "||"
	var title := String(_music.call("track_title"))
	var font := _music_ticker.get_theme_font("font")
	var title_w := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
	var box_w := _music_clip.size.x
	if title_w <= box_w:
		_music_ticker.text = title
		_music_ticker.position.x = 0.0
		return
	# Too long to fit: scroll it like a ticker, looping seamlessly.
	var gap := "      "
	var looped := title + gap + title
	if _music_ticker.text != looped:
		_music_ticker.text = looped
		_ticker_x = 0.0
	var loop_w := font.get_string_size(title + gap, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
	_ticker_x = fmod(_ticker_x + delta * 30.0, loop_w)
	_music_ticker.position.x = -_ticker_x


## Text under the reticle (e.g. "MAG" while Alt is held). Empty hides it.
func show_reticle_label(text: String) -> void:
	if _reticle_label == null:
		_reticle_label = Label.new()
		_reticle_label.add_theme_font_size_override("font_size", 16)
		_reticle_label.add_theme_color_override("font_color", Color("b8e4ff"))
		_reticle_label.add_theme_color_override("font_outline_color", Color("0b0e14"))
		_reticle_label.add_theme_constant_override("outline_size", 5)
		_reticle_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_reticle_label)
	_reticle_label.text = text
	_reticle_label.visible = text != ""


func _on_node_added(node: Node) -> void:
	var button := node as BaseButton
	if button == null or not is_ancestor_of(button):
		return
	button.pressed.connect(func() -> void: Sfx.ui("click", -2.0))
	button.mouse_entered.connect(func() -> void: Sfx.ui("hover", -8.0))


## A quick blue-white flash that hides the cut between the system view and the warp.
func warp_fade(fade_in: float, fade_out: float) -> void:
	if _fade == null:
		_fade = ColorRect.new()
		_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_fade.color = Color(0.75, 0.88, 1.0, 0.0)
		add_child(_fade)
		_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", 0.85, fade_in).set_ease(Tween.EASE_IN)
	tween.tween_property(_fade, "color:a", 0.0, fade_out).set_ease(Tween.EASE_OUT)


func _make_reward_slot(tile: PanelContainer, clickable: bool = true) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.25, 0.2, 0.05, 0.9)
	style.border_color = Color("e8c547")
	style.set_border_width_all(3)
	style.set_corner_radius_all(4)
	style.shadow_color = Color(0.91, 0.77, 0.28, 0.5)
	style.shadow_size = 10
	tile.add_theme_stylebox_override("panel", style)
	var box := tile.get_child(0) as VBoxContainer
	var icon := box.get_child(0) as Label
	icon.text = "+"
	icon.add_theme_color_override("font_color", Color("e8c547"))
	var name_label := box.get_child(1) as Label
	name_label.text = "Choose a building"
	name_label.add_theme_color_override("font_color", Color("f4e3a0"))
	if clickable:
		tile.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		tile.mouse_filter = Control.MOUSE_FILTER_STOP
		tile.gui_input.connect(_on_reward_slot_input)
	var pulse := tile.create_tween().set_loops()
	pulse.tween_property(tile, "modulate", Color(1.15, 1.1, 0.9), 0.6)
	pulse.tween_property(tile, "modulate", Color.WHITE, 0.6)


func _on_reward_slot_input(event: InputEvent) -> void:
	var press := event as InputEventMouseButton
	if press != null and press.pressed and press.button_index == MOUSE_BUTTON_LEFT:
		Sfx.ui("click")
		reward_slot_clicked.emit(_planet)


## Tooltips: a dark panel so they read clearly.
func _tooltip_theme() -> Theme:
	var t := Theme.new()
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(0.02, 0.03, 0.05, 0.97)
	panel.border_color = Color("3a4a5a")
	panel.set_border_width_all(1)
	panel.set_corner_radius_all(4)
	panel.content_margin_left = 10
	panel.content_margin_right = 10
	panel.content_margin_top = 8
	panel.content_margin_bottom = 8
	t.set_stylebox("panel", "TooltipPanel", panel)
	return t


## A label whose tooltip is rich text, so key words can be bold.
class TipLabel extends Label:
	func _make_custom_tooltip(for_text: String) -> Object:
		var text := RichTextLabel.new()
		text.bbcode_enabled = true
		text.fit_content = true
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text.custom_minimum_size = Vector2(340, 0)
		text.add_theme_font_size_override("normal_font_size", 16)
		text.add_theme_font_size_override("bold_font_size", 16)
		text.add_theme_color_override("default_color", Color("e9e6dc"))
		text.text = for_text
		return text



# --- economy guide ---------------------------------------------------------------------

## The start-of-run guide: page 1 is the gameplay loop in three pictures,
## page 2 is how the economy flows.
func show_economy_guide() -> void:
	if _card_layer != null:
		_card_layer.queue_free()
	_card_layer = ColorRect.new()
	(_card_layer as ColorRect).color = Color(0.02, 0.03, 0.05, 0.85)
	add_child(_card_layer)
	_card_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_card_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	var centre := CenterContainer.new()
	_card_layer.add_child(centre)
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	var style := _guide_shell_style()
	panel.add_theme_stylebox_override("panel", style)
	centre.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 38)
	panel.add_child(column)
	var heading := _make_label(column, Color("e8c547"), 34)
	heading.text = "HOW A RUN WORKS"
	_label_shadow(heading, 3)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 0)
	column.add_child(row)
	var steps := [
		["1. FLY AND FIGHT", "Move your fleet with WASD and hold Left Click to aim. Destroy enemies for XP: every full bar gives you a Fleet card."],
		["2. BUILD AND EXPAND", "Press B to place Starbases on asteroids and Shipyards for new ships. To colonize, fly the Kharkiv into the rocket button above an empty planet."],
		["3. GROW AND CONQUER", "Your planets grow pops and earn Growth Rewards. Survive the Rebel waves, destroy their base, then take Mars to win."],
	]
	for i in steps.size():
		_guide_step(row, i, String(steps[i][0]), String(steps[i][1]))
		if i < steps.size() - 1:
			var arrow := _make_label(row, Color("e8c547"), 44)
			arrow.text = ">"
			arrow.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
			arrow.custom_minimum_size = Vector2(88, 280)
			arrow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			_label_shadow(arrow)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_child(buttons)
	var next := Button.new()
	next.text = "   NEXT: IMPORTANT HOTKEYS   "
	next.focus_mode = Control.FOCUS_NONE
	next.add_theme_font_size_override("font_size", 22)
	_gold_frame(next)
	buttons.add_child(next)
	next.pressed.connect(func() -> void:
		Sfx.ui("card_pick")
		_show_hotkeys_page())
	Sfx.ui("card_appear")


## The death report: damage the flagship took in its last 10 seconds, weapon by weapon,
## laid out like the WEAPONS block on the ship cards (count, name, where from, damage).
func _death_panel(death: Dictionary) -> Control:
	var panel := PanelContainer.new()
	var style := _guide_shell_style()
	style.bg_color = Color(0.14, 0.18, 0.23, 0.97)
	style.border_width_top = 4
	style.border_color = Color("b89a4a")
	style.content_margin_left = 28
	style.content_margin_right = 28
	style.content_margin_top = 28
	style.content_margin_bottom = 28
	panel.add_theme_stylebox_override("panel", style)
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	panel.add_child(column)
	var head := _make_label(column, Color("e5484d"), 24)
	head.text = "LAST 10 SECONDS"
	_label_shadow(head, 2)
	var sum := _make_label(column, Color("f4efe2"), 18)
	sum.text = "The Kharkiv took %s damage" % _thousands(int(float(death["total"])))
	var tray := PanelContainer.new()
	var inset := StyleBoxFlat.new()
	inset.bg_color = Color(0.06, 0.08, 0.11, 0.9)
	inset.border_color = Color(0, 0, 0, 0.7)
	inset.border_width_top = 3
	inset.set_corner_radius_all(6)
	inset.content_margin_left = 14
	inset.content_margin_right = 14
	inset.content_margin_top = 8
	inset.content_margin_bottom = 10
	tray.add_theme_stylebox_override("panel", inset)
	column.add_child(tray)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 8)
	tray.add_child(rows)
	var cap := _make_label(rows, Color("8a939c"), 12)
	cap.text = "WEAPONS   ·   DAMAGE TAKEN"
	for e in Array(death["rows"]).slice(0, 6):
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		row.custom_minimum_size = Vector2(380, 0)
		rows.add_child(row)
		var count := _make_label(row, Color("f0c35a"), 17)
		count.text = "%dx" % int(e[1])
		count.custom_minimum_size = Vector2(40, 0)
		count.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		var name_box := VBoxContainer.new()
		name_box.add_theme_constant_override("separation", 0)
		name_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_box)
		var wname := _make_label(name_box, Color("f4efe2"), 17)
		wname.text = String(e[0])
		var who := _make_label(name_box, Color("93a3ad"), 12)
		who.text = String(e[3])
		var dealt := _make_label(row, Color("e5484d"), 17)
		dealt.text = _thousands(int(float(e[2])))
		dealt.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	return panel


## A gold-framed button like Xander's GOT IT: dark fill, gold border and gold text,
## brighter on hover (v0.9.166).
func _gold_frame(b: Button) -> void:
	var st := StyleBoxFlat.new()
	st.bg_color = Color("1a1408")
	st.border_color = Color("c9a55a")
	st.set_border_width_all(2)
	st.set_corner_radius_all(4)
	st.content_margin_left = 18
	st.content_margin_right = 18
	st.content_margin_top = 8
	st.content_margin_bottom = 8
	var hv := st.duplicate() as StyleBoxFlat
	hv.bg_color = Color("2a2414")
	hv.border_color = Color("f0d27a")
	hv.shadow_color = Color(0.94, 0.82, 0.48, 0.25)
	hv.shadow_size = 8
	b.add_theme_stylebox_override("normal", st)
	b.add_theme_stylebox_override("hover", hv)
	b.add_theme_stylebox_override("pressed", hv)
	b.add_theme_color_override("font_color", Color("f0d27a"))
	b.add_theme_color_override("font_hover_color", Color("fff1c2"))
	b.add_theme_color_override("font_pressed_color", Color("fff1c2"))


## The guide's outer panel: gold border, rounded corners and a soft drop shadow.
func _guide_shell_style() -> StyleBoxFlat:
	var style := _panel_style()
	style.set_border_width_all(2)
	style.border_color = Color("b89a4a")
	style.set_corner_radius_all(10)
	style.content_margin_left = 60
	style.content_margin_right = 60
	style.content_margin_top = 42
	style.content_margin_bottom = 42
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.6)
	style.shadow_size = 28
	style.shadow_offset = Vector2(0, 10)
	return style


## One step of the guide as its own raised card: a framed picture, then the title
## and the text with a bit of room to breathe.
func _guide_step(row: HBoxContainer, kind: int, title_text: String, body_text: String) -> void:
	var card := PanelContainer.new()
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.075, 0.105, 0.14, 0.95)
	card_style.border_color = Color(0.32, 0.38, 0.46, 0.55)
	card_style.border_width_top = 1
	card_style.border_width_left = 1
	card_style.border_width_right = 1
	card_style.border_width_bottom = 3
	card_style.set_corner_radius_all(10)
	card_style.content_margin_left = 24
	card_style.content_margin_right = 24
	card_style.content_margin_top = 24
	card_style.content_margin_bottom = 30
	card_style.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
	card_style.shadow_size = 12
	card_style.shadow_offset = Vector2(0, 6)
	card.add_theme_stylebox_override("panel", card_style)
	card.size_flags_vertical = Control.SIZE_FILL
	row.add_child(card)
	var step := VBoxContainer.new()
	step.add_theme_constant_override("separation", 20)
	card.add_child(step)
	# The picture sits in a dark, inset frame.
	var frame := PanelContainer.new()
	var frame_style := StyleBoxFlat.new()
	frame_style.bg_color = Color("0a1020")
	frame_style.border_color = Color(0.0, 0.0, 0.0, 0.7)
	frame_style.border_width_top = 3
	frame_style.border_width_left = 2
	frame_style.border_width_right = 1
	frame_style.border_width_bottom = 1
	frame_style.set_corner_radius_all(6)
	frame_style.set_content_margin_all(2)
	frame.add_theme_stylebox_override("panel", frame_style)
	step.add_child(frame)
	var picture := LoopPicture.new()
	picture.kind = kind
	picture.custom_minimum_size = Vector2(340, 220)
	frame.add_child(picture)
	var title := _make_label(step, Color("f4efe2"), 22)
	title.text = title_text
	_label_shadow(title)
	var body := _make_label(step, Color("c9ced6"), 16)
	body.text = body_text
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size = Vector2(344, 0)
	body.add_theme_constant_override("line_spacing", 9)


## A small dark drop shadow under a label, so it lifts off the panel.
func _label_shadow(label: Label, offset: int = 2) -> void:
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.65))
	label.add_theme_constant_override("shadow_offset_x", 0)
	label.add_theme_constant_override("shadow_offset_y", offset)


## Page 2 of the guide: the three hotkeys worth knowing from the start.
func _show_hotkeys_page() -> void:
	if _card_layer != null:
		_card_layer.queue_free()
	_card_layer = ColorRect.new()
	(_card_layer as ColorRect).color = Color(0.02, 0.03, 0.05, 0.85)
	add_child(_card_layer)
	_card_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_card_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	var centre := CenterContainer.new()
	_card_layer.add_child(centre)
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	var style := _guide_shell_style()
	panel.add_theme_stylebox_override("panel", style)
	centre.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 38)
	panel.add_child(column)
	var heading := _make_label(column, Color("e8c547"), 34)
	heading.text = "IMPORTANT HOTKEYS"
	_label_shadow(heading, 3)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 64)
	column.add_child(row)
	var keys := [
		["HOLD SPACE: INFO", "Shows every ship's full name and weapon ranges, and more detail on planets and stations. Use it any time you're not sure what you're looking at."],
		["F: FLEET MODE", "Takes direct control of your fleet: fly with WASD, hold Left Click to aim. Press F again to free the camera and look around."],
		["HOLD RIGHT CLICK: SEND SHIPS", "Your escort ships fly to the cursor and fight there. Let go and they fly back into formation."],
	]
	for i in keys.size():
		_guide_step(row, 3 + i, String(keys[i][0]), String(keys[i][1]))
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 48)
	column.add_child(buttons)
	var skip := CheckBox.new()
	skip.text = "  Don't show this at the start"
	skip.focus_mode = Control.FOCUS_NONE
	_style_big_checkbox(skip)
	buttons.add_child(skip)
	var ok := Button.new()
	ok.text = "   GOT IT   "
	ok.focus_mode = Control.FOCUS_NONE
	ok.add_theme_font_size_override("font_size", 22)
	_gold_frame(ok)
	buttons.add_child(ok)
	ok.pressed.connect(func() -> void:
		if skip.button_pressed:
			var config := ConfigFile.new()
			config.load("user://settings.cfg")
			config.set_value("guide", "hide_v2", true)
			config.save("user://settings.cfg")
		Sfx.ui("card_pick")
		_card_layer.queue_free()
		_card_layer = null
		guide_closed.emit())
	Sfx.ui("card_appear")


## (Not shown any more: the old economy page, kept for reference.)
## Page 2 of the guide: how the economy flows, in boxes and arrows.
func _show_economy_page() -> void:
	if _card_layer != null:
		_card_layer.queue_free()
	_card_layer = ColorRect.new()
	(_card_layer as ColorRect).color = Color(0.02, 0.03, 0.05, 0.85)
	add_child(_card_layer)
	_card_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_card_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	var centre := CenterContainer.new()
	_card_layer.add_child(centre)
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	var style := _panel_style()
	style.set_border_width_all(2)
	style.border_color = Color("b89a4a")
	style.content_margin_left = 30
	style.content_margin_right = 30
	style.content_margin_top = 22
	style.content_margin_bottom = 22
	panel.add_theme_stylebox_override("panel", style)
	centre.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	panel.add_child(column)
	var heading := _make_label(column, Color("e8c547"), 34)
	heading.text = "HOW YOUR ECONOMY WORKS"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var graphic := EconomyGraphic.new()
	graphic.custom_minimum_size = Vector2(1060, 500)
	column.add_child(graphic)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 30)
	column.add_child(row)
	var skip := CheckBox.new()
	skip.text = "  Don't show this at the start"
	skip.focus_mode = Control.FOCUS_NONE
	_style_big_checkbox(skip)
	row.add_child(skip)
	var ok := Button.new()
	ok.text = "   GOT IT   "
	ok.focus_mode = Control.FOCUS_NONE
	ok.add_theme_font_size_override("font_size", 22)
	_gold_frame(ok)
	row.add_child(ok)
	ok.pressed.connect(func() -> void:
		if skip.button_pressed:
			var config := ConfigFile.new()
			config.load("user://settings.cfg")
			config.set_value("guide", "hide_v2", true)
			config.save("user://settings.cfg")
		Sfx.ui("card_pick")
		_card_layer.queue_free()
		_card_layer = null
		guide_closed.emit())
	Sfx.ui("card_appear")


## A large, high-contrast checkbox: a 26 px box with a bright border, gold when
## ticked, on a slightly lit plate so it stands out from the panel.
func _style_big_checkbox(box: CheckBox) -> void:
	box.add_theme_font_size_override("font_size", 19)
	box.add_theme_color_override("font_color", Color("f4efe2"))
	box.add_theme_color_override("font_hover_color", Color.WHITE)
	box.add_theme_color_override("font_pressed_color", Color("f0d27a"))
	box.add_theme_icon_override("unchecked", _checkbox_icon(false))
	box.add_theme_icon_override("checked", _checkbox_icon(true))
	var plate := StyleBoxFlat.new()
	plate.bg_color = Color(1, 1, 1, 0.06)
	plate.border_color = Color(1, 1, 1, 0.18)
	plate.set_border_width_all(1)
	plate.set_corner_radius_all(6)
	plate.content_margin_left = 10
	plate.content_margin_right = 14
	plate.content_margin_top = 6
	plate.content_margin_bottom = 6
	var hover := plate.duplicate() as StyleBoxFlat
	hover.bg_color = Color(1, 1, 1, 0.12)
	hover.border_color = Color("e8c547")
	box.add_theme_stylebox_override("normal", plate)
	box.add_theme_stylebox_override("hover", hover)
	box.add_theme_stylebox_override("pressed", plate)
	box.add_theme_stylebox_override("hover_pressed", hover)


func _checkbox_icon(ticked: bool) -> ImageTexture:
	var n := 26
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var border := Color("f4efe2")
	var fill := Color("e8c547") if ticked else Color(0.05, 0.07, 0.1)
	for y in n:
		for x in n:
			var edge := x < 3 or y < 3 or x >= n - 3 or y >= n - 3
			img.set_pixel(x, y, border if edge else fill)
	if ticked:
		# A thick dark tick.
		for i in 7:
			for t in 3:
				img.set_pixel(6 + i, 12 + i - t, Color("0b0e14"))
		for i in 10:
			for t in 3:
				img.set_pixel(12 + i, 18 - i - t, Color("0b0e14"))
	return ImageTexture.create_from_image(img)


static func guide_hidden() -> bool:
	var config := ConfigFile.new()
	if config.load("user://settings.cfg") != OK:
		return false
	if not Settings.noob_mode:
		return true   # no tutorial outside Noob Mode
	return bool(config.get_value("guide", "hide_v2", false))


## The boxes-and-arrows drawing on the economy guide.
class EconomyGraphic extends Control:
	const ResIconScript = preload("res://scripts/res_icon.gd")
	const ROWS := [
		["EARN", "3dd17a", ["PLANETS", "{credits} + {alloys}\nevery day (10 s)"]],
		["", "3dd17a", ["ASTEROIDS\ninside a Starbase orbit", "HAULERS\ncarry them home", "{alloys} + {gas}"]],
		["GROW", "e8c547", ["PLANETS GROW POPS", "GROWTH REWARD\npick a building"]],
		["", "e8c547", ["TECH LABS\non your planets", "TECH", "TECH CARDS"]],
		["FIGHT", "e5484d", ["DESTROY ENEMIES", "XP", "FLEET CARDS\nstronger fleet"]],
		["SPEND", "8fb4e3", ["{alloys}  {gas}", "STATIONS + SHIPS\nbuild menu  [B]"]],
		["", "8fb4e3", ["{credits}", "COLONY SHIPS  [C]\n+ Arms Dealer cards"]],
	]

	func _draw() -> void:
		var font := ThemeDB.fallback_font
		var row_h := 56.0
		var gap := 14.0
		var left := 130.0
		var arrow := 54.0
		var width := size.x - left
		for r in ROWS.size():
			var data: Array = ROWS[r]
			var colour := Color(String(data[1]))
			var y := r * (row_h + gap)
			if String(data[0]) != "":
				draw_string(font, Vector2(0, y + row_h * 0.5 + 9), String(data[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, 24, colour)
			var boxes: Array = data[2]
			var n := boxes.size()
			var box_w := minf(300.0, (width - (n - 1) * arrow) / n)
			for i in n:
				var x := left + i * (box_w + arrow)
				var rect := Rect2(Vector2(x, y), Vector2(box_w, row_h))
				var box := StyleBoxFlat.new()
				box.bg_color = Color(colour, 0.12)
				box.border_color = Color(colour, 0.8)
				box.set_border_width_all(2)
				box.set_corner_radius_all(8)
				draw_style_box(box, rect)
				var lines := String(boxes[i]).split("\n")
				for l in lines.size():
					var big := l == 0
					var fs := 18 if big else 14
					var text := lines[l]
					var tw := ResIconScript.text_width(font, text, fs)
					var ty := y + row_h * 0.5 + (6.0 if lines.size() == 1 else (-4.0 if big else 16.0))
					ResIconScript.draw_text(self, font, Vector2(x + (box_w - tw) * 0.5, ty), text, fs, Color("f4efe2") if big else Color("c9ced6"), 0)
				if i < n - 1:
					var ax := x + box_w + 8.0
					var ay := y + row_h * 0.5
					draw_line(Vector2(ax, ay), Vector2(ax + arrow - 18.0, ay), colour, 3.0)
					draw_colored_polygon(PackedVector2Array([Vector2(ax + arrow - 16.0, ay), Vector2(ax + arrow - 26.0, ay - 7.0), Vector2(ax + arrow - 26.0, ay + 7.0)]), colour)



## A small animated picture for the gameplay-loop guide: 0 fight, 1 build, 2 grow and win.
class LoopPicture extends Control:
	var kind := 0
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _ship(nose: Vector2, length: float, width: float, facing: float, body: Color, trim: Color) -> void:
		var dir := Vector2.RIGHT.rotated(facing)
		var side := dir.orthogonal()
		var pts := PackedVector2Array([nose, nose - dir * length * 0.66 + side * width, nose - dir * length + side * width, nose - dir * length * 0.85, nose - dir * length - side * width, nose - dir * length * 0.66 - side * width])
		draw_colored_polygon(pts, body)
		var outline := pts.duplicate()
		outline.append(pts[0])
		draw_polyline(outline, Color("0b0e14"), 2.0)
		draw_line(nose - dir * length * 0.5, nose - dir * length * 0.92, trim, 3.0)

	func _text(at: Vector2, text: String, size: int, colour: Color) -> void:
		# "{alloys}" and friends draw as resource icons.
		var font := ThemeDB.fallback_font
		var w: float = preload("res://scripts/res_icon.gd").text_width(font, text, size)
		preload("res://scripts/res_icon.gd").draw_text(self, font, at - Vector2(w / 2.0, 0), text, size, colour, 4)

	func _dashed(c: Vector2, r: float, colour: Color) -> void:
		for i in 32:
			if i % 2 == 0:
				var a := TAU * i / 32.0 + _t * 0.3
				draw_arc(c, r, a, a + TAU / 32.0, 4, colour, 2.0)

	func _draw() -> void:
		var box := Rect2(Vector2.ZERO, size)
		draw_rect(box, Color("0a1020"))
		for i in 30:
			var p := Vector2(fmod(i * 97.0, size.x), fmod(i * 53.0 + i * i, size.y))
			draw_rect(Rect2(p, Vector2(2, 2)), Color(0.86, 0.91, 1.0, 0.4))
		match kind:
			0:
				_draw_fight()
			1:
				_draw_build()
			2:
				_draw_grow()
			3:
				_draw_space_key()
			4:
				_draw_f_key()
			5:
				_draw_right_click()
		draw_rect(box, Color("3a4a5a"), false, 2.0)

	func _draw_fight() -> void:
		var bob := sin(_t * 2.0) * 4.0
		# Your fleet: the Kharkiv with Corvettes out front.
		var k := Vector2(90, 110 + bob)
		draw_rect(Rect2(k - Vector2(36, 14), Vector2(60, 28)), Color("5b6675"))
		draw_rect(Rect2(k - Vector2(36, 14), Vector2(60, 28)), Color("0b0e14"), false, 2.0)
		draw_rect(Rect2(k - Vector2(32, 2), Vector2(52, 4)), Color("3e6fb0"))
		for c in [Vector2(140, 80), Vector2(150, 112), Vector2(140, 144)]:
			_ship(c + Vector2(0, bob), 26.0, 7.0, 0.0, Color("2c3642"), Color("3e6fb0"))
		# Tracers flying right.
		for i in 6:
			var d := fmod(_t * 160.0 + i * 30.0, 120.0)
			var y := 80.0 + (i % 3) * 32.0 + bob
			draw_line(Vector2(150 + d, y), Vector2(162 + d, y), Color(0.94, 0.75, 0.38, 1.0 - d / 120.0), 3.0)
		# Enemies; one keeps exploding and coming back.
		var cycle := fmod(_t, 2.4)
		for e in [Vector2(270, 72), Vector2(290, 150)]:
			_ship(e, 26.0, 7.0, PI, Color("a2402f"), Color("d0703a"))
		var target := Vector2(280, 112)
		if cycle < 1.6:
			_ship(target, 26.0, 7.0, PI, Color("a2402f"), Color("d0703a"))
		else:
			var blast := (cycle - 1.6) / 0.8
			draw_circle(target, 6.0 + 18.0 * blast, Color(1.0, 0.6, 0.2, 1.0 - blast))
			_text(target + Vector2(0, -20 - 20 * blast), "+1 XP", 16, Color("e8c547"))
		# XP bar filling up.
		var fill := fmod(_t * 0.25, 1.0)
		draw_rect(Rect2(Vector2(20, 196), Vector2(300, 8)), Color(0.02, 0.03, 0.05, 0.9))
		draw_rect(Rect2(Vector2(20, 196), Vector2(300 * fill, 8)), Color("e8c547"))
		_text(Vector2(170, 190), "XP", 13, Color("e8c547"))
		# WASD keys.
		for kk in [["W", Vector2(40, 22)], ["A", Vector2(18, 44)], ["S", Vector2(40, 44)], ["D", Vector2(62, 44)]]:
			var at: Vector2 = kk[1]
			draw_rect(Rect2(at, Vector2(20, 20)), Color("2c3642"))
			draw_rect(Rect2(at, Vector2(20, 20)), Color("8fb4e3"), false, 1.0)
			_text(at + Vector2(10, 15), String(kk[0]), 13, Color("e9e6dc"))

	func _draw_build() -> void:
		# Starbase with its collection ring around a few asteroids.
		var sb := Vector2(240, 95)
		_dashed(sb, 62.0, Color(0.3, 0.55, 1.0, 0.8))
		for r in [Vector2(205, 70), Vector2(270, 60), Vector2(280, 125), Vector2(215, 135), Vector2(250, 150)]:
			draw_circle(r, 8.0, Color("8e8478"))
			draw_circle(r + Vector2(2, -2), 2.0, Color("c79bff"))
		# The Starbase: armoured ring on spokes around a lit core, solar wings either side.
		for side: float in [-1.0, 1.0]:
			draw_line(sb + Vector2(side * 16, 0), sb + Vector2(side * 22, 0), Color("4a535d"), 3.0)
			draw_rect(Rect2(sb + Vector2(side * 22 - (0.0 if side > 0.0 else 10.0), -7), Vector2(10, 14)), Color("1d3550"))
			draw_rect(Rect2(sb + Vector2(side * 22 - (0.0 if side > 0.0 else 10.0), -7), Vector2(10, 14)), Color("0b0e14"), false, 1.0)
		for i: int in 4:
			var dir := Vector2.RIGHT.rotated(PI * 0.25 + i * PI * 0.5)
			draw_line(sb + dir * 6.0, sb + dir * 13.0, Color("4a535d"), 3.0)
		draw_arc(sb, 14.0, 0.0, TAU, 32, Color("0b0e14"), 6.0)
		draw_arc(sb, 14.0, 0.0, TAU, 32, Color("8e98a3"), 4.0)
		draw_circle(sb, 7.0, Color("c3cad1"))
		draw_circle(sb, 4.0, Color("3e6fb0"))
		# Your planet on the left.
		var planet := Vector2(50, 120)
		draw_circle(planet, 34.0, Color("2f6fb4"))
		draw_circle(planet + Vector2(-8, -8), 12.0, Color("4f8a3a"))
		# A Hauler with containers flying home.
		var t := fmod(_t * 0.4, 1.0)
		var hauler := sb.lerp(planet + Vector2(40, 0), t) + Vector2(0, 30)
		draw_rect(Rect2(hauler - Vector2(7, 5), Vector2(14, 10)), Color("d9a441"))
		for i in 3:
			draw_rect(Rect2(hauler + Vector2(12 + i * 14, -5), Vector2(10, 10)), Color("aeb9c6"))
		if t > 0.85:
			_text(planet + Vector2(0, -44), "+3 {alloys}", 15, Color("3dd17a"))
		# The B key, along the bottom.
		var key_at := Vector2(18, 180)
		draw_rect(Rect2(key_at, Vector2(22, 22)), Color("2c3642"))
		draw_rect(Rect2(key_at, Vector2(22, 22)), Color("8fb4e3"), false, 1.0)
		_text(key_at + Vector2(11, 16), "B", 14, Color("e9e6dc"))
		draw_string(ThemeDB.fallback_font, key_at + Vector2(30, 16), "Build", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("c9ced6"))
		# An empty planet with the in-game colonize button above it, and the Kharkiv
		# flying into the button.
		var empty := Vector2(120, 92)
		# A living world waiting for settlers: ocean, green continents, cloud and a thin atmosphere.
		draw_circle(empty, 19.0, Color(0.45, 0.75, 1.0, 0.18))
		draw_circle(empty, 16.0, Color("2a78b8"))
		draw_circle(empty + Vector2(-5, -4), 6.5, Color("4f9a48"))
		draw_circle(empty + Vector2(6, 5), 5.0, Color("5aa651"))
		draw_circle(empty + Vector2(2, -9), 3.0, Color("4f9a48"))
		draw_arc(empty + Vector2(-2, 2), 9.0, -0.6, 1.0, 10, Color(1.0, 1.0, 1.0, 0.55), 2.0)
		draw_arc(empty + Vector2(3, -3), 12.0, 2.4, 3.4, 8, Color(1.0, 1.0, 1.0, 0.45), 2.0)
		draw_circle(empty + Vector2(5, 5), 12.0, Color(0.02, 0.03, 0.05, 0.25))
		draw_arc(empty, 16.0, 0.0, TAU, 32, Color("0b0e14"), 2.0)
		var button := empty + Vector2(0, -50)
		_rocket_button(button, 16.0)
		draw_string(ThemeDB.fallback_font, button + Vector2(22, 5), "Colonize", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("3dd17a"))
		var fly := fmod(_t * 0.35, 1.0)
		var kh := Vector2(30, 30).lerp(button + Vector2(-6, 0), minf(fly * 1.25, 1.0))
		draw_rect(Rect2(kh - Vector2(12, 5), Vector2(20, 10)), Color("5b6675"))
		draw_rect(Rect2(kh - Vector2(12, 5), Vector2(20, 10)), Color("0b0e14"), false, 1.5)
		draw_rect(Rect2(kh - Vector2(10, 1), Vector2(16, 2)), Color("3e6fb0"))

	## The rocket-landing button that floats over planets you can colonize (as in-game).
	func _rocket_button(c: Vector2, r: float) -> void:
		var k := r / 26.0
		var breathe := 1.0 + 0.06 * sin(_t * 2.4)
		draw_circle(c, r * 1.3 * breathe, Color(0.24, 0.82, 0.48, 0.16 + 0.08 * sin(_t * 2.4)))
		draw_circle(c, r * breathe, Color("2f8f57"))
		draw_arc(c, r * breathe, 0.0, TAU, 32, Color("0b0e14"), 2.0)
		var ink := Color("e9e6dc")
		draw_arc(c + Vector2(0, r * 1.55), r * 1.05, -PI * 0.78, -PI * 0.22, 20, ink, 2.0)
		draw_rect(Rect2(c + Vector2(-3.5, -12.0) * k, Vector2(7.0, 14.0) * k), ink)
		draw_colored_polygon(PackedVector2Array([c + Vector2(-3.5, -12.0) * k, c + Vector2(3.5, -12.0) * k, c + Vector2(0, -18.0) * k]), ink)
		draw_colored_polygon(PackedVector2Array([c + Vector2(-3.5, -1.0) * k, c + Vector2(-7.5, 3.0) * k, c + Vector2(-3.5, 2.0) * k]), ink)
		draw_colored_polygon(PackedVector2Array([c + Vector2(3.5, -1.0) * k, c + Vector2(7.5, 3.0) * k, c + Vector2(3.5, 2.0) * k]), ink)
		var flame := 4.0 + 2.0 * sin(_t * 18.0)
		draw_colored_polygon(PackedVector2Array([c + Vector2(-2.5, 2.0) * k, c + Vector2(2.5, 2.0) * k, c + Vector2(0, 2.0 + flame) * k]), Color("f08a2a"))

	func _draw_grow() -> void:
		# Your planet growing pops, with a Growth Reward bubble.
		var planet := Vector2(80, 95)
		draw_circle(planet, 40.0, Color("2f6fb4"))
		draw_circle(planet + Vector2(-10, -10), 14.0, Color("4f8a3a"))
		var pops := 1 + int(fmod(_t * 1.2, 5.0))
		for i in pops:
			var at := planet + Vector2(-40 + i * 20, 56)
			draw_circle(at + Vector2(0, -5), 4.0, Color("3dd17a"))
			draw_rect(Rect2(at + Vector2(-5, 0), Vector2(10, 6)), Color("3dd17a"))
		var pulse := 0.6 + 0.4 * sin(_t * 4.0)
		draw_circle(planet + Vector2(34, -38), 12.0, Color(0.91, 0.77, 0.28, pulse))
		_text(planet + Vector2(34, -33), "!", 16, Color("0b0e14"))
		# Mars under siege, with a target.
		var mars := Vector2(255, 100)
		draw_circle(mars, 42.0, Color("b5523b"))
		draw_circle(mars + Vector2(12, 10), 10.0, Color("8c3a2a"))
		draw_arc(mars, 54.0, 0.0, TAU, 32, Color(0.9, 0.28, 0.3, 0.8), 2.0)
		draw_line(mars + Vector2(-64, 0), mars + Vector2(-44, 0), Color("e5484d"), 2.0)
		draw_line(mars + Vector2(44, 0), mars + Vector2(64, 0), Color("e5484d"), 2.0)
		draw_line(mars + Vector2(0, -64), mars + Vector2(0, -44), Color("e5484d"), 2.0)
		# MAG slugs at Mars.
		var shot := fmod(_t * 0.8, 1.0)
		var from := Vector2(150, 190)
		var hit := from.lerp(mars + Vector2(-20, 30), shot)
		draw_line(hit - (mars - from).normalized() * 16.0, hit, Color(0.85, 0.93, 1.0, 0.9), 4.0)
		if shot > 0.9:
			draw_circle(mars + Vector2(-20, 30), 12.0, Color(1.0, 0.95, 0.77, 0.8))
		_text(Vector2(255, 200), "VICTORY", 18, Color(0.91, 0.77, 0.28, 0.5 + 0.5 * sin(_t * 2.0)))

	# --- hotkey pictures ---

	func _keycap(at: Vector2, text: String, w: float, pressed: bool) -> void:
		var drop := 3.0 if pressed else 0.0
		draw_rect(Rect2(at + Vector2(0, 5), Vector2(w, 34)), Color("1a2230"))
		var face := Rect2(at + Vector2(0, drop), Vector2(w, 34))
		draw_rect(face, Color("e8c547") if pressed else Color("2c3642"))
		draw_rect(face, Color("8fb4e3"), false, 1.5)
		_text(face.position + Vector2(w / 2.0, 23), text, 16, Color("0b0e14") if pressed else Color("e9e6dc"))

	func _mini_fleet(at: Vector2, heading: float) -> void:
		var k := at
		draw_rect(Rect2(k - Vector2(22, 9), Vector2(40, 18)), Color("5b6675"))
		draw_rect(Rect2(k - Vector2(22, 9), Vector2(40, 18)), Color("0b0e14"), false, 2.0)
		draw_rect(Rect2(k - Vector2(19, 1.5), Vector2(34, 3)), Color("3e6fb0"))
		for c in [Vector2(32, -20), Vector2(38, 0), Vector2(32, 20)]:
			_ship(k + c.rotated(heading), 16.0, 5.0, heading, Color("2c3642"), Color("3e6fb0"))

	## Hold SPACE: full names and weapon ranges appear.
	func _draw_space_key() -> void:
		var held := fmod(_t, 3.0) < 1.8
		var at := Vector2(170, 105)
		if held:
			draw_arc(at, 70.0, 0.0, TAU, 48, Color(0.3, 0.55, 1.0, 0.45), 2.0)
			draw_arc(at, 40.0, 0.0, TAU, 48, Color(0.3, 0.55, 1.0, 0.3), 2.0)
			_text(at + Vector2(0, -30), "Kharkiv", 13, Color("f4efe2"))
			_text(at + Vector2(72, -26), "Corvette", 11, Color("aeb9c6"))
			_text(Vector2(270, 60), "Rebel Raider", 11, Color("e5484d"))
		_mini_fleet(at, 0.0)
		_ship(Vector2(270, 75), 16.0, 5.0, PI, Color("a2402f"), Color("d0703a"))
		_keycap(Vector2(95, 168), "SPACE", 150.0, held)
		_text(Vector2(170, 20), "HOLD: names, ranges, info", 13, Color("8fb4e3"))

	## F: take the helm (Fleet Mode on and off).
	func _draw_f_key() -> void:
		var on := fmod(_t, 4.0) < 2.4
		var drift := Vector2(sin(_t * 1.3) * 40.0, cos(_t * 0.9) * 12.0) if on else Vector2.ZERO
		var at := Vector2(170, 100) + drift
		_mini_fleet(at, 0.0)
		if on:
			draw_rect(Rect2(Vector2(80, 14), Vector2(180, 24)), Color(0.91, 0.77, 0.28, 0.2))
			_text(Vector2(170, 32), "FLEET MODE", 15, Color("e8c547"))
			for kk in [["W", Vector2(26, 120)], ["A", Vector2(4, 146)], ["S", Vector2(26, 146)], ["D", Vector2(48, 146)]]:
				var p: Vector2 = kk[1]
				draw_rect(Rect2(p, Vector2(20, 20)), Color("2c3642"))
				draw_rect(Rect2(p, Vector2(20, 20)), Color("8fb4e3"), false, 1.0)
				_text(p + Vector2(10, 15), String(kk[0]), 12, Color("e9e6dc"))
		else:
			_text(Vector2(170, 32), "free camera", 14, Color("93a3ad"))
		_keycap(Vector2(150, 168), "F", 40.0, fmod(_t, 4.0) < 0.25 or absf(fmod(_t, 4.0) - 2.4) < 0.25)

	## Hold right click: your escorts fly out to the cursor and fight there.
	func _draw_right_click() -> void:
		var cycle := fmod(_t, 4.0)
		var held := cycle < 2.6
		var home := Vector2(80, 110)
		var reticle := Vector2(255, 80)
		draw_rect(Rect2(home - Vector2(22, 9), Vector2(40, 18)), Color("5b6675"))
		draw_rect(Rect2(home - Vector2(22, 9), Vector2(40, 18)), Color("0b0e14"), false, 2.0)
		var out := clampf(cycle / 1.2, 0.0, 1.0) if held else clampf(1.0 - (cycle - 2.6) / 1.2, 0.0, 1.0)
		for i in 3:
			var slot := home + Vector2(36, -20 + i * 20)
			var spot := reticle + Vector2(-18 + i * 18, 20 * sin(_t * 3.0 + i))
			_ship(slot.lerp(spot, out), 16.0, 5.0, 0.0 if held else PI, Color("2c3642"), Color("3e6fb0"))
		_ship(reticle + Vector2(30, 0), 16.0, 5.0, PI, Color("a2402f"), Color("d0703a"))
		if held:
			draw_arc(reticle, 14.0, 0.0, TAU, 24, Color("e8c547"), 2.0)
			draw_line(reticle - Vector2(20, 0), reticle - Vector2(8, 0), Color("e8c547"), 2.0)
			draw_line(reticle + Vector2(8, 0), reticle + Vector2(20, 0), Color("e8c547"), 2.0)
		# A mouse with the right button lit.
		var m := Vector2(150, 150)
		draw_rect(Rect2(m, Vector2(36, 52)), Color("2c3642"))
		draw_rect(Rect2(m, Vector2(36, 52)), Color("8fb4e3"), false, 1.5)
		draw_line(m + Vector2(18, 0), m + Vector2(18, 20), Color("8fb4e3"), 2.0)
		draw_line(m + Vector2(0, 20), m + Vector2(36, 20), Color("8fb4e3"), 2.0)
		if held:
			draw_rect(Rect2(m + Vector2(19, 1), Vector2(16, 18)), Color("e8c547"))


# --- pause menu (Esc) ---------------------------------------------------------------

## Esc: close the pause menu if it's open; otherwise open it, unless something else is
## open that Esc should close first (planet panel, build menu, a station being placed).
func _on_escape() -> void:
	if _collection_open:
		close_collection()
		get_viewport().set_input_as_handled()
		return
	if _pause_menu != null:
		if _pause_settings != null and _pause_settings.visible:
			_pause_settings.visible = false
		else:
			close_pause_menu()
		get_viewport().set_input_as_handled()
		return
	if _card_layer != null or _flying or _build_open or is_planet_open():
		return
	if pause_blocked.is_valid() and bool(pause_blocked.call()):
		return
	open_pause_menu()
	get_viewport().set_input_as_handled()


func open_pause_menu() -> void:
	if _pause_menu != null:
		return
	get_tree().paused = true
	Sfx.ui("blip")
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.05, 0.75)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pause_menu = dim
	var centre := CenterContainer.new()
	dim.add_child(centre)
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	centre.add_child(row)
	var panel := PanelContainer.new()
	var style := _panel_style()
	style.bg_color = Color(0.14, 0.18, 0.23, 0.97)   # lighter, so the checkboxes stand out
	style.set_border_width_all(2)
	style.border_width_top = 4
	style.border_color = Color("e8c547")
	style.content_margin_left = 32
	style.content_margin_right = 32
	style.content_margin_top = 26
	style.content_margin_bottom = 26
	panel.add_theme_stylebox_override("panel", style)
	panel.custom_minimum_size = Vector2(400, 0)
	row.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	panel.add_child(column)
	var title := _make_label(column, Color("e8c547"), 36)
	title.text = "PAUSED"
	_pause_button(column, "Resume", func() -> void: close_pause_menu())
	_pause_button(column, "Settings", func() -> void: _pause_settings.visible = not _pause_settings.visible)
	_pause_button(column, "Restart run", func() -> void:
		close_pause_menu()
		restart_requested.emit())
	_pause_button(column, "Main menu", func() -> void:
		close_pause_menu()
		menu_requested.emit())
	var hint := _make_label(column, Color("93a3ad"), 14)
	hint.text = "Esc to resume"
	# Settings, beside the menu.
	var settings_panel := PanelContainer.new()
	settings_panel.add_theme_stylebox_override("panel", style.duplicate())
	settings_panel.custom_minimum_size = Vector2(460, 0)
	settings_panel.visible = false
	row.add_child(settings_panel)
	_pause_settings = settings_panel
	var sc := VBoxContainer.new()
	sc.add_theme_constant_override("separation", 12)
	settings_panel.add_child(sc)
	var st := _make_label(sc, Color("e8c547"), 28)
	st.text = "SETTINGS"
	_pause_slider(sc, "Music", Settings.music, func(v: float) -> void:
		Settings.music = v
		if _music != null:
			_music.call("set_volume", v)
		Settings.apply()
		Settings.save_settings())
	_pause_slider(sc, "Sound effects", Settings.sfx, func(v: float) -> void:
		Settings.sfx = v
		Settings.apply()
		Settings.save_settings())
	_pause_check(sc, "Damage numbers", Settings.damage_numbers, func(on: bool) -> void:
		Settings.damage_numbers = on
		Settings.apply()
		Settings.save_settings())
	_pause_check(sc, "Abbreviated Ship Names", Settings.abbrev_names, func(on: bool) -> void:
		Settings.abbrev_names = on
		Settings.apply()
		Settings.save_settings())
	_pause_check(sc, "XP pop-ups on ships", Settings.xp_popups, func(on: bool) -> void:
		Settings.xp_popups = on
		Settings.save_settings())
	_pause_check(sc, "Fullscreen (F11)", Settings.fullscreen, func(on: bool) -> void:
		Settings.fullscreen = on
		Settings.apply()
		Settings.save_settings())
	# Noob Mode gets its own box at the bottom: the master switch in the header,
	# the parts it switches on inside.
	var noob_box := PanelContainer.new()
	var nbs := StyleBoxFlat.new()
	nbs.bg_color = Color(0.95, 0.76, 0.19, 0.07)
	nbs.border_color = Color("e8c547")
	nbs.set_border_width_all(2)
	nbs.border_width_top = 4
	nbs.set_corner_radius_all(8)
	nbs.content_margin_left = 18
	nbs.content_margin_right = 18
	nbs.content_margin_top = 10
	nbs.content_margin_bottom = 12
	noob_box.add_theme_stylebox_override("panel", nbs)
	sc.add_child(noob_box)
	var noob_col := VBoxContainer.new()
	noob_col.add_theme_constant_override("separation", 6)
	noob_box.add_child(noob_col)
	var noob_head := HBoxContainer.new()
	noob_col.add_child(noob_head)
	var noob_title := Label.new()
	noob_title.text = "NOOB MODE"
	noob_title.add_theme_font_size_override("font_size", 22)
	noob_title.add_theme_color_override("font_color", Color("e8c547"))
	noob_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	noob_head.add_child(noob_title)
	var noob_note := Label.new()
	noob_note.text = "Beginner help for new Commanders."
	noob_note.add_theme_font_size_override("font_size", 14)
	noob_note.add_theme_color_override("font_color", Color("a9b4c0"))
	noob_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	noob_note.custom_minimum_size = Vector2(360, 0)
	noob_col.add_child(noob_note)
	var noob_subs := VBoxContainer.new()
	noob_subs.add_theme_constant_override("separation", 2)
	noob_col.add_child(noob_subs)
	var noob := _pause_check(noob_head, "On", Settings.noob_mode, Callable())
	noob.tooltip_text = "Xander and the start-of-run tutorial"
	var cfg0 := ConfigFile.new()
	cfg0.load(Settings.PATH)
	var advisor := _pause_check(noob_subs, "Xander, Fleet Advisor", Settings.advisor_on, func(on: bool) -> void:
		Settings.advisor_on = on
		if on:
			Settings.advisor_dismissed = []   # turning him back on brings every warning back
		elif xander != null:
			xander.call("hush")
		Settings.save_settings())
	var tutorial := _pause_check(noob_subs, "Tutorial at the start of runs", not bool(cfg0.get_value("guide", "hide_v2", false)), func(on: bool) -> void:
		var cfg := ConfigFile.new()
		cfg.load(Settings.PATH)
		cfg.set_value("guide", "hide_v2", not on)
		cfg.save(Settings.PATH))
	advisor.disabled = not Settings.noob_mode
	tutorial.disabled = not Settings.noob_mode
	noob_subs.modulate.a = 1.0 if Settings.noob_mode else 0.45
	noob.toggled.connect(func(on: bool) -> void:
		Settings.noob_mode = on
		Settings.save_settings()
		advisor.disabled = not on
		tutorial.disabled = not on
		noob_subs.modulate.a = 1.0 if on else 0.45
		if not on and xander != null:
			xander.call("hush"))


func close_pause_menu() -> void:
	if _pause_menu == null:
		return
	_pause_menu.queue_free()
	_pause_menu = null
	_pause_settings = null
	# Back to whatever it was: still paused if you had pressed P.
	get_tree().paused = _paused_by_player
	Sfx.ui("blip")


func is_pause_menu_open() -> bool:
	return _pause_menu != null


func _pause_button(parent: Control, text: String, action: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(0, 52)
	button.add_theme_font_size_override("font_size", 24)
	parent.add_child(button)
	button.pressed.connect(func() -> void:
		Sfx.ui("click")
		action.call())


func _pause_slider(parent: Control, text: String, value: float, changed: Callable) -> void:
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 14)
	parent.add_child(line)
	var name_label := _make_label(line, Color("e9e6dc"), 18)
	name_label.text = text
	name_label.custom_minimum_size = Vector2(150, 0)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = value
	slider.custom_minimum_size = Vector2(230, 28)
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.focus_mode = Control.FOCUS_NONE
	line.add_child(slider)
	slider.value_changed.connect(changed)


func _pause_check(parent: Control, text: String, on: bool, changed: Callable) -> CheckBox:
	var box := CheckBox.new()
	box.text = text
	box.button_pressed = on
	box.focus_mode = Control.FOCUS_NONE
	box.add_theme_font_size_override("font_size", 18)
	parent.add_child(box)
	if changed.is_valid():
		box.toggled.connect(changed)
	return box


## A card's collector number (F3, T12, P5) in a small gold-ringed circle.
class CardNumber extends Control:
	var code := ""

	func _draw() -> void:
		var c := size / 2.0
		var r := minf(size.x, size.y) / 2.0
		draw_circle(c + Vector2(0, 2), r, Color(0, 0, 0, 0.45))
		draw_circle(c, r, Color("0b0e14"))
		draw_arc(c, r - 1.0, 0.0, TAU, 32, Color("e8c547"), 2.5)
		var font := ThemeDB.fallback_font
		var fs := 16 if code.length() <= 2 else 14
		var w := font.get_string_size(code, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(font, Vector2(c.x - w / 2.0, c.y + fs * 0.35), code, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color("f4efe2"))


## A fan of three little cards. Hovering lifts and spreads it with a gold glow and a
## slight 3D tilt, so it reads as clickable.
class DeckButton extends Control:
	const SfxRef = preload("res://scripts/sfx.gd")
	signal clicked
	var _hover := 0.0
	var _want := 0.0
	var _t := 0.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		tooltip_text = "Your cards"
		mouse_entered.connect(func() -> void:
			_want = 1.0
			SfxRef.ui("hover"))
		mouse_exited.connect(func() -> void: _want = 0.0)

	func _gui_input(event: InputEvent) -> void:
		var b := event as InputEventMouseButton
		if b != null and b.pressed and b.button_index == MOUSE_BUTTON_LEFT:
			clicked.emit()
			accept_event()

	func _process(delta: float) -> void:
		_t += delta
		_hover = move_toward(_hover, _want, delta * 6.0)
		queue_redraw()

	func _draw() -> void:
		var c := size / 2.0 + Vector2(0, 6.0 - 5.0 * _hover)
		var card := Vector2(22, 30) * (1.0 + 0.12 * _hover)
		if _hover > 0.0:
			var pulse := 0.6 + 0.4 * sin(_t * 5.0)
			draw_circle(c, 30.0 * _hover, Color(0.91, 0.77, 0.28, 0.12 * _hover * pulse))
			draw_circle(c, 20.0 * _hover, Color(0.91, 0.77, 0.28, 0.14 * _hover * pulse))
		var colours := [Color("3e6690"), Color("b89a4a"), Color("a4504a")]
		for i in 3:
			var spread := (float(i) - 1.0)
			var angle := spread * (0.28 + 0.16 * _hover)
			var pivot := c + Vector2(spread * (8.0 + 6.0 * _hover), card.y * 0.45)
			# The 3D tilt: on hover the fan leans back (squashed vertically) and skews.
			var squash := Vector2(1.0, 1.0 - 0.12 * _hover)
			var xf := Transform2D(angle, squash, 0.18 * _hover * spread, pivot)
			draw_set_transform_matrix(xf)
			var rect := Rect2(Vector2(-card.x / 2.0, -card.y), card)
			draw_rect(Rect2(rect.position + Vector2(2, 3), rect.size), Color(0, 0, 0, 0.4))
			draw_rect(rect, Color(colours[i]))
			draw_rect(Rect2(rect.position + Vector2(3, 3), rect.size - Vector2(6, 6)), Color("efe9da"))
			draw_rect(Rect2(rect.position + Vector2(3, 3), Vector2(rect.size.x - 6, 6)), Color("0b0e14"))
			draw_rect(rect, Color(1.0, 0.85, 0.4, 0.4 + 0.6 * _hover) if _hover > 0.05 else Color("0b0e14"), false, 1.5)
		draw_set_transform_matrix(Transform2D.IDENTITY)
