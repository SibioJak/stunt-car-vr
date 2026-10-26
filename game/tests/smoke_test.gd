extends SceneTree

## Headless smoke for DE Test 1 (fallback mode, scripted inputs through
## the production action functions - _do_release / _flip_switch /
## _call_drone / _toggle_lean - plus an autopilot on the wheel):
##   Godot --headless --path . --script tests/smoke_test.gd
## Stages asserted: drop-start dangle sways -> release -> touchdown
## scored -> drive -> climb -> banked corner held -> gap crossed
## airborne -> on-demand drone lift -> dangle -> prep sequence ->
## boost credit up -> release over track -> driving resumes -> lean
## experiment changes grip at the bank.
## NOT covered here (XR layer, reported UNVERIFIED, never passed
## silently): grab-wheel hand tracking, switch flipping by hand
## proximity, HMD lean reading, panel legibility in the headset.

var failures: int = 0
var checks: int = 0
var main: Node


func check(cond: bool, stage: String) -> void:
	checks += 1
	if cond:
		print("PASS  ", stage)
	else:
		failures += 1
		print("FAIL  ", stage)


func autopilot() -> void:
	# keep the car centred; pre-compensate the banked corner's drift
	var lat: float = main.car_lat
	var s: float = main.car_s
	var steer_frac: float = clampf(-lat * 0.30, -0.6, 0.6)
	if s > 128.0 and s < 182.0:
		steer_frac = clampf(-0.45 - lat * 0.25, -0.85, 0.85)
	main.wheel_angle = steer_frac * PI


func frames(n: int, drive: bool = false) -> void:
	for i: int in n:
		if drive:
			autopilot()
		await physics_frame


func wait_until(cond: Callable, max_frames: int, drive: bool = false) -> bool:
	var t: int = 0
	while t < max_frames:
		if drive:
			autopilot()
		await physics_frame
		t += 1
		if cond.call():
			return true
	return cond.call()


func _init() -> void:
	_run()


func _run() -> void:
	var ps: PackedScene = load("res://main.tscn")
	main = ps.instantiate()
	root.add_child(main)
	main.test_mode = true
	await frames(5)

	# Stage 1: Drop Start dangle - the pendulum actually swings the car.
	check(main.mode == main.MODE_HANG and main.hang_phase == "dangle",
		"stage1: race opens dangling at Drop Start")
	var side_axis: Vector3 = main._frame_at(2.0)["side"]
	var p_min: float = 1e9
	var p_max: float = -1e9
	for i: int in 120:
		await physics_frame
		var d: float = main.car.global_position.dot(side_axis)
		p_min = minf(p_min, d)
		p_max = maxf(p_max, d)
	check(p_max - p_min > 0.25, "stage1: pendulum sway moves the car (range %.2f m)" % (p_max - p_min))

	# Stage 2: timed release -> scored touchdown -> driving.
	main._do_release()
	var landed: bool = await wait_until(func() -> bool: return main.mode == main.MODE_DRIVE, 700)
	check(landed, "stage2: release drops the car and it lands into DRIVE")
	check(main.last_touchdown != "-", "stage2: touchdown scored (%s)" % main.last_touchdown)

	# Stage 3: drive, climb, hold the bank, cross the gap airborne.
	main.test_throttle = 0.9
	var start_h: float = main.car.global_position.y
	var max_h: float = start_h
	var saw_gap_air: bool = false
	var t: int = 0
	var crossed: bool = false
	while t < 4000:
		autopilot()
		if main.car_s > 185.0 and main.car_s < main.gap_s0:
			main.test_boost = true
		else:
			main.test_boost = false
		await physics_frame
		t += 1
		max_h = maxf(max_h, main.car.global_position.y)
		if main.mode == main.MODE_AIR and main.air_from_gap:
			saw_gap_air = true
		if main.car_s > main.gap_s1 + 6.0 and main.mode == main.MODE_DRIVE:
			crossed = true
			break
		if main.mode == main.MODE_HANG:
			break # fell somewhere - fail below with diagnostics
	check(max_h > start_h + 11.0, "stage3: car climbs (rose %.1f m)" % (max_h - start_h))
	check(saw_gap_air, "stage3: car goes airborne over the gap")
	check(crossed, "stage3: gap crossed and landed, still driving (s=%.0f mode=%d)" % [main.car_s, main.mode])
	main.test_throttle = 0.0
	main.test_boost = false

	# Stage 4: on-demand drone lift -> dangle.
	main._call_drone()
	var dangling: bool = await wait_until(
		func() -> bool: return main.mode == main.MODE_HANG and main.hang_phase == "dangle", 2500)
	check(dangling, "stage4: on-demand lift carries the car to a dangle")

	# Stage 5: prep sequence in order -> boost credit increases.
	main.boost_meter = 40.0
	var boost0: float = main.boost_meter
	var order: Array = main.prep_order.duplicate()
	for idx: Variant in order:
		main._flip_switch(int(idx))
		await frames(3)
	check(main.prep_done, "stage5: prep sequence completes in the shown order")
	check(main.boost_meter > boost0, "stage5: good prep grants boost credit (%.0f -> %.0f)" % [boost0, main.boost_meter])

	# Stage 6: release over the track -> driving resumes.
	main._do_release()
	var resumed: bool = await wait_until(func() -> bool: return main.mode == main.MODE_DRIVE, 700)
	check(resumed, "stage6: release over the track resumes driving")

	# Stage 7: lean experiment changes grip at the bank (bonus layer).
	main.debug_warp_to_s(155.0)
	main.test_lean = -1.0 # lean LEFT, into the left-hand bank
	if not main.lean_on:
		main._toggle_lean()
	await frames(12, true)
	check(main.lean_on and main.grip_mult > 1.05,
		"stage7: lean into the bank raises grip (x%.2f)" % main.grip_mult)
	main.test_lean = 1.0 # wrong way
	await frames(12, true)
	check(main.grip_mult < 0.95,
		"stage7: lean the wrong way drops grip (x%.2f)" % main.grip_mult)
	main.test_lean = -99.0

	print("---")
	print("UNVERIFIED (XR layer, by design): grab-wheel hand tracking; hand-proximity switch flips; HMD lean reading; in-headset panel legibility")
	if failures == 0:
		print("SMOKE: ALL %d CHECKS PASSED" % checks)
	else:
		print("SMOKE: %d of %d CHECKS FAILED" % [failures, checks])
	quit(1 if failures > 0 else 0)
