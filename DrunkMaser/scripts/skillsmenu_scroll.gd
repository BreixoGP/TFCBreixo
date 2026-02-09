extends Control
  
@onready var ps_controls_scroll: ScrollContainer = $controls_display/ps_controls_scroll
@onready var xbox_controls_scroll: ScrollContainer = $controls_display/xbox_controls_scroll
@onready var pc_controls_scroll: ScrollContainer = $controls_display/pc_controls_scroll
@onready var wallslide_icon: TextureRect = $skills_scroll/VBoxContainer/wallslide/wallslide_icon
@onready var wallslide_label: Label = $skills_scroll/VBoxContainer/wallslide/wallslide_label
@onready var boost_icon: TextureRect = $skills_scroll/VBoxContainer/boost/boost_icon
@onready var boost_label: Label = $skills_scroll/VBoxContainer/boost/boost_label
@onready var flip_icon: TextureRect = $skills_scroll/VBoxContainer/flip/flip_icon
@onready var flip_label: Label = $skills_scroll/VBoxContainer/flip/flip_label
@onready var dash_icon: TextureRect = $skills_scroll/VBoxContainer/dash/dash_icon
@onready var dash_label: Label = $skills_scroll/VBoxContainer/dash/dash_label
@onready var wallslide_xbox: HBoxContainer = $controls_display/xbox_controls_scroll/VBoxContainer/box8
@onready var flip_xbox: HBoxContainer = $controls_display/xbox_controls_scroll/VBoxContainer/box6
@onready var flip_play: HBoxContainer = $controls_display/ps_controls_scroll/VBoxContainer/box6
@onready var wallslide_play: HBoxContainer = $controls_display/ps_controls_scroll/VBoxContainer/box8
@onready var flip_pc: HBoxContainer = $controls_display/pc_controls_scroll/VBoxContainer/box6
@onready var wallslide_pc: HBoxContainer = $controls_display/pc_controls_scroll/VBoxContainer/box8
@onready var dash_pc: HBoxContainer = $controls_display/pc_controls_scroll/VBoxContainer/box9
@onready var dash_ps: HBoxContainer = $controls_display/ps_controls_scroll/VBoxContainer/box9
@onready var dash_xbox: HBoxContainer = $controls_display/xbox_controls_scroll/VBoxContainer/box9

@onready var crystal_icon: TextureRect = $items_scroll/VBoxContainer/crystal/crystal_icon
@onready var crystal_label: Label = $items_scroll/VBoxContainer/crystal/crystal_label
@onready var key_icon: TextureRect = $items_scroll/VBoxContainer/key/key_icon
@onready var key_label: Label = $items_scroll/VBoxContainer/key/key_label


@onready var skills_scroll: ScrollContainer = $skills_scroll
@onready var controls_display: Control = $controls_display
@onready var items_scroll: ScrollContainer = $items_scroll

var crystal_text = "Cursed Brewery Altar Crystal
Set it in the altar.
The platforms awaken."
var key_text = "Golden Key
The golden face watches.
It opens the matching door."
var wallslide_txt = "Drunken Crane’s Embrace— Lan Caihe
Cling to the wall and the fall slows.
Step toward it, then rise in a drunken leap."
var boost_txt ="Iron Gourd of the Sword Immortal— Lu Dongbin
Pain fades with every drink.
The body hardens, the blows grow heavier."
var flip_txt = "Gourd of the Backward Immortal— Zhang Guolao
A retreat twists into a drunken turn.
Those before and behind share the same fate."
var dash_basic= "Drunken Step
A sudden slip of the feet.
The body surges forward,
escaping before the blow lands."
var dash_txt = "Drunken Breeze— Han Xiangzi
Feet lose their way,the body follows the wind.
What looked like escape becomes the strike."
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
	items_scroll.visible = false
	
func _on_controls_pressed() -> void:
	skills_scroll.visible = false
	controls_display.visible = true
	items_scroll.visible = false

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
	

func _on_resume_pressed() -> void:
	GameManager.resume_game()


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_items_pressed() -> void:
	skills_scroll.visible = false
	controls_display.visible = false
	items_scroll.visible = true


func update_skills_display():
	if GameManager.wall_ability_active:
		wallslide_icon.modulate = Color(1,1,1,1)
		wallslide_label.text = wallslide_txt
		wallslide_pc.visible = true
		wallslide_play.visible = true
		wallslide_xbox.visible = true
		
	else:
		wallslide_icon.modulate = Color()
		wallslide_label.text = "???????"
		wallslide_pc.visible = false
		wallslide_play.visible = false
		wallslide_xbox.visible = false
	
	var has_boost := (GameManager.upgrade_attack_temp + GameManager.upgrade_attack_perm) > 0
	if has_boost:
		boost_icon.modulate = Color(1,1,1,1)
		boost_label.text = boost_txt
	else:
		boost_icon.modulate = Color()
		boost_label.text = "???????"
		
	if GameManager.flip_ability_active:
		flip_icon.modulate = Color(1,1,1,1)
		flip_label.text = flip_txt
		flip_pc.visible = true
		flip_play.visible = true
		flip_xbox.visible = true
	else:
		flip_icon.modulate = Color()
		flip_label.text = "???????"
		flip_pc.visible = false
		flip_play.visible = false
		flip_xbox.visible = false
	if GameManager.dash_ability_active:
		dash_icon.modulate = Color(1,1,1,1)
		dash_label.text = dash_basic
		dash_pc.visible = true
		dash_ps.visible = true
		dash_xbox.visible = true
		if GameManager.dash_upgrade_active:
			dash_label.text = dash_txt
	else:
		dash_icon.modulate = Color()
		dash_label.text = "???????"
		dash_pc.visible = false
		dash_ps.visible = false
		dash_xbox.visible = false
func update_items_display():
	if GameManager.has_crystal:
		crystal_icon.modulate = Color(1.0, 1.0, 1.0, 1.0)
		crystal_label.text = crystal_text
	else:
		crystal_icon.modulate = Color()
		crystal_label.text = "???????"
	if GameManager.has_key:
		key_icon.modulate = Color(1,1,1,1)
		key_label.text = key_text
	else:
		key_icon.modulate = Color()
		key_label.text = "???????"
