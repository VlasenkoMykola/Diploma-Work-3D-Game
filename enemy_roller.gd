extends RigidBody3D

@export var player: NodePath  # Drag the player node here in the Inspector
@export var roll_force: float = 50  # Rolling speed (force applied each second, split across physics processes due to delta)
@export var jump_force: float = 40.0  # Force applied when jumping
@export var jump_interval: float = 2.0  # Time between attempted jumps
@export var collision_damage: float = 10.0 #minimum damage when colliding with a player
@export var collision_damage_per_velocity: float = 2 #do additional damage per current speed value (calculated during collision)

@export var collision_player_knockback: float = 10.0 #minimum knockback when colliding with a player
@export var collision_player_knockback_per_velocity: float = 2 #do additional player knockback per current speed value (calculated during collision)

var collision_attack_cooldown: float = 0.0 #seconds until the enemy can damage player with collisions again
@export var collision_attack_max_cooldown: float = 1.0 #seconds until the enemy can damage player with collisions again

var is_on_ground: bool = false  # Track if enemy is on the ground

var player_node: Node3D
var target_position: Vector3
var can_see_player: bool = false

@export var detection_radius: float = 20.0  # Radius of detection
var detection_time_left: float = 0.0#how many seconds are left until the enemy stops seeing the player after players leaves the detection area
@export var max_detection_time: float = 2.0#how many seconds are left until the enemy stops seeing the player after players leaves the detection area

# Components
var detection_area: Area3D
var ground_check: RayCast3D
var jump_timer: Timer

func _ready():
	player_node = Globals.player
	detection_area = $Area3D_Detection_Area
	ground_check = $GroundCheck_Raycast  # RayCast3D to detect ground
	jump_timer = $JumpTimer  # Timer for jumping
	
	# necessary to get collisions working properly:
	# Enable collision monitoring
	contact_monitor = true
	max_contacts_reported = 5  # Set to a reasonable number of contacts


	# Connect signals

	detection_area.body_entered.connect(_area_on_body_entered)
	detection_area.body_exited.connect(_area_on_body_exited)
	jump_timer.timeout.connect(_attempt_jump)

	# Connect the health_changed signal
	$HealthComponent.connect("health_changed", Callable(self, "_on_health_changed"))
	# Connect the health_depleted signal
	$HealthComponent.connect("health_depleted", Callable(self, "_on_health_depleted"))


	# Set up Area3D collision shape
	$Area3D_Detection_Area/CollisionShape3D.shape.radius = detection_radius

	# Start jump timer
	jump_timer.wait_time = jump_interval
	jump_timer.start()

func _physics_process(delta):
	player_node = Globals.player
	
	collision_attack_cooldown -= delta

	# Ensure RayCast3D always points downward
	ground_check.global_transform = Transform3D(Basis(), global_position)
	ground_check.target_position = Vector3(0, -1, 0)  # Always point straight down

	# Check if enemy is touching the ground
	is_on_ground = ground_check.is_colliding()
	
	# when player is out of sight, count down the time before enemies stop pursuing

	if can_see_player == false:
		detection_time_left -= delta

	# Move only if on ground
#	if can_see_player and is_on_ground:

#use detection_time_left so enemies can still chase the player for some time once the player leaves the sight range
#	if detection_time_left > 0 and is_on_ground:
#now can move in the air, for better jumping
	if detection_time_left > 0:
		target_position = player_node.global_position
		roll_towards_target(delta)

func roll_towards_target(delta):
	var direction = (target_position - global_position).normalized()
	#rolling only gives horizontal motion, not vertical
	#previously the roll code only worked on the ground, but not it works in mid-air too, just without vertical movement
	direction.y = 0  # Remove vertical influence to avoid unwanted lift
	var velocity = direction * roll_force * delta
	
	apply_central_impulse(velocity)

func _attempt_jump():
	# Ensure player exists, is detected, and is above the enemy before jumping
	if player_node and detection_time_left > 0 and player_node.global_position.y > global_position.y + 1.0 and is_on_ground:
		# Apply only vertical force for the jump
		apply_impulse(Vector3(0, jump_force, 0))

func _integrate_forces(state):
	for i in range(state.get_contact_count()):
		var body = state.get_contact_collider_object(i)

		if body:
#			print("Collided with:", body.name)  # Debug print

			if body == player_node:
#				print("Collided with Player!")  # Debug print
				
				# Calculate enemy speed
				var enemy_speed = linear_velocity.length()  # Get magnitude of velocity
				
				# Scale damage based on speed
				var scaled_damage = collision_damage + (collision_damage_per_velocity * enemy_speed) # Adjust scaling as needed

				# Check if the object has a HealthComponent, then apply scaled damage
				if collision_attack_cooldown <= 0 and body.has_node("HealthComponent"):
					var health_component = body.get_node("HealthComponent")
					health_component.take_damage(scaled_damage)
					collision_attack_cooldown = collision_attack_max_cooldown
					print("Dealt ", scaled_damage, " damage based on speed: ", enemy_speed)
					
					#apply knockback

					var knockback_direction = (body.global_transform.origin - self.global_transform.origin).normalized()
					var knockback_force = collision_player_knockback + (collision_player_knockback_per_velocity * enemy_speed) # Adjust scaling as needed
					var knockback_vector = knockback_direction * knockback_force
					body.apply_knockback(knockback_vector)

func _area_on_body_entered(body):
	if body == player_node:
		can_see_player = true
		detection_time_left = max_detection_time

func _area_on_body_exited(body):
	if body == player_node:
		can_see_player = false

#for when enemy is hit by player attacks while player is outside vision range
func provoked_by_attack():
	detection_time_left = max_detection_time	

func _on_health_changed(current, max):
#TODO: make it adjust his own healthbar instead!!!
#	print("Health changed: %d/%d" % [current, max])
	Globals.HUD.update_healthbar()

func _on_health_depleted():
	queue_free()  # destroy the enemy
