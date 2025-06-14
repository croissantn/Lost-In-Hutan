# hurt_box.gd
extends Area2D

class_name HurtBox

# Tidak perlu @export karena health node ada di parent dari parent (HurtBox -> Player/Enemy -> Health)
# var health_node: Health # Ini bisa jadi rumit

func take_damage(amount: int, attacker: Node2D) -> void:
	# Asumsi node Health adalah sibling dari HurtBox atau ada di parent (Player/Enemy)
	# Cara paling umum adalah mencari node Health di parent dari HurtBox
	var parent_entity = owner # Owner dari HurtBox adalah Player atau Enemy
	if parent_entity and parent_entity.has_node("Health"):
		var health_component = parent_entity.get_node("Health") as Health
		if health_component:
			health_component.take_damage(amount)
			# print(parent_entity.name + " hurt by " + attacker.name) # Debug
		else:
			print("Error: Health node not found on " + parent_entity.name)
	else:
		print("Error: HurtBox owner " + str(parent_entity) + " does not exist or has no Health node.")
