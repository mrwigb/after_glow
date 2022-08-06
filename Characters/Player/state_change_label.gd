extends Label

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.



func _on_Player__changed_state(new_state_string, _new_state_id):
	self.text = new_state_string
