extends Node

var levels = ["res://scenes/castle/level_1.tscn",
"res://scenes/castle/level_2.tscn","res://scenes/castle/level_3.tscn"]
@onready var fade: ColorRect
var hud: Node = null

var level_index= 0
var player: Node=null #instanciamos player nulo, en main en ready se asigna
var has_crystal = false #crystal para activar plataformas con altar
var levelcontainer : Node = null
var current_level : Node = null 
var score: int = 0
var saved_score: int = 0
var is_loading_game : bool = false
#var level: int = 1
var how_to_play_instance: Node = null
var options_menu_instance:Node = null

#habilidades drukmaster
var wall_ability_unlocked: bool = false   # permanente
var wall_ability_active: bool = false     # intento actual



func _ready() -> void:
	pass


func load_current_level():
		load_level(levels[level_index])
func load_next_level():
	#control de wallslide
	if level_index == 2 and wall_ability_active:
		wall_ability_unlocked = true
	level_index += 1
	wall_ability_active = wall_ability_unlocked
	load_level(levels[level_index])
	saved_score = score
	
func respawn():
		#aqui controlar el score tambien
		fade.fade_to_black()
		await get_tree().create_timer(1.5).timeout
		score = saved_score
		wall_ability_active = wall_ability_unlocked
		player.set_physics_process(false)
		player.collision.disabled = true
		player.velocity = Vector2.ZERO
		has_crystal = false
		load_level(levels[level_index])
		
		player.life = 10
		if hud:
			hud.update_health(player.life)
			hud.update_points()
		player.update_state()
		await get_tree().process_frame
		player.set_physics_process(true)
		player.collision.disabled = false
		
func load_level(path : String):
	fade.fade_to_black()
	if current_level:
		current_level.queue_free()
		
	var scene = load (path)
	current_level = scene.instantiate()
	levelcontainer.add_child(current_level)
	var spawn = current_level.get_node("Spawn")
	player.global_position = spawn.global_position

	# APLICAR LÍMITES A LA CÁMARA
	var camera = get_tree().current_scene.get_node("Camera2D")
	if current_level.has_method("apply_camera_limits"):
		current_level.apply_camera_limits(camera)
	fade.fade_from_black()
	
func add_point(value:int):
	score += 1*value
	print("you won "+str(value) +" points")
	print("Score: "+str(score))
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
