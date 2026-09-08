class_name ThreatInfo
extends RefCounted
## Information about a detected threat
##
## Created by PerceptionSystem when detecting hostile entities.
## Stored in blackboard's "threats" array for behavior tree to process.

## The threatening entity
var entity: Node2D

## Distance to the threat (pixels)
var distance: float

## Direction vector to the threat (normalized)
var direction: Vector2

## Assessed threat level (0.0 = minimal, 1.0 = extreme danger)
var threat_level: float

## Last known position of threat
var last_seen_position: Vector2

## Last time this threat was seen (game time)
var last_seen_time: float
