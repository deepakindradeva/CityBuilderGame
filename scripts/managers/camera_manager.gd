extends Node3D

@export var top_down_camera_path: NodePath = "../CameraTopDown"
@export var perspective_camera_path: NodePath = "../CameraPerspective"

var top_down_camera: Camera3D
var perspective_camera: Camera3D

var _is_top_down: bool = true

func _ready():
	top_down_camera = get_node_or_null(top_down_camera_path)
	perspective_camera = get_node_or_null(perspective_camera_path)
	print("CameraManager ready: top=", top_down_camera, " persp=", perspective_camera)
	_toggle_cameras(true)

func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("toggle_camera"):
		_is_top_down = not _is_top_down
		_toggle_cameras(_is_top_down)
		print("Camera toggled: ", "top-down" if _is_top_down else "perspective")
		get_viewport().set_input_as_handled()

func toggle() -> void:
	_is_top_down = not _is_top_down
	_toggle_cameras(_is_top_down)
	print("Camera toggled: ", "top-down" if _is_top_down else "perspective")

func _toggle_cameras(use_top_down: bool) -> void:
	if top_down_camera != null:
		top_down_camera.current = use_top_down
		print("  top_down current = ", use_top_down)
	if perspective_camera != null:
		perspective_camera.current = not use_top_down
		print("  perspective current = ", not use_top_down)
