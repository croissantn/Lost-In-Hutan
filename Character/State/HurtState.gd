extends State
class_name HurtState

@export var knockback_force := Vector2(-100, 0)
@export var hurt_duration := 0.5

var timer := 0.0

func enter():
	timer = 0.0
	if enemy:
		enemy.animation.play("Hurt")
		enemy.velocity = knockback_force

func physics_update(delta):
	timer += delta
	if enemy:
		enemy.move_and_slide()
	if timer >= hurt_duration:
		transitioned.emit("IdleState")
