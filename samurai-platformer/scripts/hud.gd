extends CanvasLayer


@onready var message_label: Label = $HBoxContainer2/message_label

@onready var points_label: Label = $HBoxContainer/points_label
@onready var life_bottle: AnimatedSprite2D = $HBoxContainer/life_bottle

var max_health = 10
var total_frames := 10 

var message_timer: Timer
var shake_time := 0.0
var shake_intensity := 6.0
var base_pos: Vector2
var base_rot := 0.0


func _ready():
	if message_label:
		message_label.visible = false

	message_timer = Timer.new()
	message_timer.one_shot = true
	add_child(message_timer)
	message_timer.timeout.connect(_hide_message)
	base_pos = life_bottle.position
	base_rot = life_bottle.rotation
func _process(delta: float) -> void:
	if shake_time > 0:
		shake_time -= delta
		
		life_bottle.position = base_pos + Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
		
		life_bottle.rotation = base_rot + randf_range(-0.15, 0.15)
	else:
		life_bottle.position = base_pos
		life_bottle.rotation = base_rot
func show_message(text: String, duration := 2.5):
	message_label.text = text
	message_label.visible = true
	message_timer.start(duration)

func _hide_message():
	message_label.visible = false

func update_points():
	points_label.text = str(GameManager.score)
	
func set_max_health(hp: int):
	max_health = hp

func update_health(life):
	life_bottle.play(str(life))
func shake():
	shake_time = 0.25
