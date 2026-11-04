extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scenes/main/main.tscn") as PackedScene
	var main := packed.instantiate()
	root.add_child(main)
	await process_frame
	await physics_frame
	var manager = get_first_node_in_group("gameplay_manager")
	var upgrade_menu = get_first_node_in_group("upgrade_menu")
	var tool_shop = get_first_node_in_group("tool_shop_panel")
	var upgrade_tab_id: int = upgrade_menu._tab_bar.get_child(0).get_instance_id()
	var shop_card_id: int = tool_shop._cards.get_child(0).get_instance_id()
	manager.bag_capacity = 100
	var items := get_nodes_in_group("trash_item")
	var started := Time.get_ticks_usec()
	for index in 3:
		manager.try_collect(items[index], true)
	var elapsed_ms := float(Time.get_ticks_usec() - started) / 1000.0
	print("MULTI_PICKUP_CALLBACK_PROFILE " + JSON.stringify({
		"items": 3,
		"elapsed_ms": snappedf(elapsed_ms, 0.001),
		"hidden_upgrade_menu_rebuilt": upgrade_tab_id != upgrade_menu._tab_bar.get_child(0).get_instance_id(),
		"hidden_tool_shop_rebuilt": shop_card_id != tool_shop._cards.get_child(0).get_instance_id(),
	}))
	main.queue_free()
	await process_frame
	quit(0)
