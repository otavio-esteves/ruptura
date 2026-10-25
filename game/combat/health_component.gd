extends Node
## Shared damage gate. Each actor controls its own feedback and knockback.
signal changed(current: float, maximum: float)
signal depleted

@export var max_health: float = 100.0
@export var invulnerability_duration: float = 0.0
var current_health: float = 100.0
var invulnerability_remaining: float = 0.0

func _ready() -> void:
	reset_health()

func _physics_process(delta: float) -> void:
	invulnerability_remaining = maxf(0.0, invulnerability_remaining - delta)

func apply_damage(amount: float) -> bool:
	if amount <= 0.0 or not is_finite(amount) or current_health <= 0.0 or invulnerability_remaining > 0.0:
		return false
	current_health = maxf(0.0, current_health - amount)
	invulnerability_remaining = invulnerability_duration
	changed.emit(current_health, max_health)
	if current_health <= 0.0:
		depleted.emit()
	return true

func heal(amount: float) -> void:
	if current_health <= 0.0 or not is_finite(amount) or amount <= 0.0:
		return
	current_health = minf(max_health, current_health + amount)
	changed.emit(current_health, max_health)

func reset_health() -> void:
	current_health = max_health
	invulnerability_remaining = 0.0
	changed.emit(current_health, max_health)
