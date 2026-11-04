extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scenes/main/main.tscn") as PackedScene
	var main := packed.instantiate()
	root.add_child(main)
	await process_frame
	# The collection page is prepared one row per frame while gameplay starts.
	# Eight frames are still shorter than the menu's 0.34 s opening animation.
	for frame_index in 8:
		await process_frame
	var upgrade_menu = get_first_node_in_group("upgrade_menu")
	upgrade_menu.open_menu()
	await process_frame

	var first := await _measure_switch(upgrade_menu, &"collection")
	await _measure_switch(upgrade_menu, &"vacuum")
	var repeated := await _measure_switch(upgrade_menu, &"collection")
	print("UPGRADE_TAB_PROFILE " + JSON.stringify({
		"first_collection_call_ms": first.call_ms,
		"first_collection_frame_ms": first.frame_ms,
		"repeated_collection_call_ms": repeated.call_ms,
		"repeated_collection_frame_ms": repeated.frame_ms,
	}))
	var worst_switch_call_ms := maxf(float(first.call_ms), float(repeated.call_ms))
	if worst_switch_call_ms > 16.0:
		push_error("Upgrade tab switch exceeded one frame of synchronous work: %.3f ms" % worst_switch_call_ms)
		main.queue_free()
		await process_frame
		quit(1)
		return
	print("UPGRADE_TAB_PROFILE_OK")
	main.queue_free()
	await process_frame
	quit(0)


func _measure_switch(upgrade_menu: Node, category: StringName) -> Dictionary:
	var started := Time.get_ticks_usec()
	upgrade_menu._select_category(category)
	var after_call := Time.get_ticks_usec()
	await process_frame
	var after_frame := Time.get_ticks_usec()
	return {
		"call_ms": snappedf(float(after_call - started) / 1000.0, 0.001),
		"frame_ms": snappedf(float(after_frame - started) / 1000.0, 0.001),
	}
