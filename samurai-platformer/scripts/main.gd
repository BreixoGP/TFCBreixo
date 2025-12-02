extends Node2D
@onready var jahmurai: Jahmurai = $Jahmurai
@onready var levelcontainer: Node2D = $levelcontainer


func _ready():
	GameManager.player = jahmurai
	GameManager.levelcontainer=levelcontainer
	GameManager.load_current_level()
	
