extends CharacterBody2D

# --- Variables and Constants ---
const SPEED = 130
const RUN_MULTIPLIER = 1.5
const JUMP_FORCE = -300
const GRAVITY = 800
const ATTACK_COOLDOWN = 0.4
const THROW_COOLDOWN = 1.0
const SWORD_DAMAGE = 5
const THROW_DAMAGE = 10

var is_attacking = false
var can_attack = true
var can_throw = true
var is_jumping = false
var is_dead = false

# --- Lifecycle Functions ---
func _ready():
	# Connect animation finished signal
	$AnimatedSprite2D.animation_finished.connect(_on_animation_finished)

func _physics_process(delta):
	if is_dead:
		return

	handle_movement(delta)
	handle_jump()
	handle_attack()
	handle_animation()
	move_and_slide()

# --- Movement Functions ---
func handle_movement(delta):
	var dir = 0
	if Input.is_action_pressed("move_left"):
		dir -= 1
	if Input.is_action_pressed("move_right"):
		dir += 1

	var speed = SPEED
	if Input.is_action_pressed("run"):
		speed *= RUN_MULTIPLIER

	# Allow movement unless attacking
	if not is_attacking:
		velocity.x = dir * speed
	
	if dir != 0:
		$AnimatedSprite2D.flip_h = dir < 0

	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		is_jumping = false

# --- Jump Functions ---
func handle_jump():
	if is_on_floor() and Input.is_action_just_pressed("jump") and not is_attacking:
		velocity.y = JUMP_FORCE
		is_jumping = true
		$AnimatedSprite2D.play("jump")

# --- Attack Functions ---
func handle_attack():
	if Input.is_action_just_pressed("attack_sword") and can_attack and not is_attacking:
		sword_attack()
	elif Input.is_action_just_pressed("attack_throw") and can_throw and not is_attacking:
		throw_object()

func sword_attack():
	is_attacking = true
	can_attack = false
	
	if not is_on_floor():
		$AnimatedSprite2D.play("air_attack")
	elif abs(velocity.x) > SPEED * 0.5 and Input.is_action_pressed("run"):
		$AnimatedSprite2D.play("run_attack")
	else:
		$AnimatedSprite2D.play("attack_sword")
	
	# Start cooldown timer
	get_tree().create_timer(ATTACK_COOLDOWN).timeout.connect(func(): can_attack = true)

func throw_object():
	is_attacking = true
	can_throw = false
	
	if not is_on_floor():
		$AnimatedSprite2D.play("air_throw")
	elif abs(velocity.x) > SPEED * 0.5 and Input.is_action_pressed("run"):
		$AnimatedSprite2D.play("run_throw")
	else:
		$AnimatedSprite2D.play("throw")
	
	# Start cooldown timer
	get_tree().create_timer(THROW_COOLDOWN).timeout.connect(func(): can_throw = true)

# --- Animation Functions ---
func handle_animation():
	if is_dead:
		$AnimatedSprite2D.play("death")
		return
		
	if is_attacking:
		return  # Don't override attack animations
		
	if not is_on_floor():
		if velocity.y < 0:
			$AnimatedSprite2D.play("jump")
		else:
			$AnimatedSprite2D.play("fall")
	elif abs(velocity.x) > 0.1:  # Small threshold to prevent jitter
		if Input.is_action_pressed("run"):
			$AnimatedSprite2D.play("run")
		else:
			$AnimatedSprite2D.play("walk")
	else:
		$AnimatedSprite2D.play("idle")

# This function is called when an animation finishes
func _on_animation_finished():
	var anim_name = $AnimatedSprite2D.animation
	
	# When attack animations finish, allow movement again
	if anim_name in ["attack_sword", "air_attack", "run_attack", "throw", "air_throw", "run_throw"]:
		is_attacking = false
		
	# For death animation, keep it playing
	if anim_name == "death":
		return

# --- Damage and Death Functions ---
func take_damage(amount):
	if is_dead:
		return
		
	$AnimatedSprite2D.play("hit")
	# Reduce health here
	# health -= amount
	
	# Example death check
	# if health <= 0:
	#     die()

func die():
	is_dead = true
	velocity = Vector2.ZERO
	$AnimatedSprite2D.play("death")
