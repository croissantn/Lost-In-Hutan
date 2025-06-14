# player.gd
extends CharacterBody2D

# Ekspor variabel agar bisa diubah dari Inspector
@export var speed: float = 200.0
@export var jump_velocity: float = -400.0
@export var attack_damage: int = 10

# Variabel gravitasi bisa diambil dari pengaturan proyek
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $HitBox
@onready var hitbox_shape: CollisionShape2D = $HitBox/CollisionShape2D # Pastikan path ini benar
@onready var health_node: Node = $Health # Akan diisi script health.gd

var is_attacking: bool = false

func _ready():
	# Nonaktifkan hitbox di awal
	hitbox_shape.disabled = true
	# Koneksikan sinyal dari hitbox
	hitbox.area_entered.connect(_on_hitbox_area_entered)
	# Koneksikan sinyal dari health node
	if health_node and health_node.has_signal("died"):
		health_node.died.connect(_on_died)


func _physics_process(delta: float) -> void:
	# Tambahkan gravitasi jika tidak sedang menyerang dan tidak di lantai (ini bisa disesuaikan)
	if not is_on_floor() and not is_attacking:
		velocity.y += gravity * delta

	# Handle lompat
	if Input.is_action_just_pressed("jump") and is_on_floor() and not is_attacking:
		velocity.y = jump_velocity

	# Handle gerakan kiri/kanan
	var direction: float = Input.get_axis("move_left", "move_right")
	if not is_attacking: # Jangan bergerak saat menyerang
		if direction:
			velocity.x = direction * speed
		else:
			velocity.x = move_toward(velocity.x, 0, speed) # Berhenti jika tidak ada input
	else:
		velocity.x = move_toward(velocity.x, 0, speed * 0.2) # Gerak lambat saat menyerang (opsional)

	# Handle serangan
	if Input.is_action_just_pressed("attack") and not is_attacking:
		_perform_attack()

	# Update animasi berdasarkan state
	_update_animation(direction)

	move_and_slide()


func _update_animation(direction: float) -> void:
	if is_attacking:
		animated_sprite.play("attack") # Asumsi ada animasi "attack"
	elif not is_on_floor():
		animated_sprite.play("jump") # Asumsi ada animasi "jump"
	elif direction != 0:
		animated_sprite.play("walk") # Asumsi ada animasi "walk"
		animated_sprite.flip_h = (direction < 0) # Balik sprite jika ke kiri
		# Balik juga hitbox agar sesuai arah karakter
		if hitbox:
			hitbox.scale.x = -1 if direction < 0 else 1
	else:
		animated_sprite.play("idle") # Asumsi ada animasi "idle"


func _perform_attack() -> void:
	is_attacking = true
	hitbox_shape.disabled = false
	animated_sprite.play("attack") # Putar animasi serangan

	# Tunggu animasi serangan selesai untuk menonaktifkan hitbox dan state attack
	# Gunakan sinyal animation_finished dari AnimatedSprite2D
	# Jika animasi "attack" tidak loop, ini akan bekerja
	if not animated_sprite.animation_finished.is_connected(_on_attack_animation_finished):
		animated_sprite.animation_finished.connect(_on_attack_animation_finished)


func _on_attack_animation_finished() -> void:
	# Hanya nonaktifkan jika animasi yang selesai adalah "attack"
	if animated_sprite.animation == "attack":
		is_attacking = false
		hitbox_shape.disabled = true
		# Penting: putuskan koneksi agar tidak terpanggil lagi oleh animasi lain
		if animated_sprite.animation_finished.is_connected(_on_attack_animation_finished):
			animated_sprite.animation_finished.disconnect(_on_attack_animation_finished)

func _on_hitbox_area_entered(area: Area2D) -> void:
	# Cek apakah yang masuk adalah HurtBox dan memiliki fungsi take_damage
	if area.has_method("take_damage"):
		# 'owner' dari hitbox adalah Player. Kita bisa mengirimkan 'self' (Player) sebagai penyerang
		area.take_damage(attack_damage, self)
		print("Player hit something!")
		# Mungkin nonaktifkan hitbox setelah 1 pukulan agar tidak multi-hit
		# hitbox_shape.disabled = true 

func _on_died():
	print("Player Died!")
	# Logika kematian player (misal: animasi mati, game over, dll)
	animated_sprite.play("death") # Asumsi ada animasi "death"
	set_physics_process(false) # Hentikan proses fisika
	# Mungkin sembunyikan atau queue_free() setelah beberapa saat


# Siapkan animasi di AnimatedSprite2D: "idle", "walk", "jump", "attack", "death"
# Pastikan animasi "attack" tidak looping.
