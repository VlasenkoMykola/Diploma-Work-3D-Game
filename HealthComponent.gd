extends Node

#this is a component node meant to be copied into other scenes

@export var max_health: float = 100
@export var health: float = 100

# Signal emitted when health changes
signal health_changed(health, max_health)
# a more specific signal for when damage is taken
signal damage_taken(damage)
# Signal emitted when health reaches 0
signal health_depleted

# Called when the node is added to the scene
func _ready():
	# Ensure current health doesn't exceed max health on initialization
	health = min(health, max_health)

# Adjust health by a given amount (positive or negative)
func adjust_health(amount: float):
	health += amount
	# Ensure current health doesn't exceed max health
	health = min(health, max_health)
	emit_signal("health_changed", health, max_health)
#adjust_health no longer kills entities by default, that is saved for the take_damage function
#	if current_health <= 0:
#		emit_signal("health_depleted")

# Fully restore health
func restore_health():
	health = max_health
	emit_signal("health_changed", health, max_health)

# Deal damage, reducing health by a fixed amount and triggering signals
func take_damage(amount: float):
	adjust_health(-amount)
	emit_signal("damage_taken", amount)
	if health <= 0:
		emit_signal("health_depleted")

# Heal by a fixed amount
func heal(amount: float):
	adjust_health(amount)
