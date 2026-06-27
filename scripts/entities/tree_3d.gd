extends StaticBody3D
class_name Tree3D

@export var wood_amount: int = 50

var _max_wood: int = 50

@onready var _tree_mesh: MeshInstance3D = _find_tree_mesh()

func _ready():
	_max_wood = max(wood_amount, 1)
	add_to_group("trees")
	_update_visual()


func _find_tree_mesh() -> MeshInstance3D:
	# Imported FBX tree uses a nested CommonTree_1 mesh
	var imported = get_node_or_null("CommonTree_1")
	if imported:
		var mesh = imported.get_node_or_null("CommonTree_1")
		if mesh is MeshInstance3D:
			return mesh

	# Fallback to old primitive names
	var leaves = get_node_or_null("Leaves")
	var trunk = get_node_or_null("Trunk")
	if leaves is MeshInstance3D:
		return leaves
	if trunk is MeshInstance3D:
		return trunk

	return null


func harvest(amount: int) -> int:
	var taken = min(amount, wood_amount)
	wood_amount -= taken
	_update_visual()

	if wood_amount <= 0:
		queue_free()

	return taken


func _update_visual() -> void:
	if _tree_mesh == null:
		return

	var ratio = clamp(float(wood_amount) / float(_max_wood), 0.0, 1.0)
	_tree_mesh.scale = Vector3(ratio, ratio, ratio)
