class_name ProgressionShutter
extends Node3D

@export var access_id: StringName
@export var unlock_with_room_one := false
@export var required_clean_areas: Array[StringName] = []
@export var permanently_locked := false

var shutter: RollerShutterDoor


func _ready() -> void:
	add_to_group("cinema_access")
	for child in get_children():
		if child is RollerShutterDoor:
			shutter = child
			break
	if shutter == null:
		push_error("ProgressionShutter requires one RollerShutterDoor child")
		return
	var manager := get_tree().get_first_node_in_group("gameplay_manager")
	if manager and manager.has_signal("state_changed"):
		manager.state_changed.connect(_refresh_state)
	_refresh_state()


func open_door() -> void:
	if not permanently_locked and _is_unlocked():
		shutter.open_door()


func close_door() -> void:
	shutter.close_door()


func get_interaction_prompt() -> String:
	if shutter.is_animating():
		return ""
	if permanently_locked:
		return "Sala 2 — Próximamente"
	return "" if _is_unlocked() else "Acceso cerrado: falta limpieza"


func interact(_player: Node) -> void:
	if shutter.is_animating():
		return
	if _is_unlocked():
		open_door()


func set_focused(focused: bool) -> void:
	shutter.set_focused(focused and not shutter.is_open)


func _is_unlocked() -> bool:
	if permanently_locked:
		return false
	var manager := get_tree().get_first_node_in_group("gameplay_manager")
	if manager == null:
		return false
	if not required_clean_areas.is_empty():
		return manager.are_required_areas_clean(required_clean_areas, 95)
	return unlock_with_room_one and manager.room_completed


func _refresh_state() -> void:
	if _is_unlocked():
		open_door()
	else:
		close_door()
