extends Node3D

var _manager: GameplayManager


func _ready() -> void:
	_manager = get_tree().get_first_node_in_group("gameplay_manager") as GameplayManager
	if _manager == null:
		push_error("ManagerHammerPickup requires GameplayManager")
		return
	_manager.state_changed.connect(_refresh)
	_refresh()


func get_interaction_prompt() -> String:
	if _manager == null or _manager.hammer_taken:
		return ""
	return "[E] Coger maza" if _manager.is_hammer_unlocked() else "Maza — limpia todo el cine al 100 %"


func interact(_player: Node) -> void:
	if _manager != null and _manager.take_hammer():
		var controller := get_tree().get_first_node_in_group("hammer_controller")
		if controller != null and controller.has_method("begin_pickup_sequence"):
			controller.begin_pickup_sequence()


func set_focused(_focused: bool) -> void:
	pass


func _refresh() -> void:
	visible = not _manager.hammer_taken
	var collider := get_node_or_null("InteractionBody/CollisionShape3D") as CollisionShape3D
	if collider != null:
		collider.disabled = _manager.hammer_taken
