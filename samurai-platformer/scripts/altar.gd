extends Area2D
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

@export var platform_path: NodePath
var platform
var used = false
func _ready():
	if platform_path != NodePath():
		platform = get_node(platform_path)
	anim.animation_finished.connect(_on_animation_finished)
func _on_body_entered(body: Node2D) -> void:
	if used:
		return
		
	if body is DrunkMaster:
		if GameManager.has_crystal:
			if platform and platform.has_method("activate"):
				used = true
				platform.activate()
				anim.play("on")
				consume_crystal()
				
		else:
			anim.play("fail")
			
func _on_animation_finished():
	if anim.animation == "fail":
		anim.play("off")
func consume_crystal():
	GameManager.has_crystal = false
