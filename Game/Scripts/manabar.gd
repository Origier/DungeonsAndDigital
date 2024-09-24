extends TextureProgressBar

@export var player : CharacterBody2D = null

func _ready():
	player.get_node("StatBlock").mana_change.connect(update)
	update()

func update():
	value = player.get_node("StatBlock").get_mana() * 100 / player.get_node("StatBlock").get_max_mana()

