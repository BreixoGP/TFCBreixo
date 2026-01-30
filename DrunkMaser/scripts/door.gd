extends AnimatedSprite2D

@onready var door: AnimatedSprite2D = $"."  

@export var target_scene := "res://scenes/castle/level_1.tscn"
@export var target_spawn := "Spawn_left"

var player_inside := false
var player_ref : Node = null
var door_opening := false

# --- Detección del jugador en la zona ---
func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is DrunkMaster:
		player_inside = true
		player_ref = body

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body == player_ref:
		player_inside = false
		player_ref = null

# --- Revisar input cada frame ---
func _physics_process(delta: float) -> void:
	if player_inside and not door_opening and Input.is_action_just_pressed("interact"):
		door_opening = true
		open_door()

# --- Abrir la puerta ---
func open_door() -> void:
	if not player_ref:
		return

	player_ref.set_physics_process(false)  # Pausar jugador
	door.play("open")
	await door.animation_finished
	GameManager.player_spawn_tag = target_spawn
	player_ref.set_physics_process(true)   # Reactivar jugador
	await GameManager.load_level(target_scene)
