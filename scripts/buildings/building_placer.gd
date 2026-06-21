extends Node2D
class_name BuildingPlacer

## Grid tile size in pixels. All buildings snap to this.
@export var grid_size: int = 64

## The list of buildings that can be placed. Assign scene files in the inspector.
@export var building_scenes: Array[PackedScene] = []

## Optional tilemap used for collision / valid-area checks.
@export var ground_tilemap: TileMap

## GameManager autoload for resource economy. Auto-detected if left empty.
@export var game_manager: GameManager

## Wood cost to place one building.
@export var wood_cost: int = 10

## Visual preview node. Created at runtime.
var _preview: Node2D

## Index of the currently selected building in `building_scenes`.
var _selected_index: int = -1

## Whether the current preview position is a valid placement spot.
var _can_place: bool = false

func _ready():
	# Auto-find the GameManager autoload if no reference was assigned.
	if game_manager == null:
		game_manager = get_node_or_null("/root/GameManager")
		if game_manager == null:
			push_error("BuildingPlacer: GameManager autoload not found.")

	# Ensure we have a preview node ready to move around.
	_preview = Node2D.new()
	_preview.modulate = Color(0.0, 1.0, 0.0, 0.5)
	add_child(_preview)

	# Select the first building by default if any are provided.
	if building_scenes.size() > 0:
		select_building(0)
	else:
		_preview.visible = false


func _input(event: InputEvent):
	# Number keys 1-9 select a building from the list.
	if event is InputEventKey and event.pressed and not event.echo:
		var key = event.keycode
		if key >= KEY_1 and key <= KEY_9:
			var idx = key - KEY_1
			if idx < building_scenes.size():
				select_building(idx)
				get_viewport().set_input_as_handled()
			return

	# Place building on left click.
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _selected_index >= 0 and _can_place:
			_place_building()
			get_viewport().set_input_as_handled()
		return

	# Cancel / clear selection on right click.
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		select_building(-1)
		get_viewport().set_input_as_handled()
		return


func _process(_delta):
	if _selected_index < 0:
		_preview.visible = false
		return

	_preview.visible = true
	var snapped_pos = _snap_to_grid(get_global_mouse_position())
	_preview.position = snapped_pos
	_update_validity(snapped_pos)


## Selects a building by index in `building_scenes`. Pass -1 to clear selection.
func select_building(index: int) -> void:
	_selected_index = clamp(index, -1, building_scenes.size() - 1)

	# Remove old preview children.
	for child in _preview.get_children():
		child.queue_free()

	if _selected_index < 0:
		_preview.visible = false
		return

	var scene = building_scenes[_selected_index]
	if scene == null:
		_preview.visible = false
		return

	# Build a preview instance. We only show it; we don't add it to the world yet.
	var instance = scene.instantiate()
	_preview.add_child(instance)

	# Disable any physics / collision logic in the preview.
	for node in _preview.find_children("*", "CollisionObject2D"):
		node.collision_layer = 0
		node.collision_mask = 0

	_preview.visible = true


func _place_building() -> void:
	if _selected_index < 0 or _selected_index >= building_scenes.size():
		return

	# Pay the wood cost before placing. The preview already shows red when broke,
	# but this guards against race conditions between frames.
	if game_manager != null and not game_manager.spend_wood(wood_cost):
		return

	var scene = building_scenes[_selected_index]
	if scene == null:
		return

	var building = scene.instantiate()
	building.position = _preview.position

	# Add to the same parent as the placer so it lives in the world, not under the preview.
	get_parent().add_child(building)

	# Optional: emit a signal or play a sound here.
	print("Placed building at ", building.position)


## Snaps a world coordinate to the nearest 64x64 grid cell.
func _snap_to_grid(world_pos: Vector2) -> Vector2:
	var x = floorf(world_pos.x / grid_size) * grid_size + grid_size / 2.0
	var y = floorf(world_pos.y / grid_size) * grid_size + grid_size / 2.0
	return Vector2(x, y)


## Checks whether the proposed cell is valid. Override or extend for terrain/collision checks.
func _update_validity(world_pos: Vector2) -> void:
	_can_place = true

	# Reject placement if the player cannot afford the building.
	if game_manager != null and game_manager.wood < wood_cost:
		_can_place = false

	# Example: reject placement if the ground tilemap does not have a tile here.
	if ground_tilemap != null:
		var cell = ground_tilemap.local_to_map(ground_tilemap.to_local(world_pos))
		var source_id = ground_tilemap.get_cell_source_id(0, cell)
		if source_id == -1:
			_can_place = false

	# Example: reject if a building already occupies this cell.
	for body in _get_buildings_at(world_pos):
		if body != _preview:
			_can_place = false
			break

	# Update preview color: green = valid, red = invalid.
	_preview.modulate = Color(0.0, 1.0, 0.0, 0.5) if _can_place else Color(1.0, 0.0, 0.0, 0.5)


## Returns a list of physics bodies occupying a 64x64 cell. Useful for overlap tests.
func _get_buildings_at(world_pos: Vector2) -> Array[Node2D]:
	var query := PhysicsShapeQueryParameters2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(grid_size - 2, grid_size - 2)
	query.shape = shape
	query.transform = Transform2D(0, world_pos)
	query.collision_mask = 1

	var result := get_world_2d().direct_space_state.intersect_shape(query)
	var bodies: Array[Node2D] = []
	for hit in result:
		var collider = hit["collider"] as Node2D
		if collider != null and collider != self:
			bodies.append(collider)
	return bodies
