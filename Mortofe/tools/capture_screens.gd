extends SceneTree

const WIDTH := 1280
const HEIGHT := 720
const OUTPUT_DIR := "res://captures"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	ProjectSettings.set_setting("mortofe/debug/mobile_controls_preview", true)
	root.size = Vector2i(WIDTH, HEIGHT)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))

	var packed := load("res://main.tscn") as PackedScene
	if packed == null:
		push_error("Could not load main.tscn")
		quit(2)
		return

	var scene := packed.instantiate()
	root.add_child(scene)
	await _wait_frames(16)

	var player = scene.get("player")
	if not is_instance_valid(player):
		push_error("Mortofe capture runner could not find player")
		quit(3)
		return

	await _capture("01_idle.png")

	# Combat composition: place the player beside the first enemy and open the attack window.
	player.global_position = Vector2(745, 575)
	player.velocity = Vector2.ZERO
	player.facing = 1
	player._start_attack()
	player._update_visual()
	await _wait_frames(2)
	await _capture("02_combat.png")

	# Double-jump composition: freeze a real second-jump state in mid-air.
	player.global_position = Vector2(1250, 330)
	player.velocity = Vector2(120, -260)
	player.jumps_used = 2
	player.attack_left = 0.0
	player.set_physics_process(false)
	player._update_visual()
	await _wait_frames(28)
	await _capture("03_double_jump.png")

	# Right-hand locomotion benchmark with one-way platform, slope and moving platform.
	player.global_position = Vector2(2400, 545)
	player.velocity = Vector2.ZERO
	player.jumps_used = 0
	player._update_visual()
	await _wait_frames(36)
	await _capture("04_locomotion_zone.png")

	quit(0)

func _wait_frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _capture(file_name: String) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null or image.is_empty():
		push_error("Empty screenshot: " + file_name)
		quit(4)
		return
	var path := ProjectSettings.globalize_path(OUTPUT_DIR.path_join(file_name))
	var result := image.save_png(path)
	if result != OK:
		push_error("Failed to save screenshot %s: %s" % [file_name, error_string(result)])
		quit(5)
		return
	print("MORTOFE_CAPTURE " + path)
