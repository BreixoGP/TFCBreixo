extends Area2D

@export var pickup_id := "upgrade_power_1"
@export var attack_bonus := 1
@export var life_bonus := 1

var picked := false

func _ready():
	if GameManager.is_pickup_collected(pickup_id):
		queue_free()

func _on_body_entered(body):
	if picked or not (body is DrunkMaster):
		return

	picked = true
	GameManager.collect_pickup(pickup_id)

	# Boost total
	GameManager.upgrade_attack_temp += attack_bonus
	GameManager.upgrade_life_temp += life_bonus
	GameManager.hud.show_message("GLUP...GLUP...GLUP... Now i feel stronger than ever!")
	body.apply_permanent_upgrades()

	queue_free()
