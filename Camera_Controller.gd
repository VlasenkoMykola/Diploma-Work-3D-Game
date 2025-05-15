extends Node3D

# Sensitivity for mouse movement
var mouse_sensitivity: float = 0.1

# Rotation values (yaw and pitch)
var rotation_yaw: float = 0.0
var rotation_pitch: float = 0.0

func _ready():
	# Hide the mouse cursor and capture it for the window
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _process(delta: float):
	if Input.is_action_just_pressed("ui_cancel"):
		# Release the mouse cursor if the escape key is pressed
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _unhandled_input(event: InputEvent):
	if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# Re-capture the mouse cursor when the user clicks the left mouse button
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event: InputEvent):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		# Adjust the yaw (left-right rotation) and pitch (up-down rotation)
		rotation_yaw -= event.relative.x * mouse_sensitivity
		rotation_pitch -= event.relative.y * mouse_sensitivity

		# Clamp pitch to avoid flipping the camera
		rotation_pitch = clamp(rotation_pitch, -80, 80)

		# Apply the rotation to the camera
		rotation_degrees = Vector3(rotation_pitch, rotation_yaw, 0)
