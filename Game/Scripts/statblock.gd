extends Node

# Exports
@export var starting_health : float = 100
@export var health_regen_rate : float = 5.0		# Per second
@export var starting_stamina : float = 100
@export var stamina_regen_rate : float = 5.0	# Per second
@export var walking_speed := 25000
@export var sprint_speed := 50000
@export var dodge_roll_multiplier := 3

# Stamina controls
var _stamina := starting_stamina
var _stamina_max := starting_stamina
# Health controls
var _health := starting_health
var _health_max := starting_health

# Adds the given delta to the current stamina, can accept positive and negative numbers
func alter_stamina(delta):
	_stamina += delta
	if _stamina <= 0.0:
		_stamina = 0.0
	elif _stamina >= _stamina_max:
		_stamina = _stamina_max
		$StaminaRegenTimer.stop()
	# Starts regenerating if the timer isn't currently working
	else:
		if $StaminaRegenTimer.is_stopped():
			$StaminaRegenTimer.start()

func get_stamina():
	return _stamina

# Adds the given delta to the current health, can accept positive and negative numbers
func alter_health(delta):
	_health += delta
	if _health <= 0.0:
		_health = 0.0
	elif _health >= _health_max:
		_health = _health_max
		$HealthRegenTimer.stop()
	# Starts regenerating if the timer isn't currently working
	else:
		if $HealthRegenTimer.is_stopped():
			$HealthRegenTimer.start()

func get_health():
	return _health

func _on_stamina_regen_timer_timeout():
	alter_stamina(stamina_regen_rate * $StaminaRegenTimer.wait_time)
	
func _on_health_regen_timer_timeout():
	alter_health(health_regen_rate * $HealthRegenTimer.wait_time)
