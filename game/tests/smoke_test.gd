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
##
## Also runs the API GUARD (check_api_surface, reported separately
## below): every XR API method/property the game code calls by name is
## asserted against ClassDB in the running engine. Hotfix 1 exists
## because main.gd called XRCamera3D.get_is_tracking() - a method that
## does not exist in Godot 4.7 - on a line that only executes in XR
## mode, so no headless check ever reached it and the invalid call
## error-spammed the live headset run into a wedge. This guard makes
## that class of bug fail loudly HERE, forever.

var failures: int = 0
var checks: int = 0
var guard_failures: int = 0
var guard_checks: int = 0
var main: Node


func check(cond: bool, stage: String) -> void:
	checks += 1
	if cond:
		print("PASS  ", stage)
	else:
		failures += 1
		print("FAIL  ", stage)


func guard_check(cond: bool, api: String) -> void:
	guard_checks += 1
	if cond:
		print("GUARD PASS  ", api)
	else:
		guard_failures += 1
		print("GUARD FAIL  ", api)


func check_api_surface() -> void:
	# Each entry: the class that defines the API in Godot 4.7 and the
	# method the game code calls by name (receiver expressions noted).
	# ClassDB.class_has_method walks inheritance, so asserting on the
	# defining class is the honest form of "this call can resolve".
	var methods: Array = [
		["XRServer", "find_interface"], # main.gd: XRServer.find_interface("OpenXR")
		["XRInterface", "is_initialized"], # main.gd: xr_interface.is_initialized()
		["XRController3D", "get_input"], # main.gd: ctrl.get_input(action)
		["XRServer", "get_tracker"], # main.gd: XRServer.get_tracker(&"head")
		["XRPositionalTracker", "get_pose"], # main.gd: pose_tracker.get_pose(&"default")
		["XRNode3D", "get_has_tracking_data"], # XRNode3D surface the controllers/camera rig conceptually relies on
	]
	for entry: Variant in methods:
		var pair: Array = entry
		guard_check(ClassDB.class_has_method(pair[0], pair[1]),
			"%s.%s exists in this engine" % [pair[0], pair[1]])
	# XRPose.has_tracking_data is a PROPERTY, not a method (main.gd
	# reads head_pose.has_tracking_data) - assert it via the property
	# list instead.
	var pose_has_prop: bool = false
	for prop: Dictionary in ClassDB.class_get_property_list("XRPose", true):
		if String(prop["name"]) == "has_tracking_data":
			pose_has_prop = true
	guard_check(pose_has_prop, "XRPose.has_tracking_data property exists in this engine")
	# XRNode3D.pose is a PROPERTY main.gd assigns by name in
	# _build_rig (c.pose = &"default" on the hand controllers, Fix
	# Pass 3) - assert it the same way.
	var node3d_has_pose: bool = false
	for prop2: Dictionary in ClassDB.class_get_property_list("XRNode3D", true):
		if String(prop2["name"]) == "pose":
			node3d_has_pose = true
	guard_check(node3d_has_pose, "XRNode3D.pose property exists in this engine")


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
	check_api_surface()
	var ps: PackedScene = load("res://main.tscn")
	main = ps.instantiate()
	root.add_child(main)
	main.test_mode = true
	await frames(5)

	# Stage 1: Drop Start dangle - the pendulum actually swings the car.
	check(main.mode == main.MODE_HANG and main.hang_phase == "dangle",
		"stage1: race opens dangling at Drop Start")
	# Fix Pass 5 re-derivation: the dangle is now TWO pendulum axes on
	# different lengths (resultant path diagonal, never a clean
	# single-plane rhythm), amplitude clearly above the old 0.74 m
	# single-axis sway. Sample 8 s and require real travel on BOTH
	# frame axes plus a large resultant offset from the hang centre.
	# (The old check measured the side axis only over 2 s.)
	var fr_s1: Dictionary = main._frame_at(2.0)
	var side_axis: Vector3 = fr_s1["side"]
	var tan_axis: Vector3 = fr_s1["tan"]
	var centre1: Vector3 = fr_s1["pos"]
	var s_min: float = 1e9
	var s_max: float = -1e9
	var t_min: float = 1e9
	var t_max: float = -1e9
	var r_max: float = 0.0
	for i: int in 480:
		await physics_frame
		var rel1: Vector3 = main.car.global_position - centre1
		var d_side: float = rel1.dot(side_axis)
		var d_tan: float = rel1.dot(tan_axis)
		s_min = minf(s_min, d_side)
		s_max = maxf(s_max, d_side)
		t_min = minf(t_min, d_tan)
		t_max = maxf(t_max, d_tan)
		r_max = maxf(r_max, Vector2(d_side, d_tan).length())
	check(s_max - s_min > 1.2,
		"stage1: dangle swings on the lateral axis (range %.2f m, floor 1.2)" % (s_max - s_min))
	check(t_max - t_min > 1.5,
		"stage1: dangle swings on the fore-aft axis (range %.2f m, floor 1.5)" % (t_max - t_min))
	check(r_max > 1.4,
		"stage1: resultant hang offset is diagonal and large (max %.2f m, floor 1.4)" % r_max)

	# Stage 1b (Fix Pass 2): at swing centre the Drop Start hang point is
	# centred over the ribbon centreline. Zero the pendulum (test-only
	# state poke; the position measured comes from production
	# _hang_car_pos) and measure against the frame at drop_target_s.
	main.pend_th_f = 0.0
	main.pend_th_l = 0.0
	main.pend_om_f = 0.0
	main.pend_om_l = 0.0
	await frames(4)
	var fr_ds: Dictionary = main._frame_at(main.drop_target_s)
	var rel_ds: Vector3 = main.car.global_position - fr_ds["pos"]
	var lat_ds: float = rel_ds.dot(fr_ds["side"])
	check(absf(lat_ds) < 0.05,
		"stage1b: Drop Start hangs centred over the centreline (lat offset %.3f m)" % lat_ds)

	# Stage 2: timed release -> scored touchdown -> driving.
	main._do_release()
	var landed: bool = await wait_until(func() -> bool: return main.mode == main.MODE_DRIVE, 700)
	check(landed, "stage2: release drops the car and it lands into DRIVE")
	check(main.last_touchdown != "-", "stage2: touchdown scored (%s)" % main.last_touchdown)

	# Stage 2c (Fix Pass 5, Item 1): suspension travel + rebound air.
	# The Drop Start landing's rebound should throw the car briefly
	# off the road on the flat start straight - air from BOUNCING,
	# no crest, no gap (Crammond: "you get a lot of air in original
	# game just bouncing"). Watch for a second airborne interval
	# (not gap-flagged) that genuinely rises above the road.
	var hop_seen: bool = false
	var hop_peak: float = 0.0
	for ih: int in 300:
		await physics_frame
		if main.mode == main.MODE_AIR and not main.air_from_gap:
			hop_seen = true
			var fr_h: Dictionary = main._frame_at(main.air_s_est)
			var h_rel: float = (main.car.global_position - fr_h["pos"]).dot(fr_h["up"])
			hop_peak = maxf(hop_peak, h_rel - main.CLEARANCE)
	check(hop_seen and hop_peak > 0.05,
		"stage2c: rebound throws the car airborne after the drop landing (peak %.2f m above road)" % hop_peak)
	# Touchdown compression orders by landing grade, via the
	# production _land path: a calm arrival compresses less than a
	# rough one, and both travel well past rest.
	main.mode = main.MODE_AIR
	main.air_vel = Vector3(0.0, -3.0, 0.0)
	main._land(main._frame_at(main.car_s), 0.0, main.CLEARANCE)
	var c_calm: float = (main.c_f + main.c_r) * 0.5
	main.mode = main.MODE_AIR
	main.air_vel = Vector3(0.0, -8.0, 0.0)
	main._land(main._frame_at(main.car_s), 0.0, main.CLEARANCE)
	var c_rough: float = (main.c_f + main.c_r) * 0.5
	check(c_calm > main.SUSP_REST + 0.08,
		"stage2c: suspension travels at touchdown (calm avg compression %.3f m vs rest %.2f)" % [c_calm, main.SUSP_REST])
	check(c_rough > c_calm + 0.05,
		"stage2c: compression orders by grade (rough %.3f m > calm %.3f m)" % [c_rough, c_calm])
	await frames(10)

	# Stage 2b (Fix Pass 3, Item 5): phantom-lean guard. On the start
	# straight, at standstill and at cruise with ZERO steering input,
	# the car's visual roll (body-roll visual AND car-vs-frame roll)
	# must stay within 1 deg of level. Plus the diagnosed cause: the
	# generator used to leave the corner's bank on ~50 m of following
	# straight (measured 27 deg of frame bank at s=185); the frame on
	# the post-corner straight must now be flat.
	main.debug_warp_to_s(10.0)
	main.speed = 0.0
	main.test_throttle = 0.0
	await frames(30)
	var fr_2b: Dictionary = main._frame_at(main.car_s)
	var up_2b: Vector3 = main.car.global_transform.basis.y
	var roll_2b: float = rad_to_deg(atan2(up_2b.dot(fr_2b["side"]), up_2b.dot(fr_2b["up"])))
	var body_2b: float = rad_to_deg(main.car_body.rotation.z)
	check(absf(body_2b) < 1.0 and absf(roll_2b) < 1.0,
		"stage2b: standstill on the start straight is level (body %.2f deg, car-vs-frame %.2f deg)" % [body_2b, roll_2b])
	main.debug_warp_to_s(10.0)
	main.test_throttle = 0.3
	for i2b: int in 60:
		main.wheel_angle = 0.0 # zero steering input, held
		await physics_frame
	main.test_throttle = 0.0
	var fr_2c: Dictionary = main._frame_at(main.car_s)
	var up_2c: Vector3 = main.car.global_transform.basis.y
	var roll_2c: float = rad_to_deg(atan2(up_2c.dot(fr_2c["side"]), up_2c.dot(fr_2c["up"])))
	var body_2c: float = rad_to_deg(main.car_body.rotation.z)
	check(absf(body_2c) < 1.0 and absf(roll_2c) < 1.0,
		"stage2b: cruise on the start straight is level (body %.2f deg, car-vs-frame %.2f deg, s=%.0f)" % [body_2c, roll_2c, main.car_s])
	check(absf(rad_to_deg(float(main._frame_at(195.0)["bank"]))) < 1.0,
		"stage2b: post-corner straight frame is flat (bank at s=195: %.2f deg)" % rad_to_deg(float(main._frame_at(195.0)["bank"])))

	# Stage 2d (Fix Pass 4, re-derived Fix Pass 5): dash/prep
	# activation is near-touch at 0.15 m, the wheel grab radius is
	# unchanged at 0.40 - and since Fix Pass 5 the LEVERS are
	# measured to their grab SEGMENT (base->cap), not to the tip
	# point: Chris's hand arrives at the shaft. A hand 0.10 m off
	# the MID-SHAFT activates the switch; a hand 0.20 m past the cap
	# (0.20 m from the whole segment) activates nothing. Buttons
	# keep the point measure (restart button: 0.10 yes, 0.20 no).
	check(absf(main.DASH_CTL_RADIUS - 0.15) < 0.001,
		"stage2d: dash activation radius is 0.15 m (got %.2f)" % main.DASH_CTL_RADIUS)
	check(absf(main.WHEEL_GRAB_RADIUS - 0.40) < 0.001,
		"stage2d: wheel grab radius unchanged at 0.40 m (got %.2f)" % main.WHEEL_GRAB_RADIUS)
	var seg0: Array = main._dash_ctl_segment(0)
	var seg_base: Vector3 = seg0[0]
	var seg_tip: Vector3 = seg0[1]
	var seg_dir: Vector3 = (seg_tip - seg_base).normalized()
	var seg_mid: Vector3 = (seg_base + seg_tip) * 0.5
	var seg_perp: Vector3 = seg_dir.cross(Vector3.UP)
	if seg_perp.length() < 0.1:
		seg_perp = seg_dir.cross(Vector3.RIGHT)
	seg_perp = seg_perp.normalized()
	check(main._dash_ctl_near(seg_mid + seg_perp * 0.10) == 0,
		"stage2d: hand 0.10 m off the lever's mid-shaft activates it (grab segment)")
	check(main._dash_ctl_near(seg_tip + seg_dir * 0.20) == -1,
		"stage2d: hand 0.20 m past the cap (from the whole segment) activates nothing")
	var btn_pos: Vector3 = main.dash_ctl_nodes[3].global_position
	check(main._dash_ctl_near(btn_pos + Vector3(0.0, 0.10, 0.0)) == 3,
		"stage2d: hand 0.10 m from a dash button activates it (point measure)")
	check(main._dash_ctl_near(btn_pos + Vector3(0.0, 0.20, 0.0)) == -1,
		"stage2d: hand 0.20 m from a dash button activates nothing")

	# Stage 3: drive, climb, hold the bank, cross the gap airborne.
	main.test_throttle = 0.9
	var start_h: float = main.car.global_position.y
	var max_h: float = start_h
	var saw_gap_air: bool = false
	var max_travel: float = 0.0
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
		max_travel = maxf(max_travel, (main.c_f + main.c_r) * 0.5)
		# Fix Pass 5 re-derivation: at boost speed the launch lip's
		# crest unload + spring rebound can put the car airborne
		# BEFORE the gap (bounce-air, air_from_gap == false), and the
		# same flight can carry the gap - the old assertion demanded
		# the scripted gap entry specifically. What the stage must
		# prove is unchanged: the car is AIRBORNE over the gap span.
		if main.mode == main.MODE_AIR and main.air_s_est > main.gap_s0 - 8.0 and main.air_s_est < main.gap_s1 + 2.0:
			saw_gap_air = true
		if main.car_s > main.gap_s1 + 6.0 and main.mode == main.MODE_DRIVE:
			crossed = true
			break
		if main.mode == main.MODE_HANG:
			break # fell somewhere - fail below with diagnostics
	check(max_h > start_h + 11.0, "stage3: car climbs (rose %.1f m)" % (max_h - start_h))
	check(saw_gap_air, "stage3: car is airborne over the gap (either mechanism)")
	check(max_travel > main.SUSP_REST + 0.05,
		"stage3: suspension works over the course (peak avg compression %.3f m)" % max_travel)
	check(crossed, "stage3: gap crossed and landed, still driving (s=%.0f mode=%d)" % [main.car_s, main.mode])
	main.test_throttle = 0.0
	main.test_boost = false

	# Stage 4: on-demand drone lift -> dangle.
	main._call_drone()
	var dangling: bool = await wait_until(
		func() -> bool: return main.mode == main.MODE_HANG and main.hang_phase == "dangle", 2500)
	check(dangling, "stage4: on-demand lift carries the car to a dangle")

	# Stage 4b (Fix Pass 2): the RECOVERY hang point is centred over the
	# ribbon centreline at swing centre - same zeroed-pendulum measure.
	main.pend_th_f = 0.0
	main.pend_th_l = 0.0
	main.pend_om_f = 0.0
	main.pend_om_l = 0.0
	await frames(4)
	var fr_rc: Dictionary = main._frame_at(main.drop_target_s)
	var rel_rc: Vector3 = main.car.global_position - fr_rc["pos"]
	var lat_rc: float = rel_rc.dot(fr_rc["side"])
	check(absf(lat_rc) < 0.05,
		"stage4b: recovery hangs centred over the centreline (lat offset %.3f m, drop s=%.0f)" % [lat_rc, main.drop_target_s])

	# Stage 5: prep sequence in order -> boost credit increases.
	main.boost_meter = 40.0
	var boost0: float = main.boost_meter
	var order: Array = main.prep_order.duplicate()
	for idx: Variant in order:
		main._flip_switch(int(idx))
		await frames(3)
	check(main.prep_done, "stage5: prep sequence completes in the shown order")
	check(main.boost_meter > boost0, "stage5: good prep grants boost credit (%.0f -> %.0f)" % [boost0, main.boost_meter])

	# Stage 6: release over the track -> driving resumes. The pendulum is
	# still zeroed from stage 4b, so this is a release AT SWING CENTRE -
	# it must land the car on the ribbon, near the centreline.
	main._do_release()
	var resumed: bool = await wait_until(func() -> bool: return main.mode == main.MODE_DRIVE, 700)
	check(resumed, "stage6: release over the track resumes driving")
	check(resumed and absf(main.car_lat) < 0.35,
		"stage6: swing-centre release lands on the ribbon (car_lat %.3f m)" % main.car_lat)

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
	# Stage 7b (Fix Pass 5, Item 4): lean view-tilt amplification.
	# With the experiment ON and a full lean, the ViewSpring node
	# rolls by step x gain (10 deg x 2.5 = ~25 deg, sign opposed to
	# the lean value: lean right tips the view right). With the
	# experiment OFF the view roll is exactly zero - the original
	# "no camera roll" behaviour is now the OFF state.
	main.test_lean = -1.0
	await frames(6, true)
	var tilt_on: float = absf(main.view_node.rotation.z)
	var tilt_expect: float = deg_to_rad(main.LEAN_TILT_STEP_DEG) * main.LEAN_VIEW_GAIN
	check(tilt_on > tilt_expect * 0.75,
		"stage7b: lean ON tilts the view (roll %.1f deg, expect ~%.1f)" % [rad_to_deg(tilt_on), rad_to_deg(tilt_expect)])
	main._toggle_lean() # experiment OFF
	await frames(6, true)
	check(absf(main.view_node.rotation.z) < 0.01,
		"stage7b: lean OFF leaves the view level (roll %.3f deg)" % rad_to_deg(main.view_node.rotation.z))
	main.test_lean = -99.0

	print("---")
	print("UNVERIFIED (XR layer, by design): grab-wheel hand tracking; hand-proximity switch flips; HMD lean reading; in-headset panel legibility")
	if guard_failures == 0:
		print("API GUARD: ALL %d CHECKS PASSED" % guard_checks)
	else:
		print("API GUARD: %d of %d CHECKS FAILED" % [guard_failures, guard_checks])
	if failures == 0:
		print("SMOKE: ALL %d CHECKS PASSED" % checks)
	else:
		print("SMOKE: %d of %d CHECKS FAILED" % [failures, checks])
	quit(1 if failures > 0 or guard_failures > 0 else 0)
