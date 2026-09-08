class_name HerdManager
extends Node
## Autoload singleton that manages all herds in the world
##
## Coordinates both active herds (with individual agents) and statistical
## herds (Tier 3, data-only). Handles creation, promotion/demotion between
## tiers, and updating herd states each frame.

## Reference to the active world node (set by World when ready)
var world_node: Node = null

## Active herds with individual agents (herd_id -> HerdGroup)
var herds: Dictionary = {}

## Statistical herds (Tier 3) (herd_id -> StatisticalHerd)
var statistical_herds: Dictionary = {}

var world_path: NodePath = NodePath("/root/World") 

func _process(delta: float) -> void:
	# Update active herds
	for herd in herds.values():
		herd.update_shared_state()

	# Update statistical herds (much cheaper)
	for stat_herd in statistical_herds.values():
		stat_herd.drift(delta)


# ============================================================================
# HERD CREATION
# ============================================================================

## Creates a new active herd at a position
func create_herd(species_id: String, position: Vector2, count: int) -> HerdGroup:
	var species = SSpeciesDatabase.get_species(species_id)
	if not species:
		push_error("Cannot create herd: unknown species %s" % species_id)
		return null

	var herd = HerdGroup.new()
	herd.herd_id = "herd_%s_%d" % [species_id, Time.get_ticks_msec()]
	herd.initialize(species)
	herd.center = position

	herds[herd.herd_id] = herd

	# Spawn initial members using the visual_scene from species definition
	if species.visual_scene and world_node:
		for i in range(count):
			var offset = Vector2(randf_range(-50, 50), randf_range(-50, 50))
			var agent = species.visual_scene.instantiate()
			agent.position = position + offset
			world_node.add_child(agent)
			herd.add_member(agent)
			print("Spawned %s at %v" % [species_id, agent.position])
	elif not species.visual_scene:
		push_warning("Species %s has no visual_scene set - cannot spawn agents" % species_id)
	elif not world_node:
		push_error("No world_node registered with HerdManager. World must set SHerdManager.world_node = self in _ready()")                                                                                                                                                               
																																																																		 
	print("Created herd: %s with %d members at %v" % [herd.herd_id, count, position])

	return herd


# ============================================================================
# TIER PROMOTION/DEMOTION
# ============================================================================

## Demotes an active herd to statistical (Tier 3)
func demote_to_statistical(herd: HerdGroup) -> StatisticalHerd:
	var stat = StatisticalHerd.new()
	stat.herd_id = herd.herd_id
	stat.species_id = herd.species_id
	stat.population = herd.members.size()
	stat.center = herd.center
	stat.drift_direction = herd.average_velocity.normalized()
	if stat.drift_direction == Vector2.ZERO:
		stat.drift_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()

	# Store persistent member data
	for member in herd.members:
		if not member.uid.is_empty():
			stat.persistent_member_ids.append(member.uid)
			# NOTE: Requires PersistenceManager
			# PersistenceManager.update_agent_record(member)

		# NOTE: Requires AgentPool
		# AgentPool.return_agent(member)

	# Remove from active, add to statistical
	herds.erase(herd.herd_id)
	statistical_herds[stat.herd_id] = stat

	print("Demoted herd %s to statistical" % herd.herd_id)

	return stat


## Promotes a statistical herd back to active
func promote_from_statistical(stat: StatisticalHerd, _player_position: Vector2) -> HerdGroup:
	var species = SSpeciesDatabase.get_species(stat.species_id)
	if not species:
		push_error("Cannot promote herd: unknown species %s" % stat.species_id)
		return null

	var herd = HerdGroup.new()
	herd.herd_id = stat.herd_id
	herd.initialize(species)
	herd.center = stat.center

	# NOTE: Spawning agents requires AgentPool and PersistenceManager
	# Commented out for now - implement when those systems are ready

	# # Spawn persistent members from saved data
	# for uid in stat.persistent_member_ids:
	#     var record = PersistenceManager.get_agent_record(uid)
	#     if record:
	#         PersistenceManager.catch_up_simulation(record)
	#         var agent = AgentPool.acquire(stat.species_id, record.position, herd)
	#         agent.uid = uid
	#         agent.health = record.current_health
	#         # ... restore other persistent state
	#         herd.members.append(agent)

	# # Fill remaining population with generic agents
	# var generic_count = stat.population - stat.persistent_member_ids.size()
	# for i in range(generic_count):
	#     var offset = Vector2(randf_range(-50, 50), randf_range(-50, 50))
	#     var agent = AgentPool.acquire(stat.species_id, stat.center + offset, herd)
	#     herd.members.append(agent)

	# Remove from statistical, add to active
	statistical_herds.erase(stat.herd_id)
	herds[herd.herd_id] = herd

	print("Promoted herd %s to active" % herd.herd_id)

	return herd


# ============================================================================
# QUERIES
# ============================================================================

## Gets an active herd by ID
func get_herd(herd_id: String) -> HerdGroup:
	return herds.get(herd_id)


## Gets a statistical herd by ID
func get_statistical_herd(herd_id: String) -> StatisticalHerd:
	return statistical_herds.get(herd_id)


## Returns total number of active herds
func get_active_herd_count() -> int:
	return herds.size()


## Returns total number of statistical herds
func get_statistical_herd_count() -> int:
	return statistical_herds.size()


## Returns all herds of a specific species
func get_herds_by_species(species_id: String) -> Array[HerdGroup]:
	var result: Array[HerdGroup] = []
	for herd in herds.values():
		if herd.species_id == species_id:
			result.append(herd)
	return result
