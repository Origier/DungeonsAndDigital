extends Node2D

func _process(delta):
	if Input.is_action_just_pressed("Test Key"):
		damage_player()
		
func damage_player():
	$Player.get_node("StatBlock").alter_health(-20)
