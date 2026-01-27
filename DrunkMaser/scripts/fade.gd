extends ColorRect

@export var fade_time := 1.5

func fade_from_black():
	# Negro -> transparente
	modulate.a = 1.0
	await get_tree().process_frame
	await get_tree().create_timer(0.3).timeout
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, fade_time)
	await tween.finished
