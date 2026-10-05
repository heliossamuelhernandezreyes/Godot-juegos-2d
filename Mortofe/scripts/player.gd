extends CharacterBody2D

signal health_changed(value: int)
signal died
signal jumped(stage: int)

const Hitbox2D = preload("res://scripts/combat/hitbox_2d.gd")
const Hurtbox2D = preload("res://scripts/combat/hurtbox_2d.gd")
const PLAYER_ATLAS: Texture2D = preload("res://art/generated/player_atlas.svg")
const PLAYER_PRODUCTION_CANDIDATE_PATH := "res://art/normalized/player/player_idle_prod_v1.png"
const FRAME_SIZE := Vector2(256, 256)
const PRODUCTION_CANDIDATE_MODE := true

@export var move_speed := 285.0
@export var ground_accel := 1900.0
@export var air_accel := 1050.0
@export var friction := 2400.0
@export var jump_velocity := -590.0
@export var double_jump_velocity := -555.0
@export var max_jumps := 2
@export var dash_speed := 760.0
@export var dash_duration := 0.12
@export var dash_cooldown_duration := 0.34

var health := 5
var facing := 1
var jumps_used := 0
var coyote_left := 0.0
var jump_buffer_left := 0.0
var dash_left := 0.0
var dash_cooldown_left := 0.0
var attack_left := 0.0
var invulnerability_left := 0.0
var gravity := float(ProjectSettings.get_setting("physics/2d/default_gravity", 980.0))
var production_candidate_active := false

var attack_hitbox: Area2D
var visual: AnimatedSprite2D

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	_build_collision()
	_build_hurtbox()
	_build_attack_hitbox()
	_build_visual()
	_build_camera()
	queue_redraw()

func _physics_process(delta: float) -> void:
	_update_timers(delta)

	if is_on_floor():
		coyote_left = 0.11
		jumps_used = 0
	else:
		coyote_left = maxf(0.0, coyote_left - delta)
		if coyote_left <= 0.0 and jumps_used == 0:
			jumps_used = 1

	if Input.is_action_just_pressed("jump"):
		jump_buffer_left = 0.12
	else:
		jump_buffer_left = maxf(0.0, jump_buffer_left - delta)

	if Input.is_action_just_pressed("attack") and attack_left <= 0.0:
		_start_attack()

	if Input.is_action_just_pressed("dash") and dash_cooldown_left <= 0.0:
		_start_dash()

	if dash_left > 0.0:
		velocity = Vector2(float(facing) * dash_speed, 0.0)
	else:
		_apply_movement(delta)

	if is_instance_valid(attack_hitbox):
		attack_hitbox.position.x = 44.0 * float(facing)
	move_and_slide()
	_update_visual()
	queue_redraw()

func _apply_movement(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

	var axis := Input.get_axis("move_left", "move_right")
	if absf(axis) > 0.01:
		facing = 1 if axis > 0.0 else -1
		var accel := ground_accel if is_on_floor() else air_accel
		velocity.x = move_toward(velocity.x, axis * move_speed, accel * delta)
	else:
		var decel := friction if is_on_floor() else air_accel * 0.35
		velocity.x = move_toward(velocity.x, 0.0, decel * delta)

	_try_consume_jump_buffer()
	if Input.is_action_just_released("jump") and velocity.y < -180.0:
		velocity.y *= 0.48

func _try_consume_jump_buffer() -> void:
	if jump_buffer_left <= 0.0:
		return
	var can_ground_jump := is_on_floor() or (coyote_left > 0.0 and jumps_used == 0)
	if can_ground_jump:
		_perform_jump(1)
		return
	if not is_on_floor() and jumps_used < max_jumps:
		_perform_jump(jumps_used + 1)

func _perform_jump(stage: int) -> void:
	jumps_used = clampi(stage, 1, max_jumps)
	velocity.y = jump_velocity if jumps_used == 1 else double_jump_velocity
	jump_buffer_left = 0.0
	coyote_left = 0.0
	jumped.emit(jumps_used)

func _start_dash() -> void:
	dash_left = dash_duration
	dash_cooldown_left = dash_cooldown_duration

func _start_attack() -> void:
	attack_left = 0.16
	if is_instance_valid(attack_hitbox):
		attack_hitbox.begin_window()
	get_tree().create_timer(0.11).timeout.connect(_finish_attack_window)

func _finish_attack_window() -> void:
	if is_instance_valid(attack_hitbox):
		attack_hitbox.end_window()

func _update_timers(delta: float) -> void:
	dash_left = maxf(0.0, dash_left - delta)
	dash_cooldown_left = maxf(0.0, dash_cooldown_left - delta)
	attack_left = maxf(0.0, attack_left - delta)
	invulnerability_left = maxf(0.0, invulnerability_left - delta)

func take_damage(amount: int, source_position: Vector2) -> bool:
	if invulnerability_left > 0.0 or dash_left > 0.0:
		return false
	health = maxi(0, health - amount)
	invulnerability_left = 0.55
	var away := signf(global_position.x - source_position.x)
	if away == 0.0:
		away = -float(facing)
	velocity = Vector2(away * 330.0, -260.0)
	health_changed.emit(health)
	if health <= 0:
		died.emit()
		health = 5
		global_position = Vector2(260, 560)
		velocity = Vector2.ZERO
	return true

func _build_collision() -> void:
	var collision := CollisionShape2D.new()
	var capsule := CapsuleShape2D.new()
	capsule.radius = 16.0
	capsule.height = 54.0
	collision.shape = capsule
	add_child(collision)

func _build_hurtbox() -> void:
	var hurtbox := Hurtbox2D.new()
	var capsule := CapsuleShape2D.new()
	capsule.radius = 17.0
	capsule.height = 56.0
	hurtbox.configure(self, 32, capsule)
	add_child(hurtbox)

func _build_attack_hitbox() -> void:
	attack_hitbox = Hitbox2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(82, 58)
	attack_hitbox.configure(self, 1, 64, rect)
	add_child(attack_hitbox)

func _atlas_frame(index: int) -> AtlasTexture:
	var frame := AtlasTexture.new()
	frame.atlas = PLAYER_ATLAS
	var column := index % 4
	var row := floori(index / 4.0)
	frame.region = Rect2(Vector2(column, row) * FRAME_SIZE, FRAME_SIZE)
	return frame

func _add_animation(frames: SpriteFrames, name: StringName, indices: Array[int], fps: float, looped: bool) -> void:
	frames.add_animation(name)
	frames.set_animation_speed(name, fps)
	frames.set_animation_loop(name, looped)
	for index in indices:
		frames.add_frame(name, _atlas_frame(index))

func _add_candidate_animation(frames: SpriteFrames, name: StringName, texture: Texture2D, fps: float, looped: bool) -> void:
	frames.add_animation(name)
	frames.set_animation_speed(name, fps)
	frames.set_animation_loop(name, looped)
	frames.add_frame(name, texture)

func _build_visual() -> void:
	var frames := SpriteFrames.new()
	if frames.has_animation(&"default"):
		frames.remove_animation(&"default")

	var candidate_texture: Texture2D = null
	if PRODUCTION_CANDIDATE_MODE and ResourceLoader.exists(PLAYER_PRODUCTION_CANDIDATE_PATH):
		candidate_texture = load(PLAYER_PRODUCTION_CANDIDATE_PATH) as Texture2D
	production_candidate_active = candidate_texture != null

	if production_candidate_active:
		# Production gate v1 intentionally reuses one normalized frame across states.
		# This validates silhouette, gameplay scale, pivot/baseline, HUD overlap and
		# movement/camera integration before animation production is expanded.
		_add_candidate_animation(frames, &"idle", candidate_texture, 1.0, true)
		_add_candidate_animation(frames, &"run", candidate_texture, 1.0, true)
		_add_candidate_animation(frames, &"jump", candidate_texture, 1.0, false)
		_add_candidate_animation(frames, &"attack", candidate_texture, 1.0, false)
		_add_candidate_animation(frames, &"hurt", candidate_texture, 1.0, false)
	else:
		_add_animation(frames, &"idle", [0, 1], 2.4, true)
		_add_animation(frames, &"run", [2, 3, 4, 5], 9.5, true)
		_add_animation(frames, &"jump", [6, 7, 8], 8.0, false)
		_add_animation(frames, &"attack", [9, 10], 12.5, false)
		_add_animation(frames, &"hurt", [11], 1.0, false)

	visual = AnimatedSprite2D.new()
	visual.sprite_frames = frames
	visual.animation = &"idle"
	if production_candidate_active:
		# Normalized asset: 384x384, baseline y=350, center y=192.
		# (350 - 192) * 0.5 = 79 px, so this keeps the visual feet on body origin.
		# 300 px visual height * 0.5 = 150 px ~= 20.8% of the 720p design height.
		visual.position = Vector2(0, -79)
		visual.scale = Vector2(0.5, 0.5)
	else:
		visual.position = Vector2(0, -39)
		visual.scale = Vector2(0.62, 0.62)
	visual.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	visual.z_index = 2
	visual.play()
	add_child(visual)

func _update_visual() -> void:
	if not is_instance_valid(visual):
		return
	var next_animation: StringName = &"idle"
	if invulnerability_left > 0.38:
		next_animation = &"hurt"
	elif attack_left > 0.0:
		next_animation = &"attack"
	elif not is_on_floor():
		next_animation = &"jump"
	elif absf(velocity.x) > 24.0:
		next_animation = &"run"
	if visual.animation != next_animation:
		visual.play(next_animation)
	visual.flip_h = facing < 0
	visual.modulate = Color(1.0, 0.86, 0.86) if invulnerability_left > 0.0 and int(invulnerability_left * 24.0) % 2 == 0 else Color.WHITE

func _build_camera() -> void:
	var camera := Camera2D.new()
	camera.position = Vector2(0, -74)
	camera.zoom = Vector2(1.14, 1.14)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 7.5
	camera.limit_left = -900
	camera.limit_right = 3250
	camera.limit_top = -300
	camera.limit_bottom = 760
	add_child(camera)

func _draw() -> void:
	if jumps_used >= 2 and not is_on_floor():
		draw_arc(Vector2(0, 24), 30.0, 0.0, TAU, 30, Color(0.83, 0.58, 0.25, 0.48), 3.0)
	if attack_left > 0.0:
		var dir := float(facing)
		draw_arc(Vector2(22.0 * dir, -7), 72.0, -0.65 if facing > 0 else PI - 0.65, 0.55 if facing > 0 else PI + 0.55, 20, Color(0.84, 0.22, 0.17, 0.42), 5.0)