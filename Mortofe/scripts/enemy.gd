extends CharacterBody2D

signal died
signal damaged(amount: int, remaining_health: int, world_position: Vector2)

const Hitbox2D = preload("res://scripts/combat/hitbox_2d.gd")
const Hurtbox2D = preload("res://scripts/combat/hurtbox_2d.gd")
const ENEMY_IDLE = preload("res://art/characters/enemy/enemy_idle.svg")
const ENEMY_ATTACK = preload("res://art/characters/enemy/enemy_attack.svg")
const ENEMY_HURT = preload("res://art/characters/enemy/enemy_hurt.svg")

@export var move_speed := 92.0
@export var aggro_distance := 520.0
@export var attack_distance := 58.0
@export var max_health := 3

var target: Node2D
var health := 3
var attack_cooldown_left := 0.0
var attack_window_left := 0.0
var hurt_flash_left := 0.0
var hit_stun_left := 0.0
var facing := -1
var gravity := float(ProjectSettings.get_setting("physics/2d/default_gravity", 980.0))
var attack_hitbox: Area2D
var visual: Sprite2D

func _ready() -> void:
	health = max_health
	collision_layer = 4
	collision_mask = 1
	_build_collision()
	_build_hurtbox()
	_build_attack_hitbox()
	_build_visual()
	queue_redraw()

func _physics_process(delta: float) -> void:
	attack_cooldown_left = maxf(0.0, attack_cooldown_left - delta)
	attack_window_left = maxf(0.0, attack_window_left - delta)
	hurt_flash_left = maxf(0.0, hurt_flash_left - delta)
	hit_stun_left = maxf(0.0, hit_stun_left - delta)

	if not is_on_floor():
		velocity.y += gravity * delta

	if hit_stun_left > 0.0:
		velocity.x = move_toward(velocity.x, 0.0, 420.0 * delta)
	else:
		_update_ai(delta)

	if is_instance_valid(attack_hitbox):
		attack_hitbox.position.x = 36.0 * float(facing)
	move_and_slide()
	_update_visual()
	queue_redraw()

func _update_ai(delta: float) -> void:
	if is_instance_valid(target):
		var dx := target.global_position.x - global_position.x
		var distance := absf(dx)
		if distance <= aggro_distance:
			facing = 1 if dx > 0.0 else -1
			if distance > attack_distance:
				velocity.x = move_toward(velocity.x, float(facing) * move_speed, 620.0 * delta)
			else:
				velocity.x = move_toward(velocity.x, 0.0, 1100.0 * delta)
				_try_attack(distance)
		else:
			velocity.x = move_toward(velocity.x, 0.0, 700.0 * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 700.0 * delta)

func _try_attack(distance: float) -> void:
	if distance > attack_distance or attack_cooldown_left > 0.0:
		return
	attack_cooldown_left = 0.9
	attack_window_left = 0.14
	if is_instance_valid(attack_hitbox):
		attack_hitbox.begin_window()
	get_tree().create_timer(0.14).timeout.connect(_finish_attack_window)

func _finish_attack_window() -> void:
	if is_instance_valid(attack_hitbox):
		attack_hitbox.end_window()

func take_damage(amount: int, source_position: Vector2) -> bool:
	if amount <= 0 or health <= 0:
		return false
	health = maxi(0, health - amount)
	hurt_flash_left = 0.18
	hit_stun_left = 0.14
	attack_window_left = 0.0
	if is_instance_valid(attack_hitbox):
		attack_hitbox.end_window()
	var away := signf(global_position.x - source_position.x)
	if away == 0.0:
		away = float(facing)
	velocity = Vector2(away * 285.0, -190.0)
	damaged.emit(amount, health, global_position)
	queue_redraw()
	if health <= 0:
		died.emit()
		queue_free()
	return true

func _build_collision() -> void:
	var collision := CollisionShape2D.new()
	var capsule := CapsuleShape2D.new()
	capsule.radius = 17.0
	capsule.height = 50.0
	collision.shape = capsule
	add_child(collision)

func _build_hurtbox() -> void:
	var hurtbox := Hurtbox2D.new()
	var capsule := CapsuleShape2D.new()
	capsule.radius = 18.0
	capsule.height = 52.0
	hurtbox.configure(self, 64, capsule)
	add_child(hurtbox)

func _build_attack_hitbox() -> void:
	attack_hitbox = Hitbox2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(58, 46)
	attack_hitbox.configure(self, 1, 32, rect)
	add_child(attack_hitbox)

func _build_visual() -> void:
	visual = Sprite2D.new()
	visual.texture = ENEMY_IDLE
	visual.position = Vector2(0, -20)
	visual.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	visual.z_index = 2
	add_child(visual)

func _update_visual() -> void:
	if not is_instance_valid(visual):
		return
	var next_texture: Texture2D = ENEMY_IDLE
	var attack_offset := 0.0
	if hurt_flash_left > 0.0:
		next_texture = ENEMY_HURT
	elif attack_window_left > 0.0:
		next_texture = ENEMY_ATTACK
		attack_offset = 16.0 * float(facing)
	visual.texture = next_texture
	visual.flip_h = facing < 0
	visual.position = Vector2(attack_offset, -20)

func _draw() -> void:
	# Health pips remain as gameplay feedback even after sprite integration.
	for i in range(max_health):
		var c := Color("a74749") if i < health else Color("2b292c")
		draw_rect(Rect2(-18 + i * 13, -58, 9, 3), c, true)
