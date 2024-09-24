extends CharacterBody2D

# Dodge roll controls
var dodge_roll_direction = null
var in_dodge_roll := false
var dodge_roll_cooldown := false
var sprinting := false

# Costs for certain actions
@export var stamina_cost_sprint : float = 15.0		# Per second
@export var stamina_cost_dodge : float = 35.0		# Per dodge

func _process(delta):
	# Resetting the velocity each frame
	velocity = Vector2(0, 0)
	
	# Processing any current dodge rolls
	if in_dodge_roll:
		continue_dodge_roll(delta)
	else:
		# Checking for dodge rolls
		if Input.is_action_just_pressed("Dodge Roll") and not dodge_roll_cooldown and $StatBlock.get_stamina() >= stamina_cost_dodge:
			$StatBlock.alter_stamina(-stamina_cost_dodge)
			start_dodge_roll(delta)
			
		# Add any sprinting modifier to the player
		if Input.is_action_just_pressed("Sprint") and not sprinting and $StatBlock.get_stamina() >= stamina_cost_sprint:
			sprinting = true
			$SprintStaminaUsageTimer.start()
		
		# Removing the players sprint when sprint is released
		if Input.is_action_just_released("Sprint") or $StatBlock.get_stamina() == 0.0:
			sprinting = false
			$SprintStaminaUsageTimer.stop()
		
		# Get the direction of travel and calculate the velocity on the player basic input
		var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		if sprinting:
			velocity = direction * $StatBlock.sprint_speed * delta
		else:
			velocity = direction * $StatBlock.walking_speed * delta
		
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
	velocity = dodge_roll_direction * $StatBlock.walking_speed * delta * $StatBlock.dodge_roll_multiplier
	move_and_slide()

# Taking the player out of the dodge roll and starting the cooldown
func _on_dodge_roll_timer_timeout():
	in_dodge_roll = false
	dodge_roll_cooldown = true
	$DodgeRollCoolDownTimer.start()

# Removing the cooldown, the player may dodge roll again
func _on_dodge_roll_cool_down_timer_timeout():
	dodge_roll_cooldown = false

func _on_sprint_stamina_usage_timer_timeout():
	$StatBlock.alter_stamina(-stamina_cost_sprint * $SprintStaminaUsageTimer.wait_time)
