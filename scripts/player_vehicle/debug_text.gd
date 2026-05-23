extends Control
@onready var speed: Label = $speed
@onready var physics_ball: PhysicsBallController = $"../PhysicsBall"

func _physics_process(delta: float) -> void:
	speed.text = "speed : max is "+str(physics_ball.max_total_speed)+" current is : "+str(int(physics_ball.linear_velocity.length())) +"
	acceleration : "+str(physics_ball.acceleration_force)+"
	"
