@tool
extends EditorPlugin

var button: Button
var template_scene_path := "res://objects/Global/Generic/Common/Architecture/HighwayOverpass_Foundation_01.tscn"

func _enter_tree():
    button = Button.new()
    button.text = "Build Floor Grid"
    add_control_to_container(CONTAINER_TOOLBAR, button)
    button.pressed.connect(_on_pressed)

func _exit_tree():
    remove_control_from_container(CONTAINER_TOOLBAR, button)
    button.free()

func _on_pressed():
    var iface = get_editor_interface()
    var root = iface.get_edited_scene_root()
    if root == null:
        push_error("Open a scene to modify.")
        return

    var undo := get_undo_redo()

    # Locate (or create) the FloorGrid parent
    var parent := root.get_node_or_null("FloorGrid")

    undo.create_action("Generate Floor Grid")

    if parent == null:
        parent = Node3D.new()
        parent.name = "FloorGrid"

        # IMPORTANT: add parent through UndoRedo
        undo.add_do_method(root, "add_child", parent)
        undo.add_undo_method(root, "remove_child", parent)

        # IMPORTANT: assign owner so parent is visible in SceneTree
        undo.add_do_method(parent, "set_owner", root)
    else:
        # Remove existing children
        for c in parent.get_children():
            undo.add_do_method(parent, "remove_child", c)
            undo.add_undo_method(parent, "add_child", c)

    # Load template
    var tscn := load(template_scene_path)
    if tscn == null:
        push_error("Could not load template.")
        undo.cancel_action()
        return

    # Grid settings (hardcoded)
    var rows = 30
    var cols = 2*rows
    var spacing_x = 10.2399997711182
    var spacing_z = 19.8911972045898

    # Create grid instances
    for x in range(cols):
        for z in range(rows):
            var inst: Node3D = tscn.instantiate() as Node3D
            inst.position = Vector3(x * spacing_x, 0, z * spacing_z)

            # Add via UndoRedo
            undo.add_do_method(parent, "add_child", inst)
            undo.add_undo_method(parent, "remove_child", inst)

            # CRITICAL: assign owner so child appears in Scene Tree
            undo.add_do_method(inst, "set_owner", root)

    undo.commit_action()
