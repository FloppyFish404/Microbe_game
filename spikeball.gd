extends StaticBody2D

# @onready var player = get_parent().get_node("Player")
var shrinking : bool = false
var redness : float 
# Called when the node enters the scene tree for the first time.
func _ready():
	name = 'Spikeball'
	scale *= randf_range(0.5, 2) * randf_range(0.5, 2)
	$Timer_start_shrink.wait_time = randi_range(120, 300)  # 120, 300
	$Timer_start_shrink.start()
	redness = 0.6 - (scale.x * 0.15)
	$Sprite2D.modulate = Color(redness, 0.0, 0.0)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if shrinking:
		scale -= Vector2(delta, delta)*0.05
		redness = 0.6 - (scale.x * 0.15)
		$Sprite2D.modulate = Color(redness, 0.0, 0.0)
	if scale.x <= 0:
		queue_free()

func _on_timer_start_shrink_timeout():
	shrinking = true
	pass # Replace with function body.
