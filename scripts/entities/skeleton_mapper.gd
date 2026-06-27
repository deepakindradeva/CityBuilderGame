extends Node3D

@export var source_skeleton_path: NodePath
@export var target_skeleton_path: NodePath

var _source_skeleton: Skeleton3D
var _target_skeleton: Skeleton3D

var _bone_map: Dictionary = {}

func _ready():
	_source_skeleton = _find_skeleton(source_skeleton_path)
	_target_skeleton = _find_skeleton(target_skeleton_path)

	if _source_skeleton == null or _target_skeleton == null or _source_skeleton == _target_skeleton:
		var all_skeletons = _find_all_skeletons(get_parent())
		if all_skeletons.size() >= 2:
			_source_skeleton = all_skeletons[0]
			_target_skeleton = all_skeletons[1]

	if _source_skeleton == null or _target_skeleton == null:
		push_error("SkeletonMapper: source or target skeleton not found.")
		return

	print("SkeletonMapper: source=", _source_skeleton.name, " target=", _target_skeleton.name)

	# Build bone name -> index mapping.
	var source_count = _source_skeleton.get_bone_count()
	var target_count = _target_skeleton.get_bone_count()
	var target_indices = {}
	for i in range(target_count):
		target_indices[_target_skeleton.get_bone_name(i)] = i

	for i in range(source_count):
		var name = _source_skeleton.get_bone_name(i)
		if target_indices.has(name):
			_bone_map[i] = target_indices[name]

	print("SkeletonMapper: mapped ", _bone_map.size(), " bones.")

func _find_skeleton(path: NodePath) -> Skeleton3D:
	if path.is_empty():
		return null
	var node = get_node_or_null(path)
	if node is Skeleton3D:
		return node
	return null

func _find_all_skeletons(node: Node) -> Array:
	var result = []
	for child in node.get_children():
		if child is Skeleton3D:
			result.append(child)
		result.append_array(_find_all_skeletons(child))
	return result

func _process(_delta):
	if _source_skeleton == null or _target_skeleton == null:
		return

	for source_index in _bone_map.keys():
		var target_index = _bone_map[source_index]
		var pose = _source_skeleton.get_bone_pose(source_index)
		_target_skeleton.set_bone_pose(target_index, pose)
