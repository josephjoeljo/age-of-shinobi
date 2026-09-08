class_name ActionIntent
extends RefCounted
## Represents a desired action from the AI decision system
##
## Behavior trees output ActionIntents which are queued in the ReactionQueue.
## The queue processes intents by priority, allowing higher-priority actions
## (like fleeing) to interrupt lower-priority ones (like wandering).

enum ActionType {
	IDLE,        ## Standing still, doing nothing
	WANDER,      ## Random movement within territory
	MOVE,        ## Deliberate movement toward a destination
	CHASE,       ## Pursuing a target
	FLEE,        ## Running away from a threat
	ATTACK,      ## Engaging in combat
	GRAZE,       ## Feeding/eating animation
	GATHER,      ## Collecting resources
	INTERACT,    ## Using an object or talking to NPC
	COWER,       ## Fear response (non-fleeing)
	RALLY,       ## Call for backup / join combat
	DIE,         ## Death animation/state
}

## Priority constants - higher values override lower ones
const PRIORITY_DEATH := 1000      ## Death state (highest)
const PRIORITY_FLEE := 800        ## Panic/escape response
const PRIORITY_ATTACK := 600      ## Combat actions
const PRIORITY_CHASE := 500       ## Pursuing targets
const PRIORITY_INTERACT := 400    ## Player interaction, using objects
const PRIORITY_WANDER := 200      ## Normal movement
const PRIORITY_IDLE := 100        ## Lowest priority

## The type of action to perform
var action: ActionType = ActionType.IDLE

## Priority level - higher values can interrupt lower ones
var priority: int = PRIORITY_IDLE

## Expected duration of the action in seconds
var duration: float = 0.5

## Target entity (for ATTACK, CHASE, INTERACT, etc.)
var target: Node2D = null

## Movement direction (for MOVE, FLEE)
var direction: Vector2 = Vector2.ZERO

## Movement destination (for MOVE to specific location)
var destination: Vector2 = Vector2.ZERO

## Movement speed multiplier (1.0 = normal, 2.0 = sprint during panic)
var speed_multiplier: float = 1.0

## Additional parameters (e.g., animation name, interaction type)
var parameters: Dictionary = {}

## Can this action be interrupted by higher priority actions?
var interruptible: bool = true

## Callback to execute when action completes (called by ReactionQueue)
var on_completion: Callable = Callable()


## Quick constructor for simple actions
static func create(action_type: ActionType, action_priority: int = PRIORITY_IDLE) -> ActionIntent:
	var intent = ActionIntent.new()
	intent.action = action_type
	intent.priority = action_priority
	return intent


## Constructor for movement actions
static func create_move(dir: Vector2, action_priority: int = PRIORITY_WANDER) -> ActionIntent:
	var intent = ActionIntent.new()
	intent.action = ActionType.MOVE
	intent.direction = dir.normalized()
	intent.priority = action_priority
	return intent


## Constructor for target-based actions
static func create_targeted(action_type: ActionType, target_entity: Node2D, action_priority: int) -> ActionIntent:
	var intent = ActionIntent.new()
	intent.action = action_type
	intent.target = target_entity
	intent.priority = action_priority
	return intent


## Check if this intent should override another based on priority
func should_override(other: ActionIntent) -> bool:
	return priority > other.priority
