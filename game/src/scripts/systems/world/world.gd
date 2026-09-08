extends Node

# Called when the node enters the scene tree for the first time.
func _ready():
	print("World starting...")

	# Register this world node with HerdManager
	SHerdManager.world_node = self
	SHerdManager.create_herd("boar", Vector2(0, 0), 3)
	SSpeciesDatabase.data_loaded.connect(load_herds)
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func load_herds():
	SHerdManager.create_herd("boar", Vector2(0, 0), 1)
