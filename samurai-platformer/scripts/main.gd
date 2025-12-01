extends Node2D
@onready var jahmurai: Jahmurai = $Jahmurai
@onready var levelcontainer: Node2D = $levelcontainer

var current_level: Node = null
# Called when the node enters the scene tree for the first time.

func load_level(path: String):
	if current_level:
		current_level.queue_free()
	
	var level_scene = load(path)
	current_level = level_scene.instantiate()
	
	levelcontainer.add_child(current_level)
	var spawn=current_level.get_node("Spawn")
	jahmurai.global_position = spawn.global_position
