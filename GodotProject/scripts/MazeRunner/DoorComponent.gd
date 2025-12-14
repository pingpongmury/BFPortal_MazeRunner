@tool
#class_name FoundationPlanter_Long_01
class_name DoorComponent
extends Node3D


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
		update_material_color(value)

@export var is_movable: bool = false:
	set(value):
		is_movable = value
		phase = 1 if is_movable else 0
		calc_name()
		update_color_from_phase()
		notify_property_list_changed()


const PHASES := ["", "A", "B", "C", "D"] # add/remove phases as needed, leading phase is static phase
const PHASE_COLORS := [
	Color.WEB_GRAY,
	Color.DARK_RED,
	Color.NAVY_BLUE,
	Color.DARK_GREEN,
	Color.DARK_GOLDENROD
]
var phase: int = 1:
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
var height: int = 0:
	set(value):
		height = value
		calc_name()
		notify_property_list_changed()


const MOVEMENT_TYPES := ["Linear", "Rotational"]
var movement_type: int = 0:
	set(value):
		movement_type = value
		calc_name()
		notify_property_list_changed()


const LINEAR_DIRECTIONS 	:= ["Up", "Down", "Left", "Right"]
const ROTATIONAL_DIRECTIONS := ["CW", "CCW", "Up", "Down"]
var direction: int = 0:
	set(value):
		direction = value
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


var mesh: MeshInstance3D
var mat: Material


#------------------------------------------------------------------------
#---------------------------- Door Overrides ----------------------------
#------------------------------------------------------------------------
func _enter_tree() -> void:
	add_to_group(StringName("all-doors"), false)
	return


#------------------------------------------------------------------------
#---------------------------- Godot Overrides ---------------------------
#------------------------------------------------------------------------
func _exit_tree() -> void:
	remove_from_group(StringName("all-doors"))

func _ready() -> void:
	setup_mesh()
	update_color_from_phase()


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


func setup_mesh() -> void:
	# Find the MeshInstance3D
	mesh = $Mesh/Mesh
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


func update_material_color(value: Color) -> void:
	if mat != null:
		mat.albedo_color = value


func update_color_from_phase() -> void:
	if phase >= 1 and phase < PHASE_COLORS.size():
		color = PHASE_COLORS[phase]
	else:
		color = Color.WEB_GRAY
