extends Node2D

@onready var player = $Player
@onready var camera = $Camera2D

# Ukuran gambar dan scale
var original_width = 1920
var sprite_scale = 0.721
var effective_width
var viewport_width

func _ready():
	effective_width = original_width * sprite_scale
	viewport_width = get_viewport_rect().size.x
	
	setup_parallax_layers()
	
	if camera:
		camera.make_current()

func setup_parallax_layers():
	var parallax_bg = $ParallaxBackground
	
	# Hanya setup layer 1, 2, dan 3
	for i in range(1, 4):  # Hanya sampai 3
		var layer_name = "ParallaxLayer"
		if i > 1:
			layer_name += str(i)
		
		var layer = parallax_bg.get_node(layer_name)
		if layer:
			# Atur motion scale
			var motion_scale = 0.2 * i
			layer.motion_scale = Vector2(motion_scale, 0.0)
			
			# Reset motion_mirroring
			layer.motion_mirroring = Vector2.ZERO
			
			# Duplikasi sprite untuk menutupi seluruh area yang mungkin terlihat
			ensure_full_coverage(layer, motion_scale)
	
	# Layer 4 tidak disentuh sama sekali - biarkan apa adanya

func ensure_full_coverage(layer, motion_scale):
	var sprite = layer.get_node("Sprite2D")
	if not sprite:
		return
		
	# Hitung berapa banyak sprite yang dibutuhkan untuk menutupi viewport
	# dengan mempertimbangkan parallax motion
	var max_camera_movement = 3000  # Perkiraan jarak maksimum kamera bergerak
	var max_parallax_offset = max_camera_movement * motion_scale
	var total_width_needed = viewport_width + max_parallax_offset * 2
	var num_sprites_needed = ceil(total_width_needed / effective_width) + 1
	
	# Buat sprite tambahan jika diperlukan
	for i in range(-num_sprites_needed/2, num_sprites_needed/2 + 1):
		if i == 0:
			# Ini sprite asli
			sprite.position.x = 0
			continue
			
		var sprite_name = "Sprite2D_" + str(i)
		var duplicate_sprite = layer.get_node_or_null(sprite_name)
		
		if not duplicate_sprite:
			duplicate_sprite = sprite.duplicate()
			duplicate_sprite.name = sprite_name
			layer.add_child(duplicate_sprite)
			
		duplicate_sprite.position.x = effective_width * i

func _process(delta):
	# Update parallax background berdasarkan posisi kamera
	if camera:
		$ParallaxBackground.scroll_offset = camera.get_camera_screen_center()
		
		# Cek apakah kita perlu menggeser sprite untuk menutupi area baru
		check_and_update_sprites()

func check_and_update_sprites():
	# Implementasi logika untuk menggeser sprite jika diperlukan
	# Ini adalah pendekatan alternatif jika motion_mirroring tidak bekerja dengan baik
	pass
