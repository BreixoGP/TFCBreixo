extends Area2D
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
		body.gain_life(1)
		GameManager.collect_pickup(pickup_id)
		queue_free()
