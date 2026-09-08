class_name BTCooldown
extends BTNode
## Rate-limits child execution with a cooldown timer
##
## Returns FAILURE if on cooldown, otherwise executes child

var child: BTNode
var cooldown_duration: float = 1.0
var _last_execution_time: float = -999.0


func tick(delta: float) -> Status:
	if not child:
		return Status.FAILURE

	var current_time = Time.get_ticks_msec() / 1000.0

	# Check if still on cooldown
	if current_time - _last_execution_time < cooldown_duration:
		return Status.FAILURE

	# Execute child
	child.blackboard = blackboard
	var status = child.tick(delta)

	# Update cooldown timer on successful execution
	if status == Status.SUCCESS:
		_last_execution_time = current_time

	return status
