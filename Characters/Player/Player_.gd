extends "res://Characters/Character.gd"

export(float) var  move_speed = 300
export(float) var wall_slide_friction = 0.5
export(float) var jump_impulse = 600
export(int) var max_jumps = 2
export(float) var jump_damage = 1
export(float) var enemy_bounce_impulse = 400
export(float) var knockback_speed = 200

enum STATE { IDLE, WALK, JUMP, DOUBLE_JUMP, FLASH_JUMP, HIT, WALL_SLIDE}

onready var animated_sprite = $AnimatedSprite
onready var animation_tree = $AnimationTree
onready var jump_hitbox = $jumpHitBox
onready var hurt_timer = $hurt_timer
onready var wall_jump_timer = $wall_jump_timer
onready var drop_timer = $drop_timer

signal changed_state(new_state_string, new_state_id)
signal player_died(player)

var current_state = STATE.IDLE setget set_current_state
var velocity : Vector2
var is_bordering_wall : bool
var jumps = 0
var wall_jump_direction : Vector2
var ready_to_jump = false

func _physics_process(_delta):	
	var input = get_player_input()
	
	if(Input.is_action_just_pressed("player_down")):
		if(drop_timer.is_stopped()):
			drop_timer.start()
		else:
			drop()
	
	velocity = move_and_slide(velocity, Vector2.UP)
	
	is_bordering_wall = get_is_on_wall_raycast_test()
	
	set_anim_parameters()
	
	match(current_state):
		STATE.IDLE, STATE.WALK, STATE.JUMP, STATE.DOUBLE_JUMP:
			if(wall_jump_timer.is_stopped()):
				velocity = normal_movement(input)
			else:
				velocity = wall_jumping_movement()
			pick_next_state()
		STATE.HIT:
			velocity = hit_move()
		STATE.WALL_SLIDE:
			velocity = wall_slide_move()
			pick_next_state()
	
			
			
func normal_movement(input):
	adjust_flip_direction(input)

	return Vector2(
			input.x * move_speed,
			min(velocity.y + GameSettings.gravity, GameSettings.terminal_velocity)
	)
	
	
#knockback where player has no control over movement temporarily.
func hit_move():
	var knockback_direction : Vector2
	
	#facing_left
	if(animated_sprite.flip_h):
		knockback_direction = Vector2.RIGHT
	else:
		knockback_direction = Vector2.LEFT
	
	knockback_direction = knockback_direction.normalized()
	
	return knockback_speed * knockback_direction
	
func wall_slide_move():
	return Vector2(
		velocity.x,
		min(velocity.y + (GameSettings.gravity * wall_slide_friction), GameSettings.terminal_velocity)
	)
	
func wall_jumping_movement():
	return Vector2(
		move_speed * wall_jump_direction.x,
		min(velocity.y +(GameSettings.gravity), GameSettings.terminal_velocity)
	)
	
func adjust_flip_direction(input : Vector2):
	if(sign(input.x) == 1):
		animated_sprite.flip_h = false
	elif(sign(input.x) == -1):
		animated_sprite.flip_h = true

func set_anim_parameters():
	animation_tree.set("parameters/x_sign/blend_position", sign(velocity.x))
	animation_tree.set("parameters/y_sign/blend_amount", sign(velocity.y))
	var is_on_wall_int : int
	if(is_bordering_wall && !is_on_floor()):
		is_on_wall_int = 1
	else:
		is_on_wall_int = 0
		
	animation_tree.set("parameters/is_on_wall/blend_amount", is_on_wall_int)


func pick_next_state():
	
	if(is_on_floor()):
		jumps = 0

		if(Input.is_action_just_pressed("player_jump")):
			self.current_state = STATE.JUMP
		elif(abs(velocity.x) >0):
			self.current_state = STATE.WALK
		else:
			self.current_state = STATE.IDLE
	elif(Input.is_action_just_pressed("player_jump") && jumps < max_jumps):
		if(is_bordering_wall):
			self.current_state = STATE.JUMP
		else:
			self.current_state = STATE.DOUBLE_JUMP
	elif(is_bordering_wall):
		self.current_state = STATE.WALL_SLIDE
	elif(self.current_state == STATE.WALL_SLIDE && !is_bordering_wall):
		self.current_state = STATE.JUMP
	
			#FLASH_JUMP
#	else:
#			if (Input.is_action_just_pressed("player_jump") && jumps < max_jumps):
#				self.current_state = STATE.FLASH_JUMP

func get_player_input():
	var input : Vector2
	
	input.x = Input.get_action_strength("player_right") - Input.get_action_strength("player_left")
	input.y = Input.get_action_strength("player_down") - Input.get_action_strength("player_up")
	
	return input
	
func get_facing_direction():
	if(animated_sprite.flip_h == false):
		return Vector2.RIGHT
	else:
		return Vector2.LEFT
	
	
func get_is_on_wall_raycast_test():
	var space_state = get_world_2d().direct_space_state
	var result = space_state.intersect_ray(global_position, global_position + 10 * get_facing_direction(), [self], self.collision_mask)
	
	if result.size() > 0:
		return true
	else:
		return false
	
func _on_AnimationPlayer_animation_finished(jump):
	if jump == "jump":
		ready_to_jump = true
	
func jump():
		velocity.y = -jump_impulse
		jumps += 1

func wall_jump():
	velocity.y = -jump_impulse
	jumps = 1
	wall_jump_direction = -get_facing_direction()
	wall_jump_timer.start()

func double_jump():
	velocity.y = -jump_impulse * 1.2
	jumps +=1
	
#FLASH_JUMP
#func flash_jump():
#	velocity.x = -jump_impulse
#	jumps +=1

func drop():
	position.y +=1


	
func _on_jumpHitBox_area_shape_entered(_area_rid, area, _area_shape_index, _local_shape_index):
	var enemy = area.owner
	
	if(enemy is Enemy && enemy.can_be_hit):
		if(velocity.y > 0):
			#jump_attack
			velocity.y = -enemy_bounce_impulse
			#damage_enemy
			enemy.get_hit(jump_damage)
			
	pass
	
func get_hit(damage : float):
	if(hurt_timer.is_stopped()):
		
		if(damage >= self.health):
			emit_signal("player_died", self)
		
		self.health -= damage
		self.current_state = STATE.HIT
		hurt_timer.start()
		
func dead():
	emit_signal("player_died", self)
	queue_free()	

func on_hit_finished():
	self.current_state = STATE.IDLE


func _on_Player__tree_entered():
	GameManager.active_player = self


#setters
func set_current_state(new_state):
	match(new_state):
		STATE.JUMP:
			if(current_state == STATE.WALL_SLIDE):
				if(Input.is_action_just_pressed("player_jump")):
					wall_jump()
			else:
				jump()
		STATE.DOUBLE_JUMP:
			double_jump()
			animation_tree.set("parameters/double_jump/active", true)
		STATE.HIT:
			animation_tree.set("parameters/hit/active", true)
		STATE.WALL_SLIDE:
			jumps = 0
			
			
		
		#FLASH_JUMP_STATE
#		STATE.FLASH_JUMP:
#			flash_jump()
			
	current_state = new_state
	emit_signal("changed_state", STATE.keys()[new_state], new_state)
