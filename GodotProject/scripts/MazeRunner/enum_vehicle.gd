@tool
extends Node

# Parent has its own unique ObjId
@export var ObjId: int = -1:
	set(value):
		ObjId = value
		_refresh_ids()

# Refresh vehicle spawner ids for direct children only
func _refresh_ids() -> void:
	var ctr: int = 1	
	for child in get_children():
		child.set("ObjId",self.ObjId + ctr)
		ctr += 1
	notify_property_list_changed()
 
func _ready():
	# Connect signals for when children enter or exit this node
	self.connect("child_entered_tree", Callable(self, "_on_child_entered"))
	self.connect("child_exited_tree", Callable(self, "_on_child_exited"))

func _get_property_list() -> Array:
	var props: Array = []
	
	props.append({
		"name": "Export Vehicle IDs",
		"type": TYPE_BOOL,
		"usage": PROPERTY_USAGE_EDITOR,
		"hint": PROPERTY_HINT_NONE,
		"hint_string": "",
	})
	
	return props

func _set(property: StringName, value) -> bool:
	if property == "Export Vehicle IDs":
		_on_run_action_pressed()
		return true
	return false

func _on_run_action_pressed():
	_refresh_ids()
	var out := "Number of Vehicle Spawners: "
	out += str(get_children().size())
	print(out)
	
	
func _on_child_entered(child: Node) -> void:
	_refresh_ids()

func _on_child_exited(child: Node) -> void:
	_refresh_ids()
