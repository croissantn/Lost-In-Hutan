extends Control

@onready var level1_button = $CenterContainer/VBoxContainer/Button
@onready var level2_button = $CenterContainer/VBoxContainer/Button2

func _ready():
	level1_button.pressed.connect(_on_level1_pressed)
	level2_button.pressed.connect(_on_Level2_pressed)

func _on_level1_pressed():
	SceneLoader.load_scene_async("res://main.tscn")

func _on_Level2_pressed():
	get_tree().change_scene_to_file("res://LevelMenu/Level2.tscn")
