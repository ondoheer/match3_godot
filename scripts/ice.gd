extends Node2D

export (int) var health


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.



	
func take_damage(dmg):
	health -= dmg
	# can add dmg effect here
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
