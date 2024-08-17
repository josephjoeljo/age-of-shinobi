var idle := State.new(
	"idle",
	{
		"up": "idle_up",
		"down": "idle_down",
		"left": "idle_left",
		"right": "idle_right"
	}
)

var walking := State.new(
	"walking",
	{
		"up": "walking_up",
		"down": "walking_down",
		"left": "walking_left",
		"right": "walking_right"
	}
)

var running := State.new(
	"running",
	{
		"up": "running_up",
		"down": "running_down",
		"left": "running_left",
		"right": "running_right"
	}
)
