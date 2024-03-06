extends CanvasLayer

@onready var player = get_parent().get_node("Player")

# Notifies `Main` node that the button has been pressed
signal start_game
signal restart_game

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func restart_message():
	$RestartButton.show()

func _on_start_button_pressed():
	$StartButton.hide()
	global.start_button_pressed.emit()

func _on_restart_button_pressed():
	global.restart_button_pressed.emit()
