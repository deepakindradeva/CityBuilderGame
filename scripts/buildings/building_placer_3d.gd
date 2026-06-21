extends Node3D
class_name BuildingPlacer3D

@export var grid_size: float = 2.0
@export var building_scenes: Array[PackedScene] = []
@export var game_manager: GameManager
@export var wood_cost: int = 10
@export var camera: Camera3D

var _preview: Node3D
var _selected_index: int = -1
var _can_place: bool = false

func _ready():
	if game_manager == null:
		game_manager = get_node_or_null("/root/GameManager")
	if camera == null:
		camera = get_viewport().get_camera_3d()

	_preview = Node3D.new()
	_preview.visible = false
	add_child(_preview)

	if building_scenes.size() > 0:
		select_building(0)

func _input(event: InputEvent):
	if event is InputEventKey and event.pressed and not event.echo:
		var key = event.keycode
		if key >= KEY_1 and key <= KEY_9:
			var idx = key - KEY_1
			if idx < building_scenes.size():
				select_building(idx)
				get_viewport().set_input_as_handled()
			return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _selected_index >= 0 and _can_place:
			_place_building()
			get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		select_building(-1)
		get_viewport().set_input_as_handled()
		return

func _process(_delta):
	if _selected_index < 0:
		_preview.visible = false
		return

	var mouse_pos = get_viewport().get_mouse_position()
	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_dir = camera.project_ray_normal(mouse_pos)

	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.new()
	query.from = ray_origin
	query.to = ray_origin + ray_dir * 1000.0
	query.collision_mask = 1

	var result = space_state.intersect_ray(query)
	if result.is_empty():
		_preview.visible = false
		_can_place = false
		return

	var hit_pos = result["position"]
	var snapped_pos = _snap_to_grid(hit_pos)
	_preview.position = snapped_pos
	_preview.visible = true
	_update_validity(snapped_pos)

func select_building(index: int) -> void:
	_selected_index = clamp(index, -1, building_scenes.size() - 1)

	for child in _preview.get_children():
		child.queue_free()

	if _selected_index < 0:
		_preview.visible = false
		return

	var scene = building_scenes[_selected_index]
	if scene == null:
		_preview.visible = false
		return

	var instance = scene.instantiate()
	_preview.add_child(instance)
	_preview.visible = true

func _place_building() -> void:
	if _selected_index < 0 or _selected_index >= building_scenes.size():
		return

	if game_manager != null and not game_manager.spend_wood(wood_cost):
		return

	var scene = building_scenes[_selected_index]
	if scene == null:
		return

	var building = scene.instantiate()
	building.position = _preview.position
	get_parent().add_child(building)
	print("Placed building at ", building.position)

func _snap_to_grid(world_pos: Vector3) -> Vector3:
	var x = floorf(world_pos.x / grid_size) * grid_size + grid_size / 2.0
	var z = floorf(world_pos.z / grid_size) * grid_size + grid_size / 2.0
	return Vector3(x, 0.0, z)

func _update_validity(world_pos: Vector3) -> void:
	_can_place = true

	if game_manager != null and game_manager.wood < wood_cost:
		_can_place = false

	for body in _get_buildings_at(world_pos):
		if body != _preview:
			_can_place = false
			break

	var color = Color(0.0, 1.0, 0.0, 0.5) if _can_place else Color(1.0, 0.0, 0.0, 0.5)
	for mesh in _preview.find_children("*", "MeshInstance3D"):
		var mat = mesh.get_active_material(0)
		if mat != null:
			var dup = mat.duplicate()
			dup.albedo_color = color
			dup.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mesh.material_override = dup

func _get_buildings_at(world_pos: Vector3) -> Array[Node3D]:
	var query := PhysicsShapeQueryParameters3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(grid_size - 0.1, 2.0, grid_size - 0.1)
	query.shape = shape
	query.transform = Transform3D(Basis(), world_pos)
	query.collision_mask = 1

	var result := get_world_3d().direct_space_state.intersect_shape(query)
	var bodies: Array[Node3D] = []
	for hit in result:
		var collider = hit["collider"] as Node3D
		if collider != null and collider != self:
			bodies.append(collider)
	return bodies
