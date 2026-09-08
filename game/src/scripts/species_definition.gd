class_name SpeciesDefinition
extends Resource
## Data-driven species definition
##
## Defines all parameters for a creature species including behavior, perception,
## movement, combat stats, and herd behavior. Used by AIAgent to configure behavior.

# ============================================================================
# IDENTITY
# ============================================================================

@export var species_id: String
@export var display_name: String
@export var category: SpeciesCategory

enum SpeciesCategory {
	PREDATOR,   ## Hunts other creatures
	PREY,       ## Flees from threats
	NPC,        ## Humanoid NPCs with schedules
	AMBIENT     ## Background creatures (birds, butterflies)
}


# ============================================================================
# BEHAVIOR
# ============================================================================

## Behavior tree template to use (PackedScene of BehaviorTree)
@export var behavior_tree: PackedScene
## Optional variant within template (e.g., "timid" for cautious deer)
@export var bt_variant: String = ""


# ============================================================================
# TIMING
# ============================================================================

## Minimum reaction time delay (seconds)
@export var reaction_time_min: float = 0.15
## Maximum reaction time delay (seconds)
@export var reaction_time_max: float = 0.30
## Behavior tree evaluation interval (seconds)
@export var decision_interval: float = 0.2


# ============================================================================
# PERCEPTION
# ============================================================================

## Vision detection range (pixels)
@export var vision_range: float = 100.0
## Vision cone angle (degrees)
@export var vision_angle: float = 120.0
## Hearing detection range (pixels)
@export var hearing_range: float = 50.0
## How long to remember threats (game-seconds)
@export var threat_memory_duration: float = 300.0


# ============================================================================
# MOVEMENT
# ============================================================================

## Normal movement speed (pixels/second)
@export var base_speed: float = 80.0
## Sprint/panic speed (pixels/second)
@export var sprint_speed: float = 150.0
## Stamina cost for sprinting (per second)
@export var sprint_stamina_cost: float = 10.0
## Turn rate (radians per second)
@export var turn_rate: float = 5.0


# ============================================================================
# BOID WEIGHTS (for herd movement)
# ============================================================================

@export_group("Boids")
## Weight for separation force (avoid crowding)
@export var separation_weight: float = 1.5
## Weight for alignment force (match neighbor velocity)
@export var alignment_weight: float = 1.0
## Weight for cohesion force (move toward center)
@export var cohesion_weight: float = 1.0
## Radius for separation behavior (pixels)
@export var separation_radius: float = 20.0
## Radius for detecting neighbors (pixels)
@export var neighbor_radius: float = 50.0


# ============================================================================
# HERD BEHAVIOR
# ============================================================================

@export_group("Herd")
## Type of herd behavior
@export var herd_type: HerdType = HerdType.SOLITARY
## Can this species call for help?
@export var can_rally: bool = false
## Health threshold to trigger rally (0.0-1.0)
@export var rally_threshold: float = 0.3
## Minimum pack size needed to be aggressive
@export var min_pack_size_for_aggression: int = 3

enum HerdType {
	SOLITARY,  ## Individual hunters, no herd
	HERD,      ## Prey animals, flee together
	PACK       ## Predators, hunt with tactics
}


# ============================================================================
# TACTICAL (pack hunters only)
# ============================================================================

@export_group("Tactics")
## Available tactical roles (e.g., ["ALPHA", "FLANKER", "SUPPORT"])
@export var available_roles: Array[String] = []
## Role assignment weights for distribution
@export var role_assignment_weights: Dictionary = {}


# ============================================================================
# COMBAT
# ============================================================================

@export_group("Combat")
## Maximum health points
@export var base_health: float = 100.0
## Base damage per attack
@export var base_damage: float = 10.0
## Attack reach distance (pixels)
@export var attack_range: float = 20.0
## Cooldown between attacks (seconds)
@export var attack_cooldown: float = 1.0
## Health percent at which to flee (0.0-1.0)
@export var flee_health_threshold: float = 0.2
## Aggression level: 0 = passive, 1 = very aggressive
@export var aggression: float = 0.5


# ============================================================================
# BT THRESHOLDS (read by behavior tree conditions)
# ============================================================================

@export_group("BT Thresholds")
## Threat level that causes panic (0.0-1.0)
@export var panic_threshold: float = 0.8
## Distance at which threats trigger flee (pixels)
@export var danger_radius: float = 50.0
## Maximum chase distance (pixels)
@export var chase_range: float = 150.0
## Curiosity level: 0 = cautious, 1 = very curious
@export var curiosity: float = 0.3
## Pack loyalty: 0 = independent, 1 = very loyal
@export var pack_loyalty: float = 0.5


# ============================================================================
# PERSISTENCE
# ============================================================================

@export_group("Persistence")
## Passive healing rate (HP per game-hour)
@export var passive_heal_rate: float = 1.0
## Threat memory decay rate (per game-hour)
@export var threat_decay_rate: float = 0.1


# ============================================================================
# RL INTEGRATION (future)
# ============================================================================

@export_group("RL")
## Path to ONNX policy file (if using RL instead of BT)
@export var rl_policy_path: String = ""
## RL observation configuration
@export var rl_observation_config: Dictionary = {}


# ============================================================================
# VISUALS
# ============================================================================

@export_group("Visuals")
## Scene for this species (can be full agent with visuals, or just visuals)
## If this is a complete agent scene (with AnimatedSprite2D already inside),
## the AIAgent will skip instantiating visual_scene as a child
@export var visual_scene: PackedScene

## Body parts where scars can appear (e.g., ["body", "face", "legs"])
@export var scar_locations: Array[String] = ["body"]
