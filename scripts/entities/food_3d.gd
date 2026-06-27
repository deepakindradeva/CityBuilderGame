extends Area3D

@export var food_value: int = 1

var _collected: bool = false

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if _collected:
		return
	if not body.is_in_group("player"):
		return

	_collected = true
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager != null:
		game_manager.add_food(food_value)

	queue_free()
