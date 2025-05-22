extends CharacterBody2D
class_name Enemy

@onready var animation = $AnimationPlayer

var state: State = null
var idle_state: IdleState
var patrol_state: PatrolState
var chase_state: ChaseState
var hurt_state: HurtState
var death_state: DeathState

func _ready():
	idle_state = preload("res://Character/State/IdleState.gd").new()
	patrol_state = preload("res://Character/State/PatrolState.gd").new()
	chase_state = preload("res://Character/State/ChaseState.gd").new()
	hurt_state = preload("res://Character/State/HurtState.gd").new()
	death_state = preload("res://Character/State/DeathState.gd").new()

	for s in [idle_state, patrol_state, chase_state, hurt_state, death_state]:
		s.enemy = self
		s.connect("transitioned", Callable(self, "_on_state_transitioned"))
		add_child(s)

	transition_to(idle_state)

func _process(delta):
	if state:
		state.update(delta)

func _physics_process(delta):
	if state:
		state.physics_update(delta)

func transition_to(new_state: State):
	if state:
		state.exit()
	state = new_state
	if state:
		state.enter()

func _on_state_transitioned(state_name: String):
	match state_name:
		"IdleState":
			transition_to(idle_state)
		"PatrolState":
			transition_to(patrol_state)
		"ChaseState":
			transition_to(chase_state)
		"HurtState":
			transition_to(hurt_state)
		"DeathState":
			transition_to(death_state)
