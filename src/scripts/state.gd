extends Node
class_name State

## State in a state machine
## Each state contains:
## - an animation dictionary which contains the 'direction': 'animation name'
## - a duration if there is an animation lock

var state_name: String
var animation: Dictionary
var duration: float

func _init(_name: String, _animation: Dictionary,  _duration: float=0):
	self.state_name = _name
	self.animation = _animation
	self.duration = _duration
	pass

func get_state_name() -> String:
	return self.state_name

func get_animation(direction: String) -> String:
	return self.animation[direction]
