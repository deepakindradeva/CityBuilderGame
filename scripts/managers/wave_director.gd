extends Node

@export var zombie_scene: PackedScene
@export var map_radius: float = 64.0
@export var spawn_margin: float = 6.0
@export var base_enemies: int = 3
@export var enemies_per_threat: float = 1.5

var _game_manager: GameManager = null
var _first_day_skipped: bool = false

func _ready():
	_game_manager = get_node_or_null("/root/GameManager")
	if _game_manager == null:
		push_error("WaveDirector: GameManager autoload not found.")
		return

	_game_manager.day_changed.connect(_on_day_changed)


func _on_day_changed(new_day: int) -> void:
	# The initial Day 1 signal fires immediately on game start; skip it.
	if not _first_day_skipped:
		_first_day_skipped = true
		return

	spawn_wave()


func get_building_count() -> int:
	return get_tree().get_nodes_in_group("buildings").size()


func get_threat_level() -> float:
	var day := 1.0
	if _game_manager != null:
		day = float(_game_manager.day)

	var building_count := float(get_building_count())
	return (day * 1.5) + (building_count * 0.5)


func spawn_wave() -> void:
	var threat_level := get_threat_level()
	var enemy_count := ceili(float(base_enemies) + (enemies_per_threat * threat_level))

	print("WaveDirector: Day ", _game_manager.day, " | Threat ", threat_level, " | Spawning ", enemy_count, " zombies")

	var scene := zombie_scene
	if scene == null:
		scene = load("res://scenes/entities3d/zombie_3d.tscn") as PackedScene

	if scene == null:
		push_error("WaveDirector: No zombie_scene assigned.")
		return

	var root := get_tree().current_scene
	if root == null:
		root = self

	for i in range(enemy_count):
		var zombie = scene.instantiate() as Zombie3D
		if zombie == null:
			continue

		zombie.position = _pick_spawn_position()
		zombie.apply_mutation(threat_level)
		root.add_child(zombie)


func _pick_spawn_position() -> Vector3:
	var side := randi() % 4
	var edge := map_radius + spawn_margin
	var x := 0.0
	var z := 0.0

	match side:
		0: # top
			x = randf_range(-map_radius, map_radius)
			z = -edge
		1: # right
			x = edge
			z = randf_range(-map_radius, map_radius)
		2: # bottom
			x = randf_range(-map_radius, map_radius)
			z = edge
		3: # left
			x = -edge
			z = randf_range(-map_radius, map_radius)

	return Vector3(x, 0.0, z)
