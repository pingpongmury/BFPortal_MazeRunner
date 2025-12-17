@tool
#class_name FoundationPlanter_Long_01
class_name DoorComponent
extends Door

@export var ObjId: int = -1
@export var id = ""
# SDK native objects use:
#		var global_name = self.get_script().get_global_name()
# to get the script class_name and validate whether the object belongs in the level.
# Instead, we spoof the global_name so LevelValidator thinks it's being called from a FoundationPlanter_Long_01:
var global_name = StringName("FoundationPlanter_Long_01") # <-- Construct a StringName using the SDK class_name


func _get_configuration_warnings() -> PackedStringArray:
	var scene_root = get_tree().edited_scene_root
	if get_node(".") == scene_root:
		return []
	if not LevelValidator.is_type_in_level(global_name, scene_root):
		var levels = LevelValidator.get_level_restrictions(global_name)
		var levels_str = "\n  - ".join(levels) if levels.size() > 0 else "Any"
		var msg = "%s is not usable in %s\nValid levels include:\n  - %s" % [global_name, scene_root.name, levels_str]
		return [msg]
	return []


func _validate_property(property: Dictionary):
	if property.name == "id":
		property.usage = PROPERTY_USAGE_NO_EDITOR 


# ------------------------------------  Begin Custom Code ------------------------------------


#------------------------------------------------------------------------
#-------------------------- DoorComponent Vars --------------------------
#------------------------------------------------------------------------
@export var color: Color = Color.WEB_GRAY:
	set(value):
		color = value
		update_material_color()

@export var is_movable: bool = false:
	set(value):
		is_movable = value
		phase = 1 if is_movable else 0
		update_decal()
		update_color_from_phase()
		calc_name()
		notify_property_list_changed()


const PHASES := ["", "A", "B", "C", "D"] # add/remove phases as needed, leading phase is static phase
const PHASE_COLORS := [
	Color.WEB_GRAY,
	Color.DARK_RED,
	Color.NAVY_BLUE,
	Color.DARK_GREEN,
	Color.DARK_GOLDENROD
]
var phase: int = 0:
	set(value):
		if phase >= 0 and phase < PHASES.size():
			if is_in_group("phase_%s" % PHASES[phase]):
				remove_from_group("phase_%s" % PHASES[phase])
		if value >= 0 and value < PHASES.size():
			add_to_group("phase_%s" % PHASES[value])
		phase = value
		calc_name()
		update_color_from_phase()
		notify_property_list_changed()
	


const HEIGHTS := ["Full", "Half"]
var height: int = 1:
	set(value):
		height = value
		calc_name()
		notify_property_list_changed()


const MOVEMENT_TYPES := ["Linear", "Rotational"]
var movement_type: int = 0:
	set(value):
		movement_type = value
		calc_name()
		call_deferred("update_decal")
		notify_property_list_changed()


const LINEAR_DIRECTIONS 	:= ["Up", "Down", "Left", "Right"]
const ROTATIONAL_DIRECTIONS := ["CW", "CCW", "Up", "Down"]
var direction: int = 0:
	set(value):
		direction = value
		call_deferred("update_decal")
		calc_name()
		notify_property_list_changed()


func _get_property_list() -> Array:
	var props: Array = []
	
	if is_movable:
		props.append({
			"name": "phase",
			"type": TYPE_INT,
			"hint": PROPERTY_HINT_ENUM,
			"hint_string": enum_to_hint_string(PHASES)
		})
		
		props.append({
			"name": "height",
			"type": TYPE_INT,
			"hint": PROPERTY_HINT_ENUM,
			"hint_string": enum_to_hint_string(HEIGHTS)
		})
		
		props.append({
			"name": "movement_type",
			"type": TYPE_INT,
			"hint": PROPERTY_HINT_ENUM,
			"hint_string": enum_to_hint_string(MOVEMENT_TYPES)
		})

		if movement_type == 0: # Linear
			props.append({
				"name": "direction",
				"type": TYPE_INT,
				"hint": PROPERTY_HINT_ENUM,
				"hint_string": enum_to_hint_string(LINEAR_DIRECTIONS)
			})
		else: # Rotational
			props.append({
				"name": "direction",
				"type": TYPE_INT,
				"hint": PROPERTY_HINT_ENUM,
				"hint_string": enum_to_hint_string(ROTATIONAL_DIRECTIONS)
			})

	return props


#------------------------------------------------------------------------
#---------------------------- Godot Overrides ---------------------------
#------------------------------------------------------------------------
func _enter_tree() -> void:
	if not Engine.is_editor_hint():
		return
	add_to_group(StringName("all-doors"), false)
	return


func _exit_tree() -> void:
	remove_from_group(StringName("all-doors"))


func _ready() -> void:
	setup_mesh()
	update_color_from_phase()
	update_material_color()
	setup_decal()
	update_decal()
	calc_name()


#------------------------------------------------------------------------
#-------------------------- DoorComponent Funcs -------------------------
#------------------------------------------------------------------------
func compute_base_obj_id() -> int:
	if not is_movable:
		return -1
	return (
		1000000 * phase +
		100000  * height +
		10000   * movement_type +
		1000    * direction +
		1
	)


func calc_name() -> void:
	var nameStr: String = ""
	if !is_movable:
		nameStr += "Static_"
	else:
		nameStr += "Door_"
		nameStr += PHASES[phase] + "_" if phase >= 0 and phase < PHASES.size() else "UNK_"
		nameStr += HEIGHTS[height] + "_" if height >= 0 and height < HEIGHTS.size() else "UNK_"
		nameStr += MOVEMENT_TYPES[movement_type] + "_" if movement_type >= 0 and movement_type < MOVEMENT_TYPES.size() else "UNK_"
		if movement_type: #Linear
			nameStr += LINEAR_DIRECTIONS[direction] + "_" if direction >= 0 and direction < LINEAR_DIRECTIONS.size() else "UNK_"
		else:
			nameStr += ROTATIONAL_DIRECTIONS[direction] + "_" if direction >= 0 and direction < ROTATIONAL_DIRECTIONS.size() else "UNK_"
	self.name = nameStr


func enum_to_hint_string(arr: Array) -> String:
	var parts := []
	for i in arr.size():
		if arr[i] != "":
			parts.append("%s:%d" % [arr[i], i])
	return ",".join(parts)


var mesh: MeshInstance3D
var mat: Material
var is_mesh_setup: bool = false
func setup_mesh() -> void:
	# Find the MeshInstance3D
	mesh = get_node_or_null("Mesh/Mesh")
	if mesh == null:
		return
	# Hide any collision mesh
	for c in mesh.get_children():
		c.visible = false
	# Duplicate material so original is preserved
	mat = mesh.get_active_material(0)
	if mat != null:
		mat = mat.duplicate()
		mesh.set_surface_override_material(0, mat)
	is_mesh_setup = true
	#print("mesh setup")


func update_material_color() -> void:
	if !is_mesh_setup:
		setup_mesh()
	if mat != null:
		mat.albedo_color = color


func update_color_from_phase() -> void:
	if phase >= 1 and phase < PHASE_COLORS.size():
		color = PHASE_COLORS[phase]
	else:
		color = Color.WEB_GRAY
	update_material_color()


var arrow_front: Decal
var arrow_back: Decal
func setup_decal() -> void:
	arrow_front = get_node_or_null("ArrowDecal_Front")	#+Z side
	arrow_back = get_node_or_null("ArrowDecal_Back") 	#-Z side
	return



func update_decal() -> void:
	if !arrow_front or !arrow_back or !arrow_front.is_inside_tree() or !arrow_back.is_inside_tree():
		return
		
	if !is_movable: #don't show the arrows if the DoorComponent isn't movable
		arrow_front.visible = false
		arrow_back.visible = false
		return
	else:
		arrow_front.visible = true
		arrow_back.visible = true
	var curr_front_rot = arrow_front.global_rotation_degrees
	var curr_back_rot = arrow_back.global_rotation_degrees

	#pick which decal to use (linear indicating or rotation indicating, direction)
	var tex_path: String = "res://objects/MazeRunner/"
	var front_path: String
	var back_path: String
	if movement_type == 0:		#Linear
		tex_path += "arrow_"
		if is_up_aligned():
			front_path = tex_path + LINEAR_DIRECTIONS[direction]
			back_path = tex_path + LINEAR_DIRECTIONS[direction]
		else:
			front_path = tex_path + get_flipped_dir()
			back_path = tex_path + get_flipped_dir()
	else:
		tex_path += "rot_arrow_"
		if is_up_aligned():
			front_path = tex_path + ROTATIONAL_DIRECTIONS[direction]
			back_path = tex_path + get_flipped_dir()
		else:
			front_path = tex_path + get_flipped_dir()	
			back_path = tex_path + ROTATIONAL_DIRECTIONS[direction]
	
	#set tecal texture according to movement type
	arrow_front.texture_albedo = load(front_path + ".png")
	arrow_back.texture_albedo = load(back_path + ".png")


func is_up_aligned() -> bool:
	var local_up = self.transform.basis.y.normalized()
	var world_up = Vector3.UP
	var dot = local_up.dot(world_up)
	
	# Convert tolerance to cosine value for dot product comparison
	var tolerance_radians = deg_to_rad(5)
	return dot >= cos(tolerance_radians)


func get_flipped_dir() -> String:
	if movement_type == 0:#linear
		match direction:
				0: return LINEAR_DIRECTIONS[direction + 1] #CW   ->   CCW
				1: return LINEAR_DIRECTIONS[direction - 1] #CCW  ->   CWs
				2: return LINEAR_DIRECTIONS[direction + 1] #Up   ->   Down
				3: return LINEAR_DIRECTIONS[direction - 1] #Down ->   Up
	else:#rotational
		match direction:
				0: return ROTATIONAL_DIRECTIONS[direction + 1] #CW   ->   CCW
				1: return ROTATIONAL_DIRECTIONS[direction - 1] #CCW  ->   CW
				2: return ROTATIONAL_DIRECTIONS[direction + 1] #Up   ->   Down
				3: return ROTATIONAL_DIRECTIONS[direction - 1] #Down ->   Up
	print("shit done broke")
	return "" #something's broken
