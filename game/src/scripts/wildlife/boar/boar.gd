extends AIAgent
## Boar AI entity
##
## Boars are prey herd animals that flee from threats and stay together.
## This class can add boar-specific behaviors if needed, but most AI
## logic comes from the PreyHerdBT template and SpeciesDefinition.

# ============================================================================
# BOAR-SPECIFIC PROPERTIES (optional)
# ============================================================================

## Custom boar behaviors can be added here if needed
## For now, all behavior comes from PreyHerdBT and boar.tres


# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready() -> void:
	# Set species ID for this boar
	species_id = "boar"

	# Call parent _ready to initialize all AI systems
	super._ready()

	# Add to entities group for perception system
	add_to_group("entities")
	
	blackboard.set_value("graze_cooldown", 0.0)

# ============================================================================
# BOAR-SPECIFIC OVERRIDES (optional)
# ============================================================================

## Override if boars need special attack behavior (tusks!)
func _perform_attack(target: Node2D) -> void:
	# Boars only fight when cornered
	super._perform_attack(target)

	# Could add tusk charge effect here
	# _play_tusk_charge_effect()


## Override if boars need special sounds
func execute_action(intent: ActionIntent) -> void:
	# Call parent first
	super.execute_action(intent)

	# Add boar-specific sounds/effects
	match intent.action:
		ActionIntent.ActionType.FLEE:
			_play_squeal_sound()
		ActionIntent.ActionType.GRAZE:
			_play_snort_sound()
		ActionIntent.ActionType.ATTACK:
			_play_charge_sound()


# ============================================================================
# BOAR SOUNDS (placeholder)
# ============================================================================

func _play_squeal_sound() -> void:
	# TODO: Add AudioStreamPlayer and sounds
	pass


func _play_snort_sound() -> void:
	# TODO: Add AudioStreamPlayer
	pass


func _play_charge_sound() -> void:
	# TODO: Add AudioStreamPlayer
	pass
