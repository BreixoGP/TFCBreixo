extends AnimatedSprite2D

@onready var anim: AnimatedSprite2D = $"."  

@export var target_scene := "res://scenes/castle/level_1.tscn"
@export var target_spawn := "Spawn_left"
@export var door_id := ""  # Identificador único para GameManager

var is_unlocked := false  # Marca si la puerta ya fue desbloqueada con llave
var player_inside := false
var player_ref : Node = null
var door_busy := false  # Evita múltiples aperturas a la vez

func _ready():
	# Revisamos si la puerta ya fue desbloqueada temporal o permanentemente
	if door_id != "":
		if door_id in GameManager.activated_platforms_perm or door_id in GameManager.activated_platforms_temp:
			is_unlocked = true
			anim.play("opened")
			anim.modulate = Color(1, 1, 1, 1)
		else:
			anim.play("idle")
			anim.modulate = Color(0.6, 0.6, 0.6, 1)

# --- Detección del jugador ---
func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is DrunkMaster:
		player_inside = true
		player_ref = body

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body == player_ref:
		player_inside = false
		player_ref = null

# --- Revisamos input cada frame ---
func _physics_process(delta: float) -> void:
	if player_inside and not door_busy and Input.is_action_just_pressed("interact"):
		if GameManager.has_key or is_unlocked:
			door_busy = true
			await unlock_and_travel(player_ref)
			door_busy = false
		else:
			fail_door()

# --- Animación de fallo ---
func fail_door() -> void:
	anim.play("fail")

# --- Abrir y teletransportar ---
func unlock_and_travel(player: Node2D) -> void:
	# Si la puerta no estaba desbloqueada, la desbloqueamos y guardamos en temp
	if not is_unlocked:
		is_unlocked = true
		anim.modulate = Color(1, 1, 1, 1)
		if door_id != "" and door_id not in GameManager.activated_platforms_temp:
			GameManager.activated_platforms_temp.append(door_id)
		GameManager.has_key = false  # Consumimos la llave
	
	# Animaciones
	anim.play("shine")
	await anim.animation_finished

	anim.play("open")
	await anim.animation_finished

	# Teletransportamos al jugador al nivel
	player.set_physics_process(false)
	GameManager.player_spawn_tag = target_spawn
	player.set_physics_process(true)
	await GameManager.load_level(target_scene)
