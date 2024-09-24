extends TextureProgressBar

@export var player : CharacterBody2D = null

func _ready():
	player.get_node("StatBlock").health_change.connect(update)
	update()

func update():
	value = player.get_node("StatBlock").get_health() * 100 / player.get_node("StatBlock").get_max_health()
