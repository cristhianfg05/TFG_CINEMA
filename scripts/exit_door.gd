extends StaticBody3D

var is_open := false
var _closed_position: Vector3

@onready var mesh: MeshInstance3D = $Mesh
@onready var collision: CollisionShape3D = $Collision


func _ready() -> void:
	add_to_group("exit_door")
	_closed_position = position
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("2f6f68")
	material.roughness = 0.72
	mesh.material_override = material
	var manager = get_tree().get_first_node_in_group("gameplay_manager")
	if manager:
		manager.state_changed.connect(_update_state)
		_update_state()


func set_focused(focused: bool) -> void:
	if is_open:
		return
	var material := mesh.material_override as StandardMaterial3D
	material.emission_enabled = focused
	material.emission = Color("4fa99d")
	material.emission_energy_multiplier = 1.1


func get_interaction_prompt() -> String:
	var manager = get_tree().get_first_node_in_group("gameplay_manager")
	return manager.get_exit_requirement_text() if manager else "Salida"


func interact(_player: Node) -> void:
	var manager = get_tree().get_first_node_in_group("gameplay_manager")
	if manager:
		manager.explain_exit_requirements()


func _update_state() -> void:
	var manager = get_tree().get_first_node_in_group("gameplay_manager")
	if manager and manager.is_exit_unlocked():
		_open()


func _open() -> void:
	if is_open:
		return
	is_open = true
	collision.set_deferred("disabled", true)
	collision_layer = 0
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "position", _closed_position + Vector3.UP * 2.5, 0.8)
