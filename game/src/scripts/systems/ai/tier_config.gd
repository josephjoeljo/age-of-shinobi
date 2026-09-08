class_name TierConfig
extends RefCounted
## LOD (Level of Detail) tier configuration
##
## Defines which AI systems are enabled and their update frequencies
## for each tier. Higher tiers = lower detail = better performance.
##
## Tier 0: Full detail (near player)
## Tier 1: Reduced detail (medium distance)
## Tier 2: Minimal detail (far distance)
## Tier 3: Statistical (very far, no individual agents)

## Perception system enabled
var perception_enabled: bool
## Perception range multiplier (1.0 = full range)
var perception_range_multiplier: float
## Perception update interval (seconds)
var perception_update_interval: float

## Behavior tree enabled
var bt_enabled: bool
## Minimum BT tick interval (seconds)
var bt_interval_min: float
## Maximum BT tick interval (seconds)
var bt_interval_max: float

## Individual steering enabled
var individual_steering: bool
## Herd steering enabled
var herd_steering: bool

## Animation system enabled
var animation_enabled: bool


## Static method to get configuration for a tier
static func get_config(tier: int) -> TierConfig:
	var config = TierConfig.new()

	match tier:
		0:  # TIER 0: Full detail (0-300 pixels from player)
			config.perception_enabled = true
			config.perception_range_multiplier = 1.0
			config.perception_update_interval = 0.1

			config.bt_enabled = true
			config.bt_interval_min = 0.5  # Slower decision-making allows animations to complete
			config.bt_interval_max = 1.0

			config.individual_steering = true
			config.herd_steering = true

			config.animation_enabled = true

		1:  # TIER 1: Reduced detail (300-800 pixels)
			config.perception_enabled = true
			config.perception_range_multiplier = 0.7
			config.perception_update_interval = 0.3

			config.bt_enabled = true
			config.bt_interval_min = 0.5
			config.bt_interval_max = 1.0

			config.individual_steering = false  # Only herd steering
			config.herd_steering = true

			config.animation_enabled = true

		2:  # TIER 2: Minimal detail (800-1500 pixels)
			config.perception_enabled = false  # No perception
			config.perception_range_multiplier = 0.0
			config.perception_update_interval = 1.0

			config.bt_enabled = false  # No BT evaluation
			config.bt_interval_min = 2.0
			config.bt_interval_max = 4.0

			config.individual_steering = false
			config.herd_steering = true  # Only follow herd

			config.animation_enabled = false  # No animation updates

		3:  # TIER 3: Statistical (>1500 pixels)
			# Agent doesn't exist individually, part of StatisticalHerd
			config.perception_enabled = false
			config.perception_range_multiplier = 0.0
			config.perception_update_interval = 0.0

			config.bt_enabled = false
			config.bt_interval_min = 0.0
			config.bt_interval_max = 0.0

			config.individual_steering = false
			config.herd_steering = false

			config.animation_enabled = false

		_:
			push_error("Invalid tier: %d" % tier)
			return get_config(0)  # Fallback to tier 0

	return config


## Get tier based on distance from player (pixels)
static func get_tier_for_distance(distance: float) -> int:
	if distance < 300.0:
		return 0
	elif distance < 800.0:
		return 1
	elif distance < 1500.0:
		return 2
	else:
		return 3
