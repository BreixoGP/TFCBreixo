extends Area2D
class_name Crystal
@export var pickup_id: String
var picked := false

func _ready():
	if pickup_id == "":
		push_error("Pickup sin ID: " + name)
		return

	if GameManager.is_pickup_collected(pickup_id):
		queue_free()

func _on_body_entered(body):
	if picked:
		return
	if body is DrunkMaster:
		picked = true
		GameManager.has_crystal = true
		#GameManager.hud.update_items()
		GameManager.hud.show_message("Cursed Brewery altar crystal picked...")
		GameManager.collect_pickup(pickup_id)

		queue_free()
