extends Node3D

var main: Node3D
var manager: GameplayManager
var capture := false

func _ready() -> void:
	var path := "res://.godot/bin_delivery_visual.json"
	OS.set_environment("CINEMA_CLEANER_TEST_SAVE_PATH",path)
	if FileAccess.file_exists(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	main=load("res://scenes/main/main.tscn").instantiate()
	add_child(main)
	for frame in 30: await get_tree().physics_frame
	manager=main.get_node("GameplayManager")
	main.get_node("GameIntro").complete_immediately()
	manager.coins=500
	manager.bag_contents={"bottle":2,"ticket":2,"can":2,"napkin":2,"cup":2,"bucket":2,"straw":2,"popcorn":2}
	manager.bag_volume=20
	manager._pending_base_value=20
	manager.state_changed.emit()
	var bin: Node3D=get_tree().get_first_node_in_group("trash_bin")
	var player: PlayerController=main.get_node("Player")
	player.global_position=bin.global_position+bin.global_basis.z.normalized()*1.35+Vector3.UP*.2
	player.velocity=Vector3.ZERO
	player.look_at(Vector3(bin.global_position.x,player.global_position.y,bin.global_position.z))
	for frame in 3: await get_tree().physics_frame
	player.head.look_at(bin.global_position+Vector3.UP*1.15)
	Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
	var started := Time.get_ticks_usec()
	bin.set_focused(true)
	var focus_call_ms := float(Time.get_ticks_usec()-started)/1000.0
	await RenderingServer.frame_post_draw
	print("BIN_FOCUS_PROFILE ",JSON.stringify({"prepared":bin._focus_prewarmed,"call_ms":focus_call_ms,"first_visible_frame_ms":float(Time.get_ticks_usec()-started)/1000.0,"cached_types":bin._deposit_models.size()}))
	capture="--capture" in OS.get_cmdline_user_args()
	if capture: await _demo()
	else: print("BIN_DELIVERY_VISUAL_READY: hold E to deliver the mixed bag")

func _demo() -> void:
	var event := InputEventAction.new()
	event.action="interact"
	event.pressed=true
	Input.parse_input_event(event)
	await get_tree().create_timer(.22).timeout
	await shot("bottle_arc")
	await get_tree().create_timer(1.08).timeout
	await shot("paper_arc")
	event=InputEventAction.new()
	event.action="interact"
	event.pressed=false
	Input.parse_input_event(event)
	await get_tree().create_timer(.15).timeout
	await shot("pending")
	await get_tree().create_timer(1.0).timeout
	await shot("money_flight")
	await get_tree().create_timer(.6).timeout
	await shot("settled")
	var hud: Node=main.get_node("GameplayHUD")
	print("BIN_DELIVERY_CAPTURE ",JSON.stringify({"coins":manager.coins,"displayed":hud._displayed_coins,"pending":hud._deposit_pending_coins,"bag":manager.bag_volume}))
	main.queue_free()
	for frame in 5: await get_tree().process_frame
	Input.set_custom_mouse_cursor(null,Input.CURSOR_ARROW)
	Input.set_custom_mouse_cursor(null,Input.CURSOR_POINTING_HAND)
	PointerTheme._default_cursor=null
	PointerTheme._clickable_cursor=null
	get_tree().quit()

func shot(label: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.godot/bin_delivery_%s.png" % label)
