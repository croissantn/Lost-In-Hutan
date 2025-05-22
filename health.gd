extends Node
class_name Health

signal health_changed(new_health, old_health)
signal health_depleted
signal damaged(amount)
signal healed(amount)

@export var max_health: int = 100
@export var current_health: int = 100
@export var invincibility_time: float = 1.0

var is_invincible: bool = false

func _ready():
	current_health = max_health

func damage(amount: int) -> void:
	if is_invincible:
		return
		
	var old_health = current_health
	current_health = max(0, current_health - amount)
	
	emit_signal("damaged", amount)
	emit_signal("health_changed", current_health, old_health)
	
	if current_health == 0:
		emit_signal("health_depleted")
	else:
		start_invincibility()

func heal(amount: int) -> void:
	var old_health = current_health
	current_health = min(max_health, current_health + amount)
	
	emit_signal("healed", amount)
	emit_signal("health_changed", current_health, old_health)

func start_invincibility() -> void:
	if invincibility_time <= 0:
		return
		
	is_invincible = true
	await get_tree().create_timer(invincibility_time).timeout
	is_invincible = false

func get_health_percent() -> float:
	if max_health <= 0:
		return 0.0
	return float(current_health) / float(max_health)
