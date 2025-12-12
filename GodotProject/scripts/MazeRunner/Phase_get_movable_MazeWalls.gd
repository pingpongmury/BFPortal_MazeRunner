@tool
extends Node

# Phase unique ObjId
@export var ObjId: int = -1:
	set(value):
		ObjId = value
		call_deferred("_refresh_wall_ids")

signal phase_obj_id_changed(new_id)

# Storage for DoorComponent ObjIds
var wall_ids: Array = []

@export var _wall_ids: Array:
	get:
		if wall_ids.size() != _checkNumGGChild():
			_refresh_wall_ids()
		return wall_ids

func _ready():
	# Watch for Doors added or removed
	if not is_connected("child_entered_tree", Callable(self, "_on_direct_child_change")):
		connect("child_entered_tree", Callable(self, "_on_direct_child_change"))
	if not is_connected("child_exiting_tree", Callable(self, "_on_direct_child_change")):
		connect("child_exiting_tree", Callable(self, "_on_direct_child_change"))

	call_deferred("_refresh_wall_ids")


func _on_direct_child_change(_child: Node) -> void:
	call_deferred("_refresh_wall_ids")


func _refresh_wall_ids() -> void:
	if not is_inside_tree():
		return

	wall_ids.clear()

	for child in get_children(): # Doors
		for grandchild in child.get_children(): # Static/Dynamic
			if grandchild.get("movable"):
				var tempWallId: int = ObjId
				tempWallId += 100000 * int(grandchild.get("height"))
				tempWallId += 10000  * int(grandchild.get("movement_type"))
				tempWallId += 1000   * int(grandchild.get("direction"))
				tempWallId += 10

				var index := wall_ids.find(tempWallId + 1)
				while index != -1:
					tempWallId += 10
					index = wall_ids.find(tempWallId + 1)

				grandchild.set("ObjId", tempWallId)

				var ggindex := 1
				for ggchild in grandchild.get_children(): # DoorComponents
					ggchild.set("ObjId", tempWallId + ggindex)
					wall_ids.append(tempWallId + ggindex)
					ggindex += 1

				grandchild.notify_property_list_changed()

	notify_property_list_changed()


func _get_property_list() -> Array:
	return [
		{
			"name": "Export Wall IDs",
			"type": TYPE_BOOL,
			"usage": PROPERTY_USAGE_EDITOR
		}
	]


func _set(property: StringName, value) -> bool:
	if property == "Export Wall IDs":
		_export_wall_ids()
		return true
	return false


func _export_wall_ids():
	var out := "const MAZE_PHASE_"
	out += char(int(ObjId / 1000000) + 64)
	out += "_WALL_IDS : number[] = ["

	for i in range(wall_ids.size()):
		out += str(wall_ids[i])
		if i < wall_ids.size() - 1:
			out += ","

	out += "];"
	print(out)


func _checkNumGGChild() -> int:
	var numGGChild: int = 0
	for child in get_children():
		for gchild in child.get_children():
			if gchild.get("movable"):
				for ggchild in gchild.get_children():
					numGGChild += 1
	return numGGChild
