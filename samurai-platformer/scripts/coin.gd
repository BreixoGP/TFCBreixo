extends Area2D


func _on_body_entered(body: Node2D) -> void:
	if body is DrunkMaster:
		GameManager.score += 20
		#sonido?
		#await $AudioStreamPlayer2D.finished
		queue_free()
		
