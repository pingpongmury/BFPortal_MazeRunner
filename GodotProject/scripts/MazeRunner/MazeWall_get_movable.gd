@tool
extends Node

# Each child has its own unique ObjId
@export var ObjId: int = -1:
	set(value):
		ObjId = value

func _enter_tree():
	# Enables Editable Children, and Make Local programatically
	if get_parent().name.begins_with("Phase_") and !is_editable_instance(self):
		get_parent().set_editable_instance(self, true);
		make_local(self)
		for child in get_children():
			make_local(child)
			for grandchild in child.get_children():
				make_local(grandchild)
		set_display_folded(true)

# Call this on the root node of the instanced scene
func make_local(node: Node):
	node.scene_file_path = ""
	node.owner = get_tree().edited_scene_root
