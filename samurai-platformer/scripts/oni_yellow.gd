extends Oni
class_name OniYellow

@onready var rayattack_melee: RayCast2D = $Flipper/rayattack_melee
@onready var attack_hitbox_melee: Area2D = $Flipper/attack_hitbox_melee

@export var attack_power_melee = 1

# ----------------------------
# Hitbox: solo cambia la lógica del frame
# ----------------------------
func _update_attack_hitbox():
	# Ataque a distancia (cadena)
	if anim.frame == 5:
		attack_hitbox.monitoring = true
	else:
		attack_hitbox.monitoring = false

# ----------------------------
# Chase: se detiene a distancia de ataque y espera si es necesario
# ----------------------------
func state_chase(_delta):
	if state == State.HURT:
		return

	if not GameManager.player:
		state = State.IDLE
		return

	var dx: float = GameManager.player.global_position.x - global_position.x
	var distance_to_player = abs(dx)
	set_direction(sign(dx))

	# Separación entre enemigos
	var separation := apply_enemy_separation(_delta)

	# Comprobamos suelo y obstáculos
	var can_move := rayfloor.is_colliding() \
		and not raywall.is_colliding() \
		and not rayspikes.is_colliding()

	# Distancia de ataque en pixeles (longitud del raycast)
	var attack_range = rayattack.target_position.x * abs(flipper.scale.x)
	var melee_range = rayattack_melee.target_position.x * abs(flipper.scale.x)

	# --- Prioridad de ataque inmediata ---
	if rayattack_melee.is_colliding():
		state = State.READY_MELEE
		return
	elif rayattack.is_colliding():
		state = State.READY
		return

	# --- Movimiento hacia jugador ---
	if can_move:
		if distance_to_player > attack_range:
			# Moverse hacia el jugador pero no pasarse del rango de ataque
			velocity.x = direction * speed * 1.3 + separation.x
			play_anim("chase")
		else:
			# Dentro de rango de ataque a distancia pero fuera de melee: esperar
			velocity.x = 0
			play_anim("waiting")
	else:
		# No puede avanzar (borde o pinchos)
		velocity.x = 0
		if distance_to_player <= attack_range:
			state = State.READY
		else:
			play_anim("waiting")

# ----------------------------
# READY_MELEE: animación de preparación melee
# ----------------------------
func state_ready_melee(_delta):
	if state == State.HURT:
		return

	velocity.x = 0
	play_anim("ready_melee")  # animación de preparación

# ----------------------------
# ATTACK_MELEE: golpe cuerpo a cuerpo
# ----------------------------
func state_attack_melee(_delta):
	if state in [State.HURT, State.DEAD]:
		attack_hitbox_melee.monitoring = false
		return

	velocity.x = 0
	play_anim("attack_melee")

	if anim.frame == 2:
		attack_hitbox_melee.monitoring = true
	else:
		attack_hitbox_melee.monitoring = false

	var frames = anim.sprite_frames.get_frame_count("attack_melee")
	if anim.frame == frames - 1:
		attack_hitbox_melee.monitoring = false
		attack_timer = attack_cooldown
		state = State.CHASE

# ----------------------------
# READY: animación de preparación ataque a distancia
# ----------------------------
func state_ready(_delta):
	if state == State.HURT:
		return

	velocity.x = 0
	play_anim("ready")  # animación preparación ataque a distancia

# ----------------------------
# ATTACK: ataque a distancia (cadena)
# ----------------------------
func state_attack(_delta):
	if state in [State.HURT, State.DEAD]:
		attack_hitbox.monitoring = false
		return

	velocity.x = 0
	play_anim("attack")
	_update_attack_hitbox()

	var frames = anim.sprite_frames.get_frame_count("attack")
	if anim.frame == frames - 1:
		attack_hitbox.monitoring = false
		attack_timer = attack_cooldown
		state = State.CHASE

# ----------------------------
# Animación terminada
# ----------------------------
func _on_anim_finished():
	if anim.animation == "ready" and state == State.READY:
		state = State.ATTACK
	elif anim.animation == "ready_melee" and state == State.READY_MELEE:
		state = State.ATTACK_MELEE

# ----------------------------
# Override process_state para incluir todos los estados
# ----------------------------
func proccess_state(delta):
	match state:
		State.IDLE: state_idle(delta)
		State.PATROL: state_patrol(delta)
		State.CHASE: state_chase(delta)
		State.READY: state_ready(delta)
		State.ATTACK: state_attack(delta)
		State.READY_MELEE: state_ready_melee(delta)
		State.ATTACK_MELEE: state_attack_melee(delta)
		State.HEAD: state_head(delta)
		State.HURT: state_hurt(delta)
		State.DEAD: state_dead(delta)

# ----------------------------
# Hitbox melee
# ----------------------------
func _on_attack_hitbox_melee_body_entered(body: Node2D) -> void:
	if body is DrunkMaster:
		var player: DrunkMaster = body as DrunkMaster
		player.take_damage(attack_power_melee, global_position, 0)
