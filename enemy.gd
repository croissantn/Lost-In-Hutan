# enemy.gd
extends CharacterBody2D
class_name Enemy # Deklarasikan nama kelas untuk script ini

# Enum sekarang bisa dirujuk sebagai Enemy.State
enum State { IDLE, CHASING, ATTACKING, RETURNING }

@export var speed: float = 75.0
@export var attack_range: float = 50.0 # Jarak untuk mulai menyerang
@export var attack_damage: int = 5
@export var attack_cooldown_time: float = 2.0 # Waktu antar serangan

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var player_detection_area: Area2D = $PlayerDetection
@onready var health_node: Node = $Health # Script health.gd
@onready var hitbox: Area2D = $HitBox # Asumsi ada node HitBox
@onready var hitbox_shape: CollisionShape2D = $HitBox/CollisionShape2D if $HitBox else null

# Gunakan Enemy.State untuk tipe dan nilai awal
var current_state: Enemy.State = Enemy.State.IDLE
var player_ref: CharacterBody2D = null # Referensi ke player jika terdeteksi
var spawn_position: Vector2
var attack_cooldown_timer: float = 0.0

func _ready() -> void:
	spawn_position = global_position
	player_detection_area.body_entered.connect(_on_player_detection_body_entered)
	player_detection_area.body_exited.connect(_on_player_detection_body_exited)

	if health_node and health_node.has_signal("died"):
		health_node.died.connect(_on_died)

	if hitbox:
		hitbox.area_entered.connect(_on_hitbox_area_entered)
		if hitbox_shape:
			hitbox_shape.disabled = true

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

	if attack_cooldown_timer > 0:
		attack_cooldown_timer -= delta

	match current_state:
		Enemy.State.IDLE:
			_state_idle(delta)
		Enemy.State.CHASING:
			_state_chasing(delta)
		Enemy.State.ATTACKING:
			_state_attacking(delta)
		Enemy.State.RETURNING:
			_state_returning(delta)

	_update_animation()
	move_and_slide()

func _state_idle(_delta: float) -> void:
	velocity.x = 0
	if player_ref:
		current_state = Enemy.State.CHASING

func _state_chasing(_delta: float) -> void:
	if not player_ref:
		current_state = Enemy.State.RETURNING
		return

	var direction_to_player: Vector2 = (player_ref.global_position - global_position).normalized()
	velocity.x = direction_to_player.x * speed

	if global_position.distance_to(player_ref.global_position) <= attack_range:
		if attack_cooldown_timer <= 0:
			current_state = Enemy.State.ATTACKING

func _state_attacking(_delta: float) -> void:
	velocity.x = 0
	if attack_cooldown_timer <= 0:
		animated_sprite.play("attack")

		if hitbox_shape:
			hitbox_shape.disabled = false

		attack_cooldown_timer = attack_cooldown_time

		if not animated_sprite.animation_finished.is_connected(_on_enemy_attack_animation_finished):
			animated_sprite.animation_finished.connect(_on_enemy_attack_animation_finished)
	else:
		if player_ref:
			current_state = Enemy.State.CHASING
		else:
			current_state = Enemy.State.RETURNING

func _on_enemy_attack_animation_finished() -> void:
	if animated_sprite.animation == "attack":
		if hitbox_shape:
			hitbox_shape.disabled = true

		if animated_sprite.animation_finished.is_connected(_on_enemy_attack_animation_finished):
			animated_sprite.animation_finished.disconnect(_on_enemy_attack_animation_finished)

		if player_ref and player_detection_area.overlaps_body(player_ref): # Cek ulang apakah player masih di area deteksi
			current_state = Enemy.State.CHASING
		else:
			player_ref = null
			current_state = Enemy.State.RETURNING

func _state_returning(_delta: float) -> void:
	if player_ref:
		current_state = Enemy.State.CHASING
		return

	var direction_to_spawn: Vector2 = (spawn_position - global_position).normalized()
	if global_position.distance_to(spawn_position) > 5:
		velocity.x = direction_to_spawn.x * speed
	else:
		velocity.x = 0
		global_position.x = spawn_position.x
		current_state = Enemy.State.IDLE

func _update_animation() -> void:
	match current_state:
		Enemy.State.IDLE:
			animated_sprite.play("idle")
		Enemy.State.CHASING:
			animated_sprite.play("walk")
			if velocity.x != 0:
				animated_sprite.flip_h = velocity.x < 0
				if hitbox:
					hitbox.scale.x = -1 if velocity.x < 0 else 1
		Enemy.State.ATTACKING:
			if animated_sprite.animation != "attack":
				animated_sprite.play("attack")
		Enemy.State.RETURNING:
			animated_sprite.play("walk")
			if velocity.x != 0:
				animated_sprite.flip_h = velocity.x < 0
				if hitbox:
					hitbox.scale.x = -1 if velocity.x < 0 else 1

func _on_player_detection_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_ref = body as CharacterBody2D
		if current_state == Enemy.State.IDLE or current_state == Enemy.State.RETURNING:
			current_state = Enemy.State.CHASING

func _on_player_detection_body_exited(body: Node2D) -> void:
	if body == player_ref:
		player_ref = null
		if current_state == Enemy.State.CHASING or current_state == Enemy.State.ATTACKING:
			current_state = Enemy.State.RETURNING

func _on_hitbox_area_entered(area: Area2D) -> void:
	if area is HurtBox and area.owner.is_in_group("player"):
		area.take_damage(attack_damage, self)
		if hitbox_shape:
			hitbox_shape.disabled = true

func _on_died() -> void:
	print("Enemy Died!")
	animated_sprite.play("death")
	set_physics_process(false)
	$CollisionShape2D.disabled = true
	$PlayerDetection/CollisionShape2D.disabled = true
	$HurtBox/CollisionShape2D.disabled = true
	if hitbox_shape:
		hitbox_shape.disabled = true

	await get_tree().create_timer(1.0).timeout
	queue_free()
