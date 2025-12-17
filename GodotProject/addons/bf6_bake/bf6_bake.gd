# file: portal_tools_hook.gd
@tool
extends EditorPlugin

func _enter_tree():
	# Delay hooking to ensure the other plugin has added its dock
	call_deferred("_hook_portal_tools_button")

func _hook_portal_tools_button():
	var root = get_editor_interface().get_base_control()
	var export_button = _find_export_button(root)
	
	if export_button:
		if not export_button.pressed.is_connected(_on_export_button_pressed):
			export_button.pressed.connect(_on_export_button_pressed)
			print("[BF6-Baker] Hooked PortalTools export button.")
	else:
		# Button not found yet; try again next frame
		call_deferred("_hook_portal_tools_button")

func _find_export_button(node: Node) -> Button:
	# Recursive search for the ExportLevel button
	if node is Button and node.name == "ExportLevel_Button":
		return node
	for child in node.get_children():
		if child is Node:
			var found = _find_export_button(child)
			if found:
				return found
	return null

func _on_export_button_pressed():
	const bf6_baker_text: String = "[color=medium_turquoise][b][BF6-Baker]:[/b][/color]"

	var doors_by_phase := {}  # phase name → array of ObjIds

	# Collect all movable doors grouped by phase
	for door in get_tree().get_nodes_in_group("all-doors"):
		if not door.is_movable:
			continue

		var phase_group := ""
		for g in door.get_groups():
			if g.begins_with("phase_"):
				phase_group = g
				break
		if phase_group == "":
			continue

		var phase_name := phase_group.replace("phase_", "")

		if not doors_by_phase.has(phase_name):
			doors_by_phase[phase_name] = []
		doors_by_phase[phase_name].append(door.ObjId)

	# Sort ObjIds in each phase
	for phase_name in doors_by_phase.keys():
		doors_by_phase[phase_name].sort()

	# Sort phase names alphabetically
	var sorted_phases = doors_by_phase.keys()
	sorted_phases.sort()
	
	if sorted_phases.is_empty():
		print_rich(bf6_baker_text + " No Moving Elements Found.")
	else:
		print_rich(bf6_baker_text + " Exporting Phase IDs:")
	# Print constants
	for phase_name in sorted_phases:
		var const_name : String = "MAZE_PHASE_%s_WALL_IDS" % phase_name
		var ids_array : Array = doors_by_phase[phase_name]

		# Convert numbers to strings
		var ids_str_array : Array = []
		for id in ids_array:
			ids_str_array.append(str(id))

		# Join using a String instance
		var ids_str : String = ",".join(ids_str_array)

		print("const %s : number[] = [%s];" % [const_name, ids_str])
