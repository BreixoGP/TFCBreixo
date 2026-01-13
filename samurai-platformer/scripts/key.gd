extends Area2D

@export var pickup_id: String


func _ready():
	if pickup_id == "":
		push_error("Pickup sin ID: " + name)
		return

	if GameManager.is_pickup_collected(pickup_id):
		queue_free()

func _on_body_entered(body):
	if body is DrunkMaster:
		#emit_signal("picked_up")
		GameManager.has_crystal = true
		GameManager.hud.update_crystal()
		GameManager.collect_pickup(pickup_id)

		queue_free()
