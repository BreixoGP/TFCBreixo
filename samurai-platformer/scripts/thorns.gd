extends Area2D

var shake_time := 0.0
var shake_intensity := 4.0
var base_pos: Vector2

func _ready():
	base_pos = position

func _process(delta: float) -> void:
	if shake_time > 0:
		shake_time -= delta

		position = base_pos + Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
	else:
		position = base_pos

func shake():
	shake_time = 0.2

func _on_body_entered(body: Node2D) -> void:
	if body is DrunkMaster:
		body.take_damage(1, global_position, 0)
		shake()   # 👈 agitar al tocar al player

	if body.is_in_group("Enemies"):
		body.take_damage(1, global_position, 0)
		shake()   # 👈 también con enemigos
