extends CharacterBody2D

@export var speed = 400
@onready var _animated_sprite = $AnimatedSprite2D

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func _handle_move():
	var isRunning = false
	
	# Running States
	if Input.is_action_pressed("shift"): 
		if Input.is_action_pressed("up") && Input.is_action_pressed("left"):
			isRunning = true
			_animated_sprite.play("running_left")
		elif Input.is_action_pressed("up") && Input.is_action_pressed("right"):
			isRunning = true
			_animated_sprite.play("running_right")
		elif Input.is_action_pressed("down") && Input.is_action_pressed("left"):
			isRunning = true
			_animated_sprite.play("running_left")
		elif Input.is_action_pressed("down") && Input.is_action_pressed("right"):
			isRunning = true
			_animated_sprite.play("running_right")
		elif Input.is_action_pressed("up"):
			isRunning = true
			_animated_sprite.play("running_up")
		elif Input.is_action_pressed("down"):
			isRunning = true
			_animated_sprite.play("running_down")
		elif Input.is_action_pressed("left"):
			isRunning = true
			_animated_sprite.play("running_left")
		elif Input.is_action_pressed("right"):
			isRunning = true
			_animated_sprite.play("running_right")
	else:
		# Walking States
		if Input.is_action_pressed("up") && Input.is_action_pressed("left"):
			_animated_sprite.play("walking_left")
		elif Input.is_action_pressed("up") && Input.is_action_pressed("right"):
			_animated_sprite.play("walking_right")
		elif Input.is_action_pressed("down") && Input.is_action_pressed("left"):
			_animated_sprite.play("walking_left")
		elif Input.is_action_pressed("down") && Input.is_action_pressed("right"):
			_animated_sprite.play("walking_right")
		elif Input.is_action_pressed("up"):
			_animated_sprite.play("walking_up")
		elif Input.is_action_pressed("down"):
			_animated_sprite.play("walking_down")
		elif Input.is_action_pressed("left"):
			_animated_sprite.play("walking_left")
		elif Input.is_action_pressed("right"):
			_animated_sprite.play("walking_right")
	
		
	var input_direction = Input.get_vector("left", "right", "up", "down")
	if isRunning:
		velocity = input_direction * (speed * 2)
	else:
		velocity = input_direction * speed

	move_and_slide()

func _handle_stop():
	if Input.is_action_just_released("up"):
		_animated_sprite.play("idle_up")
		_animated_sprite.stop()
	if Input.is_action_just_released("down"):
		_animated_sprite.play("idle_down")
		_animated_sprite.stop()
	if Input.is_action_just_released("left"):
		_animated_sprite.play("idle_left")
		_animated_sprite.stop()
	if Input.is_action_just_released("right"):
		_animated_sprite.play("idle_right")
		_animated_sprite.stop()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
	
func _physics_process(_delta):
	_handle_move()
	_handle_stop()
