extends Button
@export var first_scene:PackedScene=preload("res://scenes/main.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pressed.connect(play,4)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func play():
	GameManager.saved_score = 0
	GameManager.score = 0
	GameManager.level = 1
	GameManager.is_loading_game = false
	get_tree().change_scene_to_packed(first_scene)
	pressed.disconnect(play)
