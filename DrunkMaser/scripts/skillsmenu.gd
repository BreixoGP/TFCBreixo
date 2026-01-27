extends Control

@onready var skills_cont: VBoxContainer = $skills_cont
@onready var controls_cont: VBoxContainer = $controls_cont

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_controls_pressed() -> void:
	skills_cont.visible = false
	controls_cont.visible =true


func _on_skills_pressed() -> void:
	controls_cont.visible = false
	skills_cont.visible = true
