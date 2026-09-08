class_name PreyHerdBT
extends BehaviorTree
## Behavior tree for prey herd animals (boars, deer, rabbits)
##
## Priority order:
## 1. Death check
## 2. Panic flee (high threat)
## 3. Cautious flee (moderate threat)
## 4. Alert herd (spot threat, warn others)
## 5. Follow fleeing herd
## 6. Graze (if safe and daytime)
## 7. Stay with herd
## 8. Wander

func _init() -> void:
	root = BTSelector.new()

	# 1. DEATH CHECK (highest priority)
	var death_seq = BTSequence.new()
	death_seq.children.assign( [
		_condition("health_percent", BTCondition.Comparator.LESS, 0.01),
		_action(ActionIntent.ActionType.DIE, ActionIntent.PRIORITY_DEATH)
	])

	# 2. PANIC FLEE (extreme threat)
	var panic_seq = BTSequence.new()
	panic_seq.children.assign([
		_condition("target", BTCondition.Comparator.EXISTS, null),
		_condition_dynamic("target_distance", BTCondition.Comparator.LESS, "danger_radius"),
		_action(ActionIntent.ActionType.FLEE, ActionIntent.PRIORITY_FLEE)
	])

	# 3. CAUTIOUS FLEE (threat detected)
	var flee_seq = BTSequence.new()
	flee_seq.children.assign([
		_condition("target", BTCondition.Comparator.EXISTS, null),
		_action(ActionIntent.ActionType.FLEE, ActionIntent.PRIORITY_FLEE)
	])

	# 4. ALERT HERD (spotted threat, not yet fleeing)
	var alert_seq = BTSequence.new()
	alert_seq.children.assign([
		_condition("target", BTCondition.Comparator.EXISTS, null),
		_condition("herd_alerted", BTCondition.Comparator.NOT_EQUALS, true),
		_alert_herd_action()
	])

	# 5. FOLLOW FLEEING HERD
	var follow_flee_seq = BTSequence.new()
	follow_flee_seq.children.assign([
		_condition("herd", BTCondition.Comparator.EXISTS, null),
		_condition("herd_fleeing", BTCondition.Comparator.EQUALS, true),
		_match_herd_velocity_action()
	])

	# 6. GRAZE (safe and daytime and not on cooldown)
	var graze_seq = BTSequence.new()
	graze_seq.children.assign([
		_condition("target", BTCondition.Comparator.NOT_EXISTS, null),  # No threats
		_condition("is_daytime", BTCondition.Comparator.EQUALS, true),
		_condition("graze_cooldown", BTCondition.Comparator.LESS_OR_EQUAL, 0.0),  # Cooldown expired
		_graze_action()
	])

	# 7. STAY WITH HERD
	var herd_seq = BTSequence.new()
	herd_seq.children.assign([
		_condition("herd", BTCondition.Comparator.EXISTS, null),
		_follow_herd_action()
	])

	# 8. DEFAULT wander
	var wander = _action(ActionIntent.ActionType.WANDER, ActionIntent.PRIORITY_WANDER, 2)

	# Assemble tree
	root.children.assign([
		death_seq,
		panic_seq,
		flee_seq,
		alert_seq,
		follow_flee_seq,
		graze_seq,
		herd_seq,
		wander
	])


## Alert the herd of danger
func _alert_herd_action() -> BTNode:
	var alert = BTAction.new()
	alert.action_type = ActionIntent.ActionType.INTERACT  # Using INTERACT for herd alert
	alert.priority = ActionIntent.PRIORITY_WANDER
	return alert


## Match herd velocity (flee together)
func _match_herd_velocity_action() -> BTNode:
	var match_vel = BTAction.new()
	match_vel.action_type = ActionIntent.ActionType.FLEE
	match_vel.priority = ActionIntent.PRIORITY_FLEE
	return match_vel


## Graze animation with cooldown
func _graze_action() -> BTNode:
	var graze = BTAction.new()
	graze.action_type = ActionIntent.ActionType.GRAZE
	graze.priority = ActionIntent.PRIORITY_IDLE
	graze.duration = 15.0  # Increased for longer grazing

	# Set cooldown when graze completes
	graze.on_completion = func():
		var agent = blackboard.get_value("owner") as AIAgent
		if agent:
			# 45 seconds total: 15s graze + 30s wander before next graze
			agent.blackboard.set_value("graze_cooldown", 15.0)

	return graze


## Follow herd movement
func _follow_herd_action() -> BTNode:
	var follow = BTAction.new()
	follow.action_type = ActionIntent.ActionType.MOVE
	follow.priority = ActionIntent.PRIORITY_WANDER
	return follow
