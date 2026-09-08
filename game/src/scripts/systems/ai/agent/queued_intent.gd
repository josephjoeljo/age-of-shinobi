class_name QueuedIntent
extends RefCounted
## Wrapper for ActionIntent with scheduling information
##
## Used by ReactionQueue to manage pending actions with delays and priorities.

## The action to execute
var intent: ActionIntent

## Game time when this should execute (based on reaction delay)
var execute_at: float

## Game time when this action will complete
var complete_at: float

## Priority level (higher can interrupt lower)
var priority: int

## Can this action be interrupted by higher priority actions?
var interruptible: bool = true
