extends Area2D
@export var pickup_id: String

func _ready():
	var level_id := get_owner().name
	GameManager.ensure_level_state(level_id)

	var key = level_id + ":" + pickup_id
	var state = GameManager.level_states[level_id]

	if state["permanent_collected_pickups"].has(key):
		queue_free()

func _on_body_entered(body):
	if body is DrunkMaster:
		GameManager.wall_ability_active = true

		var level_id := get_owner().name
		var state = GameManager.level_states[level_id]
		var key = level_id + ":" + pickup_id

		if not state["collected_pickups"].has(key):
			state["collected_pickups"].append(key)

		queue_free()
