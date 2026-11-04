extends SceneTree

const MAIN_SCENE := preload("res://scenes/main/main.tscn")
const EXPECTED_VARIANTS := {
	"ButacaRota": 24,
	"ButacaEstandar": 72,
	"ButacaPlegada": 24,
}

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var main := MAIN_SCENE.instantiate()
	root.add_child(main)
	await process_frame
	await physics_frame
	var intro = get_first_node_in_group("game_intro")
	if intro and intro.has_method("complete_immediately"):
		intro.complete_immediately()
	await process_frame

	var seats := get_nodes_in_group("phase_1_seat")
	_expect(seats.size() == 120, "The auditorium no longer contains 120 seats")
	var variant_counts := {"ButacaRota": 0, "ButacaEstandar": 0, "ButacaPlegada": 0}
	var unique_shapes: Dictionary = {}
	for seat in seats:
		var variant_name := String(seat.get_meta("seat_variant", ""))
		_expect((seat as StaticBody3D).collision_layer == 8, "A seat hull is not isolated on the character collision layer")
		_expect(variant_counts.has(variant_name), "Unknown or missing seat visual variant: %s" % variant_name)
		if variant_counts.has(variant_name):
			variant_counts[variant_name] += 1
		var visual := seat.get_child(0) as Node3D
		_expect(visual != null and visual.name == variant_name and visual.scale.is_equal_approx(Vector3.ONE * 1.55), "A seat changed its established visual scale")
		var collisions := seat.find_children("*", "CollisionShape3D", true, false)
		var convex_count := 0
		for collision_node in collisions:
			var shape := (collision_node as CollisionShape3D).shape
			_expect(not shape is ConcavePolygonShape3D, "A seat still uses concave triangle collision")
			if shape is ConvexPolygonShape3D:
				convex_count += 1
				unique_shapes[shape.get_instance_id()] = shape
				_expect(shape.points.size() >= 4 and shape.points.size() <= 128, "A simplified seat hull has an unreasonable point count")
		_expect(convex_count == 1, "A seat does not use exactly one stable convex hull")
		_expect(collisions.size() == (1 if variant_name == "ButacaPlegada" else 2), "Seat cushion collision does not match its visual variant")
		if variant_name != "ButacaPlegada":
			var cushion := seat.get_node_or_null("SeatCushionSurface") as StaticBody3D
			_expect(cushion != null and cushion.collision_layer == 1, "A seat cushion is not available to world props")
	_expect(variant_counts == EXPECTED_VARIANTS, "Seat variant distribution does not match the standard-majority mix: %s" % variant_counts)
	_expect(unique_shapes.size() == 3, "The 120 seats do not share one hull per visual variant")

	var player = get_first_node_in_group("player") as CharacterBody3D
	_expect(player != null, "Player is missing from the collision stability test")
	# Warm the complete room before timing contact-heavy positions.
	for _frame in 30:
		await physics_frame

	var scenarios: Array[Vector3] = [
		Vector3(-7.68, 3.0, -9.30), # between two adjacent seats
		Vector3(-3.60, 3.4, -1.30), # another lateral gap on a raised tier
		Vector3(4.28, 3.6, 3.70),   # between two rows
		Vector3(7.00, 3.8, 6.70),   # directly over a seat
	]
	var frame_times_usec: Array[int] = []
	for scenario in scenarios:
		player.global_position = scenario
		player.velocity = Vector3.ZERO
		for _frame in 75:
			var started := Time.get_ticks_usec()
			await physics_frame
			frame_times_usec.append(Time.get_ticks_usec() - started)
			_expect(player.global_position.is_finite() and player.velocity.is_finite(), "Seat contact produced an invalid player transform")
		_expect(player.global_position.y > -0.2, "Player fell through the seats or auditorium floor")

	frame_times_usec.sort()
	var percentile_95 := frame_times_usec[int(floor((frame_times_usec.size() - 1) * 0.95))]
	var maximum := frame_times_usec[-1]
	_expect(percentile_95 < 35000, "Seat contact physics is too slow at p95: %.2f ms" % (percentile_95 / 1000.0))
	_expect(maximum < 120000, "Seat contact produced a freeze-sized frame: %.2f ms" % (maximum / 1000.0))
	print("SEAT_COLLISION_PROFILE %s" % JSON.stringify({
		"seats": seats.size(),
		"variants": variant_counts,
		"shared_hulls": unique_shapes.size(),
		"p95_ms": snappedf(percentile_95 / 1000.0, 0.001),
		"max_ms": snappedf(maximum / 1000.0, 0.001),
	}))

	main.queue_free()
	await process_frame
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
		push_error("SEAT COLLISION TEST: %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("SEAT_COLLISION_STABILITY_OK")
		quit(0)
	else:
		print("SEAT_COLLISION_STABILITY_FAILED: %s" % _failures)
		quit(1)
