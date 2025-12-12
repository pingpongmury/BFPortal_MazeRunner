@tool
extends Node

@export var ObjId: int = -1

@export var movable: bool = false:
	set(value):
		movable = value
		call_deferred("_notify_phase")

var height: int = 0:
	set(value):
		height = value
		call_deferred("_notify_phase")

var movement_type: int = 0:
	set(value):
		movement_type = value
		call_deferred("_notify_phase")

var _direction: int = 0
func _get(property: StringName):
	if property == "direction":
		return _direction
	return null

func _set(property: StringName, value) -> bool:
	if property == "direction":
		_direction = value
		call_deferred("_notify_phase")
		return true
	return false

func _get_property_list() -> Array:
	var props: Array = []

	props.append({
		"name": "height",
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": "Full,Half"
	})

	if movable:
		props.append({
			"name": "movement_type",
			"type": TYPE_INT,
			"hint": PROPERTY_HINT_ENUM,
			"hint_string": "Linear,Rotational"
		})

		if movement_type == 0:
			props.append({
				"name": "direction",
				"type": TYPE_INT,
				"hint": PROPERTY_HINT_ENUM,
				"hint_string": "Up,Down,Left,Right"
			})
		else:
			props.append({
				"name": "direction",
				"type": TYPE_INT,
				"hint": PROPERTY_HINT_ENUM,
				"hint_string": "CW,CCW,Up,Down"
			})

	return props

func _ready() -> void:
	# Watch for DoorComponents added/removed
	if not is_connected("child_entered_tree", Callable(self, "_on_component_change")):
		connect("child_entered_tree", Callable(self, "_on_component_change"))
	if not is_connected("child_exiting_tree", Callable(self, "_on_component_change")):
		connect("child_exiting_tree", Callable(self, "_on_component_change"))

	call_deferred("_notify_phase")

	if movable:
		_set_color()

func _on_component_change(_child: Node) -> void:
	call_deferred("_notify_phase")

func _notify_phase():
	var door = get_parent()
	if door == null:
		return
	var phase = door.get_parent()
	if phase == null:
		return

	phase.call_deferred("_refresh_wall_ids")

func _set_color():
	for child in get_children():
		if child.get("color") and get_parent() and get_parent().get_parent():
			var phaseID = get_parent().get_parent().get("ObjId")
			match highest_digit(phaseID):
				-1: continue
				1: child.set("color", Color.DARK_RED)
				2: child.set("color", Color.NAVY_BLUE)
				3: child.set("color", Color.DARK_GREEN)
				4: child.set("color", Color.DARK_GOLDENROD)

func highest_digit(n: int) -> int:
	if n <= 0:
		return -1
	while n >= 10:
		n /= 10  # integer division
	print(n)
	return n
