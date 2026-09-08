class_name BTConditionDynamic
extends BTNode
## Dynamic condition that compares blackboard values against species thresholds
##
## This allows behavior trees to be parameterized by species definitions.
## For example, one tree can be used for all prey animals, with each species
## having different "flee_threshold" or "danger_radius" values.

## Key in blackboard to compare (e.g., "health_percent", "target_distance")
var blackboard_key: String

## Comparison operator
var comparator: BTCondition.Comparator

## Key in SpeciesDefinition to compare against (e.g., "flee_threshold", "danger_radius")
var species_key: String


func tick(_delta: float) -> Status:
	if not blackboard:
		return Status.FAILURE

	# Get blackboard value
	var bb_value = blackboard.get_value(blackboard_key)
	if bb_value == null:
		return Status.FAILURE

	# Get species threshold
	var species = blackboard.get_value("species") as SpeciesDefinition
	if not species:
		push_error("BTConditionDynamic: No species found in blackboard")
		return Status.FAILURE

	if not species_key in species:
		push_error("BTConditionDynamic: Species missing property '%s'" % species_key)
		return Status.FAILURE

	var threshold = species.get(species_key)

	# Perform comparison
	var result: bool
	match comparator:
		BTCondition.Comparator.EQUALS:
			result = bb_value == threshold
		BTCondition.Comparator.NOT_EQUALS:
			result = bb_value != threshold
		BTCondition.Comparator.GREATER:
			result = bb_value > threshold
		BTCondition.Comparator.LESS:
			result = bb_value < threshold
		BTCondition.Comparator.EXISTS:
			result = blackboard.has_key(blackboard_key)
		BTCondition.Comparator.NOT_EXISTS:
			result = not blackboard.has_key(blackboard_key)
		_:
			result = false

	return Status.SUCCESS if result else Status.FAILURE
