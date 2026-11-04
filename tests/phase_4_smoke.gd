extends SceneTree

const CHARACTER_SCENES := {
	"manager": "res://scenes/characters/npc_manager.tscn",
	"man_fat": "res://scenes/characters/npc_man_fat.tscn",
	"popcorn": "res://scenes/characters/npc_popcorn.tscn",
	"young": "res://scenes/characters/npc_young.tscn",
}
const TRASH_IDS := ["ticket", "napkin", "cup", "bottle", "can", "straw", "popcorn", "bucket"]

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
		if asset_id == "manager":
			await _check_manager_rig(character)
		character.queue_free()
		await process_frame

	await _check_trash_models()

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
		_expect(get_nodes_in_group("manager_npc").is_empty(), "Manager must remain outside room one")
		_expect(get_nodes_in_group("spectator").is_empty(), "Removed spectators returned")
		var imported_trash := 0
		var player = get_first_node_in_group("player")
		for item in get_nodes_in_group("trash_item"):
			if item.has_method("get_room_id") and item.get_room_id() != &"room_01":
				continue
			if String(item.definition.id) in TRASH_IDS:
				imported_trash += 1
				_expect(item.has_node("Model"), "Production trash fell back to a primitive")
				var shape := item.get_node_or_null("Collision")
				_expect(shape != null and shape.get_parent() == item, "Prop collision is not on the gameplay body")
				_expect(player._resolve_interactable(item.get_node("InteractionArea")) == item, "Production prop aiming target did not resolve")
				var mesh := _first_mesh(item)
				if mesh:
					var original_material := mesh.material_override
					item.set_focused(true)
					_expect(mesh.material_overlay == null, "Production prop still uses a ghosting overlay")
					_expect(mesh.material_override != original_material, "Production prop does not highlight")
					var focused_material := mesh.material_override as StandardMaterial3D
					_expect(
						focused_material != null and focused_material.emission_enabled,
						"Production prop highlight has no emission"
					)
					item.set_focused(false)
					_expect(mesh.material_override == original_material, "Production prop material did not restore")
		_expect(imported_trash == 400, "All 400 trash instances must use source production props")
		gameplay.queue_free()
		await process_frame

	_finish()


func _check_trash_models() -> void:
	for asset_id in TRASH_IDS:
		var definition = load("res://resources/trash/%s.tres" % asset_id)
		_expect(definition != null and definition.model != null, "%s has no production model" % asset_id)
		if definition == null or definition.model == null:
			continue
		var prop: Node3D = definition.model.instantiate()
		root.add_child(prop)
		await process_frame
		_expect(_count_triangles(prop) <= 800, "%s exceeds the trash triangle budget" % asset_id)
		_expect(_count_meshes(prop) >= 1 and _count_surfaces(prop) >= 1, "%s has no imported mesh/material" % asset_id)
		var mesh := _first_mesh(prop)
		if mesh:
			_expect(mesh.mesh is ArrayMesh, "%s still uses a primitive" % asset_id)
		prop.queue_free()
		await process_frame


func _first_mesh(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node
	for child in node.get_children():
		var found := _first_mesh(child)
		if found:
			return found
	return null


func _check_manager_rig(character: Node) -> void:
	var skeletons := character.find_children("*", "Skeleton3D", true, false)
	var players := character.find_children("*", "AnimationPlayer", true, false)
	_expect(skeletons.size() == 1 and players.size() == 1, "Manager rig/animation player is missing")
	if skeletons.is_empty() or players.is_empty():
		return
	var skeleton := skeletons[0] as Skeleton3D
	var player := players[0] as AnimationPlayer
	_expect(skeleton.get_bone_count() == 23, "Manager humanoid hierarchy changed")
	var map: BoneMap = character.humanoid_bone_map
	_expect(map != null and map.profile is SkeletonProfileHumanoid, "Manager has no humanoid bone map")
	for i in skeleton.get_bone_count():
		var bone_name := skeleton.get_bone_name(i)
		_expect(map != null and map.get_skeleton_bone_name(bone_name) == bone_name, "Unmapped manager bone: %s" % bone_name)
	_expect(player.is_playing(), "Manager idle did not autoplay")
	_expect(player.has_animation("Manager_HeadIdle"), "Manager idle clip is missing")
	if not player.has_animation("Manager_HeadIdle"):
		return
	var animation := player.get_animation("Manager_HeadIdle")
	_expect(animation.loop_mode == Animation.LOOP_LINEAR, "Manager idle is not looped")
	_expect(is_equal_approx(animation.length, 6.0), "Manager idle duration changed")
	var head := skeleton.find_bone("Head")
	var foot := skeleton.find_bone("LeftFoot")
	player.seek(0.0, true)
	var first_head := skeleton.get_bone_pose_rotation(head)
	var first_foot := skeleton.get_bone_pose_rotation(foot)
	player.seek(1.5, true)
	_expect(not skeleton.get_bone_pose_rotation(head).is_equal_approx(first_head), "Head remains static")
	_expect(skeleton.get_bone_pose_rotation(foot).is_equal_approx(first_foot), "Head idle unexpectedly animates feet")
	player.seek(animation.length, true)
	_expect(skeleton.get_bone_pose_rotation(head).is_equal_approx(first_head), "Head idle has a discontinuity at the loop seam")
	player.seek(0.0, true)


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
