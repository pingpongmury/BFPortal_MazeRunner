@tool
class_name Door
extends Node3D

func _enter_tree() -> void:
	if get_node(".") == get_tree().edited_scene_root:	# If the node running this cript IS the scene root:
		return											# 	Don't do anything after this
	make_local(self)

var is_local = false
func make_local(node: Node) -> void:
	if(!is_local):										# If this node is already owned by the SceneTree root Node:
		node.owner = get_tree().edited_scene_root		# 	Make this node owned by the SceneTree root Node
		is_local = true									#	and keep track of when you have

func on_enter_tree() -> void:
	return
