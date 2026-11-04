class_name ArcadeVisibilityDiscovery
extends Node3D

# One sensor per cabinet. A frustum check alone can reveal a machine through a
# wall, so the center of the cabinet must also be reached by a physics ray.
@export_range(1, 2) var arcade_index := 1
@export var reveal_distance := 18.0

var _elapsed := 0.0


func _physics_process(delta: float) -> void:
	_elapsed += delta
	if _elapsed < 0.2:
		return
	_elapsed = 0.0
	var manager := get_tree().get_first_node_in_group("gameplay_manager") as GameplayManager
	if manager == null or not manager.first_room_exit_seen:
		return
	if (arcade_index == 1 and manager.arcade_discovered) or (arcade_index == 2 and manager.second_arcade_discovered):
		set_physics_process(false)
		return
	if not _is_cabinet_visible():
		return
	if arcade_index == 1:
		manager.mark_arcade_discovered()
	else:
		manager.mark_second_arcade_discovered()
	set_physics_process(false)


func _is_cabinet_visible() -> bool:
	var player := get_tree().get_first_node_in_group("player") as PlayerController
	var cabinet := get_parent() as CollisionObject3D
	if player == null or cabinet == null or player.camera == null:
		return false
	var camera := player.camera
	var target := cabinet.global_position + Vector3.UP * 1.0
	if camera.global_position.distance_to(target) > reveal_distance or camera.is_position_behind(target):
		return false
	var screen_point := camera.unproject_position(target)
	if not camera.get_viewport().get_visible_rect().has_point(screen_point):
		return false
	var query := PhysicsRayQueryParameters3D.create(camera.global_position, target)
	query.exclude.append(player.get_rid())
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return not hit.is_empty() and hit.get("collider") == cabinet
