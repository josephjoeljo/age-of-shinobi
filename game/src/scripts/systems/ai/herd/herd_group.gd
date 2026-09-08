class_name HerdGroup
extends RefCounted
## Manages group behavior for creatures that travel together
##
## Combines boids flocking (separation, alignment, cohesion) with optional
## tactical coordination for pack hunters. Updates shared state to member
## blackboards each tick.

# ============================================================================
# IDENTITY
# ============================================================================

var herd_id: String
var species_id: String
var herd_type: HerdType

enum HerdType {
	SOLITARY,  ## No herd behavior
	HERD,      ## Prey animals, flee together
	PACK       ## Predators, hunt with tactics
}

enum HerdRole {
	NONE,
	ALPHA,     ## Leader, engages directly
	FLANKER,   ## Fast members, attack from sides
	SUPPORT    ## Stays back, joins if needed
}


# ============================================================================
# MEMBERS
# ============================================================================

## Active member agents
var members: Array[AIAgent] = []

## Persistent member UIDs (for Tier 3 storage)
var persistent_member_ids: Array[String] = []


# ============================================================================
# SHARED STATE (written to member blackboards)
# ============================================================================

## Center of mass of the herd
var center: Vector2

## Average velocity of all members
var average_velocity: Vector2

## Aggregated threat level (0.0 - 1.0)
var threat_level: float = 0.0

## Is the herd currently fleeing?
var is_fleeing: bool = false

## Rally state (pack behavior)
var rally_active: bool = false
var rally_point: Vector2


# ============================================================================
# TACTICAL STATE (PACK type only)
# ============================================================================

## Tactical mode enabled?
var tactics_mode: bool = false

## Role assignments (agent instance_id -> HerdRole)
var role_assignments: Dictionary = {}

## Formation target position
var formation_target: Vector2


# ============================================================================
# BOID CONFIGURATION (from species)
# ============================================================================

var separation_weight: float
var alignment_weight: float
var cohesion_weight: float
var separation_radius: float
var neighbor_radius: float

## Reference to species definition
var species: SpeciesDefinition


# ============================================================================
# INITIALIZATION
# ============================================================================

func _init() -> void:
	pass


## Initializes herd with species configuration
func initialize(p_species: SpeciesDefinition) -> void:
	species = p_species
	species_id = p_species.species_id
	herd_type = _convert_herd_type(p_species.herd_type)

	# Copy boid settings from species
	separation_weight = p_species.separation_weight
	alignment_weight = p_species.alignment_weight
	cohesion_weight = p_species.cohesion_weight
	separation_radius = p_species.separation_radius
	neighbor_radius = p_species.neighbor_radius


## Convert SpeciesDefinition.HerdType to HerdGroup.HerdType
func _convert_herd_type(species_type: SpeciesDefinition.HerdType) -> HerdType:
	match species_type:
		SpeciesDefinition.HerdType.SOLITARY:
			return HerdType.SOLITARY
		SpeciesDefinition.HerdType.HERD:
			return HerdType.HERD
		SpeciesDefinition.HerdType.PACK:
			return HerdType.PACK
		_:
			return HerdType.SOLITARY


# ============================================================================
# MEMBER MANAGEMENT
# ============================================================================

## Adds an agent to the herd
func add_member(agent: AIAgent) -> void:
	if agent not in members:
		members.append(agent)
		agent.herd = self


## Removes an agent from the herd
func remove_member(agent: AIAgent) -> void:
	members.erase(agent)
	if agent.herd == self:
		agent.herd = null


# ============================================================================
# UPDATE LOOP
# ============================================================================

## Updates shared state and writes to member blackboards
func update_shared_state() -> void:
	if members.is_empty():
		return

	# Calculate center of mass and average velocity
	center = Vector2.ZERO
	average_velocity = Vector2.ZERO
	var max_threat := 0.0

	for member in members:
		center += member.global_position
		average_velocity += member.velocity

		# Aggregate threat from all members
		var member_threat = member.blackboard.get_value("personal_threat", 0.0)
		max_threat = max(max_threat, member_threat)

	center /= members.size()
	average_velocity /= members.size()
	threat_level = max_threat

	# Determine herd state
	is_fleeing = threat_level > 0.5

	# Write to all member blackboards
	for member in members:
		member.blackboard.set_value("herd_center", center)
		member.blackboard.set_value("herd_velocity", average_velocity)
		member.blackboard.set_value("herd_threat_level", threat_level)
		member.blackboard.set_value("herd_fleeing", is_fleeing)
		member.blackboard.set_value("herd_rally_active", rally_active)

		if rally_active:
			member.blackboard.set_value("rally_point", rally_point)

		if tactics_mode:
			var role = role_assignments.get(member.get_instance_id(), HerdRole.NONE)
			member.blackboard.set_value("role", role)


# ============================================================================
# BOIDS FLOCKING
# ============================================================================

## Calculates steering force for an agent using boids algorithm
func get_steering_force(agent: AIAgent) -> Vector2:
	var force := Vector2.ZERO

	# Base boid forces
	force += calculate_boid_forces(agent)

	# Tactical offset (if in tactics mode)
	if tactics_mode and role_assignments.has(agent.get_instance_id()):
		force += get_tactical_offset(agent)

	return force


## Calculates the three boid forces: separation, alignment, cohesion
func calculate_boid_forces(agent: AIAgent) -> Vector2:
	var separation := Vector2.ZERO
	var alignment := Vector2.ZERO
	var cohesion := Vector2.ZERO

	var neighbor_count := 0
	var separation_count := 0

	for other in members:
		if other == agent:
			continue

		var to_other = other.global_position - agent.global_position
		var distance = to_other.length()

		# SEPARATION: Avoid crowding close neighbors
		if distance < separation_radius and distance > 0:
			var repel = -to_other.normalized() / distance
			separation += repel
			separation_count += 1

		# ALIGNMENT and COHESION: All neighbors in range
		if distance < neighbor_radius:
			alignment += other.velocity
			cohesion += other.global_position
			neighbor_count += 1

	# Average the forces
	if separation_count > 0:
		separation /= separation_count

	if neighbor_count > 0:
		# ALIGNMENT: Match average velocity
		alignment /= neighbor_count
		alignment = (alignment - agent.velocity).normalized()

		# COHESION: Steer toward center of neighbors
		cohesion /= neighbor_count
		cohesion = (cohesion - agent.global_position).normalized()

	# Weight and combine
	var boid_force = (
		separation * separation_weight +
		alignment * alignment_weight +
		cohesion * cohesion_weight
	)

	return boid_force


# ============================================================================
# RALLY BEHAVIOR
# ============================================================================

## Alerts the entire herd of danger (prey behavior)
func alert_herd(threat_position: Vector2, p_threat_level: float = 1.0) -> void:
	self.threat_level = max(self.threat_level, p_threat_level)
	is_fleeing = true

	# Calculate flee direction (away from threat)
	var flee_direction = (center - threat_position).normalized()
	average_velocity = flee_direction * _get_flee_speed()

	# Update all members immediately
	for member in members:
		member.blackboard.set_value("herd_fleeing", true)
		member.blackboard.set_value("herd_threat_level", self.threat_level)
		member.blackboard.set_value("flee_direction", flee_direction)


## Requests combat rally (pack behavior)
## Returns true if rally was accepted
func request_rally(_requester: AIAgent, threat_position: Vector2) -> bool:
	if herd_type != HerdType.PACK:
		return false

	# Evaluate if pack should rally
	var pack_strength = _calculate_pack_strength()
	var threat_assessment = _assess_threat(threat_position)

	# Decision factors
	var should_rally = (
		pack_strength > threat_assessment * 0.5 and  # Strong enough
		members.size() >= species.min_pack_size_for_aggression  # Big enough
	)

	if should_rally:
		rally_active = true
		rally_point = threat_position
		tactics_mode = true
		formation_target = threat_position

		assign_tactical_roles()

		# Update all member blackboards
		for member in members:
			member.blackboard.set_value("herd_rally_active", true)
			member.blackboard.set_value("rally_point", rally_point)

		return true

	return false


func _get_flee_speed() -> float:
	if members.is_empty() or not species:
		return 100.0
	return species.sprint_speed


func _calculate_pack_strength() -> float:
	var strength := 0.0
	for member in members:
		strength += member.health * member.species.base_damage
	return strength


func _assess_threat(_position: Vector2) -> float:
	# Simple threat assessment
	# In full implementation, would query spatial hash for nearby threats
	return 50.0  # Placeholder


# ============================================================================
# TACTICAL LAYER (PACK)
# ============================================================================

## Assigns tactical roles to pack members
func assign_tactical_roles() -> void:
	if herd_type != HerdType.PACK:
		return

	role_assignments.clear()

	# Sort by combat fitness (HP * damage)
	var sorted_members = members.duplicate()
	sorted_members.sort_custom(func(a, b):
		var fitness_a = a.health * a.species.base_damage
		var fitness_b = b.health * b.species.base_damage
		return fitness_a > fitness_b
	)

	# Assign roles
	for i in range(sorted_members.size()):
		var member = sorted_members[i]
		var role: HerdRole

		if i == 0:
			# Strongest = Alpha
			role = HerdRole.ALPHA
		elif i < 3 and member.species.base_speed > species.base_speed * 0.9:
			# Fast members = Flankers
			role = HerdRole.FLANKER
		else:
			# Rest = Support
			role = HerdRole.SUPPORT

		role_assignments[member.get_instance_id()] = role


## Returns tactical formation offset for an agent
func get_tactical_offset(agent: AIAgent) -> Vector2:
	if not tactics_mode:
		return Vector2.ZERO

	var role = role_assignments.get(agent.get_instance_id(), HerdRole.NONE)
	var target_pos = formation_target
	var to_target = (target_pos - center).normalized()
	var perpendicular = Vector2(-to_target.y, to_target.x)

	var offset := Vector2.ZERO
	var formation_spread := 30.0

	match role:
		HerdRole.ALPHA:
			# Front and center
			offset = to_target * formation_spread

		HerdRole.FLANKER:
			# Sides, slightly forward
			var side = 1 if _get_flanker_index(agent) % 2 == 0 else -1
			offset = to_target * formation_spread * 0.5 + perpendicular * side * formation_spread

		HerdRole.SUPPORT:
			# Behind the alpha
			offset = -to_target * formation_spread * 0.5

	# Steering toward formation position
	var target_position = center + offset
	return (target_position - agent.global_position).normalized() * 0.5


func _get_flanker_index(agent: AIAgent) -> int:
	var index := 0
	for id in role_assignments:
		if role_assignments[id] == HerdRole.FLANKER:
			if id == agent.get_instance_id():
				return index
			index += 1
	return 0


# ============================================================================
# UTILITY
# ============================================================================

## Triggers rally from any member (convenience method)
func trigger_rally(position: Vector2) -> void:
	if members.size() > 0:
		request_rally(members[0], position)
