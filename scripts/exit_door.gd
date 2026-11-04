extends Node3D

var is_open: bool:
	get:
		return shutter.is_open if shutter else false

var door_panel: StaticBody3D:
	get:
		return shutter.door_panel if shutter else null

@onready var shutter: RollerShutterDoor = $RollerShutterDoor


func _ready() -> void:
	add_to_group("exit_door")
	# The Tutorial exit must physically begin closed even when the profile has
	# completed an earlier run. Its state is then driven by this run's cleanup.
	close_door()
	var manager = get_tree().get_first_node_in_group("gameplay_manager")
	if manager:
		manager.state_changed.connect(_update_state)
		_update_state()


func open_door() -> void:
	set_focused(false)
	shutter.open_door()


func close_door() -> void:
	shutter.close_door()


func _open() -> void:
	# Compatibility with Room 1's existing progression adapter.
	open_door()


func _update_state() -> void:
	var manager = get_tree().get_first_node_in_group("gameplay_manager")
	if manager and manager.is_exit_unlocked():
		open_door()
	else:
		close_door()


func set_focused(focused: bool) -> void:
	if shutter:
		shutter.set_focused(focused and not is_open)


func get_interaction_prompt() -> String:
	var manager = get_tree().get_first_node_in_group("gameplay_manager")
	return manager.get_exit_requirement_text() if manager else "Salida"


func interact(_player: Node) -> void:
	var manager = get_tree().get_first_node_in_group("gameplay_manager")
	if manager:
		manager.explain_exit_requirements()
