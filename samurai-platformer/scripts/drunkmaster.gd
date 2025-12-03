extends CharacterBody2D
class_name DrunkMaster
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D

var life=10
const SPEED = 250.0
const JUMP_VELOCITY = -330.0
const wall_jump_pushback = 100.0
const wall_side_gravity = 100

var is_wall_sliding = false
var is_taking_damage = false

func _physics_process(delta: float) -> void:
	if life <=0:
		return;
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# jump and walljump
	if Input.is_action_just_pressed("jump"):
		_jump()
		
		
	
	var direction := Input.get_axis("move_left", "move_right")
	
	# --- INPUT HORIZONTAL ---
	# actualizar flip correcto temprano
	#if direction != 0:
		#anim.flip_h = direction < 0

	if direction:
		velocity.x = direction * SPEED
		anim.flip_h = direction < 0
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	wallslide(delta)
	move_and_slide()
	update_animation()
	
func _jump():
	if is_on_floor():
		velocity.y = JUMP_VELOCITY
	elif is_on_wall():#aqui capar el walljump si no tiene objeto
		velocity.y = JUMP_VELOCITY
		if Input.is_action_pressed("move_right"):
			velocity.x = -wall_jump_pushback
		elif Input.is_action_pressed("move_left"):
			velocity.x = wall_jump_pushback
			
func wallslide(delta):
	if is_on_wall() and not is_on_floor():#aqui capar el wallslide si no tiene objeto
		if Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right"):
			is_wall_sliding = true
		else:
			is_wall_sliding = false
	else:
		is_wall_sliding = false

	if is_wall_sliding:
		velocity.y += wall_side_gravity * delta
		velocity.y = min(velocity.y, wall_side_gravity)
		
func update_animation():
	var state = get_state()
	
	match state:
		"idle":
			anim.play("idle")
		"jump":
			anim.play("jump")
		"run":
			anim.play("run")
		"fall":
			anim.play("fall")
		"wallslide":
			anim.play("wallslide")
		"die":
			anim.play("die")
		"damage":
			anim.play("damage")
			
func get_state() -> String:
	if life<=0:
		return("die")
	if is_taking_damage:
		return("damage")
	if is_wall_sliding:
		return("wallslide")
	if is_on_floor():
		if velocity.x==0:
			return "idle"
		else:
			return "run"
			
	else:
	
		return "jump"
		
func get_damage(damage: int):
	if life <=0:
		return
	await get_tree().create_timer(0.1).timeout
	life -= damage
	#is_atacking = false
	#GameManager.hud_instance.update_life()
	#audiodamage.play()
	apply_knockback()
	check_life()


func apply_knockback(knockback_strength: float = 1000.0, knockback_time: float = 0.1):
	if is_taking_damage:
		return

	is_taking_damage = true
	anim.modulate = Color(1.0, 0.494, 0.427, 0.635)
	var dir = 1 if anim.flip_h else -1
	velocity.x = dir * knockback_strength

	var t := get_tree().create_timer(knockback_time)
	t.connect("timeout", Callable(self, "_end_knockback"))

func _end_knockback():
	anim.modulate = Color(1,1,1,1)
	velocity.x = 0
	is_taking_damage = false
	

func check_life():
	if life <= 0:
		anim.play("die")
		await get_tree().create_timer(0.5).timeout
		collision.disabled = true
		GameManager.respawn()
		
