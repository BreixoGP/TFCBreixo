extends Node2D

@onready var drunkmaster: DrunkMaster = $DrunkMaster
@onready var fade: ColorRect = $CanvasLayer/Fade
@onready var levelcontainer: Node2D = $levelcontainer
@onready var hud: CanvasLayer = $HUD

func _ready():
	# 🔗 Inyectar referencias en GameManager
	GameManager.hud = hud
	GameManager.player = drunkmaster
	GameManager.levelcontainer = levelcontainer
	GameManager.fade = fade

	# 🔒 Player desactivado mientras carga
	drunkmaster.set_physics_process(false)

	# 📍 Checkpoint inicial (SIEMPRE)
	GameManager.current_checkpoint_level = GameManager.levels[0]
	GameManager.current_checkpoint_tag = "Spawn_start"
	GameManager.player_spawn_tag = "Spawn_start"

	# ▶️ Cargar primer nivel usando GameManager
	await GameManager.load_level(GameManager.levels[0])

	# 🎮 Activar player
	drunkmaster.set_physics_process(true)

	# 🧠 HUD
	hud.set_max_health(drunkmaster.life)
	hud.update_health(drunkmaster.life)
	hud.update_points()
