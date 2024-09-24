extends Node

# Exports
@export var starting_health : float = 100
@export var health_regen_rate : float = 5.0		# Per second
@export var starting_stamina : float = 100
@export var stamina_regen_rate : float = 5.0	# Per second
@export var starting_mana : float = 100
@export var mana_regen_rate : float = 5.0		# Per second
@export var walking_speed := 25000
@export var sprint_speed := 50000
@export var dodge_roll_multiplier := 3

# Stamina controls
var _stamina := starting_stamina
var _stamina_max := starting_stamina
# Health controls
var _health := starting_health
var _health_max := starting_health
# Mana controls
var _mana := starting_mana
var _mana_max := starting_mana

# Signals
signal health_change
signal stamina_change
signal mana_change
signal death

# Adds the given delta to the current stamina, can accept positive and negative numbers
func alter_stamina(delta):
	stamina_change.emit()
	_stamina += delta
	# While losing stamina, do not regenerate
	if delta < 0.0:
		$StaminaRegenTimer.stop()
	# Ensure the regeneration is happening at 0
	if _stamina <= 0.0:
		_stamina = 0.0
		if $StaminaRegenTimer.is_stopped():
			$StaminaRegenTimer.start()
			
	elif _stamina >= _stamina_max:
		_stamina = _stamina_max
		$StaminaRegenTimer.stop()
	# Starts regenerating if the timer isn't currently working
	else:
		if $StaminaRegenTimer.is_stopped():
			$StaminaRegenTimer.start()

func get_stamina():
	return _stamina
	
func get_max_stamina():
	return _stamina_max

# Adds the given delta to the current health, can accept positive and negative numbers
func alter_health(delta):
	health_change.emit()
	_health += delta
	# While losing health, do not regenerate
	if delta < 0.0:
		$HealthRegenTimer.stop()
	# Dies at zero health
	if _health <= 0.0:
		_health = 0.0
		death.emit()
		
	elif _health >= _health_max:
		_health = _health_max
		$HealthRegenTimer.stop()
	# Starts regenerating if the timer isn't currently working
	else:
		if $HealthRegenTimer.is_stopped():
			$HealthRegenTimer.start()

func get_health():
	return _health

func get_max_health():
	return _health_max

# Adds the given delta to the current health, can accept positive and negative numbers
func alter_mana(delta):
	mana_change.emit()
	_mana += delta
	# While losing mana, do not regenerate
	if delta < 0.0:
		$ManaRegenTimer.stop()
	# Ensure the regeneration is happening at 0
	if _mana <= 0.0:
		_mana = 0.0
		if $ManaRegenTimer.is_stopped():
			$ManaRegenTimer.start()
			
	elif _mana >= _mana_max:
		_mana = _mana_max
		$ManaRegenTimer.stop()
	# Starts regenerating if the timer isn't currently working
	else:
		if $ManaRegenTimer.is_stopped():
			$ManaRegenTimer.start()

func get_mana():
	return _mana

func get_max_mana():
	return _mana_max

func _on_stamina_regen_timer_timeout():
	alter_stamina(stamina_regen_rate * $StaminaRegenTimer.wait_time)
	
func _on_health_regen_timer_timeout():
	alter_health(health_regen_rate * $HealthRegenTimer.wait_time)

func _on_mana_regen_timer_timeout():
	alter_mana(mana_regen_rate * $ManaRegenTimer.wait_time)
