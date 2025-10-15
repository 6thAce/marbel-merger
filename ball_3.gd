extends RigidBody2D

@export var level: int = 3
var is_preview: bool = false
@onready var main: Node = get_tree().get_root().find_child("Main", true, false)

func _ready() -> void:
	var area = $Area2D
	# Connect manually (ignore editor connections)
	if not area.body_entered.is_connected(_on_area_2d_body_entered):
		area.body_entered.connect(_on_area_2d_body_entered)

func _on_area_2d_body_entered(body: Node) -> void:
	if is_preview:
		return
	if body == self:
		return
	if body is RigidBody2D and body.has_method("get_level") and not body.is_preview:
		if body.get_level() == level:
			if get_instance_id() < body.get_instance_id():
				# CRITICAL FIX: Use call_deferred to safely execute the merge outside the physics loop.
				call_deferred("merge_with", body)

func get_level() -> int:
	return level

func merge_with(other_ball: RigidBody2D) -> void:
	if !is_instance_valid(other_ball):
		return
	
	# Optional: Set level to -1 to prevent the 'other_ball' from initiating a merge 
	# with a third ball while it waits to be queued for deletion.
	if other_ball.has_method("get_level"):
		other_ball.level = -1

	var new_pos = (position + other_ball.position) / 2.0
	var next_level = level + 1

	# These are safe because the whole function was deferred.
	queue_free()
	other_ball.queue_free()

	if main and next_level < main.ball_scenes.size():
		var new_ball = main.ball_scenes[next_level].instantiate()
		new_ball.position = new_pos
		main.add_child(new_ball)
