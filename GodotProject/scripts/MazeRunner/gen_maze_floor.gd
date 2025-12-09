#HighwayOverpass_Foundation_01 dims: [10.2399997711182, 8.32000160217285, 19.8911972045898]

@tool
extends EditorScript

func _run():
	var template_scene: PackedScene = load("res://objects/Global/Generic/Common/Architecture/HighwayOverpass_Foundation_01.tscn") as PackedScene
	var parent_node_name: String = "GridParent"

	var root = get_editor_interface().get_edited_scene_root()
	if not root:
		push_error("No scene open!")
		return

	var parent: Node3D = root.get_node_or_null(parent_node_name)
	if not parent:
		parent = Node3D.new()
		parent.name = parent_node_name
		root.add_child(parent)

	# Grid parameters
	var rows = 10
	var cols = 2*rows
	var x_spacing = 10.2399997711182
	var z_spacing = 19.8911972045898

	# Remove previous instances of the template
	for child in parent.get_children():
		if child.filename == template_scene.resource_path:
			child.queue_free()

	# Create the grid
	for x in range(cols):
		for z in range(rows):
			var instance = template_scene.instantiate() as Node3D
			instance.position = Vector3(x * x_spacing, 0, z * z_spacing)
			parent.add_child(instance)

	# Mark the scene as modified so nodes persist in the tree
	root.set_scene_modified(true)

	print("Grid created successfully.")
