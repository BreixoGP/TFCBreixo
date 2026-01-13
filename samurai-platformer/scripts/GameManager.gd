# GameManager.gd
extends Node

# ============================================================
# CONFIGURACIÓN
# ============================================================

var levels = [
	"res://scenes/castle/level_1.tscn",
	"res://scenes/castle/level_2.tscn",
	"res://scenes/castle/level_3.tscn"
]

@onready var fade: ColorRect
var hud: Node = null
var levelcontainer: Node2D = null
var player: Node = null

# ============================================================
# ESTADO GENERAL
# ============================================================

var level_index := 0
var current_level: Node = null
var current_level_path := ""
var player_spawn_tag := "Spawn"

var score := 0
var saved_score := 0

# ============================================================
# CHECKPOINT
# ============================================================

var current_checkpoint_level := ""
var current_checkpoint_tag := ""

# ============================================================
# PROGRESO GLOBAL (IDs)
# ============================================================

# TEMPORAL (se pierde al morir)
var collected_pickups_temp: Array[String] = []
var defeated_enemies_temp: Array[String] = []
var activated_platforms_temp: Array[String] = []

# PERMANENTE (checkpoint)
var collected_pickups_perm: Array[String] = []
var defeated_enemies_perm: Array[String] = []
var activated_platforms_perm: Array[String] = []

# ============================================================
# HABILIDADES
# ============================================================

var wall_ability_unlocked := false
var wall_ability_active := false
var has_crystal := false
var has_crystal_saved := false
var has_key := false
var has_key_saved := false

# ============================================================
# NIVEL / SALAS
# ============================================================

func load_level(path: String) -> void:
	# Fade a negro instantáneo
	fade.modulate.a = 1.0
	await get_tree().process_frame  # renderiza un frame completamente negro
	
	if current_level:
		current_level.queue_free()

	var scene = load(path).instantiate()
	current_level = scene
	levelcontainer.add_child(current_level)

	current_level_path = path

	await get_tree().process_frame

	# Spawn
	var spawn := current_level.get_node_or_null(player_spawn_tag)
	if spawn:
		player.global_position = spawn.global_position
	await get_tree().process_frame  

	# Cámara
	var camera := get_tree().current_scene.get_node_or_null("Camera2D")
	if camera and current_level.has_method("apply_camera_limits"):
		current_level.apply_camera_limits(camera)

	await get_tree().process_frame

	# Fade desde negro a visible
	fade.fade_from_black()

# ============================================================
# PICKUPS
# ============================================================

func is_pickup_collected(id: String) -> bool:
	return id in collected_pickups_perm or id in collected_pickups_temp

func collect_pickup(id: String) -> void:
	if id not in collected_pickups_temp:
		collected_pickups_temp.append(id)

# ============================================================
# ENEMIGOS
# ============================================================

func is_enemy_defeated(id: String) -> bool:
	return id in defeated_enemies_perm or id in defeated_enemies_temp

func defeat_enemy(id: String) -> void:
	if id not in defeated_enemies_temp:
		defeated_enemies_temp.append(id)

# ============================================================
# PLATAFORMAS
# ============================================================

func is_platform_activated(id: String) -> bool:
	return id in activated_platforms_temp or id in activated_platforms_perm

func activate_platform(id: String) -> void:
	if id not in activated_platforms_temp:
		activated_platforms_temp.append(id)

# ============================================================
# CHECKPOINT
# ============================================================

func activate_checkpoint(level_path: String, checkpoint_tag: String) -> void:
	current_checkpoint_level = level_path
	current_checkpoint_tag = checkpoint_tag

	# 🔒 TEMP → PERM
	for id in collected_pickups_temp:
		if id not in collected_pickups_perm:
			collected_pickups_perm.append(id)

	for id in defeated_enemies_temp:
		if id not in defeated_enemies_perm:
			defeated_enemies_perm.append(id)
	for id in activated_platforms_temp:
		if id not in activated_platforms_perm:
			activated_platforms_perm.append(id)
	
	has_crystal_saved = has_crystal
	has_key_saved = has_key
	collected_pickups_temp.clear()
	defeated_enemies_temp.clear()
	activated_platforms_temp.clear()
	
	saved_score = score

# ============================================================
# RESPAWN
# ============================================================

func respawn() -> void:
	collected_pickups_temp.clear()
	defeated_enemies_temp.clear()
	activated_platforms_temp.clear()

	score = saved_score
	has_crystal = has_crystal_saved
	has_key = has_key_saved
	wall_ability_active = wall_ability_unlocked

	player.set_physics_process(false)
	player.collision.disabled = true
	player.velocity = Vector2.ZERO

	# Cargar nivel: load_level ya hace el fade a negro
	await load_level(current_checkpoint_level)
	
	# Spawn jugador
	var spawn := current_level.get_node_or_null(current_checkpoint_tag)
	if spawn:
		player.global_position = spawn.global_position

	player.gain_life(player.max_life)
	if hud:
		hud.update_health(player.life)
		hud.update_points()
		hud.update_items()

	player.update_state()
	
	await get_tree().process_frame

	player.set_physics_process(true)
	player.collision.disabled = false

# ============================================================
# NEW GAME / LOAD GAME
# ============================================================

func start_new_game() -> void:
	# Reset global
	score = 0
	saved_score = 0
	level_index = 0

	has_crystal = false
	has_key = false
	has_crystal_saved = false
	has_key_saved = false

	wall_ability_unlocked = false
	wall_ability_active = false

	collected_pickups_temp.clear()
	collected_pickups_perm.clear()
	defeated_enemies_temp.clear()
	defeated_enemies_perm.clear()
	activated_platforms_temp.clear()
	activated_platforms_perm.clear()

	# Checkpoint inicial
	current_checkpoint_level = levels[0]
	current_checkpoint_tag = "Spawn_start"
	player_spawn_tag = "Spawn_start"

	

func load_game(saved_data: Dictionary) -> void:
	# Carga desde un diccionario guardado
	score = saved_data.get("score", 0)
	saved_score = saved_data.get("saved_score", 0)
	level_index = saved_data.get("level_index", 0)

	has_crystal = saved_data.get("has_crystal", false)
	has_key = saved_data.get("has_key", false)
	has_crystal_saved = saved_data.get("has_crystal_saved", false)
	has_key_saved = saved_data.get("has_key_saved", false)

	wall_ability_unlocked = saved_data.get("wall_ability_unlocked", false)
	wall_ability_active = saved_data.get("wall_ability_active", false)

	collected_pickups_perm = saved_data.get("collected_pickups_perm", [])
	defeated_enemies_perm = saved_data.get("defeated_enemies_perm", [])
	activated_platforms_perm = saved_data.get("activated_platforms_perm", [])

	current_checkpoint_level = saved_data.get("checkpoint_level", levels[0])
	current_checkpoint_tag = saved_data.get("checkpoint_tag", "Spawn_start")
	player_spawn_tag = saved_data.get("player_spawn_tag", "Spawn_start")

	respawn()

# ============================================================
# UTILIDADES
# ============================================================

func add_point(value: int) -> void:
	score += value
	if hud:
		hud.update_points()


	#necesita codigo para mensaje en pantalla de jeugo
	

	

#func _process(_delta):
	#if Input.is_action_just_pressed("quitgame"):
			#get_tree().quit()
	#cambiar aqui si el nivel de submit score es otro distinto a 4
	#if level <4:
		#if Input.is_action_just_pressed("pause"):
			#go_how_to_menu()
	

#func go_how_to_menu():
	#if not get_tree().paused:
		#if how_to_play_instance==null:
			#var how_to_scene = preload("res://scenes/how_to_play.tscn")
			#how_to_play_instance = how_to_scene.instantiate()
			#var layer = CanvasLayer.new()
			#get_tree().current_scene.add_child(layer)
			#layer.add_child(how_to_play_instance)
		#get_tree().paused= true
		#print("Paused game and HowTo opened")
	#else:
		#if is_instance_valid(how_to_play_instance):
			#how_to_play_instance.queue_free()
			#how_to_play_instance = null
		#get_tree().paused = false
		#print("Resumed game")
