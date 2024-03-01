extends Node

var xp_points : int

var player_lvls : Dictionary = {
	"speed" = 0,
	"boost" = 0,
	"health" = 0,
	"regen" = 0,
	"spike" = 0,
	"bodydamage" = 0,
	"trail" = 0
}

var player_max_lvls : Dictionary = {
	"speed" = 20,
	"boost" = 8,
	"health" = 15,
	"regen" = 10,
	"spike" = 20,
	"bodydamage" = 10,
	"trail" = 8
}

signal speed_button_pressed
signal boost_button_pressed
signal health_button_pressed
signal regen_button_pressed
signal spike_button_pressed
signal bodydamage_button_pressed
signal trail_button_pressed

func reset_stats():
	for key in player_lvls:
		player_lvls[key] = 0
	xp_points = 0

signal start_button_pressed
signal restart_button_pressed

signal grant_kill_xp
