extends Area2D

@onready var player = get_parent().get_node("Player")

# Called when the node enters the scene tree for the first time.
func _ready():
	name = 'xp_orb'

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_body_entered(body):  
	# only microbes can collide set with collision masks
	body.xp_acquire(10)
	body.health += 1
	queue_free() # remove xp_orb
