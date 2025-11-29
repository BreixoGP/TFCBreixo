extends CharacterBody2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

const SPEED = 250.0
const JUMP_VELOCITY = -300.0


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	
	
	var direction := Input.get_axis("ui_left", "ui_right")
	
	# --- INPUT HORIZONTAL ---
	# actualizar flip correcto temprano
	if direction != 0:
		anim.flip_h = direction < 0

	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
