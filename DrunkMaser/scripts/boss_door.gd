extends AnimatedSprite2D

@onready var anim: AnimatedSprite2D = $"."



@export var target_scene := "res://scenes/castle/level_1.tscn"
@export var target_spawn := "Spawn_left"
@export var door_id := ""  # Identificador único para GameManager

var is_unlocked := false  # Marca si la puerta ya fue desbloqueada con llave

func _ready():
	# Revisamos si la puerta ya fue desbloqueada temporal o permanentemente
	if door_id != "":
		if door_id in GameManager.activated_platforms_perm or door_id in GameManager.activated_platforms_temp:
			is_unlocked = true
			anim.play("opened")
			anim.modulate = Color(1, 1, 1, 1)  # Color normal
		else:
			anim.play("idle")
			anim.modulate = Color(0.6, 0.6, 0.6, 1)  # Oscurecido para idle

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is not DrunkMaster:
		return

	if GameManager.crow_defeated_temp or GameManager.crow_defeated_perm or is_unlocked:
		await unlock_and_travel(body)
	else:
		fail_door()

func fail_door() -> void:
	anim.play("fail")

func unlock_and_travel(player: Node2D) -> void:
	# Si la puerta no estaba desbloqueada, la desbloqueamos, guardamos en temp y consumimos la llave
	
	if not is_unlocked:
		is_unlocked = true
		anim.modulate = Color(1, 1, 1, 1) 
		if door_id != "" and door_id not in GameManager.activated_platforms_temp:
			GameManager.activated_platforms_temp.append(door_id)
		
	
	anim.play("shine")
	await anim.animation_finished
	# Cuando la animación termina, la puerta se abre
	anim.play("open")
	await anim.animation_finished

	# Teletransportamos al jugador al nivel
	player.set_physics_process(false)
	GameManager.player_spawn_tag = target_spawn
	player.set_physics_process(true)
	await GameManager.load_level(target_scene)
