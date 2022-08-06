extends Enemy

enum STATE { IDLE, AWARE, HIT }

export(float) var idle_speed = 20
export(float) var attack_speed = 100

var current_state = STATE.IDLE

func _physics_process(delta):
	waypoint_move(delta)
	
func _get_move_velocity(_delta, direction):
	# Move towards waypoint
	var direction_x_sign = sign(direction.x)
	
	var move_speed : float
	
	match(current_state):
		STATE.IDLE:
			move_speed = idle_speed
		STATE.AWARE:
			move_speed = attack_speed
	
	return Vector2(
		move_speed * direction_x_sign,
		min(velocity.y + GameSettings.gravity, GameSettings.terminal_velocity)
	)
			
			
func _get_distance_to_waypoint(waypoint_position : Vector2):
	return Vector2(self.position.x, 0).distance_to(Vector2(waypoint_position.x, 0))			
			
			
func _on_line_of_site_body_shape_entered(_body_rid, _body, _body_shape_index, _local_shape_index):
	animation_tree.set("parameters/player_detected/blend_position", 1)
	
	if(current_state == STATE.IDLE):
		current_state = STATE.AWARE

func _on_line_of_site_body_shape_exited(_body_rid, _body, _body_shape_index, _local_shape_index):
	animation_tree.set("parameters/player_detected/blend_position", 0)
	
	if(current_state == STATE.AWARE):
		current_state = STATE.IDLE
		


	
	
		
func get_hit(jump_damage : float):
	self.health -= jump_damage
	
	can_be_hit = false
	current_state = STATE.HIT
	
	var anim_selection = GameSettings.RandGen.randi_range(0, 1)
	
	animation_tree.set("parameters/hit/active", true)
	animation_tree.set("parameters/hit_variation/blend_amount", anim_selection)


func _hit_animation_finished():
	can_be_hit = true
	current_state = STATE.AWARE




