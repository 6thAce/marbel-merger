extends Node2D

@onready var spawner = $BallSpawner
var ball_scenes = [
	preload("res://ball0.tscn"),
	preload("res://ball1.tscn"),
	preload("res://ball2.tscn"),
	preload("res://ball3.tscn"),
	preload("res://ball4.tscn"),
	preload("res://ball5.tscn")
]

var preview_ball: Node2D = null
var can_move = true

func _ready():
	spawn_preview()

# Create a preview ball at spawner
func spawn_preview():
	var BallScene = ball_scenes[randi() % ball_scenes.size()]
	preview_ball = BallScene.instantiate()
	preview_ball.position = spawner.position
	preview_ball.freeze = true  # stops all physics
	add_child(preview_ball)

func _process(delta):
	if preview_ball and can_move:
		if Input.is_action_pressed("ui_left"):
			preview_ball.position.x -= 200 * delta
		if Input.is_action_pressed("ui_right"):
			preview_ball.position.x += 200 * delta

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		drop_ball()

	if event is InputEventScreenTouch and event.pressed:
		drop_ball()

func drop_ball():
	if preview_ball:
		preview_ball.freeze = false
		preview_ball = null
		can_move = false
		# Wait a short delay, then allow next ball
		await get_tree().create_timer(0.5).timeout
		can_move = true
		spawn_preview()
