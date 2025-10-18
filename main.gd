extends Node2D

# UI Nodes (You need to create these nodes in your scene!)
# FIXED: The node name now matches the "Score_label" node in your scene tree.
@onready var score_label = $Score_label 
@onready var spawner = $BallSpawner

# Game Configuration
const SPAWN_WEIGHTS = [60, 25, 10, 5, 0] # Levels 0, 1, 2, 3, 4. Total 100.
const BALL_RADIUS = 16.0 # Used for boundary checking

# Resources
var ball_scenes = [
	preload("res://ball0.tscn"),
	preload("res://ball1.tscn"),
	preload("res://ball2.tscn"),
	preload("res://ball3.tscn"),
	preload("res://ball4.tscn"),
	preload("res://ball5.tscn") # For merging only
]

# State Variables
var preview_ball: RigidBody2D = null
var can_move := true
var is_game_over := false
var last_drop_x: float = 0.0
var current_score: int = 0

# =========================
# ⚙️ Initialization & Setup
# =========================

func _ready():
	randomize()
	# Initialize last drop position to the spawner's X
	last_drop_x = spawner.position.x
	update_score_display() # Display initial score (0)
	spawn_preview()

# =========================
# 📊 Score System
# =========================

func update_score_display():
	# Ensure the label is ready before trying to update it
	if is_instance_valid(score_label):
		score_label.text = "SCORE: " + str(current_score)

func add_score(points: int):
	current_score += points
	update_score_display()

# =========================
# 🧩 Ball Spawning
# =========================

func get_random_ball_scene() -> Resource:
	var total_weight = 0
	for weight in SPAWN_WEIGHTS:
		total_weight += weight

	var random_value = randi() % total_weight
	var cumulative_weight = 0

	# Iterate through weights to find the selected ball level index
	for i in range(SPAWN_WEIGHTS.size()):
		cumulative_weight += SPAWN_WEIGHTS[i]
		if random_value < cumulative_weight:
			return ball_scenes[i]
	
	# Fallback (should not happen if weights are correct)
	return ball_scenes[0]

func spawn_preview():
	if is_game_over:
		return
		
	var BallScene = get_random_ball_scene()
	preview_ball = BallScene.instantiate()
	
	# Position the new preview ball at the last dropped X position
	preview_ball.position = Vector2(last_drop_x, spawner.position.y)
	
	# --- Preview Mode ---
	preview_ball.freeze = true
	# Use bitwise NOT for safety, but this is the intent:
	preview_ball.set_collision_layer_value(1, false)
	preview_ball.set_collision_mask_value(1, false)

	# Optional visual cue (semi-transparent)
	var sprite := preview_ball.get_node_or_null("Sprite2D")
	if sprite:
		sprite.modulate.a = 0.4
	
	add_child(preview_ball)

# =========================
# ⛓️ Move the Preview
# =========================

func _process(delta):
	if preview_ball and can_move and not is_game_over:
		var move_speed = 200.0 * delta # Fixes type inference error
		
		var viewport_width = get_viewport_rect().size.x
		var min_x = BALL_RADIUS
		var max_x = viewport_width - BALL_RADIUS

		if Input.is_action_pressed("ui_left"):
			preview_ball.position.x -= move_speed
		elif Input.is_action_pressed("ui_right"):
			preview_ball.position.x += move_speed
			
		# Clamp position to keep the ball within screen boundaries
		preview_ball.position.x = clamp(preview_ball.position.x, min_x, max_x)


# =========================
# 🖱️ Handle Input
# =========================

func _input(event):
	if is_game_over:
		return

	var should_drop = false
	if event is InputEventMouseButton and event.pressed:
		should_drop = true
	elif Input.is_action_just_pressed("space"):
		should_drop = true
	elif event is InputEventScreenTouch and event.pressed:
		should_drop = true
	
	if should_drop:
		drop_ball()


# =========================
# 🪂 Drop the Ball
# =========================

func drop_ball():
	if not preview_ball:
		return
	
	# Store the drop position for the next ball
	last_drop_x = preview_ball.position.x
	
	# Restore opacity
	var sprite := preview_ball.get_node_or_null("Sprite2D")
	if sprite:
		sprite.modulate.a = 1.0

	# Enable physics + collisions
	preview_ball.freeze = false
	preview_ball.set_collision_layer_value(1, true)
	preview_ball.set_collision_mask_value(1, true)

	# Unmark as preview (if used in other scripts)
	if "is_preview" in preview_ball:
		preview_ball.is_preview = false

	# Allow delay before next preview
	preview_ball = null
	can_move = false
	
	# Wait for a brief moment before spawning the next ball
	await get_tree().create_timer(0.5).timeout
	can_move = true
	spawn_preview()

# =========================
# 🛑 Game Over
# =========================

func end_game():
	if is_game_over:
		return
		
	is_game_over = true
	can_move = false
	if preview_ball:
		preview_ball.queue_free()
		preview_ball = null
	
	# Add a simple Game Over message (You should create a proper UI for this)
	if is_instance_valid(score_label):
		score_label.text = "GAME OVER! Final Score: " + str(current_score)
 
