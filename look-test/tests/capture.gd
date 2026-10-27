extends SceneTree
## Render captures for the look test (needs a real frame - run
## under Xvfb, NOT --headless):
##   xvfb-run -a -s "-screen 0 1280x800x24" \
##     Godot --path . --script tests/capture.gd [-- --lt-lite]
## Saves tests/cockpit_view.png (the eye anchor), tests/
## external_view.png (three-quarter of the car on the ribbon),
## tests/vista_view.png (climb + banked curve + desert + horizon),
## and prints the frame cost (nodes / objects / draw calls /
## primitives) from the Performance monitors.
## --lt-lite is forwarded to main.gd (drops SSAO/SSIL/volumetric
## fog) for software-Vulkan runs; a real GPU runs it full.

var failures: int = 0


func check(cond: bool, stage: String) -> void:
	if cond:
		print("PASS  ", stage)
	else:
		failures += 1
		print("FAIL  ", stage)


func snap(cam: Camera3D, out_name: String, settle: int = 40) -> void:
	cam.current = true
	for i: int in settle:
		await process_frame
	await RenderingServer.frame_post_draw
	var img: Image = root.get_texture().get_image()
	var out_path: String = ProjectSettings.globalize_path("res://tests/" + out_name)
	var err: Error = img.save_png(out_path)
	check(err == OK, "screenshot saved: tests/" + out_name)
	var distinct: Dictionary = {}
	for x: int in range(0, img.get_width(), 6):
		for y: int in range(0, img.get_height(), 6):
			distinct[img.get_pixel(x, y).to_rgba32()] = true
	check(distinct.size() > 200, "frame is a real lit scene (%d sampled colors in %s)" % [distinct.size(), out_name])
	print("CAPTURE ", out_name, " distinct=", distinct.size())


func _init() -> void:
	_run()


func _run() -> void:
	root.size = Vector2i(1280, 800)
	var ps: PackedScene = load("res://main.tscn")
	var main: Node = ps.instantiate()
	root.add_child(main)
	for i: int in 30:
		await process_frame
	check(not bool(main.get("xr_active")), "capture runs on the desktop fallback path")

	# 1: the cockpit, exactly at the game's eye anchor.
	var fb: Camera3D = main.get("fallback_cam")
	fb.rotation = Vector3.ZERO
	await snap(fb, "cockpit_view.png")

	# 2: external three-quarter - ahead and to the right of the
	# car, looking back at it on the ribbon.
	var home: Transform3D = main.get("car_home")
	var cam2 := Camera3D.new()
	cam2.far = 4000.0
	main.add_child(cam2)
	cam2.fov = 55.0
	cam2.position = home * Vector3(3.4, 1.15, -4.1)
	cam2.look_at(home.origin + Vector3(0.0, 0.55, 0.0), Vector3.UP)
	await snap(cam2, "external_view.png")
	cam2.queue_free()

	# 3: the wide vista - from off the climb, across the banked
	# curve, desert floor and mesas below, hills at the horizon.
	var f120: Dictionary = main.call("frame_at", 118.0)
	var f250: Dictionary = main.call("frame_at", 250.0)
	var p120: Vector3 = f120["pos"]
	var sd120: Vector3 = f120["side"]
	var cam3 := Camera3D.new()
	cam3.far = 6000.0
	main.add_child(cam3)
	cam3.position = p120 + sd120 * 34.0 + Vector3(0.0, 15.0, 0.0)
	cam3.look_at((f250["pos"] as Vector3) + Vector3(0.0, -2.0, 0.0), Vector3.UP)
	await snap(cam3, "vista_view.png", 60)

	# Frame cost on the heaviest view, monitors settled.
	var perf_line: String = "PERF nodes=%d objects=%d draw_calls=%d prims=%d" % [
		main.call("_count_nodes", main),
		int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)),
		int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
		int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))]
	print(perf_line)

	print("---")
	if failures == 0:
		print("CAPTURE: ALL CHECKS PASSED")
	else:
		print("CAPTURE: %d CHECKS FAILED" % failures)
	# stdout buffering can eat the tail prints on quit; the
	# summary also lands in a file so a run's verdict survives.
	var sf := FileAccess.open("res://tests/last_run_summary.txt", FileAccess.WRITE)
	sf.store_line(perf_line)
	sf.store_line("failures=%d" % failures)
	sf.close()
	quit(1 if failures > 0 else 0)
