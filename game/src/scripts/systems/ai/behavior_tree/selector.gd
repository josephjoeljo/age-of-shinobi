class_name BTSelector
extends BTNode
## Tries each child in order until one succeeds

var children: Array[BTNode] = []


func tick(delta: float) -> Status:
	for child in children:
		child.blackboard = blackboard
		var status = child.tick(delta)
		
		if status != Status.FAILURE:
			return status
	
	return Status.FAILURE
