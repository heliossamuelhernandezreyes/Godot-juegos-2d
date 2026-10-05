extends Node2D

const PlayerController = preload("res://scripts/player.gd")
const EnemyController = preload("res://scripts/enemy.gd")
const MobileControls = preload("res://scripts/mobile_controls.gd")
const MobileTelemetry = preload("res://scripts/mobile_telemetry.gd")

var player: CharacterBody2D
var hud_status: Label
var enemy_count := 0
var mobile_controls: Control

func _ready() -> void:
	_install_input_map()
	_build_collision_world()
	_build_hud()
	_spawn_player()
	_spawn_enemy(Vector2(820, 570))
	_spawn_enemy(Vector2(1320, 570))
	_spawn_enemy(Vector2(1770, 410))
	_build_mobile_runtime()
	queue_redraw()

func _process(_delta: float) -> void:
	if is_instance_valid(player):
		if player.global_position.y > 900.0:
			player.global_position = Vector2(260, 560)
			player.velocity = Vector2.ZERO
		if is_instance_valid(hud_status):
			var controls_line := "CONTROLES TÁCTILES ACTIVOS" if is_instance_valid(mobile_controls) and mobile_controls.controls_active else "A/D mover · ESPACIO saltar · SHIFT dash · J / clic atacar"
			hud_status.text = "MORTOFE  //  PRE-ALPHA MOBILE\nHP %d   //   ENEMIGOS %d\n%s" % [player.health, enemy_count, controls_line]

func _draw() -> void:
	# Placeholder visual deliberately code-driven: it tests gameplay before final art lands.
	draw_rect(Rect2(-1200, -700, 5200, 1900), Color("09080b"), true)
	draw_circle(Vector2(1040, 120), 118.0, Color("b7aa92"))
	draw_circle(Vector2(1085, 95), 116.0, Color("09080b"))

	# Distant baroque silhouettes.
	for x in range(-400, 3000, 260):
		var h := 180.0 + float((x / 20) % 7) * 24.0
		draw_rect(Rect2(x, 650.0 - h, 150, h), Color("131117"), true)
		draw_polygon(PackedVector2Array([
			Vector2(x - 18, 650.0 - h),
			Vector2(x + 75, 650.0 - h - 115),
			Vector2(x + 168, 650.0 - h)
		]), PackedColorArray([Color("17131a")]))
		for wy in range(int(650.0 - h + 42.0), 620, 56):
			draw_rect(Rect2(x + 62, wy, 24, 30), Color("5e3726"), true)

	# Ground and playable platforms.
	draw_rect(Rect2(-1000, 650, 4300, 170), Color("1d181d"), true)
	draw_line(Vector2(-1000, 650), Vector2(3300, 650), Color("77604a"), 4.0)
	_draw_platform(Rect2(510, 525, 250, 24))
	_draw_platform(Rect2(1040, 470, 230, 24))
	_draw_platform(Rect2(1580, 490, 310, 24))
	_draw_platform(Rect2(1730, 440, 210, 24))

	# Foreground columns hint at the intended monumental/baroque scale.
	for x in [80.0, 1480.0, 2260.0]:
		draw_rect(Rect2(x, 220, 54, 430), Color("242027"), true)
		draw_rect(Rect2(x - 20, 205, 94, 20), Color("3a3132"), true)
		draw_rect(Rect2(x - 24, 630, 102, 20), Color("3a3132"), true)

func _draw_platform(rect: Rect2) -> void:
	draw_rect(rect, Color("2b252a"), true)
	draw_line(rect.position, rect.position + Vector2(rect.size.x, 0), Color("83684e"), 3.0)

func _build_collision_world() -> void:
	_add_static_rect(Vector2(1150, 735), Vector2(4300, 170))
	_add_static_rect(Vector2(635, 537), Vector2(250, 24))
	_add_static_rect(Vector2(1155, 482), Vector2(230, 24))
	_add_static_rect(Vector2(1735, 502), Vector2(310, 24))
	_add_static_rect(Vector2(1835, 452), Vector2(210, 24))

func _add_static_rect(pos: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.position = pos
	body.collision_layer = 1
	body.collision_mask = 0
	var shape_node := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	shape_node.shape = shape
	body.add_child(shape_node)
	add_child(body)

func _spawn_player() -> void:
	player = PlayerController.new()
	player.position = Vector2(260, 560)
	add_child(player)

func _spawn_enemy(pos: Vector2) -> void:
	var enemy := EnemyController.new()
	enemy.position = pos
	enemy.target = player
	enemy.died.connect(_on_enemy_died)
	add_child(enemy)
	enemy_count += 1

func _on_enemy_died() -> void:
	enemy_count = maxi(0, enemy_count - 1)

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	var panel := ColorRect.new()
	panel.position = Vector2(20, 18)
	panel.size = Vector2(500, 86)
	panel.color = Color(0.025, 0.02, 0.03, 0.82)
	layer.add_child(panel)
	hud_status = Label.new()
	hud_status.position = Vector2(34, 28)
	hud_status.add_theme_font_size_override("font_size", 18)
	hud_status.add_theme_color_override("font_color", Color("d2c3ad"))
	layer.add_child(hud_status)

func _build_mobile_runtime() -> void:
	var telemetry := MobileTelemetry.new()
	telemetry.name = "MobileTelemetry"
	add_child(telemetry)

	var controls_layer := CanvasLayer.new()
	controls_layer.name = "MobileControlsLayer"
	controls_layer.layer = 20
	add_child(controls_layer)
	mobile_controls = MobileControls.new()
	mobile_controls.name = "MobileControls"
	controls_layer.add_child(mobile_controls)

func _install_input_map() -> void:
	_ensure_action("move_left", [KEY_A, KEY_LEFT])
	_ensure_action("move_right", [KEY_D, KEY_RIGHT])
	_ensure_action("jump", [KEY_SPACE])
	_ensure_action("dash", [KEY_SHIFT, KEY_K])
	_ensure_action("attack", [KEY_J])
	if not _action_has_mouse_button("attack", MOUSE_BUTTON_LEFT):
		var mouse := InputEventMouseButton.new()
		mouse.button_index = MOUSE_BUTTON_LEFT
		InputMap.action_add_event("attack", mouse)

func _ensure_action(action: StringName, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for keycode in keys:
		if not _action_has_key(action, keycode):
			var event := InputEventKey.new()
			event.physical_keycode = keycode
			InputMap.action_add_event(action, event)

func _action_has_key(action: StringName, keycode: Key) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey and event.physical_keycode == keycode:
			return true
	return false

func _action_has_mouse_button(action: StringName, button: MouseButton) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventMouseButton and event.button_index == button:
			return true
	return false
