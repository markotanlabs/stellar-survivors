extends Node2D
## Adds up small hits on one target over a short window, then pops one number with
## the total, so a Gatling stream reads as "48" instead of sixteen "3"s.

const GD = preload("res://scripts/game_data.gd")
const DamageNumber = preload("res://scripts/damage_number.gd")

var target: Node2D = null
var total := 0.0
var yours := true
var _left := GD.DAMAGE_TALLY


func add(amount: float) -> void:
	total += amount


func _process(delta: float) -> void:
	if is_instance_valid(target):
		position = target.position
	_left -= delta
	if _left > 0.0:
		return
	if is_instance_valid(target):
		target.remove_meta("tally")
	if total > 0.0 and is_visible_in_tree():
		var number := DamageNumber.new()
		get_parent().add_child(number)
		number.setup(position, total, yours)
	queue_free()
