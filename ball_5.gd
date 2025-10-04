extends RigidBody2D

@export var level: int = 5   # Ball type (0,1,2,...)
@onready var main = get_tree().root.get_node("Main") # reference to Main node

func _ready():
	# Do NOT connect signal here, Editor already handles body_entered
	pass

func _on_body_entered(body: Node):
	if body is RigidBody2D and body.has_method("get_level"):
		print("Collision with ball level: ", body.get_level())
		if body.get_level() == level: # same type
			merge_with(body)

func get_level() -> int:
	return level

func merge_with(other_ball: RigidBody2D):
	if !is_instance_valid(other_ball):
		return

	# Example merge logic
	var new_ball_scene = load("res://ball" + str(level + 1) + ".tscn")
	var new_ball = new_ball_scene.instantiate()
	new_ball.position = (position + other_ball.position) / 2

	main.add_child(new_ball)
	queue_free()
	other_ball.queue_free()
