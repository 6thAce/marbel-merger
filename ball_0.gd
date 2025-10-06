extends RigidBody2D

@export var level: int = 0
@onready var main: Node = get_tree().get_root().find_child("Main", true, false)

func _ready() -> void:
	# Automatically connect the collision signal from Area2D (no need to do it manually)
	var area = $Area2D
	if area:
		area.body_entered.connect(_on_area_2d_body_entered)

func _on_area_2d_body_entered(body: Node) -> void:
	if body == self:
		return
	if body is RigidBody2D and body.has_method("get_level"):
		print("Collision with level:", body.get_level())
		if body.get_level() == level:
			merge_with(body)

func get_level() -> int:
	return level

func merge_with(other_ball: RigidBody2D) -> void:
	if !is_instance_valid(other_ball):
		return

	var new_pos = (position + other_ball.position) / 2.0

	# Remove both old balls safely in the next frame
	call_deferred("queue_free")
	other_ball.call_deferred("queue_free")

	var next_level = level + 1

	if main and next_level < main.ball_scenes.size():
		var new_ball = main.ball_scenes[next_level].instantiate()
		new_ball.position = new_pos
		main.add_child(new_ball)
