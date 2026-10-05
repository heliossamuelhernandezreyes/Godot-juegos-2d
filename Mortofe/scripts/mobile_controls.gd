extends Control

## Mobile-first virtual controls for Mortofe.
## Uses raw multitouch and feeds the same InputMap actions as keyboard/gamepad.

const JOYSTICK_RADIUS := 92.0
const BUTTON_RADIUS := 58.0
const DEADZONE := 0.18

var controls_active := false
var safe_rect := Rect2()
var joystick_center := Vector2.ZERO
var joystick_vector := Vector2.ZERO
var joystick_finger := -1
var action_fingers: Dictionary = {}
var attack_center := Vector2.ZERO
var jump_center := Vector2.ZERO
var dash_center := Vector2.ZERO

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	controls_active = _should_enable_controls()
	visible = controls_active
	set_process_input(controls_active)
	get_viewport().size_changed.connect(_refresh_layout)
	_refresh_layout()

func _should_enable_controls() -> bool:
	var os_name := OS.get_name()
	return os_name == "Android" or os_name == "iOS" or bool(ProjectSettings.get_setting("mortofe/debug/mobile_controls_preview", false))

func _refresh_layout() -> void:
	position = Vector2.ZERO
	size = get_viewport_rect().size
	safe_rect = _viewport_safe_rect()
	var bottom := safe_rect.position.y + safe_rect.size.y
	var right := safe_rect.position.x + safe_rect.size.x
	joystick_center = Vector2(safe_rect.position.x + 145.0, bottom - 135.0)
	attack_center = Vector2(right - 100.0, bottom - 118.0)
	jump_center = Vector2(right - 235.0, bottom - 105.0)
	dash_center = Vector2(right - 155.0, bottom - 235.0)
	queue_redraw()

func _viewport_safe_rect() -> Rect2:
	var viewport_size := get_viewport_rect().size
	var result := Rect2(Vector2.ZERO, viewport_size)
	if OS.get_name() != "Android" and OS.get_name() != "iOS":
		return result

	var physical_size := DisplayServer.screen_get_size()
	var physical_safe := DisplayServer.get_display_safe_area()
	if physical_size.x <= 0 or physical_size.y <= 0 or physical_safe.size.x <= 0 or physical_safe.size.y <= 0:
		return result

	var scale := Vector2(
		viewport_size.x / float(physical_size.x),
		viewport_size.y / float(physical_size.y)
	)
	return Rect2(
		Vector2(physical_safe.position) * scale,
		Vector2(physical_safe.size) * scale
	)

func _input(event: InputEvent) -> void:
	if not controls_active:
		return

	if event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_drag(event)

func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		if joystick_finger < 0 and _is_joystick_zone(event.position):
			joystick_finger = event.index
			_update_joystick(event.position)
			get_viewport().set_input_as_handled()
			return

		var action := _button_action_at(event.position)
		if action != StringName():
			action_fingers[event.index] = action
			Input.action_press(action)
			queue_redraw()
			get_viewport().set_input_as_handled()
	else:
		if event.index == joystick_finger:
			_release_joystick()
			get_viewport().set_input_as_handled()
			return
		if action_fingers.has(event.index):
			var action: StringName = action_fingers[event.index]
			Input.action_release(action)
			action_fingers.erase(event.index)
			queue_redraw()
			get_viewport().set_input_as_handled()

func _handle_drag(event: InputEventScreenDrag) -> void:
	if event.index == joystick_finger:
		_update_joystick(event.position)
		get_viewport().set_input_as_handled()

func _is_joystick_zone(point: Vector2) -> bool:
	var left_limit := safe_rect.position.x + safe_rect.size.x * 0.48
	var top_limit := safe_rect.position.y + safe_rect.size.y * 0.38
	return point.x <= left_limit and point.y >= top_limit

func _button_action_at(point: Vector2) -> StringName:
	if point.distance_to(attack_center) <= BUTTON_RADIUS * 1.35:
		return &"attack"
	if point.distance_to(jump_center) <= BUTTON_RADIUS * 1.35:
		return &"jump"
	if point.distance_to(dash_center) <= BUTTON_RADIUS * 1.35:
		return &"dash"
	return StringName()

func _update_joystick(point: Vector2) -> void:
	var delta := point - joystick_center
	if delta.length() > JOYSTICK_RADIUS:
		delta = delta.normalized() * JOYSTICK_RADIUS
	joystick_vector = delta / JOYSTICK_RADIUS

	Input.action_release(&"move_left")
	Input.action_release(&"move_right")
	if joystick_vector.x < -DEADZONE:
		Input.action_press(&"move_left", absf(joystick_vector.x))
	elif joystick_vector.x > DEADZONE:
		Input.action_press(&"move_right", absf(joystick_vector.x))
	queue_redraw()

func _release_joystick() -> void:
	joystick_finger = -1
	joystick_vector = Vector2.ZERO
	Input.action_release(&"move_left")
	Input.action_release(&"move_right")
	queue_redraw()

func _exit_tree() -> void:
	_release_joystick()
	for action in action_fingers.values():
		Input.action_release(action)
	action_fingers.clear()

func _draw() -> void:
	if not controls_active:
		return

	var rim := Color(0.78, 0.70, 0.60, 0.28)
	var fill := Color(0.08, 0.06, 0.08, 0.42)
	var active := Color(0.50, 0.12, 0.14, 0.58)

	# Joystick.
	draw_circle(joystick_center, JOYSTICK_RADIUS, fill)
	draw_arc(joystick_center, JOYSTICK_RADIUS, 0.0, TAU, 48, rim, 3.0)
	draw_circle(joystick_center + joystick_vector * JOYSTICK_RADIUS, 38.0, Color(0.72, 0.65, 0.56, 0.42))

	_draw_action_button(attack_center, active if _action_is_held(&"attack") else fill, rim, 0)
	_draw_action_button(jump_center, active if _action_is_held(&"jump") else fill, rim, 1)
	_draw_action_button(dash_center, active if _action_is_held(&"dash") else fill, rim, 2)

func _action_is_held(action: StringName) -> bool:
	return action in action_fingers.values()

func _draw_action_button(center: Vector2, fill: Color, rim: Color, glyph: int) -> void:
	draw_circle(center, BUTTON_RADIUS, fill)
	draw_arc(center, BUTTON_RADIUS, 0.0, TAU, 36, rim, 3.0)
	match glyph:
		0:
			# Attack: crossed blade motif.
			draw_line(center + Vector2(-22, 20), center + Vector2(22, -22), Color("d8c9ad"), 6.0)
			draw_line(center + Vector2(-8, -18), center + Vector2(19, 11), Color("9f2530"), 5.0)
		1:
			# Jump: upward chevron.
			draw_polyline(PackedVector2Array([center + Vector2(-22, 12), center + Vector2(0, -16), center + Vector2(22, 12)]), Color("d8c9ad"), 6.0)
		2:
			# Dash: double forward chevron.
			draw_polyline(PackedVector2Array([center + Vector2(-24, -16), center + Vector2(-5, 0), center + Vector2(-24, 16)]), Color("d8c9ad"), 5.0)
			draw_polyline(PackedVector2Array([center + Vector2(0, -16), center + Vector2(19, 0), center + Vector2(0, 16)]), Color("d8c9ad"), 5.0)
