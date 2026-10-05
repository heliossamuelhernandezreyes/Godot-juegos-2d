extends SceneTree

const WIDTH := 1280
const HEIGHT := 720
const OUTPUT_DIR := "res://captures"
const PLAYER_PRODUCTION_CANDIDATE_PATH := "res://art/normalized/player/player_idle_prod_v1.png"

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
	if not player.production_candidate_active:
		push_error("Production player candidate was not prepared/imported")
		quit(6)
		return

	await _capture("01_idle.png")

	player.global_position = Vector2(745, 575)
	player.velocity = Vector2.ZERO
	player.facing = 1
	player._start_attack()
	player._update_visual()
	await _wait_frames(2)
	await _capture("02_combat.png")

	player.global_position = Vector2(1250, 330)
	player.velocity = Vector2(120, -260)
	player.jumps_used = 2
	player.attack_left = 0.0
	player.set_physics_process(false)
	player._update_visual()
	await _wait_frames(28)
	await _capture("03_double_jump.png")

	player.global_position = Vector2(2400, 545)
	player.velocity = Vector2.ZERO
	player.jumps_used = 0
	player._update_visual()
	await _wait_frames(36)
	await _capture("04_locomotion_zone.png")

	scene.queue_free()
	await _wait_frames(2)
	var gate := _build_player_value_gate()
	root.add_child(gate)
	await _wait_frames(3)
	await _capture("05_player_value_gate.png")

	quit(0)

func _build_player_value_gate() -> Node2D:
	var gate := Node2D.new()
	gate.name = "PlayerValueGate"
	var candidate := load(PLAYER_PRODUCTION_CANDIDATE_PATH) as Texture2D
	if candidate == null:
		push_error("Could not load production candidate for value gate")
		return gate

	var band_width := float(WIDTH) / 3.0
	var colors := [Color("11141d"), Color("565257"), Color("80604b")]
	var labels := ["DARK / COLD", "MID / STONE", "WARM / EARTH"]
	var floor_y := 560.0

	for i in range(3):
		var left := band_width * i
		var right := band_width * (i + 1)
		var band := Polygon2D.new()
		band.polygon = PackedVector2Array([
			Vector2(left, 0), Vector2(right, 0),
			Vector2(right, HEIGHT), Vector2(left, HEIGHT),
		])
		band.color = colors[i]
		band.z_index = -10
		gate.add_child(band)

		var floor_line := Line2D.new()
		floor_line.points = PackedVector2Array([
			Vector2(left + 24.0, floor_y), Vector2(right - 24.0, floor_y),
		])
		floor_line.width = 2.0
		floor_line.default_color = Color(1.0, 1.0, 1.0, 0.34)
		gate.add_child(floor_line)

		var sprite := Sprite2D.new()
		sprite.texture = candidate
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		sprite.scale = Vector2(0.5, 0.5)
		# Normalized center y=192, feet y=350: (350 - 192) * 0.5 = 79 px.
		sprite.position = Vector2(left + band_width * 0.5, floor_y - 79.0)
		sprite.z_index = 2
		gate.add_child(sprite)

		var caption := Label.new()
		caption.text = labels[i]
		caption.position = Vector2(left + 24.0, 34.0)
		caption.add_theme_font_size_override("font_size", 18)
		caption.modulate = Color(1.0, 1.0, 1.0, 0.82)
		caption.z_index = 4
		gate.add_child(caption)

	var title := Label.new()
	title.text = "MORTOFE — PLAYER PRODUCTION GATE V1 — 150 px visible height / 720p"
	title.position = Vector2(24.0, HEIGHT - 48.0)
	title.add_theme_font_size_override("font_size", 16)
	title.modulate = Color(1.0, 1.0, 1.0, 0.72)
	title.z_index = 4
	gate.add_child(title)
	return gate

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
