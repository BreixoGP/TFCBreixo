extends Button


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pressed.connect(salir)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func salir():
	get_tree().quit()
