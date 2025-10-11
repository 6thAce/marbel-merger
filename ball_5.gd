extends RigidBody2D

@export var level: int = 5
var is_preview: bool = false
@onready var main: Node = get_tree().get_root().find_child("Main", true, false)

func _ready() -> void:
	var area = $Area2D
	if area and not area.body_entered.is_connected(_on_area_2d_body_entered):
		area.body_entered.connect(_on_area_2d_body_entered)

func _on_area_2d_body_entered(body: Node) -> void:
	if body == self or is_preview:
		return
	if body is RigidBody2D and body.has_method("get_level"):
		if body.get_level() == level:
			_on_same_level_hit(body)

func _on_same_level_hit(body: Node) -> void:
	# Do not merge; just create a bounce or special effect
	var direction = (global_position - body.global_position).normalized()
	apply_impulse(direction * 150.0)

	# Optional effects: Particles or
