extends Node3D

@onready var viewport := $SubViewport
@onready var mesh_instance := $MeshInstance3D
@onready var healthbar := $SubViewport/Control/Enemy_Healthbar
@onready var camera := get_viewport().get_camera_3d()  # Get the active 3D camera

var bar_red = preload("res://resources/images/barHorizontal_red.png")
var bar_green = preload("res://resources/images/barHorizontal_green.png")
var bar_yellow = preload("res://resources/images/barHorizontal_yellow.png")
var bar_black = preload("res://resources/images/barHorizontal_black.png")

const HEIGHT_OFFSET = 2.0  # Adjust this if needed

var health_component = null

func _ready():
	await get_tree().process_frame  # Ensure the viewport updates properly
#unused code
#	$SubViewportContainer.modulate.a = 0  # Hide from 2D view in-game, but also ensure it keeps getting updated unlike if "visible = false" is set. the container is needed to edit the 2D UI in-game
	update_healthbar_texture()

func update_healthbar_texture():
	var texture = viewport.get_texture()
	if texture:
		var material = mesh_instance.get_surface_override_material(0)
		if material:
			material.albedo_texture = texture
		else:
			material = StandardMaterial3D.new()
			material.albedo_texture = texture
			mesh_instance.set_surface_override_material(0, material)

func _process(delta):
	if get_parent():
		# Step 1: Follow parent's position, ignore rotation
		global_position = get_parent().global_position + Vector3(0, HEIGHT_OFFSET, 0)

		# Step 2: Force the health bar to always stay upright
		global_rotation = Vector3(0, 0, 0)  # Reset rotation completely

		# Step 3: Make it face the camera properly
		if camera:
			var direction = (camera.global_position - global_position).normalized()
			look_at(global_position - direction, Vector3.UP)
		#TODO: make update healthbar not as spammed	
		update_healthbar()

func update_healthbar():
#	print("health updated")

	# Attempt to get the parent node's HealthComponent if it exists
	if get_parent() and get_parent().has_node("HealthComponent"):
		health_component = get_parent().get_node("HealthComponent")

	#updating current/max hp:

	healthbar.value = health_component.health
	healthbar.max_value = health_component.max_health
	
	#show rounded down hp values
	var label_hp_text = str(floor(health_component.health)) + "/" + str(floor(health_component.max_health))

#TODO	
#	$Healthbar_player/Label_HP.text = label_hp_text
	
	healthbar.texture_progress = bar_green
	if healthbar.value < healthbar.max_value * 0.7:
		healthbar.texture_progress = bar_yellow
	if healthbar.value < healthbar.max_value * 0.35:
		healthbar.texture_progress = bar_red
