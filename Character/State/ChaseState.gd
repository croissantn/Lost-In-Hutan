extends State
class_name ChaseState

@export var chase_speed := 80
@export var player_path := NodePath("../Player")

func physics_update(delta):
	if enemy:
		var player = enemy.get_node_or_null(player_path)
		if player:
			var direction = (player.global_position - enemy.global_position).normalized()
			enemy.velocity = direction * chase_speed
			enemy.move_and_slide()
