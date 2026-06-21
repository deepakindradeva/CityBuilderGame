extends StaticBody3D
class_name ResourceNode3D

@export var max_wood: int = 50

var current_wood: int = 0

@onready var _leaves: MeshInstance3D = $Leaves
@onready var _trunk: MeshInstance3D = $Trunk

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
	if max_wood > 0:
		var ratio = float(current_wood) / float(max_wood)
		if _leaves != null:
			_leaves.scale = Vector3(ratio, ratio, ratio)
		if _trunk != null:
			_trunk.scale = Vector3(ratio, ratio, ratio)
