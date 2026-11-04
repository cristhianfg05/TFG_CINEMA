extends StaticBody3D

var room_id: StringName
var lever_number: int
var controller: Node3D


func get_interaction_prompt() -> String:
	if controller == null:
		return ""
	return controller.get_lever_prompt(room_id, lever_number)


func interact(_player: Node) -> void:
	if controller != null:
		controller.try_raise_lever(room_id, lever_number)
