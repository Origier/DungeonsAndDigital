extends TextureProgressBar

@export var player : CharacterBody2D = null

func _ready():
	player.get_node("StatBlock").stamina_change.connect(update)
	update()

func update():
	value = player.get_node("StatBlock").get_stamina() * 100 / player.get_node("StatBlock").get_max_stamina()
