extends Area3D

# Maximum force at the center of the shockwave

#default values of the shockwave, player code changes these values before spawning the shockwave
var shockwave_force = 25
var shockwave_scale = 16
var shockwave_anim_scale_duration = 0.3
var shockwave_anim_opacity_duration = 0.5#slightly longer to fully fade out

var shockwave_min_force_multiplier = 0.15#shockwave strength at the edges, so it's not quite zero


#variable so that force is only applied on one frame, while the mesh lingers longer
var push_active = true

func _ready():
	$CollisionShape3D.scale = Vector3(shockwave_scale, shockwave_scale, shockwave_scale)

#	$MeshInstance3D.scale = Vector3(shockwave_scale, shockwave_scale, shockwave_scale)

#start shockwave at 0 size before it shows to max size
	$MeshInstance3D.scale = Vector3(0,0,0)

	# Duplicate the material to ensure unique material per shockwave instance
	# (unique materials are needed for opacity to work properly with multiple shockwave objects)
	var mesh_instance = $MeshInstance3D
	var material = mesh_instance.mesh.surface_get_material(0).duplicate()
	mesh_instance.mesh.surface_set_material(0, material)

	var scale_tween = get_tree().create_tween()
	#grow the shockwave up to the shockwave scale
	scale_tween.tween_property($MeshInstance3D, "scale", Vector3(shockwave_scale, shockwave_scale, shockwave_scale), shockwave_anim_scale_duration)
	fade_out_child_mesh_and_destroy_parent(shockwave_anim_opacity_duration)

#using physics_process + queue_free instead of apply force on ready, so it's synced up with the physics process timing

#note: does NOT work if placed directly into a scene (due to timing), but works when instantiated while playing

func _physics_process(delta):
	if push_active == true:
		push_active = false

		# Get the global transform of the shockwave to determine its center
		var shockwave_center = global_transform.origin

		# Get all bodies inside the area
		var bodies = get_overlapping_bodies()

		# Apply force to each body
		for body in bodies:
			if body is RigidBody3D:#only trigger push code on rigidbodies
				var body_position = body.global_transform.origin
				var distance = shockwave_center.distance_to(body_position)
			
				# Calculate the direction and force strength
				var direction = (body_position - shockwave_center).normalized()

				# get the collision shape's shape and radius, then multiple it by scale
				var sphere_shape = $CollisionShape3D.shape
				var radius = sphere_shape.radius
				# Get the largest scale factor from the global transform
				var scale = $CollisionShape3D.global_transform.basis.get_scale()
				var largest_scale = max(scale.x, scale.y, scale.z)
				var shockwave_max_distance = radius * largest_scale
				
				#comapre distance to radius to get the shockwave strength mutliplier

				var shockwave_strength_multiplier = (shockwave_max_distance / distance) - 1
				
				#clamping the strength multiplier to avoid going above max force when using the shockwave point-blank
#				shockwave_strength_multiplier = clamp(shockwave_strength_multiplier, 0, 1)
				#UPD: now has a minimum force value
				shockwave_strength_multiplier = clamp(shockwave_strength_multiplier, shockwave_min_force_multiplier, 1)

				var force_strength = shockwave_force * shockwave_strength_multiplier
				#print("shockwave values: ")
				#print(shockwave_max_distance)
				#print(distance)
				#print(shockwave_strength_multiplier)
				#print("force strength: ")
				#print(force_strength)
		
				# Apply the force
				body.apply_central_impulse(direction * force_strength)

#OLD CODE BACKUP:
	
#		# Apply force to each body
#		for body in bodies:
#			if body is RigidBody3D:  # Ensure the body can respond to forces
#				var direction = (body.global_transform.origin - shockwave_center).normalized()
#				var force = direction * shockwave_force
#				body.apply_central_impulse(force)
			
#	# Delete the shockwave after applying the force
#	queue_free()


#IMPORTANT: THE FUNCTION ASSUMES THAT THE OBJECT HAS A MATERIAL
#AND THAT THE MATERIAL HAS TRANSPARENCY ENABLED AND BLEND MODE ALPHA

func fade_out_child_mesh_and_destroy_parent(duration: float):
	var mesh_instance = $MeshInstance3D  # Ensure this path matches your child node's name
	var material = mesh_instance.mesh.surface_get_material(0).duplicate()
	
	mesh_instance.set_surface_override_material(0, material)

	# Create a SceneTreeTween for tweening
	var tween = create_tween()

	# Tween the alpha value from current to 0.0 over the given duration
	tween.tween_property(material, "albedo_color:a", 0.0, duration)

	# Connect the tween's finished signal to a function that will destroy the shockwave object
	tween.finished.connect(self._on_tween_finished.bind())

	# Start the tween (SceneTreeTween starts automatically upon creation in Godot 4)

func _on_tween_finished():
#	print("tween finished")
	queue_free()  #destroy the shockwave object when the animation is done
