extends Node

var pipe_xp = preload("xp_orb.tscn")
var pipe_mob = preload("mob.tscn")
var pipe_spikeball = preload("spikeball.tscn")
var pipe_player = preload("player.tscn")
var xp_orbs = []
var spikeballs = []
var mobs = []
var score
var total_xp_orbs : int = 500
var total_spikeballs : int = 100 # 100
var total_mobs = 100
var game_started = false
@onready var game_running: bool = get_tree().paused
@onready var map = get_node("Map")


# signal toggle_game_paused(is_paused: bool)

# Called when the node enters the scene tree for the first time.
func _ready():
	$Player/Bod.disabled = true
	get_tree().paused = !game_running  #pause player
	for i in total_xp_orbs:
		spawn_xp_orb()
	for i in total_spikeballs:
		spawn_spikeball()
	global.restart_button_pressed.connect(restart_game)
	global.start_button_pressed.connect(start_game)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if xp_orbs.size() < total_xp_orbs:
		spawn_xp_orb()
	if spikeballs.size() < total_spikeballs:
		spawn_spikeball()
	if mobs.size() < total_mobs:
		spawn_mob()
	if $Player.dead:
		$HUD.restart_message()
		
	get_trails()

func game_over():
	$ScoreTimer.stop()
	$MobTimer.stop()
	$HUD.show_game_over()
	get_tree().call_group("mobs", "queue_free")
	$Music.stop()
	$DeathSound.play()

func start_game():
	get_tree().paused = game_running  # unpause player
	game_started = true
	$Player/Bod.disabled = false


func restart_game():
	global.reset_stats()
	get_tree().reload_current_scene()


func _input(event: InputEvent):
	if (event.is_action_pressed("pause_game") and game_started and $Player.dead == false):
		var game_running: bool = get_tree().paused
		get_tree().paused = !get_tree().paused
		if !game_running:
			$CanvasLayer/pause_menu.show()
			$Player/Canvas/Xp_points.hide()
		if game_running:
			$CanvasLayer/pause_menu.hide()
			$Player/Canvas/Xp_points.show()
	if (event.is_action_pressed("boost")):
		$Player.boost()
	if (event.is_action_released("boost")):
		$Player.stop_boost()


func _on_del_items_check_timer_timeout():  # check items consumed to be replaced
	group_cleanup(xp_orbs)
	group_cleanup(spikeballs)
	group_cleanup(mobs)

func group_cleanup(items : Array):
	var to_del_items = []
	for i in items.size() - 1:
		if not is_instance_valid(items[i]):
			to_del_items.append(i)
	for indx in to_del_items:
		items.remove_at(indx)

func spawn_xp_orb():
	var xp_orb = pipe_xp.instantiate()
	xp_orb.position = random_map_position()
	add_child(xp_orb)
	xp_orbs.append(xp_orb)
	
func spawn_spikeball():
	var spikeball = pipe_spikeball.instantiate()
	spikeball.position = random_map_position()
	add_child(spikeball)
	spikeballs.append(spikeball)

func spawn_mob():
	var mob = pipe_mob.instantiate()
	while mob.position.x < 200 or mob.position.y < 200:
		mob.position = random_map_position()
	add_child(mob)
	mobs.append(mob)

func random_map_position() -> Vector2:
	var pos_x : int = randi_range(0, map.size.x)
	var pos_y : int = randi_range(0, map.size.y)
	var position = Vector2(pos_x, pos_y)
	var distance_to_player = ($Player.position - position).length()
	while distance_to_player < 500:
		pos_x = randi_range(0, map.size.x)
		pos_y = randi_range(0, map.size.y)
		position = Vector2(pos_x, pos_y)
		distance_to_player = ($Player.position - position).length()
	return position

func get_trails():
	pass
	#for mob in mobs:
		#var trail : Line2D = mob.get_node('Trail/Trail_Line')
		#for point in trail.points:
			#if $Player/Bod.shape.has_point(point):
			#	print('in trail!')



