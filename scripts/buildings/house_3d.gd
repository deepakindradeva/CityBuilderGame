extends StaticBody3D
class_name House3D

@export var max_health: float = 100.0

var health: float = max_health

func _ready():
	add_to_group("buildings")
	health = max_health


func take_damage(amount: float) -> void:
	health -= amount

	if health <= 0.0:
		queue_free()
