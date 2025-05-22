extends CharacterBody2D

@onready var animation = $AnimationPlayer
@onready var sprite = $Sprite2D
@onready var attack_area = $AttackArea

@export var speed = 300.0
@export var jump_height = -400.0
@export var damage = 10
@export var attacking = false

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var current_state = "Idle"

func _physics_process(delta):
	if Input.is_action_just_pressed("attack_sword") and not attacking:
		attack()
		return # biar animasi serangan nggak terganggu gerakan lain

	if Input.is_action_pressed("left"):
		sprite.scale.x = abs(sprite.scale.x) * -1
	if Input.is_action_pressed("right"):
		sprite.scale.x = abs(sprite.scale.x)

	if not is_on_floor():
		velocity.y += gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_height

	var direction = Input.get_axis("left", "right")
	if direction:
		velocity.x = direction * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)

	move_and_slide()
	update_animation()

func update_animation():
	if attacking:
		if velocity.x != 0:
			animation.play("AttackRun")
		else:
			animation.play("Attack")
		return

	if velocity.y < 0:
		current_state = "Jump"
	elif velocity.y > 0:
		current_state = "Fall"
	elif velocity.x != 0:
		current_state = "Run"
	else:
		current_state = "Idle"

	animation.play(current_state)

func attack():
	attacking = true
	# Aktifkan area deteksi musuh
	attack_area.monitoring = true

	if velocity.x != 0:
		animation.play("AttackRun")
	else:
		animation.play("Attack")

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "Attack" or anim_name == "AttackRun":
		attacking = false
		attack_area.monitoring = false

func _on_attack_area_body_entered(body):
	if body.is_in_group("Enemy"):
		body.take_damage(damage)
