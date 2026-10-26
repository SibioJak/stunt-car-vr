extends SceneTree

## Rendered-frame proof (needs a real GL frame - run under Xvfb, NOT
## --headless):
##   xvfb-run -a -s "-screen 0 1280x800x24" \
##     Godot --path . --script tests/render_proof.gd
## Capture 1: cockpit view FROM THE EYE ANCHOR (fallback camera) at the
## Drop Start dangle - the driver sits IN the car: grab wheel large in
## the lower centre, dash switches, blower low, ribbon ahead.
## Capture 2: the drone lift - car dangling on 4 lines under the drone,
## shot along the ribbon so the (Fix Pass 2) centreline centring shows.
## Also asserts the panel lists every accepted command and the lines
## are actually visible during the lift.

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


func snap(cam: Camera3D, out_name: String) -> void:
	cam.current = true
	for i: int in 6:
		await process_frame
	await RenderingServer.frame_post_draw
	var img: Image = root.get_texture().get_image()
	var out_path: String = ProjectSettings.globalize_path("res://tests/" + out_name)
	var err: Error = img.save_png(out_path)
	check(err == OK, "screenshot saved: tests/" + out_name)
	var distinct: Dictionary = {}
	for x: int in range(0, img.get_width(), 8):
		for y: int in range(0, img.get_height(), 8):
			distinct[img.get_pixel(x, y).to_rgba32()] = true
	check(distinct.size() > 25, "frame is a real scene, not a void (%d colors in %s)" % [distinct.size(), out_name])


func _init() -> void:
	_run()


func _run() -> void:
	root.size = Vector2i(1280, 800)
	var ps: PackedScene = load("res://main.tscn")
	main = ps.instantiate()
	root.add_child(main)
	main.test_mode = true
	for i: int in 30:
		await physics_frame

	# Panel completeness: every accepted command must be listed.
	var ptxt: String = main.panel_label.text
	for kw: String in ["GRIP", "Throttle", "Brake", "Boost", "Release", "Call drone",
			"restart", "lean", "Recenter", "SPACE", "1/2/3", "W/S"]:
		check(ptxt.contains(kw), "panel lists command keyword: %s" % kw)
	check(main.wheel_node != null, "grab wheel exists")
	check(main.switch_pivots.size() == 3, "3 prep switches on the dash")
	check(main.state_label.text.length() > 0, "state label is live (%s)" % main.state_label.text)

	# Fix Pass 2 anchor geometry: the fallback camera sits exactly on the
	# eye anchor, and the wheel hub is at natural reach from it (brief:
	# 0.42-0.48 m forward of the eye, 0.22-0.30 m below it).
	check(main.fallback_cam.position == main.EYE_ANCHOR,
		"fallback camera sits on the eye anchor %s" % str(main.EYE_ANCHOR))
	var hub: Vector3 = main._wheel_hub_local()
	var hub_fwd: float = main.EYE_ANCHOR.z - hub.z
	var hub_drop: float = main.EYE_ANCHOR.y - hub.y
	check(hub_fwd >= 0.42 and hub_fwd <= 0.48,
		"wheel hub %.2f m forward of the eye (natural reach band)" % hub_fwd)
	check(hub_drop >= 0.22 and hub_drop <= 0.30,
		"wheel hub %.2f m below the eye (natural reach band)" % hub_drop)

	# Capture 1: cockpit from the eye anchor itself, at the Drop Start.
	await snap(main.fallback_cam, "cockpit_view.png")

	# Capture 2: the lift. Put the car on the track, call the drone,
	# skip to the dangle and shoot from outside.
	main.debug_warp_to_s(100.0)
	for i2: int in 10:
		await physics_frame
	main._call_drone()
	var t: int = 0
	while main.mode != main.MODE_HANG and t < 600:
		await physics_frame
		t += 1
	check(main.mode == main.MODE_HANG, "lift engaged for capture 2")
	main.debug_set_hang_dangle()
	# Fix Pass 2: zero the pendulum and prove the recovery hang point is
	# centred over the centreline before shooting it.
	main.pend_th_f = 0.0
	main.pend_th_l = 0.0
	main.pend_om_f = 0.0
	main.pend_om_l = 0.0
	for i3: int in 40:
		await physics_frame
	check(main.line_mis[0].visible, "lift lines visible during the dangle")
	var fr_rc: Dictionary = main._frame_at(main.drop_target_s)
	var rel_rc: Vector3 = main.car.global_position - fr_rc["pos"]
	var lat_rc: float = rel_rc.dot(fr_rc["side"])
	check(absf(lat_rc) < 0.05,
		"recovery hang centred over the centreline (lat offset %.3f m)" % lat_rc)
	# Shoot from behind/above along the ribbon so the centring reads.
	var cam2 := Camera3D.new()
	main.add_child(cam2)
	var car_pos: Vector3 = main.car.global_position
	var rc_pos: Vector3 = fr_rc["pos"]
	var rc_tan: Vector3 = fr_rc["tan"]
	var rc_up: Vector3 = fr_rc["up"]
	var rc_side: Vector3 = fr_rc["side"]
	cam2.position = rc_pos - rc_tan * 8.5 + rc_up * 3.4 + rc_side * 2.6
	cam2.look_at(car_pos + Vector3(0, 0.8, 0), Vector3.UP)
	await snap(cam2, "lift_view.png")
	cam2.queue_free()

	# Fix Pass 1 proofs: the ribbon must visibly exist.
	check(main.get_node_or_null("TrackSkirt") != null, "ribbon box-section skirt mesh exists")

	# Capture 3: long sightline - offset shot from beside the climb,
	# looking through the banked corner toward the lip: surface, edge
	# strips and skirts legible at distance. (On-path vantages were tried
	# first: on the climb the near ribbon fills the frame edge-on; on the
	# descent the far ribbon converges to sub-pixel. The offset shot is
	# the honest proof - it is also what a driver who just left the
	# track would see.)
	main.debug_warp_to_s(60.0)
	for i4: int in 10:
		await physics_frame
	var fr_a: Dictionary = main._frame_at(90.0)
	var fr_b: Dictionary = main._frame_at(168.0)
	var pa: Vector3 = fr_a["pos"]
	var sa: Vector3 = fr_a["side"]
	var ua: Vector3 = fr_a["up"]
	var pb: Vector3 = fr_b["pos"]
	var ub: Vector3 = fr_b["up"]
	var cam3 := Camera3D.new()
	main.add_child(cam3)
	cam3.position = pa + sa * 9.0 + ua * 3.0
	cam3.look_at(pb + ub * 0.3, Vector3.UP)
	await snap(cam3, "sightline_view.png")
	cam3.queue_free()

	# Capture 4: grazing side angle on the start straight - ribbon
	# thickness and skirt band must read, not just the pylons.
	var fr30: Dictionary = main._frame_at(30.0)
	var p30: Vector3 = fr30["pos"]
	var sd30: Vector3 = fr30["side"]
	var up30: Vector3 = fr30["up"]
	var cam4 := Camera3D.new()
	main.add_child(cam4)
	cam4.position = p30 + sd30 * 7.0 + up30 * 0.8
	cam4.look_at(p30 - up30 * 0.2, Vector3.UP)
	await snap(cam4, "ribbon_side_view.png")
	cam4.queue_free()

	print("---")
	if failures == 0:
		print("RENDER PROOF: ALL %d CHECKS PASSED" % checks)
	else:
		print("RENDER PROOF: %d of %d CHECKS FAILED" % [failures, checks])
	quit(1 if failures > 0 else 0)
