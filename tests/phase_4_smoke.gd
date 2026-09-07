extends SceneTree

const CHARACTER_SCENES := {
	"manager": "res://scenes/characters/npc_manager.tscn",
	"man_fat": "res://scenes/characters/npc_man_fat.tscn",
	"popcorn": "res://scenes/characters/npc_popcorn.tscn",
	"young": "res://scenes/characters/npc_young.tscn",
}

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for asset_id in CHARACTER_SCENES:
		var scene_path: String = CHARACTER_SCENES[asset_id]
		var packed := load(scene_path) as PackedScene
		_expect(packed != null, "%s container failed to load" % asset_id)
		if packed == null:
			continue

		var character := packed.instantiate()
		root.add_child(character)
		await process_frame
		_expect(character.is_in_group("phase_4_character"), "%s is missing the pipeline group" % asset_id)
		_expect(_count_meshes(character) == 1, "%s must contain exactly one imported mesh" % asset_id)
		_expect(_count_triangles(character) <= 15000, "%s exceeds the 15k triangle budget" % asset_id)
		_expect(_count_surfaces(character) == 1, "%s must use one material surface" % asset_id)
		var collision := _find_collision(character)
		_expect(collision != null, "%s is missing its simple collision" % asset_id)
		_expect(collision == null or collision.shape is CapsuleShape3D, "%s collision is not a capsule" % asset_id)
		character.queue_free()
		await process_frame

	var showcase_scene := load("res://scenes/art/phase_4_character_showcase.tscn") as PackedScene
	_expect(showcase_scene != null, "Phase 4 showcase failed to load")
	if showcase_scene:
		var showcase := showcase_scene.instantiate()
		root.add_child(showcase)
		await process_frame
		_expect(get_nodes_in_group("phase_4_character").size() == 4, "Showcase must contain the four imported characters")
		showcase.queue_free()
		await process_frame

	var gameplay_scene := load("res://scenes/main/main.tscn") as PackedScene
	_expect(gameplay_scene != null, "Gameplay scene failed to load after the manager swap")
	if gameplay_scene:
		var gameplay := gameplay_scene.instantiate()
		root.add_child(gameplay)
		await process_frame
		await physics_frame
		var manager = get_first_node_in_group("manager_npc")
		_expect(manager != null, "Functional manager is missing")
		_expect(manager == null or manager.name == "Manager", "Gameplay still uses the manager placeholder")
		_expect(manager == null or manager.has_node("Character/Model"), "Manager does not contain the imported character")
		_expect(get_nodes_in_group("spectator").size() == 2, "Existing spectator logic changed during the art swap")
		gameplay.queue_free()
		await process_frame

	_finish()


func _count_meshes(node: Node) -> int:
	var count := 1 if node is MeshInstance3D and node.mesh != null else 0
	for child in node.get_children():
		count += _count_meshes(child)
	return count


func _count_triangles(node: Node) -> int:
	var count := 0
	if node is MeshInstance3D and node.mesh != null:
		for surface_index in node.mesh.get_surface_count():
			var indices: int = node.mesh.surface_get_array_index_len(surface_index)
			count += int(indices / 3) if indices > 0 else int(node.mesh.surface_get_array_len(surface_index) / 3)
	for child in node.get_children():
		count += _count_triangles(child)
	return count


func _count_surfaces(node: Node) -> int:
	var count: int = node.mesh.get_surface_count() if node is MeshInstance3D and node.mesh != null else 0
	for child in node.get_children():
		count += _count_surfaces(child)
	return count


func _find_collision(node: Node) -> CollisionShape3D:
	if node is CollisionShape3D:
		return node
	for child in node.get_children():
		var found := _find_collision(child)
		if found:
			return found
	return null


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
		push_error(message)


func _finish() -> void:
	if _failures.is_empty():
		print("PHASE_4_SMOKE_OK")
		quit(0)
	else:
		print("PHASE_4_SMOKE_FAILED: %s" % ", ".join(_failures))
		quit(1)
