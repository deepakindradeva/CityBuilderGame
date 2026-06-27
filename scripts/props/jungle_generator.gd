extends Node3D

@export var tree_scenes: Array[PackedScene] = []
@export var bush_scenes: Array[PackedScene] = []
@export var rock_scenes: Array[PackedScene] = []
@export var grass_scenes: Array[PackedScene] = []
@export var food_scene: PackedScene

@export var area_radius: float = 60.0
@export var clear_radius_around_player: float = 5.0

@export var tree_count: int = 180
@export var bush_count: int = 200
@export var rock_count: int = 80
@export var grass_count: int = 400
@export var food_count: int = 15

@export var random_seed: int = 12345

func _ready():
	_generate()

func _generate() -> void:
	seed(random_seed)

	_clear_existing()

	# Trees are bigger and clustered, with non-uniform scaling for natural shapes.
	_place_clustered(tree_scenes, tree_count, 0.8, 2.5, 0.0, 8.0, 1.0)
	_place_scattered(bush_scenes, bush_count, 0.8, 1.8, 0.0)
	_place_scattered(rock_scenes, rock_count, 0.6, 1.5, 0.0)
	_place_scattered(grass_scenes, grass_count, 0.6, 1.4, 0.0)
	_place_scattered([food_scene], food_count, 0.5, 1.0, 0.0)

func _clear_existing() -> void:
	for child in get_children():
		child.queue_free()

func _place_scattered(scenes: Array[PackedScene], count: int, min_scale: float, max_scale: float, y_offset: float) -> void:
	if scenes.is_empty() or scenes[0] == null:
		return

	var attempts: int = 0
	var placed: int = 0

	while placed < count and attempts < count * 10:
		attempts += 1

		var angle = randf() * TAU
		var distance = sqrt(randf()) * area_radius
		var pos = Vector3(cos(angle) * distance, 0.0, sin(angle) * distance)

		if pos.length() < clear_radius_around_player:
			continue

		var scene = scenes[randi() % scenes.size()]
		var instance = scene.instantiate()
		instance.position = Vector3(pos.x, y_offset, pos.z)
		instance.rotation.y = randf() * TAU

		var s = randf_range(min_scale, max_scale)
		instance.scale = Vector3(s, s * randf_range(0.85, 1.15), s)

		add_child(instance)
		placed += 1

func _place_clustered(scenes: Array[PackedScene], count: int, min_scale: float, max_scale: float, y_offset: float, cluster_radius: float, cluster_strength: float) -> void:
	if scenes.is_empty() or scenes[0] == null:
		return

	var cluster_centers: Array[Vector3] = []
	for i in range(max(1, count / 8)):
		var angle = randf() * TAU
		var distance = sqrt(randf()) * area_radius
		cluster_centers.append(Vector3(cos(angle) * distance, 0.0, sin(angle) * distance))

	var attempts: int = 0
	var placed: int = 0

	while placed < count and attempts < count * 15:
		attempts += 1

		var center = cluster_centers[randi() % cluster_centers.size()]
		var angle = randf() * TAU
		var distance = randf() * cluster_radius
		var pos = center + Vector3(cos(angle) * distance, 0.0, sin(angle) * distance)

		if pos.length() > area_radius or pos.length() < clear_radius_around_player:
			continue

		var scene = scenes[randi() % scenes.size()]
		var instance = scene.instantiate()
		instance.position = Vector3(pos.x, y_offset, pos.z)
		instance.rotation.y = randf() * TAU

		var s = randf_range(min_scale, max_scale)
		instance.scale = Vector3(s, s * randf_range(0.85, 1.15), s)

		add_child(instance)
		placed += 1
