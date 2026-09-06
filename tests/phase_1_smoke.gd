extends SceneTree

const REQUIRED_ACTIONS := [
	"move_forward",
	"move_backward",
	"move_left",
	"move_right",
	"jump",
	"sprint",
	"crouch",
	"interact",
	"primary_action",
	"pause",
]

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for action in REQUIRED_ACTIONS:
		_expect(InputMap.has_action(action), "Missing input action: %s" % action)

	var main_scene := load("res://scenes/main/main.tscn") as PackedScene
	_expect(main_scene != null, "Main scene could not be loaded")
	if main_scene == null:
		_finish()
		return

	var main := main_scene.instantiate()
	root.add_child(main)
	await process_frame
	await physics_frame

	var player = main.get_node_or_null("Player")
	_expect(player != null, "PlayerController is missing from main scene")
	_expect(main.get_node_or_null("RespawnPoint") != null, "RespawnPoint is missing")
	_expect(main.get_node_or_null("Room01Blockout") != null, "Room blockout is missing")
	_expect(get_nodes_in_group("phase_1_seat").size() == 60, "Expected exactly 60 seats")
	_expect(get_nodes_in_group("phase_1_geometry").size() >= 190, "Blockout geometry is incomplete")

	if player:
		_expect(player.get_node_or_null("Head/Camera3D") is Camera3D, "First-person camera is missing")
		var interaction_raycast := player.get_node_or_null(
			"Head/Camera3D/InteractionRayCast3D"
		) as RayCast3D
		_expect(interaction_raycast != null, "Interaction raycast is missing")
		if interaction_raycast:
			_expect(interaction_raycast.enabled, "Interaction raycast is disabled")
			_expect(interaction_raycast.target_position.length() >= 2.5, "Interaction raycast is too short")
		_expect(player.sprint_speed > player.walk_speed, "Sprint speed must exceed walk speed")
		_expect(player.crouch_speed < player.walk_speed, "Crouch speed must be below walk speed")

		for frame in 12:
			await physics_frame
		var start_position: Vector3 = player.global_position
		Input.action_press("move_forward")
		for frame in 18:
			await physics_frame
		Input.action_release("move_forward")
		_expect(player.global_position.z < start_position.z - 0.2, "Forward movement did not move the player")

		Input.action_press("crouch")
		for frame in 18:
			await physics_frame
		_expect(player.is_crouching(), "Crouch state was not activated")
		var capsule := (player.get_node("CollisionShape3D") as CollisionShape3D).shape as CapsuleShape3D
		_expect(capsule.height < 1.3, "Crouch did not reduce the collider")
		Input.action_release("crouch")
		for frame in 18:
			await physics_frame

		player.global_position.y = -20.0
		await physics_frame
		await physics_frame
		_expect(player.global_position.y > 0.0, "Fall recovery did not respawn the player")

		for frame in 60:
			await physics_frame
			if player.is_on_floor():
				break
		_expect(player.is_on_floor(), "Player did not settle on the floor before jump test")
		var jump_started: bool = player.try_jump()
		_expect(jump_started, "Jump was rejected while the player was on the floor")
		_expect(player.velocity.y > 0.0, "Jump did not produce upward velocity")

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	main.queue_free()
	await process_frame
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
		push_error(message)


func _finish() -> void:
	if _failures.is_empty():
		print("PHASE_1_SMOKE_OK")
		quit(0)
	else:
		print("PHASE_1_SMOKE_FAILED: %s" % ", ".join(_failures))
		quit(1)
