class_name SteeringController
extends RefCounted
## Handles obstacle avoidance and steering behaviors
##
## Provides steering forces for avoiding obstacles using raycasts.
## Combined with BT movement intents and herd forces to create final velocity.

## Reference to the agent
var agent: AIAgent

## Species configuration
var species: SpeciesDefinition

## Number of raycasts for obstacle detection
const RAYCAST_COUNT := 5

## Raycast angles (in radians) relative to forward direction
const RAYCAST_ANGLES := [-0.785, -0.393, 0.0, 0.393, 0.785]  # -45°, -22.5°, 0°, 22.5°, 45°

## Raycast length multiplier based on speed
const RAYCAST_LENGTH_MULTIPLIER := 1.5

## Avoidance force strength
const AVOIDANCE_STRENGTH := 200.0


func _init(p_agent: AIAgent, p_species: SpeciesDefinition) -> void:
	agent = p_agent
	species = p_species


## Returns obstacle avoidance force
func get_avoidance_force() -> Vector2:
	if not agent:
		return Vector2.ZERO

	var avoidance_force := Vector2.ZERO
	var forward = Vector2.from_angle(agent.rotation)

	# Cast multiple rays in a cone ahead of the agent
	for i in range(RAYCAST_COUNT):
		var angle = RAYCAST_ANGLES[i]
		var ray_direction = forward.rotated(angle)
		var ray_length = species.base_speed * RAYCAST_LENGTH_MULTIPLIER

		# Perform raycast
		var space_state = agent.get_world_2d().direct_space_state
		var query = PhysicsRayQueryParameters2D.create(
			agent.global_position,
			agent.global_position + ray_direction * ray_length
		)

		# Ignore the agent itself
		query.exclude = [agent.get_rid()]

		var result = space_state.intersect_ray(query)

		if result:
			# Hit an obstacle - calculate avoidance force
			var hit_distance = agent.global_position.distance_to(result.position)
			var hit_normal = result.normal

			# Stronger force for closer obstacles
			var force_magnitude = (1.0 - hit_distance / ray_length) * AVOIDANCE_STRENGTH

			# Steer away using hit normal
			avoidance_force += hit_normal * force_magnitude

	return avoidance_force


## Returns steering force toward a target position
func seek(target_position: Vector2) -> Vector2:
	if not agent:
		return Vector2.ZERO

	var desired_velocity = (target_position - agent.global_position).normalized() * species.base_speed
	return desired_velocity - agent.velocity


## Returns steering force away from a position
func flee(threat_position: Vector2) -> Vector2:
	if not agent:
		return Vector2.ZERO

	var desired_velocity = (agent.global_position - threat_position).normalized() * species.sprint_speed
	return desired_velocity - agent.velocity


## Returns steering force to arrive at target (slows down near target)
func arrive(target_position: Vector2, slowing_radius: float = 100.0) -> Vector2:
	if not agent:
		return Vector2.ZERO

	var to_target = target_position - agent.global_position
	var distance = to_target.length()

	if distance < 1.0:
		return -agent.velocity  # Stop

	var target_speed = species.base_speed
	if distance < slowing_radius:
		# Slow down as we approach
		target_speed *= distance / slowing_radius

	var desired_velocity = to_target.normalized() * target_speed
	return desired_velocity - agent.velocity


## Returns wander force for random movement
func wander(wander_radius: float = 50.0, wander_distance: float = 100.0) -> Vector2:
	if not agent:
		return Vector2.ZERO

	# Random angle offset
	var wander_angle = randf_range(-PI / 4, PI / 4)

	# Calculate wander target
	var forward = Vector2.from_angle(agent.rotation)
	var circle_center = agent.global_position + forward * wander_distance
	var wander_offset = Vector2.from_angle(wander_angle) * wander_radius
	var wander_target = circle_center + wander_offset

	return seek(wander_target)
