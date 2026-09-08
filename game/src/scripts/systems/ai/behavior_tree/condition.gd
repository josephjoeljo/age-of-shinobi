class_name BTCondition
extends BTNode

var key: String
var comparator: Comparator
var value: Variant

enum Comparator { EQUALS, NOT_EQUALS, GREATER, GREATER_OR_EQUAL, LESS, LESS_OR_EQUAL, EXISTS, NOT_EXISTS }


func tick(_delta: float) -> Status:
	var bb_value = blackboard.get_value(key)
	
	var result: bool
	match comparator:
		Comparator.EQUALS:
			result = bb_value == value
		Comparator.NOT_EQUALS:
			result = bb_value != value
		Comparator.GREATER:
			result = bb_value > value
		Comparator.GREATER_OR_EQUAL:
			result = bb_value >= value
		Comparator.LESS:
			result = bb_value < value
		Comparator.LESS_OR_EQUAL:
			result = bb_value <= value
		Comparator.EXISTS:
			result = blackboard.has_key(key)
		Comparator.NOT_EXISTS:
			result = not blackboard.has_key(key)
	
	return Status.SUCCESS if result else Status.FAILURE
