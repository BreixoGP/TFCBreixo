extends Node2D

@onready var drunkmaster: DrunkMaster = $DrunkMaster
@onready var fade: ColorRect = $CanvasLayer/Fade
@onready var levelcontainer: Node2D = $levelcontainer
@onready var hud: CanvasLayer = $HUD
@onready var camera: Camera2D = $Camera2D

func _ready():
	# Inyectar referencias en GameManager
	GameManager.hud = hud
	GameManager.player = drunkmaster
	GameManager.levelcontainer = levelcontainer
	GameManager.fade = fade
	
	# Player desactivado mientras carga
	drunkmaster.set_physics_process(false)

	# Checkpoint inicial (si no hay partida cargada)
	if GameManager.current_checkpoint_level == "":
		GameManager.current_checkpoint_level = GameManager.levels[0]
		GameManager.current_checkpoint_tag = "Spawn_start"
		GameManager.player_spawn_tag = "Spawn_start"

	# ▶️ Cargar nivel actual
	await GameManager.load_level(GameManager.current_checkpoint_level)

	# 🎮 Activar player
	drunkmaster.set_physics_process(true)

	# HUD
	hud.set_max_health(drunkmaster.life)
	hud.update_health(drunkmaster.life)
	hud.update_points()
