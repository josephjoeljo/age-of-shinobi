class_name Blackboard
extends RefCounted
## Shared data storage for behavior tree nodes
##
## The blackboard stores runtime state that BT nodes can read and write to.
## It's passed down from parent to child nodes during tree evaluation.
## Common uses include storing current targets, health state, species parameters,
## and environmental awareness.

var _data: Dictionary = {}


## Retrieves a value from the blackboard
## Returns null if the key doesn't exist and no default is provided
func get_value(key: String, default_value: Variant = null) -> Variant:
	if _data.has(key):
		return _data[key]
	return default_value


## Stores or updates a value in the blackboard
func set_value(key: String, value: Variant) -> void:
	_data[key] = value


## Checks if a key exists in the blackboard
func has_key(key: String) -> bool:
	return _data.has(key)


## Removes a key from the blackboard
func erase(key: String) -> void:
	_data.erase(key)


## Clears all data from the blackboard
func clear() -> void:
	_data.clear()


## Returns all keys currently in the blackboard (useful for debugging)
func get_keys() -> Array:
	return _data.keys()
