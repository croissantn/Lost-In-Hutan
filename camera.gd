extends Camera2D

@export var target_path: NodePath
@export var smoothing_speed: float = 5.0

var target: Node2D

func _ready():
	if target_path:
		target = get_node(target_path)
	else:
		# Coba temukan player secara otomatis
		target = get_parent().get_node_or_null("Player")
	
	# Aktifkan kamera
	make_current()

func _process(delta):
	if target:
		# Pergerakan kamera yang halus
		global_position = global_position.lerp(target.global_position, smoothing_speed * delta)
