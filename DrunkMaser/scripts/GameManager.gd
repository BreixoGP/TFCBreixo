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
var pause_menu : Node = null
var player: Node = null
var start_new_game_flag := false
var load_game_flag := false
var pause_enabled := true
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
# PROGRESO GLOBAL
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
var upgrade_attack_temp := 0
var upgrade_attack_perm := 0
var upgrade_life_temp := 0
var upgrade_life_perm := 0
var crow_defeated_temp := false
var crow_defeated_perm := false
# ============================================================
# NIVEL / SALAS
# ============================================================
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
func load_level(path: String, spawn_tag: String = "") -> void:
	# Si se pasa un spawn_tag, lo usamos
	if spawn_tag != "":
		player_spawn_tag = spawn_tag
	if player:
		
		player.set_physics_process(false)
		player.collision.disabled = true
		player.velocity = Vector2.ZERO
	# Fade a negro instantáneo
	hud.visible = false 
	fade.modulate.a = 1.0
	await get_tree().process_frame

	# Liberar nivel anterior
	if current_level:
		current_level.queue_free()

	# Instanciar nuevo nivel
	var scene = load(path)
	current_level = scene.instantiate()
	levelcontainer.add_child(current_level)
	current_level_path = path

	await get_tree().process_frame

	# Colocar jugador en spawn
	var spawn := current_level.get_node_or_null(player_spawn_tag)
	if spawn and player:
		player.global_position = spawn.global_position

	await get_tree().process_frame

	# Configurar cámara si el nivel tiene límites
	var camera := get_tree().current_scene.get_node_or_null("Camera2D")
	if camera and current_level.has_method("apply_camera_limits"):
		current_level.apply_camera_limits(camera)

	await get_tree().process_frame

	# Fade de negro a transparente
	fade.fade_from_black()
	hud.visible = true 
	if player:
		player.set_physics_process(true)
		player.collision.disabled = false
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

	# Convertir temporal → permanente
	for id in collected_pickups_temp:
		if id not in collected_pickups_perm:
			collected_pickups_perm.append(id)
	for id in defeated_enemies_temp:
		if id not in defeated_enemies_perm:
			defeated_enemies_perm.append(id)
	for id in activated_platforms_temp:
		if id not in activated_platforms_perm:
			activated_platforms_perm.append(id)

	# Guardar habilidades permanentes/items
	has_crystal_saved = has_crystal
	has_key_saved = has_key
	wall_ability_unlocked = wall_ability_active 
	upgrade_attack_perm = upgrade_attack_temp
	crow_defeated_perm = crow_defeated_temp
	upgrade_attack_temp = 0
	upgrade_life_perm = upgrade_life_temp
	upgrade_life_temp = 0
	collected_pickups_temp.clear()
	defeated_enemies_temp.clear()
	activated_platforms_temp.clear()

	saved_score = score

	# Guardado automático
	save_game()

# ============================================================
# RESPAWN (MUERTE)
# ============================================================
func respawn():
	collected_pickups_temp.clear()
	defeated_enemies_temp.clear()
	activated_platforms_temp.clear()
	
	score = saved_score
	has_crystal = has_crystal_saved
	has_key = has_key_saved
	wall_ability_active = wall_ability_unlocked
	upgrade_attack_temp = 0
	upgrade_life_temp = 0
	crow_defeated_temp = crow_defeated_perm
	
	hud.visible = false
	
	if player:
		player.set_physics_process(false)
		player.collision.disabled = true
		player.velocity = Vector2.ZERO

	await load_level(current_checkpoint_level,current_checkpoint_tag)
	#var spawn := current_level.get_node_or_null(current_checkpoint_tag) 
	#if spawn and player: 
		#player.global_position = spawn.global_position

	if player:
		player.apply_permanent_upgrades()
		player.gain_life(player.max_life)
		player.update_state()
		player.set_physics_process(true)
		player.collision.disabled = false
		
	if hud:
		hud.update_health(player.life)
		hud.update_points()
		hud.update_items()

# ============================================================
# NUEVA PARTIDA
# ============================================================


func start_new_game() -> void:
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
	defeated_enemies_temp.clear()
	activated_platforms_temp.clear()
	collected_pickups_perm.clear()
	defeated_enemies_perm.clear()
	activated_platforms_perm.clear()

	current_checkpoint_level = levels[0]
	current_checkpoint_tag = "Spawn_start"
	player_spawn_tag = "Spawn_start"

	# Esperamos a que las referencias existan
	if not player or not levelcontainer or not fade:
		print(" GameManager no tiene referencias inyectadas aún")
		return

	await load_level(current_checkpoint_level)


# ============================================================
# GUARDAR / CARGAR PARTIDA
# ============================================================
func save_game():
	var save_data = {
		"score": score,
		"has_crystal": has_crystal,
		"has_key": has_key,
		"wall_ability_unlocked": wall_ability_unlocked,
		"wall_ability_active": wall_ability_active,
		"collected_pickups_perm": collected_pickups_perm,
		"defeated_enemies_perm": defeated_enemies_perm,
		"activated_platforms_perm": activated_platforms_perm,
		"current_checkpoint_level": current_checkpoint_level,
		"current_checkpoint_tag": current_checkpoint_tag,
		"upgrade_attack_perm": upgrade_attack_perm,
		"crow_defeated_perm": crow_defeated_perm,
		"upgrade_life_perm": upgrade_life_perm,
		

	}

	var file = FileAccess.open("user://savegame.save", FileAccess.WRITE)
	file.store_var(save_data)
	file.close()

func load_game():
	if not FileAccess.file_exists("user://savegame.save"):
		return

	var file = FileAccess.open("user://savegame.save", FileAccess.READ)
	var save_data = file.get_var()
	file.close()

	# Restaurar datos guardados
	score = save_data["score"]
	has_crystal = save_data["has_crystal"]
	has_key = save_data["has_key"]
	wall_ability_unlocked = save_data["wall_ability_unlocked"]
	wall_ability_active = save_data["wall_ability_active"]
	collected_pickups_perm = save_data["collected_pickups_perm"]
	defeated_enemies_perm = save_data["defeated_enemies_perm"]
	activated_platforms_perm = save_data["activated_platforms_perm"]
	current_checkpoint_level = save_data["current_checkpoint_level"]
	current_checkpoint_tag = save_data["current_checkpoint_tag"]
	upgrade_attack_perm = save_data.get("upgrade_attack_perm", 0)
	upgrade_attack_temp = 0
	upgrade_life_perm = save_data.get("upgrade_life_perm", 0)
	upgrade_life_temp = 0
	crow_defeated_perm = save_data["crow_defeated_perm"]
	

	# Sincronizar player_spawn_tag con checkpoint
	player_spawn_tag = current_checkpoint_tag

	# Cargar nivel usando spawn del checkpoint
	await load_level(current_checkpoint_level, current_checkpoint_tag)
	if hud and player:
		hud.update_points()
		hud.update_items()
		hud.update_health(player.life)
		player.apply_permanent_upgrades()
# ============================================================
# UTILIDADES
# ============================================================
func add_point(value: int) -> void:
	score += value
	if hud:
		hud.update_points()
	#necesita codigo para mensaje en pantalla de jeugo
	
func _input(event):
	if not pause_enabled:
		return
	if event.is_action_pressed("pause"):
		if get_tree().paused:
			resume_game()
		else:
			pause_game()

func pause_game():
	get_tree().paused = true
	hud.visible = false 
	pause_menu.update_skills_display()
	pause_menu.visible = true
	
func resume_game():
	get_tree().paused = false
	hud.visible = true
	pause_menu.visible = false
