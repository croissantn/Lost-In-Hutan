extends Area2D
class_name HurtBox

@export var owner_node_path: NodePath
@export var invincibility_time: float = 0.5

# Node yang memiliki hurtbox ini (player atau enemy)
var owner_node: Node2D
var is_invincible: bool = false

func _ready():
	# Layer 8 untuk hurtbox
	collision_layer = 8
	# Layer 4 untuk hitbox
	collision_mask = 4
	
	# Dapatkan owner node
	if owner_node_path:
		owner_node = get_node(owner_node_path)
	else:
		owner_node = get_parent()

# Mulai periode invincibility
func start_invincibility():
	if invincibility_time <= 0:
		return
		
	is_invincible = true
	
	# Nonaktifkan collision sementara
	monitorable = false
	
	# Visual feedback
	if owner_node:
		# Blink effect
		var tween = create_tween().set_loops(5)
		tween.tween_property(owner_node, "modulate:a", 0.2, 0.1)
		tween.tween_property(owner_node, "modulate:a", 1.0, 0.1)
	
	# Tunggu invincibility selesai
	await get_tree().create_timer(invincibility_time).timeout
	
	# Aktifkan kembali collision
	monitorable = true
	is_invincible = false
	
	# Reset visual
	if owner_node:
		owner_node.modulate.a = 1.0
