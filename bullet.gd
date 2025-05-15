extends Area3D

@export var is_player_bullet: bool = false
@export var damage: int = 10
@export var physics_force: int = 10
@export var speed: float = 30
#seconds until a bullet is auto-deleted, to ensure the game doesn't need to calculate bullets that fly offscreen for too long
@export var lifespan: float = 15.0

var velocity: Vector3
var lifetime: float = 0.0

func _ready():
#UPD: now it's set in _process repeatedly
#	# Set initial velocity
#	velocity = global_transform.basis.z * speed

	# Start a timer to destroy the bullet after its lifespan
	await get_tree().create_timer(lifespan).timeout
	queue_free()

func _process(delta: float):
	# Set velocity based on the forward direction of the bullet (its z-axis) and speed
	velocity = global_transform.basis.z * speed
	# Move the bullet in a straight line
	global_transform.origin += velocity * delta

func _on_body_entered(body):
	if is_player_bullet and body.is_in_group("Player"):
		#no self-collision for player bullets
		return
#	if not is_player_bullet and area.get_parent().is_in_group("Enemy"):
#		return

	#if hitting a rigidbody, apply force:

	if body is RigidBody3D:#only trigger push code on rigidbodies
		## Calculate the direction and force strength
		#var direction = (body.global_transform.origin - global_transform.origin).normalized()

		# Use the bullet's velocity direction to apply the force
		var direction = velocity.normalized()

		# Apply the force
		body.apply_central_impulse(direction * physics_force)

	# Check if the object has a HealthComponent, then apply damage
	if body.has_node("HealthComponent"):
		var health_component = body.get_node("HealthComponent")
		health_component.take_damage(damage)
	
	#used for enemies to make them aware of the player even when outside vision range
	if body.has_method("provoked_by_attack"):
		body.provoked_by_attack()

#	print("bullet touched")

	# Destroy the bullet on collision
	queue_free()
