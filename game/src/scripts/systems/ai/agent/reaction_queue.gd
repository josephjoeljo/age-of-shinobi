class_name ReactionQueue
extends RefCounted
## Manages action execution with realistic reaction delays
##
## Behavior trees output ActionIntents which are queued here with a delay
## (reaction time). This creates realistic AI that doesn't instantly respond
## to threats. Higher priority actions can interrupt lower priority ones.

## Species configuration (for reaction time parameters)
var species: SpeciesDefinition

## Currently executing intent
var current_intent: QueuedIntent = null

## Queue of pending intents waiting to execute
var pending_intents: Array[QueuedIntent] = []


func _init(p_species: SpeciesDefinition) -> void:
	species = p_species


## Queues an action intent with a reaction delay
func queue_intent(intent: ActionIntent) -> void:
	# Calculate reaction delay based on species
	var delay = randf_range(
		species.reaction_time_min,
		species.reaction_time_max
	)

	# Create queued intent
	var queued = QueuedIntent.new()
	queued.intent = intent
	queued.execute_at = Time.get_ticks_msec() / 1000.0 + delay
	queued.priority = intent.priority
	queued.interruptible = intent.interruptible

	# Check if should interrupt current action
	if current_intent and current_intent.interruptible:
		if queued.priority > current_intent.priority:
			# Higher priority - interrupt current
			current_intent = null

	# Insert sorted by execute_at time (earliest first)
	var inserted = false
	for i in range(pending_intents.size()):
		if queued.execute_at < pending_intents[i].execute_at:
			pending_intents.insert(i, queued)
			inserted = true
			break

	if not inserted:
		pending_intents.append(queued)


## Processes the queue each frame, executing due intents
func process(_delta: float, agent: AIAgent) -> void:
	var now = Time.get_ticks_msec() / 1000.0

	# Check if current action is complete
	if current_intent and now >= current_intent.complete_at:
		# Call on_completion callback if set
		if current_intent.intent.on_completion.is_valid():
			current_intent.intent.on_completion.call()
		current_intent = null

	# Execute pending intents that are due
	while pending_intents.size() > 0 and pending_intents[0].execute_at <= now:
		var queued = pending_intents.pop_front()

		# Can we interrupt current?
		if current_intent:
			if queued.priority > current_intent.priority and current_intent.interruptible:
				# Interrupt!
				current_intent = null
			else:
				# Can't interrupt - skip this intent
				continue

		# Execute the action
		current_intent = queued
		current_intent.complete_at = now + queued.intent.duration
		agent.execute_action(queued.intent)


## Clears all pending and current intents
func clear() -> void:
	pending_intents.clear()
	current_intent = null


## Returns true if an action is currently executing
func is_busy() -> bool:
	return current_intent != null


## Returns the current action type, or IDLE if none
func get_current_action() -> ActionIntent.ActionType:
	if current_intent:
		return current_intent.intent.action
	return ActionIntent.ActionType.IDLE
