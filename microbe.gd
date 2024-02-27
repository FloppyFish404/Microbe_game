# @icon("res://custom_class_icons/Microbe.svg")  # ccbs
class_name Microbe extends RigidBody2D

var pos_x : float
var pos_y : float
var speed : float = 3  # 3 good start value
var base_speed = speed
var rotation_scalar : float = 100000
var stun : bool = false

var level : int 
var xp : int = 0 
var xp_points : float = 0
var xp_required : Dictionary = { 
1: 10, 2: 12, 3: 14, 4: 17, 5: 20, 6: 24, 7: 29, 8: 35, 9: 42, 10: 50, 
11: 55, 12: 60, 13: 65, 14: 70, 15: 75, 16: 80, 17: 85, 18: 90, 19: 95, 20: 100, 
21: 105, 22: 110, 23: 115, 24: 120, 25: 125, 26: 130, 27: 135, 28: 140, 29: 145, 30: 150, 
31: 155, 32: 160, 33: 165, 34: 170, 35: 175, 36: 180, 37: 185, 38: 190, 39: 195, 40: 200, 
41: 210, 42: 220, 43: 230, 44: 240, 45: 250, 46: 260, 47: 270, 48: 280, 49: 290, 50: 300 
}

var upgrade_lvls : Dictionary = {
	"speed" = 0,
	"boost" = 0,
	"health" = 0,
	"regen" = 0,
	"spike" = 0,
	"bodydamage" = 0,
	"trail" = 0
}

var max_upgrade_lvls : Dictionary = {
	"speed" = 20,
	"boost" = 8,
	"health" = 15,
	"regen" = 10,
	"spike" = 20,
	"bodydamage" = 10,
	"trail" = 8
}

# TAIL
var tails : Array[Node]
var tail_node_draw_adjustment : Vector2 = Vector2(-39.25, 0)
var tail_swim_dir : int = 1  # for tail swim_animation()
var tail_thickness : float = 4
var tail_movement_rate : float
var tail_col = Color.BLACK

var boost_max_capacity : float = 100
var boost_capacity : float = boost_max_capacity
var boost_power : float = 1.5
var drain_boost : bool = false
var drain_rate : int = 100
var boost_regen : int = 20

var max_health : float = 100
var health : float = 100

var health_regen_flat : float = 0
var health_regen_relative : float = 0
var mit_tween : Tween 
var mit_tween_exists : bool = false
var mit_grow_size : Vector2
var mit_base_size : Vector2

var spike_damage : int = 5

var bodydamage : int = 0

var trail_length = 50
var dead : bool = false

@onready var map = get_parent().get_node("Map")


# Called when the node enters the scene tree for the first time.
func _ready():
	pass
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):

	# BOOST STAMINA LOGIC
	# boost capacity range
	if boost_capacity > boost_max_capacity:
		boost_capacity = boost_max_capacity
	if boost_capacity < 0:
		boost_capacity = 0
	
	# stamina recovery and expendature
	elif drain_boost == true and boost_capacity > 0:
		boost_capacity -= drain_rate * _delta
	elif boost_capacity < boost_max_capacity and not drain_boost:
		boost_capacity += boost_regen * _delta
	if boost_capacity == 0:
		speed = base_speed 	# base speed when stamina runs out

	# HEALTH REGEN
	# health range
	if health > max_health:
		health = max_health
	if health < 0:
		health = 0
		death()

	if upgrade_lvls['regen'] > 0:
		if health < max_health and not dead:
			health += health_regen_flat * _delta
			health += max_health * health_regen_relative * _delta
			if not mit_tween_exists:
				mit_tween = create_mitochondria_tween()
				#mit_tween.play()
		elif mit_tween_exists:
			mit_tween.kill()
			$Node2D/Mitochondria.scale = mit_base_size
			mit_tween_exists = false
	queue_redraw()
 
	if not dead:
		var col_fade : float = (health / max_health)
		$Node2D/Sprite.modulate = Color(int(col_fade*250 + 5))  # alpha value, 255 max opacity
		$Node2D/BodySpike.modulate = Color(int(col_fade*150 + 105))

	# TRAIL
	if $Trail.is_visible_in_tree():
		$Trail/Trail_Line.set_as_top_level(true)
		$Trail/Trail_Line.add_point($Trail.global_position)
		if $Trail/Trail_Line.get_point_count() > trail_length:
			$Trail/Trail_Line.remove_point(0)

func _physics_process(_delta):
	if dead or stun:  # inside min_move_distance
		speed = 0
		tail_movement_rate = 0
	if drain_boost == true and boost_capacity > 0:
		tail_movement_rate += 0.5  # faster tail for boost
	swim_animation(tail_movement_rate * _delta * 50)

func xp_acquire(xp_gain):
	xp += xp_gain
	while xp >= xp_required[level] and level < 50:
		if level != 49:  # xp bar stay maxed
			xp -= xp_required[level]
		LevelUp()

func LevelUp():
	level += 1
	xp_points += 1
	var nurf_increment = 0.03 # lowers acceleration while maintaining top speed
	mass += mass*nurf_increment
	linear_damp -= linear_damp*nurf_increment
	rotation_scalar *=  1.04 #(level)**1.5/15.0  # assists rotation with increasing mass
	scale_up()

func scale_up():
	$Node2D/Sprite.scale += Vector2(0.002, 0.002)
	$Node2D/BodySpike.scale += Vector2(0.002, 0.002)
	$Spike.scale += Vector2(0.02, 0)
	$Bod.shape.height += 2.2
	$Bod.shape.radius += 0.8
	$TailNode.position += Vector2(- 1.1, 0)
	$Trail.position = $TailNode.position
	tail_node_draw_adjustment += Vector2(-1.1, 0)
	$Spike.position.x += 1.1

func can_upgrade(att : String):
	var eligible : bool
	if (xp_points > 0 and 
	upgrade_lvls[att] != max_upgrade_lvls[att]):
		eligible = true
	else:
		eligible = false  # no xp points or max lvl reached
	return eligible
	
func upgrade(att : String):
	upgrade_lvls[att] += 1
	xp_points -= 1

func speed_lvl_up():
	if not can_upgrade("speed"):
		return
	
	upgrade("speed")
	speed = 3 + (upgrade_lvls['speed'] * 0.2)  # 3 --> 7
	base_speed = speed
	
	if upgrade_lvls['speed'] == 1:
		tails.append($TailNode/Anchor)
		tails.append($TailNode/tail_end)
		$TailNode.show()
		return
	
	# Identify old tail
	var old_tail_name
	var old_tail
	if upgrade_lvls['speed'] == 2:
		old_tail_name = "Anchor"
		old_tail = $TailNode/Anchor
	else:
		old_tail_name = "tail_%s" % str(upgrade_lvls['speed']-1)
		old_tail = get_node("TailNode/%s" % old_tail_name)
	
	# New tail segment
	var new_tail = RigidBody2D.new()
	var new_tail_name = "tail_%s" % str(upgrade_lvls["speed"])
	new_tail.name = new_tail_name
	var new_pos = Vector2((-8 * (upgrade_lvls['speed']-2)) -1, 0) + Vector2($TailNode/Anchor.position.x, 0)  # idk, this just apparently WORKS
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
	new_pin.name = "pin_%s" % str(upgrade_lvls['speed'])
	new_pin.set_node_a(NodePath("../%s" % new_tail_name))
	new_pin.set_node_b(NodePath("../%s" % old_tail_name))
	if upgrade_lvls['speed'] == 2:  # 1st pinjoint
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
		
	if $TailNode/Anchor.position.y > max_dist:
		tail_swim_dir *= -1
	elif $TailNode/Anchor.position.y < -max_dist:
		tail_swim_dir = abs(tail_swim_dir)


func boost_lvl_up():
	if can_upgrade("boost"):
		upgrade("boost")	
		boost_power += 0.2  # 1.5 --> 3.1 max lvl
		drain_rate -= 8
		tail_thickness += 0.5
		queue_redraw()
		# testing
		# print('boost len: ', 100/float(drain_rate), 's')  # 1s --> 2.77sec
		# print('boost pow: ', boost_power  # 3 --> 6.2 
	
func boost():
	if upgrade_lvls['boost'] > 0 and boost_capacity > 0 and not stun:
		speed += boost_power + 0.2*boost_power*level/10
		drain_boost = true
	else:
		return

func stop_boost():
	if upgrade_lvls["boost"] > 0:
		speed = base_speed
		drain_boost = false
	else:
		return

func health_lvl_up():
	if can_upgrade("health"):
		upgrade("health")
		# skin thickness up
		$Node2D/Sprite.animation = str(upgrade_lvls["health"])
		if upgrade_lvls["health"] % 3 == 0:  # shrink sprite to match collision shape
			$Node2D/Sprite.scale -= Vector2(0.001, 0.001)
		# stats upgrade
		var new_max : int = max_health + 10 + int(max_health* 0.1) 
		var increase = new_max - max_health
		max_health = new_max
		health += increase  # add health from upgrade
		# 100 --> 726 max value (15 upgrade slots)

func regen_lvl_up():
	if can_upgrade("regen"):
		upgrade('regen')
		if mit_tween_exists:
			mit_tween.kill()
			mit_tween_exists = false
		if upgrade_lvls["regen"] == 1: 
			$Node2D/Mitochondria.show()
		else:
			$Node2D/Mitochondria.scale = mit_base_size
			$Node2D/Mitochondria.scale += Vector2(0.001, 0.003)
			# print(name, $Node2D/Mitochondria.scale, upgrade_lvls["regen"])
		mit_grow_size = $Node2D/Mitochondria.scale * 1.2
		mit_base_size = $Node2D/Mitochondria.scale
		health_regen_flat += 0.5
		health_regen_relative += 0.002
		# max regen 7hp/s at min skin thickness
		# max regen 14hp/s at max skin thickness

func create_mitochondria_tween():
	mit_tween_exists = true
	#var tween = $Node2D/Mitochondria.create_tween()
	var tween = create_tween()
	tween.set_loops()  # runs indefinitely
	tween.tween_property($Node2D/Mitochondria, 'scale', mit_grow_size, 0.5)
	tween.tween_property($Node2D/Mitochondria, 'scale', mit_base_size, 0.5)
	return tween
	
func spike_lvl_up():
	if can_upgrade("spike"):
		upgrade('spike')
		spike_damage = 5 + upgrade_lvls["spike"]*3
		if upgrade_lvls["spike"] == 1:
			$Spike.disabled = false
			$Spike.show()
		else:
			$Spike/Spike_sprite.scale += Vector2(0, 0.004)
			$Spike.polygon[2] += Vector2(0, -5)
			# $Spike.scale += Vector2(0, 0.7)


func bodydamage_lvl_up():
	if can_upgrade("bodydamage"):
		upgrade("bodydamage")
		bodydamage = upgrade_lvls["bodydamage"] * 2
		if upgrade_lvls["bodydamage"] == 1:
			$Node2D/BodySpike.show()
		$Node2D/BodySpike.animation = str(upgrade_lvls["bodydamage"])

func trail_lvl_up():
	if can_upgrade("trail"):
		upgrade("trail")
		if upgrade_lvls["trail"] == 1:
			$Trail.show()
			return
		$Trail/Trail_Particles.amount = 8 + upgrade_lvls["trail"] * 8
		$Trail/Trail_Particles.lifetime = 2 + upgrade_lvls["trail"] * 0.2
		trail_length = 50 + (upgrade_lvls["trail"]-1)*40
		# Trail gradient visuals
		var grad : Gradient = Gradient.new()
		var green_inc : int = (upgrade_lvls["trail"]-1)*10
		var opacity_inc : int = (upgrade_lvls["trail"]-1)*10
		var fade_point : float = 1 - (float(trail_length - 50)/trail_length)
		var old_green = Color8(30, 80, 40, 80 + opacity_inc)
		var new_green = Color8(30, 80 + green_inc, 40, 80 + opacity_inc)
		# var new_purple = Color8(30 + green_inc, 80 - green_inc, 40 + green_inc*2, 80 + opacity_inc)
		grad.set_color(1, new_green)  # start of trail
		grad.add_point(fade_point, old_green)  # 50 pixels from end of trail
		grad.set_color(0, Color8(0, 30, 10, 0))  # end of trail
		grad.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_LINEAR
		$Trail/Trail_Line.gradient = grad

func _on_body_shape_entered(body_rid, body, body_shape_index, local_shape_index):
	if body.name.left(4) == 'tail':
		pass
	else:
		var body_shape_owner = body.shape_find_owner(body_shape_index)
		var body_shape_node = body.shape_owner_get_owner(body_shape_owner)
		var local_shape_owner = shape_find_owner(local_shape_index)
		var local_shape_node = shape_owner_get_owner(local_shape_owner)
		print('self: ', self.name, local_shape_node.name)
		print('other body: ', body, ', ', body.name)
		print('other body shape: ', body_shape_node, ', ', body_shape_node.name, '\n')
	
		if body.name.left(9) == 'Spikeball':
			spikeball_hit(body)
		if body_shape_node.name == 'Spike':
			spike_hit(body)
		if body_shape_node.name == 'Bod':
			body_hit(body)
			print('do body damage now! ouch!')
		# elif body_shape_node.name == 'Mob'

func spikeball_hit(body):
	# Take damage
	var damage_taken = int(10 + (linear_velocity.length() * 0.05))
	health -= damage_taken
		
	# Push microbe
	var push_dir = (position - body.global_position).normalized()
	var const_push = push_dir * mass * 100
	var vel_push = push_dir * linear_velocity.length() * mass
	var impulse_vect = const_push + vel_push
	apply_impulse(impulse_vect)
		
	# Stun microbe
	drain_boost = false
	$Stun.start()
	stun = true
	speed = 0

func _on_stun_timeout():
	stun = false
	speed = base_speed

func spike_hit(body):
	var push_dir = (position - body.global_position).normalized()
	var const_push = push_dir * mass * 200
	var vel_push = push_dir * linear_velocity.length() * mass * 0.2
	var impulse_vect = const_push + vel_push
	apply_impulse(impulse_vect)
	health -= body.spike_damage
	print(body.spike_damage)

func body_hit(body):
	health -= body.bodydamage

func death():
	dead = true
	base_speed = 0
	spike_damage = 0
	bodydamage = 0
	$Trail.hide()
	var dead_col = Color8(0, 0, 0, 80)
	var time = 1.0  # sec
	
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
# dealing damage:
	# trail
# xp gain on mob death
	#last to touch on death? 
	# if you touch dead body?
	# dead body drops xp orbs?
# mob behaviour
# blue '5' xp orb
# stop excessive tail swing


# Things to improve/fix:
	# spike collision with walls
	# tail stretch
	# change sprite to gray instead of alpha on death
	# stop overlap spawning in main

# ideas
	# - make spike damage dependant on impact speed?
	# make delay after damage taken before mito starts working
