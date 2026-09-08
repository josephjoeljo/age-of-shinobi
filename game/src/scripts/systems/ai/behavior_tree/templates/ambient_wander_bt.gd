class_name AmbientWanderBT
extends BehaviorTree
## Behavior tree for ambient creatures (birds, butterflies, fish)
##
## Very simple behavior: flee from everything or just wander
## Minimal AI cost for background atmosphere

func _init() -> void:
	root = BTSelector.new()

	# 1. FLEE from any threat
	var flee_seq = BTSequence.new()
	flee_seq.children = [
		_condition("target", BTCondition.Comparator.EXISTS, null),
		_action(ActionIntent.ActionType.FLEE, ActionIntent.PRIORITY_FLEE)
	]

	# 2. DEFAULT wander
	var wander = _action(ActionIntent.ActionType.WANDER, ActionIntent.PRIORITY_WANDER)

	# Simple two-branch tree
	root.children = [flee_seq, wander]
