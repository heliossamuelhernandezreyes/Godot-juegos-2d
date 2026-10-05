extends AnimatableBody2D

@export var travel := Vector2(220.0, 0.0)
@export var cycle_seconds := 3.2

var origin := Vector2.ZERO
var elapsed := 0.0

func _ready() -> void:
	origin = position
	sync_to_physics = true

func _physics_process(delta: float) -> void:
	elapsed += delta
	var phase := (elapsed / maxf(cycle_seconds, 0.1)) * TAU
	position = origin + travel * ((sin(phase) + 1.0) * 0.5)
