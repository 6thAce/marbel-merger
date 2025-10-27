extends Node2D

# UI Nodes 
@onready var score_label = $Score_label 
@onready var spawner = $BallSpawner
@onready var game_over_ray: RayCast2D = $GameOverRay # Reference to the Game Over RayCast2D

# Game Configuration
# Levels 0 to 4. Level 5 is merge-only. Weights sum to 100.
const SPAWN_WEIGHTS = [60, 25, 10, 5, 0] 
const BALL_RADIUS = 16.0 # Adjust this to the radius of your largest ball for clamping
const GAME_OVER_TIME = 3.0 # The duration required to trigger Game Over

# Resources (Assuming ball scenes 0-5 exist)
var ball_scenes = [
	preload("res://ball0.tscn"),
	preload("res://ball1.tscn"),
	preload("res://ball2.tscn"),
	preload("res://ball3.tscn"),
	preload("res://ball4.tscn"),
	preload("res://ball5.tscn")
]

# State Variables
var preview_ball: RigidBody2D = null
var can_move := true
var is_game_over := false
var last_drop_x: float = 0.0
var current_score: int = 0

# Game Over Timer Tracking (using RayCast2D query)
var colliding_ball_id: int = -1
var collision_time: float = 0.0

# =========================
# ⚙️ Initialization & Setup
# =========================

func _ready():
	randomize()
	# Safety check for spawner
	if is_instance_valid(spawner):
		last_drop_x = spawner.position.x
	update_score_display() 
	spawn_preview()
	
	# RayCast2D logic is handled in _physics_process, no signal connections needed.
	pass

# =========================
# 📊 Score Display & Update
# =========================

func update_score_display():
	if is_instance_valid(score_label):
		score_label.text = "SCORE: " + str(current_score)

func add_score(points: int):
	current_score += points
	update_score_display()

# =========================
# ⏱️ Timed Game Over Logic (using RayCast2D query)
# =========================

func _physics_process(delta):
	if is_game_over:
		return
	
	# Safety checks for RayCast2D
	if not is_instance_valid(game_over_ray) or not game_over_ray.is_enabled():
		return
		
	# Force the RayCast to check for collisions
	game_over_ray.force_raycast_update()
	var current_collider = game_over_ray.get_collider()
	
	if current_collider and current_collider is RigidBody2D:
		var ball = current_collider as RigidBody2D
		
		# 1. Check if the ball is NOT a preview ball (using 'in' operator fix)
		if "is_preview" in ball and not ball.is_preview:
			var current_id = ball.get_instance_id()
			
			if colliding_ball_id == current_id:
				# 2. Same ball is colliding, increment timer
				collision_time += delta
				if collision_time >= GAME_OVER_TIME:
					end_game()
					return
			else:
				# 3. A new ball started colliding, reset and start timer
				colliding_ball_id = current_id
				collision_time = 0.0 # Start counting immediately
				
	else:
		# 4. Nothing or a non-ball is colliding, reset the timer
		colliding_ball_id = -1
		collision_time = 0.0

# =========================
# 🖱️ Handle Input 
# =========================

func _input(event):
	if is_game_over:
		return
		
	if event is InputEventMouseButton and event.pressed:
		drop_ball()
	elif Input.is_action_just_pressed("space"):
		drop_ball()
	elif event is InputEventScreenTouch and event.pressed:
		drop_ball()

# =========================
# 🪂 Drop the Ball
# =========================

func drop_ball():
	if not preview_ball or is_game_over:
		return
	
	last_drop_x = preview_ball.position.x
	
	var sprite := preview_ball.get_node_or_null("Sprite2D")
	if sprite:
		sprite.modulate.a = 1.0

	preview_ball.freeze = false
	preview_ball.set_collision_layer_value(1, true)
	preview_ball.set_collision_mask_value(1, true)

	if "is_preview" in preview_ball:
		preview_ball.is_preview = false

	preview_ball = null
	can_move = false
	
	await get_tree().create_timer(0.5).timeout
	can_move = true
	spawn_preview()

# =========================
# ♻️ Spawning Logic
# =========================

func get_random_ball_scene() -> Resource:
	var total_weight = 0
	# We only sum weights up to level 4 (since level 5 is merge-only)
	for weight in SPAWN_WEIGHTS:
		total_weight += weight

	var random_value = randi() % total_weight
	var cumulative_weight = 0

	# Iterate through the weights to find the selected level
	for i in range(SPAWN_WEIGHTS.size()):
		cumulative_weight += SPAWN_WEIGHTS[i]
		if random_value < cumulative_weight:
			return ball_scenes[i]
	
	return ball_scenes[0]

func spawn_preview():
	if is_game_over:
		return
	
	# CRITICAL SAFETY CHECK: Ensure spawner exists before referencing its position
	if not is_instance_valid(spawner):
		print("ERROR: BallSpawner node is missing! Cannot spawn new ball.")
		return
		
	var BallScene = get_random_ball_scene()
	preview_ball = BallScene.instantiate()
	
	# Position the new preview ball at the last dropped X position
	preview_ball.position = Vector2(last_drop_x, spawner.position.y)
	
	# Initialize as Preview
	preview_ball.freeze = true
	preview_ball.set_collision_layer_value(1, false)
	preview_ball.set_collision_mask_value(1, false)

	var sprite := preview_ball.get_node_or_null("Sprite2D")
	if sprite:
		sprite.modulate.a = 0.4
	
	add_child(preview_ball)
	
	# Immediately clamp the new preview ball to prevent it spawning out of bounds
	var viewport_width = get_viewport_rect().size.x
	var min_x = BALL_RADIUS
	var max_x = viewport_width - BALL_RADIUS
	preview_ball.position.x = clamp(preview_ball.position.x, min_x, max_x)


# =========================
# ⛓️ Move the Preview
# =========================

func _process(delta):
	# Note: This uses delta for smooth movement
	if preview_ball and can_move and not is_game_over:
		var move_speed = 200.0 * delta
		
		var viewport_width = get_viewport_rect().size.x
		var min_x = BALL_RADIUS
		var max_x = viewport_width - BALL_RADIUS

		if Input.is_action_pressed("ui_left"):
			preview_ball.position.x -= move_speed
		elif Input.is_action_pressed("ui_right"):
			preview_ball.position.x += move_speed
			
		preview_ball.position.x = clamp(preview_ball.position.x, min_x, max_x)

# =========================
# 🛑 Game Over
# =========================

func end_game():
	if is_game_over:
		return
		
	is_game_over = true
	can_move = false
	
	# Clear the preview ball if one exists
	if preview_ball:
		preview_ball.queue_free()
		preview_ball = null
	
	# Display final score
	if is_instance_valid(score_label):
		score_label.text = "GAME OVER! Final Score: " + str(current_score)
