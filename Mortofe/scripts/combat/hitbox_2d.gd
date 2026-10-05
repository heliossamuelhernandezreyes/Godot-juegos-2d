extends Area2D

## Reusable combat hitbox. Gameplay actors own attack timing; this component owns
## target detection and damage payload delivery through Hurtbox2D.

signal hit_confirmed(target: Area2D, damage: int)

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

func _physics_process(_delta: float) -> void:
	if active:
		_scan_overlaps()

func begin_window() -> void:
	active = true
	hit_targets.clear()
	if is_instance_valid(collision_shape):
		collision_shape.set_deferred("disabled", false)
	# The shape is enabled deferred. Scanning every physics frame below guarantees
	# an already-overlapping hurtbox is still detected even if area_entered is missed.

func end_window() -> void:
	active = false
	if is_instance_valid(collision_shape):
		collision_shape.set_deferred("disabled", true)

func _on_area_entered(area: Area2D) -> void:
	_try_hit_area(area)

func _scan_overlaps() -> void:
	for area in get_overlapping_areas():
		_try_hit_area(area)

func _try_hit_area(area: Area2D) -> void:
	if not active or not is_instance_valid(area):
		return
	var key := area.get_instance_id()
	if hit_targets.has(key):
		return
	if not area.has_method("receive_hitbox"):
		return

	var consumed_variant = area.receive_hitbox(self)
	var consumed := true if consumed_variant == null else bool(consumed_variant)
	if not consumed:
		return

	hit_targets[key] = true
	hit_confirmed.emit(area, damage)
