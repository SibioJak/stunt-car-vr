extends SceneTree

## Rendered-frame proof (needs a real GL frame - run under Xvfb, NOT
## --headless):
##   xvfb-run -a -s "-screen 0 1280x800x24" \
##     Godot --path . --script tests/render_proof.gd
## Capture 1: cockpit close-up at the Drop Start dangle - grab wheel,
## dash switches, state label, controls panel, nose and the track ahead.
## Capture 2: the drone lift - car dangling on 4 lines under the drone.
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

	# Capture 1: cockpit from just behind/right of the driver, mid-swing.
	var cam1 := Camera3D.new()
	main.car.add_child(cam1)
	cam1.position = Vector3(0.48, 1.78, 1.38)
	cam1.look_at(main.car.global_transform * Vector3(0.24, 0.88, -0.60), Vector3.UP)
	await snap(cam1, "cockpit_view.png")
	cam1.queue_free()

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
	for i3: int in 40:
		await physics_frame
	check(main.line_mis[0].visible, "lift lines visible during the dangle")
	var cam2 := Camera3D.new()
	main.add_child(cam2)
	var car_pos: Vector3 = main.car.global_position
	cam2.position = car_pos + Vector3(6.0, 2.6, 6.0)
	cam2.look_at(car_pos + Vector3(0, 1.6, 0), Vector3.UP)
	await snap(cam2, "lift_view.png")

	print("---")
	if failures == 0:
		print("RENDER PROOF: ALL %d CHECKS PASSED" % checks)
	else:
		print("RENDER PROOF: %d of %d CHECKS FAILED" % [failures, checks])
	quit(1 if failures > 0 else 0)
