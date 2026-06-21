extends CharacterBody3D
class_name Survivor3D

@export var move_speed: float = 3.0
@export var stop_distance: float = 1.5
@export var harvest_interval: float = 1.0
@export var harvest_amount: int = 1

var _target: ResourceNode3D = null
var _harvest_timer: float = 0.0
var _game_manager: GameManager = null

func _ready():
	_game_manager = get_node_or_null("/root/GameManager")

func _physics_process(delta: float) -> void:
	_choose_target()

	if _target == null or not is_instance_valid(_target):
		velocity = Vector3.ZERO
		move_and_slide()
		return

	var target_pos = _target.global_position
	target_pos.y = global_position.y
	var distance = global_position.distance_to(target_pos)

	if distance > stop_distance:
		var direction = (target_pos - global_position).normalized()
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
		velocity.y = 0.0
		move_and_slide()
		_harvest_timer = 0.0
	else:
		velocity = Vector3.ZERO
		move_and_slide()
		_harvest_timer += delta
		if _harvest_timer >= harvest_interval:
			_harvest_timer = 0.0
			_harvest()

func _choose_target() -> void:
	if _target != null and is_instance_valid(_target):
		return

	var nodes = get_tree().get_nodes_in_group("resource_node")
	var nearest: ResourceNode3D = null
	var nearest_dist := INF

	for node in nodes:
		var resource = node as ResourceNode3D
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
	if taken > 0 and _game_manager != null:
		_game_manager.add_wood(taken)
