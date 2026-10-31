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
## Fix Pass 24 adds: capture 25 = the turbo meter's portrait
## (the dash face with a staged 70% fill and the payout flash
## lit - the state the bar shows as a landing pays).
## Fix Pass 26 (Item 1) replaces the subject: the bar is
## deleted (the wheel hid it from the real seat) and capture
## 25 is the FLASK's portrait - plus the sightline sweep the
## bar never faced: from the shipped eye anchor, a sampled
## grid over the flask's silhouette must clear the wheel -
## rim, hub and spokes - at centre and at full lock both
## ways (and at the quarter locks for the record).
## Fix Pass 25 (Item 1) adds: the TIRE SIGHTLINE AUDIT - from
## the shipped eye anchor (the fallback camera), a sampled
## grid over each front tire's surface is classified
## in-frustum / occluded-by-bodywork (the FP4 local-AABB
## segment test, the tire's own AABB counting as an occluder
## for its far side), at rest, full compression and full
## droop. The audit sizes Item 4: it runs BEFORE any remedy.
## Capture 26 = the steering connection's portrait: the Drop
## Start dangle with a quarter lock dialled in, shot from the
## anchor - the gained display the driver dials by.

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


func _nearest_visible_road(eye: Vector3) -> float:
	# Fix Pass 11 (Item 1): eye in CAR space. The road plane in
	# car space sits at -(CLEARANCE + heave_off) - the car's
	# origin rides that far above the surface it rests on. A
	# descending ray from the eye reaches the road only if it
	# passes over EVERY bodywork box's far top edge (entering a
	# box - through its front face or its top - ends the ray on
	# the car, not the road), so the binding ray is the SHALLOWEST
	# per-box grazing angle, taken over each box's silhouette
	# profile point (top, far z, x clamped to the eye's corridor)
	# in car space. Direct MeshInstance3D children of car_body
	# only: floor, pods, nose stack, dash slab - knobs, levers,
	# boards and the open-centred wheel are not solid silhouette.
	var road_y: float = -(main.CLEARANCE + main.heave_off)
	var to_car: Transform3D = main.car.global_transform.affine_inverse()
	var theta: float = 999.0
	for child: Node in main.car_body.get_children():
		var mi: MeshInstance3D = child as MeshInstance3D
		if mi == null or not mi.is_visible_in_tree():
			continue
		var ab: AABB = mi.get_aabb()
		var cmin := Vector3(1e9, 1e9, 1e9)
		var cmax := Vector3(-1e9, -1e9, -1e9)
		for ci: int in 8:
			var corner: Vector3 = to_car * (mi.global_transform * ab.get_endpoint(ci))
			cmin = cmin.min(corner)
			cmax = cmax.max(corner)
		var p := Vector3(clampf(eye.x, cmin.x, cmax.x), cmax.y, cmin.z)
		if p.z < eye.z - 0.10 and p.y < eye.y:
			theta = minf(theta, atan2(eye.y - p.y, eye.z - p.z))
	if theta >= 900.0:
		return 999.0
	return (eye.y - road_y) / tan(theta)


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


# --- Fix Pass 25 (Item 1): the tire sightline audit --------------------
# Occluders: every visible MeshInstance3D under the car body
# EXCEPT the boards, the grab wheel and the four road wheels
# themselves (the FP4 _collect_occluders pattern, wheels cut).

func _collect_occluders_no_wheels(n: Node, inv_arr: Array[Transform3D], box_arr: Array[AABB], to_body: Transform3D, name_arr: Array[String]) -> void:
	for child: Node in n.get_children():
		if child == main.panel_root or child == main.diag_root or child == main.wheel_node:
			continue
		if main.wheel_mis.has(child as MeshInstance3D):
			continue
		if child is MeshInstance3D:
			var mi: MeshInstance3D = child as MeshInstance3D
			if mi.is_visible_in_tree():
				inv_arr.append((to_body * mi.global_transform).affine_inverse())
				box_arr.append(mi.get_aabb())
				name_arr.append(mi.name)
		_collect_occluders_no_wheels(child, inv_arr, box_arr, to_body, name_arr)


# Fraction of one front tire's sampled surface that the
# anchored eye can actually see: in the fallback frustum AND
# with a clear sightline. Sample grid in cylinder-local space
# (axis = Y, disc in XZ): both sidewall discs (centre + three
# rings of 8) and the tread band (12 around x 3 across). The
# tire's own AABB joins the occluders - the far sidewall is
# hidden by the tire itself, and AABB corners make the count
# conservative (a sightline that clips a box corner counts
# as blocked even where the round tire would clear it).
func _tire_audit_frac(wi: int, occ_inv: Array[Transform3D], occ_box: Array[AABB], occ_names: Array[String], to_body: Transform3D, eye_b: Vector3) -> Dictionary:
	var wmi: MeshInstance3D = main.wheel_mis[wi]
	# The audit measures the mesh the driver sees (FP25 Item
	# 4's visual radius; the pre-remedy runs measured the
	# shipped 0.30 m mesh through WHEEL_RAD_F, its then-size).
	var r: float = main.WHEEL_RAD_F_VIS
	var hw: float = main.WHEEL_WID_F * 0.5
	var pts: Array[Vector3] = []
	for sy: float in [-hw, hw]:
		pts.append(Vector3(0.0, sy, 0.0))
		for ring: float in [0.3, 0.6, 0.9]:
			for k: int in 8:
				var a: float = TAU * float(k) / 8.0
				pts.append(Vector3(cos(a) * r * ring, sy, sin(a) * r * ring))
	for ty: float in [-hw * 0.5, 0.0, hw * 0.5]:
		for k2: int in 12:
			var a2: float = TAU * float(k2) / 12.0
			pts.append(Vector3(cos(a2) * r, ty, sin(a2) * r))
	var inv_all: Array[Transform3D] = occ_inv.duplicate()
	var box_all: Array[AABB] = occ_box.duplicate()
	var names_all: Array[String] = occ_names.duplicate()
	inv_all.append((to_body * wmi.global_transform).affine_inverse())
	box_all.append(wmi.get_aabb())
	names_all.append("(the tire itself)")
	var cam: Camera3D = main.fallback_cam
	var n_in: int = 0
	var n_vis: int = 0
	var blockers: Dictionary = {}
	for lp: Vector3 in pts:
		var wp: Vector3 = wmi.global_transform * lp
		if not cam.is_position_in_frustum(wp):
			continue
		n_in += 1
		var wp_b: Vector3 = to_body * wp
		var blocked: bool = false
		for oi: int in inv_all.size():
			if _seg_hits_aabb(inv_all[oi] * eye_b, inv_all[oi] * wp_b, box_all[oi]):
				blocked = true
				blockers[names_all[oi]] = int(blockers.get(names_all[oi], 0)) + 1
				break
		if not blocked:
			n_vis += 1
	return {"n": pts.size(), "in": n_in, "vis": n_vis, "blockers": blockers}


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
	# Fix Pass 10 (Item 3): the circuit is the default track;
	# captures 1-14 were authored on the test ribbon. Select
	# the ribbon explicitly; the circuit gets captures 15-16.
	main._set_track("ribbon")
	for i: int in 10:
		await physics_frame

	# Panel completeness: every accepted command must be listed.
	# Fix Pass 4: the text lives on two labels - commands on
	# panel_label, the DIAG block on diag_label. Force a DIAG refresh
	# so both hold their full text before the keyword sweep.
	main.diag_block = main._build_diag_block()
	main._update_panel()
	var ptxt: String = main.panel_label.text + "\n" + main.diag_label.text
	for kw: String in ["GRIP", "Throttle", "Brake", "Boost", "Release", "Call crane",
			"restart", "lean", "track", "Recenter", "SPACE", "W/S", "V track",
			"DIAG", "ANCHOR", "CAMH", "HLD", "Jitter", "JIT", "CONTACT",
			"SEAT+", "SEAT-", "PgUp/PgDn", "BOTH", "SEAT", "DROP BUTTON", "Panels", "TAB",
			"amber view", "G view", "drop side", "M drop side", "GRAB"]:
		check(ptxt.contains(kw), "panel lists command keyword: %s" % kw)
	check(main.wheel_node != null, "grab wheel exists")
	# Fix Pass 13 (Item 1): the prep switches are deleted -
	# the dash top is bare and exactly five dash controls
	# survive (restart / lean / track buttons, seatup /
	# seatdn levers).
	# Fix Pass 14 (Item 6): the amber VIEW A/B button joins
	# them, registered last - six controls.
	# Fix Pass 15 (Item 3): the blue lever-SIDE button joins
	# at the vacated dash-top centre, registered last again -
	# seven controls.
	# Fix Pass 20 (Item 1): the DROP BUTTON joins on the dash
	# face, registered last - eight controls.
	check(main.dash_ctl_kinds == ["restart", "lean", "track", "seatup", "seatdn", "view", "side", "drop"],
		"dash carries exactly the eight controls (%s)" % str(main.dash_ctl_kinds))
	check(main.state_label.text.length() > 0, "state label is live (%s)" % main.state_label.text)

	# Fix Pass 2 anchor geometry: the fallback camera sits exactly on the
	# eye anchor, and the wheel hub is at natural reach from it (brief:
	# 0.42-0.48 m forward of the eye, 0.22-0.30 m below it).
	# Fix Pass 11 (Item 1): the anchor is read through _eye_anchor()
	# (EYE_ANCHOR + the driver's trim; trim is 0 in this proof).
	check(main.fallback_cam.position == main._eye_anchor(),
		"fallback camera sits on the eye anchor %s" % str(main._eye_anchor()))
	var hub: Vector3 = main._wheel_hub_local()
	var hub_fwd: float = main._eye_anchor().z - hub.z
	var hub_drop: float = main._eye_anchor().y - hub.y
	check(hub_fwd >= 0.42 and hub_fwd <= 0.48,
		"wheel hub %.2f m forward of the eye (natural reach band)" % hub_fwd)
	check(hub_drop >= 0.22 and hub_drop <= 0.30,
		"wheel hub %.2f m below the eye (natural reach band)" % hub_drop)

	# Fix Pass 11 (Item 1): the seat raise, MEASURED. From the eye,
	# the nearest visible road is set by the steepest grazing angle
	# over the bodywork silhouette (direct-child boxes of car_body:
	# floor, pods, nose, engine block, blower, dash - knobs, levers
	# and the open-centred wheel are not solid silhouette). Compute
	# it at the shipped anchor and at the pre-raise height and
	# assert the raise bought road; print both for the record.
	var nvr_new: float = _nearest_visible_road(main._eye_anchor())
	var nvr_old: float = _nearest_visible_road(main._eye_anchor() - Vector3(0.0, 0.12, 0.0))
	print("render proof: nearest visible road %.1f m at the raised seat, %.1f m at the old height" % [nvr_new, nvr_old])
	check(nvr_new < nvr_old - 0.5,
		"seat raise buys visible road (%.1f m now, %.1f m at the old height)" % [nvr_new, nvr_old])

	# Fix Pass 12 (Item 2): capture 1 is now shot the way the
	# owner drives - boards HIDDEN (their spawn state). Assert
	# that state, take the shot, then call the boards up
	# through the production toggle for the label checks and
	# close-ups below.
	check(not main.panels_visible and not main.panel_root.visible and not main.diag_root.visible,
		"boards are hidden at spawn (FP12 item 2 - capture 1 shows the driving view)")

	# Capture 1: cockpit from the eye anchor itself, at the Drop Start.
	await snap(main.fallback_cam, "cockpit_view.png")

	main._toggle_panels()
	check(main.panels_visible and main.panel_root.visible and main.diag_root.visible,
		"production toggle calls both boards up for the label checks")

	# Fix Pass 4: both boards fully in frame and unobstructed from the
	# anchored eye (the fallback camera sits exactly on the anchor).
	_label_view_check(main.panel_label,
		main.panel_root.get_node("PanelBoard") as MeshInstance3D, main.fallback_cam, "commands panel")
	_label_view_check(main.diag_label,
		main.diag_root.get_node("DiagBoard") as MeshInstance3D, main.fallback_cam, "DIAG board")
	check(main.diag_label.text.contains("ANCHOR"), "DIAG board shows the live DIAG block")

	# Fix Pass 11 (Item 2): the zone audit holds in this pose too,
	# and the zones are drawn over the controls for the record -
	# magenta markers along every activation segment (start,
	# middle, end), photographed from the eye, then removed.
	# Fix Pass 16 (Item 2): the audit's rule is INVERTED now -
	# volumes contain meshes with margin (see stage 23).
	var audit_rp: Dictionary = main.debug_dash_ctl_audit()
	var viol_rp: Array = audit_rp["violations"]
	check(viol_rp.is_empty(),
		"zone audit clean in the proof pose (%d violations%s)" % [viol_rp.size(),
			"" if viol_rp.is_empty() else ": " + str(viol_rp.slice(0, 2))])
	check(float(audit_rp["worst"]) <= -main.DASH_AUDIT_MARGIN,
		"grab volumes contain their meshes (worst slack %.3f m, margin %.3f)" % [float(audit_rp["worst"]), main.DASH_AUDIT_MARGIN])
	var to_body_rp: Transform3D = main.car_body.global_transform.affine_inverse()
	var markers: Array[MeshInstance3D] = []
	var mark_mat := StandardMaterial3D.new()
	mark_mat.albedo_color = Color(1.0, 0.0, 1.0)
	mark_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for ci2: int in main.dash_ctl_nodes.size():
		var seg2: Array = main._dash_ctl_segment(ci2)
		for si2: int in 3:
			var sp2: Vector3 = (seg2[0] as Vector3).lerp(seg2[1] as Vector3, float(si2) / 2.0)
			var mk := MeshInstance3D.new()
			var sm2 := SphereMesh.new()
			sm2.radius = 0.025
			sm2.height = 0.05
			mk.mesh = sm2
			mk.material_override = mark_mat
			# The segment runs along the handle's CENTRELINE -
			# markers placed on it would be swallowed by the
			# handle meshes. Stand them 5.5 cm toward the driver
			# (body +Z) so the photograph shows the zone's line
			# floating on the control it belongs to.
			mk.position = to_body_rp * sp2 + Vector3(0.0, 0.0, 0.055)
			main.car_body.add_child(mk)
			markers.append(mk)
	# Fix Pass 11 (Item 4): the drop lever's grab segment
	# joined the overlay (same stand-off toward the driver).
	# Fix Pass 20 (Item 1): the lever is retired - the DROP
	# BUTTON's single point marker takes its place.
	var mk3 := MeshInstance3D.new()
	var sm3 := SphereMesh.new()
	sm3.radius = 0.025
	sm3.height = 0.05
	mk3.mesh = sm3
	mk3.material_override = mark_mat
	mk3.position = to_body_rp * main.debug_drop_btn_point() + Vector3(0.0, 0.0, 0.055)
	main.car_body.add_child(mk3)
	markers.append(mk3)
	await snap(main.fallback_cam, "zone_overlay_view.png")
	for mk2: MeshInstance3D in markers:
		main.car_body.remove_child(mk2)
		mk2.free()

	# Fix Pass 13 (Item 1): the dash top AFTER the prep
	# removal - a dedicated look down at the console: bare
	# where the three switches stood, the buttons in frame.
	# Fix Pass 15 (Item 3): the drop lever has left the top
	# for the face; the blue SIDE button holds the centre.
	var cam_dt := Camera3D.new()
	main.car_body.add_child(cam_dt)
	cam_dt.position = Vector3(0.0, 1.80, 0.55)
	await physics_frame
	await physics_frame
	cam_dt.look_at(main.car_body.global_transform * Vector3(0, 0.90, -0.62), Vector3.UP)
	await snap(cam_dt, "dash_top_view.png")
	cam_dt.queue_free()

	# Fix Pass 11 (Item 4): the release control's own portrait -
	# it sits beside the driver, outside the eye camera's
	# frame, so it gets a dedicated camera.
	# Fix Passes 12/13/15 reframed it through the lever's
	# lives (shifter, centre lever, face lever).
	# Fix Pass 20 (Item 1): the portrait is the DROP BUTTON's
	# now - on the dash face at the lever's spot; then the
	# mirror is toggled and the LEFT face gets the same
	# portrait. (The capture names change with the subject:
	# drop_btn_view.png / drop_btn_view_left.png.)
	check(main.drop_btn_node != null, "the drop button is built on the dash face")
	var cam_dl := Camera3D.new()
	main.car_body.add_child(cam_dl)
	cam_dl.position = Vector3(0.95, 1.40, 0.15)
	await physics_frame
	await physics_frame
	cam_dl.look_at(main.car_body.global_transform * main.drop_btn_node.position, Vector3.UP)
	await snap(cam_dl, "drop_btn_view.png")
	cam_dl.queue_free()
	if not main.drop_btn_left:
		main._toggle_drop_btn_side()
	var cam_dl2 := Camera3D.new()
	main.car_body.add_child(cam_dl2)
	cam_dl2.position = Vector3(-0.95, 1.40, 0.15)
	await physics_frame
	await physics_frame
	cam_dl2.look_at(main.car_body.global_transform * main.drop_btn_node.position, Vector3.UP)
	await snap(cam_dl2, "drop_btn_view_left.png")
	cam_dl2.queue_free()
	if main.drop_btn_left:
		main._toggle_drop_btn_side()

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
	main._call_crane()
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
	# Capture 2b (Fix Pass 16, Item 3): BOTH HANDS ON THE WHEEL.
	# The standing defect since Test 1: both hands could GRAB,
	# but only the driver's rep read as holding - the passenger
	# rep hung at the raw controller pose while the rim turned
	# under it. The fix poses the passenger rep from the wheel's
	# spin node (its grab point stored in spin-local space).
	# Staged here, in the settled dangle (the wheel is live in
	# the dangle since FP13, and the hanging car barely moves),
	# through the production grab path on the test hands; the
	# assertions measure the REP's transform, not the state -
	# this layer (controller reps under the XR rig) is exactly
	# what the headless smoke cannot see, which is why the
	# defect survived four passes of staged-green lever fixes.
	var hub_l2b: Vector3 = main._wheel_hub_local()
	var pv2b: Vector3 = main._wheel_plane_v()
	var rim_pt2b = func(r: float, phi: float) -> Vector3:
		return main.car.global_transform * (hub_l2b + r * (cos(phi) * Vector3.RIGHT + sin(phi) * pv2b))
	var rep_ang2b = func(p: Vector3) -> float:
		var lc: Vector3 = main.car.to_local(p) - hub_l2b
		return atan2(lc.dot(pv2b), lc.x)
	main.test_hand_set = true
	main.test_hand_pos["R"] = rim_pt2b.call(0.25, -0.6)
	main.test_grip["R"] = 1.0
	main._poll_grab("R", main.hand_ctrl["R"], 0.016)
	check(main.grab_hand == "R", "both-hands: the right hand drives the wheel")
	main.test_hand_pos["L"] = rim_pt2b.call(0.25, 0.6)
	main.test_grip["L"] = 1.0
	main._poll_grab("L", main.hand_ctrl["L"], 0.016)
	check(bool(main.rim_attach["L"]), "both-hands: the left hand attaches to the rim")
	await physics_frame
	var l_rep_0: Vector3 = main.ctrl_rep["L"].global_position
	var la0: float = rep_ang2b.call(l_rep_0)
	check(absf(wrapf(la0 - 0.6, -PI, PI)) < 0.05,
		"both-hands: the passenger rep sits at its grab point (%.2f rad)" % la0)
	var wa2b: float = main.wheel_angle
	main.test_hand_pos["R"] = rim_pt2b.call(0.25, -0.1)
	main._poll_grab("R", main.hand_ctrl["R"], 0.016)
	check(absf(wrapf(main.wheel_angle - wa2b - 0.5, -PI, PI)) < 0.05,
		"both-hands: the driver turns the wheel 0.5 rad")
	await physics_frame
	var l_rep_1: Vector3 = main.ctrl_rep["L"].global_position
	var la1: float = rep_ang2b.call(l_rep_1)
	check(absf(wrapf(la1 - la0 - 0.5, -PI, PI)) < 0.05,
		"both-hands: the passenger rep RIDES the rim (%.2f -> %.2f rad)" % [la0, la1])
	var hub_w2b: Vector3 = main.car.global_transform * hub_l2b
	check(absf(l_rep_1.distance_to(hub_w2b) - l_rep_0.distance_to(hub_w2b)) < 0.01,
		"both-hands: the passenger rep stays on the rim (radius constant)")
	check(main.ctrl_rep["R"].global_position.distance_to(main.hand_ctrl["R"].global_position) < 0.0001,
		"both-hands: the driver rep still equals its controller pose")
	var cam2b := Camera3D.new()
	main.car_body.add_child(cam2b)
	cam2b.fov = 55.0
	cam2b.position = Vector3(0.0, 1.32, 0.38)
	cam2b.look_at(hub_w2b, Vector3.UP)
	await snap(cam2b, "both_hands_wheel.png")
	cam2b.queue_free()
	# restore: wheel back to its entry angle, grips released
	main.test_hand_pos["R"] = rim_pt2b.call(0.25, -0.6)
	main._poll_grab("R", main.hand_ctrl["R"], 0.016)
	main.test_grip["L"] = 0.0
	main.test_grip["R"] = 0.0
	main._poll_grab("L", main.hand_ctrl["L"], 0.016)
	main._poll_grab("R", main.hand_ctrl["R"], 0.016)
	main.test_hand_set = false
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

	# Fix Pass 15 (Item 2): the crane itself, three-quarter
	# view - post on its pad, jib out over the road, the car
	# on its chains. The rig must be VISIBLE in the hang.
	check(main.crane.visible, "the crane rig is visible in the hang")
	var cam_cr := Camera3D.new()
	main.add_child(cam_cr)
	cam_cr.position = rc_pos + rc_side * 11.0 + rc_up * 2.6 - rc_tan * 7.0
	cam_cr.look_at(main.pivot_pos + Vector3(0, -1.6, 0), Vector3.UP)
	await snap(cam_cr, "crane_view.png")
	cam_cr.queue_free()

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
			var dc6: Array = main._crane_corners()
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
	var pivot_pw: Vector3 = main.pivot_pos
	cam7.position = car_pw + (fr_w["side"] as Vector3) * 5.2 - Vector3.UP * 1.7 \
		- (fr_w["tan"] as Vector3) * 3.0
	cam7.look_at((car_pw + pivot_pw) * 0.5 + Vector3.UP * 0.8, Vector3.UP)
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
	# (Fix Pass 10: the skirt is a child of the ribbon's own
	# track root now that two tracks exist.)
	var rib_root: Node3D = main.track_data["ribbon"]["root"]
	check(rib_root.get_node_or_null("TrackSkirt") != null, "ribbon box-section skirt mesh exists")

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
	# Fix Pass 10 (Item 3): 12.0 m full width everywhere (the
	# Fix Pass 9 Crammond proportion superseded by the owner's
	# two-cars-passing absolute).
	check(absf(main.HALF_WIDTH * 2.0 - 12.0) < 0.001,
		"road width is 12.0 m full (%.2f m)" % (main.HALF_WIDTH * 2.0))
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

	# Capture 15 (Fix Pass 10, Item 3): the driver's view up
	# the circuit's signature climb - 235 m at 17.5 deg, the
	# road walling up ahead of the car.
	main._set_track("circuit")
	for i: int in 10:
		await physics_frame
	var cf15: Dictionary = main.track_data["circuit"]["features"]
	main.debug_warp_to_s(float(cf15["climb_s0"]) + 25.0)
	for i: int in 3:
		await physics_frame
	await snap(main.fallback_cam, "circuit_climb_view.png")

	# Capture 16: the wide shot - home straight and the
	# closing hairpin from high off the loop's south side; the
	# circuit's scale against the same desert.
	var fr16: Dictionary = main._frame_at(190.0)
	var p16: Vector3 = fr16["pos"]
	var s16v: Vector3 = fr16["side"]
	var u16: Vector3 = fr16["up"]
	var t16v: Vector3 = fr16["tan"]
	var cam16 := Camera3D.new()
	main.add_child(cam16)
	cam16.position = p16 + s16v * 120.0 + u16 * 70.0 - t16v * 60.0
	cam16.look_at(p16 + t16v * 40.0, Vector3.UP)
	await snap(cam16, "circuit_wide_view.png")
	cam16.queue_free()
	check(main.track_len > 3000.0,
		"capture 16: the wide shot is the circuit (%.0f m)" % main.track_len)

	# Capture 20 (Fix Pass 11, Item 6): THE RAKE, side profile.
	# The car at rest on the flat home straight: the body must
	# sit pitched nose-down by the derived rake while BOTH
	# axles' contact patches stay on one plane (the model's
	# CLEARANCE hover) - the stance comes from the suspension's
	# attach heights, not from a tilted mesh, and this capture
	# plus its numbers are the proof.
	main.debug_warp_to_s(10.0)
	main.debug_pin_speed(0.0)
	main.test_throttle = 0.0
	for i: int in 90:
		await physics_frame
	var fr20: Dictionary = main._frame_at(main.car_s)
	var fwd_b20: Vector3 = -main.car_body.global_transform.basis.z
	var body_pitch20: float = rad_to_deg(asin(clampf(fwd_b20.y, -1.0, 1.0)))
	var rake_expect20: float = rad_to_deg(atan2(
		main.WHEEL_RAD_R - main.WHEEL_RAD_F, main.WHEELBASE))
	check(body_pitch20 < -rake_expect20 + 0.6 and body_pitch20 > -rake_expect20 - 0.6,
		"capture 20: body sits at the rake (pitch %.2f deg, derived %.2f deg nose-down)" % [
			body_pitch20, rake_expect20])
	var bot_f20: float = 0.0
	var bot_r20: float = 0.0
	var dia_f20: float = 0.0
	var dia_r20: float = 0.0
	for wi20: int in main.wheel_mis.size():
		var ab20: AABB = main.wheel_mis[wi20].global_transform * main.wheel_mis[wi20].get_aabb()
		if main.wheel_axle[wi20] == 0:
			bot_f20 += ab20.position.y * 0.5
			dia_f20 = maxf(dia_f20, ab20.size.y)
		else:
			bot_r20 += ab20.position.y * 0.5
			dia_r20 = maxf(dia_r20, ab20.size.y)
	var road_y20: float = (fr20["pos"] as Vector3).y
	check(absf(bot_f20 - bot_r20) < 0.02,
		"capture 20: both axles planted on one plane (front bottom %.3f, rear %.3f rel road)" % [
			bot_f20 - road_y20, bot_r20 - road_y20])
	check(bot_f20 - road_y20 > main.CLEARANCE - 0.03 and bot_f20 - road_y20 < main.CLEARANCE + 0.03,
		"capture 20: contact plane is the model's ride height (%.3f rel road)" % (bot_f20 - road_y20))
	check(dia_r20 > dia_f20 * 1.4,
		"capture 20: rear tyres dwarf the fronts (dia %.2f vs %.2f m)" % [dia_r20, dia_f20])
	var p20: Vector3 = fr20["pos"]
	var s20v: Vector3 = fr20["side"]
	var u20: Vector3 = fr20["up"]
	var cam20 := Camera3D.new()
	main.add_child(cam20)
	cam20.position = p20 + s20v * 5.4 + u20 * 0.55
	cam20.look_at(main.car.global_position + Vector3.UP * 0.35, Vector3.UP)
	await snap(cam20, "rake_profile_view.png")
	cam20.queue_free()

	# FP23: captures 17-19 (the FP10 loop spur - fork view,
	# ring view, cockpit mid-ring) are DELETED with the loop.
	# The 20-22 series below re-shoots their approach stations
	# as the home-straight absence series.


	# Captures 20-22 (Fix Pass 23): the home straight from the
	# driver's seat, boards HIDDEN - the stations the FP12 loop
	# approach series used (warps to s 70 / 120 / 168), re-shot
	# after the loop's removal. What the frames must show is an
	# absence: no LOOP gantry, no amber guide strip curving off
	# the centreline, no ring on the horizon - one clean line.
	if main.panels_visible:
		main._toggle_panels()
	check(not main.panel_root.visible and not main.diag_root.visible,
		"FP23 home straight series: boards hidden, as the owner drives")
	# State hygiene: earlier captures can leave the car
	# mid-hang; start_race is the production reset, and the
	# warp then parks the car on the road, pinned at 0 through
	# the settle (a driverless roll photographed a recovery
	# instead of the road in the FP12 series' first run).
	main.start_race()
	for i: int in 4:
		await physics_frame
	main.debug_warp_to_s(70.0)
	for i: int in 30:
		main.debug_pin_speed(0.0)
		await physics_frame
	await snap(main.fallback_cam, "home_straight_100m.png")
	main.debug_warp_to_s(120.0)
	for i: int in 30:
		main.debug_pin_speed(0.0)
		await physics_frame
	await snap(main.fallback_cam, "home_straight_50m.png")
	main.debug_warp_to_s(168.0)
	for i: int in 30:
		main.debug_pin_speed(0.0)
		await physics_frame
	await snap(main.fallback_cam, "home_straight_20m.png")
	# The FP12 guide-strip test, INVERTED (FP23): the amber
	# family the guide strip and the ring's rim band were
	# painted in must now be ABSENT from the ROAD BAND of the
	# 20 m frame (y 30-62%, x 30-75% - where the far road sits;
	# the lower half is the car's nose and the near road). The
	# dashed edge strips (g ~0.72) sit outside the test's g
	# window by construction; the strip read ~70 sampled px
	# in this band when it existed.
	var img20: Image = Image.load_from_file(ProjectSettings.globalize_path("res://tests/home_straight_20m.png"))
	var guide_px: int = 0
	if img20 != null:
		for y20: int in range(int(img20.get_height() * 0.30), int(img20.get_height() * 0.62), 2):
			for x20: int in range(int(img20.get_width() * 0.30), int(img20.get_width() * 0.75), 2):
				var pc20: Color = img20.get_pixel(x20, y20)
				if absf(pc20.r - 1.0) < 0.06 and absf(pc20.g - 0.60) < 0.06 and pc20.b < 0.12:
					guide_px += 1
	check(guide_px == 0, "FP23: no guide-strip/ring amber in the home straight frame (%d px)" % guide_px)


	# FP23: capture 23 (the spur descent leg and its chevrons)
	# is DELETED with the loop.


	# Capture 23 (Fix Pass 27): THE LINE, from the driver's
	# seat 8 m before the seam, the chequer stripe 10-11 m
	# ahead across the start/finish line. Two claims: the
	# PAINT is in the road band (white cells bright, black
	# cells dark, sampled in the same window), and the SKY
	# carries no banner green - the FP26-and-earlier span
	# (unshaded 0.15/0.60/0.20) slabbed across exactly this
	# band when it existed. State hygiene as the FP23 series:
	# start_race, warp, pin through the settle.
	main.start_race()
	for i: int in 4:
		await physics_frame
	main.debug_warp_to_s(main.track_len - 8.0)
	for i: int in 30:
		main.debug_pin_speed(0.0)
		await physics_frame
	await snap(main.fallback_cam, "finish_line_view.png")
	var img23: Image = Image.load_from_file(ProjectSettings.globalize_path("res://tests/finish_line_view.png"))
	var white23: int = 0
	var black23: int = 0
	var green23: int = 0
	if img23 != null:
		for y23: int in range(int(img23.get_height() * 0.45), int(img23.get_height() * 0.72), 2):
			for x23: int in range(int(img23.get_width() * 0.25), int(img23.get_width() * 0.75), 2):
				var pc23: Color = img23.get_pixel(x23, y23)
				if pc23.r > 0.75 and pc23.g > 0.75 and pc23.b > 0.75:
					white23 += 1
				if pc23.r < 0.12 and pc23.g < 0.12 and pc23.b < 0.12:
					black23 += 1
		for y23b: int in range(int(img23.get_height() * 0.03), int(img23.get_height() * 0.28), 2):
			for x23b: int in range(0, img23.get_width(), 2):
				var pc23b: Color = img23.get_pixel(x23b, y23b)
				if pc23b.g > 0.42 and pc23b.r < 0.38 and pc23b.b < 0.38 and pc23b.g > pc23b.r + 0.15:
					green23 += 1
	check(white23 >= 8 and black23 >= 4, "FP27: the chequer line is in the road band (white %d, black %d sampled px)" % [white23, black23])
	check(green23 == 0, "FP27: no banner green in the sky band - the span is gone (%d px)" % green23)


	# Capture 24 (Item 4): the dip-valley sightline - the far
	# read the fog cut and wider edge strips serve. Driver's
	# view from the valley floor, the road running on across
	# the desert toward the climb.
	var cf24: Dictionary = main.track_data["circuit"]["features"]
	main.debug_warp_to_s(float(cf24["dip_s0"]) + 80.0)
	for i: int in 30:
		main.debug_pin_speed(0.0)
		await physics_frame
	await snap(main.fallback_cam, "dip_valley_view.png")

	# Capture 25 (Fix Pass 26, Item 1): the FLASK's portrait -
	# the dash-top vessel at a staged 70% fill with the payout
	# flash lit: the state the liquid shows in the moment a
	# landing pays. (FP24's subject was the dash-face bar;
	# the wheel hid it from the real seat and it is deleted.)
	# Structural checks only - under this sandbox's
	# Compatibility/llvmpipe renderer the capture is not
	# colour truth.
	main._set_track("ribbon")
	main.start_race()
	main.debug_warp_to_s(30.0)
	main.boost_meter = 84.0
	await physics_frame
	await physics_frame
	check(main.flask_node != null and main.flask_liquid_mi != null and main.flask_liquid_mi.visible,
		"capture 25: the flask and its liquid exist and are visible in DRIVE")
	check(absf(main.turbo_fill_frac - 0.70) < 0.02,
		"capture 25: the staged fill is the staged stock (%.2f)" % main.turbo_fill_frac)
	main.pay_flash_t = main.PAY_FLASH_S
	var cam25 := Camera3D.new()
	main.car_body.add_child(cam25)
	cam25.position = Vector3(0.55, 1.35, 0.25)
	await physics_frame
	cam25.look_at(main.car_body.global_transform * main.FLASK_POS, Vector3.UP)
	await snap(cam25, "turbo_meter_view.png")
	cam25.queue_free()

	# Fix Pass 26 (Item 1): THE FLASK SIGHTLINE SWEEP - the
	# discipline the FP24 bar failed in the owner's headset.
	# Staged in the settled dangle, boards hidden. A grid of
	# sample points over the flask's silhouette (every flask
	# mesh's AABB corners + face points, in body space) is
	# sighted from the shipped eye anchor; a sightline is
	# blocked if it crosses the wheel plane inside the rim
	# band or hub disc (the FP4 annulus test) or hits a spoke
	# box (exact local-AABB test on the spin node's box
	# meshes, re-collected at each wheel angle). The wheel is
	# posed at CENTRE, FULL LOCK both ways (wheel_angle =
	# +-PI, the steer clamp's ends) and the quarter locks.
	main.start_race()
	main.debug_set_hang_dangle()
	main.pend_th_f = 0.0
	main.pend_th_l = 0.0
	main.pend_om_f = 0.0
	main.pend_om_l = 0.0
	main.dip_timer = 1000.0
	if main.panels_visible:
		main._toggle_panels()
	await physics_frame
	var to_body26: Transform3D = main.car_body.global_transform.affine_inverse()
	var eye_b26: Vector3 = to_body26 * main.fallback_cam.global_position
	var hub_b26: Vector3 = to_body26 * main.wheel_node.global_position
	var axis_b26: Vector3 = (to_body26.basis * main.wheel_node.global_transform.basis.y).normalized()
	var flask_pts26: Array[Vector3] = []
	var fstack26: Array[Node] = [main.flask_node]
	while not fstack26.is_empty():
		var fnd26: Node = fstack26.pop_back()
		for fch26: Node in fnd26.get_children():
			fstack26.append(fch26)
		var fmi26: MeshInstance3D = fnd26 as MeshInstance3D
		if fmi26 != null:
			var fab26: AABB = fmi26.get_aabb()
			var fxf26: Transform3D = to_body26 * fmi26.global_transform
			for ci26: int in 8:
				flask_pts26.append(fxf26 * fab26.get_endpoint(ci26))
			for fx26: float in [0.25, 0.5, 0.75]:
				for fy26: float in [0.25, 0.5, 0.75]:
					flask_pts26.append(fxf26 * Vector3(
						fab26.position.x + fab26.size.x * fx26,
						fab26.position.y + fab26.size.y * fy26,
						fab26.end.z))
					flask_pts26.append(fxf26 * Vector3(
						fab26.position.x + fab26.size.x * fx26,
						fab26.end.y,
						fab26.position.z + fab26.size.z * fy26))
	var sweep_blocked26: int = 0
	var sweep_n26: int = 0
	var sweep_min_rad26: float = 1e9
	for wa26: float in [0.0, PI, -PI, PI * 0.5, -PI * 0.5]:
		main.wheel_angle = wa26
		main._refresh_car_visuals()
		await physics_frame
		var spoke_inv26: Array[Transform3D] = []
		var spoke_box26: Array[AABB] = []
		for sch26: Node in main.wheel_spin.get_children():
			var smi26: MeshInstance3D = sch26 as MeshInstance3D
			if smi26 != null and smi26.mesh is BoxMesh:
				spoke_inv26.append(smi26.global_transform.affine_inverse())
				spoke_box26.append(smi26.get_aabb())
		var blocked26: int = 0
		for fp26: Vector3 in flask_pts26:
			sweep_n26 += 1
			var d26: Vector3 = fp26 - eye_b26
			var den26: float = d26.dot(axis_b26)
			if absf(den26) > 1e-9:
				var t26: float = (hub_b26 - eye_b26).dot(axis_b26) / den26
				if t26 > 0.02 and t26 < 0.98:
					var rel26: Vector3 = eye_b26 + d26 * t26 - hub_b26
					var rad26: float = (rel26 - axis_b26 * rel26.dot(axis_b26)).length()
					sweep_min_rad26 = minf(sweep_min_rad26, rad26)
			if _seg_hits_wheel(eye_b26, fp26, hub_b26, axis_b26):
				blocked26 += 1
				continue
			for si26: int in spoke_inv26.size():
				if _seg_hits_aabb(spoke_inv26[si26] * eye_b26, spoke_inv26[si26] * fp26, spoke_box26[si26]):
					blocked26 += 1
					break
		print("render proof FP26 flask sweep: wheel %+.2f rad - %d of %d sightlines blocked" % [wa26, blocked26, flask_pts26.size()])
		sweep_blocked26 += blocked26
	check(sweep_blocked26 == 0,
		"FP26 flask sweep: the flask is NEVER behind the rim, hub or spokes (%d of %d sightlines blocked; min wheel-plane crossing radius %.3f m, rim band ends 0.245, spokes reach 0.201)" % [sweep_blocked26, sweep_n26, sweep_min_rad26])
	main.wheel_angle = 0.0
	main._refresh_car_visuals()
	# Restore the state the FP25 audit below was written
	# against (DRIVE on the ribbon at s 30, capture 25's
	# staged stock).
	main.debug_warp_to_s(30.0)
	main.boost_meter = 84.0
	await physics_frame
	await physics_frame

	# Fix Pass 25 (Item 1): THE TIRE SIGHTLINE AUDIT. Staged
	# in DRIVE on the ribbon (capture 25's state), boards
	# hidden - the driving view. Suspension posed per state;
	# the occluder set is body-relative rigid, so it is
	# collected once. The numbers print BEFORE any remedy is
	# applied anywhere - they size Item 4 (see the README).
	if main.panels_visible:
		main._toggle_panels()
	main.fallback_cam.current = true
	await physics_frame
	var to_body25: Transform3D = main.car_body.global_transform.affine_inverse()
	var occ_inv25: Array[Transform3D] = []
	var occ_box25: Array[AABB] = []
	var occ_names25: Array[String] = []
	_collect_occluders_no_wheels(main.car_body, occ_inv25, occ_box25, to_body25, occ_names25)
	for oi25: int in occ_inv25.size():
		var bab25: AABB = occ_inv25[oi25].affine_inverse() * occ_box25[oi25]
		print("render proof FP25 occluder %d %s: body-space centre %s size %s" % [oi25, occ_names25[oi25], str(bab25.get_center()), str(bab25.size)])
	var eye_b25: Vector3 = to_body25 * main.fallback_cam.global_position
	var states25: Array = [["rest", main.SUSP_REST], ["full compression", main.SUSP_TRAVEL], ["full droop", 0.0]]
	var rest_vis25: Array[float] = [0.0, 0.0]
	for st25: Array in states25:
		main.susp_c[0] = float(st25[1])
		main.susp_c[1] = float(st25[1])
		main._refresh_car_visuals()
		await physics_frame
		var line25: String = "render proof FP25 tire audit (%s): " % String(st25[0])
		for wi25: int in [0, 1]:
			var d25: Dictionary = _tire_audit_frac(wi25, occ_inv25, occ_box25, occ_names25, to_body25, eye_b25)
			var inpc25: float = 100.0 * float(d25["in"]) / float(d25["n"])
			var vispc25: float = 100.0 * float(d25["vis"]) / float(d25["n"])
			line25 += "%s in-frame %.0f%%, visible %.0f%%   " % ["FL" if wi25 == 0 else "FR", inpc25, vispc25]
			if String(st25[0]) == "rest":
				rest_vis25[wi25] = vispc25
				var bl25: Dictionary = d25["blockers"]
				var bls25: String = ""
				for bk25: String in bl25.keys():
					bls25 += "%s x%d, " % [bk25, int(bl25[bk25])]
				print("render proof FP25 tire audit: %s blockers at rest - %s" % ["FL" if wi25 == 0 else "FR", bls25])
		print(line25)
	check(rest_vis25[0] > 0.0 and rest_vis25[1] > 0.0,
		"FP25 audit: both front tires have a measured visible fraction at rest (FL %.0f%%, FR %.0f%%)" % [rest_vis25[0], rest_vis25[1]])
	main.susp_c[0] = main.SUSP_REST
	main.susp_c[1] = main.SUSP_REST
	main._refresh_car_visuals()

	# Capture 26 (Fix Pass 25): the steering connection's
	# portrait - the Drop Start dangle, a quarter lock dialled
	# in (wheel_angle = PI/4 held by the dangle; FP13's rule
	# keeps it), the gained front-tire display read from the
	# anchor. Structural only under llvmpipe.
	main.start_race()
	var n26: int = 0
	while main.hang_phase != "dangle" and n26 < 4000:
		await physics_frame
		n26 += 1
	check(main.hang_phase == "dangle", "capture 26: dangling for the steering portrait")
	main.wheel_angle = PI * 0.25
	main._refresh_car_visuals()
	var fw26: float = (main.wheel_mis[0] as MeshInstance3D).rotation_degrees.y
	check(fw26 < -10.0,
		"capture 26: a quarter lock displays GAINED on the front tires (%.1f deg; the honest angle is %.1f)" % [fw26, -rad_to_deg(0.25 * main.MAX_LOCK_RAD)])
	await snap(main.fallback_cam, "steer_connection_view.png")

	# Capture 27 (Fix Pass 28): the feature lab's portrait -
	# the approach to PIECE 1: the roadside board ahead on
	# the right, the first drumbeat row beyond it, the 15 m
	# section stripes crossing the road. A portrait only:
	# under the sandbox's llvmpipe renderer this is
	# structure evidence, not colour truth - the board's
	# amber and the stripes' grey are the device's to judge.
	main._set_track("lab")
	main.debug_warp_to_s(64.0)
	for i27: int in 30:
		await physics_frame
	check(main.mode == main.MODE_DRIVE and main.active_track == "lab",
		"capture 27: driving the lab's head flat toward piece 1 (mode=%d)" % main.mode)
	await snap(main.fallback_cam, "lab_drumbeat_view.png")
	main._set_track("circuit")

	print("---")
	if failures == 0:
		print("RENDER PROOF: ALL %d CHECKS PASSED" % checks)
	else:
		print("RENDER PROOF: %d of %d CHECKS FAILED" % [failures, checks])
	quit(1 if failures > 0 else 0)
