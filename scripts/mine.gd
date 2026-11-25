extends Node2D
## A proximity mine from the Kharkiv's Mine Layer. Arms after a second, then blows
## up when an enemy ship comes close, hurting every enemy ship in the blast.

const GD = preload("res://scripts/game_data.gd")
const Explosion = preload("res://scripts/explosion.gd")
const Sfx = preload("res://scripts/sfx.gd")
const BlinkFlash = preload("res://scripts/blink_flash.gd")

const ARM_TIME := 1.0
const TRIGGER := 10.0  # units: an enemy this close activates the mine
const LAUNCH_SPEED := 30.0   # units per second once it launches
const LAUNCH_ACCEL := 60.0
const BLAST := 5.0     # units

var damage := GD.MINE_DAMAGE
var _age := 0.0
var _done := false
var _chasing: Node2D = null
var _chase_left := 0.0
var _speed := 0.0
var _alert := 0.0


func setup(pos_px: Vector2, new_damage: float) -> void:
	position = pos_px
	damage = new_damage
	z_index = 2


func _process(delta: float) -> void:
	_age += delta
	queue_redraw()
	if _done or _age < ARM_TIME:
		return
	# Locked on: the mine flies at its target and blows up when it gets there.
	if _chasing != null:
		if not is_instance_valid(_chasing) or not (_chasing.get("alive") == true) or _chasing.get_parent() != get_parent():
			_chasing = null
		else:
			var to := _chasing.position - position
			_speed = minf(_speed + LAUNCH_ACCEL * delta, LAUNCH_SPEED)
			position += to.normalized() * minf(_speed * GD.UNIT * delta, to.length())
			_chase_left -= delta
			if to.length() <= 1.2 * GD.UNIT or _chase_left <= 0.0:
				detonate()
			return
	var view := get_parent()
	# Look 3 grid cells out (12+ units) so the whole 10-unit trigger range is covered.
	var nearby: Array = view.call("targets_near", position, 3) if view.has_method("targets_near") else get_tree().get_nodes_in_group("ships")
	for t in nearby:
		var ship := t as Node2D
		if ship == null or not ship.is_in_group("ships") or not (ship.get("alive") == true):
			continue
		if not GD.is_hostile(GD.Faction.UNE, int(ship.get("faction"))):
			continue
		if ship.position.distance_to(position) <= TRIGGER * GD.UNIT:
			# Activate: "!" and launch.
			_chasing = ship
			_chase_left = 2.5
			_alert = 0.6
			Sfx.play("blip", self, -6.0, 0.1)
			return


func detonate() -> void:
	if _done:
		return
	_done = true
	var view := get_parent()
	var nearby: Array = view.call("targets_near", position, 2) if view.has_method("targets_near") else get_tree().get_nodes_in_group("ships")
	for t in nearby:
		var ship := t as Node2D
		if ship == null or not ship.is_in_group("ships") or not (ship.get("alive") == true):
			continue
		if not GD.is_hostile(GD.Faction.UNE, int(ship.get("faction"))):
			continue
		if ship.position.distance_to(position) <= BLAST * GD.UNIT:
			ship.call("take_damage", damage, null)
			GD.damage_dealt += damage
	# A big blast: a fireball the size of the damage area plus a shock ring.
	var boom := Explosion.new()
	view.add_child(boom)
	boom.setup(position, BLAST * GD.UNIT * 1.4)
	for i in 3:
		var extra := Explosion.new()
		view.add_child(extra)
		extra.setup(position + Vector2.RIGHT.rotated(randf() * TAU) * BLAST * GD.UNIT * 0.4, BLAST * GD.UNIT * 0.7)
	var ring := BlinkFlash.new()
	view.add_child(ring)
	ring.setup(position, BLAST * GD.UNIT * 1.2, Color("ff8a3d"), 0.6)
	Sfx.play("explosion_large", self, -6.0)
	queue_free()


## Too many mines out: the oldest one just fizzles.
func fizzle() -> void:
	_done = true
	queue_free()


func _draw() -> void:
	var armed := _age >= ARM_TIME
	# A slow red pulse so mines read as live weapons, not debris.
	var pulse := 0.5 + 0.5 * sin(_age * 4.0)
	if armed:
		# A strong red glow: wide soft halo plus a bright inner ring.
		draw_circle(Vector2.ZERO, 22.0 + 6.0 * pulse, Color(1.0, 0.15, 0.15, 0.08 + 0.08 * pulse))
		draw_circle(Vector2.ZERO, 14.0 + 3.0 * pulse, Color(1.0, 0.2, 0.2, 0.22 + 0.18 * pulse))
	draw_circle(Vector2.ZERO, 6.0, Color("2b2f36"))
	draw_arc(Vector2.ZERO, 6.0, 0.0, TAU, 16, Color(0.9, 0.3, 0.3, 0.6 + 0.4 * pulse) if armed else Color("c9ced6"), 2.0)
	for i in 4:
		var spike := Vector2.RIGHT.rotated(TAU * i / 4.0 + 0.785 + (_age * 6.0 if _chasing != null else 0.0))
		draw_line(spike * 6.0, spike * 9.0, Color("c9ced6"), 2.0)
	draw_circle(Vector2.ZERO, 2.4, Color(1.0, 0.25 + 0.2 * pulse, 0.2) if armed else Color("e8c547"))
	if _chasing != null:
		# Activated: a red "!" over it, and a short flame trail.
		var font := ThemeDB.fallback_font
		var bang := 46
		var bw := font.get_string_size("!", HORIZONTAL_ALIGNMENT_LEFT, -1, bang).x
		draw_string_outline(font, Vector2(-bw / 2.0, -16), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, bang, 8, Color("0b0e14"))
		draw_string(font, Vector2(-bw / 2.0, -16), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, bang, Color("ff4d4d"))
		var back := -(_chasing.position - position).normalized() if is_instance_valid(_chasing) else Vector2.ZERO
		draw_line(back * 7.0, back * 16.0, Color(1.0, 0.6, 0.2, 0.8), 3.0)
