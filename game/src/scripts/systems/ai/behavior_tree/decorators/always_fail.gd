class_name BTAlwaysFail
extends BTNode
## Always returns FAILURE regardless of child result
##
## Useful for fallback branches in selectors

var child: BTNode


func tick(delta: float) -> Status:
	if not child:
		return Status.FAILURE

	child.blackboard = blackboard
	child.tick(delta)  # Execute child but ignore result

	return Status.FAILURE
