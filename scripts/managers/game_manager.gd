extends Node

## Starting resources.
@export var starting_wood: int = 100
@export var starting_food: int = 50

## How many real-world seconds equal one in-game day.
@export var day_length_seconds: float = 10.0

var wood: int = 0
var food: int = 0
var day: int = 1

signal wood_changed(new_amount: int)
signal food_changed(new_amount: int)
signal day_changed(new_day: int)
signal food_depleted()

func _ready():
	wood = starting_wood
	food = starting_food

	emit_signal("wood_changed", wood)
	emit_signal("food_changed", food)
	emit_signal("day_changed", day)

	# Advance one day every `day_length_seconds`.
	var timer := Timer.new()
	timer.wait_time = day_length_seconds
	timer.autostart = true
	timer.timeout.connect(_on_day_tick)
	add_child(timer)


func _on_day_tick() -> void:
	food -= 1
	emit_signal("food_changed", food)

	day += 1
	emit_signal("day_changed", day)

	print("Day ", day, " started. Food: ", food)

	if food <= 0:
		emit_signal("food_depleted")


## Adds resources. Negative amounts spend them. Returns true if the transaction succeeded.
func modify_resource(resource_name: String, amount: int) -> bool:
	match resource_name.to_lower():
		"wood":
			if amount < 0 and wood < abs(amount):
				return false
			wood += amount
			emit_signal("wood_changed", wood)
			return true
		"food":
			if amount < 0 and food < abs(amount):
				return false
			food += amount
			emit_signal("food_changed", food)
			return true
		_:
			push_warning("Unknown resource: " + resource_name)
			return false


## Convenience wrappers.
func add_wood(amount: int) -> void:
	modify_resource("wood", amount)

func add_food(amount: int) -> void:
	modify_resource("food", amount)

func spend_wood(amount: int) -> bool:
	return modify_resource("wood", -amount)

func spend_food(amount: int) -> bool:
	return modify_resource("food", -amount)
