extends Microbe

var screen_size
var mouse_pos = null
var mouse_vector
var boost_key_held : bool

# Called when the node enters the scene tree for the first time.
func _ready():
	super()
	global.speed_button_pressed.connect(speed_lvl_up)
	global.boost_button_pressed.connect(boost_lvl_up)
	global.health_button_pressed.connect(health_lvl_up)
	global.regen_button_pressed.connect(regen_lvl_up)
	global.spike_button_pressed.connect(spike_lvl_up)
	global.bodydamage_button_pressed.connect(bodydamage_lvl_up)
	global.trail_button_pressed.connect(trail_lvl_up)
	level = 1
	xp_points = 0
	random_pos()

func random_pos():
	pos_x = randi_range(2000, map.size.x - 2000)
	pos_y = randi_range(2000, map.size.y - 2000)
	position = Vector2(pos_x, pos_y)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	super(_delta)  

	# HEALTH BAR
	$Canvas/Health_Bar.value = health
	$Canvas/Health_Bar.max_value = max_health

	# XP_BAR
	$Canvas/Xp_Bar/Level_Display.set_text(str(level))
	$Canvas/Xp_Bar.max_value = xp_required[level]
	$Canvas/Xp_Bar.value = xp
	$Canvas/Xp_Bar.show()
	
	if global.xp_points > 0:
		$Canvas/Xp_points.text = ('%s XP Points available!\nPress space to use' % global.xp_points)
	else:
		$Canvas/Xp_points.text = ''

	# BOOST STAMINA LOGIC
	$Canvas/Boost_Bar.max_value = boost_max_capacity
	$Canvas/Boost_Bar.value = boost_capacity
		# hiding stamina bar
	if boost_capacity == boost_max_capacity or dead:
		$Canvas/Boost_Bar.hide()
	elif upgrade_lvls['boost'] > 0: 
		$Canvas/Boost_Bar.show()
		# stamina recovery and expendature

func _physics_process(_delta):
	# PLAYER MOVEMENT
	var min_move_dist = $Bod.shape.height * 0.5
	var max_move_dist = 200
	mouse_pos = get_global_mouse_position()
	mouse_vector = Vector2(mouse_pos - global_position)
	
	# mouse_vector adjust magnitude to | min_move_dist <-> max_move_dist |
	if mouse_vector.length() < min_move_dist:
		mouse_vector *= 0
	else:
		mouse_vector *= (1 - min_move_dist/mouse_vector.length())
	
	# 3 possible areas to decide mouse_vector force
	if mouse_vector.length() == 0:  # inside min_move_distance
		tail_movement_rate = 0
	elif mouse_vector.length() < max_move_dist:  # gradually increase speed
		apply_central_force(mouse_vector * speed)
		tail_movement_rate = 0.4 * mouse_vector.length()/max_move_dist
	elif mouse_vector.length() >= max_move_dist:  # max speed
		mouse_vector = mouse_vector.normalized()
		apply_central_force(mouse_vector * max_move_dist * speed)
		tail_movement_rate = 0.4

	# PLAYER ROTATION
	if not dead or stun:
		var rot_angle = get_local_mouse_position().angle()
		if abs(rot_angle) > 1:  # 57 degrees
			rot_angle /= abs(rot_angle)  # constant value
		apply_torque(rot_angle * rotation_scalar)
	super(_delta)

func LevelUp():
	super()
	global.xp_points = xp_points

func scale_up():
	super()
	$Camera.zoom -= Vector2(0.008, 0.008)

func upgrade(att : String):
	super(att)
	global.player_lvls[att] = upgrade_lvls[att]
	global.xp_points = xp_points

func health_lvl_up():
	super()
	$Canvas/Health_Bar.max_value = max_health
	$Canvas/Health_Bar.value = health

func boost():
	super()
	boost_key_held = true

func stop_boost():
	super()
	boost_key_held = false

func _on_stun_timeout():
	super()
	if boost_key_held:
		boost()


	# print('mass = ', mass)
	# print('force = ', speed)
	# print('speed_total = ', speed/mass)
	# print('speed = ', linear_velocity.length())
	# print('linear damp = ', linear_damp)
