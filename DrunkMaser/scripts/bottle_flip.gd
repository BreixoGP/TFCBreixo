extends Area2D
@export var pickup_id = "bottle_flip"

func _ready():
	if pickup_id == "":
		push_error("Pickup sin ID: " + name)
		return

	if GameManager.is_pickup_collected(pickup_id):
		queue_free()

func _on_body_entered(body):
	if body is DrunkMaster:
		GameManager.flip_ability_active = true
		GameManager.collect_pickup(pickup_id)
		GameManager.hud.show_message("GLUP...GLUP...this taste... remind me of my days doing flip kicks")
		queue_free()
