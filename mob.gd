extends Microbe

var has_objective : bool = false
var target
var direction : Vector2 = Vector2(0, 0) # argument for apply_central_force() in _process()
var free_roam_dir : Vector2 = Vector2(randi_range(-1, 1), randi_range(-1, 1)).normalized()
var boundary_close : bool = false
var aggression : int = randi_range(-10, 10)
var trail_redirect : bool = false

var upgrade_probs : Dictionary = {  # list of all upgrades with probability values that sum to 1
	'speed' : 0.0, 
	'boost' : 0.0,
	'health' : 0.0,
	'regen' : 0.0,
	'spike' : 0.0,
	'bodydamage' : 0.0,
	'trail' : 0.0
}

# Called when the node enters the scene tree for the first time.
func _ready():
	name = 'Mob'
	var lvl : int = randi_range(1, 45)
	for i in range(lvl):
		LevelUp()
	get_probs()
	# position = Vector2(500, 500)  # TESTING

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	super(delta)
	if xp_points > 0:
		roulette_wheel()

	if not has_objective:
		find_target()
	if has_objective:
		pursue_target()
	else:  # no objective found - free roaming
		free_roam()

	if Engine.get_process_frames() % 20 == 0:  # recalc target
		find_target()
		
func _physics_process(delta):
	if trail_redirect:
		direction = direction.orthogonal()
		trail_redirect = false
	var force = direction * speed * 200
	apply_central_force(force)
	tail_movement_rate = force.length() * delta * 0.03
	swim_animation(tail_movement_rate)
	var rot = calc_rotation()
	apply_torque(rot)
	super(delta)


func calc_rotation() -> float:
	var rot : float = (direction.angle() - rotation)
	if abs(rot) > PI:  # aviod pos-neg sign switch at PI radians
		rot *= -1
		rot *= (2*PI - abs(rot))/abs(rot)
	if abs(rot) > 1:
		rot = rot/abs(rot)  # normalise to 1
	rot *= rotation_scalar
	return rot

func roulette_wheel():
	# picks attribute to upgrade
	var rand : float = randf()
	for att in upgrade_probs.keys():  
		rand -= upgrade_probs[att]
		if rand < 0.0:
			var upgrade_name : String = str(att) + '_lvl_up'
			call(upgrade_name)
			if upgrade_lvls[att] == max_upgrade_lvls[att]:
				adjust_probs()
			return

func get_probs():
	var prob_sum : float = 0
	var spread : int = randi_range(0,7) # spread of the probabilities towards extremes
	for key in upgrade_probs.keys():
		var prob = randf()**spread * max_upgrade_lvls[key]**(spread/7.0)
		upgrade_probs[key] = prob
		prob_sum += prob
	for key in upgrade_probs.keys():
		upgrade_probs[key] /= prob_sum

func adjust_probs():  #UNTESTED
	# if an upgrade is maxed, scale other upgrade probabilities up accordingly
	var prob_sum : float = 0
	for att in upgrade_lvls.keys():
		if upgrade_lvls[att] == max_upgrade_lvls[att]:
			upgrade_probs[att] = 0
		prob_sum += upgrade_probs[att]
	var scalar : float = 1/prob_sum
	for att in upgrade_probs.keys():
		upgrade_probs[att] *= scalar

func find_target():
	has_objective = false
	target = null
	var seen_objects : Array = $Scanner.get_overlapping_areas()
	seen_objects += $Scanner.get_overlapping_bodies()
	if seen_objects.size() == 0:
		return
		
	for obj in seen_objects:
		if (obj.name.left(9) == 'Spikeball'):
			var concern_dist : float = ($Scanner/CollisionShape2D.shape.radius * $Scanner.scale.x)
			concern_dist *= linear_velocity.length()/2000
			concern_dist *= 1 - upgrade_lvls['health']/max_upgrade_lvls['health']
			concern_dist /= 0.8 + 0.2*(health/max_health)
			concern_dist += 70 * (obj.scale.x)/2
			concern_dist += 40 + level*2
			concern_dist += upgrade_lvls['spike'] * 5
			if concern_dist > (global_position - obj.get_global_position()).length():
				has_objective = true
				target = obj
	
	if not has_objective:
		for obj in seen_objects:
			var closest_mob = $Scanner/CollisionShape2D.shape.radius * $Scanner.scale.x
			if (obj.name.left(3) == 'Mob' or obj.name.left(6) == 'Player') and self != obj:
				has_objective = true
				var mob_dist = (global_position - obj.get_global_position()).length()
				if mob_dist < closest_mob:  # target closest mob
					target = obj
					closest_mob = mob_dist 

	if not has_objective:
		boundary_close = false
		var closest_xp = $Scanner/CollisionShape2D.shape.radius * $Scanner.scale.x
		for obj in seen_objects:
			if obj.name.left(6) == 'xp_orb':
				has_objective = true
				var xp_dist = (global_position - obj.get_global_position()).length()
				if xp_dist < closest_xp:  # target closest xp orb
					target = obj
					closest_xp = xp_dist
			if obj.name.left(11) == 'World_Bound':
				boundary_close = true

func pursue_target() -> void:
		if is_instance_valid(target):
			if target.name.left(3) == 'Mob' or target.name.left(6) == 'Player':
				var eval = fight_or_flight()
				if eval < 0:  # RUN
					direction = (global_position - target.get_global_position()).normalized()
				elif eval > 0:  # KILL HIM
					var target_pos : Vector2 = target.get_global_position()
					var see_ahead : Vector2 = target.linear_velocity
					see_ahead *= (0.2 * (level+10)/10)
					see_ahead *= 1 + (upgrade_lvls['speed']/max_upgrade_lvls['speed'])
					var predicted_pos : Vector2 = target_pos + see_ahead
					direction = (predicted_pos - global_position).normalized()
				boost_if_urgent(eval)
				free_roam_dir = direction

			elif target.name.left(6) == 'xp_orb':
				direction = (target.get_global_position() - global_position).normalized()
			elif target.name.left(9) == 'Spikeball':
				direction = (global_position - target.get_global_position()).normalized()
		else:
			has_objective = false
			target = null

func fight_or_flight():
	var eval
	if upgrade_lvls['spike'] == 0 and upgrade_lvls['bodydamage'] == 0:
		eval = -10  # no damage from ramming, don't fight
		return eval
	elif 20 > (health/max_health)*100 - aggression:
		eval = -10
		return eval  # low health, run
	
	eval = aggression + (level - target.level)
	eval += (upgrade_lvls['spike'] - target.upgrade_lvls['spike'])
	eval += 20 * ((health/max_health) - (target.health/target.max_health))
	eval -= (target.get_global_position() - global_position).length() / 100
	return eval

func boost_if_urgent(eval) -> void:
	if abs(eval) > 9 and boost_capacity > 20 and not drain_boost:  # seriously situation
		boost()
	if drain_boost and (boost_capacity == 0 or abs(eval) < 9):
		stop_boost()

func free_roam():
	direction = free_roam_dir
	var adjust_dir : Vector2 = Vector2(randi_range(-1, 1), randi_range(-1, 1)) * 0.05
	# avoid world bound
	if boundary_close == true:
		adjust_dir += Vector2(map.size/2 - global_position).normalized() * 0.005  # redirect to middle of map slowly
	free_roam_dir = (free_roam_dir + adjust_dir).normalized()

func scale_up():
	super()
	$Scanner.scale += Vector2(0.01, 0.01)

func death():
	super()
	$Respawn_Timer.start()

func _on_respawn_timer_timeout():
	queue_free()
