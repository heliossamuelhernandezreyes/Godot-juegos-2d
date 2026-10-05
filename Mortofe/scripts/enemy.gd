extends CharacterBody2D

signal died

@export var move_speed := 92.0
@export var aggro_distance := 520.0
@export var attack_distance := 58.0
@export var max_health := 3

var target: Node2D
var health := 3
var attack_cooldown_left := 0.0
var hurt_flash_left := 0.0
var facing := -1
var gravity := float(ProjectSettings.get_setting("physics/2d/default_gravity", 980.0))

func _ready() -> void:
	health = max_health
	collision_layer = 4
	collision_mask = 1
	var collision := CollisionShape2D.new()
	var capsule := CapsuleShape2D.new()
	capsule.radius = 17.0
	capsule.height = 50.0
	collision.shape = capsule
	add_child(collision)
	queue_redraw()

func _physics_process(delta: float) -> void:
	attack_cooldown_left = maxf(0.0, attack_cooldown_left - delta)
	hurt_flash_left = maxf(0.0, hurt_flash_left - delta)

	if not is_on_floor():
		velocity.y += gravity * delta

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

	move_and_slide()
	queue_redraw()

func _try_attack(distance: float) -> void:
	if distance > attack_distance or attack_cooldown_left > 0.0:
		return
	attack_cooldown_left = 0.9
	if target.has_method("take_damage"):
		target.take_damage(1, global_position)

func take_damage(amount: int, source_position: Vector2) -> void:
	health -= amount
	hurt_flash_left = 0.12
	var away := signf(global_position.x - source_position.x)
	if away == 0.0:
		away = float(facing)
	velocity = Vector2(away * 250.0, -170.0)
	if health <= 0:
		died.emit()
		queue_free()

func _draw() -> void:
	var dir := float(facing)
	var flash := hurt_flash_left > 0.0
	var robe := Color("c8b7aa") if flash else Color("252027")
	var accent := Color("e2d0b2") if flash else Color("7a302f")
	var iron := Color("b7aa95") if flash else Color("5f5959")

	# Placeholder: a fallen baroque guard/penitent silhouette.
	draw_polygon(PackedVector2Array([
		Vector2(-18.0 * dir, -12),
		Vector2(-24.0 * dir, 26),
		Vector2(0, 31),
		Vector2(22.0 * dir, 24),
		Vector2(17.0 * dir, -11)
	]), PackedColorArray([robe]))
	draw_circle(Vector2(0, -27), 12.0, Color("151318"))
	draw_line(Vector2(-8.0 * dir, -33), Vector2(8.0 * dir, -20), accent, 3.0)
	draw_line(Vector2(11.0 * dir, -2), Vector2(38.0 * dir, 19), iron, 5.0)
	draw_circle(Vector2(40.0 * dir, 21), 7.0, accent)

	# Tiny health marks are intentionally debug-like for the first slice.
	for i in range(max_health):
		var c := accent if i < health else Color("2b292c")
		draw_rect(Rect2(-18 + i * 13, -52, 9, 3), c, true)
