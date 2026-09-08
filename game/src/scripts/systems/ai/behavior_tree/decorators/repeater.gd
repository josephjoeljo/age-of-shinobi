class_name BTRepeater
extends BTNode
## Repeats its child node N times
##
## Returns RUNNING until all iterations complete, then returns child's final status

var child: BTNode
var repeat_count: int = 3
var _current_iteration: int = 0


func tick(delta: float) -> Status:
	if not child:
		return Status.FAILURE

	child.blackboard = blackboard

	while _current_iteration < repeat_count:
		var status = child.tick(delta)

		if status == Status.RUNNING:
			return Status.RUNNING

		_current_iteration += 1

	# All iterations complete
	_current_iteration = 0
	return Status.SUCCESS
