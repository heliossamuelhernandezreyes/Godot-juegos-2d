extends Area2D

## Reusable receiver for combat hitboxes. The actor remains responsible for
## invulnerability, parry logic, knockback and death state.

var actor: Node2D
var collision_shape: CollisionShape2D

func configure(owner_actor: Node2D, hurtbox_layer: int, shape: Shape2D) -> void:
	actor = owner_actor
	collision_layer = hurtbox_layer
	collision_mask = 0
	monitoring = false
	monitorable = true
	collision_shape = CollisionShape2D.new()
	collision_shape.shape = shape
	add_child(collision_shape)

func receive_hitbox(hitbox: Area2D) -> void:
	if not is_instance_valid(actor) or not is_instance_valid(hitbox):
		return
	if actor.has_method("try_parry_hit") and actor.try_parry_hit(hitbox):
		return
	if actor.has_method("take_damage"):
		var source_position := actor.global_position
		var source := hitbox.get("source_actor")
		if source is Node2D and is_instance_valid(source):
			source_position = source.global_position
		var amount_variant := hitbox.get("damage")
		var amount := int(amount_variant) if amount_variant != null else 1
		actor.take_damage(amount, source_position)
