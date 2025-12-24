extends CharacterBody2D

@onready var flipper: Node2D = $Flipper
@onready var anim: AnimatedSprite2D = $Flipper/AnimatedSprite2D
@onready var raywall: RayCast2D = $Flipper/raywall
@onready var rayfloor: RayCast2D = $Flipper/rayfloor
@onready var rayspikes: RayCast2D = $Flipper/rayspikes
@onready var rayattack: RayCast2D = $Flipper/rayattack
@onready var enemy_detection_area: Area2D = $enemy_detection_area
@onready var enemy_avoid_area: Area2D = $Flipper/enemy_avoid_area


@onready var attack_hitbox: Area2D = $Flipper/attack_hitbox
@onready var hurtbox: CollisionShape2D = $hurtbox
@onready var head_hitbox: Area2D = $Flipper/head_hitbox


#ESTO PERTENECE AL SISTEA DE STATE CHASE PARA EVITAR UQE SE QUEDE CONGELADO SOBRE EL PLAYER CON IMAGEN DOBLE
#var stuck_time := 0.0
#const STUCK_LIMIT := 0.4  # segundos BORRAR SI NO LO USO

enum State { IDLE, PATROL, CHASE, READY, ATTACK,HEAD, HURT, DEAD }
var state: State = State.IDLE
var direction = -1
var life = 5
var attack_power = 1
var patrol_time = 0.0
const SPEED = 150.0
const MAX_VERTICAL_DIFF := 40.0
var attack_cooldown = 1.0 
var attack_timer = 0.0
var head_timer_started = false

func _ready():
	state = State.IDLE
	play_anim("idle")


func _physics_process(delta: float) -> void:
	
	if state == State.DEAD:
		state_dead(delta)
	else:
		attack_timer = max(attack_timer - delta, 0)
		proccess_state(delta)

	move_and_slide()
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		velocity.y = 0


func play_anim(anim_name: String):
	if anim.animation != anim_name:
		anim.play(anim_name)


func proccess_state(delta):
	match state:
		State.IDLE: state_idle(delta)
		State.PATROL: state_patrol(delta)
		State.CHASE: state_chase(delta)
		State.READY: state_ready(delta)
		State.ATTACK: state_attack(delta)
		State.HEAD: state_head(delta)
		State.HURT: state_hurt(delta)
		State.DEAD: state_dead(delta)

func state_idle(_delta):
	play_anim("idle")
	velocity.x = 0

func state_patrol(_delta):
	if patrol_time <= 0.0:
		patrol_time = randf_range(5.0, 10.0)

	play_anim("patrol")

	var separation := apply_enemy_separation(_delta)
	velocity.x = direction * SPEED + separation.x

	if should_turn():
		turn()

	patrol_time -= _delta
	if patrol_time <= 0.0:
		state = State.IDLE

func state_chase(_delta):
	if state == State.HURT:
		return

	play_anim("chase")

	if not GameManager.player:
		state = State.IDLE
		return

	var dx: float = GameManager.player.global_position.x - global_position.x
	set_direction(sign(dx))

	# Velocidad base hacia el jugador
	velocity.x = direction * SPEED * 1.3

	#  Separación entre enemigos
	var separation := apply_enemy_separation(_delta)
	velocity += separation

	# Obstáculos
	var can_move := rayfloor.is_colliding() \
		and not raywall.is_colliding() \
		and not rayspikes.is_colliding()

	if not can_move:
		velocity.x = 0
		state = State.IDLE
		return

	# Ataque
	if rayattack.is_colliding():
		state = State.READY



func state_ready(_delta):
	if state != State.HURT:
		velocity.x = 0
		play_anim("ready")
		if attack_timer == 0:
			state = State.ATTACK

func state_attack(_delta):
	if state != State.HURT:
		velocity.x = 0
		play_anim("attack")
		if anim.frame == 2 or anim.frame == 6:
			attack_hitbox.monitoring = true
		else:
			attack_hitbox.monitoring = false
		var frames = anim.sprite_frames.get_frame_count("attack")
		if anim.frame == frames - 1:
			state = State.CHASE
			attack_timer = attack_cooldown

func state_head(_delta):
	velocity.x = 0
	play_anim("head")
	
	var frames = anim.sprite_frames.get_frame_count("head")
	var fps = anim.sprite_frames.get_animation_speed("head")
	if fps > 0:
		var t = Timer.new()
		t.wait_time = frames / fps
		t.one_shot = true
		t.connect("timeout", Callable(self, "_on_head_timer_timeout"))
		add_child(t)
		t.start()
		
func state_hurt(_delta):
	play_anim("hurt")
	# El knockback se aplica mientras está en HURT
	# Bloquea cualquier movimiento hasta que toque suelo y velocidad horizontal casi 0
	if is_on_floor() and abs(velocity.x) < 1.0:
		velocity = Vector2.ZERO
		anim.modulate = Color(1,1,1,1)
		if state != State.DEAD:
			state = State.CHASE

func state_dead(_delta):
	velocity = Vector2.ZERO
	if anim.animation != "die":
		attack_hitbox.set_deferred("monitoring", false)
		attack_hitbox.set_deferred("monitorable", false)
		hurtbox.set_deferred("disabled", true)
		play_anim("die")
		
		GameManager.add_point(50)
		
		var frames = anim.sprite_frames.get_frame_count("die")
		var fps = anim.sprite_frames.get_animation_speed("die")
		if fps > 0:
			var t = Timer.new()
			t.wait_time = frames / fps
			t.one_shot = true
			t.connect("timeout", Callable(self, "queue_free"))
			add_child(t)
			t.start()

# ------------------- Lógica ------------------- #
func take_damage(amount, enemyposition: Vector2, attacktype: int):
	if state == State.DEAD:
		return
	life -= amount
	if life <= 0:
		state = State.DEAD
	else:
		state = State.HURT
		anim.modulate = Color(0.796, 0.0, 0.0, 0.741)
		apply_knockback(amount, enemyposition, attacktype)

func apply_knockback(amount:int, from_position: Vector2, attack_type:int, knockback_strength: float = 100.0,knockback_time = 0.2):
	var dir = global_position - from_position
	dir.x = sign(dir.x)  
	dir.y = -1.0 if attack_type == 1.0 else 0.0
	dir = dir.normalized()
	velocity = dir * (knockback_strength * amount)  # fuerza proporcional
	var t = get_tree().create_timer(amount * knockback_time)
	t.connect("timeout", Callable(self, "_end_knockback"))

func _end_knockback():
	if state != State.DEAD:
		state = State.CHASE
		anim.modulate = Color(1,1,1,1)
# ------------------- Detección ------------------- #
func _on_detection_area_body_entered(body: Node2D) -> void:
	if state == State.DEAD: return
	if body is DrunkMaster:
		state = State.CHASE

func _on_detection_area_body_exited(body: Node2D) -> void:
	if state == State.DEAD: return
	if body is DrunkMaster:
		state = State.PATROL

func should_turn() -> bool:
	if raywall.is_colliding() or rayspikes.is_colliding():
		return true
	if not rayfloor.is_colliding():
		return true
	return false

func turn():
	direction *= -1
	set_direction(direction)

func set_direction(dir):
	if dir == 0: return
	direction = dir
	var base_scale_x = abs(flipper.scale.x)
	flipper.scale.x = base_scale_x if dir > 0 else -base_scale_x

func _on_attack_hitbox_body_entered(body: Node2D) -> void:
	if body is DrunkMaster:
		var drunkmaster: DrunkMaster = body as DrunkMaster
		drunkmaster.take_damage(attack_power, global_position, 0)


func _on_head_hitbox_body_entered(body: Node2D) -> void:
	if body is DrunkMaster:
		player_on_head(body)

func player_on_head(player : DrunkMaster):
	if state in [State.DEAD, State.HURT, State.HEAD]:
		return
	state = State.HEAD
	
	player.take_damage(1, global_position, 3)

func _on_head_timer_timeout():
	if state == State.HEAD:
		state = State.CHASE
		head_timer_started = false
		
	
func apply_enemy_separation(delta: float) -> Vector2:
	var separation := Vector2.ZERO
	for body in enemy_avoid_area.get_overlapping_bodies():
		if body != self and body.is_in_group("Enemies"):
			var diff = global_position - body.global_position
			var dist = diff.length()
			if dist > 0:
				separation += diff.normalized() * (80.0 / dist) #cambiar el valor numerico mas bajo si se empujan mucho
	return separation * delta
