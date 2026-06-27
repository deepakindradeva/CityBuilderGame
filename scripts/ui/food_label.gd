extends Label

@export var game_manager: GameManager

func _ready():
	if game_manager == null:
		game_manager = get_node_or_null("/root/GameManager")
	if game_manager == null:
		return

	game_manager.food_changed.connect(_on_food_changed)
	_on_food_changed(game_manager.food)

func _on_food_changed(amount: int) -> void:
	text = "Food: " + str(amount)
