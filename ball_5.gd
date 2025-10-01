extends RigidBody2D

@export var level: int = 0   # Ball type (0,1,2,...)
@onready var main = get_tree().root.get_node("Main") # reference to Main node

func _ready():
	# Connect collision signal
	self.body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node):
	# Check if colliding with another ball
	if body is RigidBody2D and body.has_method("get_level"):
		if body.get_level() == level:  # same type
			merge_with(body)


func get_level() -> int:
	return level


func merge_with(other_ball: RigidBody2D):
	if !is_instance_valid(other_ball):
		return

	# Position for new ball (middle of the two)
	var new_pos = (position + other_ball.position) / 2.0

	# Remove the two old balls
	queue_free()
	other_ball.queue_free()

	# Next level
	var next_level = level + 1

	# If next level exists in Main's ball_scenes array
	if next_level < main.ball_scenes.size():
		var NewBall = main.ball_scenes[next_level].instantiate()
		NewBall.position = new_pos
		main.add_child(NewBall)
