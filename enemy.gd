extends CharacterBody2D
class_name Enemy

# --- Variabel dan Konstanta ---
@export var max_health: int = 30
@export var damage: int = 10
@export var speed: float = 50.0
@export var detection_range: float = 300.0
@export var attack_range: float = 50.0
@export var knockback_force: float = 200.0

# --- State Machine Sederhana ---
enum EnemyState {IDLE, PATROL, CHASE, ATTACK, HURT, DEAD}
var current_state = EnemyState.IDLE

# --- Referensi Node ---
@onready var health_component = $Health
@onready var animated_sprite = $AnimatedSprite2D
@onready var player_detection = $PlayerDetection
@onready var attack_area = $HitBox
@onready var hurt_box = $HurtBox
@onready var ground_check = $GroundCheck
@onready var wall_check = $WallCheck

# --- Variabel Lainnya ---
var player = null
var patrol_points = []
var current_patrol_index = 0
var gravity = 800
var direction = 1  # 1 = kanan, -1 = kiri
var is_dead = false
var attack_cooldown = false
var patrol_wait_time = 0.0

func _ready():
	# Tambahkan enemy ke grup "enemy"
	add_to_group("enemy")
	
	# Inisialisasi health component
	if not health_component:
		health_component = Node.new()
		health_component.set_script(load("res://health.gd"))
		health_component.name = "Health"
		add_child(health_component)
	
	health_component.max_health = max_health
	health_component.current_health = max_health
	health_component.connect("damaged", _on_damaged)
	health_component.connect("health_depleted", _on_health_depleted)
	
	# Inisialisasi area deteksi player
	if player_detection:
		player_detection.connect("body_entered", _on_player_detection_body_entered)
		player_detection.connect("body_exited", _on_player_detection_body_exited)
	
	# Inisialisasi hitbox
	if attack_area:
		attack_area.damage = damage
		attack_area.knockback_force = knockback_force
		attack_area.monitoring = false  # Nonaktifkan hitbox secara default
	
	# Inisialisasi hurtbox
	if hurt_box:
		hurt_box.connect("area_entered", _on_hurt_box_area_entered)
	
	# Atur patrol points default jika tidak ada
	if patrol_points.size() == 0:
		patrol_points.append(global_position + Vector2(-100, 0))
		patrol_points.append(global_position + Vector2(100, 0))

func _physics_process(delta):
	# Terapkan gravitasi jika tidak di lantai
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# State machine
	match current_state:
		EnemyState.IDLE:
			_handle_idle_state(delta)
		EnemyState.PATROL:
			_handle_patrol_state(delta)
		EnemyState.CHASE:
			_handle_chase_state(delta)
		EnemyState.ATTACK:
			_handle_attack_state(delta)
		EnemyState.HURT:
			_handle_hurt_state(delta)
		EnemyState.DEAD:
			_handle_dead_state(delta)
	
	# Gerakkan enemy
	move_and_slide()
	
	# Update animasi
	_update_animation()
	
	# Update facing direction
	_update_facing_direction()

# --- State Handlers ---
func _handle_idle_state(delta):
	velocity.x = 0
	
	# Transisi ke patrol setelah beberapa waktu
	patrol_wait_time += delta
	if patrol_wait_time >= 2.0:
		patrol_wait_time = 0.0
		current_state = EnemyState.PATROL

func _handle_patrol_state(delta):
	if patrol_points.size() == 0:
		current_state = EnemyState.IDLE
		return
	
	# Bergerak ke patrol point
	var target = patrol_points[current_patrol_index]
	var direction_to_target = (target - global_position).normalized()
	
	velocity.x = direction_to_target.x * speed
	
	# Cek jika sudah mencapai target
	if global_position.distance_to(target) < 10:
		current_patrol_index = (current_patrol_index + 1) % patrol_points.size()
		
		# Tunggu sebentar di setiap point
		velocity.x = 0
		patrol_wait_time += delta
		if patrol_wait_time >= 1.0:
			patrol_wait_time = 0.0
	
	# Cek jika ada obstacle
	if is_on_wall() or not ground_check.is_colliding():
		# Balik arah
		direction *= -1
		velocity.x = direction * speed
		
		# Update patrol point
		current_patrol_index = (current_patrol_index + 1) % patrol_points.size()

func _handle_chase_state(delta):
	if not player:
		current_state = EnemyState.PATROL
		return
	
	# Arah ke player
	var direction_to_player = (player.global_position - global_position).normalized()
	
	# Bergerak ke arah player
	velocity.x = direction_to_player.x * speed * 1.5
	
	# Cek jarak untuk serangan
	if global_position.distance_to(player.global_position) < attack_range:
		current_state = EnemyState.ATTACK

func _handle_attack_state(delta):
	velocity.x = 0
	
	if not attack_cooldown:
		# Aktifkan hitbox
		if attack_area:
			attack_area.monitoring = true
		
		# Mulai cooldown
		attack_cooldown = true
		
		# Nonaktifkan hitbox setelah beberapa waktu
		await get_tree().create_timer(0.3).timeout
		if attack_area:
			attack_area.monitoring = false
		
		# Tunggu cooldown selesai
		await get_tree().create_timer(1.0).timeout
		attack_cooldown = false
		
		# Kembali chase
		if player and not is_dead:
			current_state = EnemyState.CHASE
		else:
			current_state = EnemyState.IDLE

func _handle_hurt_state(delta):
	velocity.x = 0
	
	# Tunggu animasi hurt selesai
	if animated_sprite and not animated_sprite.is_playing():
		if player:
			current_state = EnemyState.CHASE
		else:
			current_state = EnemyState.IDLE

func _handle_dead_state(delta):
	velocity = Vector2.ZERO
	
	# Tunggu animasi death selesai
	if animated_sprite and not animated_sprite.is_playing():
		# Hapus enemy
		queue_free()

# --- Animation Handling ---
func _update_animation():
	if not animated_sprite:
		return
		
	match current_state:
		EnemyState.IDLE:
			animated_sprite.play("idle")
		EnemyState.PATROL:
			animated_sprite.play("walk")
		EnemyState.CHASE:
			animated_sprite.play("run")
		EnemyState.ATTACK:
			if not animated_sprite.is_playing() or animated_sprite.animation != "attack":
				animated_sprite.play("attack")
		EnemyState.HURT:
			if not animated_sprite.is_playing() or animated_sprite.animation != "hurt":
				animated_sprite.play("hurt")
		EnemyState.DEAD:
			if not animated_sprite.is_playing() or animated_sprite.animation != "death":
				animated_sprite.play("death")

func _update_facing_direction():
	if velocity.x > 0:
		direction = 1
		if animated_sprite:
			animated_sprite.flip_h = false
	elif velocity.x < 0:
		direction = -1
		if animated_sprite:
			animated_sprite.flip_h = true
	
	# Update posisi wall check dan ground check
	if wall_check:
		wall_check.position.x = abs(wall_check.position.x) * direction
	if ground_check:
		ground_check.position.x = abs(ground_check.position.x) * direction

# --- Signal Handlers ---
func _on_damaged(amount):
	if current_state != EnemyState.DEAD:
		current_state = EnemyState.HURT

func _on_health_depleted():
	current_state = EnemyState.DEAD
	is_dead = true
	
	# Nonaktifkan collision
	$CollisionShape2D.set_deferred("disabled", true)
	
	# Nonaktifkan hitbox dan hurtbox
	if attack_area:
		attack_area.set_deferred("monitoring", false)
	if hurt_box:
		hurt_box.set_deferred("monitorable", false)

func _on_player_detection_body_entered(body):
	if body.is_in_group("player"):
		player = body
		current_state = EnemyState.CHASE

func _on_player_detection_body_exited(body):
	if body.is_in_group("player"):
		player = null
		current_state = EnemyState.PATROL

func _on_hurt_box_area_entered(area):
	if area.is_in_group("player_hitbox"):
		# Ambil damage dari hitbox player
		var damage_amount = area.damage if area.has_method("get_damage") else 10
		
		# Ambil knockback dari hitbox player
		var knockback_dir = (global_position - area.global_position).normalized()
		var knockback = knockback_dir * (area.knockback_force if area.has_method("get_knockback_force") else 200)
		
		# Terapkan damage dan knockback
		take_damage(damage_amount, knockback)

# --- Fungsi Publik ---
func set_patrol_points(points):
	patrol_points = points
	if patrol_points.size() > 0:
		current_state = EnemyState.PATROL

func take_damage(amount, knockback_force = Vector2.ZERO):
	if is_dead:
		return
		
	if health_component:
		health_component.damage(amount)
	
	# Terapkan knockback
	if knockback_force != Vector2.ZERO:
		velocity = knockback_force
	
	# Mulai invincibility
	if hurt_box:
		hurt_box.start_invincibility()
	
	# Efek visual
	modulate = Color(1, 0.3, 0.3, 1.0)
	await get_tree().create_timer(0.2).timeout
	modulate = Color(1, 1, 1, 1.0)
