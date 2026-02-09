extends CanvasLayer


@onready var box: HBoxContainer = $CanvasLayer/HBoxContainer2
@onready var message_label: Label = $CanvasLayer/HBoxContainer2/message_label
@onready var progress_bar: TextureProgressBar = $ProgressBar
@onready var points_label: Label = $HBoxContainer/points_label
@onready var crystal: AnimatedSprite2D = $HBoxContainer/crystal
@onready var coin: AnimatedSprite2D = $HBoxContainer/coin
@onready var key: AnimatedSprite2D = $HBoxContainer/key
var message_tween: Tween
var message_timer: Timer
var shake_time := 0.0
var shake_intensity := 6.0
var base_pos: Vector2
var base_rot := 0.0


func _ready():
	if box:
		box.visible = true
		box.modulate.a = 0.0

	message_timer = Timer.new()
	message_timer.one_shot = true
	add_child(message_timer)
	message_timer.timeout.connect(_hide_message)

	base_pos = progress_bar.position
	base_rot = progress_bar.rotation
	
	coin.animation_finished.connect(_on_coin_animation_finished)

	
func _process(delta: float) -> void:
	if shake_time > 0:
		shake_time -= delta
		progress_bar.position = base_pos + Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
	
		
		progress_bar.rotation = base_rot + randf_range(-0.15, 0.15)
	else:
		progress_bar.position = base_pos
		progress_bar.rotation = base_rot
		
func show_message(text: String, duration := 2.5):
	message_label.text = text
	
	if message_tween:
		message_tween.kill()

	message_tween = create_tween()
	message_tween.set_trans(Tween.TRANS_SINE)
	message_tween.set_ease(Tween.EASE_OUT)

	# Fade IN
	message_tween.tween_property(box, "modulate:a", 1.0, 0.5)
	# Tiempo visible
	message_tween.tween_interval(duration)
	# Fade OUT
	message_tween.tween_property(box, "modulate:a", 0.0, 0.5)


func _hide_message():
	box.visible = false

func update_points():
	points_label.text = str(GameManager.score).pad_zeros(5)
	coin.play("win")
	
func set_max_health(hp: int):
	progress_bar.max_value = hp


func update_health(life):
	progress_bar.value = life


	
func shake():
	shake_time = 0.25
	
func update_items():
	crystal.play("picked" if GameManager.has_crystal else "empty")
	key.play("picked" if GameManager.has_key else "default")
	
func _on_coin_animation_finished():
	if coin.animation == "win":
		coin.play("default") 
