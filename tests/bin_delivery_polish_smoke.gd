extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	OS.set_environment("CINEMA_CLEANER_TEST_SAVE_PATH","res://.godot/bin_delivery_polish_smoke.json")
	call_deferred("_run")

func expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func _run() -> void:
	var path := OS.get_environment("CINEMA_CLEANER_TEST_SAVE_PATH")
	if FileAccess.file_exists(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var main: Node3D=load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	for frame in 5: await physics_frame
	main.get_node("GameIntro").complete_immediately()
	var manager: GameplayManager=main.get_node("GameplayManager")
	var hud: Node=main.get_node("GameplayHUD")
	hud.set_process(false)
	var bin: Node3D=get_first_node_in_group("trash_bin")
	for level in 6:
		manager.upgrade_levels["quick_hands"]=level
		manager._apply_upgrades()
		var expected: float=[.60,.48,.40,.32,.256,.20][level]
		expect(is_equal_approx(manager.get_deposit_interval(),expected),"Wrong slower delivery cadence at level %d" % level)
	expect(manager.reject_audio.volume_db<=-28.0,"Pickup rejection is still too loud")
	for definition in manager.ONE_UNIT_DEFINITIONS+manager.TWO_UNIT_DEFINITIONS:
		var pool: Array=bin._deposit_models[String(definition.id)]
		expect(pool.size()==4,"Delivery model was not prepared before interaction")
		var visual: Node3D=pool[0].get_child(0)
		expect(visual.scene_file_path==definition.model.resource_path,"Delivery does not use the collected model: "+String(definition.id))
		expect(visual.scale.is_equal_approx(Vector3.ONE*definition.model_scale),"Delivery changed the item scale")
	var start := Vector3(1,1.4,1)
	var end := Vector3(1,.55,0)
	expect(bin.get_deposit_flight_point(start,end,0).is_equal_approx(start) and bin.get_deposit_flight_point(start,end,1).is_equal_approx(end),"Arc endpoints are wrong")
	expect(bin.get_deposit_flight_point(start,end,.5).y>start.lerp(end,.5).y+.25,"Delivery follows a straight line instead of an arc")
	manager.coins=500
	manager.bag_contents={"ticket":1,"bottle":1,"can":1}
	manager.bag_volume=4
	manager._pending_base_value=4
	manager._deposit_target=bin
	hud._update_state()
	expect(manager.deposit_one() and manager.deposit_one(),"Mixed delivery failed")
	expect(manager.coins==503 and manager.bag_volume==1 and hud._deposit_pending_coins==3,"Mixed delivery lost its per-type amount or large-item value")
	expect(hud._displayed_coins==500 and hud._deposit_reward_popup.visible,"Delivery credited the visible wallet before the batch animation")
	expect(bool(bin._deposit_models["ticket"][0].get_meta("in_use")) and bool(bin._deposit_models["bottle"][0].get_meta("in_use")),"Delivered paper and bottle did not launch their own models")
	manager.stop_deposit()
	hud._update_deposit_reward(.60)
	expect(not hud._coin_animation_active and hud._deposit_pending_coins==3,"Batch flew before one second after stopping")
	# Resuming before the delay expires accumulates into the same batch.
	manager._deposit_target=bin
	expect(manager.deposit_one(),"Resumed delivery failed")
	manager.stop_deposit()
	hud._update_deposit_reward(.99)
	expect(hud._deposit_pending_coins==4 and not hud._coin_animation_active,"Resuming failed to restart the one-second delay")
	hud._update_deposit_reward(.02)
	expect(hud._unsettled_reward_coins==4 and hud._displayed_coins==500 and hud._coin_animation_active,"Money did not enter the animation before entering the wallet")
	# A second delivery while the first flies must remain pending separately.
	manager.bag_contents={"napkin":1}
	manager.bag_volume=1
	manager._pending_base_value=1
	manager._deposit_target=bin
	manager.deposit_one()
	manager.stop_deposit()
	await create_timer(.65).timeout
	expect(hud._displayed_coins==504 and hud._deposit_pending_coins==1 and manager.coins==505,"An in-flight batch swallowed newer pending money")
	hud._update_deposit_reward(1.01)
	await create_timer(.65).timeout
	expect(hud._displayed_coins==505 and hud._unsettled_reward_coins==0 and hud._deposit_pending_coins==0,"Batch completion lost or duplicated money")
	expect(bin._unit_visuals==0,"Delivery models leaked after their flight")
	manager.bag_contents={"ticket":2}
	manager.bag_volume=2
	manager._pending_base_value=2
	manager._deposit_timer=0
	manager.begin_deposit(bin)
	manager.stop_deposit()
	manager.begin_deposit(bin)
	manager.stop_deposit()
	expect(manager.bag_volume==1,"Rapid E presses bypassed the slower delivery cadence")
	main.queue_free()
	for frame in 5: await process_frame
	print("BIN_DELIVERY_POLISH_OK" if failures.is_empty() else "BIN_DELIVERY_POLISH_FAILED")
	quit(0 if failures.is_empty() else 1)
