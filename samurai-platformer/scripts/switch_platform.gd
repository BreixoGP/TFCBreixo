extends AnimatableBody2D

@export var point_a: Vector2
@export var point_b: Vector2
@export var speed: float = 100.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var moving_to_b = true
var moving_enabled = false

func _ready() -> void:
	position = point_a

func activate():
	moving_enabled = true
	anim.play("on")

func _process(delta: float) -> void:
	if not moving_enabled:
		return
	
	var target: Vector2
	if moving_to_b:
		target = point_b
	else:
		target = point_a
	
	position = position.move_toward(target, speed * delta)
	
	if position.distance_to(target) < 1.0:
		moving_to_b = not moving_to_b
