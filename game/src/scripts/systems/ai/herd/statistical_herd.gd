class_name StatisticalHerd
extends RefCounted
## Tier 3 herd representation (no individual agents)
##
## When a herd is far from players, it exists only as statistical data.
## This dramatically reduces CPU cost while maintaining world simulation.
## Can be promoted back to active herd when players approach.

## Unique identifier
var herd_id: String

## Species this herd belongs to
var species_id: String

## Number of individuals in the herd
var population: int

## Current center position of the herd
var center: Vector2

## Direction of drift/movement
var drift_direction: Vector2

## Speed of background movement (much slower than active)
var drift_speed: float = 10.0

## Persistent member UIDs (for agents that had names/scars)
var persistent_member_ids: Array[String] = []

## Last time random events were checked
var last_event_check: float = 0.0


## Simple background movement
func drift(delta: float) -> void:
	center += drift_direction * drift_speed * delta

	# Occasionally change direction (simulate wandering)
	if randf() < 0.001:  # ~0.1% chance per frame
		drift_direction = drift_direction.rotated(randf_range(-0.5, 0.5))

	# Random events (predator attacks, births)
	last_event_check += delta
	if last_event_check > 60.0:  # Check every minute of real time
		last_event_check = 0.0
		_check_random_events()


## Simulates random events that affect population
func _check_random_events() -> void:
	var species = SSpeciesDatabase.get_species(species_id)
	if not species:
		return

	# Predator attacks on prey herds
	if species.category == SpeciesDefinition.SpeciesCategory.PREY:
		if randf() < 0.05:  # 5% chance per minute
			population = max(1, population - randi_range(0, 2))

	# Small chance of population growth
	if randf() < 0.02:  # 2% chance per minute
		population += 1
