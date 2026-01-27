extends Area2D
@export var pickup_id: String
var picked : = false

func _ready():
	if pickup_id == "":
		push_error("Pickup sin ID: " + name)
		return

	if GameManager.is_pickup_collected(pickup_id):
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if picked:
		return
		
	if body is DrunkMaster:
		picked = true
		GameManager.collect_pickup(pickup_id)
		GameManager.add_point(20)
		queue_free()
