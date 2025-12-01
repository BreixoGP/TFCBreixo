extends Sprite2D
@onready var audio: AudioStreamPlayer2D = $AudioStreamPlayer2D

var has_fallen=false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Jahmurai and !has_fallen:
		var opacity_tween:Tween=create_tween().set_trans(Tween.TRANS_SINE)
		var pos_tween:Tween=create_tween().set_trans(Tween.TRANS_SINE)
		
		opacity_tween.tween_property(self,"modulate:a",0.0,0.5)
		pos_tween.tween_property(self,"global_position",global_position+Vector2(0,20),0.5)
		audio.play()
		opacity_tween.finished.connect(_disable_collider)
		has_fallen=true
		
func  _disable_collider():
		$StaticBody2D/CollisionShape2D.disabled=true
