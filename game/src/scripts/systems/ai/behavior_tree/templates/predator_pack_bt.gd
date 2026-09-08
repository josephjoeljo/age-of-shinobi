class_name PredatorPackBT
extends BehaviorTree
## Behavior tree for pack-hunting predators (wolves, lions, raptors)
##
## Priority order:
## 1. Death check
## 2. Flee when badly hurt and outnumbered
## 3. Attack if target in range
## 4. Chase target
## 5. Rally response
## 6. Pack idle behavior
## 7. Wander

func _init() -> void:
	root = BTSelector.new()

	# 1. DEATH CHECK (highest priority)
	var death_seq = BTSequence.new()
	death_seq.children = [
		_condition("health_percent", BTCondition.Comparator.LESS, 0.01),
		_action(ActionIntent.ActionType.DIE, ActionIntent.PRIORITY_DEATH)
	]

	# 2. FLEE when badly hurt AND outnumbered
	var flee_seq = BTSequence.new()
	flee_seq.children = [
		_condition_dynamic("health_percent", BTCondition.Comparator.LESS, "flee_health_threshold"),
		_condition_compare_bb("enemies_nearby", BTCondition.Comparator.GREATER, "allies_nearby"),
		_action(ActionIntent.ActionType.FLEE, ActionIntent.PRIORITY_FLEE)
	]

	# 3. ATTACK if target in range
	var attack_seq = BTSequence.new()
	attack_seq.children = [
		_condition("target", BTCondition.Comparator.EXISTS, null),
		_condition_dynamic("target_distance", BTCondition.Comparator.LESS, "attack_range"),
		_action(ActionIntent.ActionType.ATTACK, ActionIntent.PRIORITY_ATTACK)
	]

	# 4. CHASE target
	var chase_seq = BTSequence.new()
	chase_seq.children = [
		_condition("target", BTCondition.Comparator.EXISTS, null),
		_condition_dynamic("target_distance", BTCondition.Comparator.LESS, "chase_range"),
		_chase_action()
	]

	# 5. RALLY response (join pack in combat)
	var rally_seq = BTSequence.new()
	rally_seq.children = [
		_condition("herd_rally_active", BTCondition.Comparator.EQUALS, true),
		_move_to_rally_action()
	]

	# 6. PACK idle behavior (follow herd)
	var pack_seq = BTSequence.new()
	pack_seq.children = [
		_condition("herd", BTCondition.Comparator.EXISTS, null),
		_follow_herd_action()
	]

	# 7. DEFAULT wander
	var wander = _action(ActionIntent.ActionType.WANDER, ActionIntent.PRIORITY_WANDER)

	# Assemble tree
	root.children = [
		death_seq,
		flee_seq,
		attack_seq,
		chase_seq,
		rally_seq,
		pack_seq,
		wander
	]


## Condition that compares two blackboard values
func _condition_compare_bb(key1: String, comp: BTCondition.Comparator, key2: String) -> BTNode:
	# Custom condition that compares two blackboard keys
	var cond = BTConditionCompareBB.new()
	cond.key1 = key1
	cond.comparator = comp
	cond.key2 = key2
	return cond


## Chase action - move toward target
func _chase_action() -> BTNode:
	var chase = BTAction.new()
	chase.action_type = ActionIntent.ActionType.CHASE
	chase.priority = ActionIntent.PRIORITY_CHASE
	return chase


## Move to rally point action
func _move_to_rally_action() -> BTNode:
	var rally = BTAction.new()
	rally.action_type = ActionIntent.ActionType.RALLY
	rally.priority = ActionIntent.PRIORITY_ATTACK
	return rally


## Follow herd movement action
func _follow_herd_action() -> BTNode:
	var follow = BTAction.new()
	follow.action_type = ActionIntent.ActionType.MOVE
	follow.priority = ActionIntent.PRIORITY_WANDER
	return follow
