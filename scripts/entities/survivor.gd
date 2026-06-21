extends CharacterBody2D
class_name Survivor

@export var move_speed: float = 60.0
@export var stop_distance: float = 32.0
@export var harvest_interval: float = 1.0
@export var harvest_amount: int = 1
@export var game_manager: GameManager

var _target: ResourceNode = null
var _harvest_timer: float = 0.0

func _ready():
	if game_manager == null:
		game_manager = get_node_or_null("/root/GameManager")

func _physics_process(delta: float) -> void:
	_choose_target()

	if _target == null or not is_instance_valid(_target):
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var distance = global_position.distance_to(_target.global_position)
	if distance > stop_distance:
		var direction = global_position.direction_to(_target.global_position)
		velocity = direction * move_speed
		move_and_slide()
		_harvest_timer = 0.0
	else:
		velocity = Vector2.ZERO
		move_and_slide()
		_harvest_timer += delta
		if _harvest_timer >= harvest_interval:
			_harvest_timer = 0.0
			_harvest()

func _choose_target() -> void:
	if _target != null and is_instance_valid(_target):
		return

	var nodes = get_tree().get_nodes_in_group("resource_node")
	var nearest: ResourceNode = null
	var nearest_dist := INF

	for node in nodes:
		var resource = node as ResourceNode
		if resource == null or not is_instance_valid(resource):
			continue
		var dist = global_position.distance_to(resource.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = resource

	_target = nearest

func _harvest() -> void:
	if _target == null or not is_instance_valid(_target):
		return

	var taken = _target.harvest(harvest_amount)
	if taken > 0 and game_manager != null:
		game_manager.add_wood(taken)
