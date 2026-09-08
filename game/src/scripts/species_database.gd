class_name SpeciesDatabase
extends Node
## Autoload singleton that manages all species definitions
##
## Loads all SpeciesDefinition resources from res://data/species/ on startup
## and provides lookup methods for accessing species data.

## Cache of all loaded species (species_id -> SpeciesDefinition)
var species: Dictionary = {}

signal data_loaded

func _ready() -> void:
	_load_all_species()


## Loads all .tres files from the species data directory
func _load_all_species() -> void:
	var species_dir = "res://data/species/"
	var dir = DirAccess.open(species_dir)

	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()

		while file_name != "":
			if file_name.ends_with(".tres"):
				var species_def = load(species_dir + file_name) as SpeciesDefinition
				if species_def:
					species[species_def.species_id] = species_def
					print("Loaded species: %s (%s)" % [species_def.display_name, species_def.species_id])
			file_name = dir.get_next()

		dir.list_dir_end()
	else:
		push_warning("Species directory not found: %s" % species_dir)
		
	print("SpeciesDatabase: Loaded %d species definitions" % species.size())
	data_loaded.emit()


## Retrieves a species definition by ID
## Returns null if species not found
func get_species(species_id: String) -> SpeciesDefinition:
	if species.has(species_id):
		return species[species_id]

	push_error("Unknown species: %s" % species_id)
	return null


## Retrieves all species of a specific category
func get_species_by_category(category: SpeciesDefinition.SpeciesCategory) -> Array[SpeciesDefinition]:
	var result: Array[SpeciesDefinition] = []

	for species_def in species.values():
		if species_def.category == category:
			result.append(species_def)

	return result


## Retrieves all species of a specific herd type
func get_species_by_herd_type(herd_type: SpeciesDefinition.HerdType) -> Array[SpeciesDefinition]:
	var result: Array[SpeciesDefinition] = []

	for species_def in species.values():
		if species_def.herd_type == herd_type:
			result.append(species_def)

	return result


## Returns all species IDs
func get_all_species_ids() -> Array[String]:
	var ids: Array[String] = []
	ids.assign(species.keys())
	return ids


## Checks if a species ID exists
func has_species(species_id: String) -> bool:
	return species.has(species_id)
