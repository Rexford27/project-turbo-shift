extends Node3D
class_name VehicleStats
@onready var physics_ball: PhysicsBallController = $"../../PhysicsBall"
@onready var control_frame: ControlFrame = $"../../ControlFrame"

@export var gravity = 10

@export_group("boat stats")
@export var boat_steer_speed = 1.2
#speed settings
@export var boat_max_forward_speed: float = 25.0
@export var boat_max_reverse_speed: float = 15.0

@export var boat_acceleration_force: float = 25
@export var boat_brake_force: float = 15

#sliding settings
@export var boat_side_grip_force: float = 2
@export var boat_drag: float = 0.8
@export var boat_max_total_speed: float = 25.0

@export_group("boat bouyancy")
@export var buoyancy_strength: float = 80.0
@export var submersion_depth: float = 2.5
@export var vertical_damping: float = 3.0#8.0
@export var water_drag: float = 2.0

@export_group("kart spring")
@export var spring_rest_distance: float = 0.8
@export var spring_strength: float = 60.0
@export var spring_damping: float = 8.0
@export var spring_max_force: float = 90.0



#flight
@export_group("air stats")
@export var flight_direction_grip: float = 20
var flight_correction_time: float = 0.35
var flight_deadzone_speed: float = 0.4


func set_vehicle_artibutes(
	steer_speed: float,
	max_forward_speed: float,
	max_reverse_speed: float,
	acceleration_force: float,
	brake_force: float,
	side_grip_force: float,
	drag: float
) -> void:
	self.boat_steer_speed = steer_speed
	self.max_forward_speed = max_forward_speed
	self.max_reverse_speed = max_reverse_speed
	self.acceleration_force = acceleration_force
	self.brake_force = brake_force
	self.side_grip_force = side_grip_force
	self.drag = drag
