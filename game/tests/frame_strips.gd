extends SceneTree
## Fix Pass 14 frame strips: dense visual proof, rendered
## under Xvfb like the render proof. Two strips, each a
## horizontal composite of captures taken every 2nd-6th
## physics frame from a tracking trackside camera (the
## brief's >= 10 fps density at 90 Hz physics):
## - rebound_strip.png: the circuit gap at 40 m/s - the
##   first flight (sparse, every 6th frame), the contact,
##   and the Item 1 rebound flight (every 2nd frame): the
##   car lands and leaves again instead of sticking.
## - crest_edge_strip.png: stage 37's diagonal step-edge
##   crossing (every 2nd frame) - the leading front corner
##   extends a beat before the trailing one (Item 3).
## Run: xvfb-run -a Godot --path . --script tests/frame_strips.gd

var failures: int = 0
var checks: int = 0
var main: Node
var cam: Camera3D

const TILE_W: int = 220
const TILE_H: int = 138


func check(cond: bool, msg: String) -> void:
	checks += 1
	if cond:
		print("PASS  ", msg)
	else:
		failures += 1
		print("FAIL  ", msg)


func _init() -> void:
	var packed: PackedScene = load("res://main.tscn")
	main = packed.instantiate()
	root.add_child(main)
	_run()


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



func _place_cam(side_sign: float) -> void:
	# Car-anchored tracking position (right-rear quarter,
	# mirrored for the crest strip): world-anchored
	# trackside placements kept losing the car behind the
	# ribbon's own side skirt or behind neighbouring
	# sections where the track folds back on itself. The
	# anchor rides the car's basis, so the flight attitude
	# (Item 7) reads against the road in the rebound strip.
	var ct: Transform3D = main.car.global_transform
	cam.global_position = ct * Vector3(5.2 * side_sign, 2.4, 6.8)
	cam.look_at(ct * Vector3(0.0, 0.3, -6.0), Vector3.UP)


func _grab() -> Image:
	cam.current = true
	await process_frame
	await RenderingServer.frame_post_draw
	var img: Image = root.get_texture().get_image()
	img.convert(Image.FORMAT_RGBA8)
	img.resize(TILE_W, TILE_H, Image.INTERPOLATE_BILINEAR)
	return img


func _save_strip(tiles: Array, out_name: String) -> void:
	var strip := Image.create(TILE_W * tiles.size(), TILE_H, false, Image.FORMAT_RGBA8)
	strip.fill(Color(0.02, 0.02, 0.03, 1.0))
	for ti: int in tiles.size():
		strip.blit_rect(tiles[ti], Rect2i(0, 0, TILE_W, TILE_H), Vector2i(ti * TILE_W, 0))
	var out_path: String = ProjectSettings.globalize_path("res://tests/" + out_name)
	var err: Error = strip.save_png(out_path)
	check(err == OK and tiles.size() >= 10, "strip saved: tests/%s (%d tiles)" % [out_name, tiles.size()])


func _run() -> void:
	await physics_frame
	await physics_frame
	cam = Camera3D.new()
	cam.fov = 55.0
	main.add_child(cam)
	main.jitter_on = true

	# ---- rebound strip: circuit gap at 40 ----
	main._set_track("circuit")
	main.debug_warp_to_s(main.gap_s0 - 55.0)
	main.test_throttle = 0.0
	var tiles: Array = []
	var phase: int = 0
	var tail: int = 0
	var step: int = 0
	for f: int in 3000:
		autopilot_steer(0.0)
		main.debug_pin_speed(40.0)
		await physics_frame
		step += 1
		if phase == 0 and main.mode == main.MODE_AIR:
			phase = 1
		if phase == 1:
			if main.mode == main.MODE_DRIVE:
				phase = 2
			elif step % 6 == 0:
				_place_cam(1.0)
				tiles.append(await _grab())
		if phase == 2:
			if step % 2 == 0:
				_place_cam(1.0)
				tiles.append(await _grab())
		if phase == 2 and main.mode == main.MODE_AIR:
			phase = 3 # rebound flight under way
		if phase == 3:
			if step % 2 == 0:
				_place_cam(1.0)
				tiles.append(await _grab())
			if main.mode == main.MODE_DRIVE:
				phase = 4
		if phase == 4:
			tail += 1
			if step % 2 == 0:
				_place_cam(1.0)
				tiles.append(await _grab())
			if tail >= 24:
				break
	check(phase == 4, "rebound strip: the full flight-contact-rebound-settle sequence was captured (phase %d)" % phase)
	_save_strip(tiles, "rebound_strip.png")

	# ---- crest-edge strip: stage 37's diagonal crossing ----
	main._set_track("ribbon")
	main.debug_warp_to_s(main.stairs_s0 + 6.5)
	main.test_throttle = 0.0
	main.wheel_angle = 0.0
	for i: int in 40:
		main.debug_pin_speed(0.0)
		await physics_frame
	var fy: float = main._frame_yaw(main._frame_at(main.car_s)["tan"])
	main.car_heading = fy + 0.45
	# Front-quarter anchored camera for this strip: a
	# rear anchor swings INTO the ribbon on the staircase's
	# descent pitch (the offset rotates below the road
	# plane), and a fixed trackside camera loses the car
	# behind the steps' skirts; from the front quarter the
	# descent pitch lifts the camera instead, and the
	# extending front corners are the nearest thing in
	# frame.
	var tiles2: Array = []
	for i2: int in 90:
		main.debug_pin_speed(18.0)
		await physics_frame
		if i2 % 2 == 0:
			var ct2: Transform3D = main.car.global_transform
			cam.global_position = ct2 * Vector3(-4.8, 2.2, -7.2)
			cam.look_at(ct2 * Vector3(0.0, 0.2, 2.0), Vector3.UP)
			tiles2.append(await _grab())
	_save_strip(tiles2, "crest_edge_strip.png")

	print("---")
	if failures == 0:
		print("FRAME STRIPS: ALL %d CHECKS PASSED" % checks)
	else:
		print("FRAME STRIPS: %d of %d CHECKS FAILED" % [failures, checks])
	quit()
