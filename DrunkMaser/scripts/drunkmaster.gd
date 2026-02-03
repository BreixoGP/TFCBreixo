extends CharacterBody2D
class_name DrunkMaster

@onready var flipper: Node2D = $flipper
@onready var anim: AnimatedSprite2D = $flipper/AnimatedSprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var punch_hitbox: Area2D = $flipper/punch_hitbox
@onready var kick_hitbox: Area2D = $flipper/kick_hitbox
@onready var dash_hitbox: Area2D = $flipper/dash_hitbox
@onready var blood_particles: CPUParticles2D = $flipper/CanvasLayer/Bloodparticles
@onready var drunk_master: DrunkMaster = $"."
@onready var overlap_area: Area2D = $flipper/overlap_area
@onready var flip_hitbox: Area2D = $flipper/flip_hitbox

# Variables para doble tap
# Variables para doble tap teclado
var last_input_dir := 0
var last_input_time := 0.0
var double_tap_max_time := 0.3  
enum State { IDLE, RUN, JUMP, FALL, WALLSLIDE, PUNCH, KICK, FLIP, DASH, HURT, INTERACT, DEAD }
var state: State = State.IDLE
var attack_timer := 0.0
var attack_cooldown_timer := 0.0
var attack_cooldown := 0.0
var punch_cooldown = 0.1
var kick_cooldown = 0.25
const BASE_MAX_LIFE := 30.0
var max_life := BASE_MAX_LIFE
var life := BASE_MAX_LIFE
const BASE_PUNCH_POWER := 1
const BASE_KICK_POWER := 2
var punch_power = BASE_PUNCH_POWER
var kick_power = BASE_KICK_POWER
var dash_power = 0
var kick_targets_hit: Array = []
var dash_speed := 600.0 
var dash_time := 0.3
var dash_timer := 0.0
var dash_cooldown := 0.5 
var dash_cooldown_timer := 0.0
var dash_direction := Vector2.ZERO
var original_mask := 0  
const MAX_KICK_TARGETS := 3
const SPEED = 220.0
const JUMP_VELOCITY = -330.0
const WALL_JUMP_PUSHBACK = 100.0
const WALL_SLIDE_GRAVITY = 100.0

func _ready():
	if not anim.is_connected("frame_changed", Callable(self, "_on_frame_changed")):
		anim.connect("frame_changed", Callable(self, "_on_frame_changed"))
	apply_permanent_upgrades()
func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return
	if state == State.DASH:
		velocity = dash_direction * dash_speed
		dash_timer -= delta
		if dash_timer <= 0:
			end_dash()

	# ---------------- Timers de ataque ---------------- #
	if attack_timer > 0:
		attack_timer -= delta
		if attack_timer <= 0:
			attack_timer = 0
			# Animación terminó: volver a IDLE y empezar cooldown
			if state in [State.PUNCH, State.KICK, State.FLIP]:
				state = State.IDLE
			attack_cooldown_timer = attack_cooldown

	if attack_cooldown_timer > 0:
		attack_cooldown_timer -= delta
		if attack_cooldown_timer < 0:
			attack_cooldown_timer = 0
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta
		if dash_cooldown_timer < 0:
			dash_cooldown_timer = 0
	# ---------------- Física ---------------- #
	if state != State.DASH and not is_on_floor():
		velocity += get_gravity() * delta

	if state == State.WALLSLIDE:
		velocity.y = min(velocity.y, WALL_SLIDE_GRAVITY)

	handle_input(delta)
	move_and_slide()
	update_state()
	play_animation()
			
func handle_input(_delta):
	if state in [State.DEAD, State.INTERACT]:
		return

	var dir := Input.get_axis("move_left", "move_right")
	var speed_factor = 1.0

	if state == State.HURT:
		speed_factor = 0.3
		# 70% knockback + 30% input
		velocity.x = velocity.x * 0.7 + dir * SPEED * speed_factor
	elif state in [State.PUNCH, State.KICK ,State.FLIP] and is_on_floor():
		# 10% velocidad mientras ataca
		velocity.x = dir * SPEED * 0.1
	else:
		# Movimiento normal
		velocity.x = dir * SPEED * speed_factor

	# Ajuste de dirección del sprite
	if dir != 0:
		flipper.scale.x = abs(flipper.scale.x) if dir > 0 else -abs(flipper.scale.x)

	# Saltos
	if Input.is_action_just_pressed("jump") and state not in [State.PUNCH, State.KICK]:
		_jump()

	# ATAQUES: solo si no hay cooldown ni animación en curso
	if Input.is_action_just_pressed("punch") and attack_timer == 0 and attack_cooldown_timer == 0:
		punch()
	if Input.is_action_just_pressed("kick") and attack_timer == 0 and attack_cooldown_timer == 0:
		kick()
	if Input.is_action_just_pressed("move_left"):
		_check_double_tap(-1)
	elif Input.is_action_just_pressed("move_right"):
		_check_double_tap(1)

	# Botón de dash en gamepad
	if Input.is_action_just_pressed("dash_gamepad"):
		if is_on_floor()or GameManager.dash_upgrade_active and state not in [State.DASH, State.DEAD]:
			start_dash()

	if Input.is_action_just_pressed("interact"):
		interact()


func _jump():
	if is_on_floor():
		velocity.y = JUMP_VELOCITY
	elif state == State.WALLSLIDE:
		velocity.y = JUMP_VELOCITY
		if Input.is_action_pressed("move_right"):
			velocity.x = -WALL_JUMP_PUSHBACK
		elif Input.is_action_pressed("move_left"):
			velocity.x = WALL_JUMP_PUSHBACK
			
func _check_double_tap(dir_pressed: int):
	var current_time = Time.get_ticks_msec() / 1000.0
	if last_input_dir == dir_pressed and (current_time - last_input_time) <= double_tap_max_time:
		if is_on_floor() or GameManager.dash_upgrade_active and state not in [State.DASH, State.DEAD]:
			start_dash()
			last_input_time = 0.0  # reset
	else:
		last_input_time = current_time
		last_input_dir = dir_pressed
# ESTADOS
func update_state():
	if life <= 0:
		state = State.DEAD
		return
	if state in [State.PUNCH, State.KICK, State.HURT,State.INTERACT, State.FLIP, State.DASH]:
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
		State.INTERACT: anim.play("interact")
		State.DEAD: anim.play("die")
		State.FLIP: 
			if anim.animation != "flip":
				anim.play("flip")
		
func _on_frame_changed():
	if state == State.PUNCH and (anim.frame == 2 or anim.frame == 5):
		apply_punch_hit()
	if state == State.KICK:
		kick_hitbox.monitoring = (anim.frame == 4)
	if state == State.FLIP:
		flip_hitbox.monitoring = (anim.frame == 3)
	if state == State.DASH and anim.frame == 1:  # por ejemplo, el frame donde quieres golpear
		dash_hitbox.monitoring = true
	else:
		dash_hitbox.monitoring = false
# DAÑO Y KNOCKBACK
func take_damage(amount: int, from_position: Vector2,attack_type: int):
	disable_attack_hitboxes()
	if life <= 0 or state == State.DASH:
		end_dash()
		return  # ya muerto

	life -= amount
	
	spawn_blood()
	if GameManager.hud:
		GameManager.hud.update_health(life)
		GameManager.hud.shake()
	
	
	if life <= 0:
		disable_attack_hitboxes()
		state = State.DEAD
		anim.play("die")
		await get_tree().create_timer(0.5).timeout
		GameManager.respawn()
	else:
		# Aplica knockback solo si no estás ya en HURT
		if state != State.HURT:
			state = State.HURT
			anim.modulate = Color(0.878, 0.0, 0.0, 0.682)
			anim.play("hurt")
			apply_knockback(amount,from_position,attack_type)
			

func apply_knockback(amount: int,from_position: Vector2,attack_type:int):
	var knockback_strength
	var knockback_time: float = 0.1
	var dir = global_position - from_position
	dir.x = sign(dir.x)  
	
	if attack_type == 0:
		dir.y = 0        
		knockback_strength=250
	elif attack_type == 1:  
		dir.y = -200
		knockback_strength=500      	
	#falta attack ype 2 tal vez un golppe mas fuerte
	elif attack_type == 3:
		dir.y = -1
		knockback_strength = 300
		
	dir = dir.normalized()
	velocity = dir * (knockback_strength * amount) 
	
	# Timer para detener el knockback
	var t = get_tree().create_timer(knockback_time *  amount)
	t.connect("timeout", Callable(self, "_end_knockback"))

func _end_knockback():
	velocity.x = 0
	anim.modulate = Color(1,1,1,1)

	# Solo salir de HURT si no estamos muertos
	if state == State.HURT:
		state = State.IDLE  # luego update_state() puede ajustarlo a RUN, JUMP, etc.
		update_state()
	
#ATAQUES
func punch():
	if state in [State.PUNCH, State.KICK, State.HURT, State.DEAD, State.FLIP]:
		return
	if attack_timer > 0:
		return
	state = State.PUNCH
	anim.play("punch")
	
	var frame_count = anim.sprite_frames.get_frame_count("punch")
	var fps = anim.sprite_frames.get_animation_speed("punch")  # velocidad de la animación
	attack_timer = frame_count / fps  # duración automática
	attack_cooldown=punch_cooldown
func apply_punch_hit():
	punch_hitbox.monitoring = true
	var enemy = get_closest_enemy_in_area(punch_hitbox)
	if enemy:
		enemy.take_damage(punch_power, global_position, 0)
	
	
func kick():
	if state in [State.PUNCH, State.KICK, State.HURT, State.DEAD, State.FLIP]:
		return
	if attack_timer > 0:
		return
	state = State.KICK
	anim.play("kick")
	
	attack_timer = anim.sprite_frames.get_frame_count("kick") / anim.sprite_frames.get_animation_speed("kick")
	kick_targets_hit.clear()
	attack_cooldown=kick_cooldown

func flip():
	if state in [State.PUNCH, State.KICK, State.HURT, State.DEAD, State.FLIP]:
		return
	if not GameManager.flip_ability_active:
		return
	state = State.FLIP
	anim.play("flip")
	
	attack_timer = anim.sprite_frames.get_frame_count("flip") / anim.sprite_frames.get_animation_speed("flip")

func start_dash():
	state = State.DASH
	dash_timer = dash_time
	dash_cooldown_timer = dash_cooldown

	# Guardar mask original y desactivar colisión con enemigos (layer 2)
	original_mask = collision_mask
	collision_mask &= ~(1 << 1)
	if GameManager.dash_upgrade_active:
		dash_power=2
	# Dirección del dash: horizontal
	var dir := Vector2(Input.get_axis("move_left", "move_right"), 0)
	if dir == Vector2.ZERO:
		dir.x = sign(flipper.scale.x)
	dash_direction = dir.normalized()

	anim.play("dash")
	
func end_dash():
	collision_mask = original_mask  # restaurar máscara
	state = State.IDLE
	velocity = Vector2.ZERO

func _on_kick_hitbox_body_entered(body: Node2D) -> void:
	if not (body.is_in_group("Enemies") or body.is_in_group("Destructibles")):
		return
	
	if body in kick_targets_hit:
		return
		
	kick_targets_hit.append(body)	
	
	if kick_targets_hit.size() > MAX_KICK_TARGETS:
		return
	
	body.take_damage(kick_power,global_position,1)
func disable_attack_hitboxes():
	punch_hitbox.monitoring = false
	kick_hitbox.monitoring = false
	flip_hitbox.monitoring = false
func get_closest_enemy_in_area(area: Area2D) -> Node2D:
	var closest = null
	var closest_dist := INF

	for body in area.get_overlapping_bodies():
		if body.is_in_group("Enemies") or body.is_in_group("Destructibles"):
			var dist = global_position.distance_to(body.global_position)
			if dist < closest_dist:
				closest_dist = dist
				closest = body

	return closest
func interact():
	if state in [State.DEAD, State.HURT, State.PUNCH, State.KICK, State.INTERACT]:
		return

	state = State.INTERACT
	velocity.x = 0  # frena al jugador
	anim.play("interact")

	# Esperamos a que termine la animación antes de continuar
	await anim.animation_finished
	state = State.IDLE


func gain_life(amount: int):
	if life >= max_life:
		return
	if (life + amount) >max_life:
		life = max_life
	else:
		life += amount
	if GameManager.hud:
		GameManager.hud.update_health(life)
func spawn_blood():
	if blood_particles:
				# Reiniciamos partículas
		blood_particles.emitting = false
		blood_particles.restart()
		blood_particles.emitting = true
		
func apply_permanent_upgrades():
	var total_attack = GameManager.upgrade_attack_perm + GameManager.upgrade_attack_temp
	punch_power = BASE_PUNCH_POWER + total_attack
	kick_power = BASE_KICK_POWER + total_attack

	var total_life_upgrades = GameManager.upgrade_life_perm + GameManager.upgrade_life_temp
	max_life = BASE_MAX_LIFE + (total_life_upgrades * 10) # +10
	life = round((life/ BASE_MAX_LIFE) * max_life)

	if GameManager.hud:
			GameManager.hud.set_max_health(max_life)
			GameManager.hud.update_health(life)


func _on_flip_hitbox_body_entered(body: Node2D) -> void:
	if not (body.is_in_group("Enemies") or body.is_in_group("Destructibles")):
		return
	body.take_damage(30,global_position,3) #de moemnto hardcodeado falta variable


func _on_dash_hitbox_body_entered(body: Node2D) -> void:
	if not body.is_in_group("Enemies") or dash_power == 0:
		return
	
	body.take_damage(dash_power, global_position, 1)
