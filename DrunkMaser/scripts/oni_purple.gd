extends Oni


func apply_knockback(amount:int, from_position: Vector2, attack_type:int, knockback_strength: float = 50.0,knockback_time = 0.2):
	var dir = global_position - from_position
	dir.x = sign(dir.x)  
	dir.y = -1.0 if attack_type == 1.0 else 0.0
	dir = dir.normalized()
	velocity = dir * (knockback_strength * amount)  # fuerza proporcional
	var t = get_tree().create_timer(amount * knockback_time)
	t.connect("timeout", Callable(self, "_end_knockback"))

func _on_attack_hitbox_body_entered(body: Node2D) -> void:
	if body is DrunkMaster:
		var drunkmaster: DrunkMaster = body as DrunkMaster
		drunkmaster.take_damage(attack_power, global_position, 0)
	elif body.is_in_group("Destructibles"):
		if body.has_method("take_damage"):
			body.take_damage(body.life, global_position, 1)
