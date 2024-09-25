extends CharacterBody2D

# Determines randomness
var rng = RandomNumberGenerator.new()

# Movement controls
var direction_of_travel := Vector2.ZERO
var moving = false

func _ready():
	$TravelDecisionTimer.start()

func _process(delta):
	velocity = Vector2.ZERO
	if moving:
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
	moving = true
	$RandomMovementTimer.start()

# Procs the decision to travel a specific direction
func _on_travel_decision_timer_timeout():
	_decide_direction_of_travel()

# Stops the movement from continuing
func _on_random_movement_timer_timeout():
	moving = false
	$TravelDecisionTimer.start()
