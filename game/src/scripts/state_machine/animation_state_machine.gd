extends Node
class_name AnimationStateMachine

## Animation State machine.
##
## Initializes states and handle animation transitions
## The states array must contain the idle state as the first state

var states: Dictionary # All of the states of this state machine
var idle_state: AnimationState # Fallback State
var active_state: AnimationState # Current State
var last_direction: String # Direction of last movement

var _animated_sprite: AnimatedSprite2D # character sprite

var is_running: bool = false # Keeps track of fast moving states
var is_jumping: bool = false # Keeps track of airborne states

signal state_changed(previous, new, direction) # Emit state changed signal

func _init(_states: Dictionary, _sprite: AnimatedSprite2D):
	self.states = _states
	self._animated_sprite = _sprite
	self.idle_state = _states["idle"]
	print("State Machine init...")
	
func _ready():
	state_changed.connect(_on_state_changed)
	transition_to("down", "idle")
	
func transition_to(direction: String, state: String):
	# We are already in the desired state. active_state is null until the first
	# transition, so check it before dereferencing.
	if (active_state != null) && (direction == last_direction) && (state == active_state.get_state_name()):
		return

	var previous := active_state
	last_direction = direction
	active_state = self.states[state]
	_animated_sprite.play(active_state.get_animation(direction))
	if (state == "running"):
		is_running = true
	else:
		is_running = false
	# Fires only on an actual change, so listeners are not spammed every frame.
	state_changed.emit(previous, active_state, direction)
	#print("State Machine transitioning to: %s(%s)" % [state, direction])

func fallback_to(state: AnimationState):
	_reset_states()
	active_state = self.states[state]
	_animated_sprite.play(active_state.get_animation(last_direction))
	#print("State Machine falling back to to: %s" % state.get_state_name())

func _on_state_changed(_previous, _new, _direction):
	# Listener only -- must never re-emit state_changed, that would recurse forever.
	#print("State Machine state changed: %s -> %s (%s)" % [_previous, _new, _direction])
	pass

func _reset_states():
	is_running = false
	is_jumping = false
