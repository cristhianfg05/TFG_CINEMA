extends SceneTree

const OUTPUT_DIR := "res://docs/pipeline/screenshots/document_sheet"
const SAVE_PATH := "res://.godot/document_sheet_visual_capture_save.json"


func _initialize() -> void:
	OS.set_environment("CINEMA_CLEANER_TEST_SAVE_PATH", SAVE_PATH)
	call_deferred("_run")


func _run() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	root.size = Vector2i(1280, 720)
	var main := (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await physics_frame
	main.get_node("GameIntro").complete_immediately()
	main.get_node("GameplayHUD").set_gameplay_hud_visible(false)
	var document: DocumentPickup
	for node in get_nodes_in_group("document_pickup"):
		if node.document_id == "Doc1":
			document = node as DocumentPickup
			break
	if document == null:
		push_error("Doc1 not found for visual capture")
		quit(1)
		return
	var camera := Camera3D.new()
	camera.fov = 60.0
	camera.far = 80.0
	main.add_child(camera)
	camera.current = true
	var target := document.global_position + Vector3(0.0, 0.025, 0.0)
	var angles := {
		"01_room_view": Vector3(0.55, 0.75, 0.85),
		"02_detail": Vector3(0.28, 0.42, 0.48),
	}
	for label in angles:
		camera.global_position = target + angles[label]
		camera.look_at(target)
		await create_timer(0.3).timeout
		await RenderingServer.frame_post_draw
		var output := ProjectSettings.globalize_path("%s/%s.png" % [OUTPUT_DIR, label])
		var image := root.get_texture().get_image()
		var error := image.save_png(output)
		print("DOCUMENT_SHEET_CAPTURE ", label, " size=", image.get_size(), " error=", error)
		if error != OK:
			quit(1)
			return
	main.queue_free()
	await process_frame
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	quit(0)
