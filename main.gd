extends Node2D

@onready var spawner = $BallSpawner

var ball_scenes = [
	preload("res://ball0.tscn"),
	preload("res://ball1.tscn"),
	preload("res://ball2.tscn"),
	preload("res://ball3.tscn"),
	preload("res://ball4.tscn")
	# preload("res://ball5.tscn")
]

var preview_ball: RigidBody2D = null
var can_move = true

func _ready():
	spawn_preview()

# --- Create a preview ball ---
func spawn_preview():
	var BallScene = ball_scenes[randi() % ball_scenes.size()]
	preview_ball = BallScene.instantiate()
	preview_ball.position = spawner.position
	preview_ball.is_preview = true   # no check needed
	preview_ball.freeze = true
	preview_ball.set_collision_layer_value(1, false)
	preview_ball.set_collision_mask_value(1, false)
	add_child(preview_ball)
	
	# Mark it as preview mode
	if preview_ball.has_variable("is_preview"):
		preview_ball.is_preview = true
	
	# Disable collision and physics temporarily
	preview_ball.freeze = true
	preview_ball.set_collision_layer_value(1, false)
	preview_ball.set_collision_mask_value(1, false)
	
	add_child(preview_ball)

# --- Handle movement ---
func _process(delta):
	if preview_ball and can_move:
		if Input.is_action_pressed("ui_left"):
			preview_ball.position.x -= 200 * delta
		if Input.is_action_pressed("ui_right"):
			preview_ball.position.x += 200 * delta

# --- Handle input ---
func _input(event):
	if event is InputEventMouseButton and event.pressed:
		drop_ball()
	elif Input.is_action_just_pressed("space"):
		drop_ball()
	elif event is InputEventScreenTouch and event.pressed:
		drop_ball()

# --- Drop the preview ball ---
func drop_ball():
	if preview_ball:
		# Enable collisions and physics
		preview_ball.freeze = false
		preview_ball.set_collision_layer_value(1, true)
		preview_ball.set_collision_mask_value(1, true)
		
		if preview_ball.has_variable("is_preview"):
			preview_ball.is_preview = false
		
		preview_ball = null
		can_move = false
		
		# Wait before spawning next ball
		await get_tree().create_timer(0.5).timeout
		can_move = true
		spawn_preview()
