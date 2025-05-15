extends CharacterBody3D


var speed = 5.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var camera_speed = 0.1

var jump_velocity = 10
var max_air_jumps = 1
var air_jumps_left = max_air_jumps

#force when pushing rigidbodies by moving into them:
var push_force = 0.75

# Separate variable from actual velocity, to make it easier to separate knockback from normal movement
var movement_velocity = Vector3.ZERO

var knockback = Vector3.ZERO  # Stores the knockback force
var knockback_decay = 8.0  # Higher values = faster decay
var min_knockback_threshold = 0.1  # Stops knockback when very small

var shockwave_scene = preload("res://shockwave.tscn")
var bullet_scene = preload("res://bullet.tscn")

var health_regen = 2 #how much health is healer per second

func _ready():
	Globals.player = self  # Assign this instance to the global singleton
	
	# Connect the health_changed signal
	$HealthComponent.connect("health_changed", Callable(self, "_on_health_changed"))
	# Connect the health_depleted signal
	$HealthComponent.connect("health_depleted", Callable(self, "_on_health_depleted"))

func _physics_process(delta):	
	
	#regenerate every second in smaller increments (due to delta)
		
	$HealthComponent.heal(health_regen * delta)
	
	#OLD CODE, now replaced with mouse movement: rotate camera left and right with A/D:
	#if Input.is_action_just_pressed("cam_left"):
	#	$Camera_Controller.rotate_y(deg_to_rad(30))
	#if Input.is_action_just_pressed("cam_right"):
	#	$Camera_Controller.rotate_y(deg_to_rad(-30))

	# Add the gravity.
	if not is_on_floor():
		movement_velocity.y -= gravity * delta
	#double-jump code by me
	if is_on_floor():
		air_jumps_left = max_air_jumps

	# Handle jump.
#	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
#		velocity.y = JUMP_VELOCITY

#velocity restriction is to ensure double-jumps only trigger when they matter
	if Input.is_action_just_pressed("ui_accept") and (is_on_floor() or air_jumps_left > 0) and (velocity.y < jump_velocity * 0.4):
		movement_velocity.y = jump_velocity
		if not is_on_floor():
			air_jumps_left = air_jumps_left - 1

	if Input.is_action_just_pressed("skill_1"):
		var shockwave = shockwave_scene.instantiate()  # Create an instance of the shockwave scene
		shockwave.shockwave_force = 40
		shockwave.shockwave_scale = 20
		get_tree().get_root().add_child(shockwave)  # Add it to the scene				
		shockwave.transform.origin = global_transform.origin

	if Input.is_action_just_pressed("skill_2"):
		pass
		#TODO: add some kind of skill 2?
		
	if Input.is_action_just_pressed("attack"):
		var bullet = bullet_scene.instantiate()  # Create an instance of the shockwave scene
#		bullet.damage = bullet_damage
		bullet.is_player_bullet = true
		get_tree().get_root().add_child(bullet)  # Add it to the scene		
		#NOTE: the bullet spawn point note is rotated differently from the rest of the player to ensure bullets shoot forward properly		
		bullet.transform.origin = $Bullet_Spawn_Point.global_transform.origin
		#if aiming, aim towards camera, if not, aim towards where the model is facing
		if Input.is_action_pressed("aim"):
			# Get the forward direction of the camera
			var camera = $Camera_Controller
			var camera_origin = camera.global_transform.origin
			var camera_direction = camera.global_transform.basis.z.normalized()
			# Create a target point far in front of the camera
			var aim_target = camera_origin + camera_direction * 1000
			# Point the bullet toward that target
			bullet.look_at(aim_target, Vector3.UP)
#			bullet.transform.basis = $Camera_Controller.transform.basis  # Set the bullet's rotation to match the camera rotation
		else:
			bullet.transform.basis = $Bullet_Spawn_Point.global_transform.basis  # Set the bullet's rotation to match the player rotation
#		attack_cooldown = firing_rate


	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	#new Vector3 direction, taking into account user inputs and the camera rotation

	var camera_basis = $Camera_Controller.transform.basis
	# Flatten the camera's basis by ignoring the vertical component
	camera_basis.y = Vector3(0, 1, 0)  # Ensure "up" remains vertical
	camera_basis = camera_basis.orthonormalized()

	var direction = (camera_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	#rotate character to be facing same direction as camera when moving:
	if input_dir != Vector2(0,0):
		var rotate_character_dgrees_y = $Camera_Controller.rotation_degrees.y - rad_to_deg(input_dir.angle()) - 90
#UPD: now rotate the whole chracter instead of only the mesh
#		$MeshInstance3D.rotation_degrees.y = rotate_character_dgrees_y
		rotation_degrees.y = rotate_character_dgrees_y

#commented out for now to avoid clipping
#		$CollisionShape3D.rotation_degrees.y = rotate_character_dgrees_y
		
	#update velocity and move character
	if direction:
		movement_velocity.x = direction.x * speed
		movement_velocity.z = direction.z * speed
	else:
		movement_velocity.x = move_toward(movement_velocity.x, 0, speed)
		movement_velocity.z = move_toward(movement_velocity.z, 0, speed)

	# Apply knockback with exponential decay

	# Apply movement
	velocity.x = movement_velocity.x + knockback.x
	velocity.y = movement_velocity.y + knockback.y
	velocity.z = movement_velocity.z + knockback.z

	knockback *= exp(-knockback_decay * delta)  # Exponential decay for knockback

	# Prevent tiny knockback lingering
	if knockback.length() < min_knockback_threshold:
		knockback = Vector3.ZERO

	# If aiming, rotate character to match camera direction (ignoring vertical)
	if Input.is_action_pressed("aim"):
		var rotate_character_dgrees_y2 = $Camera_Controller.rotation_degrees.y
#UPD: now rotate the whole chracter instead of only the mesh
#		$MeshInstance3D.rotation_degrees.y = rotate_character_dgrees_y
		direction = camera_basis
		rotation_degrees.y = rotate_character_dgrees_y2
	
	move_and_slide()
	
	#push rigidbody objects:

	for collision_index in get_slide_collision_count():
		var collision := get_slide_collision(collision_index)
		if collision.get_collider() is RigidBody3D:
			collision.get_collider().apply_central_impulse(-collision.get_normal() * push_force)

	#Make camera controller gradually match the position of player
	$Camera_Controller.position = lerp($Camera_Controller.position,position,camera_speed)
	
# Function to apply knockback from an attack
func apply_knockback(force: Vector3):
	#if falling and knockback is positive, reset falling
	if movement_velocity.y < 0 and force.y > 0:
		movement_velocity.y = 0
	
	knockback += force	

func _on_health_changed(current, max):
#	print("Health changed: %d/%d" % [current, max])
	Globals.HUD.update_healthbar()

func _on_health_depleted():
	#reload scene if health runs out
	print("Health depleted!")
	get_tree().reload_current_scene()
#	queue_free()  # Example: destroy the entity
