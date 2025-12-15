@tool
class_name Door
extends Node3D

# Metadata key for per-node localization tracking
const META_LOCALIZED := "_children_localized"
func _enter_tree() -> void:
	if not Engine.is_editor_hint():
		return

	var scene_root := get_tree().edited_scene_root
	if scene_root == null or self == scene_root:
		return
		
	if get_meta("_children_localized", false):
		return

	for child in get_children():
		if child.owner != scene_root:
			child.owner = scene_root
			
	scene_file_path = ""
	if self.owner != scene_root:
		self.owner = scene_root
	
	set_display_folded(true)
	set_meta("_children_localized", true)
