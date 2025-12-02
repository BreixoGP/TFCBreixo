extends Camera2D

var target: Node2D = null
var shake_strength: float = 0.0
var shake_decay: float = 5.0
var shake_offset := Vector2.ZERO
@export var smooth: float = 0.15        # Suavizado general
@export var deadzone_size := Vector2(80, 40)  # Tamaño de la zona muerta (mitad ancho/alto)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	enabled = false #las activa el gamemanager
	target=GameManager.player

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not enabled:
		return
	if target == null:
		target=GameManager.player
		return
	
	follow_with_deadzone(delta)
	apply_shake(delta)

func follow_with_deadzone(delta):
	var cam_pos=global_position
	var player_pos=target.global_position
	
	var min_x = cam_pos.x - deadzone_size.x
	var max_x = cam_pos.x + deadzone_size.x
	var min_y = cam_pos.y - deadzone_size.y
	var max_y = cam_pos.x + deadzone_size.y
	
	var new_pos=cam_pos
	
	#horizontal
	if player_pos.x < min_x:
		new_pos.x = player_pos.x + deadzone_size.x
	if player_pos.x > max_x:
		new_pos.x = player_pos.x - deadzone_size.x
	#vertical
	if player_pos.y < min_y:
		new_pos.y = player_pos.y + deadzone_size.y
	if player_pos.y > max_y:
		new_pos.y = player_pos.y - deadzone_size.y
	#suavizado
	global_position = global_position.lerp(new_pos, smooth)
	
func apply_shake(delta):
	if shake_strength > 0:
		shake_offset = Vector2(
			randf_range(-shake_strength, shake_strength),
			randf_range(-shake_strength, shake_strength)
		)
		shake_strength -= shake_decay * delta
	else:
		shake_offset = Vector2.ZERO
	global_position += shake_offset
	
