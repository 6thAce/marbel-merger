extends RigidBody2D

@export var level: int = 1
@onready var main = get_tree().root.get_node("Main")

func _on_area_2d_body_entered(body: Node) -> void:
	if body is RigidBody2D and body.has_method("get_level"):
		print("Collision with ball level:", body.get_level())

		if body.get_level() == level:
			merge_with(body)


func get_level() -> int:
	return level


func merge_with(other_ball: RigidBody2D):
	if !is_instance_valid(other_ball):
		return

	var new_pos = (position + other_ball.position) / 2.0

	queue_free()
	other_ball.queue_free()

	var next_level = level + 1

	if next_level < main.ball_scenes.size():
		var new_ball = main.ball_scenes[next_level].instantiate()
		new_ball.position = new_pos
		main.add_child(new_ball)
