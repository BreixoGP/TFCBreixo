extends Area2D

@export var checkpoint_tag: String = "Respawn"          # Nodo Respawn dentro del nivel
@export var checkpoint_level_path: String = ""          # Nivel donde se activa el checkpoint

func _on_body_entered(body):
	if body is DrunkMaster:
		# Determinar nivel del checkpoint
		var level_path := checkpoint_level_path
		if level_path == "":
			level_path = GameManager.current_level_id  # Si no se especifica, usar nivel actual
		
		# Activar checkpoint en GameManager
		GameManager.activate_checkpoint(level_path, checkpoint_tag)
		
		# Guardar habilidades permanentes del jugador
		GameManager.wall_ability_unlocked = body.wall_ability_active

		# Hacer permanente todo lo temporal de enemigos y pickups
		GameManager.make_temporary_permanent()

		print("Checkpoint activado:", checkpoint_tag, "en nivel:", GameManager.current_checkpoint_level)
		print("Habilidad wallslide permanente:", GameManager.wall_ability_unlocked)
