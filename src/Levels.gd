extends Node2D
onready var Globals = get_node("/root/Globals")

var gameTime = 0

func _ready():
	$Timer.start(1)
	$MusicDay.volume_db = Globals.music_sound
	$MusicNight.volume_db = Globals.music_sound
	
func _on_Timer_timeout():
	$MusicDay.volume_db = Globals.music_sound
	$MusicNight.volume_db = Globals.music_sound
	gameTime += 1
	if !$day_night.is_playing():
		if Globals.timeState == "day" and gameTime >= 90 or Globals.timeState == "night" and gameTime >= 70:
			if Globals.timeState == "day":
				$day_night.set_current_animation("ToNight")
				$day_night.play()
				Globals.timeState = "night"
				gameTime = 0
				$MusicDay.stop()
				$MusicNight.play()
			elif Globals.timeState == "night":
				$day_night.set_current_animation("ToDay")
				$day_night.play()
				Globals.timeState = "day"
				gameTime = 0
				$MusicDay.play()
				$MusicNight.stop()
