extends CharacterBody2D

@export var speed := 2000

func _process(delta):
	velocity = Vector2(0, 0)
	
	if Input.is_action_pressed("ui_right"):
		velocity.x = speed * delta
	if Input.is_action_pressed("ui_left"):
		velocity.x = -speed * delta
	if Input.is_action_pressed("ui_down"):
		velocity.y = speed * delta
	if Input.is_action_pressed("ui_up"):
		velocity.y = -speed * delta
	move_and_slide()
