extends RefCounted
## Ship models in the Starbase's design language: armoured grey hulls tinted with the
## faction colour, ink outlines, a lit top edge, plate seams, glowing faction windows,
## engine glow and blinking nav lights. Each class has its own silhouette:
##   corvette   gunboat: a conventional little warship with gun sponsons either side
##   frigate    tuning fork: twin torpedo tubes out front
##   destroyer  a ship bolted to a gun: a long armoured barrel shroud, a compact stern
##   cruiser    missile barge: box racks of missile cells on both flanks
##   carrier    flat-top: a rectangular deck, runway stripe, island tower off to one side
##   battleship armoured brick: heavy sponsons, four turrets
##   capital    the Kharkiv: a ring ship with the Starbase's habitat ring and glowing core
##   colony     a spine carrying three habitat drums
## Coordinates are in ship radii: x forward (nose at +1), y to starboard.

const GD = preload("res://scripts/game_data.gd")

const HULL := Color("8e98a3")
const HULL_LIGHT := Color("c3cad1")
const HULL_DARK := Color("4a535d")
const INK := Color("0b0e14")

## Top half of each symmetric outline, nose first; mirrored for the other side.
const HALF := {
	"corvette": [[1.0, 0.0], [0.72, -0.18], [0.36, -0.3], [0.16, -0.3], [0.1, -0.46], [-0.26, -0.46], [-0.32, -0.3], [-0.78, -0.3], [-0.9, -0.22], [-0.9, 0.0]],
	"frigate": [[0.42, 0.0], [0.52, -0.14], [1.0, -0.14], [1.0, -0.44], [0.3, -0.52], [-0.1, -0.4], [-0.7, -0.48], [-0.92, -0.3], [-0.92, 0.0]],
	"destroyer": [[0.98, 0.0], [0.98, -0.09], [0.86, -0.11], [0.8, -0.15], [0.62, -0.15], [0.56, -0.11], [0.42, -0.11], [0.36, -0.16], [0.12, -0.16], [0.02, -0.3], [-0.32, -0.34], [-0.55, -0.56], [-0.78, -0.56], [-0.72, -0.3], [-0.98, -0.24], [-0.98, 0.0]],
	"cruiser": [[1.0, 0.0], [0.62, -0.2], [0.42, -0.26], [0.42, -0.62], [-0.42, -0.62], [-0.48, -0.32], [-0.86, -0.3], [-0.96, -0.16], [-0.96, 0.0]],
	"battleship": [[1.0, 0.0], [1.0, -0.16], [0.76, -0.4], [0.32, -0.44], [0.24, -0.64], [-0.42, -0.64], [-0.52, -0.44], [-0.9, -0.42], [-1.0, -0.22], [-1.0, 0.0]],
	"capital": [[1.0, 0.0], [0.84, -0.2], [0.44, -0.3], [0.36, -0.48], [-0.36, -0.48], [-0.44, -0.34], [-0.78, -0.36], [-0.94, -0.54], [-1.0, -0.54], [-1.0, 0.0]],
	"colony": [[0.95, 0.0], [0.75, -0.1], [0.7, -0.1], [0.6, -0.224], [0.5, -0.283], [0.4, -0.3], [0.3, -0.283], [0.2, -0.224], [0.1, -0.24], [0.0, -0.289], [-0.1, -0.299], [-0.2, -0.275], [-0.3, -0.204], [-0.4, -0.254], [-0.5, -0.294], [-0.6, -0.297], [-0.7, -0.265], [-0.8, -0.18], [-0.9, -0.1], [-0.9, 0.0]],
	"fighter": [[1.0, 0.0], [-0.7, -0.8], [-0.4, 0.0]],
}
## The carrier is lopsided (island to starboard), so it has a full outline.
const CARRIER := [[1.0, -0.36], [1.0, 0.36], [0.82, 0.5], [0.24, 0.5], [0.2, 0.7], [-0.36, 0.7], [-0.4, 0.5], [-0.95, 0.5], [-0.95, -0.5], [0.82, -0.5]]


## The silhouette as a closed list of points (nose at +x), for icons and hit shapes.
static func outline(type_id: String) -> PackedVector2Array:
	if type_id == "carrier":
		var pts := PackedVector2Array()
		for p in CARRIER:
			pts.append(Vector2(float(p[0]), float(p[1])))
		return pts
	return _mirror(HALF.get(type_id, HALF["fighter"]))


static func _mirror(half: Array) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for p in half:
		pts.append(Vector2(float(p[0]), float(p[1])))
	for i: int in range(half.size() - 1, -1, -1):
		var p: Array = half[i]
		if absf(float(p[1])) < 0.001:
			continue   # points on the centreline aren't doubled
		pts.append(Vector2(float(p[0]), -float(p[1])))
	return pts


## Draws one ship. at: centre in the canvas's space; r: radius in pixels.
static func draw(ci: CanvasItem, type_id: String, r: float, heading: float, at: Vector2, faction: int, flash: float, time: float) -> void:
	var tint := GD.faction_colour(faction)
	var trim := GD.faction_trim(faction)
	var hull := HULL.lerp(tint, 0.45)
	if flash > 0.0:
		hull = hull.lerp(Color("e5484d"), clampf(flash * 2.0, 0.0, 1.0))
	var glow := tint.lightened(0.5)
	if faction == GD.Faction.SONS:
		glow = trim   # the Sons' near-black hulls glow gold
	var line := maxf(1.0, r * 0.07)
	var shape := outline(type_id)
	# Shadow, offset down and right in screen space (doesn't turn with the ship).
	ci.draw_set_transform(at + Vector2(r * 0.08, r * 0.14), heading, Vector2(r, r))
	ci.draw_colored_polygon(shape, Color(0, 0, 0, 0.32))
	ci.draw_set_transform(at, heading, Vector2(r, r))
	# Habitat ring goes under the Kharkiv's hull, like the Starbase's ring round its core.
	if type_id == "capital":
		_ring(ci, r, hull, glow, time)
	ci.draw_colored_polygon(shape, hull)
	match type_id:
		"corvette":
			_corvette(ci, r, hull, glow, trim)
		"frigate":
			_frigate(ci, r, hull, glow, trim)
		"destroyer":
			_destroyer(ci, r, hull, glow, trim)
		"cruiser":
			_cruiser(ci, r, hull, glow, trim)
		"carrier":
			_carrier(ci, r, hull, glow, trim, time)
		"battleship":
			_battleship(ci, r, hull, glow, trim)
		"capital":
			_capital(ci, r, hull, glow, trim, time)
		"colony":
			_colony(ci, r, hull, glow, trim)
	# Lit top (port) edge and the ink outline over everything.
	_lit_edge(ci, shape, hull.lightened(0.45), line / r)
	var closed := shape.duplicate()
	closed.append(shape[0])
	ci.draw_polyline(closed, INK, line / r * 1.6)
	if type_id != "fighter":
		_nav_lights(ci, shape, time)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# --- per-class details ---------------------------------------------------------------

static func _corvette(ci: CanvasItem, r: float, hull: Color, glow: Color, trim: Color) -> void:
	# A plain little warship: deck plating, a bridge aft, and a gun sponson either side
	# (the shots come out of these, alternating left and right).
	_poly(ci, [[0.6, -0.16], [0.3, -0.24], [-0.7, -0.24], [-0.7, 0.24], [0.3, 0.24], [0.6, 0.16]], hull.darkened(0.15))
	for s: float in [-1.0, 1.0]:
		# The sponson: an armoured blister with a turret and a barrel pointing forward.
		_poly(ci, [[0.08, -0.31 * s], [0.04, -0.43 * s], [-0.22, -0.43 * s], [-0.26, -0.31 * s]], hull.darkened(0.3))
		ci.draw_line(Vector2(-0.02, -0.37 * s), Vector2(0.34, -0.37 * s), INK, 0.07)
		ci.draw_line(Vector2(-0.02, -0.37 * s), Vector2(0.32, -0.37 * s), HULL_LIGHT, 0.03)
		ci.draw_circle(Vector2(-0.09, -0.37 * s), 0.09, HULL_DARK)
		ci.draw_circle(Vector2(-0.09, -0.37 * s), 0.05, trim)
		_poly(ci, [[0.5, -0.2 * s], [0.22, -0.28 * s], [0.22, -0.24 * s], [0.5, -0.16 * s]], trim)   # bow stripe
		_poly(ci, [[-0.36, -0.3 * s], [-0.7, -0.3 * s], [-0.7, -0.25 * s], [-0.36, -0.25 * s]], trim)   # stern stripe
		_engine(ci, Vector2(-0.9, -0.13 * s), 0.09, glow)
	_seam(ci, Vector2(0.0, -0.24), Vector2(0.0, 0.24), r)
	_seam(ci, Vector2(-0.35, -0.24), Vector2(-0.35, 0.24), r)
	# Bridge block with lit windows.
	ci.draw_rect(Rect2(Vector2(-0.62, -0.14), Vector2(0.26, 0.28)), HULL_LIGHT.lerp(hull, 0.4))
	ci.draw_rect(Rect2(Vector2(-0.42, -0.1), Vector2(0.05, 0.2)), glow)
	ci.draw_circle(Vector2(0.45, 0), 0.06, glow)   # sensor on the bow


static func _frigate(ci: CanvasItem, r: float, hull: Color, glow: Color, trim: Color) -> void:
	for s: float in [-1.0, 1.0]:
		# Torpedo tubes: darker armoured barrels with open mouths.
		_poly(ci, [[0.55, -0.16 * s], [0.98, -0.16 * s], [0.98, -0.42 * s], [0.32, -0.48 * s]], hull.darkened(0.25))
		ci.draw_circle(Vector2(0.98, -0.29 * s), 0.1, INK)
		ci.draw_circle(Vector2(0.98, -0.29 * s), 0.05, glow)
		_seam(ci, Vector2(0.3, -0.48 * s), Vector2(-0.1, -0.2 * s), r)
		_engine(ci, Vector2(-0.92, -0.16 * s), 0.1, glow)
	_poly(ci, [[0.2, -0.06], [-0.6, -0.06], [-0.6, 0.06], [0.2, 0.06]], trim)   # spine stripe
	ci.draw_circle(Vector2(0.28, 0), 0.08, glow)


static func _destroyer(ci: CanvasItem, r: float, hull: Color, glow: Color, trim: Color) -> void:
	# The barrel shroud runs the length of the ship: rails down the middle, coils lighting
	# up along it, and two heavy collar bands clamping it to the hull.
	_poly(ci, [[0.96, -0.08], [0.96, 0.08], [0.12, 0.12], [0.12, -0.12]], hull.darkened(0.2))
	for s: float in [-1.0, 1.0]:
		ci.draw_line(Vector2(0.96, 0.035 * s), Vector2(0.0, 0.045 * s), INK, 0.035)
	for i: int in 7:
		var x := 0.9 - i * 0.12
		ci.draw_line(Vector2(x, -0.05), Vector2(x, 0.05), Color(glow, 0.85), 0.03)
	for band: Array in [[0.8, 0.62], [0.36, 0.12]]:
		var x0: float = band[0]
		var x1: float = band[1]
		_poly(ci, [[x0, -0.15], [x0, 0.15], [x1, 0.15], [x1, -0.15]], HULL_DARK.lerp(hull, 0.3))
		for xx: float in [x0 - 0.04, x1 + 0.04]:
			ci.draw_circle(Vector2(xx, -0.11), 0.025, HULL_LIGHT)   # bolts
			ci.draw_circle(Vector2(xx, 0.11), 0.025, HULL_LIGHT)
	# Muzzle brake at the very tip.
	ci.draw_rect(Rect2(Vector2(0.88, -0.09), Vector2(0.1, 0.18)), INK)
	for s: float in [-1.0, 1.0]:
		ci.draw_line(Vector2(0.9, 0.05 * s), Vector2(0.96, 0.05 * s), HULL_LIGHT, 0.02)
		# The stern body: fin stripes and plate seams.
		_poly(ci, [[-0.58, -0.52 * s], [-0.74, -0.52 * s], [-0.7, -0.32 * s], [-0.52, -0.33 * s]], trim)
		_seam(ci, Vector2(0.02, -0.28 * s), Vector2(-0.6, -0.3 * s), r)
		_engine(ci, Vector2(-0.98, -0.12 * s), 0.1, glow)
	# Bridge on the stern body.
	ci.draw_rect(Rect2(Vector2(-0.42, -0.14), Vector2(0.26, 0.28)), HULL_LIGHT.lerp(hull, 0.4))
	ci.draw_rect(Rect2(Vector2(-0.22, -0.09), Vector2(0.04, 0.18)), glow)


static func _cruiser(ci: CanvasItem, r: float, hull: Color, glow: Color, trim: Color) -> void:
	for s: float in [-1.0, 1.0]:
		# Missile racks: a raised box of cells, each with a glowing warhead.
		_poly(ci, [[0.38, -0.3 * s], [0.38, -0.58 * s], [-0.38, -0.58 * s], [-0.38, -0.3 * s]], hull.darkened(0.3))
		for cx: int in 4:
			for cy: int in 2:
				var c := Vector2(0.28 - cx * 0.19, (-0.38 - cy * 0.12) * s)
				ci.draw_rect(Rect2(c - Vector2(0.06, 0.04), Vector2(0.12, 0.08)), INK)
				ci.draw_circle(c, 0.03, glow)
		_engine(ci, Vector2(-0.96, -0.1 * s), 0.09, glow)
	# Flak turrets along the spine.
	for x: float in [0.5, -0.1, -0.6]:
		ci.draw_circle(Vector2(x, 0), 0.09, HULL_DARK)
		ci.draw_circle(Vector2(x, 0), 0.05, trim)


static func _carrier(ci: CanvasItem, r: float, hull: Color, glow: Color, trim: Color, time: float) -> void:
	# The flight deck: darker plating with a dashed runway down the middle.
	_poly(ci, [[0.95, -0.4], [0.95, 0.4], [-0.9, 0.44], [-0.9, -0.44]], hull.darkened(0.3))
	for i: int in 7:
		var x := 0.8 - i * 0.26
		ci.draw_line(Vector2(x, 0), Vector2(x - 0.13, 0), trim, 0.05)
	# Launch lights chasing down the deck edges.
	for i: int in 6:
		var x := 0.85 - i * 0.33
		var on := 0.25 + 0.75 * clampf(sin(time * 4.0 - i * 0.9), 0.0, 1.0)
		ci.draw_circle(Vector2(x, -0.38), 0.035, Color(glow, on))
		ci.draw_circle(Vector2(x, 0.38), 0.035, Color(glow, on))
	# Hangar mouth at the bow.
	ci.draw_rect(Rect2(Vector2(0.86, -0.22), Vector2(0.14, 0.44)), INK)
	# The island tower, off to starboard.
	_poly(ci, [[0.16, 0.5], [0.14, 0.66], [-0.32, 0.66], [-0.34, 0.5]], HULL_LIGHT.lerp(hull, 0.4))
	for i: int in 3:
		ci.draw_rect(Rect2(Vector2(0.06 - i * 0.14, 0.55), Vector2(0.08, 0.05)), glow)
	_engine(ci, Vector2(-0.95, -0.25), 0.1, glow)
	_engine(ci, Vector2(-0.95, 0.25), 0.1, glow)


static func _battleship(ci: CanvasItem, r: float, hull: Color, glow: Color, trim: Color) -> void:
	for s: float in [-1.0, 1.0]:
		# Armour sponsons: heavy side plates with seams.
		_poly(ci, [[0.24, -0.46 * s], [0.24, -0.62 * s], [-0.42, -0.62 * s], [-0.5, -0.46 * s]], hull.darkened(0.22))
		for x: float in [0.05, -0.2]:
			_seam(ci, Vector2(x, -0.46 * s), Vector2(x, -0.62 * s), r)
		# Two Gatling turrets a side.
		for x: float in [0.5, -0.65]:
			ci.draw_circle(Vector2(x, -0.26 * s), 0.11, HULL_DARK)
			ci.draw_circle(Vector2(x, -0.26 * s), 0.06, trim)
		_engine(ci, Vector2(-1.0, -0.12 * s), 0.11, glow)
		_seam(ci, Vector2(0.74, -0.38 * s), Vector2(0.3, -0.42 * s), r)
	# Bridge block at the back, with lit windows.
	ci.draw_rect(Rect2(Vector2(-0.48, -0.16), Vector2(0.3, 0.32)), HULL_LIGHT.lerp(hull, 0.4))
	for i: int in 3:
		ci.draw_rect(Rect2(Vector2(-0.44 + i * 0.09, -0.04), Vector2(0.05, 0.08)), glow)


static func _ring(ci: CanvasItem, r: float, hull: Color, glow: Color, time: float) -> void:
	# The Starbase's armoured habitat ring, around the Kharkiv's midship.
	var rr := 0.64
	ci.draw_arc(Vector2.ZERO, rr, 0.0, TAU, 40, INK, 0.2)
	ci.draw_arc(Vector2.ZERO, rr, 0.0, TAU, 40, hull, 0.14)
	for i: int in 4:
		var d := Vector2.RIGHT.rotated(PI * 0.25 + i * PI * 0.5)
		ci.draw_line(d * 0.2, d * (rr - 0.06), HULL_DARK, 0.07)
	# Windows that slowly travel round as the ring turns.
	for i: int in 16:
		if i % 4 == 0:
			continue
		var d := Vector2.RIGHT.rotated(time * 0.4 + i * TAU / 16.0)
		ci.draw_circle(d * rr, 0.025, Color(glow, 0.9))


static func _capital(ci: CanvasItem, r: float, hull: Color, glow: Color, trim: Color, time: float) -> void:
	# Armoured midship block under the ring, with heavy plate seams.
	_poly(ci, [[0.34, -0.42], [-0.34, -0.42], [-0.34, 0.42], [0.34, 0.42]], hull.darkened(0.18))
	for x: float in [0.17, 0.0, -0.17]:
		_seam(ci, Vector2(x, -0.42), Vector2(x, 0.42), r)
	# Command core: the Starbase's octagon with the pulsing glow.
	var core := PackedVector2Array()
	for i: int in 8:
		core.append(Vector2.RIGHT.rotated(PI / 8.0 + i * TAU / 8.0) * 0.26)
	ci.draw_colored_polygon(core, HULL_LIGHT.lerp(hull, 0.3))
	core.append(core[0])
	ci.draw_polyline(core, INK, 0.04)
	ci.draw_circle(Vector2.ZERO, 0.14, glow.darkened(0.3))
	ci.draw_circle(Vector2.ZERO, 0.14 * (0.55 + 0.1 * sin(time * 2.0)), Color(glow.lightened(0.3), 0.9))
	for s: float in [-1.0, 1.0]:
		# Bow armour stripes and plating.
		_poly(ci, [[0.8, -0.14 * s], [0.46, -0.24 * s], [0.46, -0.16 * s], [0.8, -0.08 * s]], trim)
		_seam(ci, Vector2(0.7, -0.15 * s), Vector2(0.44, -0.27 * s), r)
		# Stern sponsons: heavy armour round the engine block.
		_poly(ci, [[-0.46, -0.3 * s], [-0.76, -0.32 * s], [-0.9, -0.48 * s], [-0.98, -0.48 * s], [-0.98, -0.2 * s], [-0.46, -0.2 * s]], hull.darkened(0.25))
		_seam(ci, Vector2(-0.6, -0.2 * s), Vector2(-0.6, -0.33 * s), r)
		# Gatling turrets on the flanks.
		for x: float in [0.62, -0.62]:
			ci.draw_circle(Vector2(x, -0.2 * s), 0.08, HULL_DARK)
			ci.draw_circle(Vector2(x, -0.2 * s), 0.045, trim)
		_engine(ci, Vector2(-1.0, -0.36 * s), 0.12, glow)
	_engine(ci, Vector2(-1.0, 0.0), 0.16, glow)
	ci.draw_circle(Vector2(0.66, 0), 0.07, glow)   # forward bridge


static func _colony(ci: CanvasItem, r: float, hull: Color, glow: Color, trim: Color) -> void:
	# Three habitat drums on the spine, green-lit windows for the settlers.
	var green := Color("5fe39a")
	for x: float in [0.4, -0.08, -0.56]:
		ci.draw_circle(Vector2(x, 0), 0.3, INK)
		ci.draw_circle(Vector2(x, 0), 0.26, hull)
		ci.draw_arc(Vector2(x, 0), 0.26, PI * 1.1, PI * 1.9, 12, hull.lightened(0.4), 0.05)
		for i: int in 6:
			var d := Vector2.RIGHT.rotated(i * TAU / 6.0)
			ci.draw_circle(Vector2(x, 0) + d * 0.16, 0.03, green)
	_engine(ci, Vector2(-0.9, 0), 0.1, glow)


# --- shared bits ---------------------------------------------------------------------

static func _poly(ci: CanvasItem, pts: Array, colour: Color) -> void:
	var packed := PackedVector2Array()
	for p in pts:
		packed.append(Vector2(float(p[0]), float(p[1])))
	ci.draw_colored_polygon(packed, colour)


static func _seam(ci: CanvasItem, a: Vector2, b: Vector2, r: float) -> void:
	ci.draw_line(a, b, Color(INK, 0.55), maxf(0.02, 1.0 / r))


static func _engine(ci: CanvasItem, at: Vector2, size: float, glow: Color) -> void:
	ci.draw_circle(at, size * 1.8, Color(glow, 0.18))
	ci.draw_circle(at, size, Color(glow.lightened(0.3), 0.95))


## A lighter line along the port-side edges that face up-left, like the Starbase's lit rim.
static func _lit_edge(ci: CanvasItem, shape: PackedVector2Array, colour: Color, width: float) -> void:
	for i: int in shape.size():
		var a := shape[i]
		var b := shape[(i + 1) % shape.size()]
		if a.y < -0.001 and b.y <= 0.001 and a.x > b.x:
			ci.draw_line(a, b, colour, width * 1.4)


## Red to port, green to starboard on the widest points, blinking like the Starbase's.
static func _nav_lights(ci: CanvasItem, shape: PackedVector2Array, time: float) -> void:
	var port := Vector2.ZERO
	var starboard := Vector2.ZERO
	for p in shape:
		if p.y < port.y:
			port = p
		if p.y > starboard.y:
			starboard = p
	var blink := 1.0 if fmod(time, 1.6) < 0.25 else 0.3
	ci.draw_circle(port, 0.05, Color(1.0, 0.3, 0.25, blink))
	ci.draw_circle(starboard, 0.05, Color(0.3, 1.0, 0.45, blink))
