extends CharacterBody2D

signal health_changed(value: int)
signal died

const Hitbox2D = preload("res://scripts/combat/hitbox_2d.gd")
const Hurtbox2D = preload("res://scripts/combat/hurtbox_2d.gd")

@export var move_speed := 285.0
@export var ground_accel := 1900.0
@export var air_accel := 1050.0
@export var friction := 2400.0
@export var jump_velocity := -590.0
@export var dash_speed := 760.0
@export var dash_duration := 0.12
@export var dash_cooldown_duration := 0.34

var health := 5
var facing := 1
var coyote_left := 0.0
var jump_buffer_left := 0.0
var dash_left := 0.0
var dash_cooldown_left := 0.0
var attack_left := 0.0
var invulnerability_left := 0.0
var gravity := float(ProjectSettings.get_setting("physics/2d/default_gravity", 980.0))

var attack_hitbox: Area2D

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	_build_collision()
	_build_hurtbox()
	_build_attack_hitbox()
	_build_camera()
	queue_redraw()

func _physics_process(delta: float) -> void:
	_update_timers(delta)

	if is_on_floor():
		coyote_left = 0.11
	else:
		coyote_left = maxf(0.0, coyote_left - delta)

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

	if jump_buffer_left > 0.0 and coyote_left > 0.0:
		velocity.y = jump_velocity
		jump_buffer_left = 0.0
		coyote_left = 0.0

	if Input.is_action_just_released("jump") and velocity.y < -180.0:
		velocity.y *= 0.48

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

func take_damage(amount: int, source_position: Vector2) -> void:
	if invulnerability_left > 0.0 or dash_left > 0.0:
		return
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
	rect.size = Vector2(72, 54)
	attack_hitbox.configure(self, 1, 64, rect)
	add_child(attack_hitbox)

func _build_camera() -> void:
	var camera := Camera2D.new()
	camera.position = Vector2(0, -70)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 7.5
	camera.limit_left = -900
	camera.limit_right = 3250
	camera.limit_top = -300
	camera.limit_bottom = 760
	add_child(camera)

func _draw() -> void:
	var dir := float(facing)
	var flash := invulnerability_left > 0.0 and int(invulnerability_left * 20.0) % 2 == 0
	var cloth := Color("c9bcc0") if flash else Color("4e1820")
	var metal := Color("d0b98f") if flash else Color("756351")

	# Dark baroque placeholder silhouette. Final sprite art replaces this later.
	draw_polygon(PackedVector2Array([
		Vector2(-17.0 * dir, -14),
		Vector2(-26.0 * dir, 28),
		Vector2(0, 23),
		Vector2(25.0 * dir, 30),
		Vector2(16.0 * dir, -13)
	]), PackedColorArray([cloth]))
	draw_circle(Vector2(0, -28), 13.0, Color("1a171b"))
	draw_arc(Vector2(0, -28), 14.5, PI, TAU, 14, metal, 3.0)
	draw_line(Vector2(8.0 * dir, -5), Vector2(28.0 * dir, 22), metal, 5.0)

	if attack_left > 0.0:
		draw_line(Vector2(16.0 * dir, -4), Vector2(73.0 * dir, -22), Color("d8c9ad"), 5.0)
		draw_arc(Vector2(19.0 * dir, -3), 60.0, -0.65 if facing > 0 else PI - 0.65, 0.55 if facing > 0 else PI + 0.55, 18, Color(0.75, 0.18, 0.16, 0.65), 4.0)
	else:
		draw_line(Vector2(16.0 * dir, 7), Vector2(42.0 * dir, 35), Color("bfb39d"), 4.0)
