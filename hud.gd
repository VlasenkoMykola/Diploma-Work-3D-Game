extends CanvasLayer

var bar_red = preload("res://resources/images/barHorizontal_red.png")
var bar_green = preload("res://resources/images/barHorizontal_green.png")
var bar_yellow = preload("res://resources/images/barHorizontal_yellow.png")
var bar_black = preload("res://resources/images/barHorizontal_black.png")

var player_UI_initialized = false

# Called when the node enters the scene tree for the first time.
func _ready():
	Globals.HUD = self  # Assign this instance to the global singleton
	update_coins()

func _process(delta):
	#wait until the player instance is already defined before setting player-specific UI stuff:
	if Globals.player != null and player_UI_initialized == false:
		initialize_player_ui()
	
func initialize_player_ui():
	player_UI_initialized = true
	$Healthbar_player/HealthBar.texture_under = bar_black
#	hide()
#	if get_parent() and get_parent().get("MaxHP"):

	var health_component = Globals.player.get_node("HealthComponent")

	$Healthbar_player/HealthBar.value = health_component.health
	$Healthbar_player/HealthBar.max_value = health_component.max_health
#	print($Healthbar_player/HealthBar.value)
#	print($Healthbar_player/HealthBar.max_value)
	
	update_healthbar()
	
func update_healthbar():
#	print("health updated")

	var health_component = Globals.player.get_node("HealthComponent")

	#updating current/max hp:

	$Healthbar_player/HealthBar.value = health_component.health
	$Healthbar_player/HealthBar.max_value = health_component.max_health
	
	#show rounded down hp values
	var label_hp_text = str(floor(health_component.health)) + "/" + str(floor(health_component.max_health))
	
	$Healthbar_player/Label_HP.text = label_hp_text
	
	$Healthbar_player/HealthBar.texture_progress = bar_green
	if $Healthbar_player/HealthBar.value < $Healthbar_player/HealthBar.max_value * 0.7:
		$Healthbar_player/HealthBar.texture_progress = bar_yellow
	if $Healthbar_player/HealthBar.value < $Healthbar_player/HealthBar.max_value * 0.35:
		$Healthbar_player/HealthBar.texture_progress = bar_red

func update_coins():
	$Panel/Coins_Counter.text = "Money: " + str(Globals.coins) + "/" + str(Globals.necessary_coins)
		
#hiding/showins is unused for the player for now since the HP is in the top-left of the screen instead of above the player
#However, this could code be used in common enemy healthbars instead
#	if $Healthbar_player/HealthBar.value >= $HealthBar.max_value:
#		hide()
#	if $Healthbar_player/HealthBar.value < $HealthBar.max_value:
#		show()
