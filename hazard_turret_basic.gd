extends RigidBody3D

var bullet_scene = preload("res://bullet.tscn")

var bullet_damage = 15

var firing_rate = 1 # in seconds
var attack_cooldown = 0


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	attack_cooldown -= delta
	if attack_cooldown <= 0:
		var bullet = bullet_scene.instantiate()  # Create an instance of the shockwave scene
		bullet.damage = bullet_damage
		get_tree().get_root().add_child(bullet)  # Add it to the scene				
		bullet.transform.origin = $Bullet_Spawn_Point.global_transform.origin
		bullet.transform.basis = $Bullet_Spawn_Point.global_transform.basis  # Set the bullet's rotation to match the turret's rotation
		attack_cooldown = firing_rate
