class_name ArcadeMachine
extends StaticBody3D

@export var model_scene: PackedScene
@export var model_scale := Vector3.ONE
@export var model_rotation_degrees := Vector3.ZERO
@export var interaction_size := Vector3(1.04, 1.90, 1.16)
@export_range(1, 2) var arcade_index := 1
const MAX_INTERACTION_DISTANCE := 1.85
const VISIBILITY_DISCOVERY_SCRIPT := preload("res://scripts/arcade_visibility_discovery.gd")


func _ready() -> void:
	if model_scene == null:
		push_error("ArcadeMachine necesita el modelo 3D existente.")
		return
	var model := model_scene.instantiate() as Node3D
	model.name = "Model"
	model.scale = model_scale
	model.rotation_degrees = model_rotation_degrees
	add_child(model)
	var collision := CollisionShape3D.new()
	collision.name = "Collision"
	var shape := BoxShape3D.new()
	shape.size = interaction_size
	collision.shape = shape
	collision.position.y = interaction_size.y * 0.5
	add_child(collision)
	var discovery := VISIBILITY_DISCOVERY_SCRIPT.new()
	discovery.name = "ObjectiveVisibility"
	discovery.arcade_index = arcade_index
	add_child(discovery)


func get_interaction_prompt() -> String:
	if get_tree().paused or _has_open_modal() or not _player_is_close_enough():
		return ""
	return "[E] Jugar a El último acomodador" if arcade_index == 2 else "[E] Jugar a Rescata el carrete"


func interact(_player: Node) -> void:
	if _has_open_modal() or not _player_is_close_enough():
		return
	var group_name := "arcade_usher_minigame" if arcade_index == 2 else "arcade_minigame"
	var arcade := get_tree().get_first_node_in_group(group_name)
	if arcade and arcade.has_method("open_arcade"):
		arcade.open_arcade(self)


func set_focused(_focused: bool) -> void:
	pass


func _player_is_close_enough() -> bool:
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player == null:
		return false
	var offset := player.global_position - global_position
	return Vector2(offset.x, offset.z).length() <= MAX_INTERACTION_DISTANCE


func _has_open_modal() -> bool:
	var intro := get_tree().get_first_node_in_group("game_intro")
	if intro and intro.has_method("is_active") and intro.is_active():
		return true
	for group_name in ["arcade_minigame", "arcade_usher_minigame", "upgrade_menu", "tool_shop_panel", "pause_menu"]:
		var modal := get_tree().get_first_node_in_group(group_name)
		if modal and modal.has_method("is_open") and modal.is_open():
			return true
	return false
