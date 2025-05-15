extends Area3D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_body_entered(body):
	#if entered body is player, reload level, otherwise destroy object
#	if body.name == "Steve": 
	if body.is_in_group("Player"):
		get_tree().reload_current_scene()
	else:
		# Destroy non-player objects
		body.queue_free()
