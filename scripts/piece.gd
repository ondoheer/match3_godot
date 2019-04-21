extends Node2D

export (String) var color

var matched = false
var move_tween 
# Called when the node enters the scene tree for the first time.
func _ready():
	move_tween = $MoveTween
	
func move(target):
	move_tween.interpolate_property(self, "position", position, target, .3,
									 Tween.TRANS_ELASTIC, Tween.EASE_OUT)
	move_tween.start()

func dim():
	var sprite = $Sprite
	sprite.modulate = Color(1,1,1,.5)
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
