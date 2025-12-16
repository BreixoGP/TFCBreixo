extends CharacterBody2D
class_name DrunkMaster

@onready var flipper: Node2D = $flipper
@onready var anim: AnimatedSprite2D = $flipper/AnimatedSprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var punch_hitbox: Area2D = $flipper/punch_hitbox
@onready var kick_hitbox: Area2D = $flipper/kick_hitbox


enum State { IDLE, RUN, JUMP, FALL, WALLSLIDE, PUNCH, KICK, HURT, DEAD }
var state: State = State.IDLE
var attack_timer := 0.0
var life = 10
var punch_power = 1
var kick_power = 2 
const SPEED = 250.0
const JUMP_VELOCITY = -330.0
const WALL_JUMP_PUSHBACK = 100.0
const WALL_SLIDE_GRAVITY = 100.0

func _ready():
	if not anim.is_connected("frame_changed", Callable(self, "_on_frame_changed")):
		anim.connect("frame_changed", Callable(self, "_on_frame_changed"))
	
func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return

	# Aplicar gravedad siempre
	if not is_on_floor():
		velocity += get_gravity() * delta
	# WALL SLIDE
	if state == State.WALLSLIDE:
		velocity.y = min(velocity.y, WALL_SLIDE_GRAVITY)
	# Llamamos a handle_input que decide todo lo relacionado con inputs
	handle_input(delta)

	# Mover el personaje
	move_and_slide()

	# Actualizar estado y animaciones
	update_state()
	play_animation()

	# Manejo de ataque por timer
	if state in [State.PUNCH, State.KICK]:
		attack_timer -= delta
		if attack_timer <= 0:
			state = State.IDLE
			punch_hitbox.monitoring = false
			kick_hitbox.monitoring = false


func handle_input(_delta):
	if state in [State.HURT, State.DEAD]:
		return

	var dir := Input.get_axis("move_left", "move_right")

	# Movimiento lateral
	if state in [State.PUNCH, State.KICK] and is_on_floor():
		velocity.x = 0  # bloqueado en suelo durante ataque
	else:
		velocity.x = dir * SPEED if dir != 0 else move_toward(velocity.x, 0, SPEED)
		if dir != 0:
			flipper.scale.x = abs(flipper.scale.x) if dir > 0 else -abs(flipper.scale.x)

	# Saltos
	if Input.is_action_just_pressed("jump") and state not in [State.PUNCH, State.KICK]:
		_jump()

	# Ataques
	if Input.is_action_just_pressed("punch"):
		punch()
	if Input.is_action_just_pressed("kick"):
		kick()

func _jump():
	if is_on_floor():
		velocity.y = JUMP_VELOCITY
	elif state == State.WALLSLIDE:
		velocity.y = JUMP_VELOCITY
		if Input.is_action_pressed("move_right"):
			velocity.x = -WALL_JUMP_PUSHBACK
		elif Input.is_action_pressed("move_left"):
			velocity.x = WALL_JUMP_PUSHBACK


# ESTADOS
func update_state():
	if life <= 0:
		state = State.DEAD
		return
	if state in [State.PUNCH, State.KICK]:
		return
	if is_on_wall() and not is_on_floor() and (Input.is_action_pressed("move_left")
	 or Input.is_action_pressed("move_right")) and GameManager.wall_ability_active:
		state = State.WALLSLIDE
		return
	if not is_on_floor():
		state = State.JUMP if velocity.y < 0 else State.FALL
		return
	else:
		state = State.RUN if velocity.x != 0 else State.IDLE
		return

# ANIMACIONES
func play_animation():
	match state:
		State.IDLE: anim.play("idle")
		State.RUN: anim.play("run")
		State.JUMP: anim.play("jump")
		State.FALL: anim.play("fall")
		State.WALLSLIDE: anim.play("wallslide")
		State.PUNCH: 
			if anim.animation != "punch":
				anim.play("punch")
		State.KICK:
			if anim.animation != "kick":
				anim.play("kick")
		State.HURT: anim.play("hurt")
		State.DEAD: anim.play("die")
		
func _on_frame_changed():
	if state == State.PUNCH:
		punch_hitbox.monitoring = (anim.frame == 2 or anim.frame == 5)

	if state == State.KICK:
		kick_hitbox.monitoring = (anim.frame == 3)
		
# DAÑO Y KNOCKBACK
func take_damage(amount: int, from_position: Vector2,attack_type: int):
	if life <= 0:
		return  # ya muerto

	life -= amount
	if GameManager.hud:
		GameManager.hud.update_health(life)
		GameManager.hud.shake()
	
	
	if life <= 0:
		state = State.DEAD
		anim.play("die")
		await get_tree().create_timer(0.5).timeout
		GameManager.respawn()
	else:
		# Aplica knockback solo si no estás ya en HURT
		if state != State.HURT:
			state = State.HURT
			anim.modulate = Color(0.878, 0.0, 0.0, 0.682)
			apply_knockback(amount,from_position,attack_type)


func apply_knockback(amount: int,from_position: Vector2,attack_type:int, knockback_strength: float = 400.0, knockback_time: float = 0.2):
	var dir = global_position - from_position
	dir.x = sign(dir.x)  

	if attack_type == 1:  
		dir.y = -0.5       
	elif attack_type == 0:
		dir.y = 0        
	elif attack_type == 3:
		dir.y = -1
		dir.x *= 1.5
	dir = dir.normalized()
	velocity = dir * (knockback_strength * amount) 
	
	# Timer para detener el knockback
	var t = get_tree().create_timer(knockback_time *  amount)
	t.connect("timeout", Callable(self, "_end_knockback"))

func _end_knockback():
	anim.modulate = Color(1,1,1,1)
	velocity.x = 0
	update_state()
	
#ATAQUES
func punch():
	if state in [State.PUNCH, State.KICK, State.HURT, State.DEAD]:
		return
	state = State.PUNCH
	anim.play("punch")
	
	var frame_count = anim.sprite_frames.get_frame_count("punch")
	var fps = anim.sprite_frames.get_animation_speed("punch")  # velocidad de la animación
	attack_timer = frame_count / fps  # duración automática

func kick():
	if state in [State.PUNCH, State.KICK, State.HURT, State.DEAD]:
		return
	state = State.KICK
	anim.play("kick")
	
	var frame_count = anim.sprite_frames.get_frame_count("kick")
	var fps = anim.sprite_frames.get_animation_speed("kick")
	attack_timer = frame_count / fps



func _on_punch_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("Enemies"):
		body.take_damage(punch_power,global_position,0)


func _on_kick_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("Enemies"):
		body.take_damage(kick_power,global_position,1)
