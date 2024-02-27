extends RigidBody2D
# extends Microbe

var screen_size
var pos_x
var pos_y
var mouse_pos = null
var mouse_vector
var speed : float = 3  # 3 good start value
var base_speed = speed
var stun : bool = false
# linear_velocity.length = speed * mass * constant

var level = 1
var xp = 0
var xp_required = {}

# TAIL
var tails: Array[Node]
var tail_node_draw_adjustment = Vector2(-39.25, 0)
var tail_swim_dir = 1  # for tail swim_animation()
var tail_thickness : float = 4
var tail_movement_rate : float
var tail_col = Color.BLACK

var boost_power : float = 1.5
var drain_boost : bool = false
var drain_rate : int = 100
var boost_regen : int = 20
var boost_key_held : bool

var health_regen_flat : float = 0
var health_regen_relative : float = 0

var trail_length = 50
var dead = false

@onready var map = get_parent().get_node("Map")

# Called when the node enters the scene tree for the first time.
func _ready():
	global.speed_button_pressed.connect(tail_lvl_up)
	global.boost_button_pressed.connect(boost_lvl_up)
	global.health_button_pressed.connect(health_lvl_up)
	global.regen_button_pressed.connect(regen_lvl_up)
	global.spike_button_pressed.connect(spike_lvl_up)
	global.bodydamage_button_pressed.connect(bodydamage_lvl_up)
	global.trail_button_pressed.connect(trail_lvl_up)
	get_levels()  # preloads xp_required for each level

	pos_x = randi_range(2000, map.size.x - 2000)
	pos_y = randi_range(2000, map.size.y - 2000)
	position = Vector2(pos_x, pos_y)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):

	# XP_BAR
	$Canvas/Xp_Bar/Level_Display.set_text(str(level))
	$Canvas/Xp_Bar.max_value = xp_required[level]
	$Canvas/Xp_Bar.value = xp
	$Canvas/Xp_Bar.show()
	
	if global.xp_points > 0:
		$Canvas/Xp_points.text = ('%s XP Points available!\nPress space to use' % global.xp_points)
		# $Canvas/Xp_points.text = 'XP points available! press space to use'
	else:
		$Canvas/Xp_points.text = ''
		
	
	# BOOST STAMINA LOGIC
		# hiding stamina bar
	if $Canvas/Boost_Bar.value == $Canvas/Boost_Bar.max_value or dead:
		$Canvas/Boost_Bar.hide()
	elif global.player_lvls['boost'] > 0: 
		$Canvas/Boost_Bar.show()
		# stamina recovery and expendature
	if dead:
		pass
	elif drain_boost == true:
		$Canvas/Boost_Bar.value -= drain_rate * _delta
	else:
		$Canvas/Boost_Bar.value += boost_regen * _delta
		# base speed when stamina runs out
	if $Canvas/Boost_Bar.value == 0:
		speed = base_speed
	
	# HEALTH REGEN
	if $Canvas/Health_Bar.value < $Canvas/Health_Bar.max_value and not dead:
		$Canvas/Health_Bar.value += health_regen_flat * _delta
		$Canvas/Health_Bar.value += $Canvas/Health_Bar.max_value * health_regen_relative * _delta
		$Node2D/Mitochondria/AnimatePulse.play('pulsation')
	else:
		$Node2D/Mitochondria/AnimatePulse.stop()
	queue_redraw()
 
	if not dead:
		var col_fade : float = ($Canvas/Health_Bar.value / $Canvas/Health_Bar.max_value)
		$Node2D/Sprite.modulate = Color(int(col_fade*250 + 5))  # alpha value, 255 max opacity
		$Node2D/BodySpike.modulate = Color(int(col_fade*150 + 105))

	# TRAIL
	if $Trail.is_visible_in_tree():
		$Trail/Trail_Line.set_as_top_level(true)
		$Trail/Trail_Line.add_point($Trail.global_position)
		if $Trail/Trail_Line.get_point_count() > trail_length:
			$Trail/Trail_Line.remove_point(0)


func _physics_process(_delta):
	# PLAYER MOVEMENT
	var min_move_dist = $CollisionShape.shape.height * 0.5
	var max_move_dist = 200
	mouse_pos = get_global_mouse_position()
	mouse_vector = Vector2(mouse_pos - global_position)
	
	# mouse_vector only positive outside min_move_dist
	if mouse_vector.length() < min_move_dist:
		mouse_vector *= 0
	else:
		mouse_vector *= (1 - min_move_dist/mouse_vector.length())
	
	# 3 possible areas to decide mouse_vector force
	if dead or stun or mouse_vector.length() == 0:  # inside min_move_distance
		get_node("Pointer").polygon[2].x = 50
		tail_movement_rate = 0
	elif mouse_vector.length() < max_move_dist:  # gradually increase speed
		apply_central_force(mouse_vector * speed)
		get_node("Pointer").polygon[2].x = (50 + 100 * mouse_vector.length()/max_move_dist)
		tail_movement_rate = 0.4 * mouse_vector.length()/max_move_dist
	elif mouse_vector.length() >= max_move_dist:  # max speed
		mouse_vector = mouse_vector.normalized()
		apply_central_force(mouse_vector * max_move_dist * speed)
		get_node("Pointer").polygon[2].x = 150
		tail_movement_rate = 0.4
	
	if drain_boost == true and $Canvas/Boost_Bar.value > 0:
		tail_movement_rate += 0.5  # faster tail for boost
	swim_animation(tail_movement_rate)

	# PLAYER ROTATION
	if not dead or stun:
		var rot_angle = get_local_mouse_position().angle()
		apply_torque(rot_angle * 15/(15+level)*10)

	# FAILED ATTEMPT TO STOP TAIL EXTENDING AT LONG LENGTHS 
	#for i in range(1, tails.size()-1):
	#	if abs($TailNode/tail_end.position.x) < 100:
	#		tails[i].linear_damp = 2
	#	if abs($TailNode/tail_end.position.x) > 100:
	#		tails[i].linear_damp = 4 / (1 + (abs($TailNode/tail_end.position.x)**3/10**6))
	#	if abs($TailNode/tail_end.position.x) > 500:
	#		tails[i].linear_damp = 0
	#	print(tails[1].linear_damp)

	# print('mass = ', mass)
	# print('force = ', speed)
	# print('speed_total = ', speed/mass)
	# print('speed = ', linear_velocity.length())
	# print('linear damp = ', linear_damp)

func xp_acquire(xp_gain):
	xp += xp_gain
	while xp >= xp_required[level] and level < 50:
		if level != 49:  # xp bar stay maxed
			xp -= xp_required[level]
		LevelUp()

func LevelUp():
	level += 1
	global.xp_points += 1
	var nurf_increment = 0.03 # lowers acceleration while maintaining top speed
	mass += mass*nurf_increment
	linear_damp -= linear_damp*nurf_increment
	scale_up()

func get_levels():
	var lvl1_10 = [10, 12, 14, 17, 20, 24, 29, 35, 42, 50]
	var value
	for i in range(50):
		if i < 10:
			value = lvl1_10[i]
		elif i >= 10 and i < 40:
			value += 5
		else:
			value += 10
		xp_required[i+1] = value

func scale_up():
	$Node2D/Sprite.scale += Vector2(0.002, 0.002)
	$Node2D/BodySpike.scale += Vector2(0.002, 0.002)
	$Spike.scale += Vector2(0.02, 0)
	$CollisionShape.shape.height += 2.2
	$CollisionShape.shape.radius += 0.8
	$Pointer.position.x += 1.1
	$Camera.zoom -= Vector2(0.008, 0.008)
	$TailNode.position += Vector2(- 1.1, 0)
	$Trail.position = $TailNode.position
	tail_node_draw_adjustment += Vector2(-1.1, 0)
	$Spike.position.x += 1.1
	

func can_upgrade(att : String):
	var eligible : bool
	if (global.xp_points > 0 and 
	global.player_lvls[att] != global.player_max_lvls[att]):
		eligible = true
	else:
		eligible = false  # no xp points or max lvl reached
	return eligible
	
func upgrade(att : String):
	global.player_lvls[att] += 1
	global.xp_points -= 1

func tail_lvl_up():
	if not can_upgrade("speed"):
		return
	
	upgrade("speed")
	speed = 3 + (global.player_lvls['speed'] * 0.2)  # 3 --> 7
	base_speed = speed
	
	if global.player_lvls["speed"] == 1:
		tails.append($TailNode/Anchor)
		tails.append($TailNode/tail_end)
		$TailNode.show()
		return
	
	# Identify old tail
	var old_tail_name
	var old_tail
	if global.player_lvls["speed"] == 2:
		old_tail_name = "Anchor"
		old_tail = $TailNode/Anchor
	else:
		old_tail_name = "tail_%s" % str(global.player_lvls["speed"]-1)
		old_tail = get_node("TailNode/%s" % old_tail_name)
	
	# New tail segment
	var new_tail = RigidBody2D.new()
	var new_tail_name = "tail_%s" % str(global.player_lvls["speed"])
	new_tail.name = new_tail_name
	var new_pos = Vector2((-8 * (global.player_lvls["speed"]-2)) -1, 0) + Vector2($TailNode/Anchor.position.x, 0)  # idk, this just apparently WORKS
	new_tail.position = new_pos
	new_tail.gravity_scale = 0
	new_tail.angular_damp_mode = RigidBody2D.DAMP_MODE_REPLACE
	new_tail.angular_damp = 1
	new_tail.set_collision_layer_value(1, false)
	new_tail.set_collision_layer_value(2, true)
	new_tail.set_collision_mask_value(1, true)
	new_tail.set_collision_mask_value(3, true)
	new_tail.set_collision_mask_value(5, true)
	new_tail.set_collision_mask_value(6, true)
	$TailNode.add_child(new_tail)
	
	# New CollisionShape
	var new_col = CollisionShape2D.new()
	new_col.shape = RectangleShape2D.new()
	new_col.shape.size = Vector2(4, 4)
	var new_tail_path = "TailNode/%s" % new_tail_name
	get_node(new_tail_path).add_child(new_col)
	
	# New Polygon
	var new_poly = Polygon2D.new()
	var arr = PackedVector2Array()
	arr.append(Vector2(-2 ,2))
	arr.append(Vector2(2, 2))
	arr.append(Vector2(2, -2))
	arr.append(Vector2(-2, -2))
	new_poly.polygon = arr
	new_poly.color = Color.BLACK
	get_node(new_tail_path).add_child(new_poly)
	
	# Build ordered tail node array
	tails.clear()
	tails.append($TailNode/Anchor)
	for child in $TailNode.get_children():
		if child.name.left(4) == "tail" and str(child.name)[5].is_valid_int():
			tails.append(child)
	tails.append($TailNode/tail_end)
	
	# reset tails position
	for i in tails.size():
		tails[i].rotation = 0
		# tails[i].position = Vector2((-8 * i), 0)
		tails[i].position = Vector2((-8 * i) - 1, 0) 
	
	# Pin_end, update old tail -> new tail
	$TailNode/Pin_end.set_node_a(NodePath("../%s" % new_tail_name))
	$TailNode/Pin_end.position = new_pos
	
	# New pinjoint, new_tail - old_tail
	var new_pin = PinJoint2D.new()
	new_pin.name = "pin_%s" % str(global.player_lvls["speed"])
	new_pin.set_node_a(NodePath("../%s" % new_tail_name))
	new_pin.set_node_b(NodePath("../%s" % old_tail_name))
	if global.player_lvls["speed"] == 2:  # 1st pinjoint
		new_pin.bias = 0.9
	# new_pin.bias = 0.3  # higher values more glitchy
	new_pin.disable_collision = true
	new_pin.position = new_pos
	$TailNode.add_child(new_pin)
	queue_redraw()

func _draw():  # draw tail
	var draw_start: Vector2
	var draw_end: Vector2
	for i in tails.size() - 1:
		draw_start = tails[i].position + $TailNode.position # + Vector2(2, 0)  # anchor pos + width
		draw_end = tails[i+1].position + $TailNode.position
		draw_line(draw_start, draw_end, tail_col, tail_thickness)

func swim_animation(move_dist: float):
	# reset to base position at rest
	if move_dist == 0:
		$TailNode/Anchor.position.y = 0
		$TailNode/Anchor.rotation = 0
		if tails.size() >= 3:
			$TailNode/pin_2.bias = 0.0  # relax tail base
		return
	elif tails.size() >= 3:
		$TailNode/pin_2.bias = 0.9  # tense tail base for flicking
		
	var max_dist : float = 2.0
	var flick_angle : int = 15  # think this dose nothing lol, no angular torsion force for pinjoint
	move_dist *= tail_swim_dir
	$TailNode/Anchor.position.y += move_dist
	
	# ROTATION tail anchor
	if tail_swim_dir == 1: 
		$TailNode/Anchor.rotation = -flick_angle
	elif tail_swim_dir == -1:
		$TailNode/Anchor.rotation = flick_angle
		# alternate method: Windscreen wiper movement
		# $TailNode/Anchor.rotation = $TailNode/Anchor.position.y * 15
		
	if abs($TailNode/Anchor.position.y) > max_dist:
		tail_swim_dir *= -1

func boost_lvl_up():
	if can_upgrade("boost"):
		upgrade("boost")	
		boost_power += 0.2  # 1.5 --> 3.1 max lvl
		drain_rate -= 8
		tail_thickness += 0.5
		# testing
		# print('boost len: ', 100/float(drain_rate), 's')  # 1s --> 2.77sec
		# print('boost pow: ', boost_power  # 3 --> 6.2 
	
func boost():
	if global.player_lvls["boost"] > 0 and $Canvas/Boost_Bar.value > 0 and not stun:
		speed += boost_power + 0.2*boost_power*level/10
		drain_boost = true
		boost_key_held = true
	else:
		return

func stop_boost():
	if global.player_lvls["boost"] > 0:
		speed = base_speed
		drain_boost = false
		boost_key_held = false
	else:
		return

func health_lvl_up():
	if can_upgrade("health"):
		upgrade("health")
		# skin thickness up
		$Node2D/Sprite.animation = str(global.player_lvls["health"])
		if global.player_lvls["health"] % 3 == 0:  # shrink sprite to match collision shape
			$Node2D/Sprite.scale -= Vector2(0.001, 0.001)
		# stats upgrade
		$Canvas/Health_Bar.max_value += 10
		$Canvas/Health_Bar.max_value += int($Canvas/Health_Bar.max_value * 0.1)  
		# 100 --> 752 max value (15 upgrade slots)

func regen_lvl_up():
	if can_upgrade("regen"):
		upgrade('regen')
		if global.player_lvls["regen"] == 1:
			$Node2D/Mitochondria.show()
		else:
			$Node2D/Mitochondria.scale += Vector2(0.001, 0.003)
		var animation : AnimationPlayer = $Node2D/Mitochondria/AnimatePulse
		animation.get_animation('pulsation').track_set_key_value(0, 0, $Node2D/Mitochondria.scale)
		animation.get_animation('pulsation').track_set_key_value(0, 1, $Node2D/Mitochondria.scale*1.2)
		animation.get_animation('pulsation').track_set_key_value(0, 2, $Node2D/Mitochondria.scale)
		health_regen_flat += 0.5
		health_regen_relative += 0.002
		# max regen 7hp/s at min skin thickness
		# max regen 14hp/s at max skin thickness

func spike_lvl_up():
	if can_upgrade("spike"):
		upgrade('spike')
		if global.player_lvls["spike"] == 1:
			$Spike.show()
		else:
			# var width : float = 1.0/(10+global.player_lvls["spike"]*3)
			# $Spike.scale += Vector2(width, 0.7)
			$Spike.scale += Vector2(0, 0.7)


func bodydamage_lvl_up():
	if can_upgrade("bodydamage"):
		upgrade("bodydamage")
		if global.player_lvls["bodydamage"] == 1:
			$Node2D/BodySpike.show()
		$Node2D/BodySpike.animation = str(global.player_lvls["bodydamage"])


func trail_lvl_up():
	if can_upgrade("trail"):
		upgrade("trail")
		if global.player_lvls["trail"] == 1:
			$Trail.show()
			return
		$Trail/Trail_Particles.amount = 8 + global.player_lvls["trail"] * 8
		$Trail/Trail_Particles.lifetime = 2 + global.player_lvls["trail"] * 0.2
		trail_length = 50 + (global.player_lvls["trail"]-1)*40
		# Trail gradient visuals
		var grad : Gradient = Gradient.new()
		var green_inc : int = (global.player_lvls["trail"]-1)*10
		var opacity_inc : int = (global.player_lvls["trail"]-1)*10
		var fade_point : float = 1 - (float(trail_length - 50)/trail_length)
		var old_green = Color8(30, 80, 40, 80 + opacity_inc)
		var new_green = Color8(30, 80 + green_inc, 40, 80 + opacity_inc)
		# var new_purple = Color8(30 + green_inc, 80 - green_inc, 40 + green_inc*2, 80 + opacity_inc)
		grad.set_color(1, new_green)  # start of trail
		grad.add_point(fade_point, old_green)  # 50 pixels from end of trail
		grad.set_color(0, Color8(0, 30, 10, 0))  # end of trail
		grad.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_LINEAR
		$Trail/Trail_Line.gradient = grad
		

func _on_body_entered(body):
	if body.name.left(9) == 'Spikeball':
		spikeball_collision(body)
	elif body.name == 'World_Bound' and false:  # DISABLED
		# var pos = position
		world_bound_collision(body)

func _on_spike_area_body_entered(body):
	if body.name.left(9) == 'Spikeball':
		spikeball_collision(body)
	elif body.name == 'World_Bound':
		# var pos = to_global($Spike/Spike_Area/CollisionPolygon2D.polygon[2])
		# var pos = $Spike/Spike_Area/CollisionPolygon2D.polygon[2]
		# pos = to_global($Spike.position + Vector2(0, 8.9 + global.player_lvls["spike"]*6.2))
		world_bound_collision(body)

func spikeball_collision(body):
	# Take damage
	var damage_taken = int(10 + (linear_velocity.length() * 0.05))
	# print('oowie : ', linear_velocity.length()*0.05, ', + 10')
	$Canvas/Health_Bar.value -= damage_taken
		
	# Push player
	var push_dir = (position - body.global_position).normalized()
	var const_push = push_dir * mass * 100
	var vel_push = push_dir * linear_velocity.length() * mass
	var impulse_vect = const_push + vel_push
	apply_impulse(impulse_vect)
		
	# Stun player
	drain_boost = false
	$Stun.start()
	stun = true
	speed = 0

func _on_stun_timeout():
	stun = false
	speed = base_speed
	if boost_key_held:
		boost()

func world_bound_collision(body):
	var push_dir : Vector2
	var detection_dist = 50 + level + global.player_lvls["spike"]*8.5
	if position.x < detection_dist:  # LEFT BOUND
		push_dir = Vector2(1, 0)
	if position.x > (map.size.x - detection_dist):  # RIGHT BOUND
		push_dir += Vector2(-1, 0)
	if position.y < detection_dist:  # TOP BOUND
		push_dir += Vector2(0, 1)
	if position.y > (map.size.y - detection_dist):  # BOTTOM BOUND
		push_dir += Vector2(0, -1)
	var impulse_vect = push_dir * mass * 300
	apply_impulse(impulse_vect)
	# spike not detected at angles still :/

func death():
	dead = true
	$Canvas/Boost_Bar.value = 0
	$Trail.hide()
	
	var dead_col = Color8(0, 0, 0, 80)
	var time = 5.0  # sec
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_parallel(true)
	tween.tween_property($Node2D/Sprite, 'modulate', dead_col, time)
	tween.tween_property($Node2D/Mitochondria, 'modulate', dead_col, time)
	tween.tween_property($Node2D/BodySpike, 'modulate', dead_col, time)
	tween.tween_property($Spike/Sprite2D, 'modulate', dead_col, time)
	tween.tween_property(self, 'tail_col', dead_col, time)
	for tail in $TailNode.get_children():
		for poly in tail.get_children():
			if poly is Polygon2D:
				tween.tween_property(poly, 'modulate', Color(0), time)  # tail_polygons dissapear

# TODO
# clean player code and reproduce for enemy mobs
# change sprite to gray instead of alpha on death


# Things to improve/fix:
	# spike collision with walls
	# tail stretch
