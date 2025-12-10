@tool
extends EditorPlugin

const RAY_LENGTH = 1000
const VECTOR_INF = Vector3(INF, INF, INF)

@onready var undo_redo = get_undo_redo()

var selection = get_editor_interface().get_selection()
var selected : Node3D = null
var origin = Vector3()
var origin_2d = null

func _enter_tree():
	selection.connect("selection_changed", _on_selection_changed)

func _handles(object):
	return object is Node3D

func _forward_3d_draw_over_viewport(overlay):
	if origin_2d != null:
		overlay.draw_circle(origin_2d, 4, Color.YELLOW)

var first_point : Vector3
var second_point : Vector3
var first_point_set : bool = false
var prompt_printed : bool = false
var first_object : Node3D = null
var second_object : Node3D = null

func _forward_3d_gui_input(camera, event):
	if selected == null or not event is InputEventMouse:
		return false

	if Input.is_key_pressed(KEY_V):
		if not prompt_printed:
			if not first_point_set:
				print("Holding V: Place the FIRST point")
			else:
				print("Holding V: Place the SECOND point")
			prompt_printed = true

		var from = camera.project_ray_origin(event.position)
		var direction = camera.project_ray_normal(event.position)

		# Find closest vertex
		var meshes = find_meshes(selected)
		origin = find_closest_point(meshes, from, direction)

		if origin != VECTOR_INF:
			origin_2d = camera.unproject_position(origin)
		else:
			origin_2d = null

		# Detect left click
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if not first_point_set:
				first_point = origin
				first_object = selected
				first_point_set = true
				print("First point selected:", first_point)
			else:
				second_point = origin
				second_object = selected
				print("Second point selected:", second_point)
				var vector_between = second_point - first_point
				print("Vector from first to second point:", vector_between)

				# Move first object so first_point aligns with second_point
				if first_object != null:
					first_object.global_translate(vector_between)
					print("Moved first object by vector:", vector_between)

				# Reset for next operation
				first_point_set = false
				first_point = Vector3()
				second_point = Vector3()
				first_object = null
				second_object = null
#blah
		update_overlays()
		return true
	else:
		origin = VECTOR_INF
		origin_2d = null
		prompt_printed = false
		update_overlays()
		return false




func _on_selection_changed():
	var nodes = selection.get_selected_nodes()
	if nodes.size() > 0 and nodes[0] is Node3D:
		selected = nodes[0]
	else:
		selected = null
		origin = VECTOR_INF

func find_meshes(node : Node3D) -> Array:
	var meshes : Array = []
	if node is MeshInstance3D or node is CSGShape3D:
		meshes.append(node)
	for child in node.get_children():
		if child is Node3D:
			meshes += find_meshes(child)
	return meshes

func find_closest_point(meshes : Array, from : Vector3, direction : Vector3) -> Vector3:
	var closest := VECTOR_INF
	var closest_distance := INF
	var segment_start := from
	var segment_end := from + direction

	for mesh in meshes:
		var vertices = PackedVector3Array()
		if mesh is MeshInstance3D:
			vertices = mesh.get_mesh().get_faces()
		elif mesh is CSGShape3D:
			if mesh.is_root_shape():
				vertices = mesh.get_meshes()[1].get_faces()
			else:
				vertices.append(Vector3.ZERO)

		for i in range(vertices.size()):
			var current_point: Vector3 = mesh.global_transform * vertices[i]
			var current_on_ray := Geometry3D.get_closest_point_to_segment_uncapped(
				current_point, segment_start, segment_end)
			var current_distance := current_on_ray.distance_to(current_point)
			if closest == VECTOR_INF or current_distance < closest_distance:
				closest = current_point
				closest_distance = current_distance

	return closest
