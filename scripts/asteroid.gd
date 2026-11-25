extends Node2D
## One asteroid. Regular rocks pay Alloys or Gas to a Starbase whose orbit covers them.
## Only focus fire hurts them. A destroyed regular rock is replaced by one that drifts in
## from the system's edge. Silver and gold asteroids drop a Fleet Card pickup instead.

signal asteroid_destroyed(rock: Node2D)

const Smoke = preload("res://scripts/smoke.gd")
const GD = preload("res://scripts/game_data.gd")
const Explosion = preload("res://scripts/explosion.gd")
const ResIcon = preload("res://scripts/res_icon.gd")

var kind := "rock"          # rock, gas, silver, gold
var yield_alloys := 0
var yield_gas := 0
var shielded := false     # Asteroid Force Fields: nothing can destroy it
var _shield_flash := 0.0
var size := 1.0             # units
var health := 25.0
var max_health := 25.0
var faction := GD.Faction.NEUTRAL
var alive := true
var field_id := -1
var arrived := true
var last_hit_une := false   # only rocks you break pay you
var worked := false         # inside a friendly Starbase orbit (set by main)
var home := Vector2.ZERO    # pixels

var _shape := PackedVector2Array()
var _spin := 0.0
var _phase := 0.0
var _time := 0.0
var _knock := Vector2.ZERO
var _since_hit := 99.0      # seconds since the last hit; the health bar hides after 5
var _knock_vel := Vector2.ZERO
var _drift_speed := 0.0
var _specks: Array = []     # purple Alloy flecks, in rock-relative units
var _vents: Array = []      # green Gas vents, in rock-relative units
var _font: Font


func setup(new_kind: String, home_px: Vector2, new_size: float, shape: PackedVector2Array, spin: float, alloys: int, gas: int, field: int) -> void:
	kind = new_kind
	home = home_px
	position = home_px
	size = new_size * GD.ASTEROID_SCALE   # 20% bigger (v0.9.223); health stays as before
	_shape = shape
	_spin = spin
	_phase = randf() * TAU
	yield_alloys = alloys   # rocks now roll 1-8 directly (v0.9.239)
	yield_gas = gas
	field_id = field
	max_health = 25.0 * new_size
	health = max_health
	_font = ThemeDB.fallback_font
	if kind == "rock" and yield_alloys > 0:
		for i in 2 + mini(yield_alloys, 6):   # fewer flecks to draw (was 2 + 2 per Alloy, up to 18)
			_specks.append(Vector2.RIGHT.rotated(randf() * TAU) * randf_range(0.1, 0.55))
	# Gas rocks: glowing green vents on the surface.
	if kind == "gas" and yield_gas > 0:
		for i in 3:
			_vents.append(Vector2.RIGHT.rotated(randf() * TAU) * randf_range(0.15, 0.5))


func _ready() -> void:
	# Performance (v0.9.241): rocks are no longer in the "targets" group. Every gun and
	# ship scans that group for enemies, and rocks are never hostile, so hundreds of them
	# were being checked and thrown away many times a second. Shots still hit rocks (the
	# system's hit grid includes them) and you can still focus them.
	add_to_group("asteroids")
	_slot = randi() % 2


## A replacement rock floating in from far away to this rock's spot.
func start_drift(from_px: Vector2, seconds: float) -> void:
	arrived = false
	position = from_px
	_drift_speed = from_px.distance_to(home) / maxf(1.0, seconds)


func knock(push_px: Vector2) -> void:
	# One shove at a time, and never far: a ship resting on a rock used to add a push
	# every frame, flinging the rock across the system before it slid home.
	if _knock_vel.length() > push_px.length() * 0.5:
		return
	_knock_vel += push_px


## A little burst of gas from a spot on the surface: two or three puffs drifting out.
static func _vent(parent: Node, centre: Vector2, radius: float, colour: Color) -> void:
	var dir := Vector2.RIGHT.rotated(randf() * TAU)
	var at := centre + dir * radius * randf_range(0.7, 1.0)
	for i in randi_range(2, 3):
		var puff := Smoke.new()
		parent.add_child(puff)
		puff.setup(at + Vector2(randf_range(-4.0, 4.0), randf_range(-4.0, 4.0)), radius * randf_range(0.18, 0.3), colour,
			randf_range(1.6, 2.6), dir * randf_range(14.0, 28.0) + Vector2(randf_range(-6.0, 6.0), randf_range(-6.0, 6.0)), 2.4)


func radius_px() -> float:
	return size * GD.UNIT


func take_damage(amount: float, attacker: Node2D = null) -> void:
	if not alive:
		return
	if shielded:
		_shield_flash = 0.25
		queue_redraw()
		return
	if attacker != null and is_instance_valid(attacker):
		var f = attacker.get("faction")
		last_hit_une = f != null and int(f) == GD.Faction.UNE
	# Rock armor: every hit does 3 less, but never less than 1.
	if amount > 0.0 and GD.ROCK_ARMOR > 0.0:
		amount = maxf(amount - GD.ROCK_ARMOR, 1.0)
		GD.hit_hardened = true
	health -= amount
	_since_hit = 0.0
	if health <= 0.0:
		alive = false
		var boom := Explosion.new()
		get_parent().add_child(boom)
		boom.setup(position, radius_px() * 2.0)
		asteroid_destroyed.emit(self)
		queue_free()
	else:
		queue_redraw()


var _puff_t := randf_range(1.0, 5.0)   # gas rocks: seconds until the next gas puff
var _slot := 0                          # which frames this rock redraws on (spreads the work)
var _small := false                     # tiny on screen: draw the cheap version


func _process(delta: float) -> void:
	_time += delta
	# Gas rocks vent now and then: a soft green puff drifting off the surface.
	if yield_gas > 0 and alive:
		_puff_t -= delta
		if _puff_t <= 0.0:
			_puff_t = randf_range(2.0, 5.0)
			if is_visible_in_tree() and GD.on_screen(self):
				_vent(get_parent(), position, radius_px(), Color(0.55, 0.78, 0.38, 0.35))
	_since_hit += delta
	_shield_flash = maxf(0.0, _shield_flash - delta)
	var shown := is_visible_in_tree()
	if not arrived:
		var to := home - position
		var step := _drift_speed * delta
		if to.length() <= step:
			position = home
			arrived = true
		else:
			position += to.normalized() * step
	elif shown or _knock != Vector2.ZERO or _knock_vel != Vector2.ZERO:
		# After a bump, slide away and slowly drift back home. (Rocks in systems you're
		# not looking at skip the idle wobble: nobody sees it.)
		_knock += _knock_vel * delta
		_knock_vel *= exp(-2.5 * delta)
		_knock = _knock.lerp(Vector2.ZERO, 1.0 - exp(-0.6 * delta))
		_knock = _knock.limit_length(3.0 * GD.UNIT)
		if _knock.length_squared() < 0.0001 and _knock_vel.length_squared() < 0.0001:
			_knock = Vector2.ZERO
			_knock_vel = Vector2.ZERO
		var wobble := Vector2(sin(_time * 0.7 + _phase), cos(_time * 0.5 + _phase)) * 0.15 * GD.UNIT
		position = home + _knock + wobble
	if not shown:
		return
	var k := GD.screen_scale(self)
	if not GD.on_screen(self, 160.0 + radius_px() * 1.6 / k):
		return
	# Redraw every other frame (half the rocks each frame), and only every fourth frame
	# when the rock is a speck on screen. The animations are slow enough not to notice.
	_small = radius_px() / k < 9.0
	var frame := Engine.get_process_frames()
	if (frame + _slot) % (4 if _small else 2) == 0 or _since_hit < 0.3 or _shield_flash > 0.0 or not arrived:
		queue_redraw()


func _draw() -> void:
	var colour := Color("8e8478")
	match kind:
		"gas":
			colour = Color("6f8a4f") if yield_gas > 0 else Color("7d8070")
		"silver":
			colour = Color("c9ced6")
		"gold":
			colour = Color("d9a93a")
	var r := radius_px()
	if shielded:
		# A soft blue force field, brighter for a moment when something hits it.
		var hit := _shield_flash / 0.25
		draw_circle(Vector2.ZERO, r * 1.55, Color(0.45, 0.75, 1.0, 0.07 + 0.15 * hit))
		draw_arc(Vector2.ZERO, r * 1.55, 0.0, TAU, 32, Color(0.56, 0.82, 1.0, 0.35 + 0.5 * hit), 1.5 + 1.5 * hit)
	if kind == "silver" or kind == "gold":
		draw_circle(Vector2.ZERO, r * 1.6, Color(colour, 0.15))
	var pts := PackedVector2Array()
	var angle := _time * _spin + _phase
	for p in _shape:
		pts.append(p.rotated(angle) * r)
	# Silver and gold rocks glow softly.
	if kind == "silver" or kind == "gold":
		var glow := Color("e8c547") if kind == "gold" else Color("d6e2ee")
		var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 500.0)
		draw_circle(Vector2.ZERO, r * 1.6, Color(glow, 0.06 + 0.05 * pulse))
		draw_circle(Vector2.ZERO, r * 1.3, Color(glow, 0.08 + 0.06 * pulse))
	# Resource rocks glisten: a soft pulsing aura in their colour (purple Alloys, green Gas).
	var valuable := not _specks.is_empty() or not _vents.is_empty()
	var tint := Color(0.75, 0.45, 1.0) if not _specks.is_empty() else Color(0.45, 0.95, 0.45)
	if valuable:
		var aura := 0.5 + 0.5 * sin(_time * 1.6 + _phase)
		draw_circle(Vector2.ZERO, r * 1.55, Color(tint, 0.05 + 0.05 * aura))
		draw_circle(Vector2.ZERO, r * 1.25, Color(tint, 0.07 + 0.07 * aura))
	draw_colored_polygon(pts, colour if arrived else colour.darkened(0.3))
	var outline := pts.duplicate()
	outline.append(pts[0])
	draw_polyline(outline, Color("0b0e14"), 2.0)
	if valuable and _small:
		# Zoomed out: just a coloured core, no glints, motes or twinkles (performance).
		draw_circle(Vector2.ZERO, r * 0.35, Color(tint.lightened(0.3), 0.9))
	elif valuable:
		# A bright glint sliding round the rim, and motes of light circling the rock.
		var sweep := fmod(_time * 0.9 + _phase, TAU)
		draw_arc(Vector2.ZERO, r * 0.98, sweep, sweep + 0.7, 10, Color(1, 1, 1, 0.55), 2.5)
		draw_arc(Vector2.ZERO, r * 0.98, sweep + 0.15, sweep + 0.45, 6, Color(tint.lightened(0.6), 0.9), 3.5)
		for m: int in 3:
			var ma := _time * (0.6 + m * 0.17) + _phase + m * TAU / 3.0
			var mp := Vector2(cos(ma), sin(ma) * 0.8) * r * (1.3 + 0.08 * sin(_time * 2.0 + m))
			var mt := 0.4 + 0.6 * pow(maxf(0.0, sin(_time * 3.1 + m * 2.0 + _phase)), 4.0)
			draw_circle(mp, maxf(1.5, r * 0.06) * (1.0 + mt), Color(tint.lightened(0.5), 0.35 * mt))
			draw_circle(mp, maxf(1.0, r * 0.03), Color(1, 1, 1, 0.8 * mt))
	# Alloy-bearing rocks are flecked with bright purple, and the flecks twinkle now and
	# then so a rich rock is easy to spot.
	for i in (0 if _small else _specks.size()):
		var p: Vector2 = _specks[i]
		var at := p.rotated(angle) * r
		var fleck := maxf(1.8, r * 0.1)
		draw_circle(at, fleck * 1.9, Color(0.75, 0.45, 1.0, 0.22))
		draw_circle(at, fleck, Color("c98bff"))
		var tw := pow(maxf(0.0, sin(_time * 3.4 + _phase * 3.0 + i * 1.7)), 6.0)
		if tw > 0.02:
			var arm := fleck * (2.5 + 6.0 * tw)
			var sparkle := Color(1.0, 0.9, 1.0, tw)
			draw_line(at - Vector2(arm, 0), at + Vector2(arm, 0), sparkle, 2.0)
			draw_line(at - Vector2(0, arm), at + Vector2(0, arm), sparkle, 2.0)
			var diag := arm * 0.55
			draw_line(at - Vector2(diag, diag), at + Vector2(diag, diag), Color(sparkle, tw * 0.6), 1.5)
			draw_line(at - Vector2(diag, -diag), at + Vector2(diag, -diag), Color(sparkle, tw * 0.6), 1.5)
			draw_circle(at, fleck * 1.0, Color(1, 1, 1, tw))
	# Gas rocks: green vents that glow and puff softly.
	for i in (0 if _small else _vents.size()):
		var p: Vector2 = _vents[i]
		var at := p.rotated(angle) * r
		var breathe := 0.5 + 0.5 * sin(_time * 1.8 + _phase + i * 2.1)
		var vent := maxf(2.0, r * 0.11)
		draw_circle(at, vent * (2.4 + 1.2 * breathe), Color(0.45, 0.9, 0.4, 0.12 + 0.12 * breathe))
		draw_circle(at, vent, Color(0.6, 1.0, 0.5, 0.75 + 0.25 * breathe))
		var tw := pow(maxf(0.0, sin(_time * 3.0 + _phase * 2.0 + i * 2.6)), 6.0)
		if tw > 0.02:
			var arm := vent * (2.5 + 5.0 * tw)
			draw_circle(at, vent * 1.0, Color(1, 1, 1, tw))
			draw_line(at - Vector2(arm, 0), at + Vector2(arm, 0), Color(0.85, 1.0, 0.8, tw), 2.0)
			draw_line(at - Vector2(0, arm), at + Vector2(0, arm), Color(0.85, 1.0, 0.8, tw), 2.0)
	var k := GD.screen_scale(self)
	if GD.show_full_names and arrived:
		var items := _label_items()
		var text := _yield_text()
		if not items.is_empty():
			# Each yield as its icon with the number above it: green when a Starbase is
			# collecting this rock, grey when nobody is.
			var shift := _label_shift(k)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(k, k))
			var col := Color("3dd17a") if worked else Color("8a96a0")
			# Label centre (in this scaled space): under the rock, stepped down to dodge
			# neighbours. A worked rock's label stays inside its Starbase's orbit: if under
			# the rock would poke outside, it goes on the side facing the Starbase.
			var lc := Vector2(0, r / k + 30.0 + shift)
			if worked and get_parent().has_method("_une_base_covering"):
				var base: Vector2 = get_parent().call("_une_base_covering", position / GD.UNIT)
				if base != Vector2.INF:
					var base_px := base * GD.UNIT
					var orbit_px := (GD.STARBASE_ORBIT * GD.orbit_multiplier - 1.5) * GD.UNIT
					if (position + lc * k).distance_to(base_px) > orbit_px:
						var inward := (base_px - position).normalized()
						lc = inward * (r / k + 24.0)
			if lc.x == 0.0 and lc.y > r / k + 30.5:
				draw_line(Vector2(0, r / k + 4.0), lc - Vector2(0, 20), Color(col, 0.35), 1.5)
			var total_w := items.size() * 34.0
			for i in items.size():
				var item: Array = items[i]
				var cx := lc.x - total_w / 2.0 + 17.0 + i * 34.0
				var num := str(int(item[1]))
				var nw := _font.get_string_size(num, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
				draw_string_outline(_font, Vector2(cx - nw / 2.0, lc.y - 5.0), num, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, 6, Color("0b0e14"))
				draw_string(_font, Vector2(cx - nw / 2.0, lc.y - 5.0), num, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, col)
				# A dark backing disc so the icon reads against anything.
				draw_circle(Vector2(cx, lc.y + 10.0), 12.5, Color(0.03, 0.04, 0.06, 0.55))
				ResIcon.draw(self, String(item[0]), Vector2(cx, lc.y + 10.0), 11.0, not worked)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		elif text != "":
			# Labels that would overlap a neighbour's are pushed down a line at a time.
			var shift := _label_shift(k)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(k, k))
			var w := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
			var y := r / k + 28.0 + shift
			if shift > 0.0:
				draw_line(Vector2(0, r / k + 6.0), Vector2(0, y - 14.0), Color(_yield_colour(), 0.35), 1.5)
			draw_string_outline(_font, Vector2(-w / 2.0, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, 5, Color("0b0e14"))
			draw_string(_font, Vector2(-w / 2.0, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, _yield_colour())
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if health < max_health and _since_hit < 5.0:
		var w := 30.0 * k
		draw_rect(Rect2(Vector2(-w / 2.0, r + 4.0 * k), Vector2(w, 4.0 * k)), Color(0.02, 0.03, 0.05, 0.8))
		draw_rect(Rect2(Vector2(-w / 2.0, r + 4.0 * k), Vector2(w * health / max_health, 4.0 * k)), Color("e8c547"))


## Where this rock's label sits (extra screen px down) so no two labels overlap.
## Worked out once per frame for every rock in the system, top to bottom.
func _label_shift(k: float) -> float:
	var view := get_parent()
	var frame := Engine.get_process_frames()
	if int(view.get_meta("label_frame", -1)) != frame:
		view.set_meta("label_frame", frame)
		view.set_meta("label_shifts", _layout_labels(view, k))
	var shifts: Dictionary = view.get_meta("label_shifts", {})
	return float(shifts.get(get_instance_id(), 0.0))


static func _layout_labels(view: Node, k: float) -> Dictionary:
	var items: Array = []
	for n in view.get_children():
		if not n.is_in_group("asteroids") or not (n.get("alive") == true) or not (n.get("arrived") == true):
			continue
		var label: Vector2 = n.call("label_size")
		if label == Vector2.ZERO:
			continue
		var rock := n as Node2D
		var w := label.x * k
		var top := rock.position.y + float(rock.call("radius_px")) + 10.0 * k
		items.append({"id": rock.get_instance_id(), "x": rock.position.x - w / 2.0, "w": w, "top": top, "h": label.y * k})
	items.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["top"]) < float(b["top"]))
	var placed: Array = []
	var shifts := {}
	var line := 18.0 * k
	for it in items:
		var rect := Rect2(float(it["x"]) - 4.0 * k, float(it["top"]), float(it["w"]) + 8.0 * k, float(it["h"]))
		var moved := 0.0
		var guard := 0
		var hit := true
		while hit and guard < 12:
			hit = false
			for p in placed:
				if rect.intersects(p):
					rect.position.y += line
					moved += line
					hit = true
					break
			guard += 1
		placed.append(rect)
		shifts[it["id"]] = moved / k
	return shifts


## Plain Alloy and Gas rocks: [[resource, amount], ...] shown as icons (Space).
## Silver and gold rocks have no label (what they hold is a surprise).
func _label_items() -> Array:
	if kind != "rock" and kind != "gas":
		return []
	var out: Array = []
	if yield_alloys > 0:
		out.append(["alloys", yield_alloys])
	if yield_gas > 0:
		out.append(["gas", yield_gas])
	return out


## Unscaled size of this rock's label, for keeping labels apart.
func label_size() -> Vector2:
	var items := _label_items()
	if not items.is_empty():
		return Vector2(items.size() * 34.0, 42.0)
	var text := _yield_text()
	if text == "":
		return Vector2.ZERO
	return Vector2(ThemeDB.fallback_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x, 18.0)


## What this rock is worth, shown while Info (Space) is held.
func _yield_text() -> String:
	var parts: Array = []
	if yield_alloys > 0:
		parts.append("%d ALLOY%s" % [yield_alloys, "S" if yield_alloys > 1 else ""])
	if yield_gas > 0:
		parts.append("%d GAS" % yield_gas)
	# Silver and gold rocks get no label at all: players find out what's inside.
	if kind == "silver" or kind == "gold":
		return ""
	return " · ".join(PackedStringArray(parts))


func _yield_colour() -> Color:
	if worked:
		return Color("3dd17a")
	if yield_alloys > 0:
		return Color("c79bff")
	if yield_gas > 0:
		return Color("8fd14f")
	if kind == "gold":
		return Color("e8c14a")
	return Color("c9ced6")
