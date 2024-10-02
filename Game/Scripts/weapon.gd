extends Node2D

# Exports - Stats for the weapon
@export var base_damage := 20
@export var reach := 25.0 		# Distance in pixels that the weapon can extend

# Signals to inform the wielder of certain things taking place
signal attack_animation_finished
signal target_struck

# Makes the weapon visible and swings the weapon from the position provided
func swing_weapon(position_in):
	$WeaponSprite.global_position = position_in
	$WeaponSprite.visible = true
	$DamageDelayTimer.start()
	$AttackAnimation.play("swing_weapon_arc")

# Delays the amount of time needed before the weapon deals damage
func _on_damage_delay_timer_timeout():
	$WeaponSprite/WeaponArea2D/WeaponCollider.disabled = false

# Disables the weapon again upon the animation finishing - emits that the attack is done
func _on_attack_animation_animation_finished(_anim_name):
	$WeaponSprite.visible = false
	$WeaponSprite/WeaponArea2D/WeaponCollider.disabled = true
	attack_animation_finished.emit()

# Emits the body that was struck in the attack
func _on_weapon_area_2d_body_entered(body):
	target_struck.emit(body)
