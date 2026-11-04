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
	"collect_item",
	"primary_action",
	"pause",
	"upgrade_menu",
	"ability_1",
	"ability_2",
	"seal_bag",
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
	_expect(get_nodes_in_group("phase_1_seat").size() == 120, "Expected exactly 120 imported seats")
	_expect(get_nodes_in_group("phase_1_geometry").size() >= 240, "Room-one geometry is incomplete")
	var room = main.get_node_or_null("Room01Blockout")
	_expect(room != null and is_equal_approx(room.ROOM_WIDTH, 22.0), "Room width must be 22 m")
	_expect(room != null and is_equal_approx(room.ROOM_LENGTH, 30.0), "Room depth must be 30 m")
	_expect(room != null and is_equal_approx(room.ROOM_HEIGHT, 7.0), "Room height must be 7 m")
	_expect(room != null and is_equal_approx(room.RAMP_REAR_HEIGHT, 1.17), "Raked floor height must be 1.17 m")
	_expect(room != null and room.get_node_or_null("CentralRamp") != null, "Central ramp is missing")
	_expect(room != null and room.find_child("RearStepMiddle_*", false, false) != null, "Rear access must use three filled steps")
	var ramp_edge := room.find_child("RampEdge_*", false, false) as StaticBody3D if room else null
	_expect(ramp_edge != null and ramp_edge.collision_layer & 4 != 0, "Black stair cladding does not physically contain trash")
	var left_side_ramp := room.get_node_or_null("LeftSideRamp") as Node3D if room else null
	var right_side_ramp := room.get_node_or_null("RightSideRamp") as Node3D if room else null
	_expect(left_side_ramp != null and right_side_ramp != null, "Lateral ramps are missing")
	if left_side_ramp and right_side_ramp:
		var left_shape := left_side_ramp.get_node("Collision") as CollisionShape3D
		var right_shape := right_side_ramp.get_node("Collision") as CollisionShape3D
		var left_width: float = (left_shape.shape as BoxShape3D).size.x
		var right_width: float = (right_shape.shape as BoxShape3D).size.x
		_expect(is_equal_approx(left_width, 1.90), "Left lateral stair is not 1.90 m wide")
		_expect(is_equal_approx(right_width, 1.90), "Right lateral stair is not 1.90 m wide")
		_expect(
			is_equal_approx(left_side_ramp.position.x - left_width * 0.5, -11.0),
			"Left lateral stair no longer touches its wall"
		)
		_expect(
			is_equal_approx(right_side_ramp.position.x + right_width * 0.5, 11.0),
			"Right lateral stair no longer touches its wall"
		)
	var left_screen_speaker := room.get_node_or_null("CinemaSpeakerLeft") as Node3D if room else null
	var right_screen_speaker := room.get_node_or_null("CinemaSpeakerRight") as Node3D if room else null
	_expect(
		left_screen_speaker != null and is_equal_approx(left_screen_speaker.position.z, -13.35),
		"Left screen speaker was not returned toward the screen"
	)
	_expect(
		right_screen_speaker != null and is_equal_approx(right_screen_speaker.position.z, -13.35),
		"Right screen speaker was not returned toward the screen"
	)
	if left_screen_speaker and right_screen_speaker:
		var left_visual := left_screen_speaker.get_child(0) as Node3D
		var right_visual := right_screen_speaker.get_child(0) as Node3D
		_expect(left_visual.scale.is_equal_approx(Vector3.ONE * 5.4), "Left screen speaker scale is incorrect")
		_expect(right_visual.scale.is_equal_approx(Vector3.ONE * 5.4), "Right screen speaker scale is incorrect")
	var first_ramp_light := room.get_node_or_null("AisleLight_01_01") as Node3D if room else null
	_expect(first_ramp_light != null, "Central ramp light is missing")
	if first_ramp_light:
		var expected_ramp_angle: float = -atan2(
			room.RAMP_REAR_HEIGHT, room.RAMP_REAR_Z - room.RAMP_FRONT_Z
		)
		_expect(
			is_equal_approx(first_ramp_light.rotation.x, expected_ramp_angle),
			"Long floor lights do not follow the ramp angle"
		)
	var found_left_outer_cladding := false
	var found_right_outer_cladding := false
	if room:
		for child in room.get_children():
			if not String(child.name).begins_with("RampEdge_01_"):
				continue
			found_left_outer_cladding = (
				found_left_outer_cladding or is_equal_approx(child.position.x, -10.94)
			)
			found_right_outer_cladding = (
				found_right_outer_cladding or is_equal_approx(child.position.x, 10.94)
			)
	_expect(found_left_outer_cladding, "Outer black cladding is missing from the left lateral stair")
	_expect(found_right_outer_cladding, "Outer black cladding is missing from the right lateral stair")
	_expect(main.get_node_or_null("SpectatorLeft") == null, "Spectator NPC must be removed")
	_expect(main.get_node_or_null("SpectatorRight") == null, "Spectator NPC must be removed")
	_expect(main.get_node_or_null("ScreenContent") == null, "Legacy screen content must be removed")
	_expect(main.get_node_or_null("Manager") == null, "Manager desk must remain outside room one")

	if player:
		_expect(player.get_node_or_null("Head/Camera3D") is Camera3D, "First-person camera is missing")
		var interaction_raycast := player.get_node_or_null(
			"Head/Camera3D/InteractionRayCast3D"
		) as RayCast3D
		_expect(interaction_raycast != null, "Interaction raycast is missing")
		if interaction_raycast:
			_expect(interaction_raycast.enabled, "Interaction raycast is disabled")
			_expect(interaction_raycast.target_position.length() >= 1.5, "Base interaction reach must be 1.5 m")
		_expect(not bool(player.get_sprint_state().unlocked), "Sprint must begin locked")
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

		# The central aisle now uses a physical shallow ramp. It must be traversable
		# without the removed step-up teleport or a jump.
		player.global_position = Vector3(0.0, 0.1, -10.8)
		player.velocity = Vector3.ZERO
		for frame in 12:
			await physics_frame
		var stair_start_z: float = player.global_position.z
		Input.action_press("move_backward")
		for frame in 120:
			await physics_frame
		Input.action_release("move_backward")
		_expect(
			player.global_position.z > stair_start_z + 3.0,
			"Central stair aisle could not be climbed without jumping"
		)

		# Cross a complete seating block through the corridor between rows one and
		# two. This guards against replacing the detailed chair silhouette with a
		# full-depth box that blocks the row.
		player.global_position = Vector3(-8.9, 0.25, -8.3)
		player.velocity = Vector3.ZERO
		for frame in 12:
			await physics_frame
		Input.action_press("move_right")
		for frame in 120:
			await physics_frame
		Input.action_release("move_right")
		_expect(
			player.global_position.x > -2.0,
			"Detailed seat collisions still block passage between rows"
		)

	var trash_bin := main.get_node_or_null("TrashBin") as Node3D
	var lost_found := main.get_node_or_null("LostFoundBox") as Node3D
	var manager_node := main.get_node_or_null("Manager") as Node3D
	_expect(trash_bin != null and trash_bin.position.z >= 14.45 and trash_bin.position.z < 15.0, "Trash bin must be flush with the exit wall")
	_expect(trash_bin != null and is_equal_approx(absf(trash_bin.rotation_degrees.y), 180.0), "Entrance trash bin opening must face the screen")
	_expect(lost_found == null, "Lost-items box must wait for the future office")
	_expect(manager_node == null, "Manager desk must wait for the future office")

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
