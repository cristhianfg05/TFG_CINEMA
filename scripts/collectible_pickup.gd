class_name CollectiblePickup
extends Area3D

@export var collectible_id := ""

@onready var visual_root: Node3D = $VisualRoot

var _collected := false


func _ready() -> void:
	add_to_group("collectible_pickup")
	var manager = get_tree().get_first_node_in_group("gameplay_manager")
	if manager == null:
		push_error("CollectiblePickup '%s' requiere GameplayManager." % name)
		_disable_invalid_pickup()
		return
	manager.collectible_found.connect(_on_collectible_found)
	if not manager.has_collectible_definition(collectible_id):
		push_error("CollectiblePickup '%s' usa un collectible_id desconocido: '%s'." % [name, collectible_id])
		_disable_invalid_pickup()
		return
	if manager.is_collectible_found(collectible_id):
		_collected = true
		queue_free()
		return
	var definition: Dictionary = manager.get_collectible_definition(collectible_id)
	var model_scene := definition.get("model_scene") as PackedScene
	if model_scene == null:
		push_error("La figura '%s' no tiene model_scene." % collectible_id)
		_disable_invalid_pickup()
		return
	var model := model_scene.instantiate() as Node3D
	model.name = "CollectibleModel"
	visual_root.add_child(model)
	# The imported figures are centred on their pivots and point up along Y.
	# Lay them on their backs without changing the artist-authored scale.
	model.rotation_degrees.x = -90.0
	model.position.y = -_lowest_visual_y(model) + 0.012


func _lowest_visual_y(model: Node3D) -> float:
	var minimum := INF
	for mesh_node in model.find_children("*", "MeshInstance3D", true, false):
		var instance := mesh_node as MeshInstance3D
		if instance.mesh == null:
			continue
		var bounds := instance.mesh.get_aabb()
		for corner in 8:
			var local_point := visual_root.to_local(instance.to_global(bounds.get_endpoint(corner)))
			minimum = minf(minimum, local_point.y)
	return 0.0 if minimum == INF else minimum


func get_interaction_prompt() -> String:
	return "" if _collected else "E — Recoger figura"


func interact(_player: Node) -> void:
	if _collected:
		return
	var manager = get_tree().get_first_node_in_group("gameplay_manager")
	if manager and manager.collect_collectible(collectible_id, self):
		_collected = true


func set_focused(_focused: bool) -> void:
	# The floor prop stays visually unchanged, even when it can be picked up.
	pass


func collect() -> void:
	_collected = true
	set_focused(false)
	collision_layer = 0
	collision_mask = 0
	queue_free()


func _on_collectible_found(found_collectible_id: String) -> void:
	if found_collectible_id == collectible_id and not _collected:
		collect()


func _disable_invalid_pickup() -> void:
	visible = false
	collision_layer = 0
	collision_mask = 0
