extends Control  # Pastikan ini sesuai dengan tipe node Anda

# Referensi ke node UI
@onready var health_bar = $HealthBar/ProgressBar
@onready var health_text = $HealthText
@onready var health_icon = $HealthIcon

# Referensi ke player dan health component
var player
var health_component

# Warna untuk health bar
var normal_color = Color(0.0, 0.8, 0.0)  # Hijau
var low_health_color = Color(0.9, 0.0, 0.0)  # Merah
var low_health_threshold = 0.3  # 30% dari max health

func _ready():
	# Cek apakah node UI ada
	if !health_bar:
		push_error("HealthBar/ProgressBar tidak ditemukan! Periksa path: $HealthBar/ProgressBar")
	if !health_text:
		push_error("HealthText tidak ditemukan! Periksa path: $HealthText")
	
	# Cari player dengan berbagai metode
	find_player()
	
	# Connect ke health component
	if player and player.has_node("Health"):
		health_component = player.get_node("Health")
		
		# Connect signal
		if health_component:
			health_component.connect("health_changed", _on_health_changed)
			health_component.connect("damaged", _on_player_damaged)
			health_component.connect("healed", _on_player_healed)
			
			# Set nilai awal
			update_health_display(health_component.current_health)
		else:
			push_error("Health component tidak ditemukan pada player!")
	else:
		push_error("Player tidak ditemukan atau tidak memiliki node Health!")

# Fungsi untuk mencari player
func find_player():
	print("Mencari player...")
	
	# Metode 1: Path langsung
	player = get_node_or_null("/root/Main/Player")
	
	# Metode 2: Cari di scene tree
	if !player:
		player = get_tree().get_root().find_child("Player", true, false)
	
	# Metode 3: Cari dengan grup
	if !player:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player = players[0]
	
	# Debug info
	if player:
		print("Player ditemukan: ", player.name)
	else:
		push_error("Player tidak ditemukan dengan metode apapun!")

# Fungsi untuk update tampilan health
func update_health_display(health_value):
	if !health_bar or !health_text or !health_component:
		return
	
	# Update progress bar
	health_bar.max_value = health_component.max_health
	health_bar.value = health_value
	
	# Update text
	health_text.text = str(health_value) + "/" + str(health_component.max_health)
	
	# Update warna berdasarkan health
	var health_percent = float(health_value) / float(health_component.max_health)
	if health_percent <= low_health_threshold:
		health_bar.modulate = low_health_color
	else:
		health_bar.modulate = normal_color

# Signal handler untuk health_changed
func _on_health_changed(new_health, old_health):
	# Update tampilan dengan animasi
	if health_bar:
		var tween = create_tween()
		tween.tween_property(health_bar, "value", new_health, 0.3).set_ease(Tween.EASE_OUT)
	
	# Update text langsung
	if health_text and health_component:
		health_text.text = str(new_health) + "/" + str(health_component.max_health)
	
	# Update warna
	if health_bar and health_component:
		var health_percent = float(new_health) / float(health_component.max_health)
		if health_percent <= low_health_threshold:
			health_bar.modulate = low_health_color
		else:
			health_bar.modulate = normal_color

# Signal handler untuk damaged
func _on_player_damaged(amount):
	if !health_bar:
		return
		
	# Efek visual saat terkena damage
	var damage_tween = create_tween()
	damage_tween.tween_property(health_bar, "modulate", Color(1, 0, 0), 0.1)
	damage_tween.tween_property(health_bar, "modulate", health_bar.modulate, 0.2)
	
	# Efek shake
	if health_text:
		var shake_tween = create_tween()
		var original_pos = health_text.position
		shake_tween.tween_property(health_text, "position", original_pos + Vector2(2, 0), 0.05)
		shake_tween.tween_property(health_text, "position", original_pos + Vector2(-2, 0), 0.05)
		shake_tween.tween_property(health_text, "position", original_pos, 0.05)

# Signal handler untuk healed
func _on_player_healed(amount):
	if !health_bar:
		return
		
	# Efek visual saat healing
	var heal_tween = create_tween()
	heal_tween.tween_property(health_bar, "modulate", Color(0, 1, 0), 0.1)
	heal_tween.tween_property(health_bar, "modulate", health_bar.modulate, 0.2)
