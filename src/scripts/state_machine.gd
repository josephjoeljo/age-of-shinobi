extends Node
class_name StateMachine

## Hierarchical State machine.
##
## Initializes states and handle animation transitions
## The states array must contain the idle state as the first state

var states: Dictionary # All of the states of this state machine
var idle_state: State # Fallback State
var active_state: State # Current State
var last_direction: String # Direction of last movement

var _animated_sprite: AnimatedSprite2D # character sprite

var is_running: bool = false # Keeps track of fast moving states
var is_jumping: bool = false # Keeps track of airbone states

signal state_changed(previous, new, direction) # Emit state changed signal

func _init(_states: Dictionary, _sprite: AnimatedSprite2D):
	self.states = _states
	self._animated_sprite = _sprite
	self.idle_state = _states["idle"]
	print("State Machine init...")
	
func _ready():
	state_changed.connect(_on_state_changed)
	transisiton_to("down", "idle")
	
func transisiton_to(direction: String, state: String):
	# We are already in the desired state
	if (direction == last_direction) && (state == active_state.get_state_name()):
		return

	last_direction = direction
	active_state = self.states[state]
	_animated_sprite.play(active_state.get_animation(direction))
	if (state == "running"):
		is_running = true
	else:
		is_running = false
	print("State Machine transitioning to: %s(%s)" % [state, direction])

func fallback_to(state: State):
	_reset_states()
	active_state = self.states[state]
	_animated_sprite.play(active_state.get_animation(last_direction))
	print("State Machine falling back to to: %s" % state.get_state_name())

func _on_state_changed(previous, new, direction):
	state_changed.emit(previous, new, direction)
	print("State Machine state changed")

func _reset_states():
	is_running = false
	is_jumping = false
