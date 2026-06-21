extends CanvasLayer
class_name UIManager

## The GameManager autoload to read from. Set in the inspector or leave empty
## to auto-find the global `GameManager` node.
@export var game_manager: GameManager

## Building placer used by the bottom toolbar. Can be BuildingPlacer (2D) or BuildingPlacer3D.
@export var building_placer: Node

var _wood_label: Label
var _food_label: Label
var _day_label: Label
var _log_label: Label

func _ready():
	if game_manager == null:
		game_manager = get_node_or_null("/root/GameManager")
	if game_manager == null:
		push_error("UIManager: GameManager not found. Register it as an Autoload.")
		return

	if building_placer == null:
		building_placer = get_node_or_null("../BuildingPlacer")

	game_manager.wood_changed.connect(_on_wood_changed)
	game_manager.food_changed.connect(_on_food_changed)
	game_manager.day_changed.connect(_on_day_changed)

	_build_ui()

	# Initialize immediately so labels are not blank on the first frame.
	_on_wood_changed(game_manager.wood)
	_on_food_changed(game_manager.food)
	_on_day_changed(game_manager.day)

	_log("Settlement founded. Survive the season.")


func _build_ui() -> void:
	var top_bar := HBoxContainer.new()
	top_bar.anchors_preset = Control.PRESET_TOP_WIDE
	top_bar.offset_left = 16
	top_bar.offset_top = 16
	top_bar.offset_right = -16
	top_bar.offset_bottom = 64
	top_bar.add_theme_constant_override("separation", 16)
	add_child(top_bar)

	# Left resource panel.
	var resource_panel := _create_panel()
	top_bar.add_child(resource_panel)

	var resource_margin := _create_margin(12, 8, 12, 8)
	resource_panel.add_child(resource_margin)

	var resource_box := HBoxContainer.new()
	resource_box.add_theme_constant_override("separation", 20)
	resource_margin.add_child(resource_box)

	resource_box.add_child(_create_icon("🪵", Color(0.6, 0.4, 0.2)))
	_wood_label = _create_value_label("0")
	resource_box.add_child(_wood_label)

	resource_box.add_child(_create_icon("🍞", Color(0.85, 0.65, 0.25)))
	_food_label = _create_value_label("0")
	resource_box.add_child(_food_label)

	# Center day badge.
	var center_spacer := Control.new()
	center_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(center_spacer)

	var day_panel := _create_panel()
	top_bar.add_child(day_panel)

	var day_margin := _create_margin(24, 8, 24, 8)
	day_panel.add_child(day_margin)

	_day_label = Label.new()
	_day_label.text = "Day 1"
	_day_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_day_label.add_theme_font_size_override("font_size", 22)
	_day_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	day_margin.add_child(_day_label)

	var right_spacer := Control.new()
	right_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(right_spacer)

	# Bottom toolbar.
	var bottom_bar := HBoxContainer.new()
	bottom_bar.anchors_preset = Control.PRESET_BOTTOM_WIDE
	bottom_bar.offset_left = 16
	bottom_bar.offset_top = -72
	bottom_bar.offset_right = -16
	bottom_bar.offset_bottom = -16
	bottom_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(bottom_bar)

	var toolbar := _create_panel()
	bottom_bar.add_child(toolbar)

	var toolbar_margin := _create_margin(12, 8, 12, 8)
	toolbar.add_child(toolbar_margin)

	var toolbar_box := HBoxContainer.new()
	toolbar_box.add_theme_constant_override("separation", 10)
	toolbar_margin.add_child(toolbar_box)

	var house_btn := _create_tool_button("House")
	house_btn.pressed.connect(_on_build_button_pressed.bind(0))
	toolbar_box.add_child(house_btn)

	var cancel_btn := _create_tool_button("Cancel")
	cancel_btn.pressed.connect(_on_build_button_pressed.bind(-1))
	toolbar_box.add_child(cancel_btn)

	# Bottom-left event log.
	var log_panel := _create_panel()
	log_panel.anchors_preset = Control.PRESET_BOTTOM_LEFT
	log_panel.offset_left = 16
	log_panel.offset_top = -176
	log_panel.offset_right = 336
	log_panel.offset_bottom = -80
	add_child(log_panel)

	var log_margin := _create_margin(10, 8, 10, 8)
	log_panel.add_child(log_margin)

	var log_box := VBoxContainer.new()
	log_margin.add_child(log_box)

	var log_header := Label.new()
	log_header.text = "Events"
	log_header.add_theme_font_size_override("font_size", 14)
	log_header.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	log_box.add_child(log_header)

	_log_label = Label.new()
	_log_label.text = ""
	_log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_log_label.add_theme_font_size_override("font_size", 14)
	_log_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	log_box.add_child(_log_label)


func _create_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.08, 0.9)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.25, 0.25, 0.25, 1)
	return style


func _create_button_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.18, 0.18, 0.18, 1)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.35, 0.35, 0.35, 1)
	return style


func _create_button_hover_style() -> StyleBoxFlat:
	var style := _create_button_style()
	style.bg_color = Color(0.28, 0.28, 0.28, 1)
	return style


func _create_button_pressed_style() -> StyleBoxFlat:
	var style := _create_button_style()
	style.bg_color = Color(0.12, 0.12, 0.12, 1)
	style.border_color = Color(0.5, 0.5, 0.5, 1)
	return style


func _create_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _create_panel_style())
	return panel


func _create_margin(left: int, top: int, right: int, bottom: int) -> MarginContainer:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", left)
	margin.add_theme_constant_override("margin_top", top)
	margin.add_theme_constant_override("margin_right", right)
	margin.add_theme_constant_override("margin_bottom", bottom)
	return margin


func _create_icon(emoji: String, color: Color) -> Label:
	var label := Label.new()
	label.text = emoji
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 22)
	label.custom_minimum_size = Vector2(28, 28)
	return label


func _create_value_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	return label


func _create_tool_button(text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(80, 40)
	btn.add_theme_font_size_override("font_size", 16)
	btn.add_theme_stylebox_override("normal", _create_button_style())
	btn.add_theme_stylebox_override("hover", _create_button_hover_style())
	btn.add_theme_stylebox_override("pressed", _create_button_pressed_style())
	btn.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	btn.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))
	btn.add_theme_color_override("font_pressed_color", Color(0.9, 0.9, 0.9, 1))
	return btn


func _on_build_button_pressed(index: int) -> void:
	if building_placer != null and building_placer.has_method("select_building"):
		building_placer.select_building(index)
		if index >= 0:
			_log("Building selected.")
		else:
			_log("Build mode cancelled.")


func _log(message: String) -> void:
	print(message)
	if _log_label != null:
		_log_label.text += message + "\n"


func _on_wood_changed(amount: int) -> void:
	if _wood_label != null:
		_wood_label.text = str(amount)


func _on_food_changed(amount: int) -> void:
	if _food_label != null:
		_food_label.text = str(amount)


func _on_day_changed(new_day: int) -> void:
	if _day_label != null:
		_day_label.text = "Day " + str(new_day)
