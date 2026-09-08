## A class for handling basic vitals
##
## The vitals class handles anything that has to do with an entity's vitals 
## if something can be killed or hurt it will use this vitals class.
##
extends Node
class_name Vitals

var health: int
var stamina: int
var chakra: int

## Constructor
func _init():
	self.health = 100;
	self.stamina = 100
	self.chakra = 100
	pass
