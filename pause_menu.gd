extends Control

@onready var speed: Button = $Panel/VBoxContainer2/speed_upgrade_but
@onready var boost: Button = $Panel/VBoxContainer2/boost_upgrade_but
@onready var health: Button = $Panel/VBoxContainer2/health_upgrade_but
@onready var regen: Button = $Panel/VBoxContainer2/regen_upgrade_but
@onready var spike: Button = $Panel/VBoxContainer2/spike_upgrade_but
@onready var bodydamage: Button = $Panel/VBoxContainer2/bodydamage_upgrade_but
@onready var trail: Button = $Panel/VBoxContainer2/trail_upgrade_but
@onready var buttons : Array = [speed, boost, health, regen, spike, bodydamage, trail]

func _ready():
	hide()  # hides upon start

func _process(_delta):
	var xp : String = str(global.xp_points)
	$Panel/VBoxContainer/XpPoints.text = "XP Points: %s" % xp
	queue_redraw()
	pass

# Draws upgrade circles in pause menu
func _draw():
	for button in buttons:
		var name_len : int = button.name.find('_')
		var upg_name : String = button.name.left(name_len)
		var circle_spacing : Vector2 = Vector2(0, 0)
		for i in global.player_max_lvls[upg_name]:
			var button_pos : Vector2 = button.global_position + Vector2(195, 15)
			var circle_pos : Vector2 = button_pos + circle_spacing
			draw_circle(circle_pos, 10, Color.BLACK)  # Background circles
			if global.player_lvls[upg_name] > i:
				draw_circle(circle_pos, 5, Color.WHITE)  # Upgraded filled circles 
			circle_spacing += Vector2(45, 0)

func _on_speed_upgrade_but_pressed():
	global.speed_button_pressed.emit()

func _on_boost_upgrade_but_pressed():
	global.boost_button_pressed.emit()

func _on_health_upgrade_but_pressed():
	global.health_button_pressed.emit()

func _on_regen_upgrade_but_pressed():
	global.regen_button_pressed.emit()

func _on_spike_upgrade_but_pressed():
	global.spike_button_pressed.emit()

func _on_bodydamage_upgrade_but_pressed():
	global.bodydamage_button_pressed.emit()

func _on_trail_upgrade_but_pressed():
	global.trail_button_pressed.emit()


func _on_speed_upgrade_but_mouse_entered():
	var txt : String = '[center]Increase tail length to provide more thrust.[/center]'
	$Panel/RichTextLabel.text = txt

func _on_boost_upgrade_but_mouse_entered():
	var txt : String = ('[center]Increase energy storage capacity with greater tail thickness.\
	 This allows short bursts of for speed.\nLeft click to boost.[/center]')
	$Panel/RichTextLabel.text = txt

func _on_health_upgrade_but_mouse_entered():
	var txt : String = '[center]A thicker cell wall to provide greater protection from external threats[/center]'
	$Panel/RichTextLabel.text = txt

func _on_regen_upgrade_but_mouse_entered():
	var txt : String = '[center]Mitochondria continuously repair you from any damage taken.[/center]'
	$Panel/RichTextLabel.text = txt

func _on_spike_upgrade_but_mouse_entered():
	var txt : String = '[center]A Large front facing spike to deal significant damage.[/center]'
	$Panel/RichTextLabel.text = txt

func _on_bodydamage_upgrade_but_mouse_entered():
	var txt : String = '[center]Sharp spines to damage any contacting body.[/center]'
	$Panel/RichTextLabel.text = txt

func _on_trail_upgrade_but_mouse_entered():
	var txt : String = '[center]A trail of toxic metabolites to damage pursuing hostiles.[/center]' 
	$Panel/RichTextLabel.text = txt


func _on_speed_upgrade_but_mouse_exited():
	$Panel/RichTextLabel.text = ''
func _on_boost_upgrade_but_mouse_exited():
	$Panel/RichTextLabel.text = ''
func _on_health_upgrade_but_mouse_exited():
	$Panel/RichTextLabel.text = ''
func _on_regen_upgrade_but_mouse_exited():
	$Panel/RichTextLabel.text = ''
func _on_spike_upgrade_but_mouse_exited():
	$Panel/RichTextLabel.text = ''
func _on_bodydamage_upgrade_but_mouse_exited():
	$Panel/RichTextLabel.text = ''
func _on_trail_upgrade_but_mouse_exited():
	$Panel/RichTextLabel.text = ''
