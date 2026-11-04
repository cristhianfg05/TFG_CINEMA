extends Node3D

# Safe visual sandbox: no writes to the user's real saved game.
var main: Node3D
var manager: GameplayManager

func _ready() -> void:
	OS.set_environment("CINEMA_CLEANER_TEST_SAVE_PATH","res://.godot/incremental_visual_sandbox.json")
	var path := "res://.godot/incremental_visual_sandbox.json"
	if FileAccess.file_exists(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	main = load("res://scenes/main/main.tscn").instantiate()
	add_child(main)
	for frame in 8: await get_tree().physics_frame
	manager = main.get_node("GameplayManager")
	main.get_node("GameIntro").complete_immediately()
	manager.purchased_tools["broom"] = true
	manager.purchased_tools["vacuum"] = true
	manager.upgrade_levels["quick_hands"] = 1
	manager.coins = 2000
	manager._apply_upgrades()
	set_view("room1")
	manager.equip_tool(&"broom")
	print("INCREMENTAL_VISUAL_READY")
	if "--capture" in OS.get_cmdline_user_args():
		_capture_views()

func _capture_views() -> void:
	var samples: Array[Dictionary] = []
	for view in ["room1","room2","room3","room4","lobby","office"]:
		set_view(view)
		for frame in 90: await get_tree().physics_frame
		var times: Array[float] = []
		var registry := manager.get_dense_registry()
		var physics_start: int = registry.profile_total_usec
		var ticks_start: int = registry.profile_ticks
		var started := Time.get_ticks_usec()
		var last_frame := started
		for frame in 90:
			await get_tree().process_frame
			var now := Time.get_ticks_usec()
			times.append(float(now-last_frame)/1000000.0)
			last_frame=now
		var measured := metrics()
		measured["wall_fps"] = 90000000.0/float(last_frame-started)
		measured["trash_registry_cpu_ms"] = float(registry.profile_total_usec-physics_start)/maxi(1,registry.profile_ticks-ticks_start)/1000.0
		await RenderingServer.frame_post_draw
		var image := get_viewport().get_texture().get_image()
		image.save_png("res://.godot/incremental_%s.png" % view)
		times.sort()
		measured["median_frame_ms"] = times[times.size()/2]*1000.0
		measured["p95_frame_ms"] = times[int(times.size()*.95)]*1000.0
		samples.append({"view":view,"metrics":measured})
	print("INCREMENTAL_VISUAL_METRICS ",JSON.stringify(samples))
	var file := FileAccess.open("res://.godot/incremental_visual_metrics.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(samples,"\t"))
	file.close()
	var menu := main.get_node("UpgradeMenu") as UpgradeMenu
	menu.open_menu(&"abilities")
	menu._select_category(&"broom")
	for frame in 45: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.godot/incremental_broom_upgrades.png")
	menu.close_menu()
	manager.purchased_tools.erase("broom")
	var shop := main.get_node("ToolShopPanel") as ToolShopPanel
	shop.open_tool(&"broom")
	for frame in 45: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.godot/incremental_broom_shop.png")
	shop.close_shop()
	main.queue_free()
	for frame in 5: await get_tree().process_frame
	# Static cursor textures otherwise outlive RenderingServer in CLI captures.
	Input.set_custom_mouse_cursor(null,Input.CURSOR_ARROW)
	Input.set_custom_mouse_cursor(null,Input.CURSOR_POINTING_HAND)
	PointerTheme._default_cursor=null
	PointerTheme._clickable_cursor=null
	get_tree().quit()

func set_view(view: String) -> void:
	var player := main.get_node("Player") as PlayerController
	if player.is_sitting(): player.stand_up_from_cinema_seat()
	player.complete_game_intro_immediately()
	player.velocity = Vector3.ZERO
	var position := Vector3(0,0.2,2.0)
	var yaw := 0.0
	var room: StringName = &"room_01"
	match view:
		"room2":
			position = Vector3(25.5,1.5,42)
			yaw = PI
			room = &"room_02"
		"lobby":
			position = Vector3(14.7,0.2,5)
			room = &"lobby"
		"room3":
			position = Vector3(-9.375,1.0,37)
			yaw = PI
			room = &"room_03"
		"room4":
			position = Vector3(27.9,1.8,2.0)
			room = &"room_04"
		"office":
			position = Vector3(-16.3,0.2,16.7)
			yaw = deg_to_rad(145)
			room = &"manager_office"
	player.global_position = position
	player.rotation.y = yaw
	player.head.rotation.x = deg_to_rad(-27)
	player.set_current_room_id(room)

func metrics() -> Dictionary:
	var registry := manager.get_dense_registry()
	return {"entries":registry.entries.size(),"proxies":registry.proxies.size(),"active_bodies":registry.bodies.size(),
		"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		"fps":Engine.get_frames_per_second(),"nodes":Performance.get_monitor(Performance.OBJECT_NODE_COUNT)}
