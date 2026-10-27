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
## Fix Pass 6 stages: 2e = driver-body seat spring (sink depth,
## phase lag behind the car springs, ordering by impact, zero at
## rest); 2f = 8 m road width + the engine/skid audio state
## machine (pitch vs speed, skid vs slip/grip/air, teardown latch).
## Fix Pass 7 stages: 2g = the Crammond jitter mechanism (quantised
## physics surface: identical to smooth on the dead-flat straight,
## tremble in the 5-15 mm band on the climb, negative control OFF,
## skid slip identical ON vs OFF, toggle + DIAG); 8 = the FULL
## extended lap driven end to end (crest straight, mirrored
## sweeper, staircase, second gap, finish) with its measured time.
## Fix Pass 8 stages: 9 = the INSTRUMENTED lap (per-frame view
## heave/pitch + frame time logged by main.gd; steps ranked as
## second differences outside genuine events, JIT OFF - the
## frame-step fix's before/after table lives here); 10 = crest
## air on the reshaped humps at 24 m/s (load ~zero from
## geometry, no steering authority airborne, graded landings)
## + 10a, the climb-top negative control for the load-based
## airborne rule that replaced the peak-compression gate.
## Fix Pass 9: the autopilot is now a STEERING driver (pure
## pursuit on the car's own heading - the free-heading model
## has no lateral-offset steering to poke, and no self-drive
## ships in production). Stage 11 gains the two human grip
## orders (grip-first-then-reach, held-grip sweep) for the
## level-based lever activation. New stages: 12 = the
## free-heading model itself (heading-vs-frame divergence on a
## straight, real slip + centring vs counter-steer recovery,
## sweeper divergence measured in stage 8); 13 = the
## edge-straddle save (shoulder support, roll toward the off
## side, the save, the fall past the cutoff, both edges).
## Stage 2f's width check is the Crammond proportion: road =
## 6.0x the measured front wheel track.
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


func swap_hand_path(p: String) -> String:
	# Fix Pass 10 (Item 0): the path a LEFT binding must mirror on
	# the RIGHT hand: the user path swaps, and the face-button
	# NAMES swap with it - the left controller's buttons are
	# physically labelled X/Y where the right's are A/B (that is
	# why the actions are named ax_button / by_button). Every
	# other component the game binds (squeeze, trigger,
	# thumbstick, aim...) is spelled identically on both hands.
	var s: String = p.replace("/user/hand/left", "/user/hand/right")
	s = s.replace("/input/x/", "/input/a/").replace("/input/y/", "/input/b/")
	return s


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
		["AudioStreamPlayer", "play"], # Fix Pass 6: engine_player.play() / skid_player.play()
		["AudioStreamPlayer", "stop"], # Fix Pass 6: the teardown latch stops both players
		["Time", "get_ticks_msec"], # Fix Pass 6: audio stall-watchdog heartbeat
		["Time", "get_ticks_usec"], # Fix Pass 8: the step logger's frame-time column
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
	# Fix Pass 6: AudioStreamWAV properties main.gd assigns by name
	# when it generates the engine/skid streams (format, mix_rate,
	# data, loop_mode, loop_begin, loop_end).
	var wav_props: Array[String] = []
	for prop3: Dictionary in ClassDB.class_get_property_list("AudioStreamWAV", true):
		wav_props.append(String(prop3["name"]))
	for pname: String in ["format", "mix_rate", "data", "loop_mode", "loop_begin", "loop_end"]:
		guard_check(wav_props.has(pname),
			"AudioStreamWAV.%s property exists in this engine" % pname)
	# Fix Pass 6: the notification constants _notification switches
	# on (audio teardown latch) - integer constants on Node in 4.7.
	var node_consts: PackedStringArray = ClassDB.class_get_integer_constant_list("Node", true)
	for cname: String in ["NOTIFICATION_APPLICATION_FOCUS_OUT", "NOTIFICATION_APPLICATION_FOCUS_IN",
			"NOTIFICATION_WM_CLOSE_REQUEST", "NOTIFICATION_EXIT_TREE"]:
		guard_check(node_consts.has(cname),
			"Node.%s constant exists in this engine" % cname)
	# Fix Pass 10 (Item 0): ACTION-MAP BINDING SYMMETRY. Run 10's
	# video forensics: the LEFT grip channel read 0.00 on every
	# channel in every frame while the right cycled to 1.00 -
	# one hand's signal simply never arrived. The shipped map
	# itself parses SYMMETRIC (see the Fix Pass 10 report), so
	# this guard is the tripwire that keeps it that way: parse
	# the loaded OpenXRActionMap and ASSERT, for every action
	# the game reads, that in every interaction profile the set
	# of LEFT binding paths equals the set of RIGHT paths with
	# the hand swapped (see swap_hand_path: the swap includes
	# the face-button letters, X<->A and Y<->B - the one place
	# the two controllers' paths legitimately differ in
	# spelling while binding the same control role). A
	# one-sided binding edit - the class of
	# failure that ships silently because headless runs never
	# touch a live channel - now fails HERE. Presence is also
	# asserted where it matters: in the profiles a Quest/Virtual
	# Desktop session negotiates (oculus touch, khr generic),
	# grip / trigger / primary_click must be bound for BOTH
	# hands, so a hand can never lose its core channels whole.
	var game_actions: Array[String] = ["grip", "grip_click", "grip_force",
		"trigger", "trigger_click", "ax_button", "by_button",
		"primary_click", "primary", "default_pose"]
	var map_res: Resource = load(ProjectSettings.get_setting("xr/openxr/default_action_map"))
	guard_check(map_res is OpenXRActionMap, "action map loads as OpenXRActionMap")
	if map_res is OpenXRActionMap:
		var amap: OpenXRActionMap = map_res as OpenXRActionMap
		for prof: OpenXRInteractionProfile in amap.get_interaction_profiles():
			var per: Dictionary = {} # action -> {"L": [...], "R": [...]}
			for b: OpenXRIPBinding in prof.get_bindings():
				var aname: String = b.action.resource_name
				if not game_actions.has(aname):
					continue
				var bp: String = b.binding_path
				var side: String = ""
				if bp.begins_with("/user/hand/left"):
					side = "L"
				elif bp.begins_with("/user/hand/right"):
					side = "R"
				else:
					continue
				if not per.has(aname):
					per[aname] = {"L": [], "R": []}
				(per[aname] as Dictionary)[side].append(bp)
			for aname2: String in game_actions:
				var d: Dictionary = per.get(aname2, {"L": [], "R": []})
				var lset: Array = (d["L"] as Array).duplicate()
				var rset: Array = (d["R"] as Array).duplicate()
				var lswap: Array = []
				for p: Variant in lset:
					lswap.append(swap_hand_path(String(p)))
				lswap.sort()
				rset.sort()
				guard_check(lswap == rset,
					"map symmetry: %s '%s' L paths == R paths swapped (L=%s R=%s)"
						% [prof.interaction_profile_path, aname2, str(lset), str(rset)])
			if prof.interaction_profile_path in [
					"/interaction_profiles/oculus/touch_controller",
					"/interaction_profiles/khr/generic_controller"]:
				for core: String in ["grip", "trigger", "primary_click"]:
					var dc: Dictionary = per.get(core, {"L": [], "R": []})
					guard_check((dc["L"] as Array).size() > 0 and (dc["R"] as Array).size() > 0,
						"map presence: %s binds '%s' for BOTH hands" % [prof.interaction_profile_path, core])


func autopilot() -> void:
	# Fix Pass 9: the autopilot is a STEERING driver now (test
	# code only - no self-drive ships). Pure pursuit: aim the
	# car's own heading at a spine point a speed-scaled
	# lookahead ahead, and convert the heading error into a
	# wheel angle in the same +-PI range the hands use (sign:
	# positive wheel = right turn, so the wheel opposes the
	# heading error). Speed is curvature-capped the same way a
	# careful driver caps it: the lateral-acceleration budget
	# (11 m/s^2 - the model's own grip limit) over the coming
	# 46 m, and 24 m/s wherever the vertical curvature says
	# humps (the stage-10 cruise the humps were shaped for).
	_autopilot_drive(0.0, true)


func autopilot_pursuit() -> void:
	# Pursuit steering WITHOUT speed management - the fixture
	# for stages that must overdrive a corner on purpose
	# (2f/2g's forced slip): the speed-managed autopilot brakes
	# to the grip-limited pace and the car simply grips, which
	# is correct driving and a useless slip fixture.
	_autopilot_drive(0.0, false)


func autopilot_steer(lat_off: float = 0.0) -> void:
	# Steering only, at a lateral offset from the centreline -
	# the straddle stage parks the car on the shoulder with
	# this while the stage itself owns the throttle. A PD lane-
	# change law, NOT the pursuit: the desired heading is the
	# frame direction corrected by an approach angle from the
	# lateral error, DAMPED by the car's lateral velocity -
	# the undamped version overshot the shoulder target all
	# the way to the fall line (the heading obeys at once, the
	# velocity's lateral lag carries the car onward). The
	# damping term's sign: the velocity already points
	# lat_vel/vf radians toward the +lat side of the heading,
	# so the heading aims that much back the other way
	# (+lat_vel in this formula - an earlier draft had it
	# backwards and anti-damped the car off the edge). Used
	# only on straights (the crest straight, the home
	# straight), where the frame direction is the road's.
	# The law aims the VELOCITY, not the heading: desired
	# velocity direction = frame direction + a GENTLE approach
	# angle from the lateral error (capped at ~8 deg - the
	# straddle target sits only 1.6 m from the fall line, and
	# at the 11 m/s^2 grip limit a faster approach cannot be
	# stopped inside it; the ~24 deg approach measured in the
	# FP9 probe arrived with 5 m/s of lateral velocity and
	# went over), and the desired heading is that direction
	# plus the current slip angle (the heading must lead the
	# velocity by exactly the angle it lags).
	var fr: Dictionary = main._frame_at(main.car_s)
	var fy: float = main._frame_yaw(fr["tan"])
	var lat_err: float = main.car_lat - lat_off
	var slip_ang: float = atan2(main.lat_vel, maxf(absf(main.speed), 3.0))
	var desired: float = fy + clampf(lat_err * 0.12, -0.14, 0.14) + slip_ang
	var err: float = wrapf(desired - main.car_heading, -PI, PI)
	main.wheel_angle = clampf(-err * 1.6, -1.0, 1.0) * PI


func _autopilot_drive(lat_off: float, with_speed: bool) -> void:
	var s: float = main.car_s
	var spd: float = maxf(main.speed, 0.0)
	var la: float = clampf(spd * 0.55, 6.0, 22.0)
	var fr_t: Dictionary = main._frame_at(s + la)
	var tgt: Vector3 = fr_t["pos"] + fr_t["side"] * lat_off
	var pos: Vector3 = main.car.global_position
	var desired: float = atan2(-(tgt.x - pos.x), -(tgt.z - pos.z))
	var err: float = wrapf(desired - main.car_heading, -PI, PI)
	main.wheel_angle = clampf(-err * 1.6, -1.0, 1.0) * PI
	if with_speed:
		var max_kv: float = 0.0
		var max_curv: float = 0.0
		var ss: float = s
		while ss < s + 46.0:
			var fr_q: Dictionary = main._frame_at(ss)
			max_kv = maxf(max_kv, absf(float(fr_q["kv"])))
			max_curv = maxf(max_curv, absf(float(fr_q["curv"])))
			ss += 4.0
		var v_allow: float = clampf(sqrt(11.0 / maxf(max_curv, 0.0001)), 9.0, 34.0)
		if max_kv > 0.012:
			v_allow = minf(v_allow, 24.0)
		if main.speed < v_allow:
			main.test_throttle = 0.9
			main.test_brake = 0.0
		else:
			main.test_throttle = 0.0
			main.test_brake = 0.7


func grip_flip_switch(switch_idx: int, hand: String = "R") -> void:
	# Fix Pass 8 (Item 0): flip a prep switch through the
	# PRODUCTION grip path - the synthetic hand is posed on the
	# switch's grab segment (production geometry via
	# _dash_ctl_segment), proximity is resolved by
	# _dash_ctl_near, and the flip must come from _poll_grab
	# into _activate_dash_ctl -> _flip_switch. (Fix Pass 9:
	# pose-then-grip is one of the two human orders the
	# level-based activation serves; stage 11a covers the
	# other.)
	# Nothing here calls _flip_switch directly. The poll calls
	# are synchronous (no physics frames between posing and
	# polling), so the swinging car cannot move the segment
	# mid-flip.
	var ctl: int = main.dash_ctl_kinds.find("switch%d" % switch_idx)
	var seg: Array[Vector3] = main._dash_ctl_segment(ctl)
	main.test_hand_pos[hand] = (seg[0] + seg[1]) * 0.5
	main.test_hand_set = true
	# released for two polls (a clean not-gripping state), one
	# gripped poll (the edge), released again
	main.test_grip[hand] = 0.0
	main._poll_grab(hand, main.hand_ctrl[hand], 1.0 / 90.0)
	main._poll_grab(hand, main.hand_ctrl[hand], 1.0 / 90.0)
	main.test_grip[hand] = 1.0
	main._poll_grab(hand, main.hand_ctrl[hand], 1.0 / 90.0)
	main.test_grip[hand] = 0.0
	main._poll_grab(hand, main.hand_ctrl[hand], 1.0 / 90.0)


func prep_one_hand(hand: String) -> bool:
	# Fix Pass 10 (Item 0, stage 15): complete a full prep
	# sequence on a fresh Drop Start dangle using ONE hand,
	# with the other hand's grip held at 0.0 the whole time (a
	# simulated DEAD channel) and its hand parked far away, so
	# no zone entry can be credited to it. Returns prep_done.
	var other: String = "L" if hand == "R" else "R"
	main.start_race()
	await frames(4)
	main.test_grip[other] = 0.0
	main.test_hand_pos[other] = main.car.global_position + Vector3(5.0, 5.0, 5.0)
	main.test_hand_set = true
	for idx: Variant in main.prep_order.duplicate():
		grip_flip_switch(int(idx), hand)
	return main.prep_done and float(main.test_grip[other]) == 0.0


func hf_p2p(series: Array) -> float:
	# Fix Pass 7 (stage 2g): high-frequency peak-to-peak of a
	# sampled series - the series minus a centred 31-sample moving
	# average, extremes over the uncontaminated middle span.
	var n: int = series.size()
	if n < 40:
		return 0.0
	var lo: float = 1e9
	var hi: float = -1e9
	for i: int in range(15, n - 15):
		var acc: float = 0.0
		for k: int in range(i - 15, i + 16):
			acc += float(series[k])
		var resid: float = float(series[i]) - acc / 31.0
		lo = minf(lo, resid)
		hi = maxf(hi, resid)
	return hi - lo


func measure_shelf(jit_window: bool) -> Array:
	# Fix Pass 7 (stage 2g) fixture: cruise the steady-slope shelf
	# of the climb (phi steady at 16 deg from s~98 to the corner at
	# s=131, so the smooth geom is constant and detrended travel
	# variation IS the high-frequency content) at a pinned 20 m/s;
	# returns [front, rear, avg] HF peak-to-peak travel. The
	# springs are poked to rest after the warp (a warp leaves them
	# wherever the previous stage dropped them, and their
	# ring-down would swamp a millimetre measurement) and both
	# arms settle with jitter OFF - the window is the only
	# difference between arms.
	main.debug_warp_to_s(98.0)
	main.test_throttle = 0.0
	main.c_f = main.SUSP_REST
	main.c_r = main.SUSP_REST
	main.cv_f = 0.0
	main.cv_r = 0.0
	main.jitter_on = false
	for i: int in 24:
		autopilot()
		main.debug_pin_speed(20.0)
		await physics_frame
	main.jitter_on = jit_window
	var sf: Array = []
	var sr: Array = []
	for i2: int in 100:
		autopilot()
		main.debug_pin_speed(20.0)
		await physics_frame
		sf.append(main.c_f)
		sr.append(main.c_r)
	var savg: Array = []
	for j: int in sf.size():
		savg.append((float(sf[j]) + float(sr[j])) * 0.5)
	return [hf_p2p(sf), hf_p2p(sr), hf_p2p(savg)]


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

	# Stage 2e (Fix Pass 6, Item 1): the driver-BODY seat spring.
	# A second, softer spring under the viewpoint only: staged
	# touchdowns through the production _land path must (a) dip the
	# view beyond the car-spring trace (the sink IS that extra dip),
	# (b) peak AFTER the car springs' peak compression - the phase
	# lag is the whole effect, (c) order by impact, (d) return to
	# ~zero at rest.
	main.debug_warp_to_s(10.0)
	main.debug_pin_speed(0.0)
	main.test_throttle = 0.0
	await frames(150) # settle from the warp: spring back to rest
	check(absf(main.body_sink) < 0.002,
		"stage2e: body spring is zero at rest (sink %.4f m)" % main.body_sink)
	main.mode = main.MODE_AIR
	main.air_vel = Vector3(0.0, -3.0, 0.0)
	main._land(main._frame_at(main.car_s), 0.0, main.CLEARANCE)
	var car_peak1: float = 0.0
	var car_i1: int = -1
	var sink_peak1: float = 0.0
	var sink_i1: int = -1
	for ib: int in 150:
		await physics_frame
		var cc1: float = (main.c_f + main.c_r) * 0.5
		if cc1 > car_peak1:
			car_peak1 = cc1
			car_i1 = ib
		if main.body_sink > sink_peak1:
			sink_peak1 = main.body_sink
			sink_i1 = ib
	check(sink_peak1 > 0.006,
		"stage2e: view sinks in the seat past the car-spring trace (peak sink %.3f m)" % sink_peak1)
	check(sink_i1 > car_i1,
		"stage2e: peak sink lands AFTER peak car compression (frame %d vs %d)" % [sink_i1, car_i1])
	main.mode = main.MODE_AIR
	main.air_vel = Vector3(0.0, -8.0, 0.0)
	main._land(main._frame_at(main.car_s), 0.0, main.CLEARANCE)
	var sink_peak2: float = 0.0
	for ib2: int in 240:
		await physics_frame
		sink_peak2 = maxf(sink_peak2, main.body_sink)
	check(sink_peak2 > sink_peak1 + 0.006,
		"stage2e: sink depth orders by impact (rough %.3f m > calm %.3f m)" % [sink_peak2, sink_peak1])
	check(absf(main.body_sink) < 0.003,
		"stage2e: body spring settles back to ~zero (sink %.4f m)" % main.body_sink)

	# Stage 2b (Fix Pass 3, Item 5): phantom-lean guard. On the start
	# straight, at standstill and at cruise with ZERO steering input,
	# the car's visual roll (body-roll visual AND car-vs-frame roll)
	# must stay within 1 deg of level. Plus the diagnosed cause: the
	# generator used to leave the corner's bank on ~50 m of following
	# straight (measured 27 deg of frame bank at s=185); the frame on
	# the post-corner straight must now be flat.
	main.debug_warp_to_s(10.0)
	main.debug_pin_speed(0.0)
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

	# Stage 2f (Fix Pass 6, Items 2 + 3): the road width and the
	# audio state machine. Sound QUALITY is not asserted anywhere
	# here (headless cannot hear) - only that the channels track
	# the model's state: engine pitch monotonic with speed, skid
	# gain ~0 while gripping and while airborne, > 0 under forced
	# slip, and the focus-out latch stops both players.
	# Fix Pass 9 (Item 3) set the width by Crammond's PROPORTION
	# (6.0x the wheel track = 9.36 m). Fix Pass 10 (Item 3)
	# supersedes it with the owner's absolute: 12.0 m full -
	# "wide enough for two cars to pass each other". Reported
	# in car bodies as well as metres (the eye reads bodies).
	check(absf(main.HALF_WIDTH - 6.0) < 0.001,
		"stage2f: road is 12.0 m full (half %.2f m)" % main.HALF_WIDTH)
	var body_w2f: float = main.debug_body_width_m()
	print("stage2f: car BODY width %.2f m -> road is %.2f bodies wide" % [body_w2f, 12.0 / body_w2f])
	check(body_w2f > 1.5 and body_w2f < 2.1,
		"stage2f: body width measured off the built meshes (%.2f m)" % body_w2f)
	main.debug_warp_to_s(10.0)
	main.test_throttle = 0.0
	main.debug_pin_speed(6.0)
	await frames(50)
	var pitch_lo: float = main.audio_engine_pitch()
	main.debug_pin_speed(26.0)
	await frames(50)
	var pitch_hi: float = main.audio_engine_pitch()
	check(pitch_hi > pitch_lo + 0.3,
		"stage2f: engine pitch tracks speed (%.2f at ~6 m/s -> %.2f at ~26 m/s)" % [pitch_lo, pitch_hi])
	check(main.audio_skid_gain() < 0.02,
		"stage2f: skid silent while gripping on the straight (gain %.3f)" % main.audio_skid_gain())
	# Forced slip: the banked corner at speed - the model's real
	# lateral velocity is large (Fix Pass 9: slip_state derives
	# from it). Warped to the corner ENTRY and given 80 frames:
	# at 24 m/s the R30 corner demands ~19 m/s^2 against an
	# ~11 m/s^2 grip limit plus the bank's help, so the slide
	# develops over ~2/3 s and saturates - the old model's
	# instantaneous drift proxy read full slip in 35 frames,
	# the real one has to break loose first (measured, probe).
	main.debug_warp_to_s(145.0)
	main.debug_pin_speed(24.0)
	main.test_throttle = 0.3
	main.test_brake = 0.0
	for i2f: int in 80:
		autopilot_pursuit()
		await physics_frame
	check(main.audio_skid_gain() > 0.15,
		"stage2f: skid sounds under forced slip at the bank (gain %.2f, slip %.2f)" % [main.audio_skid_gain(), main.slip_state])
	main.test_throttle = 0.0
	# Airborne: tires unload, the skid silences. (30 frames:
	# the gain follower decays at 22/s from the segment's full
	# slip - from 1.0 it needs ~0.3 s to fall silent, where the
	# old model's smaller slip cleared it in 10 frames.)
	main.debug_stage_landing(232.0, 3.0, 12.0)
	await frames(30)
	check(main.mode == main.MODE_AIR and main.audio_skid_gain() < 0.05,
		"stage2f: skid silent while airborne (gain %.3f)" % main.audio_skid_gain())
	var landed2: bool = await wait_until(func() -> bool: return main.mode == main.MODE_DRIVE, 300)
	check(landed2, "stage2f: staged flight lands back into DRIVE")
	# Teardown latch (the _notification focus-out path's function):
	# latched = both players stopped; unlatch = engine resumes,
	# but only because a race is live.
	main._set_audio_latched(true)
	await frames(3)
	check(main.audio_latched and not main.engine_player.playing and not main.skid_player.playing,
		"stage2f: focus-out latch silences both players")
	main._set_audio_latched(false)
	await frames(5)
	check(not main.audio_latched and main.engine_player.playing,
		"stage2f: focus-in unlatch resumes the engine in a live race")
	main.debug_warp_to_s(10.0)
	main.debug_pin_speed(10.0)
	await frames(5)

	# Stage 2g (Fix Pass 7, Item 2): the Crammond jitter mechanism.
	# (a) Surface level: over the dead-flat start straight the
	# quantised profile is IDENTICAL to the smooth one - on a
	# mathematically flat road the mechanism is silent, exactly as
	# in the original (its flattest decoded profile is 14 zeros;
	# crammond-notes.md Q3). Over the climb the quantisation
	# bites: the brief's cruise measurement therefore lives on the
	# climb, and what the mechanism gives there is reported, not
	# forced. (b) Cruise level: jitter ON puts per-axle travel
	# tremble in the 5-15 mm target band; jitter OFF collapses to
	# ~0 (the negative control). (c) The skid must not hear the
	# tremble: forced-slip readings at the bank are identical ON
	# vs OFF (Fix Pass 9: slip is the real lateral velocity, and
	# the plan-view trajectory it follows is jitter-independent -
	# the quantised surface only moves the springs). (d) The
	# toggle flips the state and the DIAG block reports it.
	var q_flat: float = 0.0
	var q_climb: float = 0.0
	for iq: int in 201:
		# Fix Pass 8: the flat window is the start straight's
		# MIDDLE (s 5..40). FP8's build-time profile smoothing
		# rounds the straight->climb join over ~2 samples, so
		# the last metres before the climb are no longer
		# mathematically flat (by design); the property asserted
		# here - quantisation is silent on a flat road - is
		# measured where the road is flat.
		var sq1: float = 5.0 + float(iq) * 0.175
		q_flat = maxf(q_flat, absf(main._elev_quantised(sq1) - main._elev_smooth(sq1)))
		var sq2: float = 60.0 + float(iq) * 0.25
		q_climb = maxf(q_climb, absf(main._elev_quantised(sq2) - main._elev_smooth(sq2)))
	check(q_flat < 0.0005,
		"stage2g: quantised surface == smooth on the dead-flat straight (max diff %.4f m)" % q_flat)
	check(q_climb > 0.004,
		"stage2g: quantisation bites on the climb (max diff %.4f m)" % q_climb)
	var shelf_off: Array = await measure_shelf(false)
	var shelf_on: Array = await measure_shelf(true)
	check(float(shelf_on[0]) > 0.005 and float(shelf_on[0]) < 0.020
			and float(shelf_on[1]) > 0.005 and float(shelf_on[1]) < 0.020,
		"stage2g: per-axle tremble in the 5-15 mm band, jitter ON (front %.1f mm, rear %.1f mm p2p)"
			% [float(shelf_on[0]) * 1000.0, float(shelf_on[1]) * 1000.0])
	check(float(shelf_on[2]) > 0.0035 and float(shelf_on[2]) < 0.020,
		"stage2g: avg-axle HF travel in band, jitter ON (%.1f mm p2p)" % (float(shelf_on[2]) * 1000.0))
	check(float(shelf_off[2]) < 0.002,
		"stage2g: NEGATIVE CONTROL - jitter OFF is ~silent on the shelf (avg HF travel %.1f mm p2p)"
			% (float(shelf_off[2]) * 1000.0))
	main.debug_warp_to_s(145.0)
	main.debug_pin_speed(24.0)
	main.test_throttle = 0.3
	main.test_brake = 0.0 # measure_shelf's speed-managed autopilot leaves brake behind
	main.jitter_on = true
	for isl: int in 80:
		autopilot_pursuit()
		await physics_frame
	var slip_jit: float = main.slip_state
	main.debug_warp_to_s(145.0)
	main.debug_pin_speed(24.0)
	main.test_brake = 0.0
	main.jitter_on = false
	for isl2: int in 80:
		autopilot_pursuit()
		await physics_frame
	var slip_smooth: float = main.slip_state
	main.test_throttle = 0.0
	check(slip_jit > 0.15 and absf(slip_jit - slip_smooth) < 0.02,
		"stage2g: skid slip identical ON vs OFF (%.3f vs %.3f) - the tremble is not slip" % [slip_jit, slip_smooth])
	main.jitter_on = true
	main._toggle_jitter()
	check(not main.jitter_on and main._build_diag_block().contains("JIT OFF"),
		"stage2g: toggle turns jitter OFF and the DIAG block says so")
	main._toggle_jitter()
	check(main.jitter_on and main._build_diag_block().contains("JIT ON"),
		"stage2g: toggle restores jitter ON (the default) and the DIAG block says so")

	# Stage 3: drive, climb, hold the bank, cross the gap airborne.
	# (Fix Pass 7 sequencing: stage 2g now sits between 2f and here
	# and leaves the car at the bank - restore this stage's
	# original start premise, the s=10 warp stage 2f used to end
	# on. No assertion changes.)
	main.debug_warp_to_s(10.0)
	main.debug_pin_speed(10.0)
	await frames(5)
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

	# Stage 8 (Fix Pass 7, Item 1): the FULL extended lap, driven
	# end to end from a fresh Drop Start through the production
	# release: the original lap, then the crest straight, the
	# mirrored sweeper, the descending staircase, the second gap,
	# the final climb and the home straight to the relocated
	# finish. (Boost is topped up once before the second gap -
	# the prep credit a driver would have banked at a drone stop;
	# the autopilot has no hands for switches.)
	main.start_race()
	main.pend_th_f = 0.0
	main.pend_th_l = 0.0
	main.pend_om_f = 0.0
	main.pend_om_l = 0.0
	await frames(4)
	main._do_release()
	var rel8: bool = await wait_until(func() -> bool: return main.mode == main.MODE_DRIVE, 700)
	check(rel8, "stage8: fresh Drop Start release lands into DRIVE for the full lap")
	main.test_throttle = 0.9
	var topped8: bool = false
	var in_sweeper: bool = false
	var gap2_air: bool = false
	var crest_work: float = 0.0
	var stairs_work: float = 0.0
	var t8: int = 0
	var lap_done: bool = false
	# Fix Pass 9 (Item 2, assertion d): heading-vs-frame
	# divergence through the banked sweeper - the car runs at a
	# slip angle there, so its heading and the frame's heading
	# are measurably different quantities now.
	var sweep_div_max: float = 0.0
	var sweep_div_sum: float = 0.0
	var sweep_div_n: int = 0
	while t8 < 20000:
		autopilot()
		main.test_boost = (main.car_s > 185.0 and main.car_s < main.gap_s0) \
			or (main.car_s > main.gap2_s0 - 25.0 and main.car_s < main.gap2_s0)
		if not topped8 and main.car_s > main.gap2_s0 - 80.0:
			main.boost_meter = 60.0
			topped8 = true
		await physics_frame
		t8 += 1
		if main.car_s > main.sweeper_s0 and main.car_s < main.sweeper_s1:
			in_sweeper = true
			if main.mode == main.MODE_DRIVE:
				var fr8: Dictionary = main._frame_at(main.car_s)
				var dv8: float = rad_to_deg(absf(wrapf(main.car_heading - main._frame_yaw(fr8["tan"]), -PI, PI)))
				sweep_div_max = maxf(sweep_div_max, dv8)
				sweep_div_sum += dv8
				sweep_div_n += 1
		if main.mode == main.MODE_AIR and main.air_s_est > main.gap2_s0 - 8.0 and main.air_s_est < main.gap2_s1 + 2.0:
			gap2_air = true
		if main.car_s > main.ext_s0 and main.car_s < main.sweeper_s0:
			crest_work = maxf(crest_work, (main.c_f + main.c_r) * 0.5)
		if main.car_s > main.sweeper_s1 + 20.0 and main.car_s < main.gap2_s0 - 45.0:
			stairs_work = maxf(stairs_work, (main.c_f + main.c_r) * 0.5)
		if main.mode == main.MODE_DONE:
			lap_done = true
			break
		if main.mode == main.MODE_HANG:
			break # fell somewhere - fail below with diagnostics
	main.test_throttle = 0.0
	main.test_boost = false
	check(lap_done,
		"stage8: FULL extended lap driven to the finish (s=%.0f mode=%d, track %.0f m)" % [main.car_s, main.mode, main.track_len])
	check(in_sweeper,
		"stage8: the mirrored sweeper is on the driven line (s %.0f-%.0f)" % [main.sweeper_s0, main.sweeper_s1])
	check(gap2_air,
		"stage8: airborne over the second gap (s %.0f-%.0f)" % [main.gap2_s0, main.gap2_s1])
	check(crest_work > main.SUSP_REST + 0.05,
		"stage8: crest straight works the suspension (peak avg compression %.3f m)" % crest_work)
	check(stairs_work > main.SUSP_REST + 0.15,
		"stage8: staircase hammers the suspension (peak avg compression %.3f m)" % stairs_work)
	var sweep_div_avg: float = sweep_div_sum / maxf(float(sweep_div_n), 1.0)
	check(sweep_div_max > 3.0,
		"stage8: heading diverges from the frame heading through the sweeper (max %.1f deg, typical %.1f deg over %d frames)"
			% [sweep_div_max, sweep_div_avg, sweep_div_n])
	print("stage8: measured full-lap time %.1f s (game clock) over %.0f m of ribbon" % [main.finished_time, main.track_len])

	# Stage 9 (Fix Pass 8, Item 1): the INSTRUMENTED lap. A full
	# lap driven with the step logger on and JIT OFF (Chris's
	# run-8 condition - his capture shows JIT OFF throughout, so
	# the jitter mechanism is exonerated and the measurement runs
	# in his condition). main.gd logs per physics frame: s, mode,
	# the view height/pitch the eye rides, and the wall frame
	# time. Analysis: per-frame steps on consecutive DRIVE
	# frames, excluding genuine events (any non-DRIVE frame and
	# the 12 frames after re-entering DRIVE - landings, the
	# rebound hop's touchdown, the release). The full-view
	# top-10 tables print for the record; the checks assert the
	# GEOMETRY channels (frame pitch + frame_y, logged alongside),
	# which isolate the sampled road from the spring integrators.
	main.jitter_on = false
	main.start_race()
	main.pend_th_f = 0.0
	main.pend_th_l = 0.0
	main.pend_om_f = 0.0
	main.pend_om_l = 0.0
	main.step_rows.clear()
	main._step_last_us = 0
	main.step_log_on = true
	await frames(4)
	main._do_release()
	var rel9: bool = await wait_until(func() -> bool: return main.mode == main.MODE_DRIVE, 700)
	check(rel9, "stage9: Drop Start release lands into DRIVE for the instrumented lap")
	main.test_throttle = 0.9
	var topped9: bool = false
	var t9: int = 0
	var lap9_done: bool = false
	while t9 < 20000:
		autopilot()
		main.test_boost = (main.car_s > 185.0 and main.car_s < main.gap_s0) \
			or (main.car_s > main.gap2_s0 - 25.0 and main.car_s < main.gap2_s0)
		if not topped9 and main.car_s > main.gap2_s0 - 80.0:
			main.boost_meter = 60.0
			topped9 = true
		await physics_frame
		t9 += 1
		if main.mode == main.MODE_DONE:
			lap9_done = true
			break
		if main.mode == main.MODE_HANG:
			break
	main.test_throttle = 0.0
	main.test_boost = false
	main.step_log_on = false
	check(lap9_done, "stage9: instrumented lap completed (mode=%d)" % main.mode)
	var rows9: Array = main.step_rows
	# median DRIVE-frame wall time (the hitch yardstick)
	var fus: Array = []
	for r9: Array in rows9:
		if int(r9[1]) == main.MODE_DRIVE and float(r9[4]) > 0.0:
			fus.append(float(r9[4]))
	fus.sort()
	var med_us: float = float(fus[fus.size() / 2]) if fus.size() > 0 else 0.0
	# A STEP is a discontinuity: the per-frame delta CHANGES
	# abruptly. Raw deltas are just velocity (on the 16 deg climb
	# the view legitimately rises ~0.11 m/frame), so the tables
	# rank the SECOND differences - |d(dy)| and |d(dpitch)| -
	# which are ~0 in smooth motion however fast, and spike
	# exactly where the trajectory kinks.
	var last_bad: int = -100000 # last row index that was not plain DRIVE
	var dv_list: Array = []
	var dp_list: Array = []
	# The GEOMETRY channels (frame pitch, column 5; frame_y,
	# column 8 - the height the sampled road alone places the
	# car at). The view channels ride the spring/body
	# integrators, which are continuous except at genuine
	# events, so steps in the geometry channels outside events
	# are sampling/join mechanisms by elimination - the thing
	# item 1 exists to remove. These are the ASSERTED numbers;
	# the full-view tables print for the record (their tops are
	# expected to be event tails: hump-flight landing ring-down,
	# staircase bottoming).
	var gv_list: Array = []
	var gp_list: Array = []
	var raw_dy_max: float = 0.0
	var hitch_frames: int = 0
	for i9: int in rows9.size():
		var rr: Array = rows9[i9]
		if int(rr[1]) != main.MODE_DRIVE:
			last_bad = i9
			continue
		if float(rr[4]) > med_us * 2.0 + 3000.0:
			hitch_frames += 1
		if i9 < 2 or i9 - last_bad <= 12:
			continue
		var pv: Array = rows9[i9 - 1]
		var pv2: Array = rows9[i9 - 2]
		if int(pv[1]) != main.MODE_DRIVE or int(pv2[1]) != main.MODE_DRIVE:
			continue
		raw_dy_max = maxf(raw_dy_max, absf(float(rr[2]) - float(pv[2])))
		var dv9: float = absf((float(rr[2]) - float(pv[2])) - (float(pv[2]) - float(pv2[2])))
		var dp9: float = rad_to_deg(absf((float(rr[3]) - float(pv[3])) - (float(pv[3]) - float(pv2[3]))))
		dv_list.append([dv9, float(rr[0]), float(rr[4])])
		dp_list.append([dp9, float(rr[0]), float(rr[4])])
		var gv9: float = absf((float(rr[8]) - float(pv[8])) - (float(pv[8]) - float(pv2[8])))
		var gp9: float = rad_to_deg(absf((float(rr[5]) - float(pv[5])) - (float(pv[5]) - float(pv2[5]))))
		gv_list.append([gv9, float(rr[0]), float(rr[4])])
		gp_list.append([gp9, float(rr[0]), float(rr[4])])
	dv_list.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) > float(b[0]))
	dp_list.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) > float(b[0]))
	gv_list.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) > float(b[0]))
	gp_list.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) > float(b[0]))
	print("stage9: %d DRIVE frames analysed, median frame %.0f us, %d hitch frames (>2x median + 3 ms), raw |dy| max %.3f m/frame (velocity, not steps)"
		% [dv_list.size(), med_us, hitch_frames, raw_dy_max])
	print("stage9: TOP-10 view-height STEPS outside events (|d(dy)| m | s | frame us):")
	for e9: Array in dv_list.slice(0, 10):
		print("   step %.4f m at s=%.1f (frame %.0f us)" % [float(e9[0]), float(e9[1]), float(e9[2])])
	print("stage9: TOP-10 view-pitch STEPS outside events (|d(dpitch)| deg | s | frame us):")
	for e9b: Array in dp_list.slice(0, 10):
		print("   step %.3f deg at s=%.1f (frame %.0f us)" % [float(e9b[0]), float(e9b[1]), float(e9b[2])])
	print("stage9: TOP-10 GEOMETRY height steps outside events (|d(d frame_y)| m | s | frame us):")
	for e9c: Array in gv_list.slice(0, 10):
		print("   step %.4f m at s=%.1f (frame %.0f us)" % [float(e9c[0]), float(e9c[1]), float(e9c[2])])
	print("stage9: TOP-10 GEOMETRY pitch steps outside events (|d(d frame pitch)| deg | s | frame us):")
	for e9d: Array in gp_list.slice(0, 10):
		print("   step %.3f deg at s=%.1f (frame %.0f us)" % [float(e9d[0]), float(e9d[1]), float(e9d[2])])
	var gv_out: Array = []
	var gp_out: Array = []
	for e9g: Array in gv_list:
		if float(e9g[1]) < main.stairs_s0 - 2.0 or float(e9g[1]) > main.stairs_s1 + 2.0:
			gv_out.append(e9g)
	for e9h: Array in gp_list:
		if float(e9h[1]) < main.stairs_s0 - 2.0 or float(e9h[1]) > main.stairs_s1 + 2.0:
			gp_out.append(e9h)
	print("stage9: TOP-5 GEOMETRY height steps EXCLUDING the staircase band:")
	for e9i: Array in gv_out.slice(0, 5):
		print("   step %.4f m at s=%.1f (frame %.0f us)" % [float(e9i[0]), float(e9i[1]), float(e9i[2])])
	print("stage9: TOP-5 GEOMETRY pitch steps EXCLUDING the staircase band:")
	for e9j: Array in gp_out.slice(0, 5):
		print("   step %.3f deg at s=%.1f (frame %.0f us)" % [float(e9j[0]), float(e9j[1]), float(e9j[2])])
	var max_dv9: float = float(dv_list[0][0]) if dv_list.size() > 0 else 0.0
	var max_dp9: float = float(dp_list[0][0]) if dp_list.size() > 0 else 0.0
	print("stage9: full-view worst outside events: height %.4f m, pitch %.3f deg (event tails on the integrators - see report)" % [max_dv9, max_dp9])
	# Two-tier GEOMETRY bounds, stated from the achieved AFTER
	# measurements with margin (see the Fix Pass 8 report).
	# Outside the staircase the worst height steps sit at the
	# lip joins and the sweeper-exit bank unwind acting through
	# the car's lateral offset - the designed features' own
	# curvature at speed, 0.0127 m / 0.277 deg achieved. The
	# staircase's six drops are designed hammerings - 22 deg
	# edges the suspension bottoms on (stage 8 asserts the
	# bottoming) - and their geometry steps are that curvature
	# at full size: 0.0289 m / 1.185 deg achieved. What the fix
	# removed is the BEFORE table's spread: steps of the same
	# size at the corner exit, both lips, the sweeper exit and
	# the descent joins - plain road, no feature - are gone;
	# outside the staircase band nothing exceeds the tier bound
	# anywhere on the lap.
	var max_gv9: float = 0.0
	var max_gp9: float = 0.0
	var max_sv9: float = 0.0
	var max_sp9: float = 0.0
	for e9e: Array in gv_list:
		if float(e9e[1]) >= main.stairs_s0 - 2.0 and float(e9e[1]) <= main.stairs_s1 + 2.0:
			max_sv9 = maxf(max_sv9, float(e9e[0]))
		else:
			max_gv9 = maxf(max_gv9, float(e9e[0]))
	for e9f: Array in gp_list:
		if float(e9f[1]) >= main.stairs_s0 - 2.0 and float(e9f[1]) <= main.stairs_s1 + 2.0:
			max_sp9 = maxf(max_sp9, float(e9f[0]))
		else:
			max_gp9 = maxf(max_gp9, float(e9f[0]))
	check(max_gv9 < 0.014,
		"stage9: worst GEOMETRY height step outside the staircase is %.4f m (bound 0.014)" % max_gv9)
	check(max_gp9 < 0.35,
		"stage9: worst GEOMETRY pitch step outside the staircase is %.3f deg (bound 0.35)" % max_gp9)
	check(max_sv9 < 0.032,
		"stage9: worst GEOMETRY height step AT the staircase is %.4f m (bound 0.032)" % max_sv9)
	check(max_sp9 < 1.30,
		"stage9: worst GEOMETRY pitch step AT the staircase is %.3f deg (bound 1.30)" % max_sp9)

	# Stage 10 (Fix Pass 8, Item 2): real air on the little
	# hills, and the negative control the gate rework must not
	# break. 10a: the big climb's TOP BEND at speed - the case
	# Fix Pass 5's peak-compression gate existed for. The load
	# there is partial (~0.3-0.45) and sustained, so the new
	# load rule must keep the car planted BY MECHANISM: assert
	# no AIR through the bend AND that the load bottomed in the
	# partial band, never at ~zero. 10b: the crest straight at
	# the stated cruise (24 m/s) over the reshaped humps -
	# airborne episodes from GEOMETRY (load clamps to ~zero at
	# both axles), steering with no authority while airborne
	# (Fix Pass 9: the HEADING is frozen across each flight -
	# the free-heading form of the old lateral freeze),
	# landings that grade through the production path without
	# damage.
	main.jitter_on = true # back to the shipped default for stage 10
	main.debug_warp_to_s(100.0)
	main.test_throttle = 0.0
	var min_load10a: float = 1.0
	var air10a: bool = false
	var t10a: int = 0
	while main.car_s < 195.0 and t10a < 1200:
		autopilot()
		main.debug_pin_speed(30.0) # pinned, measure_shelf style
		await physics_frame
		t10a += 1
		if main.car_s > 125.0:
			min_load10a = minf(min_load10a, minf(main.load_f, main.load_r))
			if main.mode == main.MODE_AIR:
				air10a = true
		if main.mode == main.MODE_HANG:
			break
	check(not air10a and main.mode == main.MODE_DRIVE,
		"stage10a: NEGATIVE CONTROL - no airborne at the climb-top bend at 30 m/s (mode=%d)" % main.mode)
	check(min_load10a > 0.10 and min_load10a < 0.75,
		"stage10a: climb-top load stays partial by mechanism (min %.2f, never ~zero)" % min_load10a)
	# 10b: the humps at cruise.
	main.debug_warp_to_s(main.ext_s0 + 2.0)
	var episodes10: Array = []
	var in_air10: bool = false
	var ep_frames10: int = 0
	var ep_head0: float = 0.0
	var grades10: Array = []
	var dent10: int = main.dent_level
	var min_load10b: float = 1.0
	var air_frames10: int = 0
	var t10b: int = 0
	while main.car_s < main.sweeper_s0 - 5.0 and t10b < 1800:
		if main.mode == main.MODE_DRIVE:
			autopilot_steer()
			main.debug_pin_speed(24.0) # the stated cruise the humps were shaped for
		await physics_frame
		t10b += 1
		min_load10b = minf(min_load10b, minf(main.load_f, main.load_r))
		if main.mode == main.MODE_AIR and not main.air_from_gap:
			if not in_air10:
				in_air10 = true
				ep_frames10 = 0
				ep_head0 = main.car_heading
				# Hard-over wheel poke for the whole flight:
				# _update_air integrates no steering channel -
				# the heading must come out of the flight
				# untouched.
				main.wheel_angle = PI * 0.9
			ep_frames10 += 1
			air_frames10 += 1
		elif in_air10:
			in_air10 = false
			episodes10.append([ep_frames10, ep_head0, main.car_heading])
			grades10.append(String(main.last_touchdown).split(" ")[0])
		if main.mode == main.MODE_HANG:
			break
	if in_air10:
		episodes10.append([ep_frames10, ep_head0, main.car_heading])
		grades10.append(String(main.last_touchdown).split(" ")[0])
	var head_ok10: bool = episodes10.size() > 0
	for ep10: Array in episodes10:
		if absf(wrapf(float(ep10[2]) - float(ep10[1]), -PI, PI)) > deg_to_rad(1.0):
			head_ok10 = false
	var grades_ok10: bool = grades10.size() == episodes10.size()
	for g10: String in grades10:
		if g10 == "HARD" or g10 == "-" or g10 == "":
			grades_ok10 = false
	check(episodes10.size() >= 3,
		"stage10b: the humps throw the car airborne repeatedly at 24 m/s (%d flights)" % episodes10.size())
	check(float(air_frames10) / 90.0 >= 0.8,
		"stage10b: total hump air time %.2f s at cruise (floor 0.8 s)" % (float(air_frames10) / 90.0))
	check(min_load10b <= 0.031,
		"stage10b: crest load reaches ~zero at both axles (min %.3f) - air from geometry" % min_load10b)
	check(head_ok10,
		"stage10b: no steering authority while airborne (heading frozen across all %d flights)" % episodes10.size())
	check(grades_ok10 and main.dent_level == dent10,
		"stage10b: hump landings grade normally, no damage (grades %s, dent %d)" % [str(grades10), main.dent_level])
	main.wheel_angle = 0.0

	# Stage 11 (Fix Pass 8, Item 0; Fix Pass 9, Item 1): THE
	# LEVERS. FP8 hunted a state regression and did not reproduce
	# one headless; run 9 produced the decisive evidence - the
	# panel said HOLD (grip arrived, hand in range) and the
	# levers still did not move, because the flip fired on the
	# grip EDGE inside the zone and a human hand squeezes FIRST
	# and reaches SECOND, spending the edge in empty air. FP9
	# makes activation LEVEL-based inside the zone (fires once
	# per continuous grab-and-zone entry, re-arms on release or
	# zone exit). This stage now proves BOTH human orders
	# through the production grip path, plus the FP8 three-
	# dangle regression coverage unchanged:
	#   11a: grip-first-then-reach, then a HELD-GRIP SWEEP
	#        across the remaining switches (each fires on zone
	#        entry, exactly once), prep completes, credit lands.
	#   11b: recovery dangle - wrong-order reset, a held-grip
	#        probe (parked in the zone: exactly one flip), then
	#        the original pose-then-grip sequence.
	#   11c: post-FINISH Drop Start, pose-then-grip throughout.
	main.test_throttle = 0.0
	main.test_boost = false
	# --- dangle A: fresh Drop Start (the production restart
	# entry every restart path lands in) ---
	main.start_race()
	await frames(4)
	check(main.mode == main.MODE_HANG and main.hang_phase == "dangle",
		"stage11a: fresh Drop Start dangle (mode=%d phase=%s)" % [main.mode, main.hang_phase])
	var boost_a: float = main.boost_meter
	# (a) GRIP FIRST, THEN REACH - the run-9 failure order.
	var hold_idx: int = int(main.prep_order[0])
	var hold_ctl: int = main.dash_ctl_kinds.find("switch%d" % hold_idx)
	var hold_seg: Array[Vector3] = main._dash_ctl_segment(hold_ctl)
	var hold_mid: Vector3 = (hold_seg[0] + hold_seg[1]) * 0.5
	main.test_hand_pos["R"] = hold_mid + Vector3(0.0, 0.55, 0.0)
	main.test_hand_set = true
	check(main._dash_ctl_near(main.test_hand_pos["R"]) == -1,
		"stage11a: the reach starts outside every control zone")
	main.test_grip["R"] = 1.0
	for ih: int in 2:
		main._poll_grab("R", main.hand_ctrl["R"], 1.0 / 90.0)
	check(main.prep_index == 0,
		"stage11a: gripping in empty air fires nothing (index %d)" % main.prep_index)
	main.test_hand_pos["R"] = hold_mid # hand arrives, grip STILL held
	for ih2: int in 2:
		main._poll_grab("R", main.hand_ctrl["R"], 1.0 / 90.0)
	check(main.prep_index == 1 and main.switch_on[hold_idx],
		"stage11a: grip-first-then-reach flips the switch on zone entry (index %d)" % main.prep_index)
	# (b) HELD-GRIP SWEEP: without ever releasing, the hand
	# moves to the next switch's segment, then the last - each
	# fires exactly once on entry and the sequence completes.
	for ia: int in range(1, main.prep_order.size()):
		var sw_idx: int = int(main.prep_order[ia])
		var sw_ctl: int = main.dash_ctl_kinds.find("switch%d" % sw_idx)
		var sw_seg: Array[Vector3] = main._dash_ctl_segment(sw_ctl)
		main.test_hand_pos["R"] = (sw_seg[0] + sw_seg[1]) * 0.5
		for ih3: int in 2:
			main._poll_grab("R", main.hand_ctrl["R"], 1.0 / 90.0)
	check(main.prep_done, "stage11a: held-grip sweep completes the prep sequence")
	check(main.boost_meter > boost_a, "stage11a: prep credit lands (%.0f -> %.0f)" % [boost_a, main.boost_meter])
	# Parked in the last zone, still gripping: no re-fire (a
	# re-fire now would TOGGLE the switch back off - _flip_switch's
	# post-completion branch - so a true latch is observable).
	for ih4: int in 4:
		main._poll_grab("R", main.hand_ctrl["R"], 1.0 / 90.0)
	check(main.switch_on[int(main.prep_order[2])] and main.prep_index == 3,
		"stage11a: a parked held grip does not re-fire (index %d)" % main.prep_index)
	main.test_grip["R"] = 0.0
	main._poll_grab("R", main.hand_ctrl["R"], 1.0 / 90.0)
	# --- forced fall -> drone recovery dangle ---
	main._do_release()
	var drv_a: bool = await wait_until(func() -> bool: return main.mode == main.MODE_DRIVE, 700)
	check(drv_a, "stage11b: release lands into DRIVE")
	# The fall must be driven, not teleported: an earlier draft
	# shoved car_lat past the edge in one write, and the car
	# landed back on the ribbon - the ballistic phase starts
	# from the car's PLACED position (still on the road that
	# frame), so a state-variable teleport falls back onto the
	# tarmac, while a real edge crossing starts at the edge
	# with outward velocity and cannot land. Pin the wheel hard
	# over and let the drive code carry the car off. Fix Pass 9:
	# the drive now runs until the DRONE catches the car (a
	# mere AIR sighting no longer ends the stage - under the
	# free-heading model a hard-over turn crosses the shoulder
	# progressively, and the straddle state must not be
	# mistaken for the fall). AND the speed must be built FIRST,
	# centred: at full lock the car's turning circle is ~9.6 m
	# across - nearly inscribed in the 9.36 m road - so a
	# hard-over pin from low speed donuts on the ribbon
	# forever (measured: 4500 frames, no fall). At 18+ m/s the
	# yaw-rate cap stretches the radius past 11 m and the car
	# sweeps across the fall line in about a second.
	main.test_throttle = 0.9
	var tsp: int = 0
	while main.speed < 17.0 and tsp < 600 and main.mode == main.MODE_DRIVE:
		autopilot()
		await physics_frame
		tsp += 1
	main.test_throttle = 0.6
	var tf: int = 0
	var dang_b: bool = false
	while tf < 3000:
		main.wheel_angle = PI
		await physics_frame
		tf += 1
		if main.mode == main.MODE_HANG and main.hang_phase == "dangle":
			dang_b = true
			break
		if main.mode == main.MODE_DONE:
			break
	main.wheel_angle = 0.0
	main.test_throttle = 0.0
	check(dang_b, "stage11b: steering hard over drives the car off the edge into a drone-recovery dangle (mode=%d phase=%s, %d frames)" % [main.mode, main.hang_phase, tf])
	check(not main.is_drop_start, "stage11b: this dangle is a recovery, not a Drop Start")
	# wrong switch first: the production reset, through the grip path
	var wrong_idx: int = int(main.prep_order[1])
	grip_flip_switch(wrong_idx)
	check(main.prep_index == 0 and not main.switch_on[wrong_idx],
		"stage11b: wrong-order grip flip resets the sequence (index %d)" % main.prep_index)
	# held-grip probe on the sequence's first switch: a grip
	# parked in the zone across many polls flips EXACTLY once
	# (a second fire would be the wrong switch now and reset
	# the sequence to 0 - so index == 1 proves the latch).
	var hold_idx_b: int = int(main.prep_order[0])
	var hold_ctl_b: int = main.dash_ctl_kinds.find("switch%d" % hold_idx_b)
	var hold_seg_b: Array[Vector3] = main._dash_ctl_segment(hold_ctl_b)
	main.test_hand_pos["R"] = (hold_seg_b[0] + hold_seg_b[1]) * 0.5
	main.test_hand_set = true
	main.test_grip["R"] = 1.0
	for ihb: int in 6:
		main._poll_grab("R", main.hand_ctrl["R"], 1.0 / 90.0)
	check(main.prep_index == 1 and main.switch_on[hold_idx_b],
		"stage11b: a HELD grip parked in the zone flips exactly once (index %d)" % main.prep_index)
	main.test_grip["R"] = 0.0
	main._poll_grab("R", main.hand_ctrl["R"], 1.0 / 90.0)
	for ib: int in range(1, main.prep_order.size()):
		grip_flip_switch(int(main.prep_order[ib]))
	check(main.prep_done, "stage11b: recovery-dangle prep completes through the grip path")
	# --- FINISH, restart, fresh Drop Start dangle ---
	main._do_release()
	var drv_b: bool = await wait_until(func() -> bool: return main.mode == main.MODE_DRIVE, 700)
	check(drv_b, "stage11c: recovery release lands into DRIVE")
	main.debug_warp_to_s(main.track_len - 25.0)
	main.test_throttle = 0.9
	var fin_c: bool = false
	var tc: int = 0
	while tc < 1500:
		autopilot()
		await physics_frame
		tc += 1
		if main.mode == main.MODE_DONE:
			fin_c = true
			break
		if main.mode == main.MODE_HANG:
			break
	main.test_throttle = 0.0
	check(fin_c, "stage11c: lap finishes (mode=%d)" % main.mode)
	main.start_race()
	await frames(4)
	check(main.mode == main.MODE_HANG and main.hang_phase == "dangle" and main.is_drop_start,
		"stage11c: restart re-enters a Drop Start dangle")
	for ic: int in main.prep_order.size():
		grip_flip_switch(int(main.prep_order[ic]))
	check(main.prep_done, "stage11c: post-FINISH Drop Start prep completes through the grip path")
	main.test_hand_set = false
	main.test_grip["R"] = 0.0
	main.test_grip["L"] = 0.0

	# Stage 12 (Fix Pass 9, Item 2): THE FREE-HEADING MODEL.
	# (a) On a dead straight, a held wheel angle turns the
	# car's own HEADING away from the frame's heading while
	# the car stays on the ribbon - the sensation Chris found
	# missing in run 9 ("it more slides... riding a rail")
	# cannot exist in the old model and must exist in this
	# one. (b) A hard flick at speed breaks the tires loose
	# with REAL lateral velocity (slip_state is derived from
	# it); centring the wheel lets grip recover it, and
	# counter-steering recovers it faster.
	main.debug_warp_to_s(20.0)
	main.debug_pin_speed(14.0)
	main.test_throttle = 0.35
	var div12_max: float = 0.0
	var lat12_max: float = 0.0
	for i12: int in 36:
		main.wheel_angle = 0.45 * PI
		await physics_frame
		var fr12: Dictionary = main._frame_at(main.car_s)
		div12_max = maxf(div12_max, rad_to_deg(absf(wrapf(
			main.car_heading - main._frame_yaw(fr12["tan"]), -PI, PI))))
		lat12_max = maxf(lat12_max, absf(main.car_lat))
	main.wheel_angle = 0.0
	main.test_throttle = 0.0
	check(div12_max > 12.0,
		"stage12a: a held wheel turns the HEADING off the frame on a straight (max divergence %.1f deg, floor 12)" % div12_max)
	check(lat12_max < main.HALF_WIDTH and main.mode == main.MODE_DRIVE,
		"stage12a: the car stays on the ribbon while its heading is its own (max |lat| %.2f m)" % lat12_max)
	# (b) slip and recovery on the home straight. The flick is
	# 36 frames (0.4 s): the yaw inertia (YAW_TAU 0.16 s) eats a
	# shorter flick - a 20-frame flick measured only 0.22 peak
	# slip because the heading had barely begun to rotate when
	# it ended. 0.4 s of hard lock rotates the heading ~23 deg
	# while the velocity lags ~13 deg behind it: real slip.
	main.debug_warp_to_s(main.track_len - 190.0)
	main.debug_pin_speed(20.0)
	main.test_throttle = 0.3
	var peak12: float = 0.0
	for i12b: int in 36:
		main.wheel_angle = 0.9 * PI
		await physics_frame
		peak12 = maxf(peak12, main.slip_state)
	check(peak12 > 0.5,
		"stage12b: a hard flick at 20 m/s breaks the tires loose (peak slip %.2f, floor 0.5)" % peak12)
	main.wheel_angle = 0.0 # recovery A: centre and let grip work
	var rec_a12: int = 0
	while main.slip_state >= 0.08 and rec_a12 < 400 and main.mode == main.MODE_DRIVE:
		await physics_frame
		rec_a12 += 1
	main.debug_warp_to_s(main.track_len - 190.0)
	main.debug_pin_speed(20.0)
	var peak12b: float = 0.0
	for i12c: int in 36:
		main.wheel_angle = 0.9 * PI
		await physics_frame
		peak12b = maxf(peak12b, main.slip_state)
	main.wheel_angle = -0.55 * PI # recovery B: counter-steer
	var rec_b12: int = 0
	while main.slip_state >= 0.08 and rec_b12 < 400 and main.mode == main.MODE_DRIVE:
		await physics_frame
		rec_b12 += 1
	main.wheel_angle = 0.0
	main.test_throttle = 0.0
	check(rec_b12 < rec_a12,
		"stage12b: counter-steer shortens the slip recovery (%d frames vs %d centred)" % [rec_b12, rec_a12])
	check(main.mode == main.MODE_DRIVE,
		"stage12b: still driving after the flick and both recoveries (mode=%d)" % main.mode)

	# Stage 13 (Fix Pass 9, Item 2 scope addition): THE
	# EDGE-STRADDLE SAVE, Crammond's invisible sloping
	# shoulder. At moderate overshoot the car stays SUPPORTED
	# (no fall), rolls measurably toward the off side (the
	# wobble), and steering back restores full support (the
	# save). Past the cutoff the car goes over and the normal
	# fall/drone path engages. Both edges, mirrored.
	for sgn13: float in [1.0, -1.0]:
		var side_name: String = "right" if sgn13 > 0.0 else "left"
		main.debug_warp_to_s(main.track_len - 190.0)
		main.test_throttle = 0.25 # gentle: the whole manoeuvre must fit the home straight
		# Settle on the centreline first - a LONG settle: the
		# warp does not reset the springs, and the previous
		# side's release landing can still be ringing (its
		# rebound hop fired mid-hold on the left run and tripped
		# the mode watch - a landing transient, not a straddle
		# failure). 150 frames is several ring periods past it.
		for ic13: int in 150:
			autopilot_steer(0.0)
			await physics_frame
		var roll_sum13: float = 0.0
		var roll_n13: int = 0
		var drove13: bool = true
		for ih13: int in 320:
			autopilot_steer(sgn13 * (main.HALF_WIDTH + 0.35))
			await physics_frame
			if main.mode != main.MODE_DRIVE:
				drove13 = false
			if ih13 >= 240:
				roll_sum13 += main.car.global_transform.basis.y.dot(main._heading_right())
				roll_n13 += 1
		var roll13: float = roll_sum13 / maxf(float(roll_n13), 1.0)
		check(drove13,
			"stage13: %s straddle at moderate overshoot stays supported - no fall" % side_name)
		check(roll13 * sgn13 > 0.08,
			"stage13: %s straddle rolls toward the off side (up-along-right %.3f, ~%.0f deg)" % [side_name, roll13, rad_to_deg(asin(clampf(roll13, -1.0, 1.0)))])
		check(absf(main.car_lat - sgn13 * (main.HALF_WIDTH + 0.35)) < 0.55,
			"stage13: %s straddle holds its line on the shoulder (car_lat %.2f m)" % [side_name, main.car_lat])
		# Fix Pass 10 (Item 3): the save window grows 200 -> 340
		# frames - the road is 12 m wide now, so the trip back
		# from the shoulder is ~1.3 m longer at the lane law's
		# capped approach angle. Same mechanism, longer road.
		for is13: int in 340: # the save: steer back to centre
			autopilot_steer(0.0)
			await physics_frame
		check(main.mode == main.MODE_DRIVE and absf(main.car_lat) < 0.6,
			"stage13: %s save - steering back restores the centreline (car_lat %.2f m)" % [side_name, main.car_lat])
		var roll_save13: float = main.car.global_transform.basis.y.dot(main._heading_right())
		check(absf(roll_save13) < 0.035,
			"stage13: %s save - the wobble is gone once support is back (roll %.3f)" % [side_name, roll_save13])
		# Fix Pass 10 (Item 3): the fall leg gets a FRESH run at
		# the home straight. At 12 m wide the straddle + save
		# legs above now travel far enough that the fall leg ran
		# out of straight and crossed the finish line instead of
		# going over - each leg is a property of the overshoot,
		# not of one unbroken journey, so it re-stages cleanly.
		main.debug_warp_to_s(main.track_len - 190.0)
		main.test_throttle = 0.25
		for ir13: int in 90:
			autopilot_steer(0.0)
			await physics_frame
		var fell13: bool = false
		for io13: int in 400: # FP10: wider road - the fall line is 1.3 m further out
			autopilot_steer(sgn13 * (main.HALF_WIDTH + 2.55))
			await physics_frame
			if main.mode == main.MODE_AIR:
				fell13 = true
				break
			if main.mode != main.MODE_DRIVE:
				break
		check(fell13, "stage13: %s - past the cutoff the car goes over (mode=%d)" % [side_name, main.mode])
		main.test_throttle = 0.0
		var dang13: bool = await wait_until(
			func() -> bool: return main.mode == main.MODE_HANG and main.hang_phase == "dangle", 2500)
		check(dang13, "stage13: %s - the drone recovery engages after the fall" % side_name)
		main.pend_th_f = 0.0
		main.pend_th_l = 0.0
		main.pend_om_f = 0.0
		main.pend_om_l = 0.0
		await frames(4)
		main._do_release()
		var drv13: bool = await wait_until(func() -> bool: return main.mode == main.MODE_DRIVE, 700)
		check(drv13, "stage13: %s - release resumes driving for the mirror run" % side_name)

	# Stage 15 (Fix Pass 10, Item 0): the levers against a DEAD
	# CHANNEL, and one-hand reach. Run 10: the left grip channel
	# delivered nothing live, ever - so activation must provably
	# not depend on a specific hand. (a) A full prep completed
	# RIGHT-hand-only with the left grip held at 0.0 throughout
	# (the run-10 world), and LEFT-hand-only with the right
	# dead - both through the production grip path on fresh
	# dangles. (b) Reach, measured from the anchored seat: the
	# three prep switches must sit within cross-body reach of
	# BOTH shoulders (an arm plus the torso allowance a seated
	# player actually has) and within a one-hand sweep of both
	# wheel-rest positions, so the surviving hand can always
	# work the whole prep row. The two dash BUTTONS are also
	# measured: same-side reach is asserted, cross-body is
	# printed for the record (each also has a controller twin -
	# lean = R B button, restart = L Y button - and they sit
	# at the dash's far corners by design).
	var ok15a: bool = await prep_one_hand("R")
	check(ok15a, "stage15: full prep with a DEAD LEFT channel (right hand works all three switches)")
	var ok15b: bool = await prep_one_hand("L")
	check(ok15b, "stage15: full prep with a DEAD RIGHT channel (left hand works all three switches)")
	main.test_hand_set = false
	main.test_grip["L"] = 0.0
	main.test_grip["R"] = 0.0
	var inv15: Transform3D = main.car.global_transform.affine_inverse()
	var sh15: Dictionary = {"L": Vector3(-0.21, 1.02, 0.12), "R": Vector3(0.21, 1.02, 0.12)}
	var rest15: Dictionary = {"L": Vector3(-0.23, 0.88, -0.40), "R": Vector3(0.23, 0.88, -0.40)}
	var worst_sw_sh: float = 0.0
	var worst_sw_rest: float = 0.0
	for ci15: int in 3:
		var seg15: Array = main._dash_ctl_segment(ci15)
		var b15: Vector3 = inv15 * (seg15[0] as Vector3)
		var t15: Vector3 = inv15 * (seg15[1] as Vector3)
		for h15: String in ["L", "R"]:
			worst_sw_sh = maxf(worst_sw_sh, main._seg_point_dist(b15, t15, sh15[h15] as Vector3))
			worst_sw_rest = maxf(worst_sw_rest, main._seg_point_dist(b15, t15, rest15[h15] as Vector3))
	check(worst_sw_sh <= 0.90,
		"stage15: every prep switch within cross-body reach of both shoulders (worst %.2f m, bound 0.90)" % worst_sw_sh)
	check(worst_sw_rest <= 0.60,
		"stage15: every prep switch within a one-hand sweep of both wheel-rest positions (worst %.2f m, bound 0.60)" % worst_sw_rest)
	for ci15b: int in range(3, main.dash_ctl_nodes.size()):
		var seg15b: Array = main._dash_ctl_segment(ci15b)
		var b15b: Vector3 = inv15 * (seg15b[0] as Vector3)
		var t15b: Vector3 = inv15 * (seg15b[1] as Vector3)
		var own15: float = main._seg_point_dist(b15b, t15b,
			sh15["R" if ci15b == 3 else "L"] as Vector3)
		var cross15: float = main._seg_point_dist(b15b, t15b,
			sh15["L" if ci15b == 3 else "R"] as Vector3)
		print("stage15: button %s reach - same-side shoulder %.2f m, cross-body %.2f m (record)"
			% [main.dash_ctl_kinds[ci15b], own15, cross15])
		check(own15 <= 0.85,
			"stage15: button %s within same-side shoulder reach (%.2f m)" % [main.dash_ctl_kinds[ci15b], own15])
	# DIAG zone line names the hand in the zone.
	main.test_hand_set = true
	var segz: Array = main._dash_ctl_segment(0)
	main.test_hand_pos["R"] = ((segz[0] as Vector3) + (segz[1] as Vector3)) * 0.5
	main.test_hand_pos["L"] = main.car.global_position + Vector3(5.0, 5.0, 5.0)
	check(main._build_diag_block().contains("FUEL:R"),
		"stage15: DIAG zone line names the hand in the zone (%s)" % main._diag_zone_line())
	main.test_hand_set = false

	# ---------- stage 16: Fix Pass 10 (Item 1) - drone placement ----------
	# The drop search walks BACK from where the car left the road
	# and must land on a flat straight piece with
	# DROP_MIN_RUNUP_M of hazard-free road ahead. Property-check
	# the brief's staged falls directly against _find_drop_s
	# (pure function of the built track), then fly one LIVE gap
	# fall through the production recovery path.
	main.start_race()
	await frames(4)
	var fall_cases: Array = [
		[main.gap_s1 + 2.0, "just past gap 1"],
		[main.gap2_s1 + 2.0, "just past gap 2"],
		[155.0, "mid-banked-corner"],
		[main.ext_s0 - 2.0, "one car length before hump 1"],
		[main.stairs_s0 + 15.0, "ON the staircase"],
	]
	for fc: Variant in fall_cases:
		var fall_s: float = float(fc[0])
		var drop_s: float = main._find_drop_s(fall_s)
		check(drop_s <= fall_s + 0.01,
			"stage16: drop never ahead of the fall (%s: fall %.0f -> drop %.0f)" % [String(fc[1]), fall_s, drop_s])
		check(main._drop_piece_ok(drop_s),
			"stage16: drop piece flat/straight/unbanked (%s, drop %.0f)" % [String(fc[1]), drop_s])
		check(main._drop_runup_ok(drop_s),
			"stage16: drop has %.0f m hazard-free run-up (%s, drop %.0f)" % [main.DROP_MIN_RUNUP_M, String(fc[1]), drop_s])
	check(main._drop_piece_ok(2.0) and main._drop_runup_ok(2.0),
		"stage16: the start-line piece itself qualifies as a drop (gantry rule)")
	# LIVE: too slow for the 14 m gap - coast in at 9 m/s, fall
	# in, and let the production recovery run. The drop must sit
	# at or behind where the car left the road AND clear of the
	# gap it just failed (run-up may not cross the lip).
	for idx: Variant in main.prep_order.duplicate():
		grip_flip_switch(int(idx), "R")
	main._do_release()
	var drv16: bool = await wait_until(func() -> bool: return main.mode == main.MODE_DRIVE, 700)
	check(drv16, "stage16: setup release lands into DRIVE")
	main.debug_warp_to_s(main.gap_s0 - 60.0)
	var f16: int = 0
	var entered_air: bool = false
	while f16 < 5000 and not entered_air:
		autopilot() # the approach crosses the banked corner - steer it
		main.debug_pin_speed(6.0) # per-frame pin: slow enough to fall IN
		await physics_frame
		f16 += 1
		# A hop off the lip crest 26 m earlier also enters AIR;
		# only the entry AT the gap counts (fall start at the lip
		# of the gap itself).
		if main.mode == main.MODE_AIR and main.air_start_s >= main.gap_s0 - 2.5:
			entered_air = true
	check(entered_air, "stage16: slow entry falls into gap 1 (live)")
	if entered_air:
		check(main.air_start_s >= main.gap_s0 - 2.5 and main.air_start_s <= main.gap_s1 + 1.0,
			"stage16: fall-start s recorded at the lip (%.1f, gap %.0f-%.0f)" % [main.air_start_s, main.gap_s0, main.gap_s1])
		f16 = 0
		var caught16: bool = false
		var landed16: bool = false
		while f16 < 6000 and not caught16 and not landed16:
			await physics_frame
			f16 += 1
			if main.mode == main.MODE_HANG:
				caught16 = true
			elif main.mode == main.MODE_DRIVE:
				landed16 = true # made the far side - fixture invalid, say so
		check(caught16 and not landed16,
			"stage16: drone catches the gap fall (live)")
		if caught16:
			check(main.drop_target_s <= main.air_start_s + 0.01,
				"stage16: live drop at/behind the fall start (drop %.0f <= fall %.0f)" % [main.drop_target_s, main.air_start_s])
			check(main.drop_target_s <= main.gap_s0 - 24.0,
				"stage16: live drop's run-up clears the failed gap (drop %.0f, lip %.0f)" % [main.drop_target_s, main.gap_s0])
			check(main._drop_piece_ok(main.drop_target_s) and main._drop_runup_ok(main.drop_target_s),
				"stage16: live drop piece + run-up valid (drop %.0f)" % main.drop_target_s)

	# ---------- stage 17: Fix Pass 10 (Item 2) - pivot-driven flight ----
	# (a) The pendulum integrates the PIVOT's acceleration: inject
	# a sustained 3 m/s^2 along the drop frame's tangent. The
	# swing must LAG first (small angle early) and settle at the
	# physical equilibrium -atan(a/g) = -0.297 rad.
	main.start_race()
	await frames(4)
	main.dip_timer = 1000.0 # keep flown dips out of the measurements
	main.pend_th_f = 0.0
	main.pend_th_l = 0.0
	main.pend_om_f = 0.0
	main.pend_om_l = 0.0
	await frames(3)
	var fr17: Dictionary = main._frame_at(main.drop_target_s)
	main.test_pivot_accel = (fr17["tan"] as Vector3) * 3.0
	main.test_pivot_accel_on = true
	await frames(21) # ~0.23 s at the project's 90 Hz tick
	var early17: float = main.pend_th_f
	check(absf(early17) < 0.10,
		"stage17: swing LAGS a step pivot acceleration (th_f %.3f rad at 0.23 s, bound 0.10)" % early17)
	# The pendulum is LIGHTLY damped by design (PEND_DAMP 0.10 -
	# the swing persists; that is the FP5 feel), so a step in
	# pivot acceleration rings around the new equilibrium for
	# many seconds: the equilibrium claim is a MEAN claim. Inject
	# for ~13 s and average the last ~4.7 s (one full period of
	# the 5.5 m axis) - the oscillation cancels, the mean is the
	# equilibrium.
	await frames(726)
	var sum17: float = 0.0
	var ring17: float = 0.0
	for i17m: int in 423:
		await physics_frame
		sum17 += main.pend_th_f
		ring17 = maxf(ring17, absf(main.pend_th_f))
	var mean17: float = sum17 / 423.0
	check(mean17 < -0.20 and mean17 > -0.38,
		"stage17: equilibrium tilt under sustained pivot accel (mean th_f %.3f, expect ~-0.297)" % mean17)
	check(ring17 > 0.40,
		"stage17: the step RINGS past equilibrium before settling (peak |th_f| %.3f in the mean window)" % ring17)
	main.test_pivot_accel_on = false
	# (b) The car's facing seeks a yaw TARGET on its spring:
	# step the target 90 deg - the facing must overshoot the
	# target, then settle on it. Then the production path: turn
	# the CARRIER and confirm the car realigns to it (no
	# permanent twist left behind).
	main.start_race()
	await frames(4)
	main.dip_timer = 1000.0
	main.pend_th_f = 0.0
	main.pend_th_l = 0.0
	main.pend_om_f = 0.0
	main.pend_om_l = 0.0
	await frames(30)
	var y17: float = main.orient_yaw
	main.test_yaw_target = wrapf(y17 + PI / 2.0, -PI, PI)
	main.test_yaw_target_on = true
	var over17: float = 0.0
	var settle17: bool = false
	for i17: int in 720:
		await physics_frame
		var err17: float = wrapf(main.orient_yaw - main.test_yaw_target, -PI, PI)
		over17 = maxf(over17, err17)
		if i17 > 200 and absf(err17) < deg_to_rad(1.0):
			settle17 = true
			break
	check(over17 > deg_to_rad(1.0),
		"stage17: car yaw OVERSHOOTS a target step (%.2f deg past, floor 1.0)" % rad_to_deg(over17))
	check(settle17,
		"stage17: car yaw settles on the target (err %.2f deg)" % rad_to_deg(wrapf(main.orient_yaw - main.test_yaw_target, -PI, PI)))
	main.test_yaw_target_on = false
	main.debug_carrier_turn(PI / 2.0)
	var realign17: bool = await wait_until(
		func() -> bool: return absf(wrapf(main.orient_yaw - main.carrier_yaw, -PI, PI)) < deg_to_rad(1.5), 900)
	check(realign17, "stage17: car realigns to the carrier after a carrier turn (no permanent twist)")
	# (c) Production carry: fall off the staircase, get carried
	# ~110 m back along the retrace path. The flight must EXCITE
	# the pendulum (accel/braking/turns), the hang must SETTLE
	# after arrival, and a flown dip at full depth must slack
	# the lines through MEASURED carrier acceleration.
	for idx: Variant in main.prep_order.duplicate():
		grip_flip_switch(int(idx), "R")
	main._do_release()
	var drv17: bool = await wait_until(func() -> bool: return main.mode == main.MODE_DRIVE, 700)
	check(drv17, "stage17: setup release lands into DRIVE")
	main.debug_warp_to_s(main.stairs_s0 + 15.0)
	main._call_drone()
	var path17: int = 0
	var peak17: float = 0.0
	var saw_carry17: bool = false
	var f17: int = 0
	while f17 < 5000:
		await physics_frame
		f17 += 1
		if main.hang_phase == "carry":
			saw_carry17 = true
			path17 = main.carrier_path.size()
		if saw_carry17:
			peak17 = maxf(peak17, maxf(absf(main.pend_th_f), absf(main.pend_th_l)))
		if saw_carry17 and main.hang_phase == "dangle":
			break
	main.dip_timer = 1000.0 # settle window stays dip-free; the dip test re-arms it
	check(saw_carry17 and path17 >= 2,
		"stage17: recovery flies a retrace path (%d waypoints)" % path17)
	check(peak17 > 0.10,
		"stage17: the carry excites the pendulum (peak %.3f rad, floor 0.10)" % peak17)
	# settle: with the carrier AT STATION the swing must DECAY at
	# the pendulum's own light damping - never be re-pumped.
	# Two 2 s windows ~7 s apart: the later peak must be well
	# under the earlier (e^{-0.05*7} = 0.70 is the physics).
	await frames(90)
	var win_a17: float = 0.0
	for i17b: int in 180:
		await physics_frame
		win_a17 = maxf(win_a17, maxf(absf(main.pend_th_f), absf(main.pend_th_l)))
	await frames(480)
	var win_b17: float = 0.0
	for i17c: int in 180:
		await physics_frame
		win_b17 = maxf(win_b17, maxf(absf(main.pend_th_f), absf(main.pend_th_l)))
	check(win_b17 < 0.80 * win_a17,
		"stage17: swing decays at station, not re-pumped (window peaks %.3f -> %.3f rad)" % [win_a17, win_b17])
	check(win_b17 < 0.75 * peak17,
		"stage17: hang settles after arrival (late %.3f vs carry peak %.3f)" % [win_b17, peak17])
	# flown dip at full depth -> measured accel -> slack
	main.dip_timer = 0.05 # next dip almost immediately
	var dip_seen17: bool = false
	var slack_seen17: bool = false
	var min_acc17: float = 0.0
	f17 = 0
	while f17 < 2400 and not slack_seen17:
		await physics_frame
		f17 += 1
		if main.dip_t >= 0.0:
			if not dip_seen17:
				dip_seen17 = true
				main.dip_depth = 1.40 # range maximum - the flight stays production
			min_acc17 = minf(min_acc17, main.carrier_accel.y)
		if main.slack_t > 0.0:
			slack_seen17 = true
	check(dip_seen17, "stage17: a flown dip occurs at the dangle")
	check(min_acc17 < -3.0,
		"stage17: the dip is real carrier acceleration (min %.1f m/s^2)" % min_acc17)
	check(slack_seen17,
		"stage17: full-depth dip slacks the lines via measured accel (min %.1f, threshold %.1f)" % [min_acc17, main.DIP_SLACK_ACCEL])
	# and the whole hang still hands off to a drive
	for idx: Variant in main.prep_order.duplicate():
		grip_flip_switch(int(idx), "R")
	main._do_release()
	var drv17b: bool = await wait_until(func() -> bool: return main.mode == main.MODE_DRIVE, 700)
	check(drv17b, "stage17: release after the carried, dipped hang resumes driving")

	print("---")
	print("UNVERIFIED (XR layer, by design): grab-wheel hand tracking; live XR grip channel VALUES and hand poses (switch-flip logic itself is verified on synthetic poses, stage 11); HMD lean reading; in-headset panel legibility")
	if guard_failures == 0:
		print("API GUARD: ALL %d CHECKS PASSED" % guard_checks)
	else:
		print("API GUARD: %d of %d CHECKS FAILED" % [guard_failures, guard_checks])
	if failures == 0:
		print("SMOKE: ALL %d CHECKS PASSED" % checks)
	else:
		print("SMOKE: %d of %d CHECKS FAILED" % [failures, checks])
	quit(1 if failures > 0 or guard_failures > 0 else 0)
