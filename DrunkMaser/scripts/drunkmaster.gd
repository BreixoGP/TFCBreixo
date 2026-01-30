extends CharacterBody2D
class_name DrunkMaster

@onready var flipper: Node2D = $flipper
@onready var anim: AnimatedSprite2D = $flipper/AnimatedSprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var punch_hitbox: Area2D = $flipper/punch_hitbox
@onready var kick_hitbox: Area2D = $flipper/kick_hitbox
@onready var blood_particles: CPUParticles2D = $flipper/Bloodparticles
@onready var overlap_area: Area2D = $flipper/overlap_area

var inside_enemy_time := 0.0
const ENEMY_FRICTION := 0.6
const CHIP_DAMAGE_TIME := 0.6

enum State { IDLE, RUN, JUMP, FALL, WALLSLIDE, PUNCH, KICK, HURT, DEAD }
var state: State = State.IDLE
var attack_timer := 0.0
const BASE_MAX_LIFE := 30.0
var max_life := BASE_MAX_LIFE
var life := BASE_MAX_LIFE
const BASE_PUNCH_POWER := 1
const BASE_KICK_POWER := 2
var punch_power = BASE_PUNCH_POWER
var kick_power = BASE_KICK_POWER
var kick_targets_hit: Array = []
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

	# Aplicar gravedad siempre
	if not is_on_floor():
		velocity += get_gravity() * delta
	# WALL SLIDE
	if state == State.WALLSLIDE:
		velocity.y = min(velocity.y, WALL_SLIDE_GRAVITY)
	# Llamamos a handle_input que decide todo lo relacionado con inputs
	handle_input(delta)
	# --- Penalización por atravesar enemigos ---
	if is_inside_enemy():
		inside_enemy_time += delta

		# Fricción horizontal
		if state not in [State.PUNCH, State.KICK, State.JUMP]:
			velocity.x *= ENEMY_FRICTION

		# Daño suave si se queda demasiado
		if inside_enemy_time >= CHIP_DAMAGE_TIME:
			take_damage(1, global_position, 0)
			inside_enemy_time = 0.0
	else:
		inside_enemy_time = 0.0
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
			#punch_hitbox.monitoring = false
			kick_hitbox.monitoring = false


func handle_input(_delta):
	if state == State.DEAD:
		return

	var dir := Input.get_axis("move_left", "move_right")
	var speed_factor = 1.0
	if state == State.HURT:
		speed_factor = 0.3  # 30% de la velocidad normal
	# Movimiento lateral
	if state in [State.PUNCH, State.KICK] and is_on_floor():
		velocity.x = dir * SPEED if dir != 0 else move_toward(velocity.x, 0, SPEED)
		velocity.x *= 0.1
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

func is_inside_enemy() -> bool:
	return overlap_area.get_overlapping_bodies().size() > 0

# ESTADOS
func update_state():
	if life <= 0:
		state = State.DEAD
		return
	if state in [State.PUNCH, State.KICK, State.HURT]:
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
	if state == State.PUNCH and (anim.frame == 2 or anim.frame == 5):
		apply_punch_hit()

	if state == State.KICK:
		kick_hitbox.monitoring = (anim.frame == 3)

		
# DAÑO Y KNOCKBACK
func take_damage(amount: int, from_position: Vector2,attack_type: int):
	disable_attack_hitboxes()
	if life <= 0:
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
			

func apply_knockback(amount: int,from_position: Vector2,attack_type:int, knockback_strength: float = 75.0, knockback_time: float = 0.1):
	var dir = global_position - from_position
	dir.x = sign(dir.x)  

	 
	if attack_type == 0:
		dir.y = 0        
		knockback_strength=50
	elif attack_type == 1:  
		dir.y = -0.5
		knockback_strength=75      	
	#falta attack ype 2 tal vez un golppe mas fuerte
	elif attack_type == 3:
		dir.y = -1
		dir.x *= 3
		knockback_strength = 200
		
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
	if state in [State.PUNCH, State.KICK, State.HURT, State.DEAD]:
		return
	state = State.PUNCH
	anim.play("punch")
	
	var frame_count = anim.sprite_frames.get_frame_count("punch")
	var fps = anim.sprite_frames.get_animation_speed("punch")  # velocidad de la animación
	attack_timer = frame_count / fps  # duración automática
	
func apply_punch_hit():
	punch_hitbox.monitoring = true
	var enemy = get_closest_enemy_in_area(punch_hitbox)
	if enemy:
		enemy.take_damage(punch_power, global_position, 0)
	
	
	

func kick():
	if state in [State.PUNCH, State.KICK, State.HURT, State.DEAD]:
		return
		
	state = State.KICK
	anim.play("kick")
	
	attack_timer = anim.sprite_frames.get_frame_count("kick") / anim.sprite_frames.get_animation_speed("kick")
	kick_targets_hit.clear()

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
