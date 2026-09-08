extends Node
## Handles animation state transitions for boar
##
## Listens to the parent AIAgent's action changes and updates
## the AnimatedSprite2D accordingly. Handles directional animations.

@onready var agent: AIAgent = get_parent()
@onready var sprite: AnimatedSprite2D = $"../AnimatedSprite2D"

## Current animation direction
var current_direction: String = "down"


func _ready() -> void:
	# Wait for agent to initialize
	await get_tree().process_frame

	if not agent:
		push_error("AnimationHandler must be child of AIAgent")
		return

	if not sprite:
		push_error("AnimatedSprite2D not found as sibling")
		return

	# Set sprite frames from species definition
	if agent.species and agent.species.sprite_frames:
		sprite.sprite_frames = agent.species.sprite_frames
		sprite.scale = Vector2(agent.species.scale, agent.species.scale)


func _process(_delta: float) -> void:
	if not agent or not sprite:
		return

	# Update direction based on velocity
	_update_direction()

	# Get current action from blackboard
	var current_action = agent.blackboard.get_value("current_action", ActionIntent.ActionType.IDLE)

	# Map action to animation
	_play_animation_for_action(current_action)


## Updates direction based on movement
func _update_direction() -> void:
	if agent.velocity.length() < 5.0:
		return  # Keep current direction when idle

	# Determine dominant direction
	if abs(agent.velocity.x) > abs(agent.velocity.y):
		# Horizontal movement
		current_direction = "right" if agent.velocity.x > 0 else "left"
	else:
		# Vertical movement
		current_direction = "down" if agent.velocity.y > 0 else "up"

	# Flip sprite for left/right
	if current_direction == "left":
		sprite.flip_h = true
	elif current_direction == "right":
		sprite.flip_h = false


## Plays appropriate animation for current action
func _play_animation_for_action(action: ActionIntent.ActionType) -> void:
	var anim_name := ""

	match action:
		ActionIntent.ActionType.IDLE:
			anim_name = "idle_" + current_direction

		ActionIntent.ActionType.WANDER, ActionIntent.ActionType.MOVE:
			anim_name = "walk_" + current_direction

		ActionIntent.ActionType.FLEE:
			anim_name = "run_" + current_direction

		ActionIntent.ActionType.ATTACK:
			anim_name = "attack_" + current_direction

		ActionIntent.ActionType.GRAZE:
			anim_name = "graze_" + current_direction

		ActionIntent.ActionType.DIE:
			anim_name = "death"

		_:
			anim_name = "idle_" + current_direction

	# Play animation if it exists
	if sprite.sprite_frames and sprite.sprite_frames.has_animation(anim_name):
		if sprite.animation != anim_name:
			sprite.play(anim_name)
	else:
		# Fallback to basic animation without direction
		var fallback = anim_name.split("_")[0]  # "idle", "walk", etc.
		if sprite.sprite_frames and sprite.sprite_frames.has_animation(fallback):
			if sprite.animation != fallback:
				sprite.play(fallback)
