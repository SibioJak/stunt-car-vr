extends SceneTree

## Frame discipline probe: node count + draw calls in a real GL frame.
##   xvfb-run -a Godot --path . --script tests/frame_stats.gd

func _init() -> void:
	_run()


func _run() -> void:
	root.size = Vector2i(1280, 800)
	var ps: PackedScene = load("res://main.tscn")
	var main: Node = ps.instantiate()
	root.add_child(main)
	for i: int in 30:
		await physics_frame
	for j: int in 5:
		await process_frame
	await RenderingServer.frame_post_draw
	print("NODES: ", root.get_tree().get_node_count())
	print("DRAW CALLS (frame): ", RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME))
	print("PRIMITIVES (frame): ", RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME))
	quit(0)
