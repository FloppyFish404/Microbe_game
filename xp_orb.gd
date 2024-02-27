extends Area2D

@onready var player = get_parent().get_node("Player")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_body_entered(body):  
	# only microbes can collide set with collision masks
	body.xp_acquire(300)
	body.health += 1
	queue_free() # remove xp_orb
