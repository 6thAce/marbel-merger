extends Node2D

# --- Constants ---
# Movement speed of the ball while it's in preview mode
const BALL_SPAWN_SPEED := 200.0
# Estimated radius (half-width) of the ball in pixels, used for boundary clamping.
const BALL_RADIUS := 16.0 

# NEW: Defines the likelihood of spawning each ball level (0 to 4).
# Level 5 is excluded as it is merge-only.
# Higher number = higher chance. Total sum is 100.
# [L0, L1, L2, L3, L4]
const SPAWN_WEIGHTS = [60, 25, 10, 5, 0] 

@onready var spawner = $BallSpawner

# List of preloaded ball scenes to choose from randomly
var ball_scenes = [
	preload("res://ball0.tscn"),
	preload("res://ball1.tscn"),
	preload("res://ball2.tscn"),
	preload("res://ball3.tscn"),
	preload("res://ball4.tscn"),
	preload("res://ball5.tscn") # Merge-only ball
]

var preview_ball: RigidBody2D = null
var can_move := true # Flag to control movement and input processing
var is_game_over := false # State to track if the game has ended

func _ready():
	# Use randomize() to ensure true random ball selection on each run
	randomize() 
	spawn_preview()

# =========================
# 🎮 Game State Management
# =========================

# Public function to be called by a Game Over area in the scene
func end_game():
	if is_game_over:
		return
	
	is_game_over = true
	can_move = false
	
	if preview_ball:
		preview_ball.queue_free()
		preview_ball = null
	
	print("GAME OVER! Balls stopped spawning.")

# =========================
# 🧩 Create a Preview Ball - NOW WITH WEIGHTED SELECTION
# =========================
func spawn_preview():
	if is_game_over: # Don't spawn if the game is over
		return
		
	# 1. Determine which ball level to spawn based on weights
	var max_weight = 0
	for weight in SPAWN_WEIGHTS:
		max_weight += weight
	
	var random_pick = randi() % max_weight
	var chosen_index = 0
	var current_weight_sum = 0
	
	# Find the index corresponding to the random number
	for i in range(SPAWN_WEIGHTS.size()):
		current_weight_sum += SPAWN_WEIGHTS[i]
		if random_pick < current_weight_sum:
			chosen_index = i
			break
			
	# The chosen index (0-4) corresponds to the ball scene in the array
	var BallScene = ball_scenes[chosen_index]
	preview_ball = BallScene.instantiate()
	preview_ball.position = spawner.position
	
	# --- Preview Mode Setup (Ghost-like state) ---
	preview_ball.freeze = true 
	preview_ball.set_collision_layer_value(1, false) 
	preview_ball.set_collision_mask_value(1, false)
	
	var sprite := preview_ball.get_node_or_null("Sprite2D")
	if sprite:
		sprite.modulate.a = 0.4
	
	# 2. Add the ball to the scene tree
	add_child(preview_ball)


# =========================
# ⛓️ Move the Preview & Clamp Boundaries
# =========================
func _process(delta):
	# Check if the game is active before allowing movement
	if preview_ball and can_move and not is_game_over:
		var move_speed = BALL_SPAWN_SPEED * delta 
		
		# Apply movement
		if Input.is_action_pressed("ui_left"):
			preview_ball.position.x -= move_speed
		elif Input.is_action_pressed("ui_right"):
			preview_ball.position.x += move_speed
			
		# CLAMPING: Ensure the ball stays within the screen boundaries
		var viewport_width = get_viewport_rect().size.x
		var min_x = BALL_RADIUS
		var max_x = viewport_width - BALL_RADIUS
		
		# Clamp position to prevent ball from leaving the play area
		preview_ball.position.x = clamp(preview_ball.position.x, min_x, max_x)


# =========================
# 🖱️ Handle Input
# =========================
func _input(event):
	# Only process input if we are in the move state AND the game is not over
	if can_move and not is_game_over:
		# Check for Mouse Click, Spacebar, or Screen Touch
		if (event is InputEventMouseButton and event.pressed) or \
		   Input.is_action_just_pressed("space") or \
		   (event is InputEventScreenTouch and event.pressed):
			drop_ball()


# =========================
# 🪂 Drop the Ball (Activate Physics)
# =========================
func drop_ball():
	if not preview_ball or is_game_over: 
		return
	
	# 1. Restore visual state
	var sprite := preview_ball.get_node_or_null("Sprite2D")
	if sprite:
		sprite.modulate.a = 1.0

	# 2. Enable physics and collisions
	preview_ball.freeze = false
	preview_ball.set_collision_layer_value(1, true)
	preview_ball.set_collision_mask_value(1, true)

	# 3. Unmark as preview
	if "is_preview" in preview_ball:
		preview_ball.is_preview = false

	# 4. Cleanup and setup for next ball
	preview_ball = null
	can_move = false
	
	await get_tree().create_timer(0.5).timeout
	
	if not is_game_over: 
		can_move = true
		spawn_preview()
