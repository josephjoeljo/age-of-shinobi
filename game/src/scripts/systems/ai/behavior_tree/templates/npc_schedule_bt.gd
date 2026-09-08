class_name NPCScheduleBT
extends BehaviorTree
## Behavior tree for NPCs with schedules (merchants, guards, villagers)
##
## Priority order:
## 1. Death check
## 2. Threat response (fight or flee based on role)
## 3. Player interaction
## 4. Follow schedule
## 5. Idle at location

func _init() -> void:
	root = BTSelector.new()

	# 1. DEATH CHECK (highest priority)
	var death_seq = BTSequence.new()
	death_seq.children = [
		_condition("health_percent", BTCondition.Comparator.LESS, 0.01),
		_action(ActionIntent.ActionType.DIE, ActionIntent.PRIORITY_DEATH)
	]

	# 2. THREAT RESPONSE (depends on role)
	var threat_sel = BTSelector.new()

	# 2a. GUARD fights
	var guard_fight_seq = BTSequence.new()
	guard_fight_seq.children = [
		_condition("target", BTCondition.Comparator.EXISTS, null),
		_condition("role", BTCondition.Comparator.EQUALS, "GUARD"),
		_action(ActionIntent.ActionType.ATTACK, ActionIntent.PRIORITY_ATTACK)
	]

	# 2b. CIVILIAN flees
	var civilian_flee_seq = BTSequence.new()
	civilian_flee_seq.children = [
		_condition("target", BTCondition.Comparator.EXISTS, null),
		_action(ActionIntent.ActionType.FLEE, ActionIntent.PRIORITY_FLEE)
	]

	threat_sel.children = [guard_fight_seq, civilian_flee_seq]

	# 3. PLAYER INTERACTION
	var interact_seq = BTSequence.new()
	interact_seq.children = [
		_condition("player_nearby", BTCondition.Comparator.EQUALS, true),
		_condition("player_wants_interaction", BTCondition.Comparator.EQUALS, true),
		_interact_action()
	]

	# 4. FOLLOW SCHEDULE
	var schedule_sel = BTSelector.new()

	# 4a. TRAVEL to destination
	var travel_seq = BTSequence.new()
	travel_seq.children = [
		_condition("schedule_destination", BTCondition.Comparator.EXISTS, null),
		_condition("at_destination", BTCondition.Comparator.NOT_EQUALS, true),
		_move_to_destination_action()
	]

	# 4b. DO ACTIVITY at destination
	var activity_seq = BTSequence.new()
	activity_seq.children = [
		_condition("schedule_destination", BTCondition.Comparator.EXISTS, null),
		_condition("at_destination", BTCondition.Comparator.EQUALS, true),
		_do_schedule_activity_action()
	]

	schedule_sel.children = [travel_seq, activity_seq]

	# 5. DEFAULT idle
	var idle = _action(ActionIntent.ActionType.IDLE, ActionIntent.PRIORITY_IDLE)

	# Assemble tree
	root.children = [
		death_seq,
		threat_sel,
		interact_seq,
		schedule_sel,
		idle
	]


## Player interaction action
func _interact_action() -> BTNode:
	var interact = BTAction.new()
	interact.action_type = ActionIntent.ActionType.INTERACT
	interact.priority = ActionIntent.PRIORITY_INTERACT
	interact.duration = 2.0
	return interact


## Move to schedule destination
func _move_to_destination_action() -> BTNode:
	var move = BTAction.new()
	move.action_type = ActionIntent.ActionType.MOVE
	move.priority = ActionIntent.PRIORITY_WANDER
	return move


## Perform schedule activity (work animation, etc.)
func _do_schedule_activity_action() -> BTNode:
	var activity = BTAction.new()
	activity.action_type = ActionIntent.ActionType.GATHER  # Using GATHER for work activities
	activity.priority = ActionIntent.PRIORITY_IDLE
	activity.duration = 5.0
	return activity
