extends Area3D

var rot_speed = 360#rotation speed in degrees per second

@export var coin_value = 1

# Called when the node enters the scene tree for the first time.
func _ready():
	set_coin_type(coin_value)#update the labels on the coin based on the variable

func set_coin_type(new_coin_value):
	coin_value = new_coin_value
	$Label3D_coinvalue.text = str(new_coin_value)
	$Label3D_coinvalue2.text = str(new_coin_value)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	rotate_y(deg_to_rad(rot_speed * delta))

func _on_body_entered(body):
	if body.is_in_group("Player"):		
		#increase coin count by 1
		Globals.coins += coin_value
		Globals.HUD.update_coins()
#		print(Globals.coins)

		#victory if you collect enough coins
		if Globals.coins >= Globals.necessary_coins:
			Globals.victory()
		queue_free()#coin is destroyed when touching a player
