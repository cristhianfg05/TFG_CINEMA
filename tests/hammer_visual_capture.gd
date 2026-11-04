extends SceneTree

const SAVE_PATH := "res://.godot/hammer_visual_capture_save.json"


func _initialize() -> void:
	OS.set_environment("CINEMA_CLEANER_TEST_SAVE_PATH", SAVE_PATH)
	call_deferred("_run")


func _run() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	root.size = Vector2i(1920, 1080)
	var main := (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	main.get_node("GameIntro").complete_immediately()
	var manager := main.get_node("GameplayManager") as GameplayManager
	var player := main.get_node("Player") as PlayerController
	var pickup := main.get_node("LeftWingBlockout/ManagerHammerPickup")
	var wall := main.get_node("CinemaExpansionBlockout/FutureFinalRoomBrickBarrier")
	var inspection := Camera3D.new()
	inspection.fov = 60.0
	main.add_child(inspection)
	inspection.global_position = Vector3(-15.75, 1.65, 22.7)
	inspection.look_at(Vector3(-18.6, 0.45, 22.7))
	inspection.current = true
	await _capture("hammer_manager")
	for area in manager.HAMMER_REQUIRED_AREAS:
		manager.room_trash_remaining[String(area)] = 0
	manager.remaining_trash = 0
	manager.state_changed.emit()
	player.global_position = Vector3(-15.75, 0.15, 22.7)
	player.rotation.y = PI * 0.5
	player.reset_camera_interpolation()
	player.camera.current = true
	pickup.interact(player)
	await create_timer(0.32, true).timeout
	await _capture("hammer_pickup_lift", 2)
	await create_timer(0.56, true).timeout
	await _capture("hammer_pickup_inspect", 2)
	await create_timer(1.15, true).timeout
	player.global_position = Vector3(34.3, 0.15, 20.0)
	player.rotation.y = -PI * 0.5
	player.reset_camera_interpolation()
	await _capture("hammer_held")
	wall.hit_wall(Vector3(36.85, 0.75, 19.0))
	wall.hit_wall(Vector3(36.85, 1.45, 21.0))
	wall.hit_wall(Vector3(36.85, 1.85, 20.0))
	await _capture("hammer_wall_fractured")
	await create_timer(0.7, true).timeout
	await _capture("hammer_wall_settled")
	wall.hit_wall(Vector3(36.85, 1.4, 20.0))
	await create_timer(0.48, true).timeout
	await _capture("hammer_walk_to_wall", 2)
	await create_timer(0.83, true).timeout
	await _capture("hammer_gentle_release", 2)
	await create_timer(1.08, true).timeout
	await _capture("hammer_wall_open")
	inspection.global_position = Vector3(34.8, 1.5, 18.5)
	inspection.look_at(Vector3(36.55, 0.75, 16.0))
	inspection.current = true
	await _capture("hammer_left_on_wall")
	main.queue_free()
	await process_frame
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	quit(0)


func _capture(name: String, settle_frames: int = 8) -> void:
	for frame in settle_frames:
		await process_frame
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path("res://.godot/%s.png" % name)
	var error := root.get_texture().get_image().save_png(path)
	print("HAMMER_CAPTURE ", name, " error=", error)
