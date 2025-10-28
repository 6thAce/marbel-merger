extends Node2D

const scale_increment = Vector2(0.1,0.1)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _input(event):
	if event.is_action_pressed("ui_up"):
			scale += scale_increment
		
	elif  event.is_action_pressed("ui_down"):
			scale -= scale_increment
