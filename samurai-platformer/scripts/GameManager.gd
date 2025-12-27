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

# PERMANENTE (checkpoint)
var collected_pickups_perm: Array[String] = []
var defeated_enemies_perm: Array[String] = []

# ============================================================
# HABILIDADES
# ============================================================

var wall_ability_unlocked := false
var wall_ability_active := false
var has_crystal := false

# ============================================================
# NIVEL / SALAS
# ============================================================

func load_current_level() -> void:
	await load_level(levels[level_index])

func load_next_level():
	if level_index >= levels.size() - 1:
		return

	level_index += 1
	wall_ability_active = wall_ability_unlocked
	saved_score = score
	await load_level(levels[level_index])

func load_level(path: String) -> void:
	fade.fade_to_black()
	await get_tree().process_frame

	if current_level:
		current_level.queue_free()

	var scene = load(path)
	current_level = scene.instantiate()
	levelcontainer.add_child(current_level)

	current_level_path = path

	await get_tree().process_frame

	# Spawn
	var spawn := current_level.get_node_or_null(player_spawn_tag)
	if spawn:
		player.global_position = spawn.global_position

	# Cámara
	var camera := get_tree().current_scene.get_node_or_null("Camera2D")
	if camera and current_level.has_method("apply_camera_limits"):
		current_level.apply_camera_limits(camera)

	await fade.fade_from_black()

# ============================================================
# PICKUPS (GLOBAL)
# ============================================================

func is_pickup_collected(id: String) -> bool:
	return id in collected_pickups_perm or id in collected_pickups_temp

func collect_pickup(id: String) -> void:
	if id not in collected_pickups_temp:
		collected_pickups_temp.append(id)

# ============================================================
# ENEMIGOS (GLOBAL)
# ============================================================

func is_enemy_defeated(id: String) -> bool:
	return id in defeated_enemies_perm or id in defeated_enemies_temp

func defeat_enemy(id: String) -> void:
	if id not in defeated_enemies_temp:
		defeated_enemies_temp.append(id)

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

	collected_pickups_temp.clear()
	defeated_enemies_temp.clear()

	saved_score = score

# ============================================================
# RESPAWN (MUERTE)
# ============================================================

func respawn(is_new_game := false) -> void:
	fade.fade_to_black()
	await get_tree().create_timer(1.2).timeout

	# ❌ perder progreso temporal
	collected_pickups_temp.clear()
	defeated_enemies_temp.clear()

	if not is_new_game:
		score = saved_score

	wall_ability_active = wall_ability_unlocked

	player.set_physics_process(false)
	player.collision.disabled = true
	player.velocity = Vector2.ZERO

	await load_level(current_checkpoint_level)

	var spawn := current_level.get_node_or_null(current_checkpoint_tag)
	if spawn:
		player.global_position = spawn.global_position

	player.life = 10
	if hud:
		hud.update_health(player.life)
		hud.update_points()

	player.update_state()
	await get_tree().process_frame

	player.set_physics_process(true)
	player.collision.disabled = false

	await fade.fade_from_black()

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
