var idle := AnimationState.new(
	"idle",
	{
		"up": "idle_up",
		"down": "idle_down",
		"left": "idle_left",
		"right": "idle_right"
	}
)

var walking := AnimationState.new(
	"walking",
	{
		"up": "walking_up",
		"down": "walking_down",
		"left": "walking_left",
		"right": "walking_right"
	}
)

var running := AnimationState.new(
	"running",
	{
		"up": "running_up",
		"down": "running_down",
		"left": "running_left",
		"right": "running_right"
	}
)
