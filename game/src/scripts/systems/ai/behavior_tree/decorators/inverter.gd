class_name BTInverter
extends BTNode
## Inverts the result of its child node
##
## SUCCESS becomes FAILURE, FAILURE becomes SUCCESS
## RUNNING stays RUNNING

var child: BTNode


func tick(delta: float) -> Status:
	if not child:
		return Status.FAILURE

	child.blackboard = blackboard
	var status = child.tick(delta)

	match status:
		Status.SUCCESS:
			return Status.FAILURE
		Status.FAILURE:
			return Status.SUCCESS
		Status.RUNNING:
			return Status.RUNNING
		_:
			return Status.FAILURE
