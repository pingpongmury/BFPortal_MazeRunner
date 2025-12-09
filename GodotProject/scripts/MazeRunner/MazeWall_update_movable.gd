@tool
extends Node

#Door Numbering Scheme:
#   {Phase}         {Height}         {Movement Type}                       {Direction}                 {doorIndex} {doorIndex}  {compIndex}
#{1:A,2:B,etc.}  {0:Full,1:Half}  {0:Linear,1:Rotational}  {0:UP/CW,1:DOWN/CCW,2:LEFT/Up,3:RIGHT/Down}    {0-9}       {0-9}        {1-9}
#Example:
#ObjId = 1103172 would correspond to a half-height door in phase A that moves linearly to the right and is the 17th of that type with components enumerated with compIndex (in this case component 2)

# Movable object has its own unique ObjId
@export var ObjId: int = -1

# Controls if object is movable
@export var movable: bool = false:
	set(value):
		movable = value
		_notify_grandparent_of_change()


# Internal storage for height (int)
var height: int = 0:
	set(value):
		height = value
		_notify_grandparent_of_change()


# Controls type of movement
var movement_type: int = 0:
	set(value):
		movement_type = value
		_notify_grandparent_of_change()


# Internal storage for direction (int)
var _direction: int = 0
func _get(property: StringName):
	if property == "direction":
		return _direction
func _set(property: StringName, value) -> bool:
	if property == "direction":
		_direction = value
		_notify_grandparent_of_change()
		return true
	return false


# Display movement type and direction options only if movable
func _get_property_list() -> Array:
	var props: Array = []
	
	props.append({
		"name": "height",
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": "Full,Half"
	})
	
	# Add normal movement_type dropdown
	if movable:
		props.append({
			"name": "movement_type",
			"type": TYPE_INT,
			"hint": PROPERTY_HINT_ENUM,
			"hint_string": "Linear,Rotational"
		})

		# Now add direction based on movement_type
		if movement_type == 0:
			props.append({
				"name": "direction",
				"type": TYPE_INT,
				"hint": PROPERTY_HINT_ENUM,
				"hint_string": "Up,Down,Left,Right"
			})
		else:
			props.append({
				"name": "direction",
				"type": TYPE_INT,
				"hint": PROPERTY_HINT_ENUM,
				"hint_string": "CW,CCW,Up,Down"
			})

	return props


func _notify_grandparent_of_change():
	if get_parent() != null:
		var grandparent = get_parent().get_parent()
		grandparent._refresh_wall_ids()
