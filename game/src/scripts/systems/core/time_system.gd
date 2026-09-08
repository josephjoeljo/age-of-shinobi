class_name TimeSystem
extends Node
## Central time management system
##
## Manages game time progression with a configurable time scale.
## Emits signals when time periods change for other systems to react.

# ============================================================================
# CONSTANTS
# ============================================================================

## Time scale: 1 real second = TIME_SCALE game seconds
const TIME_SCALE := 12.0

## Day periods enum for type-safe time-of-day checks
enum Period {
	DAWN,    ## 05:00 - 07:00 (sunrise)
	DAY,     ## 07:00 - 19:00 (daytime)
	DUSK,    ## 19:00 - 21:00 (sunset)
	NIGHT    ## 21:00 - 05:00 (nighttime)
}


# ============================================================================
# STATE
# ============================================================================

## Total elapsed game time in seconds
var game_time_seconds: float = 0.0


# ============================================================================
# COMPUTED PROPERTIES
# ============================================================================

## Current game hour (0.0 - 23.99)
var game_hour: float:
	get: return fmod(game_time_seconds / 3600.0, 24.0)

## Current game day (0, 1, 2, ...)
var game_day: int:
	get: return int(game_time_seconds / 86400.0)

## Current game minute within the hour (0-59)
var game_minute: int:
	get: return int(fmod(game_time_seconds / 60.0, 60.0))

## Is it currently daytime? (6am - 8pm)
var is_daytime: bool:
	get: return game_hour >= 6.0 and game_hour < 20.0

## Is it currently nighttime? (8pm - 6am)
var is_nighttime: bool:
	get: return not is_daytime

## Current period of day (enum)
var current_period: Period:
	get:
		if game_hour >= 21.0 or game_hour < 5.0:
			return Period.NIGHT
		elif game_hour < 7.0:
			return Period.DAWN
		elif game_hour < 19.0:
			return Period.DAY
		else:
			return Period.DUSK


# ============================================================================
# SIGNALS
# ============================================================================

signal minute_changed(new_minute: int)
signal hour_changed(new_hour: int)
signal day_changed(new_day: int)
signal period_changed(new_period: Period)


# ============================================================================
# CHANGE TRACKING
# ============================================================================

var _last_hour: int = -1
var _last_day: int = -1
var _last_period: Period = Period.NIGHT
var _last_minute: int = -1


# ============================================================================
# LIFECYCLE
# ============================================================================

func _ready() -> void:
	_last_hour = int(game_hour)
	_last_day = game_day
	_last_period = current_period
	_last_minute = game_minute


func _process(delta: float) -> void:
	game_time_seconds += delta * TIME_SCALE
	_check_and_emit_signals()


func _check_and_emit_signals() -> void:
	var current_hour = int(game_hour)
	var current_day = game_day
	var period = current_period
	var current_min = game_minute

	if current_min != _last_minute:
		_last_minute = current_min
		minute_changed.emit(current_min)

	if current_hour != _last_hour:
		_last_hour = current_hour
		hour_changed.emit(current_hour)

	if current_day != _last_day:
		_last_day = current_day
		day_changed.emit(current_day)

	if period != _last_period:
		_last_period = period
		period_changed.emit(period)


# ============================================================================
# UTILITY METHODS
# ============================================================================

## Convert real seconds to game seconds
func real_to_game_duration(real_seconds: float) -> float:
	return real_seconds * TIME_SCALE


## Convert game seconds to real seconds
func game_to_real_duration(game_seconds: float) -> float:
	return game_seconds / TIME_SCALE


## Get game time as formatted string (HH:MM)
func get_time_string() -> String:
	return "%02d:%02d" % [int(game_hour), game_minute]


## Get period name as display string
func get_period_name() -> String:
	match current_period:
		Period.DAWN:
			return "Dawn"
		Period.DAY:
			return "Day"
		Period.DUSK:
			return "Dusk"
		Period.NIGHT:
			return "Night"
		_:
			return "Unknown"


## Get detailed time string (e.g., "Day 3, 14:30 (Day)")
func get_detailed_time_string() -> String:
	return "Day %d, %s (%s)" % [game_day, get_time_string(), get_period_name()]


## Set game time directly (for loading saves)
func set_game_time(day: int, hour: float) -> void:
	game_time_seconds = (day * 86400.0) + (hour * 3600.0)
	_check_and_emit_signals()


## Advance time by game hours (for time skips)
func advance_hours(hours: float) -> void:
	game_time_seconds += hours * 3600.0
	_check_and_emit_signals()


## Check if current time is within a specific period
func is_period(period: Period) -> bool:
	return current_period == period
