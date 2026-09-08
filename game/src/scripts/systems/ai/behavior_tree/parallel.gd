class_name BTParallel
extends BTNode
## Runs all children simultaneously
##
## Different policies for when to succeed/fail based on children results

enum Policy {
	REQUIRE_ALL,    ## All children must succeed
	REQUIRE_ONE,    ## At least one child must succeed
}

var children: Array[BTNode] = []
var success_policy: Policy = Policy.REQUIRE_ALL
var failure_policy: Policy = Policy.REQUIRE_ONE


func tick(delta: float) -> Status:
	if children.is_empty():
		return Status.FAILURE

	var success_count := 0
	var failure_count := 0
	var running_count := 0

	# Execute all children
	for child in children:
		child.blackboard = blackboard
		var status = child.tick(delta)

		match status:
			Status.SUCCESS:
				success_count += 1
			Status.FAILURE:
				failure_count += 1
			Status.RUNNING:
				running_count += 1

	# Check failure policy
	match failure_policy:
		Policy.REQUIRE_ONE:
			if failure_count >= 1:
				return Status.FAILURE
		Policy.REQUIRE_ALL:
			if failure_count >= children.size():
				return Status.FAILURE

	# Check success policy
	match success_policy:
		Policy.REQUIRE_ALL:
			if success_count >= children.size():
				return Status.SUCCESS
		Policy.REQUIRE_ONE:
			if success_count >= 1:
				return Status.SUCCESS

	# Still running
	return Status.RUNNING
