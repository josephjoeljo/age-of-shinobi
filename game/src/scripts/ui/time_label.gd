extends Label                                                                                                                                                                                                                                     
																																																													
func _ready() -> void:                                                                                                                                                                                                                            
	# Connect to the minute_changed signal for efficient updates                                                                                                                                                                                  
	STimeSystem.minute_changed.connect(_update_time_display)                                                                                                                                                                                       
																																																													
	# Set initial time                                                                                                                                                                                                                            
	_update_time_display(STimeSystem.game_minute)                                                                                                                                                                                                  
																																																													
func _update_time_display(_minute: int) -> void:                                                                                                                                                                                                  
	# Simple time format: "14:30"                                                                                                                                                                                                                 
	#text = STimeSystem.get_time_string()                                                                                                                                                                                                           
																																																													
	# Or detailed format: "Day 3, 14:30 (Day)"                                                                                                                                                                                                    
	text = " " + STimeSystem.get_detailed_time_string() + " "                                                                                                                                                                                             
																																																													
	# Or fully custom:                                                                                                                                                                                                                            
	# text = "Day %d - %02d:%02d" % [TimeSystem.game_day, int(TimeSystem.game_hour), TimeSystem.game_minute]    
