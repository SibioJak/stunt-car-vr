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
## Fix Pass 4: the panel is TWO boards (commands ahead-right, DIAG
## low-left). From the anchor this proof checks both labels
## geometrically: text fits its board, every text corner projects
## inside the frame with >= 8% margin, and no car geometry crosses
## the sightlines to a grid of text points (car meshes via segment vs
## global-AABB; the wheel rim/hub via a plane-crossing annulus test).
## Capture 5 is a close-up of the DIAG board for legibility.
## Fix Pass 6 adds: capture 7 = the drone lift lines framed from
## below during the diagonal dangle, paired with a plan-view
## segment-intersection sweep over sampled hang states (the wires
## must never cross - Item 4); capture 8 = the driver's view of
## the WIDENED road on the climb (Item 2); and a body-spring sink
## sample read at the staged touchdown (Item 1).
## Fix Pass 7 adds: capture 9 = the driver's view down the new
## crest straight (Item 1); capture 10 = the extension's mirrored
## sweeper from trackside (Item 1); the panel keyword sweep gains
## the jitter command (Item 2 - the commands board and the DIAG
## JIT state must both list it).
## Fix Pass 8 adds: capture 11 = the car AIRBORNE off a crest-
## straight hump at cruise, from trackside (Item 2 - the unload
## is real, not a dip); capture 12 = the staircase from
## trackside, drops and treads reading as steps (Item 1).
## Fix Pass 9 (Item 3) adds: capture 13 = looking DOWN past the
## dangling car to the desert floor far below (the void is
## gone; there is a world under the ribbon now); capture 14 =
## a wide trackside shot mid-extension - ribbon on stilts,
## desert floor, hill ring, horizon. Capture 1 (cockpit from
## the dangle) now frames ribbon + desert + horizon from the
## seat, and capture 8's width assertion is the Crammond
## proportion (6.0x the wheel track = 9.36 m).

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


func _seg_cross_xz(a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> bool:
	# Proper plan-view (XZ) segment intersection, endpoints
	# excluded with a small margin (adjacent lift lines bound a
	# side of the lift quad - they must not cross mid-span).
	var rx: float = b.x - a.x
	var rz: float = b.z - a.z
	var sx: float = d.x - c.x
	var sz: float = d.z - c.z
	var den: float = rx * sz - rz * sx
	if absf(den) < 0.0000001:
		return false
	var qx: float = c.x - a.x
	var qz: float = c.z - a.z
	var t: float = (qx * sz - qz * sx) / den
	var u: float = (qx * rz - qz * rx) / den
	return t > 0.02 and t < 0.98 and u > 0.02 and u < 0.98


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


# --- Fix Pass 4 panel geometry helpers ---------------------------------
# Occluders: every visible MeshInstance3D under the car body EXCEPT the
# two boards themselves and the wheel assembly. The wheel is handled
# analytically (its AABB is the full disc - a sightline through the
# open centre would false-flag): a sightline counts as wheel-blocked
# only if it crosses the wheel plane inside the rim tube band or the
# hub disc.
# The occlusion test transforms each sightline into every occluder's
# OWN local space and tests it against the mesh's local AABB, which is
# exact for this box-built car. World- or body-space AABBs inflate for
# every rotated part (the dangling car's tilt balloons the 1.5 m
# nose's AABB by ~0.2 m; a tilted switch lever's AABB is 3x its
# thickness) and false-flag sightlines that pass centimetres clear of
# the actual mesh - measured, not hypothetical: the nose and both
# switch levers did exactly that during this pass's development.

func _collect_occluders(n: Node, inv_arr: Array[Transform3D], box_arr: Array[AABB], to_body: Transform3D) -> void:
	for child: Node in n.get_children():
		if child == main.panel_root or child == main.diag_root or child == main.wheel_node:
			continue
		if child is MeshInstance3D:
			var mi: MeshInstance3D = child as MeshInstance3D
			if mi.is_visible_in_tree():
				inv_arr.append((to_body * mi.global_transform).affine_inverse())
				box_arr.append(mi.get_aabb())
		_collect_occluders(child, inv_arr, box_arr, to_body)


func _seg_hits_aabb(a: Vector3, b: Vector3, box: AABB) -> bool:
	var av: Array[float] = [a.x, a.y, a.z]
	var dv: Array[float] = [b.x - a.x, b.y - a.y, b.z - a.z]
	var lo: Array[float] = [box.position.x, box.position.y, box.position.z]
	var hi: Array[float] = [box.end.x, box.end.y, box.end.z]
	var tmin: float = 0.02
	var tmax: float = 0.98
	for axis: int in 3:
		if absf(dv[axis]) < 1e-9:
			if av[axis] < lo[axis] or av[axis] > hi[axis]:
				return false
		else:
			var t1: float = (lo[axis] - av[axis]) / dv[axis]
			var t2: float = (hi[axis] - av[axis]) / dv[axis]
			if t1 > t2:
				var tmp: float = t1
				t1 = t2
				t2 = tmp
			tmin = maxf(tmin, t1)
			tmax = minf(tmax, t2)
			if tmin > tmax:
				return false
	return true


func _seg_hits_wheel(a: Vector3, b: Vector3, hub: Vector3, axis_n: Vector3) -> bool:
	var d: Vector3 = b - a
	var denom: float = d.dot(axis_n)
	if absf(denom) < 1e-9:
		return false
	var t: float = (hub - a).dot(axis_n) / denom
	if t < 0.02 or t > 0.98:
		return false
	var p: Vector3 = a + d * t
	var rel: Vector3 = p - hub
	var radial: float = (rel - axis_n * rel.dot(axis_n)).length()
	return (radial >= 0.155 and radial <= 0.245) or radial <= 0.075


func _label_view_check(label: Label3D, board: MeshInstance3D, cam: Camera3D, tag: String) -> void:
	var ab: AABB = label.get_aabb()
	var bsize: Vector3 = (board.mesh as BoxMesh).size
	check(ab.size.x <= bsize.x + 0.02 and ab.size.y <= bsize.y + 0.02,
		"%s: text (%.2f x %.2f m) fits its board (%.2f x %.2f m)" % [tag, ab.size.x, ab.size.y, bsize.x, bsize.y])
	var vp: Vector2 = Vector2(root.size)
	var eye: Vector3 = cam.global_position
	var fwd: Vector3 = -cam.global_transform.basis.z
	# Corners: all in front of the camera and inside the frame with an
	# 8% margin on every side (the fallback frame is NARROWER than the
	# Quest's, so passing here passes in the headset with more room).
	var worst: float = 1e9
	var all_front: bool = true
	for ci: int in 8:
		var corner_local: Vector3 = ab.get_endpoint(ci)
		var corner_world: Vector3 = label.global_transform * corner_local
		if (corner_world - eye).dot(fwd) <= 0.0:
			all_front = false
			continue
		var sp: Vector2 = cam.unproject_position(corner_world)
		worst = minf(worst, minf(minf(sp.x, vp.x - sp.x) / vp.x, minf(sp.y, vp.y - sp.y) / vp.y))
	check(all_front, "%s: every text corner is in front of the anchored eye" % tag)
	check(worst >= 0.08,
		"%s: every text corner inside the frame with >= 8%% margin (worst %.1f%%)" % [tag, worst * 100.0])
	# Occlusion: grid of points over the text face; no car mesh and
	# not the wheel rim/hub may cross the sightline from the eye.
	# Each sightline is tested in every occluder's own local space
	# against its exact local AABB (see the helpers note); the wheel
	# test runs in car-body space.
	var to_body: Transform3D = main.car_body.global_transform.affine_inverse()
	var occ_inv: Array[Transform3D] = []
	var occ_box: Array[AABB] = []
	_collect_occluders(main.car_body, occ_inv, occ_box, to_body)
	var eye_b: Vector3 = to_body * eye
	var hub_b: Vector3 = to_body * main.wheel_node.global_position
	var axis_b: Vector3 = (to_body.basis * main.wheel_node.global_transform.basis.y).normalized()
	var blocked: int = 0
	var samples: int = 0
	for ix: int in 7:
		for iy: int in 9:
			var lp: Vector3 = Vector3(
				ab.position.x + ab.size.x * float(ix) / 6.0,
				ab.position.y + ab.size.y * float(iy) / 8.0,
				ab.position.z)
			var wp: Vector3 = (to_body * label.global_transform) * lp
			samples += 1
			if _seg_hits_wheel(eye_b, wp, hub_b, axis_b):
				blocked += 1
				continue
			for oi: int in occ_inv.size():
				if _seg_hits_aabb(occ_inv[oi] * eye_b, occ_inv[oi] * wp, occ_box[oi]):
					blocked += 1
					break
	check(blocked == 0,
		"%s: no car geometry occludes the text (%d of %d sightlines blocked)" % [tag, blocked, samples])


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
	# Fix Pass 4: the text lives on two labels - commands on
	# panel_label, the DIAG block on diag_label. Force a DIAG refresh
	# so both hold their full text before the keyword sweep.
	main.diag_block = main._build_diag_block()
	main._update_panel()
	var ptxt: String = main.panel_label.text + "\n" + main.diag_label.text
	for kw: String in ["GRIP", "Throttle", "Brake", "Boost", "Release", "Call drone",
			"restart", "lean", "Recenter", "SPACE", "1/2/3", "W/S",
			"DIAG", "ANCHOR", "CAMH", "FRC", "Jitter", "JIT"]:
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

	# Fix Pass 4: both boards fully in frame and unobstructed from the
	# anchored eye (the fallback camera sits exactly on the anchor).
	_label_view_check(main.panel_label,
		main.panel_root.get_node("PanelBoard") as MeshInstance3D, main.fallback_cam, "commands panel")
	_label_view_check(main.diag_label,
		main.diag_root.get_node("DiagBoard") as MeshInstance3D, main.fallback_cam, "DIAG board")
	check(main.diag_label.text.contains("ANCHOR"), "DIAG board shows the live DIAG block")

	# Fix Pass 3 (Item 4): the stood-up wheel must FACE the driver.
	# Project the rim circle (in the tilt node's local XZ plane)
	# through the anchor camera and measure the screen-space ellipse:
	# minor/major axis ratio from the projected points' covariance.
	# A flat plate seen from the seat scores ~0.3; the target is
	# >= 0.55.
	var rim_pts: Array[Vector2] = []
	for k: int in 16:
		var ang: float = TAU * float(k) / 16.0
		var p_local := Vector3(cos(ang) * 0.205, 0.0, sin(ang) * 0.205)
		var p_world: Vector3 = main.wheel_node.global_transform * p_local
		rim_pts.append(main.fallback_cam.unproject_position(p_world))
	var mean := Vector2.ZERO
	for p: Vector2 in rim_pts:
		mean += p
	mean /= float(rim_pts.size())
	var sxx: float = 0.0
	var syy: float = 0.0
	var sxy: float = 0.0
	for p2: Vector2 in rim_pts:
		var d: Vector2 = p2 - mean
		sxx += d.x * d.x
		syy += d.y * d.y
		sxy += d.x * d.y
	var tr: float = sxx + syy
	var det: float = sxx * syy - sxy * sxy
	var disc: float = sqrt(maxf(tr * tr * 0.25 - det, 0.0))
	var lam_max: float = tr * 0.5 + disc
	var lam_min: float = maxf(tr * 0.5 - disc, 0.0)
	var ellipse_ratio: float = sqrt(lam_min / lam_max) if lam_max > 0.0 else 0.0
	check(ellipse_ratio >= 0.55,
		"wheel rim ellipse ratio %.2f >= 0.55 (wheel faces the driver, not a flat plate)" % ellipse_ratio)

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
	# Fix Pass 5: the lift proof now shoots the car hanging at a
	# DIAGONAL - both pendulum axes displaced, so the hang direction
	# (and with it the car attitude, via the lagged orientation)
	# carries fore-aft AND lateral tilt, like the multi-axis dangle
	# actually flies. The centred assertion above stays as the
	# Fix Pass 2 guard; this is the portrait of the new hang.
	main.pend_th_f = 0.30
	main.pend_th_l = 0.24
	main.pend_om_f = 0.0
	main.pend_om_l = 0.0
	for i3b: int in 30:
		await physics_frame
	var up_hang: Vector3 = main.car.global_transform.basis.y
	check(absf(up_hang.dot(fr_rc["tan"])) > 0.10 and absf(up_hang.dot(fr_rc["side"])) > 0.10,
		"car hangs at a diagonal (attitude tilt: fwd %.2f, lat %.2f)" % [
			up_hang.dot(fr_rc["tan"]), up_hang.dot(fr_rc["side"])])
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

	# Fix Pass 6 (Item 4): the lift wires must never cross. Sweep
	# the running dangle (the car is still hanging diagonally from
	# the debug pose above, swinging and dipping) and test every
	# pair of the 4 lift lines for a plan-view (XZ) intersection;
	# then capture 7 frames the lines from BELOW - Chris's run-6
	# viewpoint - so the pairing is visible, not just asserted.
	var crossings: int = 0
	var samples: int = 0
	for iw: int in 240:
		await physics_frame
		if iw % 8 == 0:
			samples += 1
			var dc6: Array = main._drone_corners()
			var cc6: Array = main._car_corners()
			for pa: int in 4:
				for pb: int in range(pa + 1, 4):
					if _seg_cross_xz(dc6[pa], cc6[pa], dc6[pb], cc6[pb]):
						crossings += 1
	check(crossings == 0,
		"no lift-wire crossings across %d sampled hang states (%d crossings)" % [samples, crossings])
	var cam7 := Camera3D.new()
	main.add_child(cam7)
	var fr_w: Dictionary = main._frame_at(main.drop_target_s)
	var car_pw: Vector3 = main.car.global_position
	var drone_pw: Vector3 = main.drone.global_position
	cam7.position = car_pw + (fr_w["side"] as Vector3) * 5.2 - Vector3.UP * 1.7 \
		- (fr_w["tan"] as Vector3) * 3.0
	cam7.look_at((car_pw + drone_pw) * 0.5 + Vector3.UP * 0.8, Vector3.UP)
	await snap(cam7, "wires_view.png")
	cam7.queue_free()

	# Capture 13 (Fix Pass 9, Item 3): looking DOWN past the
	# dangling car - the camera above/behind it, aimed steeply
	# down past the car toward the desert floor ~85 m below the
	# ribbon. The frame is the evidence the void is gone: car,
	# then air, then a WORLD - sand, mesas, the horizon's haze
	# band at the frame's lower reaches.
	var cam13 := Camera3D.new()
	main.add_child(cam13)
	var car_p13: Vector3 = main.car.global_position
	cam13.position = car_p13 + Vector3.UP * 5.5 - (fr_w["tan"] as Vector3) * 4.5 \
		+ (fr_w["side"] as Vector3) * 2.0
	cam13.look_at(car_p13 - Vector3.UP * 26.0, Vector3.UP)
	await snap(cam13, "desert_below_view.png")
	cam13.queue_free()

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

	# Capture 5 (Fix Pass 4): DIAG board close-up - the legibility
	# proof for the smaller type on the split board. The camera is a
	# CHILD of the DIAG board (0.55 m in front of its face): at this
	# point in the sequence the car is driving, and a world-parked
	# camera was left behind by ~5 m during snap's frames - measured
	# during this pass's development; the first close-up attempt
	# rendered the car's rear from down the track.
	var diag_up: Vector3 = main.diag_root.global_transform.basis.y
	var cam5 := Camera3D.new()
	main.diag_root.add_child(cam5)
	cam5.position = Vector3(0.0, 0.03, 0.55)
	cam5.look_at(main.diag_root.global_position, diag_up)
	await snap(cam5, "diag_closeup.png")
	cam5.queue_free()

	# Capture 6 (Fix Pass 5): the landing. Stage a ballistic drop
	# onto the landing straight through the production air/land
	# path, sample the suspension through the hit, and shoot the
	# car at peak compression - front wheels travelled up into the
	# body, nose down: the visible bounce, caught in a frame.
	main.debug_stage_landing(232.0, 1.3, 12.0)
	var land_peak: float = 0.0
	var land_sink: float = 0.0
	var land_frames: int = 0
	while land_frames < 240:
		await physics_frame
		land_peak = maxf(land_peak, (main.c_f + main.c_r) * 0.5)
		land_sink = maxf(land_sink, main.body_sink)
		if main.mode == main.MODE_DRIVE:
			break
		land_frames += 1
	var landed_ok: bool = main.mode == main.MODE_DRIVE
	# The touchdown must also land in the DRIVER (Fix Pass 6, Item
	# 1): keep sampling past the hit - the body spring peaks AFTER
	# the car springs by design. (The mode is read at loop exit:
	# this landing rebounds into a hop after touchdown.)
	for il2: int in 40:
		await physics_frame
		land_sink = maxf(land_sink, main.body_sink)
	check(land_sink > 0.004,
		"driver body sinks at the staged touchdown (peak sink %.3f m)" % land_sink)
	check(landed_ok, "staged landing touches down into DRIVE")
	check(land_peak > main.SUSP_REST + 0.08,
		"suspension travels at the staged touchdown (peak avg compression %.3f m)" % land_peak)
	# Camera RIDES the car body (beside the front axle, tight lens):
	# a world-parked camera loses the car during snap's frames
	# (measured twice: speck in v1, ribbon skirt in v2). Riding the
	# body also frames the travel honestly - the wheels move
	# relative to the body the camera is bolted to.
	var cam6 := Camera3D.new()
	main.car_body.add_child(cam6)
	cam6.fov = 42.0
	cam6.position = Vector3(3.0, 1.05, -0.9)
	var fwd6: Vector3 = -main.car.global_transform.basis.z
	cam6.look_at(main.car.global_position
		+ main.car.global_transform.basis.y * 0.2 + fwd6 * 0.8, Vector3.UP)
	await snap(cam6, "landing_view.png")
	cam6.queue_free()

	# Capture 8 (Fix Pass 6, Item 2): the widened road from the
	# driver's seat on the climb - a wide ribbon ahead, room to
	# manoeuvre. Numerical width asserted in the smoke (stage 2f);
	# here the frame itself is the evidence.
	# Fix Pass 9 (Item 3): the width is Crammond's proportion -
	# road full width = 6.0x the measured front wheel track.
	check(absf(main.HALF_WIDTH * 2.0 - 6.0 * main.WHEEL_TRACK_M) < 0.001,
		"road width is 6.0x the wheel track (%.2f m full, track %.2f m)" % [main.HALF_WIDTH * 2.0, main.WHEEL_TRACK_M])
	main.debug_warp_to_s(60.0)
	for i8: int in 10:
		await physics_frame
	await snap(main.fallback_cam, "wide_road_view.png")

	# Capture 9 (Fix Pass 7, Item 1): the driver's view down the
	# new crest straight - the ribbon rolling away in waves past
	# the old finish. Numerical length is the smoke's stage 8;
	# here the frame is the evidence the extension exists and
	# reads as road.
	main.debug_warp_to_s(main.ext_s0 + 8.0)
	for i9: int in 10:
		await physics_frame
	await snap(main.fallback_cam, "crest_view.png")

	# Capture 10 (Fix Pass 7, Item 1): the mirrored sweeper from
	# trackside - the bank leaning the OTHER way from the first
	# corner (capture 3's subject), so both banks are on record.
	var sw_mid: float = (main.sweeper_s0 + main.sweeper_s1) * 0.5
	var fr_sw: Dictionary = main._frame_at(sw_mid)
	var psw: Vector3 = fr_sw["pos"]
	var ssw: Vector3 = fr_sw["side"]
	var usw: Vector3 = fr_sw["up"]
	var tsw: Vector3 = fr_sw["tan"]
	var cam10 := Camera3D.new()
	main.add_child(cam10)
	cam10.position = psw - tsw * 16.0 + ssw * 7.0 + usw * 7.5
	cam10.look_at(psw + tsw * 8.0, Vector3.UP)
	await snap(cam10, "sweeper_view.png")
	cam10.queue_free()

	# Capture 11 (Fix Pass 8, Item 2): the hump unload, staged
	# exactly as the smoke's stage 10b - warped to the crest
	# straight, speed pinned at the 24 m/s cruise - and shot
	# from trackside the moment the car leaves the road. The
	# camera aims ahead of the separation point because snap's
	# frames let the car fly on ~2-3 m; the frame is the
	# evidence the car is OFF the ribbon, not dipping with it.
	main.debug_warp_to_s(main.ext_s0 + 2.0)
	var air11: bool = false
	var t11: int = 0
	while t11 < 900:
		main.debug_pin_speed(24.0)
		await physics_frame
		t11 += 1
		if main.mode == main.MODE_AIR and not main.air_from_gap:
			air11 = true
			break
		if main.mode == main.MODE_HANG or main.mode == main.MODE_DONE:
			break
	check(air11, "capture 11: car left the road over a hump at cruise (mode=%d)" % main.mode)
	var fr11: Dictionary = main._frame_at(main.car_s)
	var p11: Vector3 = fr11["pos"]
	var s11v: Vector3 = fr11["side"]
	var u11: Vector3 = fr11["up"]
	var t11v: Vector3 = fr11["tan"]
	var cam11 := Camera3D.new()
	main.add_child(cam11)
	cam11.position = p11 - t11v * 6.0 + s11v * 9.0 + u11 * 3.5
	cam11.look_at(p11 + t11v * 7.0 + u11 * 1.0, Vector3.UP)
	await snap(cam11, "hump_view.png")
	cam11.queue_free()
	main.debug_pin_speed(0.0)

	# Capture 12 (Fix Pass 8, Item 1): the staircase from
	# trackside, mid-flight of drops - the ribbon stepping down
	# in distinct drops with treads between (the steps must
	# READ as steps; stage 9 carries the numbers).
	var st_mid: float = (main.stairs_s0 + main.stairs_s1) * 0.5
	main.debug_warp_to_s(st_mid)
	for i12: int in 4:
		await physics_frame
	var fr12: Dictionary = main._frame_at(st_mid + 10.0)
	var p12: Vector3 = fr12["pos"]
	var s12v: Vector3 = fr12["side"]
	var u12: Vector3 = fr12["up"]
	var t12v: Vector3 = fr12["tan"]
	var cam12 := Camera3D.new()
	main.add_child(cam12)
	cam12.position = p12 - t12v * 14.0 + s12v * 10.0 + u12 * 5.0
	cam12.look_at(p12 + t12v * 6.0, Vector3.UP)
	await snap(cam12, "stairs_view.png")
	cam12.queue_free()

	# Capture 14 (Fix Pass 9, Item 3): the wide trackside shot -
	# from off the ribbon over the crest straight, taking in the
	# ribbon on its stilts, the desert floor ~85 m below it,
	# mesas, the hill ring and the horizon in one frame. This is
	# the scale evidence: the track has a world to dwarf the car
	# against now.
	var fr14: Dictionary = main._frame_at(main.ext_s0 + 55.0)
	var p14: Vector3 = fr14["pos"]
	var s14v: Vector3 = fr14["side"]
	var u14: Vector3 = fr14["up"]
	var t14v: Vector3 = fr14["tan"]
	var cam14 := Camera3D.new()
	main.add_child(cam14)
	cam14.position = p14 + s14v * 30.0 + u14 * 9.0 - t14v * 22.0
	cam14.look_at(p14 + t14v * 26.0 - u14 * 2.0, Vector3.UP)
	await snap(cam14, "desert_wide_view.png")
	cam14.queue_free()

	print("---")
	if failures == 0:
		print("RENDER PROOF: ALL %d CHECKS PASSED" % checks)
	else:
		print("RENDER PROOF: %d of %d CHECKS FAILED" % [failures, checks])
	quit(1 if failures > 0 else 0)
