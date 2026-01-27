extends Button

@export var main_scene: PackedScene = preload("res://scenes/main.tscn")

func _ready() -> void:
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	
	get_tree().change_scene_to_packed(main_scene)
	
	
	GameManager.start_new_game_flag = true
