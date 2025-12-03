extends Button
@export var main_scene:PackedScene=preload("res://scenes/main.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pressed.connect(play,4)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func play():
	GameManager.saved_score = 0
	GameManager.score = 0
	GameManager.level_index = 0
	GameManager.is_loading_game = false
	get_tree().change_scene_to_packed(main_scene)
	#pressed.disconnect(play)
