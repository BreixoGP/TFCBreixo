extends Button
@export var main_scene:PackedScene=preload("res://scenes/main.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pressed.connect(play,4)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func play():
	GameManager.score = 0
	GameManager.saved_score = 0
	GameManager.level_index = 0
	GameManager.has_crystal = false

	# habilidades
	GameManager.wall_ability_unlocked = false
	GameManager.wall_ability_active = false

	# spawn inicial
	GameManager.current_checkpoint_level = GameManager.levels[GameManager.level_index]
	GameManager.current_checkpoint_tag = "Spawn_start"

	# cambiar a la escena principal
	get_tree().change_scene_to_packed(main_scene)
