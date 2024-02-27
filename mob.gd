extends Microbe

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
	var lvl : int = randi_range(1, 30)
	for i in range(lvl):
		LevelUp()
	get_probs()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	super(delta)
	if xp_points > 0:
		roulette_wheel()
		

func _physics_process(delta):
	super(delta)

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
