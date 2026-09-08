class_name BehaviorTree
extends Node
## Base class for behavior tree instances
##
## Manages the root node and coordinates tree evaluation. Each AIAgent
## instantiates a BehaviorTree from a species template and ticks it at
## regular intervals based on tier configuration.

## Root node of the behavior tree
var root: BTNode

## Reference to agent's blackboard
var blackboard: Blackboard

## Is this tree enabled? (controlled by tier)
var enabled: bool = true

## Tick interval in seconds (randomized per agent)
var tick_interval: float = 0.2

## Internal tick timer
var _tick_timer: float = 0.0


func _ready() -> void:
	# Trees are built in _init() or by subclasses
	pass


func _process(delta: float) -> void:
	if not enabled:
		if blackboard:
			print("BT disabled for ", blackboard.get_value("owner"))
		return

	if not root:
		if blackboard:
			push_error("BT root is null for ", blackboard.get_value("owner"))
		return

	_tick_timer += delta
	if _tick_timer >= tick_interval:
		_tick_timer = 0.0
		#if blackboard:
			#print("BT ticking for ", blackboard.get_value("owner"))
		tick(delta)


## Evaluates the behavior tree
func tick(delta: float) -> BTNode.Status:
	if not root or not blackboard:
		return BTNode.Status.FAILURE

	# Pass blackboard down to root
	root.blackboard = blackboard

	# Evaluate the tree
	return root.tick(delta)


## Helper method to create a condition node
func _condition(key: String, comp: BTCondition.Comparator, val: Variant) -> BTCondition:
	var cond = BTCondition.new()
	cond.key = key
	cond.comparator = comp
	cond.value = val
	return cond


## Helper method to create a dynamic condition (compares against species)
func _condition_dynamic(bb_key: String, comp: BTCondition.Comparator, species_key: String) -> BTConditionDynamic:
	var cond = BTConditionDynamic.new()
	cond.blackboard_key = bb_key
	cond.comparator = comp
	cond.species_key = species_key
	return cond


## Helper method to create an action node
func _action(type: ActionIntent.ActionType, prio: int = ActionIntent.PRIORITY_IDLE, duration: float = 0.5) -> BTAction:
	var act = BTAction.new()
	act.action_type = type
	act.priority = prio
	act.duration = duration
	return act


## Helper method to create a selector node
func _selector(child_nodes: Array[BTNode]) -> BTSelector:
	var sel = BTSelector.new()
	sel.children = child_nodes
	return sel


## Helper method to create a sequence node
func _sequence(child_nodes: Array[BTNode]) -> BTSequence:
	var seq = BTSequence.new()
	seq.children = child_nodes
	return seq
