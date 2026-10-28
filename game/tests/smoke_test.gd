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
		["XRInterface", "trigger_haptic_pulse"], # Fix Pass 11 (Item 4): xr_iface.trigger_haptic_pulse - on the BASE class, not OpenXRInterface
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


func autopilot_fast() -> void:
	# Fix Pass 11 (Item 5): the raised-envelope driver - the
	# lap and gap stages (19/20) run at the new cap; every
	# other fixture keeps the FP10 pace it was calibrated at
	# (autopilot() above, and stage 9's geometry tiers in
	# particular stay on the old envelope).
	_autopilot_drive(0.0, true, main.TOP_SPEED)


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


func _autopilot_drive(lat_off: float, with_speed: bool, cap: float = 34.0) -> void:
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
		var v_allow: float = clampf(sqrt(11.0 / maxf(max_curv, 0.0001)), 9.0, cap)
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
	# Fix Pass 10 (Item 3): the circuit is the game's default
	# track, but stages 1-17 were authored against the test
	# ribbon. Select the ribbon explicitly so the legacy suite
	# runs unchanged; the circuit gets its own stages 18-20.
	main._set_track("ribbon")
	await frames(5)

	# Fix Pass 12 (Item 2): the info boards spawn HIDDEN (the
	# toggle round-trip itself is stage 27, at the end - the
	# spawn state has to be asserted here, before anything
	# could have toggled them).
	check(not main.panels_visible and not main.panel_root.visible and not main.diag_root.visible,
		"boot: both info boards start hidden (FP12 item 2)")

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
		# same side = the shoulder on the control's own side of
		# the car centreline (Fix Pass 10: the track button
		# joined the row; side comes from geometry, not index)
		var own_side15: String = "R" if (b15b + t15b).x >= 0.0 else "L"
		var own15: float = main._seg_point_dist(b15b, t15b,
			sh15[own_side15] as Vector3)
		var cross15: float = main._seg_point_dist(b15b, t15b,
			sh15["L" if own_side15 == "R" else "R"] as Vector3)
		print("stage15: button %s reach - same-side shoulder %.2f m, cross-body %.2f m (record)"
			% [main.dash_ctl_kinds[ci15b], own15, cross15])
		# Fix Pass 11 (Item 6): the bound was 0.85, stated from
		# the FP10 car (worst measured 0.82 - the track button).
		# The rake pitches the whole body -3.24 deg about the car
		# origin, swinging every dash control ~3.4 cm down and
		# forward in car space; the same button now measures
		# 0.86 m. The bound is re-stated at 0.90, the figure the
		# prep switches already carry cross-body above - the
		# reach is unchanged in kind, the car moved, not the arm.
		check(own15 <= 0.90,
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

	# ---------- stage 18: Fix Pass 10 (Item 3) - the mountain circuit ----
	main._set_track("circuit")
	await frames(5)
	var cf18: Dictionary = main.track_data["circuit"]["features"]
	check(main.track_closed and main.active_track == "circuit",
		"stage18: circuit active and closed")
	check(float(cf18["closure_err_m"]) < 0.05,
		"stage18: closure exact (err %.4f m)" % float(cf18["closure_err_m"]))
	check(main.track_len >= 2800.0 and main.track_len <= 3400.0,
		"stage18: length in the brief band (%.0f m)" % main.track_len)
	# the seam join itself: the wrap segment is a normal segment
	var n18: int = main.t_pts.size()
	var seam_len18: float = main.t_pts[0].distance_to(main.t_pts[n18 - 1])
	check(absf(seam_len18 - 1.0) < 0.05,
		"stage18: seam segment ~1 m (%.4f)" % seam_len18)
	# features: signature climb >= +60 m, massive dip >= 45 m
	var cl_y0: float = main._frame_at(float(cf18["climb_s0"]))["pos"].y
	var cl_y1: float = main._frame_at(float(cf18["climb_s1"]))["pos"].y
	var climb_gain18: float = cl_y1 - cl_y0
	check(climb_gain18 >= 60.0,
		"stage18: signature climb gains >= 60 m (%.1f)" % climb_gain18)
	var dip_ymax18: float = -1e9
	var dip_ymin18: float = 1e9
	var dip_s18: float = 0.0
	while dip_s18 < float(cf18["climb_s0"]):
		var dip_y18: float = main._frame_at(maxf(dip_s18, 2.0))["pos"].y
		if dip_s18 < float(cf18["dip_s0"]):
			dip_ymax18 = maxf(dip_ymax18, dip_y18)
		if dip_s18 >= float(cf18["dip_s0"]) and dip_s18 <= float(cf18["dip_s1"]):
			dip_ymin18 = minf(dip_ymin18, dip_y18)
		dip_s18 += 5.0
	var dip_depth18: float = dip_ymax18 - dip_ymin18
	check(dip_depth18 >= 45.0,
		"stage18: massive dip gives back >= 45 m (%.1f)" % dip_depth18)
	check(float(cf18["home_len"]) >= 350.0 and float(cf18["mid_len"]) >= 350.0,
		"stage18: two straightaways >= 350 m (home %.0f, mid %.0f)" % [float(cf18["home_len"]), float(cf18["mid_len"])])
	# at least two long banked swinging curves, one each way,
	# generous radius
	var long_l18: int = 0
	var long_r18: int = 0
	for cv18: Variant in cf18["curves"]:
		var cva18: Array = cv18
		if float(cva18[1]) - float(cva18[0]) >= 150.0 and float(cva18[3]) >= 100.0:
			if float(cva18[2]) > 0.0:
				long_l18 += 1
			else:
				long_r18 += 1
	check(long_l18 >= 1 and long_r18 >= 1,
		"stage18: long banked curves both ways (L %d, R %d)" % [long_l18, long_r18])
	check(absf((main.gap_s1 - main.gap_s0) - 14.0) < 0.5,
		"stage18: the one gap spans 14 m (%.1f)" % (main.gap_s1 - main.gap_s0))
	# five-hump row carried over: five crest kv peaks in the span
	var crests18: int = 0
	var prev_kv18: float = 0.0
	var hc_s18: float = main.ext_s0 + 2.0
	while hc_s18 < float(cf18["hump_s1"]) - 2.0:
		var hc_kv18: float = main._frame_at(hc_s18)["kv"]
		if prev_kv18 < 0.010 and hc_kv18 >= 0.010:
			crests18 += 1
		prev_kv18 = hc_kv18
		hc_s18 += 1.0
	check(crests18 == 5,
		"stage18: five-hump row present (counted %d)" % crests18)
	# drone placement wraps the seam: a fall just past the
	# gantry walks back across it; a fall just before the gap
	# lands at least 25 m ahead-clear of it
	# the seam neighbourhood is benign BY DESIGN (the closing
	# hairpin unwinds to flat/unbanked at the join), so a fall
	# just past the gantry legitimately drops close behind
	# itself; the wrap machinery is asserted by the invariant
	# (drop never ahead of the fall, measured across the seam)
	# plus a fall staged inside the banked closing hairpin,
	# whose walk-back travels toward and past the seam zone
	var d18a: float = main._find_drop_s(12.0)
	check(d18a <= 12.0 and main._drop_piece_ok(d18a) and main._drop_runup_ok(d18a),
		"stage18: fall at s=12 drops at/behind itself, qualified (%.0f)" % d18a)
	var fall18h: float = main.track_len - 40.0
	var d18h: float = main._find_drop_s(fall18h)
	var back18h: float = fmod(fall18h - d18h + main.track_len, main.track_len)
	check(back18h > 1.0 and main._drop_piece_ok(d18h) and main._drop_runup_ok(d18h),
		"stage18: hairpin fall walks back %.0f m to a qualified piece (drop %.0f)" % [back18h, d18h])
	var d18b: float = main._find_drop_s(main.gap_s0 - 3.0)
	check(d18b <= main.gap_s0 - 25.0 and main._drop_runup_ok(d18b),
		"stage18: pre-gap fall drops clear of the gap (%.0f into gap %.0f)" % [d18b, main.gap_s0])

	# ---------- stage 19: three laps to DONE, seam steps invisible ----
	main.jitter_on = false
	main.start_race()
	await frames(3)
	main.step_rows.clear()
	main._step_last_us = 0
	main.step_log_on = true
	main._do_release()
	var lap_frames19: int = 0
	var done19: bool = false
	while lap_frames19 < 90000 and not done19:
		await physics_frame
		lap_frames19 += 1
		autopilot_fast() # Fix Pass 11 (Item 5): laps run the raised envelope
		if main.mode == main.MODE_AIR:
			await wait_until(func() -> bool: return main.mode != main.MODE_AIR, 4000)
		elif main.mode == main.MODE_HANG:
			for idx: Variant in main.prep_order.duplicate():
				grip_flip_switch(int(idx), "R")
			main._do_release()
		elif main.mode == main.MODE_DONE:
			done19 = true
	main.step_log_on = false
	check(done19 and main.lap_count == main.RACE_LAPS,
		"stage19: autopilot completes 3 laps to DONE (%d frames, laps %d)" % [lap_frames19, main.lap_count])
	# seam steps by stage 9's method exactly: GEOMETRY channel
	# second differences (frame_y col 8, frame pitch col 5) on
	# DRIVE rows outside event tails, restricted to the seam
	# band, against stage 9's outside-staircase tier bounds
	var rows19: Array = main.step_rows
	var last_bad19: int = -100000
	var gv_max19: float = 0.0
	var gp_max19: float = 0.0
	for i19: int in rows19.size():
		var rr19: Array = rows19[i19]
		if int(rr19[1]) != main.MODE_DRIVE:
			last_bad19 = i19
			continue
		if i19 < 2 or i19 - last_bad19 <= 12:
			continue
		var pv19: Array = rows19[i19 - 1]
		var pv219: Array = rows19[i19 - 2]
		if int(pv19[1]) != main.MODE_DRIVE or int(pv219[1]) != main.MODE_DRIVE:
			continue
		var s19: float = float(rr19[0])
		if s19 > 90.0 and s19 < main.track_len - 90.0:
			continue
		var gv19: float = absf((float(rr19[8]) - float(pv19[8])) - (float(pv19[8]) - float(pv219[8])))
		var gp19: float = rad_to_deg(absf((float(rr19[5]) - float(pv19[5])) - (float(pv19[5]) - float(pv219[5]))))
		gv_max19 = maxf(gv_max19, gv19)
		gp_max19 = maxf(gp_max19, gp19)
	check(gv_max19 < 0.014,
		"stage19: worst seam GEOMETRY height step %.4f m (stage-9 tier 0.014)" % gv_max19)
	check(gp_max19 < 0.35,
		"stage19: worst seam GEOMETRY pitch step %.3f deg (stage-9 tier 0.35)" % gp_max19)

	# ---------- stage 20: circuit hump air + gap crossing ----
	# hump air: the stage-10b protocol at the circuit hump span
	main._set_track("circuit")
	await frames(3)
	main.debug_warp_to_s(main.ext_s0 + 2.0)
	var flights20: int = 0
	var in_air20: bool = false
	var f20: int = 0
	while main.car_s < main.ext_s0 + 245.0 and f20 < 1800:
		if main.mode == main.MODE_DRIVE:
			autopilot_steer()
			main.debug_pin_speed(24.0)
		await physics_frame
		f20 += 1
		if main.mode == main.MODE_AIR and not main.air_from_gap:
			if not in_air20:
				in_air20 = true
				flights20 += 1
		else:
			in_air20 = false
		if main.mode == main.MODE_HANG:
			break
	check(flights20 >= 3,
		"stage20: circuit humps fly the car (>= 3 flights, saw %d)" % flights20)
	# gap crossing under autopilot with the boost window
	main._set_track("circuit")
	await frames(3)
	main.start_race()
	await frames(3)
	main._do_release()
	var gap_ok20: bool = false
	var f20b: int = 0
	while f20b < 30000 and not gap_ok20:
		await physics_frame
		f20b += 1
		autopilot_fast() # Fix Pass 11 (Item 5): the gap run at the raised envelope
		main.test_boost = main.car_s > main.gap_s0 - 130.0 and main.car_s < main.gap_s0
		if main.car_s > main.gap_s1 + 30.0:
			gap_ok20 = main.mode == main.MODE_DRIVE
		if main.mode == main.MODE_AIR:
			await wait_until(func() -> bool: return main.mode != main.MODE_AIR, 4000)
		elif main.mode == main.MODE_HANG:
			for idx: Variant in main.prep_order.duplicate():
				grip_flip_switch(int(idx), "R")
			main._do_release()
		elif main.mode == main.MODE_DONE:
			break
	main.test_boost = false
	check(gap_ok20,
		"stage20: circuit gap crossed under autopilot and the lap continues")

	# ---------- stage 21: Fix Pass 10 (Item 4) - the loop spur ----
	# Fast run: pinned at 30 m/s the car takes the fork, loops
	# the ring (frame orientation continuous, ~360 deg of total
	# pitch), merges at the join and the lap continues.
	var spur21: Dictionary = main.track_data["circuit"]["spur"]
	var ring0_21: float = float(spur21["ring_s0"])
	var ring1_21: float = float(spur21["ring_s1"])
	main._set_track("circuit")
	await frames(3)
	main.start_race()
	await frames(3)
	main._do_release()
	await wait_until(func() -> bool: return main.mode == main.MODE_DRIVE, 300)
	var captured21: bool = false
	var merged21: bool = false
	var max_rot21: float = 0.0
	var ring_rot21: float = 0.0
	var prev_q21 := Quaternion.IDENTITY
	var have_q21: bool = false
	var drv_frames21: int = 0
	var f21: int = 0
	while f21 < 4500 and not merged21:
		await physics_frame
		f21 += 1
		if main.mode == main.MODE_AIR:
			await wait_until(func() -> bool: return main.mode != main.MODE_AIR, 4000)
		elif main.mode == main.MODE_DRIVE:
			drv_frames21 += 1
			if drv_frames21 > 45:
				main.debug_pin_speed(30.0)
			if main.on_spur:
				captured21 = true
				var frq21: Dictionary = main._spur_frame_at(main.spur_s + clampf(main.speed * 0.55, 6.0, 22.0))
				var tp21: Vector3 = frq21["pos"]
				var cp21: Vector3 = main.car.global_position
				var des21: float = atan2(-(tp21.x - cp21.x), -(tp21.z - cp21.z))
				if absf(Vector3(frq21["tan"]).y) > 0.45:
					des21 = main._spur_frame_yaw(main._spur_frame_at(main.spur_s))
				main.wheel_angle = clampf(-wrapf(des21 - main.car_heading, -PI, PI) * 1.6, -1.0, 1.0) * PI
			else:
				var tgt21: float = 0.0
				if main.car_s > main.SPUR_ENTRY_S:
					var uu21: float = clampf((main.car_s - 120.0) / 85.0, 0.0, 1.0)
					tgt21 = -3.4 * (uu21 * uu21 * (3.0 - 2.0 * uu21))
				autopilot_steer(tgt21)
			if have_q21:
				var q21: Quaternion = main.car.global_transform.basis.get_rotation_quaternion()
				var drot21: float = rad_to_deg(prev_q21.angle_to(q21))
				if main.on_spur:
					max_rot21 = maxf(max_rot21, drot21)
					if main.spur_s > ring0_21 and main.spur_s < ring1_21:
						ring_rot21 += drot21
				prev_q21 = q21
			else:
				prev_q21 = main.car.global_transform.basis.get_rotation_quaternion()
				have_q21 = true
			if captured21 and not main.on_spur and main.car_s > main.SPUR_JOIN_S - 20.0:
				merged21 = true
		elif main.mode == main.MODE_HANG:
			break
	check(captured21, "stage21: the fork captures a car steered onto its line")
	check(merged21, "stage21: fast run loops the ring and merges back (car_s %.0f)" % main.car_s)
	check(max_rot21 < 3.5,
		"stage21: orientation continuous on the spur (worst frame step %.2f deg)" % max_rot21)
	check(ring_rot21 > 320.0 and ring_rot21 < 400.0,
		"stage21: the ring turns the car through ~360 deg (%.0f)" % ring_rot21)
	# Slow run: pinned 16 to the ring, then 10 m/s - below the
	# top's sqrt(gR) ~= 10.4 - the load goes negative past
	# vertical and the car detaches INSIDE the ring, falls,
	# and the drone recovers it onto the MAIN track.
	main._set_track("circuit")
	await frames(3)
	main.start_race()
	await frames(3)
	main._do_release()
	await wait_until(func() -> bool: return main.mode == main.MODE_DRIVE, 300)
	var air_in_ring21: bool = false
	var was_spur21: bool = false
	var last_spur_s21: float = 0.0
	var drv_frames21b: int = 0
	var f21b: int = 0
	while f21b < 4500:
		await physics_frame
		f21b += 1
		if main.mode == main.MODE_DRIVE:
			drv_frames21b += 1
			was_spur21 = main.on_spur
			if main.on_spur:
				last_spur_s21 = main.spur_s
			if drv_frames21b > 45:
				if main.on_spur and main.spur_s > ring0_21:
					main.debug_pin_speed(10.0)
				else:
					main.debug_pin_speed(16.0)
			if main.on_spur:
				var frq21b: Dictionary = main._spur_frame_at(main.spur_s + clampf(main.speed * 0.55, 6.0, 22.0))
				var tp21b: Vector3 = frq21b["pos"]
				var cp21b: Vector3 = main.car.global_position
				var des21b: float = atan2(-(tp21b.x - cp21b.x), -(tp21b.z - cp21b.z))
				# Fix Pass 11: the yaw-law switch keys on the
				# LOOKAHEAD frame's pitch, and near the ring top
				# the lookahead tangent passes through level -
				# the law chatters between pursuit bearing and
				# frame yaw, the car's psi diverges, spur_s
				# stalls just short of the both-axle detach
				# window (traced: stall at 122.9, window opens
				# at 123.0) and the car wallows at the top until
				# the frame budget dies. Inside the ring span
				# the frame yaw is the stable target throughout
				# (the ring is planar); use it from 10 m out.
				if absf(Vector3(frq21b["tan"]).y) > 0.45 or main.spur_s > ring0_21 - 10.0:
					des21b = main._spur_frame_yaw(main._spur_frame_at(main.spur_s))
				main.wheel_angle = clampf(-wrapf(des21b - main.car_heading, -PI, PI) * 1.6, -1.0, 1.0) * PI
			else:
				var tgt21b: float = 0.0
				if main.car_s > main.SPUR_ENTRY_S:
					var uu21b: float = clampf((main.car_s - 120.0) / 85.0, 0.0, 1.0)
					tgt21b = -3.4 * (uu21b * uu21b * (3.0 - 2.0 * uu21b))
				autopilot_steer(tgt21b)
		elif main.mode == main.MODE_AIR:
			# the detach counts only if the car left DRIVE from
			# ON the spur, inside the ring span - a release
			# rebound in the first frames must not fake it.
			# Fix Pass 11: the break used to sit OUTSIDE the if,
			# so ANY air - including that rebound, or a landing
			# hop on the way to the fork - ended the run in a
			# spurious failure (seen post-rake: exits at spur_s
			# 0 and 115 with the detach itself verified at 123
			# in clean runs). Mirror the fast run above: wait
			# unrelated air out, break only on the ring detach.
			if was_spur21 and last_spur_s21 >= ring0_21 and last_spur_s21 <= ring1_21 + 5.0:
				air_in_ring21 = true
				break
			await wait_until(func() -> bool: return main.mode != main.MODE_AIR, 4000)
		elif main.mode == main.MODE_HANG:
			break
	check(air_in_ring21 and main.mode == main.MODE_AIR,
		"stage21: slow ring entry detaches inside the ring (spur_s %.0f of %.0f-%.0f)" % [last_spur_s21, ring0_21, ring1_21])
	var hang21: bool = await wait_until(func() -> bool: return main.mode == main.MODE_HANG, 6000)
	check(hang21, "stage21: the fall ends in a drone recovery")
	if hang21:
		check(main._drop_piece_ok(main.drop_target_s) and main._drop_runup_ok(main.drop_target_s),
			"stage21: recovery drop is a qualified MAIN-track piece (s %.0f)" % main.drop_target_s)

	# ---------- stage 22: Fix Pass 11 (Item 1) - seat + yaw cone ----
	# (a) The trim funnel: the eye follows the trim, the live seat
	# moves by the delta, the clamp holds, and the value persists
	# through the settings file (the game's first persisted
	# setting - see the seat_trim note in main.gd).
	main._apply_seat_trim(0.0)
	check(absf(main._eye_anchor().y - main.EYE_ANCHOR.y) < 0.001,
		"stage22: zero trim puts the eye on EYE_ANCHOR")
	var seat_y0: float = main.seat_offset.transform.origin.y
	main._apply_seat_trim(0.10)
	check(absf(main.seat_trim - 0.10) < 0.001
		and absf(main.seat_offset.transform.origin.y - (seat_y0 + 0.10)) < 0.001,
		"stage22: trim moves the live seat by the delta (trim %+.2f)" % main.seat_trim)
	main._apply_seat_trim(1.0)
	check(absf(main.seat_trim - main.SEAT_TRIM_MAX) < 0.001,
		"stage22: trim clamps at +%.2f" % main.SEAT_TRIM_MAX)
	main._apply_seat_trim(-1.0)
	check(absf(main.seat_trim + main.SEAT_TRIM_MAX) < 0.001,
		"stage22: trim clamps at -%.2f" % main.SEAT_TRIM_MAX)
	main._apply_seat_trim(0.07)
	main.seat_trim = 0.0 # bypass the funnel: prove the FILE restores it
	main._load_settings()
	check(absf(main.seat_trim - 0.07) < 0.001,
		"stage22: trim persists through the settings file (%.2f)" % main.seat_trim)
	# (b) Hold-to-trim through the production grab path: pose the
	# right hand on each seat lever's segment, grip, and poll -
	# SEAT+ runs the trim up at SEAT_TRIM_RATE, SEAT- back down.
	var sup_idx: int = main.dash_ctl_kinds.find("seatup")
	var sdn_idx: int = main.dash_ctl_kinds.find("seatdn")
	check(sup_idx > 5 and sdn_idx > 5,
		"stage22: seat levers registered after the FP10 controls (idx %d/%d)" % [sup_idx, sdn_idx])
	main._apply_seat_trim(0.0)
	main.test_hand_set = true
	var seg_sup: Array = main._dash_ctl_segment(sup_idx)
	main.test_hand_pos["R"] = ((seg_sup[0] as Vector3) + (seg_sup[1] as Vector3)) * 0.5
	main.test_hand_pos["L"] = main.car.global_position + Vector3(5.0, 5.0, 5.0)
	main.test_grip["R"] = 1.0
	main._poll_grab("R", main.hand_ctrl["R"], 0.5)
	check(main.seat_trim > 0.10,
		"stage22: holding SEAT+ trims up through _poll_grab (%.2f after 0.5 s)" % main.seat_trim)
	var seg_sdn: Array = main._dash_ctl_segment(sdn_idx)
	main.test_hand_pos["R"] = ((seg_sdn[0] as Vector3) + (seg_sdn[1] as Vector3)) * 0.5
	main._poll_grab("R", main.hand_ctrl["R"], 0.5)
	check(main.seat_trim < 0.05,
		"stage22: holding SEAT- trims back down (%.2f)" % main.seat_trim)
	main.test_grip["R"] = 0.0
	main.test_hand_set = false
	main._apply_seat_trim(0.0)
	# (c) The yaw cone through the production anchor math: the
	# deviation helper on known forwards, then a posed head -
	# 40 deg off, an AUTOMATIC apply must land translation only
	# and owe the yaw; the explicit bake (what the cone watch and
	# every recenter call) settles it. The stability-gate chain
	# that decides WHEN these run is live-rig only (XRServer has
	# no tracked head here) and stays on the unverified list.
	check(absf(main._yaw_dev_of(Vector3(0, 0, -1))) < 0.001
		and absf(main._yaw_dev_of(Vector3(1, 0, 0)) - PI / 2.0) < 0.001
		and absf(main._yaw_dev_of(Vector3(-1, 0, 0)) + PI / 2.0) < 0.001,
		"stage22: yaw deviation helper reads 0 / +90 / -90 deg")
	main.seat_offset.transform = Transform3D.IDENTITY
	main.origin.rotation = Vector3(0.0, deg_to_rad(40.0), 0.0)
	await frames(2)
	var yawed22: bool = main._apply_seat_anchor(false)
	check(not yawed22 and main.anchor_yaw_pending,
		"stage22: automatic apply at 40 deg off lands translation only (yaw owed)")
	var cam_car22: Transform3D = main._cam_in_car()
	check((cam_car22.origin - main._eye_anchor()).length() < 0.01,
		"stage22: translation landed the eye on the anchor (err %.3f m)" % (cam_car22.origin - main._eye_anchor()).length())
	main.origin.rotation = Vector3.ZERO
	await frames(2)
	var baked22: bool = main._apply_seat_anchor(true)
	check(baked22 and not main.anchor_yaw_pending,
		"stage22: explicit bake applies the yaw and clears the debt")
	main.seat_offset.transform = Transform3D.IDENTITY
	check(main._build_diag_block().contains("SEAT +0.00"),
		"stage22: DIAG shows the seat trim")

	# ---------- stage 23: Fix Pass 11 (Item 2) - zone geometry -----
	# The PERMANENT audit (it stays in the suite): every control
	# _poll_grab can fire has its activation segment ON its
	# visible handle and no segment sample buried in other
	# bodywork. The render proof asserts the same audit in its
	# pose and draws the zones as markers over the controls.
	var audit23: Dictionary = main.debug_dash_ctl_audit()
	var viol23: Array = audit23["violations"]
	check(viol23.is_empty(),
		"stage23: zone audit clean (%d violations%s)" % [viol23.size(),
			"" if viol23.is_empty() else ": " + str(viol23.slice(0, 2))])
	check(float(audit23["worst"]) <= main.DASH_AUDIT_TOL,
		"stage23: worst segment-to-handle deviation %.3f m (tol %.3f)" % [float(audit23["worst"]), main.DASH_AUDIT_TOL])

	# ---------- stage 24: Fix Pass 11 (Item 3) - drone approach ----
	# Production recovery with a LONG opposed walk-back: warp to
	# circuit s 900, whose drop piece sits 158 m behind on the
	# same road - mid-carry the carrier flies back along the
	# track facing its velocity, ~180 deg from the drop heading
	# (asserted, so the stage cannot silently stop exercising
	# the owner's case). It must still ARRIVE aligned: yaw
	# error at the dangle transition within the gate's few
	# degrees (the old behaviour arrived ~180 deg out and spun
	# at the station), the alignment already flown 30 frames
	# before arrival, and the car's own facing settled on the
	# drop heading within ~2 s of arrival (releasable).
	main.start_race()
	await frames(4)
	main.dip_timer = 1000.0 # keep flown dips out of the measurements
	for idx: Variant in main.prep_order.duplicate():
		grip_flip_switch(int(idx), "R")
	main._do_release()
	var drv24: bool = await wait_until(func() -> bool: return main.mode == main.MODE_DRIVE, 700)
	check(drv24, "stage24: setup release lands into DRIVE")
	main.debug_warp_to_s(900.0)
	main._call_drone()
	var drop_yaw24: float = 0.0
	var yaw_err_dangle24: float = -1.0
	var yaw_err_max24: float = 0.0
	var err_hist24: Array[float] = []
	var saw_carry24: bool = false
	var f24: int = 0
	while f24 < 6000:
		await physics_frame
		f24 += 1
		if main.hang_phase == "carry":
			saw_carry24 = true
		if saw_carry24:
			drop_yaw24 = main._frame_yaw(main._frame_at(main.drop_target_s)["tan"])
			var e24: float = absf(wrapf(main.carrier_yaw - drop_yaw24, -PI, PI))
			yaw_err_max24 = maxf(yaw_err_max24, e24)
			err_hist24.append(e24)
			if err_hist24.size() > 30:
				err_hist24.pop_front()
		if saw_carry24 and main.hang_phase == "dangle":
			yaw_err_dangle24 = absf(wrapf(main.carrier_yaw - drop_yaw24, -PI, PI))
			break
	main.dip_timer = 1000.0
	check(saw_carry24 and yaw_err_dangle24 >= 0.0,
		"stage24: the recovery carries and arrives (dangle reached)")
	check(yaw_err_max24 > deg_to_rad(90.0),
		"stage24: the carry really is opposed mid-flight (max yaw err %.0f deg)" % rad_to_deg(yaw_err_max24))
	check(yaw_err_dangle24 >= 0.0 and yaw_err_dangle24 < deg_to_rad(5.0),
		"stage24: carrier arrives aligned (yaw err %.1f deg at the dangle)" % rad_to_deg(maxf(yaw_err_dangle24, 0.0)))
	check(err_hist24.size() >= 10 and err_hist24[0] < deg_to_rad(20.0),
		"stage24: the turn was flown, not spun at the station (err %.1f deg, 30 frames out)" % rad_to_deg(err_hist24[0] if err_hist24.size() > 0 else 999.0))
	var t24: int = 0
	var aligned24: bool = false
	while t24 < 180:
		await physics_frame
		t24 += 1
		if absf(wrapf(main.orient_yaw - drop_yaw24, -PI, PI)) < deg_to_rad(5.0):
			aligned24 = true
			break
	check(aligned24,
		"stage24: car facing settles on the drop heading within 2 s of arrival (%.1f s)" % (float(t24) / 90.0))
	for idx: Variant in main.prep_order.duplicate():
		grip_flip_switch(int(idx), "R")
	main._do_release()
	var drv24b: bool = await wait_until(func() -> bool: return main.mode == main.MODE_DRIVE, 700)
	check(drv24b, "stage24: release after the aligned arrival resumes driving")

	# ---------- stage 25: Fix Pass 11 (Item 4) - the drop lever ----
	# Production path only: posed test hands through _poll_grab.
	# (a) grab + pull past the detent = the car lets go;
	# (b) grab + partial pull + release the grip = the lever
	# springs home and nothing drops; (c) the panel names the
	# lever as THE release (the XR trigger release is retired).
	main.start_race()
	await frames(4)
	main.dip_timer = 1000.0
	check(main.mode == main.MODE_HANG and main.hang_phase == "dangle",
		"stage25: dangling for the lever test")
	# Fix Pass 12 (Item 1): the shifter's placement, measured:
	# pivot forward beside the wheel on the right pod, and the
	# grab segment spans the SHORT shaft (0.19 m of segment on
	# a 0.33 m shaft, vs FP11's 0.22 on 0.50 - the segment was
	# re-based to the same upper-shaft-plus-knob span).
	check(main.drop_lever_pivot.position == Vector3(0.72, 0.71, -0.60),
		"stage25: shifter pivot forward beside the wheel (0.72, 0.71, -0.60)")
	var seg25: Array = main.debug_drop_lever_segment()
	check(seg25.size() == 2 and absf((seg25[0] as Vector3).distance_to(seg25[1]) - 0.19) < 0.01,
		"stage25: grab segment spans the shortened shaft (%.2f m)" % (
			(seg25[0] as Vector3).distance_to(seg25[1]) if seg25.size() == 2 else -1.0))
	check(main._panel_text().contains("DROP SHIFTER"),
		"stage25: the panel names the DROP SHIFTER as the release")
	# Fix Pass 12 (Item 1): the hand poses on the SHIFTER's
	# shaft - 0.27 m out the pivot (the 0.33 m shaft's working
	# reach; FP11's 0.50 m shaft used 0.45).
	var lever_at = func(th: float) -> Vector3:
		return main.car_body.global_transform * (main.drop_lever_pivot.position \
			+ Basis(Vector3.RIGHT, th) * Vector3(0, 0.27, 0))
	main.test_hand_set = true
	main.test_hand_pos["L"] = main.car.global_position + Vector3(5.0, 5.0, 5.0)
	main.test_hand_pos["R"] = lever_at.call(main.drop_lever_angle)
	main.test_grip["R"] = 1.0
	main._poll_grab("R", main.hand_ctrl["R"], 0.016)
	check(main.drop_lever_hand == "R", "stage25: grip near the shaft latches the lever")
	main.test_hand_pos["R"] = lever_at.call(0.30)
	main._poll_grab("R", main.hand_ctrl["R"], 0.016)
	check(absf(main.drop_lever_angle - 0.30) < 0.06 and main.mode == main.MODE_HANG,
		"stage25: lever follows the hand below the detent (%.2f rad), no drop" % main.drop_lever_angle)
	main.test_hand_pos["R"] = lever_at.call(0.55)
	main._poll_grab("R", main.hand_ctrl["R"], 0.016)
	check(main.mode == main.MODE_AIR,
		"stage25: past the detent (%.2f rad) the car lets go" % main.drop_lever_angle)
	main.test_grip["R"] = 0.0
	main._poll_grab("R", main.hand_ctrl["R"], 0.016)
	main.test_hand_set = false
	var drv25: bool = await wait_until(func() -> bool: return main.mode == main.MODE_DRIVE, 700)
	check(drv25, "stage25: the lever's drop lands into DRIVE")
	# (b) partial pull, early release
	main.start_race()
	await frames(4)
	main.dip_timer = 1000.0
	main.test_hand_set = true
	main.test_hand_pos["L"] = main.car.global_position + Vector3(5.0, 5.0, 5.0)
	main.test_hand_pos["R"] = lever_at.call(main.drop_lever_angle)
	main.test_grip["R"] = 1.0
	main._poll_grab("R", main.hand_ctrl["R"], 0.016)
	main.test_hand_pos["R"] = lever_at.call(0.15)
	main._poll_grab("R", main.hand_ctrl["R"], 0.016)
	var pulled25: float = main.drop_lever_angle
	main.test_grip["R"] = 0.0
	main._poll_grab("R", main.hand_ctrl["R"], 0.016)
	main.test_hand_set = false
	check(absf(pulled25 - 0.15) < 0.06 and main.drop_lever_hand == "" and main.mode == main.MODE_HANG,
		"stage25: partial pull (%.2f rad) held, grip released, car still hangs" % pulled25)
	await frames(40)
	check(absf(main.drop_lever_angle - main.DROP_LEVER_REST_RAD) < 0.03 and main.mode == main.MODE_HANG,
		"stage25: lever springs home (%.2f rad), no drop" % main.drop_lever_angle)

	# ---------- stage 26: Fix Pass 11 (Item 5) - the speed envelope --
	# (a) the lock scale: EXACTLY the FP10 expression at and
	# below 24 m/s (the owner's squirrely band, numerically
	# untouched), the blended envelope above it.
	var lock_ok26: bool = true
	for v26: float in [0.0, 6.0, 12.0, 18.0, 24.0]:
		var old26: float = 1.0 / (1.0 + (v26 / 26.0) * (v26 / 26.0))
		if main._lock_scale(v26) != old26:
			lock_ok26 = false
	check(lock_ok26, "stage26: lock scale is bit-identical to FP10 at 0/6/12/18/24 m/s")
	var spots26: Array = [[30.0, 0.507], [34.0, 0.523], [38.0, 0.518], [48.0, 0.410]]
	var spots_ok26: bool = true
	for sp26: Array in spots26:
		if absf(main._lock_scale(float(sp26[0])) - float(sp26[1])) > 0.002:
			spots_ok26 = false
		var old_sp26: float = 1.0 / (1.0 + (float(sp26[0]) / 26.0) * (float(sp26[0]) / 26.0))
		if main._lock_scale(float(sp26[0])) <= old_sp26:
			spots_ok26 = false
	check(spots_ok26, "stage26: blended lock above 24 (30: %.3f, 34: %.3f, 38: %.3f, 48: %.3f - all above the old curve)" % [
		main._lock_scale(30.0), main._lock_scale(34.0), main._lock_scale(38.0), main._lock_scale(48.0)])
	# (b) standing start on the circuit's opening straight
	# (381 m of low curvature from s 0): brake to zero, floor
	# it, pursuit-steer. vmax must be the new clamp and the
	# 0->45 time is the engine's honest run (10 / 0.10 terms).
	main._set_track("circuit")
	await frames(3)
	main.start_race()
	await frames(3)
	main._do_release()
	var rel26: bool = await wait_until(func() -> bool: return main.mode == main.MODE_DRIVE, 700)
	check(rel26, "stage26: release lands into DRIVE for the speed run")
	main.debug_warp_to_s(2.0)
	await frames(3)
	main.test_brake = 1.0
	var bz26: int = 0
	while main.speed > 0.01 and bz26 < 900:
		await physics_frame
		bz26 += 1
	main.test_brake = 0.0
	main.test_throttle = 1.0
	var f26: int = 0
	var t45_26: float = -1.0
	var vmax26: float = 0.0
	while f26 < 2700:
		await physics_frame
		f26 += 1
		var fr_t26: Dictionary = main._frame_at(main.car_s + clampf(main.speed * 0.55, 6.0, 22.0))
		var tgt26: Vector3 = fr_t26["pos"]
		var pos26: Vector3 = main.car.global_position
		var des26: float = atan2(-(tgt26.x - pos26.x), -(tgt26.z - pos26.z))
		var err26: float = wrapf(des26 - main.car_heading, -PI, PI)
		main.wheel_angle = clampf(-err26 * 1.6, -1.0, 1.0) * PI
		vmax26 = maxf(vmax26, main.speed)
		if t45_26 < 0.0 and main.speed >= 45.0:
			t45_26 = float(f26) / 90.0
		if main.mode != main.MODE_DRIVE:
			break
	main.test_throttle = 0.0
	check(vmax26 >= 47.9, "stage26: top speed is the new clamp (vmax %.1f m/s = %.0f km/h)" % [vmax26, vmax26 * 3.6])
	check(t45_26 > 4.5 and t45_26 < 8.0, "stage26: 0->45 m/s in %.1f s (standing start, opening straight)" % t45_26)
	# (c) the circuit hump span at pin 48 (stage 20's protocol
	# at 24): the car must keep landing - flights counted, no
	# drone call, the span completed. Longest flight reported;
	# no hump re-tune is forced by this evidence (see README).
	main._set_track("circuit")
	await frames(3)
	main.debug_warp_to_s(main.ext_s0 + 2.0)
	var flights26: int = 0
	var in_air26: bool = false
	var air_run26: int = 0
	var air_max26: int = 0
	var f26c: int = 0
	var hang26: bool = false
	while main.car_s < main.ext_s0 + 245.0 and f26c < 1800:
		if main.mode == main.MODE_DRIVE:
			autopilot_steer()
			main.debug_pin_speed(48.0)
		await physics_frame
		f26c += 1
		if main.mode == main.MODE_AIR and not main.air_from_gap:
			air_run26 += 1
			if not in_air26:
				in_air26 = true
				flights26 += 1
		else:
			air_max26 = maxi(air_max26, air_run26)
			air_run26 = 0
			in_air26 = false
		if main.mode == main.MODE_HANG:
			hang26 = true
			break
	air_max26 = maxi(air_max26, air_run26)
	check(flights26 >= 3 and not hang26 and main.car_s >= main.ext_s0 + 245.0,
		"stage26: hump span at pin 48 - %d flights, longest %.1f s, landed throughout (end s %.0f)" % [
			flights26, float(air_max26) / 90.0, main.car_s])
	# (d) engine pitch follows the rescaled normaliser: pinned
	# at 34 vs 48, throttle closed, the settled pitch must sit
	# at the rescaled stations (2.11 / 2.65).
	main._set_track("ribbon")
	await frames(3)
	main.start_race()
	await frames(3)
	main._do_release()
	var rel26d: bool = await wait_until(func() -> bool: return main.mode == main.MODE_DRIVE, 700)
	check(rel26d, "stage26: release lands into DRIVE for the pitch check")
	main.test_throttle = 0.0
	# the pin is a per-frame fixture (a single call decays
	# under drag within a second) - hold each speed while the
	# revs settle, staying ahead of the crest at s ~154.
	for pf26: int in 90:
		main.debug_pin_speed(34.0)
		await physics_frame
	var pitch34_26: float = main.engine_player.pitch_scale
	for pf26b: int in 60:
		main.debug_pin_speed(48.0)
		await physics_frame
	var pitch48_26: float = main.engine_player.pitch_scale
	check(absf(pitch34_26 - 2.11) < 0.12 and absf(pitch48_26 - 2.65) < 0.12 and pitch48_26 > pitch34_26 + 0.4,
		"stage26: engine pitch rescaled (34 m/s: %.2f, 48 m/s: %.2f)" % [pitch34_26, pitch48_26])

	# ---------- stage 27: Fix Pass 12 (Item 2) - panel toggle ----
	# The boards spawn hidden (asserted at boot). One switch -
	# production _toggle_panels(), driven here through the real
	# desktop input path (a Tab key event into _input) and back
	# - flips BOTH boards together, and the prep/DIAG content
	# keeps refreshing while hidden (visibility is display
	# state, not a data gate).
	var tab_ev := InputEventKey.new()
	tab_ev.keycode = KEY_TAB
	tab_ev.pressed = true
	main._input(tab_ev)
	check(main.panels_visible and main.panel_root.visible and main.diag_root.visible,
		"stage27: Tab calls both boards up")
	main._input(tab_ev)
	check(not main.panels_visible and not main.panel_root.visible and not main.diag_root.visible,
		"stage27: Tab makes both boards go away")
	main.diag_block = "FP12 STAGE27 MARKER"
	main._update_panel()
	check(main.diag_label.text == "FP12 STAGE27 MARKER" and main.panel_label.text.contains("Panels: R B button"),
		"stage27: DIAG/panel content refreshes while hidden; panel lists the toggle")
	main._toggle_panels()
	check(main.panels_visible and main.panel_root.visible and main.diag_root.visible,
		"stage27: production toggle shows both boards (the R B path calls this)")

	# ---------- stage 28: Fix Pass 12 (Item 3) - drone clearance --
	# Production recoveries, asserted ANALYTICALLY on every frame
	# of the carry: the carried car (plan disc r=1.7 m at its
	# centre, floor at its true global AABB min) must never
	# intersect a ribbon box (surface-0.45..surface over
	# +-HALF_WIDTH) or a stilt box (0.55 wide, surface down to
	# the desert floor) of any sample near the route - main
	# track and spur alike. Cases: (A) the stage-24 walk-back
	# (fall s 900, drop 158 m behind) re-timed - FP11 needed
	# 1911 frames end to end; (H) a drone call past the hump
	# span, whose walk-back crosses all five humps; (G) a
	# genuine gap fall - the catch is inside the gap, below
	# road level, and the climb-out crosses the lip.
	var car_meshes28: Array[MeshInstance3D] = []
	main._collect_meshes(main.car_body, car_meshes28)
	var run_case28 = func(fall_s: float, label: String, frame_cap: int) -> Array:
		main._set_track("circuit") # stage 26 leaves the ribbon active
		main.start_race()
		await frames(4)
		main.dip_timer = 1000.0
		for idx: Variant in main.prep_order.duplicate():
			grip_flip_switch(int(idx), "R")
		main._do_release()
		var drv: bool = await wait_until(func() -> bool: return main.mode == main.MODE_DRIVE, 700)
		if not drv:
			return [false, 0, "setup release failed"]
		main.debug_warp_to_s(fall_s)
		await frames(3)
		main._call_drone()
		await frames(2)
		# Candidate samples: within 9 m in plan of the flown
		# corridor (path points lerped every ~5 m).
		var corridor: Array[Vector3] = [main.anchor_pos]
		var prev_cp: Vector3 = main.anchor_pos
		for pi: int in main.carrier_path.size():
			var nxt_cp: Vector3 = main.carrier_path[pi]
			var seg_len: float = prev_cp.distance_to(nxt_cp)
			var seg_n: int = maxi(1, int(seg_len / 5.0))
			for si2: int in range(1, seg_n + 1):
				corridor.append(prev_cp.lerp(nxt_cp, float(si2) / float(seg_n)))
			prev_cp = nxt_cp
		var cands: Array = []
		var n_main: int = main.t_pts.size()
		for i: int in n_main:
			if bool(main.t_gap[i]):
				continue
			var p: Vector3 = main.t_pts[i]
			var near: bool = false
			for cp: Vector3 in corridor:
				if Vector2(p.x - cp.x, p.z - cp.z).length() < 9.0:
					near = true
					break
			if near:
				var frc: Dictionary = main._frame_at(float(i))
				cands.append([p, Vector3(frc["side"]), Vector3(frc["tan"]), i % 10 == 0, 0.275])
		var spur28: Dictionary = main.track_data["circuit"].get("spur", {})
		if not spur28.is_empty():
			var spts: Array = spur28["pts"]
			var sside: Array = spur28["side"]
			var stan: Array = spur28["tan"]
			for i2: int in spts.size():
				var p2: Vector3 = spts[i2]
				var near2: bool = false
				for cp2: Vector3 in corridor:
					if Vector2(p2.x - cp2.x, p2.z - cp2.z).length() < 9.0:
						near2 = true
						break
				if near2:
					cands.append([p2, Vector3(sside[i2]), Vector3(stan[i2]), i2 % 12 == 0, 0.30])
		var hits: int = 0
		var brush: int = 0
		var min_clear: float = 1e9
		var f: int = 0
		var saw_carry: bool = false
		while f < frame_cap:
			await physics_frame
			f += 1
			if main.mode != main.MODE_HANG:
				break
			if main.hang_phase == "carry":
				saw_carry = true
			if main.hang_phase == "dangle":
				break
			if not saw_carry:
				continue
			var bb := AABB()
			var first: bool = true
			for mi: MeshInstance3D in car_meshes28:
				var ga: AABB = mi.global_transform * mi.get_aabb()
				if first:
					bb = ga
					first = false
				else:
					bb = bb.merge(ga)
			var cpos: Vector3 = main.car.global_position
			# Station exemption, measured and bounded: in the
			# final settle the still-swinging car's low AABB
			# corner brushes the road plane at the drop point
			# itself (worst corner depth ~0.17 m across traces,
			# ~0.4 s) - the hang stack's 1.2 m clearance minus
			# the swing dip. That cell (10 m plan around the
			# station) is counted as brush, not asserted; the
			# ROUTE - the run-12 complaint, road and pylon
			# mid-carry - is asserted clean.
			var at_station: bool = Vector2(cpos.x - main.anchor_target.x, cpos.z - main.anchor_target.z).length() < 10.0
			for cd: Array in cands:
				var sp: Vector3 = cd[0]
				var rel: Vector3 = cpos - sp
				var lat_s: float = rel.dot(cd[1])
				var al_s: float = rel.dot(cd[2])
				var hit28: bool = false
				if absf(lat_s) < main.HALF_WIDTH + 1.7 and absf(al_s) < 0.5 + 1.7:
					min_clear = minf(min_clear, bb.position.y - sp.y)
					if bb.position.y < sp.y + 0.02 and bb.end.y > sp.y - main.RIBBON_DEPTH - 0.02:
						hit28 = true
				if bool(cd[3]) and Vector2(rel.x, rel.z).length() < float(cd[4]) + 1.7:
					if bb.position.y < sp.y + 0.02:
						hit28 = true
				if hit28:
					if at_station:
						brush += 1
					else:
						hits += 1
		return [hits == 0 and saw_carry, f, "hits %d, station brush %d, min car-floor clearance over near samples %.2f m, %s" % [hits, brush, min_clear, label]]
	var case_a28: Array = await run_case28.call(900.0, "A: s900 walk-back", 2400)
	check(bool(case_a28[0]), "stage28: case A carry is collision-free (%s)" % String(case_a28[2]))
	check(int(case_a28[1]) < 1700,
		"stage28: case A end-to-end %d frames (FP11: 1911 for the same recovery)" % int(case_a28[1]))
	# Case H's fall sits INSIDE the hump span's far end (2455):
	# from 2494 the drop search finds a flat piece just past
	# the humps and the route never crosses them (measured in
	# the first FP12 run - a 235-frame local hop). From inside
	# the span the drop lands well behind the fall, so the
	# carry crosses the humps in between.
	var case_h28: Array = await run_case28.call(2455.0, "H: hump-span walk-back", 3600)
	check(bool(case_h28[0]), "stage28: case H carry over the humps is collision-free (%s)" % String(case_h28[2]))
	print("stage28: case H end-to-end %d frames (%s)" % [int(case_h28[1]), String(case_h28[2])])
	# Case G: the gap fall (drives in at pin 13, falls, drone).
	main._set_track("circuit")
	main.start_race()
	await frames(4)
	main.dip_timer = 1000.0
	for idx: Variant in main.prep_order.duplicate():
		grip_flip_switch(int(idx), "R")
	main._do_release()
	var drv_g28: bool = await wait_until(func() -> bool: return main.mode == main.MODE_DRIVE, 700)
	check(drv_g28, "stage28: case G setup release lands into DRIVE")
	main.debug_warp_to_s(main.gap_s0 - 45.0)
	var fg28: int = 0
	var hang_g28: bool = false
	while fg28 < 3000 and not hang_g28:
		await physics_frame
		fg28 += 1
		if main.mode == main.MODE_DRIVE:
			autopilot_steer()
			main.debug_pin_speed(13.0)
		elif main.mode == main.MODE_HANG:
			hang_g28 = true
	check(hang_g28, "stage28: the gap fall is caught by the drone (drone call from inside the gap)")
	# fly this recovery out with the same analytic assertion
	var corridor_g: Array[Vector3] = [main.anchor_pos]
	var prev_cg: Vector3 = main.anchor_pos
	for pi2: int in main.carrier_path.size():
		var nxt_cg: Vector3 = main.carrier_path[pi2]
		var seg_leng: float = prev_cg.distance_to(nxt_cg)
		var seg_ng: int = maxi(1, int(seg_leng / 5.0))
		for si3: int in range(1, seg_ng + 1):
			corridor_g.append(prev_cg.lerp(nxt_cg, float(si3) / float(seg_ng)))
		prev_cg = nxt_cg
	# Fall-site scoping, stated plainly: the gap catch wedges
	# the car UNDER the far lip (measured: caught ~4.7 m below
	# the lip's surface at its plan position, on the
	# centreline, where the lip's own stilt stands). ANY
	# extraction crosses that one cell - rising through it,
	# sliding under it, or dodging its stilt - for the ~1-2 s
	# the drone needs to lift the car out of the hole it fell
	# into; FP11's attach did the same, unmeasured. That cell
	# (the gap span plus both lips) is therefore EXEMPT from
	# the assertion and its brush count is printed for the
	# record. Everything beyond it - the climb-out's exit,
	# the whole 260 m carry across the climb - is asserted.
	var cands_g: Array = []
	for i3: int in main.t_pts.size():
		if bool(main.t_gap[i3]):
			continue
		var p3: Vector3 = main.t_pts[i3]
		var near3: bool = false
		for cp3: Vector3 in corridor_g:
			if Vector2(p3.x - cp3.x, p3.z - cp3.z).length() < 9.0:
				near3 = true
				break
		if near3:
			var frg: Dictionary = main._frame_at(float(i3))
			var exempt3: bool = float(i3) >= main.gap_s0 - 4.0 and float(i3) <= main.gap_s1 + 6.0
			cands_g.append([p3, Vector3(frg["side"]), Vector3(frg["tan"]), i3 % 10 == 0, 0.275, exempt3])
	var hits_g: int = 0
	var brush_g: int = 0
	var fg2: int = 0
	var saw_carry_g: bool = false
	while fg2 < 6000:
		await physics_frame
		fg2 += 1
		if main.mode != main.MODE_HANG or main.hang_phase == "dangle":
			break
		if main.hang_phase == "carry":
			saw_carry_g = true
		if not saw_carry_g:
			continue
		var bbg := AABB()
		var firstg: bool = true
		for mi2: MeshInstance3D in car_meshes28:
			var gag: AABB = mi2.global_transform * mi2.get_aabb()
			if firstg:
				bbg = gag
				firstg = false
			else:
				bbg = bbg.merge(gag)
		var cposg: Vector3 = main.car.global_position
		for cdg: Array in cands_g:
			var spg: Vector3 = cdg[0]
			var relg: Vector3 = cposg - spg
			var hitg: bool = false
			if absf(relg.dot(cdg[1])) < main.HALF_WIDTH + 1.7 and absf(relg.dot(cdg[2])) < 0.5 + 1.7:
				if bbg.position.y < spg.y + 0.02 and bbg.end.y > spg.y - main.RIBBON_DEPTH - 0.02:
					hitg = true
			if bool(cdg[3]) and Vector2(relg.x, relg.z).length() < float(cdg[4]) + 1.7:
				if bbg.position.y < spg.y + 0.02:
					hitg = true
			if hitg:
				if bool(cdg[5]) or Vector2(cposg.x - main.anchor_target.x, cposg.z - main.anchor_target.z).length() < 10.0:
					brush_g += 1
				else:
					hits_g += 1
	check(hits_g == 0 and saw_carry_g,
		"stage28: case G carry beyond the fall-site cell is collision-free (hits %d)" % hits_g)
	print("stage28: case G fall->dangle %d frames from the drone call; fall-site brush %d frame-samples (exempt cell, see comment)" % [fg2, brush_g])

	# ---------- stage 29: Fix Pass 12 (Items 5+6) ----------------
	# Item 5: the air trigger. The convicted case first: a
	# 48 m/s launch off the climb top (s 2125, rebound 2.0)
	# flies 3.64 s and LANDS (the old bare 2.4 s timer snatched
	# it at 2.41 s). The dip-lip flight (2.32 s) lands too.
	# Genuine losses still get the drone, and sooner: the
	# below-band dwell fires in well under the old 2.4 s.
	main._set_track("circuit")
	await frames(3)
	main.dip_timer = 1000.0
	var fly_case = func(s: float, rebound: float, kick: float) -> Array:
		main.debug_warp_to_s(s)
		# Fixture hygiene: a warp does not reset the suspension
		# or the body spring, and staged cold off the previous
		# case's HARD landing the car sat 0.27 m low (measured)
		# and the flight fizzled into a frame-1 "landing".
		# Zero the spring state so every case stages from the
		# same settled car a real driver would have.
		main.c_f = main.SUSP_REST
		main.c_r = main.SUSP_REST
		main.cv_f = 0.0
		main.cv_r = 0.0
		main.heave_off = 0.0
		main.body_sink = 0.0
		main.body_sink_v = 0.0
		await frames(3)
		main.debug_pin_speed(48.0)
		if kick != 0.0:
			var r0: Vector3 = main._heading_right()
			main.vel2 += Vector2(r0.x, r0.z) * kick
		main._enter_air(false, rebound)
		var fa: int = 0
		while fa < 700:
			await physics_frame
			fa += 1
			if main.mode == main.MODE_DRIVE:
				return [true, fa]
			if main.mode == main.MODE_HANG:
				return [false, fa]
		return [false, fa]
	var climb29: Array = await fly_case.call(2125.0, 2.0, 0.0)
	check(bool(climb29[0]) and int(climb29[1]) > 270 and int(climb29[1]) < 450,
		"stage29: climb-top launch LANDS after %.2f s of flight (no snatch)" % (float(climb29[1]) / 90.0))
	var lip29: Array = await fly_case.call(735.0, 2.0, 0.0)
	check(bool(lip29[0]) and int(lip29[1]) > 150 and int(lip29[1]) < 300,
		"stage29: dip-lip flight LANDS after %.2f s" % (float(lip29[1]) / 90.0))
	# The lost case keeps the lip's pop (rebound 2.0, like the
	# lip case): entering air at road height with rebound 0 on
	# the lip's downslope lands on frame 1 - the landing test
	# quite rightly sees a car still on the road. A real
	# lateral exit leaves WITH the lip's unload; the kick is
	# what makes it lost.
	var lost29: Array = await fly_case.call(735.0, 2.0, 30.0)
	check(not bool(lost29[0]) and int(lost29[1]) < 200,
		"stage29: a lateral exit off the dip lip is genuinely lost - drone in %.2f s (lateral-exit rule)" % (float(lost29[1]) / 90.0))
	# Item 6: the merge arrives aligned, and the garnishes exist.
	var spur29: Dictionary = main.track_data["circuit"]["spur"]
	var slen29: float = float(spur29["len"])
	var end29: Dictionary = main._spur_frame_at(slen29)
	var jfr29: Dictionary = main._frame_at(main.SPUR_JOIN_S)
	var resid29: float = absf(rad_to_deg(wrapf(main._spur_frame_yaw(end29) - main._frame_yaw(Vector3(jfr29["tan"])), -PI, PI)))
	check(resid29 <= 0.5,
		"stage29: merge heading residual %.2f deg (was 2.54 before the blend)" % resid29)
	var worst29: float = 0.0
	var prev_yaw29: float = main._spur_frame_yaw(main._spur_frame_at(slen29 - 12.0))
	for k29: int in range(11, -1, -1):
		var yw29: float = main._spur_frame_yaw(main._spur_frame_at(slen29 - float(k29)))
		worst29 = maxf(worst29, absf(rad_to_deg(wrapf(yw29 - prev_yaw29, -PI, PI))))
		prev_yaw29 = yw29
	check(worst29 <= 1.1,
		"stage29: exit-leg unwind over the last 12 m peaks at %.2f deg/m (entry side: <= 1.00)" % worst29)
	var circ_root29: Node3D = main.track_data["circuit"]["root"]
	check(circ_root29.get_node_or_null("SpurGuide") != null,
		"stage29: the amber guide strip is built on the capture corridor")
	check(circ_root29.get_node_or_null("SpurChevrons") != null,
		"stage29: descent chevrons are built")
	check(circ_root29.get_node_or_null("GantryLOOP") != null,
		"stage29: the LOOP gantry stands at s 158")
	var skirt29: MeshInstance3D = circ_root29.get_node("SpurSkirt") as MeshInstance3D
	var cols29: PackedColorArray = skirt29.mesh.surface_get_arrays(0)[Mesh.ARRAY_COLOR]
	var band29: int = 0
	for c29: Color in cols29:
		if absf(c29.r - 1.0) < 0.01 and absf(c29.g - 0.58) < 0.01 and absf(c29.b - 0.06) < 0.01:
			band29 += 1
	check(band29 > 200,
		"stage29: the ring's rim band is painted (bright underside verts %d)" % band29)

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
