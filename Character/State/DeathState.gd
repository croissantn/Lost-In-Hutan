extends State
class_name DeathState

func enter():
	if enemy:
		enemy.animation.play("Death")
		enemy.set_physics_process(false)
		enemy.set_process(false)
