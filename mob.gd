extends Microbe

var has_objective : bool = false
var target
var direction : Vector2 = Vector2(0, 0) # argument for apply_central_force() in _process()
var free_roam : Vector2 = Vector2(randi_range(-1, 1), randi_range(-1, 1)).normalized()
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
	var lvl : int = randi_range(1, 25)
	for i in range(lvl):
		LevelUp()
	get_probs()
	position = Vector2(500, 500)  # TESTING ONLY, DEL ME


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	super(delta)
	if xp_points > 0:
		roulette_wheel()
	var seen_objects : Array = $Scanner.get_overlapping_areas()
	
	if not has_objective:  # search for objective
		var closest_xp_dist = $Scanner/CollisionShape2D.shape.radius * $Scanner.scale.x
		for obj in seen_objects:
			if obj.name.left(6) == 'xp_orb':
				has_objective = true
				var xp_dist = (global_position - obj.get_global_position()).length()
				print(obj.name, ', ', xp_dist)
				if xp_dist < closest_xp_dist:
					target = obj
					closest_xp_dist = xp_dist
		# no objective found
		direction = free_roam * 0.5
		var adjust_dir : Vector2 = Vector2(randi_range(-1, 1), randi_range(-1, 1)) * 0.05
		# avoid world bound
		if (position.x < 1000 or position.x > (map.size.x - 1000)) or (position.y < 1000 or position.y > (map.size.y - 1000)):
			adjust_dir += Vector2(map.size/2 - global_position).normalized() * 0.005  # redirect to middle of map slowly
		free_roam = (free_roam + adjust_dir).normalized()
	
	elif has_objective:
		if is_instance_valid(target):
			if target.name.left(6) == 'xp_orb':
				direction = (target.get_global_position() - global_position).normalized()
		else:
			has_objective = false

func _physics_process(delta):
	apply_central_force(direction * speed * 200)

	var rotate : float = (direction.angle() - rotation)
	if abs(rotate) > 1:
		rotate = rotate/abs(rotate)  # normalise to 1
	apply_torque(rotate * rotation_scalar)
	
	super(delta)

func scale_up():
	super()
	$Scanner.scale += Vector2(0.01, 0.01)

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
	var spread : float = 5  # spread of the probabilities towards extremes
	for key in upgrade_probs.keys():
		var prob = randf()**spread * max_upgrade_lvls[key]
		upgrade_probs[key] = prob
		prob_sum += prob
	for key in upgrade_probs.keys():
		upgrade_probs[key] /= prob_sum
		# print(key, ', ', upgrade_probs[key])
	# print('\n')

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


func death():
	super()
	$Respawn_Timer.start()

func _on_respawn_timer_timeout():
	queue_free()
