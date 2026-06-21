extends StaticBody2D
class_name ResourceNode

@export var max_wood: int = 50
@export var sprite: Sprite2D

var current_wood: int = 0

func _ready():
	current_wood = max_wood
	add_to_group("resource_node")
	_update_visual()

func harvest(amount: int) -> int:
	var taken = min(amount, current_wood)
	current_wood -= taken
	_update_visual()
	if current_wood <= 0:
		queue_free()
	return taken

func _update_visual() -> void:
	if sprite != null and max_wood > 0:
		var ratio = float(current_wood) / float(max_wood)
		sprite.scale = Vector2(ratio, ratio)
