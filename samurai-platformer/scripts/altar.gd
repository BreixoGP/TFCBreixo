extends Area2D
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@export var id: String
@export var platform_path: NodePath
var platform
var used = false

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
	if used:
		return
		
	if body is DrunkMaster:
		if GameManager.has_crystal:
			activate()
			consume_crystal()
			GameManager.activate_platform(id)
			
				
		else:
			anim.play("fail")
			
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
	GameManager.hud.update_items()
