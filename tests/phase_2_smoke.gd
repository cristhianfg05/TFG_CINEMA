extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_expect(InputMap.has_action("debug_reset"), "Missing debug reset input")
	_expect(InputMap.has_action("collect_item"), "Missing right-click collection input")
	var has_right_click := false
	for input_event in InputMap.action_get_events("collect_item"):
		if input_event is InputEventMouseButton and input_event.button_index == MOUSE_BUTTON_RIGHT:
			has_right_click = true
	_expect(has_right_click, "Collection input is not bound to the right mouse button")
	var scene := load("res://scenes/main/main.tscn") as PackedScene
	_expect(scene != null, "Main scene failed to load")
	if scene == null:
		_finish()
		return
	var main := scene.instantiate()
	root.add_child(main)
	await process_frame
	await physics_frame

	var manager = get_first_node_in_group("gameplay_manager")
	var trash_bin = get_first_node_in_group("trash_bin")
	var hud = get_first_node_in_group("gameplay_hud")
	var player = get_first_node_in_group("player")
	_expect(manager != null, "Gameplay manager is missing")
	_expect(trash_bin != null, "Trash bin is missing")
	_expect(hud != null, "Gameplay HUD is missing")
	_expect(get_nodes_in_group("trash_item").size() == 20, "Expected 20 trash items")
	if player:
		var interaction_raycast := player.get_node("Head/Camera3D/InteractionRayCast3D") as RayCast3D
		_expect(interaction_raycast.collide_with_areas, "Interaction raycast ignores aiming spheres")
		_expect(interaction_raycast.collision_mask & 2 != 0, "Interaction raycast cannot see trash aiming layer")
	if hud:
		var hud_root := hud.get_node_or_null("HUDRoot") as Control
		_expect(hud_root != null, "Gameplay HUD root is missing")
		if hud_root:
			_expect_hud_ignores_mouse(hud_root)
	if player:
		var yaw_before: float = player.rotation.y
		player._apply_mouse_look(Vector2(40.0, 0.0))
		_expect(
			not is_equal_approx(player.rotation.y, yaw_before),
			"Mouse look did not rotate the player"
		)
	if manager:
		_expect(manager.total_trash == 20, "Total trash count is incorrect")
		_expect(manager.remaining_trash == 20, "Initial remaining count is incorrect")
		_expect(manager.get_clean_percent() == 0, "Initial clean percentage is not zero")
		_expect(is_equal_approx(manager.bag_capacity, 10.0), "Initial bag capacity is not 10")
		_expect(manager.pickup_audio.stream is AudioStreamWAV, "Pickup sound was not generated")
		_expect(manager.empty_audio.stream is AudioStreamWAV, "Emptying sound was not generated")
		var initial_item = get_nodes_in_group("trash_item")[0]
		_expect(
			String(initial_item.get_interaction_prompt()).begins_with("Clic derecho — Recoger"),
			"Valid trash does not expose the pickup prompt"
		)
		var focus_collision := initial_item.get_node_or_null(
			"InteractionArea/FocusRadius"
		) as CollisionShape3D
		_expect(focus_collision != null, "Trash item has no enlarged aiming radius")
		if focus_collision:
			var focus_sphere := focus_collision.shape as SphereShape3D
			_expect(focus_sphere != null, "Trash aiming target is not spherical")
			if focus_sphere:
				_expect(focus_sphere.radius <= 0.31, "Trash aiming sphere is still too large")

		var collected_before_full := 0
		var rejected_item: Node = null
		for item in get_nodes_in_group("trash_item"):
			if manager.try_collect(item, true):
				collected_before_full += 1
			elif rejected_item == null:
				rejected_item = item
			_expect(manager.bag_volume <= manager.bag_capacity + 0.0001, "Bag exceeded capacity")
		await process_frame
		_expect(collected_before_full < 20, "Bag never reached a capacity limit")
		_expect(rejected_item != null, "No item was rejected when the bag filled")
		if rejected_item:
			_expect(
				rejected_item.get_interaction_prompt() == "Bolsa llena — vacíala en el contenedor",
				"Full bag prompt is incorrect"
			)
		_expect(trash_bin.get_interaction_prompt() == "E — Vaciar bolsa", "Bin prompt is missing")
		var coins_before_empty: int = manager.coins
		_expect(manager.empty_bag(), "Non-empty bag could not be emptied")
		_expect(manager.coins > coins_before_empty, "Emptying did not award coins")
		_expect(is_zero_approx(manager.bag_volume), "Bag volume did not reset")
		var coins_after_empty: int = manager.coins
		_expect(not manager.empty_bag(), "Empty bag was accepted twice")
		_expect(manager.coins == coins_after_empty, "Repeated emptying duplicated coins")
		_expect(trash_bin.get_interaction_prompt() == "Bolsa vacía", "Empty bin prompt is incorrect")

		while manager.remaining_trash > 0:
			var collected_this_pass := false
			for item in get_nodes_in_group("trash_item"):
				if is_instance_valid(item) and not item.is_queued_for_deletion():
					if manager.try_collect(item, true):
						collected_this_pass = true
			await process_frame
			if manager.remaining_trash > 0:
				_expect(manager.empty_bag(), "Could not empty bag while trash remained")
			if not collected_this_pass and manager.remaining_trash > 0:
				_failures.append("Trash collection loop made no progress")
				break

		_expect(manager.remaining_trash == 0, "Not all trash could be collected")
		_expect(manager.get_clean_percent() == 100, "Clean percentage did not reach 100")
		manager.empty_bag()
		_expect(manager.coins > 0, "Final coin total is not positive")

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	main.queue_free()
	await process_frame
	call_deferred("_finish")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
		push_error(message)


func _expect_hud_ignores_mouse(node: Node) -> void:
	if node is Control:
		_expect(
			node.mouse_filter == Control.MOUSE_FILTER_IGNORE,
			"HUD control blocks mouse input: %s" % node.name
		)
	for child in node.get_children():
		_expect_hud_ignores_mouse(child)


func _finish() -> void:
	if _failures.is_empty():
		print("PHASE_2_SMOKE_OK")
		quit(0)
	else:
		print("PHASE_2_SMOKE_FAILED: %s" % ", ".join(_failures))
		quit(1)
