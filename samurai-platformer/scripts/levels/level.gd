extends Node2D
@export var cam_limit_left : int
@export var cam_limit_top : int
@export var cam_limit_right : int
@export var cam_limit_bottom : int
#@export var uses_crystal := false


#func _ready():
	#if uses_crystal:
		#var crystal := get_node_or_null("Crystal")
		#if crystal:
			#crystal.picked_up.connect(_on_crystal_picked)


func apply_camera_limits(camera: Camera2D):
	camera.limit_left = cam_limit_left
	camera.limit_top = cam_limit_top
	camera.limit_right = cam_limit_right
	camera.limit_bottom = cam_limit_bottom

func _on_crystal_picked():
	GameManager.has_crystal = true
