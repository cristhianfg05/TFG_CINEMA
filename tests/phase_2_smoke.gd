extends SceneTree

const SAVE_PATH := "res://.godot/phase_2_smoke_save.json"

var _failures: Array[String] = []


func _initialize() -> void:
	OS.set_environment("CINEMA_CLEANER_TEST_SAVE_PATH", SAVE_PATH)
	call_deferred("_run")


func _run() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
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
	_expect(_room_one_trash().size() == 400, "Room one must contain exactly 400 trash items")
	var one_unit_count := 0
	var two_unit_count := 0
	var base_reward_total := 0
	var found_elevated_trash := false
	var found_expanded_straw_target := false
	var zone_counts := {"on_seat": 0, "under_seat": 0, "between_rows": 0, "open_floor": 0}
	var lying_container_ids: Dictionary = {}
	for trash_item in _room_one_trash():
		if int(trash_item.definition.size_units) == 1: one_unit_count += 1
		if int(trash_item.definition.size_units) == 2: two_unit_count += 1
		base_reward_total += int(trash_item.definition.reward)
		var spawn_zone := String(trash_item.get_meta("spawn_zone", ""))
		if zone_counts.has(spawn_zone): zone_counts[spawn_zone] += 1
		if String(trash_item.get_meta("spawn_pose", "")) == "lying":
			lying_container_ids[String(trash_item.definition.id)] = true
		_expect(trash_item is RigidBody3D, "Trash is not using lightweight rigid-body physics")
		if trash_item is RigidBody3D:
			_expect(trash_item.collision_layer & 1 != 0, "Trash has no physical collision layer")
			_expect(trash_item.collision_mask & 1 != 0, "Trash does not collide with the room")
			_expect(trash_item.collision_mask & 4 != 0, "Trash ignores the black stair cladding")
		if String(trash_item.definition.id) in ["ticket", "napkin", "straw"]:
			_expect(trash_item.lock_rotation, "Floor-sensitive trash can still tip through the floor")
			_expect(trash_item.get_visual_bottom_local_y() >= 0.011, "Floor-sensitive trash visual still intersects its local floor plane")
		if trash_item.global_position.y > 1.0:
			found_elevated_trash = true
		var item_focus := trash_item.get_node("InteractionArea/FocusRadius") as CollisionShape3D
		var item_focus_sphere := item_focus.shape as SphereShape3D
		if String(trash_item.definition.id) == "straw":
			found_expanded_straw_target = found_expanded_straw_target or item_focus_sphere.radius >= 0.47
		elif spawn_zone == "under_seat":
			_expect(item_focus_sphere.radius >= 0.60, "Under-seat trash lacks its accessibility target")
		else:
			_expect(item_focus_sphere.radius <= 0.38, "A non-straw aiming sphere became oversized")
	_expect(one_unit_count == 380, "Room one must contain exactly 380 one-coin trash items")
	_expect(two_unit_count == 20, "Room one must contain exactly 20 two-coin trash items")
	_expect(base_reward_total == 420, "Room-one trash must total exactly 420 base coins")
	_expect(int(zone_counts.on_seat) == 60, "Trash-on-seat quota changed")
	_expect(int(zone_counts.under_seat) == 100, "Under-seat trash quota changed")
	_expect(int(zone_counts.between_rows) == 108, "Between-row trash quota changed")
	_expect(int(zone_counts.open_floor) == 132, "Open-floor trash quota changed")
	_expect(lying_container_ids.has("cup"), "No cups spawn tipped over")
	_expect(lying_container_ids.has("bottle"), "No bottles spawn lying down")
	_expect(lying_container_ids.has("bucket"), "No popcorn buckets spawn tipped over")
	_expect(found_expanded_straw_target, "Straw pickup target was not enlarged")
	_expect(found_elevated_trash, "Trash on the raised seating area still spawns below its floor")
	if player:
		var interaction_raycast := player.get_node("Head/Camera3D/InteractionRayCast3D") as RayCast3D
		var trash_push_area := player.get_node_or_null("TrashPushArea") as Area3D
		_expect(interaction_raycast.collide_with_areas, "Interaction raycast ignores aiming spheres")
		_expect(interaction_raycast.collision_mask & 2 != 0, "Interaction raycast cannot see trash aiming layer")
		_expect(player.trash_push_impulse_factor > 0.0, "Player has no physical trash-push impulse")
		_expect(trash_push_area != null, "Player has no non-blocking trash push area")
		_expect(trash_push_area == null or trash_push_area.collision_mask & 2 != 0, "Trash push area cannot detect item areas")
		for trash_item in _room_one_trash():
			_expect(
				(trash_item as PhysicsBody3D).get_collision_exceptions().has(player),
				"Trash still has a blocking physical collision with the player"
			)
		var pushed_item := _room_one_trash()[-1] as RigidBody3D
		player.global_position = Vector3(0.0, 0.1, -11.65)
		player.rotation = Vector3.ZERO
		pushed_item.global_position = Vector3(0.0, 0.08, -12.05)
		pushed_item.linear_velocity = Vector3.ZERO
		pushed_item.angular_velocity = Vector3.ZERO
		pushed_item.sleeping = false
		await physics_frame
		await physics_frame
		var pushed_item_start := pushed_item.global_position
		player.velocity = Vector3(0.0, 0.0, -player.walk_speed)
		player._push_nearby_trash()
		for frame in 5:
			await physics_frame
		_expect(
			pushed_item.global_position.distance_to(pushed_item_start) > 0.015,
			"Non-blocking player contact did not displace the trash"
		)
		player.velocity = Vector3.ZERO
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
		_expect(manager.total_trash == 400, "Total trash count is incorrect")
		_expect(manager.remaining_trash == 400, "Initial remaining count is incorrect")
		_expect(manager.get_clean_percent() == 0, "Initial clean percentage is not zero")
		_expect(is_equal_approx(manager.bag_capacity, 10.0), "Initial bag capacity is not 10")
		_expect(manager.pickup_audio.stream is AudioStreamWAV, "Pickup sound was not generated")
		_expect(manager.empty_audio.stream is AudioStreamWAV, "Emptying sound was not generated")
		_expect(manager.reject_audio.stream is AudioStreamWAV, "Rejected-pickup sound was not generated")
		var initial_item = _room_one_trash()[0]
		_expect(initial_item.get_interaction_prompt().is_empty(), "Trash still displays the right-click pickup text")
		var focus_collision := initial_item.get_node_or_null(
			"InteractionArea/FocusRadius"
		) as CollisionShape3D
		_expect(focus_collision != null, "Trash item has no enlarged aiming radius")
		if focus_collision:
			var focus_sphere := focus_collision.shape as SphereShape3D
			_expect(focus_sphere != null, "Trash aiming target is not spherical")
			if focus_sphere:
				var expected_max := 0.38
				if String(initial_item.get_meta("spawn_zone", "")) == "under_seat":
					expected_max = 0.62
				elif String(initial_item.definition.id) == "straw":
					expected_max = 0.54
				_expect(focus_sphere.radius <= expected_max + 0.005, "Trash aiming sphere is larger than intended")
		var physical_collision := initial_item.get_node_or_null("Collision") as CollisionShape3D
		if physical_collision and physical_collision.shape is BoxShape3D:
			_expect(
				(physical_collision.shape as BoxShape3D).size.y > 0.025,
				"Trash collision has no clearance against floor clipping"
			)

		if player:
			var remaining_before_animation: int = manager.remaining_trash
			var bag_before_animation: int = manager.bag_volume
			var position_before_animation: Vector3 = initial_item.global_position
			initial_item.collect_interact(player)
			_expect(initial_item.is_being_collected(), "Trash did not enter its collection animation")
			_expect(
				manager.remaining_trash == remaining_before_animation,
				"Trash count changed before the collection animation finished"
			)
			_expect(
				is_equal_approx(manager.bag_volume, bag_before_animation),
				"Bag volume changed before the collection animation finished"
			)
			await create_timer(0.18).timeout
			_expect(
				is_instance_valid(initial_item)
				and initial_item.global_position.distance_to(position_before_animation) > 0.05,
				"Trash did not travel toward the player"
			)
			_expect(
				manager.remaining_trash == remaining_before_animation,
				"Trash count changed halfway through the collection animation"
			)
			await create_timer(0.32).timeout
			await process_frame
			_expect(
				manager.remaining_trash == remaining_before_animation - 1,
				"Trash was not counted when the collection animation arrived"
			)
			_expect(
				manager.bag_volume > bag_before_animation,
				"Animated collection did not add trash to the bag"
			)

		var collected_before_full := 0
		var rejected_item: Node = null
		for item in _room_one_trash():
			if manager.try_collect(item, true):
				collected_before_full += 1
			elif rejected_item == null:
				rejected_item = item
			_expect(manager.bag_volume <= manager.bag_capacity + 0.0001, "Bag exceeded capacity")
		await process_frame
		_expect(collected_before_full < manager.total_trash, "Bag never reached a capacity limit")
		_expect(rejected_item != null, "No item was rejected when the bag filled")
		if rejected_item:
			_expect(rejected_item.get_interaction_prompt().is_empty(), "Full bag still displays an explanatory prompt")
			var pickup_rejections: Array[bool] = []
			var pickup_notices: Array[String] = []
			manager.pickup_rejected.connect(func() -> void: pickup_rejections.append(true))
			manager.notification_requested.connect(func(message: String) -> void: pickup_notices.append(message))
			manager._pickup_cooldown_remaining = 0.0
			_expect(not manager.request_collect(rejected_item, player), "A full bag accepted another trash item")
			await process_frame
			_expect(pickup_rejections.size() == 1, "Rejected pickup did not emit tactile HUD feedback")
			_expect(pickup_notices.is_empty(), "Rejected pickup still displays an explanatory notice")
			_expect(
				hud._crosshair_reject_tween != null and hud._crosshair_reject_tween.is_valid(),
				"Rejected pickup did not vibrate the crosshair"
			)
		_expect(String(trash_bin.get_interaction_prompt()).begins_with("E — Vaciar bolsa"), "Bin prompt is missing")
		var coins_before_empty: int = manager.coins
		var deposit_notices: Array[String] = []
		manager.notification_requested.connect(func(message: String) -> void: deposit_notices.append(message))
		_expect(manager.empty_bag(), "Non-empty bag could not be emptied")
		_expect(manager.coins > coins_before_empty, "Emptying did not award coins")
		_expect(deposit_notices.is_empty(), "Emptying trash still displays a delivery notification")
		_expect(is_zero_approx(manager.bag_volume), "Bag volume did not reset")
		var coins_after_empty: int = manager.coins
		_expect(not manager.empty_bag(), "Empty bag was accepted twice")
		_expect(manager.coins == coins_after_empty, "Repeated emptying duplicated coins")
		_expect(trash_bin.get_interaction_prompt() == "Bolsa vacía", "Empty bin prompt is incorrect")

		while manager.remaining_trash > 0:
			var collected_this_pass := false
			for item in _room_one_trash():
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


func _room_one_trash() -> Array[Node]:
	var result: Array[Node] = []
	for item in get_nodes_in_group("trash_item"):
		if item.has_method("get_room_id") and item.get_room_id() == &"room_01":
			result.append(item)
	return result


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
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	if _failures.is_empty():
		print("PHASE_2_SMOKE_OK")
		quit(0)
	else:
		print("PHASE_2_SMOKE_FAILED: %s" % ", ".join(_failures))
		quit(1)
