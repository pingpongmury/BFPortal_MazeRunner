@tool
extends EditorPlugin

const DOOR_CLASS := "DoorComponent"
const WATCHED_PROPERTIES := [
	"phase",
	"height",
	"movement_type",
	"direction",
	"is_movable"
]

var _inspector: EditorInspector
var _recompute_pending := false
var _suppress_property_events := false


func _enter_tree() -> void:
	_inspector = get_editor_interface().get_inspector()
	_inspector.property_edited.connect(_on_property_edited)

	var tree := get_editor_interface().get_editor_main_screen().get_tree()
	tree.node_added.connect(_on_node_added)
	tree.node_removed.connect(_on_node_removed)


func _exit_tree() -> void:
	if _inspector and _inspector.property_edited.is_connected(_on_property_edited):
		_inspector.property_edited.disconnect(_on_property_edited)

	var tree := get_editor_interface().get_editor_main_screen().get_tree()
	if tree.node_added.is_connected(_on_node_added):
		tree.node_added.disconnect(_on_node_added)

	if tree.node_removed.is_connected(_on_node_removed):
		tree.node_removed.disconnect(_on_node_removed)


# --------------------------------------------------
# Signal handlers
# --------------------------------------------------


func _on_property_edited(property_name: String) -> void:
	if _suppress_property_events:
		return

	if property_name in WATCHED_PROPERTIES:
		_request_recompute()


func _on_node_added(node: Node) -> void:
	if node is DoorComponent:
		_request_recompute()


func _on_node_removed(node: Node) -> void:
	if node is DoorComponent:
		_request_recompute()


# --------------------------------------------------
# Recompute control
# --------------------------------------------------

func _request_recompute() -> void:
	if _recompute_pending:
		return

	_recompute_pending = true
	call_deferred("_recompute_all_obj_ids")


# --------------------------------------------------
# Core logic
# --------------------------------------------------

func _recompute_all_obj_ids() -> void:
	_recompute_pending = false

	var root := get_editor_interface().get_edited_scene_root()
	if not root:
		return
	
	var doors := get_tree().get_nodes_in_group("all-doors")
	if doors.is_empty():
		return

	var buckets := {}  # Dictionary[int, Array]

	for door in doors:
		if not door.has_method("compute_base_obj_id"):
			continue

		var base_id = door.compute_base_obj_id()

		if base_id < 0:
			if door.ObjId != -1:
				_suppress_property_events = true
				door.ObjId = -1
				_suppress_property_events = false
			continue

		if not buckets.has(base_id):
			buckets[base_id] = []
		buckets[base_id].append(door)

	# Resolve collisions deterministically
	for base_id in buckets:
		var group: Array = buckets[base_id]

		group.sort_custom(func(a, b):
			return a.get_instance_id() < b.get_instance_id()
		)

		for i in group.size():
			var new_id = base_id + i
			if group[i].ObjId != new_id:
				_suppress_property_events = true
				group[i].ObjId = new_id
				_suppress_property_events = false
