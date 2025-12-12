@tool
extends Node3D

# Each child has its own unique ObjId
@export var ObjId: int = -1:
	set(value):
		ObjId = value

var is_baked = false
var is_local = false

func _on_bake():
	if !is_baked and Engine.is_editor_hint():
		_make_local()
		is_baked = true

func _make_local():
	if(!is_local):
		# re-root the instance for root node
		self.owner = get_tree().edited_scene_root
		# and all the children
		for child in get_children():
			child.owner = get_tree().edited_scene_root
		# set the flag
		is_local = true
