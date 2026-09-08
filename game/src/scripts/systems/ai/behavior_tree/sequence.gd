class_name BTSequence
extends BTNode
## Runs each child in order until one fails

var children: Array[BTNode] = []
var _current_index: int = 0


func tick(delta: float) -> Status:
	while _current_index < children.size():
		var child = children[_current_index]
		child.blackboard = blackboard
		var status = child.tick(delta)
		
		if status == Status.RUNNING:
			return Status.RUNNING
		
		if status == Status.FAILURE:
			_current_index = 0
			return Status.FAILURE
		
		_current_index += 1
	
	_current_index = 0
	return Status.SUCCESS
