extends Control
## The flagship's death, on the tactical display (v0.9.188): the Kharkiv's red wireframe
## cut in two by a MAG round, the halves tumbling slowly apart through space like a
## cruiser breaking up in a cinematic, sparks spitting from the cut, bits of hull
## drifting off, and FLAGSHIP OFFLINE breathing in red at the top. Same hologram look
## as the green ships on the title screen. Fills the screen behind the end-of-run panels.

const ShipInfo = preload("res://scripts/ship_info.gd")
const RED := Color("e5484d")
const HOT := Color("ff8a4a")
const LENGTH := 640.0   # bow to stern, in pixels, before it broke

var _t := 0.0
var _halves: Array = []   # [[polygons...], [polygons...]]: front, back (hull units, nose = +x)
var _cores: Array = []
var _cut: PackedVector2Array
var _debris: Array = []   # [offset, velocity, spin, size]
var _sparks: Array = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	# The hull, turned so the nose points along +x.
	var hull := PackedVector2Array()
	for p in ShipInfo.SHAPES["capital"]:
		hull.append(Vector2(-float(p[1]), float(p[0])))
	# A jagged cut straight across the middle, where the slug went through.
	_cut = PackedVector2Array([Vector2(0.05, -1.3), Vector2(-0.04, -0.6), Vector2(0.06, -0.35), Vector2(-0.05, -0.1),
		Vector2(0.04, 0.12), Vector2(-0.06, 0.36), Vector2(0.03, 0.62), Vector2(-0.02, 1.3)])
	var front := _cut.duplicate()
	front.append(Vector2(2, 1.3))
	front.append(Vector2(2, -1.3))
	var back := _cut.duplicate()
	back.reverse()
	back.append(Vector2(-2, -1.3))
	back.append(Vector2(-2, 1.3))
	var core := PackedVector2Array()
	for i in 8:
		core.append(Vector2.RIGHT.rotated(PI / 8.0 + i * TAU / 8.0) * 0.17)
	_halves = [Geometry2D.intersect_polygons(hull, front), Geometry2D.intersect_polygons(hull, back)]
	_cores = [Geometry2D.intersect_polygons(core, front), Geometry2D.intersect_polygons(core, back)]
	for i in 26:
		var side := 1.0 if i % 2 == 0 else -1.0
		_debris.append([Vector2(randf_range(-0.05, 0.05), randf_range(-0.45, 0.45)),
			Vector2(side * randf_range(4.0, 22.0), randf_range(-14.0, 14.0)),
			randf_range(-1.5, 1.5), randf_range(4.0, 11.0)])


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


## Where each half is and how it has turned: they part slowly and keep on drifting.
func _pose(half: int) -> Array:
	var centre := size * Vector2(0.5, 0.5)
	# Apart quickly enough to show either side of the score panels once they're up.
	var sep := 60.0 + 1100.0 * (1.0 - exp(-_t / 10.0)) + _t * 8.0
	var side := 1.0 if half == 0 else -1.0
	var pos := centre + Vector2(side * sep * 0.5, -side * sep * 0.12)
	var rot := side * (0.03 + _t * 0.022) + (sin(_t * 0.4) * 0.02)
	return [pos, rot]


func _draw() -> void:
	var fade := clampf(_t / 1.4, 0.0, 1.0)
	var sc := LENGTH * 0.5 / 0.95
	# A slow shimmer rather than a fast flicker, and no random jumps: smooth motion (v0.9.192).
	var flicker := 0.9 + 0.1 * sin(_t * 2.6)
	var glitch := Vector2.ZERO
	for half in 2:
		var pose := _pose(half)
		var pos: Vector2 = pose[0] + glitch
		var rot: float = pose[1]
		var xf := func(p: Vector2) -> Vector2: return pos + (p * sc).rotated(rot)
		# The habitat ring: this half's side of it.
		var ring := PackedVector2Array()
		var a0 := -PI * 0.5 if half == 0 else PI * 0.5
		for i in 25:
			ring.append(xf.call(Vector2.RIGHT.rotated(a0 + PI * i / 24.0) * 0.61))
		draw_polyline(ring, Color(RED, 0.2 * fade), 7.0, true)
		draw_polyline(ring, Color(RED, 0.8 * flicker * fade), 2.5, true)
		for poly in _halves[half]:
			var pts := PackedVector2Array()
			for p in poly:
				pts.append(xf.call(p))
			draw_colored_polygon(pts, Color(RED, 0.16 * fade))
			var outline := pts.duplicate()
			outline.append(pts[0])
			draw_polyline(outline, Color(RED, 0.25 * fade), 7.0, true)
			draw_polyline(outline, Color(RED, flicker * fade), 2.5, true)
		for poly in _cores[half]:
			var cp := PackedVector2Array()
			for p in poly:
				cp.append(xf.call(p))
			draw_colored_polygon(cp, Color(RED, 0.25 * fade))
		# Spine stub and the glowing torn edge where the slug cut through.
		draw_line(xf.call(Vector2(0.8 if half == 0 else -0.8, 0)), xf.call(Vector2(0.05 if half == 0 else -0.05, 0)), Color(RED, 0.5 * fade), 1.5, true)
		var edge := PackedVector2Array()
		for p in _cut:
			if absf(p.y) <= 0.47:
				edge.append(xf.call(p))
		if edge.size() > 1:
			var heat := 0.6 + 0.4 * sin(_t * 1.8 + half)
			draw_polyline(edge, Color(HOT, 0.3 * fade * heat), 9.0, true)
			draw_polyline(edge, Color(1.0, 0.85, 0.6, 0.9 * fade * heat), 2.0, true)
			# Sparks drifting out of the cut: each on its own steady cycle (no random
			# flashing from frame to frame), dimming as the wreck cools.
			var cool := clampf(1.0 - _t / 25.0, 0.25, 1.0)
			for k in 9:
				var phase := fmod(_t * 0.9 + k * 0.137 + half * 0.5, 1.0)
				var at: Vector2 = edge[(k * 3 + half) % edge.size()]
				var d := Vector2.RIGHT.rotated(rot + (0.0 if half == 0 else PI) + PI + (float(k % 5) - 2.0) * 0.45)
				var p0 := at + d * phase * 34.0
				draw_line(p0, p0 + d * (4.0 + 6.0 * (1.0 - phase)), Color(1.0, 0.8, 0.45, (1.0 - phase) * fade * cool), 1.5, true)
	# Bits of hull tumbling away from the break.
	var mid := size * Vector2(0.5, 0.5)
	for d in _debris:
		var p: Vector2 = mid + Vector2(d[0]) * sc + Vector2(d[1]) * _t * 1.6
		var ang: float = float(d[2]) * _t * 0.5
		var s: float = d[3]
		var tri := PackedVector2Array([p + Vector2(s, 0).rotated(ang), p + Vector2(-s * 0.6, s * 0.5).rotated(ang), p + Vector2(-s * 0.4, -s * 0.7).rotated(ang), p + Vector2(s, 0).rotated(ang)])
		draw_polyline(tri, Color(RED, 0.6 * fade * clampf(1.0 - _t / 30.0, 0.3, 1.0)), 1.5, true)
	# FLAGSHIP OFFLINE, breathing slowly in red at the top.
	var font := ThemeDB.fallback_font
	var title := "F L A G S H I P   O F F L I N E"
	var fs := 46
	var tw := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var breathe := 0.45 + 0.55 * (0.5 + 0.5 * sin(_t * 1.5))
	var at_text := Vector2(size.x / 2.0 - tw / 2.0, 92.0)
	draw_string_outline(font, at_text, title, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 14, Color(RED, 0.18 * breathe * fade))
	draw_string(font, at_text, title, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(RED, breathe * fade))
