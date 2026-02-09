extends CharacterBody2D
class_name OniBlue

@onready var flipper: Node2D = $Flipper
@onready var anim: AnimatedSprite2D = $Flipper/AnimatedSprite2D
@onready var raywall: RayCast2D = $Flipper/raywall
@onready var rayfloor: RayCast2D = $Flipper/rayfloor
@onready var rayspikes: RayCast2D = $Flipper/rayspikes
@onready var rayattack: RayCast2D = $Flipper/rayattack


@onready var enemy_avoid_area: Area2D = $Flipper/enemy_avoid_area
@export var enemy_id: String
@onready var blood_particles: CPUParticles2D = $Flipper/Bloodparticles
@onready var shadow_particles: CPUParticles2D = $Flipper/Shadowparticles
@export var pickup_position: Node2D
@export var pickup_scene: PackedScene
@onready var attack_hitbox: Area2D = $Flipper/attack_hitbox
@onready var attack_2_hitbox: Area2D = $Flipper/attack2_hitbox
@onready var hurtbox: CollisionShape2D = $hurtbox



enum State { IDLE, PATROL, CHASE, READY, ATTACK, HURT, DEAD, JUMP_BACK }
var state: State = State.IDLE
var direction = -1
@export var life = 35
@export var attack_power = 1
@export var attack2_power = 2
var jump_started := false
@export var speed = 190.0
@export var point_value=50
const MAX_VERTICAL_DIFF := 40.0
var attack_chosen := false
var attack_type
var attack_cooldown = 0.5 
var attack_timer = 0.0
@export var chase_offset_range := 30.0
var chase_offset_x := 0.0
var chase_offset_timer := 0.0
const OFFSET_REFRESH_TIME := 1.2
@export var vertical_attack_x_range := 24.0
@export var vertical_attack_y_diff := 40.0
@export var vertical_attack_delay := 0.3
var vertical_attack_timer := 0.0
var message ="A powerful relic dropped..."

func _ready():
	anim.animation_finished.connect(_on_anim_finished)
	if enemy_id == "":
		push_error("Enemy sin ID: " + name)
		return
		
	chase_offset_x = randf_range(-chase_offset_range, chase_offset_range)
	
	if GameManager.is_enemy_defeated(enemy_id):
		queue_free()
		return

	state = State.IDLE
	play_anim("idle")


func _physics_process(delta: float) -> void:
	if state != State.ATTACK:
		attack_hitbox.monitoring = false
		
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
		State.CHASE: state_chase(delta)
		State.READY: state_ready(delta)
		State.ATTACK: state_attack(delta)
		State.HURT: state_hurt(delta)
		State.DEAD: state_dead(delta)
		State.JUMP_BACK: state_jump_back(delta)
func state_idle(delta):
	play_anim("idle")
	velocity.x = 0

func state_chase(_delta):
	if state == State.HURT:
		return
	attack_chosen = false
	play_anim("chase")

	if not GameManager.player:
		state = State.IDLE
		return
	update_chase_offset(_delta)
	var dx: float = GameManager.player.global_position.x - global_position.x
	set_direction(sign(dx))
	if abs(dx) < 4.0:
		velocity.x = 0
	else:
		velocity.x = direction * speed * 1.3
	

	#  Separación entre enemigos
	var separation := apply_enemy_separation(_delta)
	velocity += separation

	# Obstáculos
	var can_move := rayfloor.is_colliding() \
		and not raywall.is_colliding() \
		and not rayspikes.is_colliding()

	if not can_move:
		velocity.x = 0
		state = State.JUMP_BACK
		return

	# Ataque
	if rayattack.is_colliding():
		state = State.READY
	
		# --- ATAQUE VERTICAL SI EL PLAYER ESTÁ ENCIMA ---
	var player = GameManager.player
	if player:
		var dx_abs = abs(player.global_position.x - global_position.x)
		var dy = player.global_position.y - global_position.y

		if dx_abs <= vertical_attack_x_range and dy <= -vertical_attack_y_diff:
			vertical_attack_timer += _delta
			if vertical_attack_timer >= vertical_attack_delay:
				state = State.JUMP_BACK
				jump_started = false
				vertical_attack_timer = 0.0
				return
		else:
			vertical_attack_timer = 0.0
func state_ready(_delta):
	if state != State.HURT:
		velocity.x = 0
		play_anim("ready")
		
		if not rayattack.is_colliding():
			state = State.CHASE
			
		
func state_attack(_delta):
		if not attack_chosen:
			attack_chosen = true

			if randf() < 0.5:
				attack_type = "attack"
			else:
				attack_type = "attack2"

			play_anim(attack_type)
		
		
		var frames = anim.sprite_frames.get_frame_count(attack_type)
		if anim.frame == frames - 1:
			state = State.CHASE
			
			
func state_jump_back(_delta):
	play_anim("jump")
	if not jump_started:
		jump_started = true

		var player = GameManager.player
		if player:
			# Dirección relativa al player (-1: player a la izquierda, 1: player a la derecha)
			var dir = sign(player.global_position.x - global_position.x)

			# Distancia horizontal final aleatoria detrás del player
			var distance = randf_range(20, 80)
			var target_x = player.global_position.x + (dir * distance)

			# Limitamos X para que no salga del mapa
			target_x = clamp(target_x, -10, 1660)

			# Offset en Y para que no quede pegado al suelo
			var target_y = player.global_position.y - 40  # siempre cae un poco arriba

			var start_pos = global_position
			var end_pos = Vector2(target_x, target_y)

			# Altura máxima de la parábola proporcional a la distancia horizontal
			var apex_height = lerp(50, 120, clamp(abs(end_pos.x - start_pos.x) / 400.0, 0, 1))
			var apex = Vector2((start_pos.x + end_pos.x) / 2, min(start_pos.y, end_pos.y) - apex_height)

			# Duración del salto proporcional a la distancia
			var jump_time = clamp(abs(end_pos.x - start_pos.x) / 300.0, 0.3, 0.7)

			# Tween de parábola: dos tramos, hasta apex y hasta target
			var tween = create_tween()
			tween.tween_property(self, "global_position", apex, jump_time / 2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			tween.tween_property(self, "global_position", end_pos, jump_time / 2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
			tween.connect("finished", Callable(self, "_on_jump_finished"))

	else:
		# Mientras no toque el suelo, no hacemos nada
		pass




func _on_jump_finished():
	jump_started = false
	state = State.CHASE
	
func state_hurt(_delta):
	play_anim("hurt")
	# El knockback se aplica mientras está en HURT
	# Bloquea cualquier movimiento hasta que toque suelo y velocidad horizontal casi 0
	if is_on_floor() and abs(velocity.x) < 1.0:
		velocity = Vector2.ZERO
		anim.modulate = Color(1,1,1,1)
	
func state_dead(_delta):
	velocity = Vector2.ZERO
	if anim.animation != "die":
		attack_hitbox.set_deferred("monitoring", false)
		attack_hitbox.set_deferred("monitorable", false)
		hurtbox.set_deferred("disabled", true)
		play_anim("die")

		#GameManager.add_point(point_value)
		GameManager.defeat_enemy(enemy_id)
		# Timer para desaparecer
		var frames = anim.sprite_frames.get_frame_count("die")
		var fps = anim.sprite_frames.get_animation_speed("die")
		if fps > 0:
			var t = Timer.new()
			t.wait_time = frames / fps
			t.one_shot = true
			t.connect("timeout", Callable(self, "queue_free"))
			add_child(t)
			spawn_pickup()
			GameManager.hud.show_message(message,1.5)
			t.start()

# ------------------- Lógica ------------------- #
func take_damage(amount, enemyposition: Vector2, attacktype: int):
	if state == State.DEAD:
		return
	life -= amount
	spawn_blood()
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
		attack_chosen = false
		if randf() <0.5:
			state = State.JUMP_BACK
		else:
			state=State.CHASE
		anim.modulate = Color(1,1,1,1)
		 
		
func _on_area_body_entered(body: Node2D):
	if body is DrunkMaster:
		if state not in [State.HURT, State.DEAD, State.JUMP_BACK]:
			state = State.JUMP_BACK
			jump_started = false

# ------------------- Detección ------------------- #
func _on_detection_area_body_entered(body: Node2D) -> void:
	if state == State.DEAD: return
	if body is DrunkMaster:
		state = State.CHASE

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
		drunkmaster.take_damage(attack_power, global_position, 3)
	elif body.is_in_group("Destructibles"):
		if body.has_method("take_damage"):
			body.take_damage(body.life, global_position, 0)


func apply_enemy_separation(delta: float) -> Vector2:
	var separation := Vector2.ZERO
	for body in enemy_avoid_area.get_overlapping_bodies():
		if body != self and body.is_in_group("Enemies"):
			var diff = global_position - body.global_position
			var dist = diff.length()
			if dist > 0:
				separation += diff.normalized() * (80.0 / dist) #cambiar el valor numerico mas bajo si se empujan mucho
	return separation * delta

func _on_anim_finished():
	if anim.animation == "ready" and state == State.READY:
		state = State.ATTACK
	
func spawn_blood():
	if blood_particles:
				# Reiniciamos partículas
		blood_particles.emitting = false
		blood_particles.restart()
		blood_particles.emitting = true
func jump():
	state = State.JUMP_BACK
	jump_started = false

func update_chase_offset(delta):
	chase_offset_timer += delta
	if chase_offset_timer >= OFFSET_REFRESH_TIME:
		chase_offset_timer = 0.0
		chase_offset_x = randf_range(-chase_offset_range, chase_offset_range)

func _on_animated_sprite_2d_frame_changed() -> void:
	if state == State.ATTACK and anim.frame == 2:
		if attack_type == "attack":
			attack_hitbox.monitoring = true
		if attack_type == "attack2":
			attack_2_hitbox.monitoring = true
	else:
		attack_hitbox.monitoring = false
		attack_2_hitbox.monitoring = false

func spawn_pickup():
	if pickup_scene:
		var pickup = pickup_scene.instantiate()
		pickup.global_position = pickup_position.global_position
		pickup.pickup_id = enemy_id + "_pickup"

		get_parent().call_deferred("add_child", pickup)


func _on_animated_sprite_2d_animation_finished() -> void:
	if state == State.ATTACK:
		attack_chosen = false
		state = State.CHASE


func _on_attack_2_hitbox_body_entered(body: Node2D) -> void:
	if body is DrunkMaster:
		var drunkmaster: DrunkMaster = body as DrunkMaster
		drunkmaster.take_damage(attack2_power, global_position, 1)
