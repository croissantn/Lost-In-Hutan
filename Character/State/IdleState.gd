extends State
class_name IdleState

@export var idle_time := 1.5
var timer := 0.0

func enter():
	timer = 0.0
	if enemy:
		enemy.animation.play("Idle")
		enemy.velocity = Vector2.ZERO

func update(delta):
	timer += delta
	if timer >= idle_time:
		transitioned.emit("PatrolState")
