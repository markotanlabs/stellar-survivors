extends Node
## While the game is paused, the info side of the game still works: click planets to open
## their panel, hold Space for info, and pan the camera to look around.
const FeedbackPanel = preload("res://scripts/feedback.gd")

var main: Node = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	if main == null or not get_tree().paused or FeedbackPanel.is_open:
		return
	main.call("_update_full_names")
	if bool(main.get("in_galaxy")):
		return
	# Xander's lessons pause the game too: no panning about while he's talking (v0.9.190).
	if bool(main.call("_xander_up")):
		return
	var dir := Input.get_vector("pan_left", "pan_right", "pan_up", "pan_down")
	dir += Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if dir != Vector2.ZERO:
		var camera: Camera2D = main.get("camera")
		camera.position += dir.limit_length(1.0) * 1400.0 * delta / camera.zoom.x
		main.call("_clamp_camera")


func _unhandled_input(event: InputEvent) -> void:
	if main == null or FeedbackPanel.is_open or not get_tree().paused or bool(main.get("in_galaxy")) or bool(main.call("_xander_up")):
		return
	var click := event as InputEventMouseButton
	if click == null or not click.pressed or click.button_index != MOUSE_BUTTON_LEFT:
		return
	var views: Array = main.get("system_views")
	var view: Node2D = views[int(main.get("current"))]
	var planet: Dictionary = view.call("planet_at", view.get_global_mouse_position())
	if not planet.is_empty():
		main.call("_on_planet_clicked", planet)
		get_viewport().set_input_as_handled()
