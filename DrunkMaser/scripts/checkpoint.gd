extends Area2D

@export var checkpoint_tag: String = "Respawn"
@export var checkpoint_level_path: String = ""

var player_inside := false
var player_ref : Node = null

func _on_body_entered(body: Node2D) -> void:
	if body is DrunkMaster:
		player_inside = true
		player_ref = body

func _on_body_exited(body: Node2D) -> void:
	if body == player_ref:
		player_inside = false
		player_ref = null

func _physics_process(delta: float) -> void:
	if player_inside and Input.is_action_just_pressed("interact") and player_ref:
		activate_checkpoint(player_ref)

func activate_checkpoint(player: Node2D) -> void:
	var level_path := checkpoint_level_path
	if level_path == "":
		level_path = GameManager.current_level_path

	GameManager.activate_checkpoint(level_path, checkpoint_tag)

	player.gain_life(player.max_life)  # restauramos la vida del jugador
	print("Checkpoint activated")
	print("Level:", level_path)
	print("Spawn:", checkpoint_tag)
