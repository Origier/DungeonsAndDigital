extends CharacterBody2D

# Exports
@export var aggro_range := 300.0			# Pixel distance the player needs to be away from the enemy to lose aggro
@export var travel_wait_time_min := 1.0		# Seconds before moving
@export var travel_wait_time_max := 2.0		# Seconds before moving
@export var attack_damage := 10				# Base amount of damage the attack will do
@export var equipped_weapon : Node2D = null

# Determines randomness
var rng = RandomNumberGenerator.new()

# Movement controls
var direction_of_travel := Vector2.ZERO
var moving_randomly := false
var player_target : CharacterBody2D = null
var performing_attack := false

var player_attack_offset := 0.0	# Pixel distance of the offset to the player before the enemy starts their attack

func _ready():
	$TravelDecisionTimer.wait_time = rng.randf_range(travel_wait_time_min, travel_wait_time_max)
	$TravelDecisionTimer.start()
	$StatBlock.death.connect(_upon_death)
	if equipped_weapon != null:
		equipped_weapon.attack_animation_finished.connect(_attack_finished)
		equipped_weapon.target_struck.connect(_attack_hit_body)
		player_attack_offset = equipped_weapon.reach

func _process(delta):
	velocity = Vector2.ZERO
	# While attacking do nothing until the animation is over
	if performing_attack:
		pass
	elif player_target != null:
		# Firtly determine if the player is within aggro range still
		var player_delta_vector = player_target.position - position
		var distance_to_player = player_delta_vector.length()
		# Lose aggro to player
		if abs(distance_to_player) >= aggro_range:
			player_target = null
			$TravelDecisionTimer.start()
		# When close enough to the player the monster will start its attack
		elif abs(distance_to_player) <= player_attack_offset:
			velocity = Vector2.ZERO
			_rotate_attack()
			_perform_attack()
		else:
			direction_of_travel = (player_delta_vector).normalized()
			velocity = $StatBlock.sprint_speed * direction_of_travel * delta
	elif moving_randomly:
		velocity = $StatBlock.walking_speed * direction_of_travel * delta
	# Move the monster
	move_and_slide()

# Public function to allow the enemy to take damage
func take_damage(damage):
	$StatBlock.alter_health(-damage)

# Function to handle removing the enemy
func _upon_death():
	queue_free()

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
	# Look in the direction of travel to determine if it is clear to travel
	_update_direction_from_sight()
	
	moving_randomly = true
	# Change direciton for line of sight
	_update_line_of_sight_rotation()
	$RandomMovementTimer.start()

# Rotates the attack vector towards the players position
func _rotate_attack():
	var player_delta_vector = player_target.position - position
	# Focusing on the x direction
	if equipped_weapon != null:
		if abs(player_delta_vector.x) > abs(player_delta_vector.y):
			if player_delta_vector.x > 0.0:
				equipped_weapon.rotation = 0.0 * PI
			else:
				equipped_weapon.rotation = 1.0 * PI
		# Focusing on the y direction
		else:
			if player_delta_vector.y > 0.0:
				equipped_weapon.rotation = 0.5 * PI
			else:
				equipped_weapon.rotation = 1.5 * PI

# Plays the attack animation and attempts to strike the player
func _perform_attack():
	if equipped_weapon != null:
		equipped_weapon.swing_weapon(global_position)
		performing_attack = true

# Updates the direction of travel based on if the monster can see walls nearby
func _update_direction_from_sight():
	_update_ray_cast_rotation()
	# If not, flip the direction of travel
	if $SightRayCast.is_colliding():
		_flip_direction()
		_update_ray_cast_rotation()
	# If still colliding, try the other axis
	if $SightRayCast.is_colliding():
		if abs(direction_of_travel.x) == 1.0:
			direction_of_travel = Vector2(0.0, 1.0)
		else:
			direction_of_travel = Vector2(1.0, 0.0)
		_update_ray_cast_rotation()
	# Once again, if still colliding flip the direciton again
	if $SightRayCast.is_colliding():
		_flip_direction()
		_update_ray_cast_rotation()
	# Finally, if still colliding then the enemy is boxed in, should delete itself since it cant go anywhere
	if $SightRayCast.is_colliding():
		queue_free()

# Flips the direction of travel
func _flip_direction():
	if direction_of_travel.x == 1.0:
		direction_of_travel.x = -1.0
	elif direction_of_travel.y == 1.0:
		direction_of_travel.y = -1.0
	elif direction_of_travel.x == -1.0:
		direction_of_travel.x = 1.0
	else:
		direction_of_travel.y = 1.0

func _update_line_of_sight_rotation():
	# Going down
	if direction_of_travel.x == 0.0 and direction_of_travel.y > 0.0:
		$LineOfSightCone.set_rotation(0.0)
	# Going left
	elif direction_of_travel.x < 0.0 and direction_of_travel.y == 0.0:
		$LineOfSightCone.set_rotation(0.5 * PI)
	# Going up
	elif direction_of_travel.x == 0.0 and direction_of_travel.y < 0.0:
		$LineOfSightCone.set_rotation(PI)
	else:
		$LineOfSightCone.set_rotation(1.5 * PI)

# Updates the direction the ray cast is pointing based on which way the monster will travel
func _update_ray_cast_rotation():
	if direction_of_travel.x == 0.0 and direction_of_travel.y > 0.0:
		$SightRayCast.set_rotation(0.0)
		$SightRayCast.force_raycast_update()
	# Going left
	elif direction_of_travel.x < 0.0 and direction_of_travel.y == 0.0:
		$SightRayCast.set_rotation(0.5 * PI)
		$SightRayCast.force_raycast_update()
	# Going up
	elif direction_of_travel.x == 0.0 and direction_of_travel.y < 0.0:
		$SightRayCast.set_rotation(PI)
		$SightRayCast.force_raycast_update()
	else:
		$SightRayCast.set_rotation(1.5 * PI)
		$SightRayCast.force_raycast_update()

# Called upon player death
func _player_dead():
	player_target = null
	$TravelDecisionTimer.start()

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

# Called on the end of attack animations
func _attack_finished():
	performing_attack = false

# Called when the weapon collider hit something
func _attack_hit_body(body):
	if body.is_in_group("Player"):
		body.take_damage(attack_damage + equipped_weapon.base_damage)


