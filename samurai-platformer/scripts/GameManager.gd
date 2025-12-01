extends Node

#var player: Kitsune = null
var score: int = 0
var saved_score: int = 0
var is_loading_game : bool = false
var level: int = 1
var how_to_play_instance: Node = null
var options_menu_instance:Node = null
#const player_scene = preload("res://scenes/kitsune.tscn")
#const HUD_SCENE = preload("res://scenes/lifeandpoints.tscn")

#var hud_instance: LifePoints = null
func _ready() -> void:
	pass


func add_point(value:int):
	score+=1*value
	print("you won "+str(value) +" points")
	print("Score: "+str(score))
	#hud_instance.update_points()
	#life_points.update_points()
	#necesita codigo para mensaje en pantalla de jeugo
	
	
#func show_hud(actual_scene:Node):
	#if is_instance_valid(hud_instance):
		#return
	#hud_instance=HUD_SCENE.instantiate()
	#actual_scene.add_child(hud_instance)
	
#func get_hud():
	#return hud_instance
	
func _process(_delta):
	if Input.is_action_just_pressed("quitgame"):
			get_tree().quit()
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
