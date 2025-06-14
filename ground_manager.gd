# ground_manager.gd
extends Node2D # Atau Node, tergantung di mana Anda meletakkannya

@export var platform_scene: PackedScene # Seret platform.tscn ke sini di Inspector
@export var num_initial_platforms: int = 10
@export var platform_spacing_x: float = 200.0 # Jarak antar platform
@export var platform_y_position: float = 500.0 # Posisi Y platform
@export var generation_range_x: float = 1000.0 # Seberapa jauh platform di generate di depan player

@onready var player: CharacterBody2D = null # Akan diisi saat player ada di scene
var last_generated_x: float = 0.0

func _ready() -> void:
	# Cari player saat scene siap
	# Ini asumsi Player adalah child langsung dari Main. Jika tidak, sesuaikan path
	# Cara yang lebih baik adalah player mengumumkan dirinya saat siap
	await get_tree().process_frame # Tunggu satu frame agar node lain siap
	player = get_tree().root.find_child("Player", true, false) # Cari player di seluruh scene

	if not player:
		print("GroundManager: Player not found!")
		return

	# Generate platform awal
	for i in range(num_initial_platforms):
		_generate_platform(i * platform_spacing_x)
	last_generated_x = (num_initial_platforms -1) * platform_spacing_x

func _process(delta: float) -> void:
	if not player:
		return

	# Generate platform baru jika player mendekati ujung platform terakhir
	if player.global_position.x > last_generated_x - generation_range_x:
		_generate_platform(last_generated_x + platform_spacing_x)


func _generate_platform(x_pos: float) -> void:
	if not platform_scene:
		printerr("Platform scene not set in GroundManager!")
		return

	var platform_instance = platform_scene.instantiate()
	# Pastikan ground_manager ada di Main.tscn agar platform jadi child dari Main
	add_child(platform_instance) 
	platform_instance.global_position = Vector2(x_pos, platform_y_position)
	last_generated_x = x_pos
	# print("Generated platform at: ", platform_instance.global_position)

	# Hapus platform lama (opsional, untuk performa)
	_cleanup_old_platforms()

func _cleanup_old_platforms() -> void:
	if not player:
		return
		
	var children = get_children()
	for child in children:
		if child is StaticBody2D and child.name == "Platform": # Cek nama jika perlu
			if child.global_position.x < player.global_position.x - (generation_range_x * 1.5): # Jauh di belakang player
				# print("Removing platform at: ", child.global_position)
				child.queue_free()
