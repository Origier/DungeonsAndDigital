extends CharacterBody2D

# Exports
@export var aggro_range := 300.0	# Pixel distance the player needs to be away from the enemy to lose aggro

# Determines randomness
var rng = RandomNumberGenerator.new()

# Movement controls
var direction_of_travel := Vector2.ZERO
var moving_randomly = false
var player_target : CharacterBody2D = null

func _ready():
	$TravelDecisionTimer.start()

func _process(delta):
	velocity = Vector2.ZERO
	if player_target != null:
		var player_delta_vector = player_target.position - position
		var distance_to_player = player_delta_vector.length()
		# Lose aggro to player
		if abs(distance_to_player) >= aggro_range:
			player_target = null
			$TravelDecisionTimer.start()
		else:
			direction_of_travel = (player_delta_vector).normalized()
			velocity = $StatBlock.sprint_speed * direction_of_travel * delta
	elif moving_randomly:
		velocity = $StatBlock.walking_speed * direction_of_travel * delta
		
	move_and_slide()
	
# Decide a random direction to travel
func _decide_direction_of_travel():
	var x_dir = rng.randf_range(-1.0, 1.0)
	var y_dir = rng.randf_range(-1.0, 1.0)
	
	# Force the random movement to occur along an axis
	if abs(x_dir) > abs(y_dir):
		y_dir = 0.0
	else:
		x_dir = 0.0
		
	direction_of_travel = Vector2(x_dir, y_dir).normalized()
	moving_randomly = true
	
	# Change direciton for line of sight
	# Going down
	if x_dir == 0.0 and y_dir > 0.0:
		$LineOfSightCone.set_rotation(0.0)
	# Going left
	elif x_dir < 0.0 and y_dir == 0.0:
		$LineOfSightCone.set_rotation(0.5 * PI)
	# Going up
	elif x_dir == 0.0 and y_dir < 0.0:
		$LineOfSightCone.set_rotation(PI)
	else:
		$LineOfSightCone.set_rotation(1.5 * PI)
	$RandomMovementTimer.start()

# Procs the decision to travel a specific direction
func _on_travel_decision_timer_timeout():
	_decide_direction_of_travel()

# Stops the movement from continuing
func _on_random_movement_timer_timeout():
	moving_randomly = false
	$TravelDecisionTimer.start()

func _on_line_of_sight_cone_body_entered(body):
	moving_randomly = false
	$RandomMovementTimer.stop()
	player_target = body
