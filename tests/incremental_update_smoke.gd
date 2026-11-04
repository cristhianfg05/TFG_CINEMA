extends SceneTree

const SAVE := "res://.godot/incremental_update_smoke.json"
const Rules := preload("res://resources/upgrades/incremental_rules.gd")
var failures: Array[String] = []

func _initialize() -> void:
	OS.set_environment("CINEMA_CLEANER_TEST_SAVE_PATH",SAVE)
	call_deferred("_run")

func expect(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)

func _run() -> void:
	if FileAccess.file_exists(SAVE): DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	var started := Time.get_ticks_msec()
	var packed := load("res://scenes/main/main.tscn") as PackedScene
	var main := packed.instantiate()
	root.add_child(main)
	for frame in 5: await physics_frame
	var manager := main.get_node("GameplayManager") as GameplayManager
	var registry: Node3D = manager.get_dense_registry()
	expect(registry.entries.size()==6270,"All built zones must contain 6270 objects; final stays reserved")
	var objects := 0
	var units := 0
	for room in registry.COUNTS:
		var count: Vector2i = registry.COUNTS[room]
		expect(int(manager.room_trash_totals.get(room,0))==count.x+count.y,"Wrong room total: "+room)
		objects += count.x+count.y
		units += count.x+count.y*2
	expect(objects==6270 and units==6859,"Built-zone base reward is not 68,59")
	expect(manager.bag_capacity==25,"Initial bag must be 25")
	expect(not manager.room_completed and manager.coins==0,"Fresh room must not complete during asynchronous generation")
	expect(Rules.money(1)=="0,01" and Rules.money(100)=="1,00","Money formatting")
	expect(is_equal_approx(Rules.percent(299,300),99.67),"Percentage must round to two decimals")
	expect(not manager.owns_tool(&"boti") and not manager.UpgradeCatalog.TOOL_DEFINITIONS.has("boti"),"Retired tool is still purchasable")
	await test_held_deposit(main,manager)
	manager.coins = 0
	manager.bag_contents = {"ticket":100,"bottle":1}
	manager.bag_volume = 102
	manager._pending_base_value = 102
	for i in 100: expect(manager.deposit_one(),"Paper deposit failed")
	expect(manager.coins==100 and manager.bag_volume==2,"100 papers must pay 1,00 and leave bottle")
	expect(manager.deposit_one(),"Bottle deposit failed")
	expect(manager.coins==102 and manager.bag_volume==0,"One bottle pulse must release/pay two units")
	expect(not manager.deposit_one() and manager.coins==102,"Empty deposit duplicated money")
	await test_secondary_bin_sack(manager)
	manager.upgrade_levels["quick_hands"] = 1
	manager._apply_upgrades()
	expect(is_equal_approx(manager.get_deposit_interval(),0.48),"Hands1 must use the slower 0.48s delivery")
	var waiting_item: Node = registry.proxies.values()[0]
	manager._pickup_cooldown_remaining = 0.3
	var feedback_time := manager._pickup_reject_feedback_remaining
	expect(not manager.request_collect(waiting_item,main.get_node("Player")),"Cooldown accepted another pickup")
	expect(manager._pickup_reject_feedback_remaining==feedback_time,"Hands1 cooldown played rejection feedback")
	manager._pickup_cooldown_remaining = 0.0
	test_broom_shop(manager)
	manager.upgrade_levels["quick_hands"] = 5
	manager.upgrade_levels["reinforced_bag"] = 5
	manager._apply_upgrades()
	expect(manager.bag_capacity==220 and is_equal_approx(manager.get_deposit_interval(),.20),"Final bag/deposit cadence")
	manager.room_completed = true
	manager._check_monetary_objectives()
	var coins_after_objective := manager.coins
	manager._check_monetary_objectives()
	expect(manager.coins==coins_after_objective and manager.claimed_objective_rewards.has("room_01_clean"),"Objective reward is not exactly once")
	expect(registry.proxies.size()<=256 and registry.bodies.size()<=48,"Near-field physics budget exceeded")
	manager._save_progress()
	var saved = JSON.parse_string(FileAccess.get_file_as_string(SAVE))
	expect(saved is Dictionary and int(saved.version)==14,"Versioned save not written")
	expect(saved.bag_contents.is_empty() and saved.claimed_objective_rewards.has("room_01_clean"),"Bag/objective state missing in save")
	var proxy: Node = registry.proxies.values()[0]
	var collected_id := String(proxy.world_item_id)
	var coins_before_pickup := manager.coins
	expect(manager.request_collect(proxy,main.get_node("Player")),"Animated pickup could not start")
	for frame in 25: await physics_frame
	expect(manager.is_world_trash_collected(collected_id),"Pickup did not retire its stable ID")
	expect(manager.coins==coins_before_pickup,"Pickup paid money before deposit")
	var moved_index := int(registry.proxies.keys()[0])
	var moved_id := String(registry.entries[moved_index].id)
	var moved_position := Vector3(registry.entries[moved_index].pos)+Vector3(.12,0,.12)
	var stationary_id := String(registry.entries.back().id)
	var stationary_position := Vector3(registry.entries.back().pos)
	registry._set_position(moved_index,moved_position,Vector3.ZERO)
	manager._save_progress()
	print("INCREMENTAL_PROFILE ",JSON.stringify({"objects":registry.entries.size(),"render_batches":registry.groups.size(),"proxies":registry.proxies.size(),"active_bodies":registry.bodies.size(),"ready_ms":Time.get_ticks_msec()-started,"nodes":Performance.get_monitor(Performance.OBJECT_NODE_COUNT)}))
	manager._save_dirty = false
	main.queue_free()
	for frame in 5: await process_frame
	main = packed.instantiate()
	root.add_child(main)
	for frame in 4: await physics_frame
	manager = main.get_node("GameplayManager")
	registry = manager.get_dense_registry()
	expect(manager.coins==coins_before_pickup,"Continue duplicated an objective reward")
	var collected_present := false
	var moved_present := false
	for entry in registry.entries:
		if entry.id==stationary_id:
			expect(Vector3(entry.pos).is_equal_approx(stationary_position),"Retiring another object shuffled the static layout on continue")
		if entry.id==collected_id: collected_present=true
		if entry.id==moved_id:
			moved_present=true
			expect(Vector2(Vector3(entry.pos).x,Vector3(entry.pos).z).distance_to(Vector2(moved_position.x,moved_position.z))<.20,"Moved trash lost its position on reload")
	expect(not collected_present and moved_present,"Continue regenerated retired trash or lost moved trash")
	manager._save_dirty=false
	main.queue_free()
	for frame in 5: await process_frame
	# A representative old save: owned retired tool, one paid capacity upgrade,
	# bag without a type ledger, and an already completed first objective.
	var legacy := FileAccess.open(SAVE,FileAccess.WRITE)
	legacy.store_string(JSON.stringify({"version":13,"coins":500,"purchased_tools":{"boti":true},"upgrade_levels":{"boti_capacity":1},"bag_units":2,"pending_base_value":2,"room_completed":true,"world_trash_collected":[]}))
	legacy.close()
	main=packed.instantiate()
	root.add_child(main)
	for frame in 5: await physics_frame
	manager=main.get_node("GameplayManager")
	expect(manager.coins==2250 and manager.owns_tool(&"broom"),"Retired-tool migration lost or duplicated investment")
	expect(not manager.purchased_tools.has("boti") and not manager.upgrade_levels.has("boti_capacity"),"Retired purchase survived migration")
	manager._check_monetary_objectives()
	expect(manager.coins==2250,"Migration paid an already-completed objective")
	expect(manager.legacy_bag_units==2 and manager.deposit_one() and manager.deposit_one() and manager.coins==2252,"Legacy bag value was not preserved")
	manager._save_progress()
	saved=JSON.parse_string(FileAccess.get_file_as_string(SAVE))
	expect(int(saved.version)==14 and saved.purchased_tools.has("broom"),"Migration was not versioned")
	expect(FileAccess.file_exists(SAVE+".pre_incremental.bak"),"Migration did not preserve a backup")
	manager._load_progress()
	expect(manager.coins==2252,"Loading migrated save refunded the retired tool twice")
	# An old v14 pile save must not restore its suspended positions. Only the
	# layout is replaced; progress, retired IDs and currency survive.
	saved.erase("trash_layout_revision")
	saved["moved_trash"]={"room_02:small:001":[20,50,40,0,0,0]}
	var old_pile_save := FileAccess.open(SAVE,FileAccess.WRITE)
	old_pile_save.store_string(JSON.stringify(saved))
	old_pile_save.close()
	var retired_count := manager._collected_world_trash_ids.size()
	manager._load_progress()
	expect(manager.moved_trash.is_empty() and manager.coins==2252 and manager._collected_world_trash_ids.size()==retired_count,"Scatter migration restored floating piles or changed progress")
	manager._save_progress()
	manager._save_dirty=false
	main.queue_free()
	for frame in 5: await process_frame
	if failures.is_empty(): print("INCREMENTAL_UPDATE_SMOKE_OK")
	else: print("INCREMENTAL_UPDATE_SMOKE_FAILED: ",failures)
	quit(0 if failures.is_empty() else 1)

func test_broom_shop(manager: GameplayManager) -> void:
	var previous := manager.coins
	manager.coins=2000
	expect(manager.purchase_tool(&"broom"),"Broom could not be bought in the existing shop")
	for branch in [&"broom_speed",&"broom_width"]:
		expect(manager.purchase_upgrade(branch) and manager.purchase_upgrade(branch),"Broom branch could not buy both upgrades")
		expect(not manager.purchase_upgrade(branch),"Broom gained an unrequested third upgrade")
	expect(manager.coins==925,"Broom or its upgrades charged the wrong cents")
	expect(is_equal_approx(manager.broom_interval,.55) and is_equal_approx(manager.broom_width,1.60),"Broom upgrades did not change gameplay")
	manager.coins=previous
	manager.equip_tool(&"")


func test_secondary_bin_sack(manager: GameplayManager) -> void:
	var bins := get_nodes_in_group("trash_bin")
	expect(bins.size()>=2,"Secondary bin is missing")
	if bins.size()<2: return
	var bin: Node3D = bins[1]
	var sack := load("res://scenes/gameplay/sealed_bag.tscn").instantiate() as SealedBag
	sack.contained_units=3
	sack.contained_base_value=3
	manager.sealed_bags.add_child(sack)
	sack.freeze=true
	sack.set_physics_process(false)
	sack.global_position=bin.get_absorption_point()+bin.global_basis.z.normalized()*.75
	for frame in 2: await physics_frame
	expect(manager.find_accepting_sack_bin(sack,SealedBag.BIN_ABSORB_DISTANCE)==bin,"Sack selected the wrong bin")
	var previous := manager.coins
	expect(manager.request_sack_absorption(sack),"Second bin did not accept the sealed sack")
	expect(not manager.request_sack_absorption(sack),"Absorbing sack was accepted twice")
	for frame in 40: await physics_frame
	expect(manager.coins==previous+3,"Sealed sack was not paid exactly once")


func test_held_deposit(main: Node, manager: GameplayManager) -> void:
	main.get_node("GameIntro").complete_immediately()
	var player := main.get_node("Player") as PlayerController
	var bin := get_first_node_in_group("trash_bin") as Node3D
	var forward := bin.global_basis.z.normalized()
	player.global_position=bin.global_position+forward*1.1+Vector3.UP*.2
	player.velocity=Vector3.ZERO
	player.look_at(Vector3(bin.global_position.x,player.global_position.y,bin.global_position.z))
	Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
	for frame in 5: await physics_frame
	player.head.look_at(bin.get_absorption_point())
	for frame in 3: await physics_frame
	expect(player.get_interaction_target()==bin,"Deposit test could not focus the bin")
	manager.bag_contents={"ticket":10}
	manager.bag_volume=10
	manager._pending_base_value=10
	var pressed := InputEventAction.new()
	pressed.action="interact"
	pressed.pressed=true
	Input.parse_input_event(pressed)
	for frame in 5: await physics_frame
	expect(manager.bag_volume<10 and manager.bag_volume>0,"Holding E did not deliver progressively")
	var released := InputEventAction.new()
	released.action="interact"
	released.pressed=false
	Input.parse_input_event(released)
	for frame in 2: await physics_frame
	var remaining := manager.bag_volume
	for frame in 12: await physics_frame
	expect(manager.bag_volume==remaining and not manager.is_depositing(),"Releasing E failed to interrupt delivery")
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
