extends Node2D
## A station ghost: the outline of a Starbase or Shipyard where you placed it, with a
## status line above ("Waiting for construction ship", "ETA 0:14", a build bar...).
## The same node follows the mouse while you're choosing a spot (preview).

const GD = preload("res://scripts/game_data.gd")
const ResIcon = preload("res://scripts/res_icon.gd")

var kind := "starbase"
var system_index := 0
var preview := false
var valid := true
var reason := ""          # why this spot doesn't work (preview only)
var status := "waiting"   # "waiting", "enroute", "building", "lost", "no_yard"
var place_in_line := 1
var eta := 0.0
var progress := 0.0       # seconds of building done
var build_time := 20.0
var respawn_left := 0.0
var paid := {}
var tint := Color("4c8dff")   # outline colour (another faction's builds use their own)
var owner_text := ""          # whose build this is, when it isn't yours

var _time := 0.0
var _font: Font


func setup(new_kind: String, system: int, pos_px: Vector2) -> void:
	kind = new_kind
	system_index = system
	position = pos_px
	build_time = float(GD.STRUCTURES[kind]["time"])


func _ready() -> void:
	z_index = 4
	_font = ThemeDB.fallback_font


func _process(delta: float) -> void:
	_time += delta
	if is_visible_in_tree():
		queue_redraw()


static func clock(seconds: float) -> String:
	var s := int(ceil(maxf(seconds, 0.0)))
	return "%d:%02d" % [s / 60, s % 60]


func _ordinal(n: int) -> String:
	match n:
		2:
			return "2nd"
		3:
			return "3rd"
		_:
			return "%dth" % n


func _draw() -> void:
	var u := GD.UNIT
	var k := GD.screen_scale(self)
	var colour := tint if valid else Color("e5484d")
	var pulse := 0.55 + 0.25 * sin(_time * 3.0)
	var done := clampf(progress / maxf(build_time, 0.01), 0.0, 1.0)
	var top := 0.0
	if kind == "starbase":
		var orbit_r := GD.STARBASE_ORBIT * GD.orbit_multiplier * u
		_dashed_circle(orbit_r, Color(colour, 0.45), 2.5)
		var half := 0.9 * u
		var box := Rect2(-Vector2(half, half), Vector2(half, half) * 2.0)
		draw_rect(box, Color(colour, 0.12 * pulse))
		if done > 0.0:
			draw_rect(Rect2(box.position + Vector2(0, box.size.y * (1.0 - done)), Vector2(box.size.x, box.size.y * done)), Color("b8bec4"))
		draw_rect(box, Color(colour, 0.9), false, 2.0)
		top = -half
	else:
		var repair_r := GD.STARBASE_ORBIT * GD.orbit_multiplier * u
		_dashed_circle(repair_r, Color(0.24, 0.82, 0.48, 0.35) if valid else Color(colour, 0.35), 2.0)
		var size := Vector2(1.6, 1.0) * u
		var box := Rect2(-size / 2.0, size)
		draw_rect(box, Color(colour, 0.12 * pulse))
		if done > 0.0:
			draw_rect(Rect2(box.position, Vector2(box.size.x * done, box.size.y)), Color(GD.faction_colour(GD.Faction.UNE), 0.6))
		draw_rect(box, Color(colour, 0.9), false, 2.0)
		top = -size.y / 2.0
	var name_text := String(GD.STRUCTURES[kind]["name"]).to_upper()
	var line := ""
	var line_colour := Color("f4efe2")
	if preview:
		line = reason if reason != "" else "CLICK TO PLACE  ·  RIGHT-CLICK TO CANCEL"
		line_colour = Color("e5484d") if reason != "" else Color("8fb4e3")
	else:
		match status:
			"waiting":
				line = "WAITING FOR CONSTRUCTION SHIP"
				if place_in_line > 1:
					line += " (%s)" % _ordinal(place_in_line)
				line_colour = Color("c9ced6")
			"enroute":
				line = "CONSTRUCTION SHIP ETA %s" % clock(eta)
				line_colour = Color("e8c547")
			"building":
				line = "BUILDING %s" % clock(build_time - progress)
				if owner_text != "":
					line = "%s  ·  %s" % [owner_text, line]
				line_colour = Color(GD.GAIN_COLOUR)
			"lost":
				line = "CONSTRUCTION SHIP LOST  ·  NEW ONE IN %s" % clock(respawn_left)
				line_colour = Color("e5484d")
			"no_yard":
				line = "NEEDS A SHIPYARD"
				line_colour = Color("e5484d")
	_label(Vector2(0, top - 26.0 * k), name_text, 15, Color("f4efe2"))
	_label(Vector2(0, top - 8.0 * k), line, 13, line_colour)
	if not preview and status == "building":
		var w := 70.0 * k
		var y := -top + 8.0 * k
		draw_rect(Rect2(Vector2(-w / 2.0, y), Vector2(w, 5.0 * k)), Color(0.02, 0.03, 0.05, 0.8))
		draw_rect(Rect2(Vector2(-w / 2.0, y), Vector2(w * done, 5.0 * k)), Color(GD.GAIN_COLOUR))


var muted_label := false   # draw the next labels' resource icons greyed out


func _label(pos: Vector2, text: String, size: int, colour: Color) -> void:
	var k := GD.screen_scale(self)
	# "{alloys}40" and friends draw as resource icons (res_icon.gd).
	var w := ResIcon.text_width(_font, text, size)
	draw_set_transform(pos, 0.0, Vector2(k, k))
	ResIcon.draw_text(self, _font, Vector2(-w / 2.0, 0), text, size, colour, 4, muted_label)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _dashed_circle(r: float, colour: Color, width: float) -> void:
	var segments := 48
	var spin := _time * 0.2
	for i in segments:
		if i % 2 == 0:
			var a := TAU * i / segments + spin
			draw_arc(Vector2.ZERO, r, a, a + TAU / segments, 4, colour, width)
