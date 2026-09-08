class_name PerceptionSystem
extends Node
## Handles sensory input and threat detection for AI agents
##
## Detects nearby entities using vision and hearing, classifies them as threats
## or allies, and writes the results to the agent's blackboard for behavior tree
## to process. Updates at configurable intervals based on LOD tier.

## Reference to owning agent
var agent: AIAgent

## Reference to agent's blackboard
var blackboard: Blackboard

## Is perception enabled? (controlled by tier)
var enabled: bool = true

## Range multiplier for LOD (1.0 = full range, 0.5 = half range)
var range_multiplier: float = 1.0

## Update interval in seconds (lower tier = less frequent updates)
var update_interval: float = 0.1

## Internal update timer
var _update_timer: float = 0.0

## Memory of detected threats (entity_id -> ThreatInfo)
var _threat_memory: Dictionary = {}


func _init(p_agent: AIAgent, p_blackboard: Blackboard) -> void:
	agent = p_agent
	blackboard = p_blackboard


func _process(delta: float) -> void:
	if not enabled:
		return

	_update_timer += delta
	if _update_timer >= update_interval:
		_update_timer = 0.0
		_update_perception()


## Main perception update - detects and classifies nearby entities
func _update_perception() -> void:
	if not agent or not agent.species:
		return

	var species = agent.species
	var position = agent.global_position

	# Get nearby entities using spatial query
	# NOTE: This uses SpatialHashMap which needs to be implemented separately
	# For now, we'll use a simple area query
	var vision_range = species.vision_range * range_multiplier
	var nearby = _query_nearby_entities(position, vision_range)

	var threats: Array[ThreatInfo] = []
	var allies_count := 0
	var enemies_count := 0
	var closest_enemy: Node2D = null
	var closest_distance := INF

	for entity in nearby:
		if entity == null or entity == agent:
			continue

		var to_entity = entity.global_position - position
		var distance = to_entity.length()
		var direction = to_entity.normalized()

		# Vision cone check
		if not _is_in_vision_cone(direction, species.vision_angle):
			# Can still hear if in hearing range
			if distance > species.hearing_range * range_multiplier:
				continue

		# Classify entity
		if _is_threat(entity):
			enemies_count += 1

			var threat = ThreatInfo.new()
			threat.entity = entity
			threat.distance = distance
			threat.direction = direction
			threat.threat_level = _calculate_threat_level(entity, distance)
			threat.last_seen_position = entity.global_position
			threat.last_seen_time = Time.get_ticks_msec() / 1000.0
			threats.append(threat)

			if distance < closest_distance:
				closest_distance = distance
				closest_enemy = entity

		elif _is_ally(entity):
			allies_count += 1

	# Update blackboard with perception results
	blackboard.set_value("threats", threats)
	blackboard.set_value("allies_nearby", allies_count)
	blackboard.set_value("enemies_nearby", enemies_count)

	if closest_enemy:
		blackboard.set_value("target", closest_enemy)
		blackboard.set_value("target_distance", closest_distance)
		blackboard.set_value("target_direction",
			(closest_enemy.global_position - position).normalized())
	else:
		blackboard.erase("target")
		blackboard.erase("target_distance")
		blackboard.erase("target_direction")

	# Decay old threat memory
	_decay_threat_memory()


## Queries nearby entities (placeholder for spatial hash)
## In a full implementation, this would query a SpatialHashMap
func _query_nearby_entities(position: Vector2, radius: float) -> Array[Node2D]:
	var result: Array[Node2D] = []

	# Simple implementation: get all entities in scene tree
	# This should be replaced with a proper spatial hash lookup
	var entities = get_tree().get_nodes_in_group("entities")

	for entity in entities:
		if entity is Node2D:
			var distance = entity.global_position.distance_to(position)
			if distance <= radius:
				result.append(entity)

	return result


## Checks if a direction is within the agent's vision cone
func _is_in_vision_cone(direction: Vector2, angle_degrees: float) -> bool:
	# Calculate forward direction based on agent rotation
	var forward = Vector2.from_angle(agent.rotation)
	var angle = rad_to_deg(forward.angle_to(direction))
	return abs(angle) <= angle_degrees / 2.0


## Determines if an entity is a threat to this agent
func _is_threat(entity: Node2D) -> bool:
	# Check if entity is a player
	if entity.is_in_group("player"):
		return true

	# Check if entity is an AI agent
	if entity is AIAgent:
		var other_agent = entity as AIAgent
		if other_agent.species:
			# Predators are threats to prey
			if other_agent.species.category == SpeciesDefinition.SpeciesCategory.PREDATOR:
				if agent.species.category == SpeciesDefinition.SpeciesCategory.PREY:
					return true

			# Different predator species can be threats to each other
			if other_agent.species.category == SpeciesDefinition.SpeciesCategory.PREDATOR:
				if agent.species.category == SpeciesDefinition.SpeciesCategory.PREDATOR:
					if other_agent.species_id != agent.species_id:
						return true

	return false


## Determines if an entity is an ally
func _is_ally(entity: Node2D) -> bool:
	if entity is AIAgent:
		var other_agent = entity as AIAgent
		# Same species = ally
		return other_agent.species_id == agent.species_id

	return false


## Calculates threat level for an entity (0.0 - 1.0)
func _calculate_threat_level(entity: Node2D, distance: float) -> float:
	var base_threat := 0.5

	# Closer = more threatening
	var distance_factor = 1.0 - (distance / agent.species.vision_range)
	base_threat += distance_factor * 0.3

	# Check entity type
	if entity.is_in_group("player"):
		base_threat += 0.2  # Players are always extra dangerous

	return clampf(base_threat, 0.0, 1.0)


## Decays old threat memory over time
func _decay_threat_memory() -> void:
	# For now, simple cleanup
	# In full implementation, this would handle threat decay in persistence
	var now = Time.get_ticks_msec() / 1000.0

	for entity_id in _threat_memory.keys():
		var threat_info = _threat_memory[entity_id] as ThreatInfo
		if now - threat_info.last_seen_time > agent.species.threat_memory_duration:
			_threat_memory.erase(entity_id)
