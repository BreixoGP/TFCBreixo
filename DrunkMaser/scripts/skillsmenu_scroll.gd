extends Control
  
@onready var ps_controls_scroll: ScrollContainer = $controls_display/ps_controls_scroll
@onready var xbox_controls_scroll: ScrollContainer = $controls_display/xbox_controls_scroll
@onready var pc_controls_scroll: ScrollContainer = $controls_display/pc_controls_scroll

@onready var wallslide_icon: TextureRect = $skills_scroll/VBoxContainer/wallslide/wallslide_icon
@onready var wallslide_label: Label = $skills_scroll/VBoxContainer/wallslide/wallslide_label
@onready var boost_icon: TextureRect = $skills_scroll/VBoxContainer/boost/boost_icon
@onready var boost_label: Label = $skills_scroll/VBoxContainer/boost/boost_label
@onready var skills_scroll: ScrollContainer = $skills_scroll
@onready var controls_display: Control = $controls_display


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_skills_pressed() -> void:
	update_skills_display()
	controls_display.visible = false
	skills_scroll.visible = true
	


func _on_controls_pressed() -> void:
	skills_scroll.visible = false
	controls_display.visible = true

func _on_xbox_pressed() -> void:
	pc_controls_scroll.visible = false
	ps_controls_scroll.visible = false
	xbox_controls_scroll.visible = true


func _on_ps_pressed() -> void:
	pc_controls_scroll.visible = false
	xbox_controls_scroll.visible = false
	ps_controls_scroll.visible = true

func _on_pc_pressed() -> void:
	ps_controls_scroll.visible = false
	xbox_controls_scroll.visible = false
	pc_controls_scroll.visible = true
func update_skills_display():
	if GameManager.wall_ability_active:
		wallslide_icon.modulate = Color(1,1,1,1)
		wallslide_label.visible = true
	else:
		wallslide_icon.modulate = Color()
		wallslide_label.visible = false
	
	var has_boost := (GameManager.upgrade_attack_temp + GameManager.upgrade_attack_perm) > 0
	if has_boost:
		boost_icon.modulate = Color(1,1,1,1)
		boost_label.visible = true
	else:
		boost_icon.modulate = Color()
		boost_label.visible = false
		


func _on_resume_pressed() -> void:
	GameManager.resume_game()


func _on_quit_pressed() -> void:
	get_tree().quit()
