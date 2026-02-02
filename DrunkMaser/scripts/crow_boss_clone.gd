extends Node2D
class_name CrowClone

@onready var anim: AnimatedSprite2D = $Flipper/AnimatedSprite2D
@onready var hurtbox: CollisionShape2D = $hurtbox
@onready var shadowparticles: CPUParticles2D = $Flipper/Shadowparticles

enum State { IDLE, DEAD }
var state := State.IDLE
var invulnerable := true

signal clone_hit(clone_node)
var boss_node: Node = null

func _ready():
	if boss_node:
		# Conectamos a las señales del boss
		boss_node.connect("state_changed", Callable(self, "_on_boss_state_changed"))
		boss_node.connect("anim_changed", Callable(self, "_on_boss_anim_changed"))
	play_anim("idle")

func _on_boss_state_changed(new_state):
	if state == State.DEAD:
		return
	# Los clones son invulnerables mientras el boss esté en SUMMON
	invulnerable = (new_state == boss_node.State.SUMMON)
	# Copiamos animación del boss para despistar
	if boss_node:
		play_anim(boss_node.anim.animation)

func _on_boss_anim_changed(anim_name: String):
	if state != State.DEAD:
		play_anim(anim_name)
		if anim_name == "recover":
			shadowparticles.color=Color(1.0, 0.458, 0.988, 1.0)
			
		else:
			shadowparticles.color=Color(0.15, 0.0, 0.15, 1.0)
			
		if anim_name == "explosion":
			_kill_clone()
			
func take_damage(amount: int, enemyposition: Vector2, attacktype: int):
	if state == State.DEAD or invulnerable:
		return

	# Muere y emite señal al boss
	state = State.DEAD
	invulnerable = true
	anim.modulate = Color(0.3, 0.0, 0.257, 1.0)
	play_anim("explosion")
	hurtbox.disabled = true

	if boss_node:
		emit_signal("clone_hit")

	# Queue free tras animación
	var frames = anim.sprite_frames.get_frame_count("explosion")
	var fps = anim.sprite_frames.get_animation_speed("explosion")
	if fps > 0:
		var t = Timer.new()
		t.wait_time = frames / fps
		t.one_shot = true
		t.timeout.connect(Callable(self, "queue_free"))
		add_child(t)
		t.start()

func play_anim(anim_name: String):
	if anim.animation != anim_name:
		anim.play(anim_name)
func _kill_clone():
	if state == State.DEAD:
		return
	state = State.DEAD
	invulnerable = true
	hurtbox.disabled = true

	# Animación de explosión y modulate
	play_anim("explosion")
	anim.modulate = Color(0.3, 0.0, 0.257, 1.0)

	# Queue_free al terminar la animación
	var frames = anim.sprite_frames.get_frame_count("explosion")
	var fps = anim.sprite_frames.get_animation_speed("explosion")
	if fps > 0:
		var t = Timer.new()
		t.wait_time = frames / fps
		t.one_shot = true
		t.timeout.connect(Callable(self, "queue_free"))
		add_child(t)
		t.start()
