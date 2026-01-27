extends Button

func _on_pressed() -> void:
	if GameManager:
		# Indicamos que queremos cargar partida
		GameManager.load_game_flag = true

		# Cambiar a la escena principal
		get_tree().change_scene_to_file("res://scenes/main.tscn")
