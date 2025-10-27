extends RigidBody2D

@export var level: int = 0
var is_preview: bool = false
@onready var main: Node = get_tree().get_root().find_child("Main", true, false)

func _ready() -> void:
	var area = $Area2D
	# Connect manually (ignore editor connections)
	if not area.body_entered.is_connected(_on_area_2d_body_entered):
		area.body_entered.connect(_on_area_2d_body_entered)
	
	# Score Diagnostic: Check if Main node was found
	if not is_instance_valid(main):
		print("ERROR: Ball failed to find the 'Main' node!")

func _on_area_2d_body_entered(body: Node) -> void:
	if is_preview:
		return
	if body == self:
		return
		
	# CRITICAL SAFETY CHECK: Prevent collision/deletion if the ball hits the spawner.
	if main and is_instance_valid(main.spawner) and body == main.spawner:
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
	if other_ball.has_method("get_level"):
		other_ball.level = -1
	
	# --- SCORE CALCULATION ---
	# Calculate points based on the level of the ball being merged (2^(level + 1))
	var points_earned = int(pow(2, level + 1))
	
	# Pass the score to the main node
	if main and main.has_method("add_score"):
		main.add_score(points_earned)
	# -------------------------

	var new_pos = (position + other_ball.position) / 2.0
	var next_level = level + 1

	# These are safe because the whole function was deferred.
	queue_free()
	other_ball.queue_free()

	if main and next_level < main.ball_scenes.size():
		var new_ball = main.ball_scenes[next_level].instantiate()
		new_ball.position = new_pos
		
		# Ensure the newly merged ball has physics and collisions enabled
		new_ball.freeze = false
		new_ball.set_collision_layer_value(1, true)
		new_ball.set_collision_mask_value(1, true)
		
		main.add_child(new_ball)
