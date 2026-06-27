extends CharacterBody3D
class_name Zombie3D

enum State {
	SPAWN,
	SEEK,
	ATTACK,
	DEAD
}

@export var base_health: float = 30.0
@export var base_speed: float = 2.5
@export var base_damage: float = 5.0
@export var attack_range: float = 1.5
@export var attack_interval: float = 1.0

var max_health: float = base_health
var health: float = base_health
var move_speed: float = base_speed
var damage: float = base_damage
var mutation: String = ""

var _state: State = State.SPAWN
var _target: Node3D = null
var _attack_timer: float = 0.0

@onready var _anim_tree: AnimationTree = $AnimationTree
@onready var _anim_player: AnimationPlayer = $UAL2_Standard/AnimationPlayer
@onready var _mesh: MeshInstance3D = $UAL2_Standard/Armature/Skeleton3D/Mannequin

func _ready():
	_state = State.SEEK
	_setup_animation_tree()


func _setup_animation_tree() -> void:
	if _anim_tree == null or _anim_player == null:
		return

	var blend_space = AnimationNodeBlendSpace1D.new()
	blend_space.min_space = 0.0
	blend_space.max_space = 5.0

	var idle_node = AnimationNodeAnimation.new()
	idle_node.animation = "Zombie_Idle"
	blend_space.add_blend_point(idle_node, 0.0)

	var walk_node = AnimationNodeAnimation.new()
	walk_node.animation = "Zombie_Walk_Fwd"
	blend_space.add_blend_point(walk_node, 5.0)

	_anim_tree.tree_root = blend_space
	_anim_tree.anim_player = _anim_player.get_path()
	_anim_tree.active = true
	_anim_tree.set("parameters/blend_position", 0.0)


func _physics_process(delta: float) -> void:
	match _state:
		State.SPAWN:
			_state = State.SEEK

		State.SEEK:
			_find_target()
			if _target == null or not is_instance_valid(_target):
				velocity = Vector3.ZERO
				move_and_slide()
				return

			var target_pos = _target.global_position
			target_pos.y = global_position.y
			var distance = global_position.distance_to(target_pos)

			if distance <= attack_range:
				velocity = Vector3.ZERO
				move_and_slide()
				_attack_timer = 0.0
				_state = State.ATTACK
			else:
				var direction = (target_pos - global_position).normalized()
				velocity.x = direction.x * move_speed
				velocity.z = direction.z * move_speed
				velocity.y = 0.0
				move_and_slide()

		State.ATTACK:
			if _target == null or not is_instance_valid(_target):
				_state = State.SEEK
				return

			velocity = Vector3.ZERO
			move_and_slide()

			_attack_timer += delta
			if _attack_timer >= attack_interval:
				_attack_timer = 0.0
				_attack()

		State.DEAD:
			velocity = Vector3.ZERO
			move_and_slide()

	_update_animation_blend()


func _update_animation_blend() -> void:
	if _anim_tree == null:
		return

	var flat_speed = Vector2(velocity.x, velocity.z).length()
	var blend_position = clamp(flat_speed, 0.0, 5.0)
	_anim_tree.set("parameters/blend_position", blend_position)


func apply_mutation(threat_level: float) -> void:
	max_health = base_health * (1.0 + threat_level * 0.15)
	move_speed = base_speed * (1.0 + threat_level * 0.05)
	damage = base_damage * (1.0 + threat_level * 0.1)
	mutation = ""

	var roll := randf()
	if threat_level >= 5.0:
		if roll < 0.15:
			mutation = "Tank"
			max_health *= 3.0
		elif roll < 0.35:
			mutation = "Runner"
			move_speed *= 2.0

	health = max_health
	_update_visual_scale()

	print("Zombie3D spawned: threat=", threat_level, " mutation=", mutation, " hp=", max_health, " speed=", move_speed, " dmg=", damage)


func take_damage(amount: float) -> void:
	health -= amount
	_update_visual_scale()

	if health <= 0.0:
		_state = State.DEAD
		queue_free()


func _find_target() -> void:
	var survivors = get_tree().get_nodes_in_group("survivors")
	var buildings = get_tree().get_nodes_in_group("buildings")
	var candidates: Array[Node3D] = []
	candidates.assign(survivors)
	candidates.append_array(buildings)

	var nearest: Node3D = null
	var nearest_dist := INF

	for node in candidates:
		var target = node as Node3D
		if target == null or not is_instance_valid(target):
			continue
		var dist = global_position.distance_to(target.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = target

	_target = nearest


func _attack() -> void:
	if _target == null or not is_instance_valid(_target):
		return

	if _target.has_method("take_damage"):
		_target.take_damage(damage)


func _update_visual_scale() -> void:
	if _mesh == null:
		return

	var ratio = clamp(health / max_health, 0.3, 1.0)
	_mesh.scale = Vector3(ratio, ratio, ratio)
