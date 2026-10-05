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

func receive_hitbox(hitbox: Area2D) -> bool:
	if not is_instance_valid(actor) or not is_instance_valid(hitbox):
		return false

	if actor.has_method("try_parry_hit") and actor.try_parry_hit(hitbox):
		return true

	if not actor.has_method("take_damage"):
		return false

	var source_position := actor.global_position
	var source := hitbox.get("source_actor")
	if source is Node2D and is_instance_valid(source):
		source_position = source.global_position

	var amount_variant := hitbox.get("damage")
	var amount := int(amount_variant) if amount_variant != null else 1
	var accepted_variant = actor.take_damage(amount, source_position)
	return true if accepted_variant == null else bool(accepted_variant)
