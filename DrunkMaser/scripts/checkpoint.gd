extends Area2D

@export var checkpoint_tag: String = "Respawn"
@export var checkpoint_level_path: String = ""

func _on_body_entered(body: Node2D) -> void:
	if body is not DrunkMaster:
		return

	var level_path := checkpoint_level_path
	if level_path == "":
		level_path = GameManager.current_level_path

	GameManager.activate_checkpoint(level_path, checkpoint_tag)

	body.gain_life(body.max_life)  # restauramos la vida del jugador
	print("✅ Checkpoint activado")
	print("Nivel:", level_path)
	print("Spawn:", checkpoint_tag)
