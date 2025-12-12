@tool
extends Node

func _get_property_list() -> Array:
	var props: Array = []
	
	props.append({
		"name": "Export All Ids",
		"type": TYPE_BOOL,
		"usage": PROPERTY_USAGE_EDITOR,
		"hint": PROPERTY_HINT_NONE,
		"hint_string": "",
	})
	return props
	
func _set(property: StringName, value) -> bool:
	if property == "Export All Ids":
		_on_run_action_pressed()
		return true
	return false

func _on_run_action_pressed():
	if get_children().size() != 0:
		for child in get_children():
			child._on_run_action_pressed()
