class_name BTConditionCompareBB
extends BTNode
## Condition that compares two blackboard values
##
## Useful for comparisons like "enemies_nearby > allies_nearby"

var key1: String
var comparator: BTCondition.Comparator
var key2: String


func tick(_delta: float) -> Status:
	if not blackboard:
		return Status.FAILURE

	var value1 = blackboard.get_value(key1)
	var value2 = blackboard.get_value(key2)

	if value1 == null or value2 == null:
		return Status.FAILURE

	var result: bool
	match comparator:
		BTCondition.Comparator.EQUALS:
			result = value1 == value2
		BTCondition.Comparator.NOT_EQUALS:
			result = value1 != value2
		BTCondition.Comparator.GREATER:
			result = value1 > value2
		BTCondition.Comparator.LESS:
			result = value1 < value2
		_:
			result = false

	return Status.SUCCESS if result else Status.FAILURE
