class_name BTAction
extends BTNode

var action_type: ActionIntent.ActionType
var priority: int = ActionIntent.PRIORITY_IDLE
var duration: float = 1.0  # Allow animations to complete

## Optional callback when action completes
var on_completion: Callable = Callable()


func tick(_delta: float) -> Status:
	var intent = ActionIntent.new()
	intent.action = action_type
	intent.priority = priority
	intent.duration = duration
	intent.on_completion = on_completion
	
	# Get parameters from blackboard
	match action_type:
		ActionIntent.ActionType.ATTACK:
			intent.target = blackboard.get_value("target")
			intent.priority = ActionIntent.PRIORITY_ATTACK
		
		ActionIntent.ActionType.FLEE:
			var threat_dir = blackboard.get_value("target_direction", Vector2.ZERO)
			intent.direction = -threat_dir  # Run away
			intent.priority = ActionIntent.PRIORITY_FLEE
		
		ActionIntent.ActionType.MOVE:
			intent.direction = blackboard.get_value("movement_direction", Vector2.ZERO)
			intent.priority = ActionIntent.PRIORITY_WANDER
	
	# Queue the intent
	var agent = blackboard.get_value("owner") as AIAgent
	if agent:
		agent.reaction_queue.queue_intent(intent)
	
	return Status.SUCCESS
