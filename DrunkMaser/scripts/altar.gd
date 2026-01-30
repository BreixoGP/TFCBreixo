extends Area2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@export var id: String
@export var platform_path: NodePath
var platform
var used = false
var player_inside := false
var player_ref : Node = null
var altar_busy := false  # Evita activaciones simultáneas

func _ready():
	if platform_path != NodePath():
		platform = get_node(platform_path)
	anim.animation_finished.connect(_on_animation_finished)

	if id == "":
		push_error("sin ID: " + name)
		return

	if GameManager.is_platform_activated(id):
		call_deferred("activate")

func _on_body_entered(body: Node2D) -> void:
	if body is DrunkMaster:
		player_inside = true
		player_ref = body

func _on_body_exited(body: Node2D) -> void:
	if body == player_ref:
		player_inside = false
		player_ref = null

func _physics_process(delta: float) -> void:
	if player_inside and not altar_busy and Input.is_action_just_pressed("interact"):
		if used:
			return
		altar_busy = true
		if GameManager.has_crystal:
			activate()
			consume_crystal()
			GameManager.activate_platform(id)
		else:
			anim.play("fail")
		altar_busy = false

func activate():
	if platform and platform.has_method("activate"):
		used = true
		platform.activate()
		anim.play("on") 

func _on_animation_finished():
	if anim.animation == "fail":
		anim.play("off")

func consume_crystal():
	GameManager.has_crystal = false
	if GameManager.hud:
		GameManager.hud.update_items()
