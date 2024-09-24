extends CharacterBody2D

# Speed variables
@export var walking_speed := 25000
@export var sprint_speed := 50000
var current_speed := walking_speed

# Dodge roll controls
@export var dodge_roll_multiplier := 3
var dodge_roll_direction = null
var in_dodge_roll := false
var dodge_roll_cooldown := false

# Stamina control
@export var starting_stamina := 100
var stamina_max := starting_stamina

func _process(delta):
	velocity = Vector2(0, 0)
	
	# Processing any current dodge rolls
	if in_dodge_roll:
		continue_dodge_roll(delta)
	else:
		# Checking for dodge rolls
		if Input.is_action_just_pressed("Dodge Roll") and not dodge_roll_cooldown:
			start_dodge_roll(delta)
			
		# Add any sprinting modifier to the player
		if Input.is_action_pressed("Sprint"):
			current_speed = sprint_speed
		else:
			current_speed = walking_speed
		
		# Get the direction of travel and calculate the velocity on the player basic input
		var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		velocity = direction * current_speed * delta
		
		move_and_slide()
	
# Starts the dodge roll timer and initiates the control lock-out during the roll
func start_dodge_roll(delta):
	dodge_roll_direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	# Ensuring that the player is moving in a direction
	if (dodge_roll_direction == Vector2.ZERO):
		return
	$DodgeRollTimer.start()
	in_dodge_roll = true
	continue_dodge_roll(delta)
	
# Processes each frame of the dodge roll until the timer ends
func continue_dodge_roll(delta):
	velocity = dodge_roll_direction * walking_speed * delta * dodge_roll_multiplier
	move_and_slide()

# Taking the player out of the dodge roll and starting the cooldown
func _on_dodge_roll_timer_timeout():
	in_dodge_roll = false
	dodge_roll_cooldown = true
	$DodgeRollCoolDownTimer.start()

# Removing the cooldown, the player may dodge roll again
func _on_dodge_roll_cool_down_timer_timeout():
	dodge_roll_cooldown = false
