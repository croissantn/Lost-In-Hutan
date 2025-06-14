# health.gd
extends Node

class_name Health # Agar bisa di-type hint

signal health_changed(current_health: int, max_health: int)
signal died

@export var max_health: int = 100
var current_health: int

func _ready() -> void:
	current_health = max_health
	health_changed.emit(current_health, max_health)

func take_damage(amount: int) -> void:
	current_health = max(0, current_health - amount)
	health_changed.emit(current_health, max_health)
	print(owner.name + " took " + str(amount) + " damage. Health: " + str(current_health))
	if current_health <= 0:
		died.emit()

func heal(amount: int) -> void:
	current_health = min(max_health, current_health + amount)
	health_changed.emit(current_health, max_health)
