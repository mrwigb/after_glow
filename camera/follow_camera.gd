extends Camera2D

onready var top_left = $Bounds/top_left
onready var bot_right = $Bounds/bot_right

func _ready():
	self.limit_top = top_left.global_position.y
	self.limit_left = top_left.global_position.x
	self.limit_bottom = bot_right.global_position.y
	self.limit_right = bot_right.global_position.x
