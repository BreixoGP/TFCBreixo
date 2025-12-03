extends Area2D


func _on_body_entered(body: Node2D) -> void:
	if body.name=="DrunkMaster":
		var drunkmaster:DrunkMaster = body as DrunkMaster
		drunkmaster.get_damage(drunkmaster.life)
		
		
