extends SceneTree

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var arcade := ArcadeReelRescue.new()
	root.add_child(arcade)
	await process_frame
	arcade._screen.visible = true
	arcade._mode = ArcadeReelRescue.Mode.MENU
	await _capture("menu")
	arcade._menu_selection = 2
	await _capture("menu_long")
	arcade._menu_selection = 0
	arcade._mode = ArcadeReelRescue.Mode.HOW_TO
	await _capture("how_to")
	arcade._start_run(0)
	arcade._stage_banner_time = 0.0
	arcade._defects = [
		{"lane": 0, "y": 92.0, "kind": 0, "bonus": false},
		{"lane": 2, "y": 118.0, "kind": 1, "bonus": true},
	]
	await _capture("gameplay")
	arcade._mode = ArcadeReelRescue.Mode.VICTORY
	arcade._feedback = "CARTEL DESBLOQUEADO"
	await _capture("victory")
	arcade._mode = ArcadeReelRescue.Mode.DEFEAT
	arcade._feedback = "SE ACABÓ LA FUNCIÓN"
	arcade._defeat_selection = 1
	await _capture("defeat")
	arcade._screen.visible = false
	arcade.queue_free()
	await process_frame
	quit(0)


func _capture(label: String) -> void:
	for frame in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var path := ProjectSettings.globalize_path("res://.godot/arcade_visual_%s.png" % label)
	var result := image.save_png(path)
	print("ARCADE_VISUAL ", label, " ", image.get_size(), " ", result)
