extends CharacterBody3D

@export var move_speed: float = 4.0
@export var rotation_speed: float = 8.0

var _move_input: Vector2 = Vector2.ZERO

@onready var _anim_tree: AnimationTree = $AnimationTree
@onready var _anim_player: AnimationPlayer = $UAL2_Standard/AnimationPlayer
@onready var _camera_pivot: Node3D = $CameraPivot

func _ready():
	add_to_group("player")
	_setup_animation_tree()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _setup_animation_tree() -> void:
	if _anim_tree == null or _anim_player == null:
		return

	var blend_space = AnimationNodeBlendSpace1D.new()
	blend_space.min_space = 0.0
	blend_space.max_space = 5.0

	var idle_node = AnimationNodeAnimation.new()
	idle_node.animation = "Idle_FoldArms"
	blend_space.add_blend_point(idle_node, 0.0, 0)

	var walk_node = AnimationNodeAnimation.new()
	walk_node.animation = "Walk_Carry"
	blend_space.add_blend_point(walk_node, 5.0, 1)

	_anim_tree.tree_root = blend_space
	_anim_tree.anim_player = _anim_player.get_path()
	_anim_tree.active = true
	_anim_tree.set("parameters/blend_position", 0.0)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if _camera_pivot != null:
			_camera_pivot.rotate_y(-event.relative.x * 0.003)

func _physics_process(delta: float) -> void:
	_move_input = Input.get_vector("move_left", "move_right", "move_forward", "move_back")

	var camera_basis = Basis.IDENTITY
	if _camera_pivot != null:
		camera_basis = _camera_pivot.global_transform.basis

	var direction = Vector3.ZERO
	if _camera_pivot != null:
		direction = (camera_basis * Vector3(_move_input.x, 0.0, _move_input.y)).normalized()
	else:
		direction = (transform.basis * Vector3(_move_input.x, 0.0, _move_input.y)).normalized()

	if direction.length() > 0.01:
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed

		var target_rotation = atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, rotation_speed * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, move_speed * delta * 5.0)
		velocity.z = move_toward(velocity.z, 0.0, move_speed * delta * 5.0)

	velocity.y = 0.0
	move_and_slide()

	_update_animation_blend()

func _update_animation_blend() -> void:
	if _anim_tree == null:
		return

	var flat_speed = Vector2(velocity.x, velocity.z).length()
	var blend_position = clamp(flat_speed, 0.0, 5.0)
	_anim_tree.set("parameters/blend_position", blend_position)
