@tool
extends Node3D

# Unique Door ObjId
@export var ObjId: int = -1

var is_baked = false
var is_local = false

func _notification(what):
	if what == NOTIFICATION_PARENTED:
		var phase = get_parent()
		if phase != null:
			phase.call_deferred("_refresh_wall_ids")
		var statDyns = self.get_children()
		for statDyn in statDyns:
			if statDyn.get("movable"):
				statDyn._set_color()
	elif what == NOTIFICATION_UNPARENTED:
		var phase = get_parent()	
		if phase != null:
			phase.call_deferred("_refresh_wall_ids")
		var statDyns = self.get_children()
		for statDyn in statDyns:
			if statDyn.get("movable"):
				statDyn._set_color()


func _on_bake():
	if not is_baked and Engine.is_editor_hint():
		_make_local()
		is_baked = true

func _make_local():
	if not is_local:
		self.owner = get_tree().edited_scene_root
		for child in get_children():
			child.owner = get_tree().edited_scene_root
			for grandchild in child.get_children():
				grandchild.owner = get_tree().edited_scene_root
		is_local = true
