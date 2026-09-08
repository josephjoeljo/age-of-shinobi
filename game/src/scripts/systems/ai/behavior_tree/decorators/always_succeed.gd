class_name BTAlwaysSucceed
extends BTNode
## Always returns SUCCESS regardless of child result
##
## Useful for actions that shouldn't fail the parent sequence

var child: BTNode


func tick(delta: float) -> Status:
	if not child:
		return Status.SUCCESS

	child.blackboard = blackboard
	child.tick(delta)  # Execute child but ignore result

	return Status.SUCCESS
