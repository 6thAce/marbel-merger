extends RigidBody2D

@export var level: int = 5
@onready var main: Node = get_tree().get_root().find_child("Main", true, false)

func _ready() -> void:
	var area = $Area2D
	if area:
		area.body_entered.connect(_on_area_2d_body_entered)

func _on_area_2d_body_entered(body: Node) -> void:
	if body == self:
		return
	if body is RigidBody2D and body.has_method("get_level"):
		if body.get_level() == level:
			_on_same_level_hit(body)

func _on_same_level_hit(body: Node) -> void:
	# Both are max-level balls
	print("💥 Two max-level balls collided!")

	# Optional: bounce effect when two max balls hit
	var direction = (global_position - body.global_position).normalized()
	apply_impulse(direction * 150.0)

	# Optional: add visual or sound feedback
	if has_node("Particles2D"):
		$Particles2D.emitting = true
	if has_node("AudioStreamPlayer2D"):
		$AudioStreamPlayer2D.play()

	# No merging — this is the final level
