class_name BTNode
extends RefCounted
## Generic Behavior Tree Node
##
## This base class will be extended to create many new node types
## Returns the current state of the node

enum Status { SUCCESS, FAILURE, RUNNING }

var blackboard: Blackboard


func tick(_delta: float) -> Status:
	return Status.FAILURE  # Override in subclasses
