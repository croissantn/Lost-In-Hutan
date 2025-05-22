extends Area2D
class_name HitBox

@export var damage: int = 10
@export var knockback_force: float = 200.0
@export var owner_node_path: NodePath

# Node yang memiliki hitbox ini (player atau enemy)
var owner_node: Node2D

func _ready():
	# Layer 4 untuk hitbox
	collision_layer = 4
	# Layer 8 untuk hurtbox
	collision_mask = 8
	
	# Dapatkan owner node
	if owner_node_path:
		owner_node = get_node(owner_node_path)
	else:
		owner_node = get_parent()
	
	# Nonaktifkan hitbox secara default
	# Akan diaktifkan saat animasi serangan
	monitoring = false
	
	# Connect signal
	connect("area_entered", _on_area_entered)

func _on_area_entered(area):
	if area is HurtBox:
		var target = area.get_parent()
		
		# Pastikan tidak menyerang diri sendiri
		if target == owner_node:
			return
			
		# Pastikan target bisa menerima damage
		if target.has_method("take_damage"):
			# Hitung arah knockback
			var knockback_direction = (target.global_position - owner_node.global_position).normalized()
			
			# Terapkan damage dan knockback
			target.take_damage(damage, knockback_direction * knockback_force)

# Aktifkan hitbox (dipanggil dari animasi serangan)
func activate():
	monitoring = true

# Nonaktifkan hitbox (dipanggil setelah serangan selesai)
func deactivate():
	monitoring = false
