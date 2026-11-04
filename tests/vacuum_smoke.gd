extends SceneTree

const SAVE_PATH := "res://.godot/vacuum_smoke_save.json"

var failures: Array[String] = []


func _initialize() -> void:
	OS.set_environment("CINEMA_CLEANER_TEST_SAVE_PATH", SAVE_PATH)
	call_deferred("_run")


func _run() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	var packed := load("res://scenes/main/main.tscn") as PackedScene
	var main := packed.instantiate()
	root.add_child(main)
	await process_frame
	await physics_frame
	var manager = get_first_node_in_group("gameplay_manager")
	var player = get_first_node_in_group("player")
	var hud = get_first_node_in_group("gameplay_hud")
	_expect(manager != null and player != null and hud != null, "Vacuum integration dependencies are missing")
	manager.coins = 999999
	_expect(manager.purchase_tool(&"vacuum"), "Vacuum could not be purchased")
	for branch_id in [&"vacuum_reach", &"vacuum_battery", &"vacuum_recharge"]:
		for level in 4:
			_expect(manager.purchase_upgrade(branch_id), "Vacuum upgrade failed: %s level %d" % [branch_id, level + 1])
	_expect(is_equal_approx(manager.vacuum_reach, 4.0), "Maximum vacuum reach was not applied")
	_expect(is_equal_approx(manager.vacuum_battery, 40.0), "Maximum vacuum battery was not applied")
	_expect(is_equal_approx(manager.vacuum_recharge, 4.0), "Maximum vacuum recharge was not applied")
	hud._update_vacuum_hud(0.0)
	_expect(hud._vacuum_view_container.visible, "Equipped vacuum HUD viewport is hidden: %s" % manager.get_vacuum_state())
	_expect(hud._vacuum_view_root.get_node_or_null("AxisCorrection/Model") != null, "Vacuum HUD viewport does not contain the supplied model")
	_expect(is_equal_approx(hud._tool_slots.anchor_left, 0.5) and is_equal_approx(hud._tool_slots.anchor_right, 0.5), "Tool selector is not centered")
	_expect(hud._sprint_bar.position.y < hud._tool_slots.position.y, "Sprint bar is not above the tool selector")
	_expect(hud._tool_slots.position.y + hud._tool_slots.size.y <= hud._vacuum_battery_gauge.position.y - 2.0, "Tool selector overlaps the vacuum battery gauge")
	_expect(hud._vacuum_battery_gauge.position.x > 0.0 and hud._vacuum_battery_gauge.size.x < 150.0, "Vacuum battery is not aligned below the vacuum tool card")
	_expect(hud._vacuum_battery_bar.size.x > hud._vacuum_battery_bar.size.y * 6.0, "Vacuum battery is not a horizontal bar")
	_expect(hud._vacuum_view_container.anchor_left == 0.0 and hud._vacuum_view_root.position.x > 0.5 and absf(hud._vacuum_view_root.rotation_degrees.z) < 14.0 and hud._vacuum_viewport.get_camera_3d().fov >= 40.0, "Vacuum view is not framed as a forward-held tool")
	_expect(hud._vacuum_view_root.get_node("AxisCorrection").rotation_degrees.is_equal_approx(Vector3(0.0, -90.0, 0.0)), "The GLB nozzle axis is not corrected toward the camera forward axis")
	_expect(hud.VACUUM_VIEWMODEL_SCALE < 2.2 and hud.VACUUM_VIEWMODEL_SCALE > 1.9 and hud.VACUUM_VIEWMODEL_IDLE_ROTATION.x > 0.0, "Vacuum should be slightly smaller and tilted upward")
	_expect(hud._vacuum_wind_streaks.size() == 24 and hud._vacuum_nozzle_anchor != null, "The nozzle-attached gray airflow is missing")
	_expect(hud._vacuum_wind_streaks[0].mesh is ArrayMesh and hud._vacuum_wind_streaks[0].material_override.vertex_color_use_as_albedo, "Airflow must use tapered translucent ribbons, not rigid quads")
	_expect(hud._vacuum_view_container.anchor_left == 0.0 and hud._vacuum_view_container.anchor_right == 1.0, "Vacuum viewport can still crop the view instead of covering the full screen")

	var item = null
	for candidate in get_nodes_in_group("trash_item"):
		if candidate.get_room_id() == &"room_01":
			item = candidate
			break
	_expect(item != null, "Room 1 has no trash for the vacuum test")
	item.global_position = player.camera.global_position - player.camera.global_basis.z * 2.0 + Vector3.DOWN * 0.28
	item.linear_velocity = Vector3.ZERO
	manager.bag_volume = manager.bag_capacity
	var charge_before := float(manager.get_vacuum_state().charge)
	manager.set_vacuum_trigger_held(true)
	manager._update_vacuum(0.25)
	hud._update_vacuum_hud(0.0)
	_expect(manager.get_vacuum_state().active, "Holding primary action did not activate the vacuum")
	_expect(float(manager.get_vacuum_state().charge) < charge_before, "Vacuum battery did not drain")
	_expect(is_instance_valid(item) and item.linear_velocity.length() > 0.01, "A full bag stopped physical suction")
	_expect(hud._vacuum_battery_gauge.visible and hud._vacuum_battery_bar.value < 100.0 and hud._vacuum_wind_root.visible, "Horizontal battery bar or inward wind feedback is missing")

	manager.set_vacuum_trigger_held(false)
	var drained_charge := float(manager.get_vacuum_state().charge)
	manager._update_vacuum(0.5)
	_expect(not manager.get_vacuum_state().active, "Vacuum kept attracting after releasing primary action")
	_expect(float(manager.get_vacuum_state().charge) > drained_charge, "Vacuum battery did not recharge while idle")

	manager.bag_volume = 0
	manager._reserved_bag_units = 0
	var units := int(item.definition.size_units)
	item.global_position = player.camera.global_position - player.camera.global_basis.z * 0.65 + Vector3.DOWN * 0.10
	manager.set_vacuum_trigger_held(true)
	manager._update_vacuum(0.05)
	await create_timer(0.38).timeout
	_expect(manager.bag_volume >= units, "A fitting item did not enter the bag: bag=%d expected-at-least=%d" % [manager.bag_volume, units])
	_expect(not is_instance_valid(item) or item.is_queued_for_deletion(), "Captured vacuum item was not removed from the world")
	manager.set_vacuum_trigger_held(false)

	var wind_stream := manager.vacuum_audio.stream as AudioStreamWAV
	_expect(wind_stream != null and wind_stream.loop_mode == AudioStreamWAV.LOOP_FORWARD and wind_stream.resource_path.is_empty(), "Approved suction must be a looping per-instance WAV")
	_expect(manager.vacuum_transition_audio.stream != null and manager.vacuum_transition_audio.stream.resource_path.ends_with("vacuum_start_01_half.wav") and manager.vacuum_transition_audio.stream.get_length() < 0.63, "Start and end must share the half-length start 01")
	_expect(wind_stream != null and wind_stream.get_length() < 3.6, "Suction should only loop the steady body of candidate 03")
	_expect(manager.vacuum_audio.bus == &"Tools" and manager.vacuum_transition_audio.bus == &"Tools", "Vacuum audio must use the Tools bus")
	main.queue_free()
	await process_frame
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	if failures.is_empty():
		print("VACUUM_SMOKE_OK")
		quit(0)
	else:
		print("VACUUM_SMOKE_FAILED: " + ", ".join(failures))
		quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)
