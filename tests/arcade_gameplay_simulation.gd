extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var arcade := ArcadeReelRescue.new()
	root.add_child(arcade)
	await process_frame
	# Thousands of logical ticks run in under a second; no real audio mixer tick
	# occurs between SFX calls, so mute the simulation to avoid stale voices.
	arcade._repair_audio.stream = null
	arcade._error_audio.stream = null
	var failures: Array[String] = []
	arcade._start_run(0)
	var normal_first_speed := arcade._defect_speed()
	var normal_first_interval := arcade._spawn_interval()
	arcade._stage = 3
	if arcade._defect_speed() <= normal_first_speed or arcade._spawn_interval() >= normal_first_interval:
		failures.append("Normal mode must accelerate each act")
	arcade._start_run(1)
	if arcade._defect_speed() <= normal_first_speed or arcade._spawn_interval() >= normal_first_interval:
		failures.append("Difficult mode must start faster and spawn more often than Normal")
	var hard_first_speed := arcade._defect_speed()
	var hard_first_interval := arcade._spawn_interval()
	arcade._stage = 3
	if arcade._defect_speed() <= hard_first_speed or arcade._spawn_interval() >= hard_first_interval:
		failures.append("Difficult mode must accelerate each act")
	for difficulty in [0, 1]:
		for skip_every in [4, 3, 2]:
		# A fallible player catches three of four reachable frames, without using
		# the slow-motion focus ability. The game should be completable, not trivial.
			seed(420 + difficulty)
			arcade._start_run(difficulty)
			var opportunities := 0
			for tick in 4200:
				if arcade._mode != ArcadeReelRescue.Mode.PLAYING:
					break
				arcade._update_run(0.05)
				for index in arcade._defects.size():
					var defect: Dictionary = arcade._defects[index]
					if bool(defect.get("tested", false)) or absf(float(defect.y) - 143.0) > 5.0:
						continue
					opportunities += 1
					if opportunities % skip_every == 0:
						defect.tested = true
						arcade._defects[index] = defect
					else:
						arcade._operator_lane = int(defect.lane)
						arcade._try_repair()
					break
			print("ARCADE_SIM difficulty=", difficulty, " skip_every=", skip_every, " mode=", arcade._mode, " elapsed=", arcade._elapsed, " repairs=", arcade._repairs, " lives=", arcade._integrity, " opportunities=", opportunities)
			if skip_every >= 3 and arcade._mode != ArcadeReelRescue.Mode.VICTORY:
				failures.append("Difficulty %d is not beatable with at least two-thirds of frames repaired" % difficulty)
			if skip_every >= 3 and arcade._elapsed < arcade._duration():
				failures.append("Difficulty %d ended before its intended run time" % difficulty)
	arcade.close_arcade()
	arcade.queue_free()
	await process_frame
	if failures.is_empty():
		print("ARCADE_GAMEPLAY_SIMULATION_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
