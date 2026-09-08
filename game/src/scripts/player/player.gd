extends CharacterBody2D

@export var speed = 400
@onready var _animated_sprite = $AnimatedSprite2D

var vitals: Vitals
var state_machine: AnimationStateMachine

# Called when the node enters the scene tree for the first time.
func _ready():
	var player_states = load("res://src/scripts/player/animation_states.gd").new()
	self.vitals = Vitals.new()
	self.state_machine = AnimationStateMachine.new(
		{
			"idle": player_states.idle,
			"walking": player_states.walking,
			"running": player_states.running
		},
		_animated_sprite
	)
	# Parent the state machine so it actually gets _ready(), _process() and the
	# rest of the node lifecycle
	state_machine.name = "AnimationStateMachine"
	add_child(state_machine)

func _handle_move():

	# Running States
	if Input.is_action_pressed("shift"): 
		if Input.is_action_pressed("up") && Input.is_action_pressed("left"):
			state_machine.transition_to("left", "running")
		elif Input.is_action_pressed("up") && Input.is_action_pressed("right"):
			state_machine.transition_to("right", "running")
		elif Input.is_action_pressed("down") && Input.is_action_pressed("left"):
			state_machine.transition_to("left", "running")
		elif Input.is_action_pressed("down") && Input.is_action_pressed("right"):
			state_machine.transition_to("right", "running")
		elif Input.is_action_pressed("up"):
			state_machine.transition_to("up", "running")
		elif Input.is_action_pressed("down"):
			state_machine.transition_to("down", "running")
		elif Input.is_action_pressed("left"):
			state_machine.transition_to("left", "running")
		elif Input.is_action_pressed("right"):
			state_machine.transition_to("right", "running")
	else:
		# Walking States
		if Input.is_action_pressed("up") && Input.is_action_pressed("left"):
			state_machine.transition_to("left", "walking")
		elif Input.is_action_pressed("up") && Input.is_action_pressed("right"):
			state_machine.transition_to("right", "walking")
		elif Input.is_action_pressed("down") && Input.is_action_pressed("left"):
			state_machine.transition_to("left", "walking")
		elif Input.is_action_pressed("down") && Input.is_action_pressed("right"):
			state_machine.transition_to("right", "walking")
		elif Input.is_action_pressed("up"):
			state_machine.transition_to("up", "walking")
		elif Input.is_action_pressed("down"):
			state_machine.transition_to("down", "walking")
		elif Input.is_action_pressed("left"):
			state_machine.transition_to("left", "walking")
		elif Input.is_action_pressed("right"):
			state_machine.transition_to("right", "walking")
	
		
	var input_direction = Input.get_vector("left", "right", "up", "down")
	if state_machine.is_running:
		velocity = input_direction * (speed * 2)
	else:
		velocity = input_direction * speed

	move_and_slide()

func _handle_stop():
	if Input.get_vector("left", "right", "up", "down") == Vector2.ZERO:
		# Keep the facing we stopped in rather than whichever key was released last.
		state_machine.transition_to(state_machine.last_direction, "idle")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
	
func _physics_process(_delta):
	_handle_move()
	_handle_stop()
