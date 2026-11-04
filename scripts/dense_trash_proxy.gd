extends StaticBody3D

var registry: Node3D
var entry_index := -1
var definition: Resource
var room_id: StringName
var world_item_id := ""
var collecting := false
var _flight: Node3D

func _ready() -> void:
	add_to_group("trash_item")
	collision_layer = 18 # Interaction + local pile support, never player collision.
	collision_mask = 0

func get_room_id() -> StringName: return room_id
func get_world_item_id() -> String: return world_item_id
func get_interaction_prompt() -> String: return ""
func is_being_collected() -> bool: return collecting
func set_focused(value: bool) -> void: registry.tint(entry_index, Color("ffd36b") if value else Color.WHITE)
func set_all_seeing_revealed(_value: bool) -> void: pass

func collect_interact(player: Node) -> void:
	get_tree().get_first_node_in_group("gameplay_manager").request_collect(self, player)

func begin_collection(collector: Node3D, arrived: Callable) -> bool:
	if collecting:
		return false
	collecting = true
	collision_layer = 0
	registry.reserve(entry_index)
	_flight = definition.model.instantiate()
	_flight.scale = Vector3.ONE * float(definition.model_scale)
	_flight.rotation_degrees = definition.model_rotation_degrees
	add_child(_flight)
	var start := global_position
	var tween := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.tween_method(func(t: float):
		if is_instance_valid(collector):
			global_position = start.lerp(collector.global_position + Vector3.UP * 1.05, t * t)
			_flight.scale = Vector3.ONE * float(definition.model_scale) * lerpf(1.0,0.12,t), 0.0, 1.0, 0.28)
	tween.tween_callback(func():
		if arrived.is_valid(): arrived.call(self))
	return true

func collect() -> void:
	registry.remove_entry(entry_index)

func apply_vacuum_pull(target: Vector3, _acceleration: float, delta: float) -> bool:
	if collecting: return false
	registry.pull(entry_index, target, delta)
	return true
