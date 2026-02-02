extends Node2D
class_name CrowPhase2

@onready var anim: AnimatedSprite2D = $Flipper/AnimatedSprite2D
@onready var hurtbox: CollisionShape2D = $hurtbox

@export var phase2_hp := 14
@export var clone_sprites: Array[Node2D] = []
@export var summon_points: Array[Node2D] = []
@export var hp_pickup_point: Node2D
@export var enemy_scenes: Array[PackedScene] = []
@export var hp_pickups: PackedScene
@export var explosion_scene: PackedScene  # arrástralo desde el editor
@onready var shadowparticles: CPUParticles2D = $Flipper/Shadowparticles

var current_hp := phase2_hp
var invulnerable := true
var recover_started := false
var enemies_alive := []
var recover_time = 10.0
var summon_timer := 0.0
var summon_interval := 3.0
var enemies_per_spawn := 2
var enemies_spawned_this_round := 0
var enemies_this_round := 2  # enemigos en la ronda actual
@export var round_increment := 2  # cuántos enemigos más cada ronda

enum State { SUMMON, RECOVER, HURT, DEAD }
var state := State.SUMMON

signal clone_hit
signal state_changed(new_state)
signal anim_changed(anim_name)


func _ready():
	connect("clone_hit", Callable(self, "_on_clone_hit"))
	emit_signal("state_changed", state)
	invulnerable = true

	# Timer visual para transición a summon
	var frames = anim.sprite_frames.get_frame_count("explosion")
	var fps = anim.sprite_frames.get_animation_speed("explosion")
	var spawn_time = 0.5
	if fps > 0:
		spawn_time = frames / fps

	await get_tree().create_timer(spawn_time).timeout
	reset_to_summon()


func _process(delta):
	match state:
		State.SUMMON:
			process_summon(delta)
		State.RECOVER:
			process_recover(delta)
		State.DEAD:
			state_dead(delta)


func set_state(new_state):
	if state == new_state:
		return
	state = new_state
	emit_signal("state_changed", state)


func process_summon(delta):
	set_state(State.SUMMON)
	play_anim("summon")
	invulnerable = true
	shadowparticles.color=Color(0.15, 0.0, 0.15, 1.0)


	# Solo spawn si no hemos alcanzado el máximo de la ronda
	if enemies_spawned_this_round < enemies_this_round:
		summon_timer += delta
		if summon_timer >= summon_interval:
			summon_timer = 0.0

			# Spawneamos hasta `enemies_per_spawn` enemigos sin pasarnos del máximo
			var to_spawn = min(enemies_per_spawn, enemies_this_round - enemies_spawned_this_round)
			for i in range(to_spawn):
				var p = summon_points[i % summon_points.size()]
				spawn_enemy(p.global_position)
				enemies_spawned_this_round += 1


func spawn_enemy(pos: Vector2):
	if enemy_scenes.is_empty():
		push_error("No enemy scenes assigned!")
		return
	
	if explosion_scene:
		var explosion = explosion_scene.instantiate()
		explosion.global_position = pos
		get_parent().add_child(explosion)

	var enemy_scene = enemy_scenes[randi() % enemy_scenes.size()]
	var enemy = enemy_scene.instantiate()
	enemy.global_position = pos

	if enemy.has_signal("died"):
		enemy.connect("died", Callable(self, "_on_enemy_died"))

	get_parent().add_child(enemy)
	enemies_alive.append(enemy)
func _on_enemy_died(enemy):
	if enemy in enemies_alive:
		enemies_alive.erase(enemy)

	# Si no queda ninguno, pasamos a RECOVER y preparamos próxima ronda
	if enemies_alive.is_empty():
		set_state(State.RECOVER)
		enemies_this_round += round_increment
		enemies_spawned_this_round = 0
		if hp_pickup_point:
			spawn_hppickup(hp_pickup_point.global_position)

func process_recover(_delta):
	if  recover_started:
		return
	recover_started = true
	set_state(State.RECOVER)
	shadowparticles.color=Color(1.0, 0.458, 0.988, 1.0)
	play_anim("recover")
	invulnerable = false
	var t := Timer.new()
	t.wait_time = recover_time
	t.one_shot = true
	t.timeout.connect(end_recover)
	add_child(t)
	t.start()
func take_damage(amount: int, enemyposition: Vector2, attacktype: int):
	if invulnerable or state == State.DEAD:
		return

	current_hp -= amount

	if current_hp <= 0:
		set_state(State.DEAD)
	else:
		apply_knockback_visual()

func state_dead(_delta):
	play_anim("explosion")
	anim.modulate = Color(0.3, 0.0, 0.257, 1.0)
	hurtbox.set_deferred("disabled", true)

	var frames = anim.sprite_frames.get_frame_count("explosion")
	var fps = anim.sprite_frames.get_animation_speed("explosion")

	if fps > 0:
		var t := Timer.new()
		t.wait_time = frames / fps
		t.one_shot = true
		t.timeout.connect(queue_free)
		add_child(t)
		t.start()


func apply_knockback_visual():
	if state == State.DEAD:
		return

	set_state(State.HURT)
	anim.modulate = Color(0.751, 0.001, 0.832, 0.741)

	var original_pos = anim.position
	var shake_amount := 6.0
	var shake_times := 3
	var shake_duration := 0.2 / (shake_times * 2)

	var tween := create_tween()
	for i in range(shake_times):
		tween.tween_property(anim, "position", original_pos + Vector2(shake_amount, 0), shake_duration)
		tween.tween_property(anim, "position", original_pos + Vector2(-shake_amount, 0), shake_duration)

	tween.tween_property(anim, "position", original_pos, shake_duration)
	tween.finished.connect(_end_knockback_visual)

func _end_knockback_visual():
	if state == State.DEAD:
		return

	anim.modulate = Color(1,1,1,1)
	await get_tree().create_timer(0.3).timeout
	reset_to_summon()
func end_recover():
	play_anim("ready")
	var frames = anim.sprite_frames.get_frame_count("ready")
	var fps = anim.sprite_frames.get_animation_speed("ready")

	if fps > 0:
		var t := Timer.new()
		t.wait_time = frames / fps
		t.one_shot = true
		t.timeout.connect(reset_to_summon)
		add_child(t)
		t.start()
	
func reset_to_summon():
	invulnerable = true
	recover_started = false
	summon_timer = 0.0
	set_state(State.SUMMON)
	play_anim("summon")

func _on_clone_hit():
	if state != State.DEAD:
		reset_to_summon()

func play_anim(anim_name: String):
	if anim.animation != anim_name:
		anim.play(anim_name)
		emit_signal("anim_changed", anim_name)
		
func spawn_hppickup(pos: Vector2):
	if not hp_pickups:
		push_error("No HP pickup scene assigned!")
		return
	
	var pickup = hp_pickups.instantiate()
	pickup.global_position = pos
	get_parent().add_child(pickup)
	
	if explosion_scene:
		var explosion = explosion_scene.instantiate()
		explosion.global_position = pos
		get_parent().add_child(explosion)
