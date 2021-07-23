extends Actor
onready var tween = get_node("Tween")
onready var EvArea = get_node("/root/LevelTemplete/Area2D")
onready var BULLET = preload("Bullet.tscn")

onready var _animated_sprite = $Player
onready var _fire_light = $Light2D


# hit from left
var hit_dir = ""
var knockback_hit_started = false
# player health
var health = 3
var time = 0
# resting time (count per 1/60 seconds, maybe? that mean FPS but my screen is too suck)
var AFK_counter = 0
var onWallHIt = "none"
var fire_dir_left = true
var fire_cooldown = 0
var fire_cooldown_started = false
var attacking_counter = 0
var onGUI = false
var openInvTime = 0

func _ready():
	Globals.eScore = 0
	Globals.score = 0
	Globals.time_bonus = 0
	Globals.inventory[0][0] = 0
	Globals.inventory[0][1] = 0
	Globals.inventory[0][2] = 0
	get_node("Timer").start(1)
	
func _input(event):
	if !$Attack.is_playing() and !onGUI and event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.pressed:
		var mouse_dir = get_local_mouse_position().angle()
		$Attack/AttackArea.scale.x = 1
		$Attack/AttackArea.scale.y = 1

		if mouse_dir > -1 and mouse_dir < 1:
			#print("mouse_dir: right")
			$Attack.position.x = 50
			$Attack.set_flip_h(true)
			$Attack.play()
		elif mouse_dir > -4 and mouse_dir < -2 or mouse_dir > 2 and mouse_dir < 4:
			#print("mouse_dir: left")
			$Attack.position.x = -50
			$Attack.play()
		elif mouse_dir > -2 and mouse_dir < -1:
			#print("mouse_dir: top")
			$Attack.position.y = -68
			$Attack.play("default",true)
		elif mouse_dir > 1 and mouse_dir < 2:
			#print("mouse_dir: bottom")
			$Attack.position.y = 32
			$Attack.set_flip_h(true)
			$Attack.set_flip_v(true)
			$Attack.play("default",true)
		$attackEffect.play()
		
	if Input.is_action_pressed("openInv") and openInvTime >= 15:
		if $Camera2D/invMneu.visible:
			$Camera2D/invMneu.visible = false
			openInvTime = 0
		else:
			$Camera2D/invMneu.visible = true
			$guiEffect.play()
			openInvTime = 0
			
	if Input.is_action_pressed("esc"):
		if $Camera2D/escMenu.visible:
			$Camera2D/escMenu.visible = false
			onGUI = false
			get_tree().paused = false
		else:
			$Camera2D/escMenu.visible = true
			onGUI = true
			get_tree().paused = true
			$guiEffect.play()
	
func _physics_process(delta: float) -> void:
	var dir: = get_dir()
	vel = calcu_move_vel(vel,dir,speed)
	vel = move_and_slide_with_snap(vel, Vector2.ZERO)

func _process(delta):
	# uhhhhh?
	if openInvTime >= 600:
		openInvTime = 0
	openInvTime += 1
	# mouse attack
	if $Attack.is_playing():
		attacking_counter += 1
	if attacking_counter >= 45:
		$Attack/AttackArea.scale.x = 0.2
		$Attack/AttackArea.scale.y = 0.2
		$Attack.position.x = 0
		$Attack.position.y = -18
		$Attack.set_flip_h(false)
		$Attack.set_flip_v(false)
		$Attack.stop()
		$Attack.set_frame(0)
		attacking_counter = 0
		$Camera2D/invMneu/wood.text = str(Globals.inventory[0][0])
		$Camera2D/invMneu/stone.text = str(Globals.inventory[0][1])
		$Camera2D/invMneu/rope.text = str(Globals.inventory[0][2])

	# eight dir moveing
	if Input.is_action_pressed("move_right"):
		_animated_sprite.set_animation("right")
		_animated_sprite.play()
	elif Input.is_action_pressed("move_left"):
		_animated_sprite.set_animation("left")
		_animated_sprite.play()
	elif Input.is_action_pressed("move_top"):
		_animated_sprite.set_animation("top")
		_animated_sprite.play()
	elif Input.is_action_pressed("move_down"):
		_animated_sprite.set_animation("down")
		_animated_sprite.play()
	else:
		_animated_sprite.stop()
		_animated_sprite.set_frame(1)
		
	# she is running!
	if Input.is_action_pressed("running"):
		speed = Vector2(475.0,475.0)
	else:
		speed = Vector2(275.0,275.0)
		
	if Input.is_action_pressed("attack"):
		if !fire_cooldown_started:
			fire_cooldown_started = true
			_fire_light.enabled = true
			$onFire.play()
			
			var bullet =  BULLET.instance()
			get_node("/root/LevelTemplete").add_child(bullet)
			bullet.global_position.y = $Player.global_position.y-20
			if fire_dir_left:
				bullet.global_position.x = $Player.global_position.x+65
				bullet.apply_impulse(Vector2(),Vector2(1025,0.0015))
			else:
				bullet.global_position.x = $Player.global_position.x-155
				bullet.apply_impulse(Vector2(),Vector2(-1025,0.0015))
	
	if fire_cooldown >= 20:
		fire_cooldown_started = false
		fire_cooldown = 0
	
	if fire_cooldown >=3:
		_fire_light.enabled = false
	
	# when player resting
	if vel == Vector2.ZERO:
		AFK_counter += 1
	else:
		AFK_counter = 0
	# Unstock, Restart game
	if Input.get_action_strength("Reflash") and AFK_counter > 30:
		AFK_counter = 0
		get_node("CollisionShape2D").disabled = true
		queue_free()
		get_tree().reload_current_scene()
	
	# Player Knockback by Enemy
	if knockback_hit_started:
		for i in get_slide_count():
			var collision = get_slide_collision(i)
			if collision.collider is TileMap:
				if collision.normal.x > 0 and collision.normal.y == 0:
					onWallHIt = "left"
				elif collision.normal.x < 0 and collision.normal.y == 0:
					onWallHIt = "right"
				elif collision.normal.x == 0 and collision.normal.y < 0:
					onWallHIt = "bottom"
				elif collision.normal.x == 0 and collision.normal.y > 0:
					onWallHIt = "top"
				else:
					onWallHIt = "none"

		if(hit_dir == "left"):
			tween.interpolate_property(self, "position",
					position, Vector2(position.x-150 ,position.y), 0.25,
					Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
			tween.start()
			get_node("Knockback").play()
			hit_dir = ""
		elif(hit_dir == "right"):
			tween.interpolate_property(self, "position",
					position, Vector2(position.x+150 ,position.y), 0.25,
					Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
			tween.start()
			get_node("Knockback").play()
			hit_dir = ""
		elif(hit_dir == "top"):
			tween.interpolate_property(self, "position",
					position, Vector2(position.x ,position.y-150), 0.25,
					Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
			tween.start()
			get_node("Knockback").play()
			hit_dir = ""
		elif(hit_dir == "bottom"):
			tween.interpolate_property(self, "position",
					position, Vector2(position.x ,position.y+150), 0.25,
					Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
			tween.start()
			get_node("Knockback").play()
			hit_dir = ""
			
		if onWallHIt != "none":
			tween.stop(self)
			onWallHIt = "none"
		if not tween.is_active():
			knockback_hit_started = false
	# when counter more than 600, it need to reset to 0 because ...?
	if(AFK_counter > 600):
		AFK_counter = 0
func _on_Area2D_body_entered(body: PhysicsBody2D):
	# HITBOX, my love!
	if body.name == "Boss":
		minusHP(body, get_node("Area2D"), "Boss")
	else:
		minusHP(body, get_node("Area2D"), "Enemy")
# idk
func minusHP(entity: PhysicsBody2D, PArea2D: Node2D, DamagedFrom: String) -> void:
	# oh sad, the health minus one
	
	if DamagedFrom == "Boss":
		health -= 3
	else:
		health -= 1
	
	if DamagedFrom != "Trap":
		var diff_x = (entity.global_position.x - PArea2D.global_position.x)
		var diff_y = (entity.global_position.y - PArea2D.global_position.y)
		var original_size = entity.get_node('CollisionShape2D').shape.extents*2
		
		if abs(diff_x) > original_size.x: #right or left
			if diff_x > 0:
				hit_dir = "left"
			else:
				hit_dir = "right"
		elif abs(diff_y) > original_size.y: # top or bottom
			if diff_y > 0:
				hit_dir = "top"
			else:
				hit_dir = "bottom"
		knockback_hit_started = true
		
		#print(entity.global_position.x)
		# Call player knockback func
		#if(entity.x < PArea2D.global_position.x):
		#	hit_dir = "left"
		#	knockback_hit_started = true
		#else:
		#	hit_dir = "right"
		#	knockback_hit_started = true
	
	# when health less than 0, restarting game
	# hide health images?
	if(health <= 0):
		$Camera2D/Health/hp1.hide()
		get_node("Knockback").play()
		get_node("CollisionShape2D").disabled = true
		queue_free()
		get_tree().change_scene("res://src/GameOver.tscn")
	elif health == 2:
		$Camera2D/Health/hp3.hide()
	elif health == 1:
		$Camera2D/Health/hp2.hide()
				
func get_dir() -> Vector2:
	return Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_top")
	)
func calcu_move_vel(liner_vel: Vector2,dir: Vector2,speed: Vector2) -> Vector2:
	var new_vel: = liner_vel
	new_vel.x = speed.x * dir.x
	new_vel.y = speed.y * dir.y
	return new_vel

func _on_Timer_timeout():
	$attackEffect.volume_db = Globals.effect_sound
	$Knockback.volume_db = Globals.effect_sound
	$onFire.volume_db = Globals.effect_sound
	
	time += 1
	var time_min = floor(time/60)
	var time_min_format = "0" + str(time_min) if time_min < 10 else str(time_min)
	
	var time_sec = time - floor(time/60)*60
	var time_sec_format = "0" + str(time_sec) if time_sec < 10 else str(time_sec)
	

	$Camera2D/Label2.text = time_min_format + ":" + time_sec_format
	$Camera2D/Mission/wd_amount.text = str(Globals.inventory[0][0])
	$Camera2D/Mission/st_amount.text = str(Globals.inventory[0][1])
	$Camera2D/Mission/rp_amount.text = str(Globals.inventory[0][2])
	$Camera2D/Mission/ene_amount.text = str(Globals.eScore)
	
	
	if Globals.inventory[0][0] >= 100 and Globals.inventory[0][1] >= 100 and Globals.inventory[0][2] >= 100 and Globals.eScore == 14:
		get_node("Timer").stop()
		var time_bonus = Globals.eScore*120+Globals.inventory[0][0]+Globals.inventory[0][1]+Globals.inventory[0][2] - time
		var score = Globals.eScore + time_bonus
		Globals.score = score
		Globals.time_format = $Camera2D/Label2.text
		Globals.time_bonus = time_bonus
		
		get_tree().change_scene("res://src/GameWin.tscn")
		
	#if get_node("/root/LevelTemplete/Boss") == null:
	#	get_node("Timer").stop()
	#	var time_bonus = Globals.base_score - time
	#	var score = Globals.eScore + time_bonus

	#	Globals.score = score
	#	Globals.time_format = $Camera2D/Label2.text
	#	Globals.time_bonus = time_bonus
	#	
	#	get_tree().change_scene("res://src/GameWin.tscn")
		

func _on_exit_pressed():
	get_tree().quit()
func _on_continue_pressed():
	$Camera2D/escMenu.visible = false
	onGUI = false
	get_tree().paused = false


func _on_musicSound_value_changed(value):
	Globals.music_sound = value

func _on_effectSound_value_changed(value):
	Globals.effect_sound = value
