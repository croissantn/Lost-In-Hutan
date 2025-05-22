extends State
class_name PatrolState

@export var patrol_speed := 60
@export var patrol_distance := 100

var direction := Vector2.RIGHT
var origin_position := Vector2.ZERO

func enter():
	if enemy:
		enemy.animation.play("Walk")
		origin_position = enemy.global_position

func physics_update(delta):
	if enemy:
		enemy.velocity = direction * patrol_speed
		enemy.move_and_slide()

		var distance = enemy.global_position.distance_to(origin_position)
		if distance >= patrol_distance:
			direction *= -1
			origin_position = enemy.global_position
