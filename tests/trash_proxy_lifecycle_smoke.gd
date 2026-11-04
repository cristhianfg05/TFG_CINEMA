extends SceneTree

const SAVE := "res://.godot/trash_proxy_lifecycle_smoke.json"
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
	var main := (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	for frame in 8: await physics_frame
	var manager := main.get_node("GameplayManager") as GameplayManager
	var registry := manager.get_dense_registry()
	registry.set_physics_process(false)
	registry._refresh_proxies()
	var index: int = registry.proxies.keys()[0]
	var proxy: Node = registry.proxies[index]
	var remaining := manager.remaining_trash
	proxy.free()
	expect(not registry.proxies.has(index),"Freed proxy remained registered")
	registry._refresh_proxies()
	expect(is_instance_valid(registry.proxies.get(index)),"Alive trash did not regain an interaction proxy")
	expect(manager.remaining_trash==remaining,"Replacing an interaction proxy changed cleaning progress")
	# Refresh may replace a queued node before its tree_exiting signal arrives.
	proxy=registry.proxies[index]
	proxy.queue_free()
	registry._refresh_proxies()
	var replacement: Node = registry.proxies[index]
	await process_frame
	expect(registry.proxies.get(index)==replacement and is_instance_valid(replacement),"Old proxy exit removed its replacement")
	registry._wake(index,Vector3.RIGHT)
	expect(registry.bodies.has(index),"Moving-trash setup failed")
	registry.wake_queue[index]=Vector3.UP
	registry.remove_entry(index)
	registry.remove_entry(index)
	expect(not registry.proxies.has(index) and not registry.bodies.has(index) and not registry.wake_queue.has(index),"Retired trash retained physics or proxy state")
	registry._refresh_proxies()
	expect(not registry.proxies.has(index),"Retired trash respawned")

	main.get_node("GameIntro").complete_immediately()
	var player := main.get_node("Player") as PlayerController
	manager.purchased_tools["broom"]=true
	manager.purchased_tools["vacuum"]=true
	manager.equipped_tool=""
	var key := InputEventKey.new()
	key.physical_keycode=KEY_Q
	key.pressed=true
	expect(key.is_action_pressed("cycle_tool"),"Q is not mapped to tool cycling")
	# The headless display server cannot capture the mouse. Exercise actual
	# player input in a graphical run; both runs check the binding and lifecycle.
	if DisplayServer.get_name()!="headless":
		Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
		for button in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
			var wheel := InputEventMouseButton.new()
			wheel.button_index=button
			wheel.pressed=true
			player._unhandled_input(wheel)
			expect(manager.equipped_tool.is_empty(),"Mouse wheel still changes tools")
		var hud := main.get_node("GameplayHUD")
		hud._rebuild_tool_slots()
		expect(hud._tool_slots.get_child(1).get_meta("tool_id")=="broom","Middle diamond does not show the next tool")
		player._unhandled_input(key)
		expect(manager.equipped_tool=="broom","Q did not select broom")
		key.echo=true
		player._unhandled_input(key)
		expect(manager.equipped_tool=="broom","Held Q repeated tool changes")
		key.echo=false
		expect(hud._tool_slots.get_child(1).get_meta("tool_id")=="vacuum","Next tool does not match middle diamond after selecting broom")
		player._unhandled_input(key)
		expect(manager.equipped_tool=="vacuum","Q did not select vacuum")
		expect(hud._tool_slots.get_child(1).get_meta("tool_id")=="hand","Middle diamond does not show hand before wrapping")
		player._unhandled_input(key)
		expect(manager.equipped_tool.is_empty(),"Q did not return to hand")
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	player._unhandled_input(key)
	expect(manager.equipped_tool.is_empty(),"Q changed equipment with cursor released")

	manager.debug_unlock_and_clean_all()
	await process_frame
	registry._refresh_proxies()
	expect(registry.proxies.is_empty() and registry.bodies.is_empty(),"Debug cleaning retained or recreated trash")
	for entry in registry.entries:
		expect(not entry.alive,"Distant trash survived debug cleaning")
	manager._save_dirty=false
	main.queue_free()
	for frame in 3: await process_frame
	Input.set_custom_mouse_cursor(null,Input.CURSOR_ARROW)
	Input.set_custom_mouse_cursor(null,Input.CURSOR_POINTING_HAND)
	PointerTheme._default_cursor=null
	PointerTheme._clickable_cursor=null
	if FileAccess.file_exists(SAVE): DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	if failures.is_empty():
		print("TRASH_PROXY_LIFECYCLE_SMOKE_OK")
		quit(0)
	else:
		print("TRASH_PROXY_LIFECYCLE_SMOKE_FAILED: ",failures)
		quit(1)
