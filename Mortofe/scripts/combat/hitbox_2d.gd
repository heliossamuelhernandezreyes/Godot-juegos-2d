extends Area2D

## Reusable combat hitbox. Gameplay actors own attack timing; this component owns
## target detection and damage payload delivery through Hurtbox2D.

var source_actor: Node2D
var damage := 1
var active := false
var hit_targets: Dictionary = {}
var collision_shape: CollisionShape2D

func configure(source: Node2D, damage_amount: int, target_hurtbox_mask: int, shape: Shape2D) -> void:
	source_actor = source
	damage = damage_amount
	collision_layer = 0
	collision_mask = target_hurtbox_mask
	monitoring = true
	monitorable = false
	collision_shape = CollisionShape2D.new()
	collision_shape.shape = shape
	collision_shape.disabled = true
	add_child(collision_shape)
	area_entered.connect(_on_area_entered)

func begin_window() -> void:
	active = true
	hit_targets.clear()
	if is_instance_valid(collision_shape):
		collision_shape.set_deferred("disabled", false)

func end_window() -> void:
	active = false
	if is_instance_valid(collision_shape):
		collision_shape.set_deferred("disabled", true)

func _on_area_entered(area: Area2D) -> void:
	if not active or not is_instance_valid(area):
		return
	var key := area.get_instance_id()
	if hit_targets.has(key):
		return
	hit_targets[key] = true
	if area.has_method("receive_hitbox"):
		area.receive_hitbox(self)
