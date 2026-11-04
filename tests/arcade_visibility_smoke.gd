extends SceneTree

const SAVE_PATH := "res://.godot/arcade_visibility_smoke_save.json"

var failures: Array[String] = []


func _initialize() -> void:
	OS.set_environment("CINEMA_CLEANER_TEST_SAVE_PATH", SAVE_PATH)
	call_deferred("_run")


func _run() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	var main := (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await physics_frame
	main.get_node("GameIntro").complete_immediately()
	var manager := main.get_node("GameplayManager") as GameplayManager
	var player := main.get_node("Player") as PlayerController
	manager.first_room_exit_seen = true
	var first := main.get_node("LeftWingBlockout/FutureArcadeMachine") as CollisionObject3D
	var second := main.get_node("CinemaExpansionBlockout/LeftCorridorArcade") as CollisionObject3D
	_expect(not manager.arcade_discovered and not manager.second_arcade_discovered, "Arcades were discovered before appearing in camera")
	player.camera.look_at(first.global_position + Vector3.UP)
	_expect(not first.get_node("ObjectiveVisibility")._is_cabinet_visible(), "First arcade was revealed through auditorium walls")
	player.set_physics_process(false)
	for cabinet in [first, second]:
		var sensor := cabinet.get_node("ObjectiveVisibility") as ArcadeVisibilityDiscovery
		player.global_position = cabinet.global_position + Vector3(0.0, 0.0, -3.0)
		player.velocity = Vector3.ZERO
		await physics_frame
		player.reset_camera_interpolation()
		player.camera.look_at(player.camera.global_position + Vector3.FORWARD)
		_expect(not sensor._is_cabinet_visible(), "%s revealed while the camera faced away" % cabinet.name)
		player.camera.look_at(cabinet.global_position + Vector3.UP)
		_expect(sensor._is_cabinet_visible(), "%s did not register in the camera with clear line of sight" % cabinet.name)
		sensor._physics_process(0.21)
	_expect(manager.arcade_discovered and manager.second_arcade_discovered, "Looking at both cabinets did not reveal both objectives")
	main.queue_free()
	await process_frame
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	if failures.is_empty():
		print("ARCADE_VISIBILITY_SMOKE_OK")
		quit(0)
	else:
		print("ARCADE_VISIBILITY_SMOKE_FAILED: " + ", ".join(failures))
		quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)
