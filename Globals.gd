extends Node

var coins : int = 0

#collect 100 coins to win the game
var necessary_coins : int = 100

var player : Node = null # Holds a reference to the player instance

var HUD : Node = null # Holds a reference to the HUD interface instance

func victory():
	coins = 0#reset coins
	get_tree().change_scene_to_file("res://start_screen.tscn")
	# Release the mouse cursor on victory
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
