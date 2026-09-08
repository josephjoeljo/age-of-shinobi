class_name AIAgent
extends CharacterBody2D
## Core runtime entity for AI-controlled creatures and NPCs
##
## Combines perception, decision-making (BT or RL), reaction timing,
## and animation into a cohesive unit. Supports LOD tiers and pooling.

# ============================================================================
# IDENTITY
# ============================================================================

## Persistent unique ID (empty string = generic pooled agent)
@export var uid: String = ""

## Species identifier (e.g., "wolf", "deer", "merchant")
@export var species_id: String

## Cached species definition
var species: SpeciesDefinition


# ============================================================================
# COMPONENTS
# ============================================================================

var blackboard: Blackboard
var perception: PerceptionSystem
var behavior_tree: BehaviorTree
var reaction_queue: ReactionQueue
var steering: SteeringController
var animation_player: AnimationPlayer


# ============================================================================
# HERD/SOCIAL
# ============================================================================

var herd: HerdGroup = null
var herd_role: HerdRole = HerdRole.NONE

enum HerdRole {
	NONE,
	MEMBER,
	LEADER,
	SCOUT,
	DEFENDER
}


# ============================================================================
# LOD (Level of Detail)
# ============================================================================

## Current LOD tier (0 = full detail, 3 = statistical)
var current_tier: int = 0
var tier_config: TierConfig


# ============================================================================
# STATE
# ============================================================================

var is_in_combat: bool = false
var current_target: Node2D = null
var health: float = 100.0
var stamina: float = 100.0


# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready() -> void:
	species = SSpeciesDatabase.get_species(species_id)
	if not species:
		push_error("Species '%s' not found! Check that %s.tres exists in res://data/species/" % [species_id, species_id])
		return

	_initialize_components()
	_apply_tier_config()


func _initialize_components() -> void:
	# Create blackboard and populate with agent identity
	blackboard = Blackboard.new()
	blackboard.set_value("owner", self)
	blackboard.set_value("species", species)
	blackboard.set_value("health_percent", health / species.base_health)
	blackboard.set_value("stamina_percent", stamina / 100.0)  # Using fixed max of 100
	blackboard.set_value("graze_cooldown", 0.0)  # Initialize to 0 so boars can graze immediately

	# Instance visual scene if provided AND we don't already have visuals built-in
	# Check if this agent already has a Visuals child or AnimationPlayer (built into the scene)
	var has_built_in_visuals = has_node("Visuals") or has_node("AnimationPlayer")

	if species.visual_scene and not has_built_in_visuals:
		var visuals = species.visual_scene.instantiate()
		visuals.name = "Visuals"
		add_child(visuals)

	# Initialize perception system
	perception = PerceptionSystem.new(self, blackboard)
	add_child(perception)

	# Initialize behavior tree from species template
	behavior_tree = species.behavior_tree.instantiate()
	behavior_tree.blackboard = blackboard
	add_child(behavior_tree)

	# Initialize reaction queue and steering
	reaction_queue = ReactionQueue.new(species)
	steering = SteeringController.new(self, species)

	# Get AnimationPlayer from scene (try multiple locations)
	# AnimationPlayer is preferred for more detailed animations
	if has_node("AnimationPlayer"):
		animation_player = $AnimationPlayer
	elif has_node("Visuals/AnimationPlayer"):
		animation_player = $Visuals/AnimationPlayer

	if not animation_player:
		push_warning("No AnimationPlayer found for %s" % species_id)
	else:
		# Ensure animation player is active on spawn
		animation_player.active = true

# ============================================================================
# MAIN LOOP
# ============================================================================

func _physics_process(delta: float) -> void:
	if current_tier >= 3:
		return  # Statistical tier - no individual processing

	# Update health/stamina in blackboard
	blackboard.set_value("health_percent", health / species.base_health)
	blackboard.set_value("stamina_percent", stamina / 100.0)  # Using fixed max of 100

	# Decay graze cooldown
	var cooldown = blackboard.get_value("graze_cooldown", 0.0)
	if cooldown > 0.0:
		var new_val = cooldown - delta
		blackboard.set_value("graze_cooldown", new_val if new_val > 0 else 0)

	# Steering always runs (when enabled by tier)
	if tier_config.individual_steering or tier_config.herd_steering:
		_update_steering(delta)

	# Process reaction queue (executes pending actions)
	reaction_queue.process(delta, self)


func _update_steering(_delta: float) -> void:
	var final_velocity := Vector2.ZERO

	# Individual steering from BT movement intent
	if tier_config.individual_steering:
		var intent_dir = blackboard.get_value("movement_direction", Vector2.ZERO)
		final_velocity += intent_dir * species.base_speed

	# Herd steering forces (cohesion, separation, alignment)
	if tier_config.herd_steering and herd:
		var herd_force = herd.get_steering_force(self)
		final_velocity += herd_force

	# Obstacle avoidance
	final_velocity += steering.get_avoidance_force()

	# Apply movement
	velocity = final_velocity
	move_and_slide()


# ============================================================================
# LOD MANAGEMENT
# ============================================================================

func set_tier(new_tier: int) -> void:
	"""Changes the LOD tier and updates component configurations"""
	if new_tier == current_tier:
		return

	current_tier = new_tier
	_apply_tier_config()


func _apply_tier_config() -> void:
	"""Applies tier-specific settings to all components"""
	tier_config = TierConfig.get_config(current_tier)

	# Perception settings
	perception.enabled = tier_config.perception_enabled
	perception.range_multiplier = tier_config.perception_range_multiplier
	perception.update_interval = tier_config.perception_update_interval

	# Behavior tree settings
	behavior_tree.enabled = tier_config.bt_enabled
	behavior_tree.tick_interval = randf_range(
		tier_config.bt_interval_min,
		tier_config.bt_interval_max
	)

	# Animation settings - pause/unpause based on LOD tier
	if animation_player:
		animation_player.active = tier_config.animation_enabled


# ============================================================================
# PERSISTENCE
# ============================================================================

func promote_to_persistent() -> String:
	"""Converts a generic pooled agent to a persistent agent with a UID
	Returns the newly created UID"""
	if uid.is_empty():
		# TODO: Implement PersistenceManager
		uid = "agent_%d" % get_instance_id()
		# uid = PersistenceManager.create_agent_record(self)
	return uid


func get_save_data() -> Dictionary:
	"""Returns serializable data for persistence"""
	return {
	"uid": uid,
	"species_id": species_id,
	"position": global_position,
	"health": health,
	"stamina": stamina,
	"herd_id": herd.herd_id if herd else "",
	"is_in_combat": is_in_combat
	}


# ============================================================================
# ACTION EXECUTION
# ============================================================================

func execute_action(intent: ActionIntent) -> void:
	"""Called by ReactionQueue when an action should execute"""

	# Determine movement direction for directional animations
	var move_dir = blackboard.get_value("movement_direction", Vector2.ZERO)
	var direction_suffix = _get_direction_suffix(move_dir)

	match intent.action:
		ActionIntent.ActionType.IDLE:
			_play_animation("idle" + direction_suffix)

		ActionIntent.ActionType.WANDER:
			var random_dir = Vector2.from_angle(randf() * TAU)
			blackboard.set_value("movement_direction", random_dir)
			# Calculate direction suffix from NEW direction
			var wander_suffix = _get_direction_suffix(random_dir)
			_play_animation("walk" + wander_suffix)

		ActionIntent.ActionType.MOVE:
			blackboard.set_value("movement_direction", intent.direction)
			# Calculate direction suffix from NEW direction
			var move_suffix = _get_direction_suffix(intent.direction)
			_play_animation("walk" + move_suffix)

		ActionIntent.ActionType.ATTACK:
			_perform_attack(intent.target)
			_play_animation("attack" + direction_suffix)
			is_in_combat = true

		ActionIntent.ActionType.FLEE:
			blackboard.set_value("movement_direction", intent.direction)
			var flee_suffix = _get_direction_suffix(intent.direction)
			_play_animation("run" + flee_suffix)

		ActionIntent.ActionType.GRAZE:
			# Stop movement while grazing
			blackboard.set_value("movement_direction", Vector2.ZERO)
			_play_animation("idle" + direction_suffix)
			print("%s grazing at pos %v (playing idle%s)" % [species_id, global_position, direction_suffix])

		ActionIntent.ActionType.RALLY:
			if herd:
				herd.trigger_rally(global_position)

		ActionIntent.ActionType.DIE:
			_play_animation("death")
			_on_death()

	# Store current action in blackboard for animation system
	blackboard.set_value("current_action", intent.action)


func _get_direction_suffix(direction: Vector2) -> String:
	"""Convert a direction vector to animation suffix (_down, _up, _left, _right)"""
	if direction == Vector2.ZERO:
		# Use last known direction or default to down
		direction = blackboard.get_value("last_direction", Vector2.DOWN)

	# Determine primary direction (4-way)
	if abs(direction.x) > abs(direction.y):
		# Horizontal movement is stronger
		if direction.x > 0:
			blackboard.set_value("last_direction", Vector2.RIGHT)
			return "_right"
		else:
			blackboard.set_value("last_direction", Vector2.LEFT)
			return "_left"
	else:
		# Vertical movement is stronger
		if direction.y > 0:
			blackboard.set_value("last_direction", Vector2.DOWN)
			return "_down"
		else:
			blackboard.set_value("last_direction", Vector2.UP)
			return "_up"


func _play_animation(anim_name: String) -> void:
	"""Plays an animation using AnimationPlayer.
	Tries species-prefixed names first (e.g., 'boar/idle_down'), then falls back."""
	if not animation_player:
		return

	# Build the full animation path with species prefix (e.g., "boar/idle_down")
	var full_name = species_id + "/" + anim_name

	# Try species-prefixed animation first
	if animation_player.has_animation(full_name):
		animation_player.play(full_name)
	# Try without species prefix
	elif animation_player.has_animation(anim_name):
		animation_player.play(anim_name)
	else:
		# Try base animation without direction suffix (e.g., "boar/idle" or "idle")
		var base_name = anim_name.split("_")[0]
		var full_base = species_id + "/" + base_name
		if animation_player.has_animation(full_base):
			animation_player.play(full_base)
		elif animation_player.has_animation(base_name):
			animation_player.play(base_name)
		else:
			push_warning("Animation '%s' not found for %s" % [full_name, species_id])


func _perform_attack(target: Node2D) -> void:
	"""Executes attack logic on target"""
	if target == null:
		return

	if target.has_method("take_damage"):
		var damage = species.base_damage
		target.take_damage(damage, self)


# ============================================================================
# DAMAGE & DEATH
# ============================================================================

func take_damage(amount: float, attacker: Node2D) -> void:
	"""Receives damage from an attacker"""
	health -= amount
	health = maxf(health, 0.0)
  	
	# Update blackboard
	blackboard.set_value("health_percent", health / species.base_health)

  	# Store attacker as threat/target
	if attacker:
		blackboard.set_value("target", attacker)
		var to_attacker = (attacker.global_position - global_position).normalized()
		blackboard.set_value("target_direction", to_attacker)

	# Check for death
	if health <= 0:
		var death_intent = ActionIntent.create(
		 			ActionIntent.ActionType.DIE,
		 			ActionIntent.PRIORITY_DEATH
		)
		reaction_queue.queue_intent(death_intent)


func _on_death() -> void:
	"""Handles death cleanup and persistence"""
	# Mark as dead in persistence system if persistent
	if not uid.is_empty():
		# TODO: Implement PersistenceManager
		# PersistenceManager.mark_dead(uid)
		pass

	# Notify herd
	if herd:
		herd.remove_member(self)

	# Return to pool or queue_free based on persistence
	if uid.is_empty():
		# Generic agent - return to pool after death animation
		# TODO: Implement AgentPool
		# await anim_state_machine.animation_finished
		# AgentPool.return_agent(self)
		await get_tree().create_timer(5.0).timeout
		queue_free()
	else:
		# Persistent agent - keep corpse or queue_free after timer
		await get_tree().create_timer(5.0).timeout
		queue_free()


# ============================================================================
# DEBUGGING
# ============================================================================

func get_debug_info() -> Dictionary:
	"""Returns debug information for dev tools"""
	return {
		"uid": uid if not uid.is_empty() else "pooled",
		"species": species_id,
		"tier": current_tier,
		"health": "%.0f/%.0f" % [health, species.base_health],
		"target": str(current_target.name) if current_target else "none",
		"herd": herd.herd_id if herd else "none",
		"herd_role": HerdRole.keys()[herd_role],
		"pending_intents": reaction_queue.pending_intents.size()
	}
