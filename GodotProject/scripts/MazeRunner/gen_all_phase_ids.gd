@tool
extends Node

func _get_property_list() -> Array:
	var props: Array = []
	
	props.append({
		"name": "Export All IDs",
		"type": TYPE_BOOL,
		"usage": PROPERTY_USAGE_EDITOR,
		"hint": PROPERTY_HINT_NONE,
		"hint_string": "",
	})
	return props
	
func _set(property: StringName, value) -> bool:
	if property == "Export All IDs":
		_on_run_action_pressed()
		return true
	return false

func _on_run_action_pressed():
	for child in get_children():
		if child.get("wall_ids") != null:
			child._on_run_action_pressed()
