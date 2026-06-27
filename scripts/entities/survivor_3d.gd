extends CharacterBody3D
class_name Survivor3D

enum State {
	IDLE,
	FIND_RESOURCE,
	MOVE,
	GATHER
}

@export var move_speed: float = 3.0
@export var stop_distance: float = 1.5
@export var harvest_interval: float = 1.0
@export var harvest_amount: int = 1
@export var max_health: float = 25.0

var health: float = max_health

var _state: State = State.IDLE
var _target: Node3D = null
var _harvest_timer: float = 0.0
var _game_manager: GameManager = null

@onready var _anim_tree: AnimationTree = $AnimationTree
@onready var _anim_player: AnimationPlayer = $UAL2_Standard/AnimationPlayer

func _ready():
	add_to_group("survivors")
	health = max_health

	_game_manager = get_node_or_null("/root/GameManager")
	_state = State.FIND_RESOURCE

	_setup_animation_tree()


func _setup_animation_tree() -> void:
	if _anim_tree == null or _anim_player == null:
		return

	var blend_space = AnimationNodeBlendSpace1D.new()
	blend_space.min_space = 0.0
	blend_space.max_space = 5.0

	var idle_node = AnimationNodeAnimation.new()
	idle_node.animation = "Idle_FoldArms"
	blend_space.add_blend_point(idle_node, 0.0)

	var walk_node = AnimationNodeAnimation.new()
	walk_node.animation = "Walk_Carry"
	blend_space.add_blend_point(walk_node, 5.0)

	var gather_node = AnimationNodeAnimation.new()
	gather_node.animation = "TreeChopping"
	blend_space.add_blend_point(gather_node, 2.5)

	_anim_tree.tree_root = blend_space
	_anim_tree.anim_player = _anim_player.get_path()
	_anim_tree.active = true
	_anim_tree.set("parameters/blend_position", 0.0)


func take_damage(amount: float) -> void:
	health -= amount

	if health <= 0.0:
		queue_free()


func _physics_process(delta: float) -> void:
	match _state:
		State.IDLE:
			velocity = Vector3.ZERO
			move_and_slide()
			_state = State.FIND_RESOURCE

		State.FIND_RESOURCE:
			_find_target()
			if _target != null and is_instance_valid(_target):
				_state = State.MOVE
			else:
				velocity = Vector3.ZERO
				move_and_slide()

		State.MOVE:
			if _target == null or not is_instance_valid(_target):
				_state = State.FIND_RESOURCE
				return

			var target_pos = _target.global_position
			target_pos.y = global_position.y
			var distance = global_position.distance_to(target_pos)

			if distance <= stop_distance:
				velocity = Vector3.ZERO
				move_and_slide()
				_harvest_timer = 0.0
				_state = State.GATHER
			else:
				var direction = (target_pos - global_position).normalized()
				velocity.x = direction.x * move_speed
				velocity.z = direction.z * move_speed
				velocity.y = 0.0
				move_and_slide()

		State.GATHER:
			if _target == null or not is_instance_valid(_target):
				_state = State.FIND_RESOURCE
				return

			velocity = Vector3.ZERO
			move_and_slide()

			_harvest_timer += delta
			if _harvest_timer >= harvest_interval:
				_harvest_timer = 0.0
				_harvest()

	_update_animation_blend()


func _update_animation_blend() -> void:
	if _anim_tree == null:
		return

	var flat_speed = Vector2(velocity.x, velocity.z).length()
	var blend_position = clamp(flat_speed, 0.0, 5.0)
	_anim_tree.set("parameters/blend_position", blend_position)


func _find_target() -> void:
	var trees = get_tree().get_nodes_in_group("trees")
	var nearest: Node3D = null
	var nearest_dist := INF

	for node in trees:
		var tree = node as Node3D
		if tree == null or not is_instance_valid(tree):
			continue
		var dist = global_position.distance_to(tree.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = tree

	_target = nearest


func _harvest() -> void:
	if _target == null or not is_instance_valid(_target):
		return

	if _target.has_method("harvest"):
		var taken = _target.harvest(harvest_amount)
		if taken > 0 and _game_manager != null:
			_game_manager.add_wood(taken)
