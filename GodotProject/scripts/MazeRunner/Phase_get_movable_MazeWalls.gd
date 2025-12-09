@tool
extends Node


# Parent has its own unique ObjId
@export var ObjId: int = -1:
	set(value):
		ObjId = value
		_refresh_wall_ids()


# Signal to notify the parent when ObjId changes
signal phase_obj_id_changed(new_id)


# Internal storage of wall ObjIds
var wall_ids: Array = []


# Exported getter to show dynamic wall IDs in Inspector
@export var _wall_ids: Array:
	get:
		if wall_ids.size() != _checkNumGGChild(): #if there's not the same number of walls as there are elements in wall id array
			_refresh_wall_ids()
		return wall_ids


# Refresh wall_ids for direct children only
func _refresh_wall_ids() -> void:
	wall_ids.clear()
	var ctr: int = 1
	
	for child in get_children():
		for grandchild in child.get_children():
			if grandchild.get("movable"):
				var tempWallId: int = self.ObjId + (100000 * grandchild.get("height")) + (10000 * grandchild.get("movement_type")) + (1000 * grandchild.get("direction") + 10)
				var index := wall_ids.find(tempWallId + 1)
				while index != -1: #while this id already exists
					tempWallId += 10
					index = wall_ids.find(tempWallId + 1)
				grandchild.set("ObjId",tempWallId) #Set ObjId for door root node
				var ggindex = 1
				for ggchild in grandchild.get_children(): #For all components in door root node
					ggchild.set("ObjId",tempWallId + ggindex) #Give them a unique ObjId
					wall_ids.append(tempWallId + ggindex) #And add them to the list of moveable door objects
					ggindex += 1
				grandchild.notify_property_list_changed()
			
		notify_property_list_changed()
 

func _ready() -> void: 
	if wall_ids.size() != _checkNumGGChild(): #if there's not the same number of moving wall components as there are elements in wall id array
		_refresh_wall_ids()

func _get_property_list() -> Array:
	var props: Array = []
	
	props.append({
		"name": "Export Wall IDs",
		"type": TYPE_BOOL,
		"usage": PROPERTY_USAGE_EDITOR,
		"hint": PROPERTY_HINT_NONE,
		"hint_string": "",
	})
	
	return props

func _set(property: StringName, value) -> bool:
	if property == "Export Wall IDs":
		_on_run_action_pressed()
		return true
	return false

func _on_run_action_pressed():
	var out := "const MAZE_PHASE_"
	out += char(self.ObjId / 1000000 + 64)
	out += "_WALL_IDS : number[] = ["
	var count := wall_ids.size()

	for i in count:
		out += str(wall_ids[i])
		if i < count - 1:
			out += ","
	out += "];"
	print(out)

func _checkNumGGChild():
	var numGGChild: int = 0
	for child in get_children():
		for gchild in child.get_children():
			if gchild.get("movable"):
				for ggchild in gchild.get_children():
					numGGChild += 1
	return numGGChild
