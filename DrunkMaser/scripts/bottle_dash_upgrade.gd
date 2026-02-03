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
		GameManager.dash_upgrade_active = true
		GameManager.collect_pickup(pickup_id)
		GameManager.hud.show_message("GLUP...GLUP...I feel like i could dash the air...")
		queue_free()
