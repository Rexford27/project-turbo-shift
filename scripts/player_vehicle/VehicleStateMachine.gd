extends Node
class_name VehicleStateMachine

enum VehicleMode {
	KART,
	BOAT,
	AIR
}

@export var start_mode: VehicleMode = VehicleMode.KART

# The ControlFrame has enable_flight on it.
@export var control_frame: ControlFrame

# Visual nodes
@export var kart_visual: Node3D
@export var boat_visual: Node3D
@export var air_visual: Node3D

# Collision shapes
@export var kart_shape: CollisionShape3D
@export var boat_shape: CollisionShape3D
@export var air_shape: CollisionShape3D

# Optional movement scripts
@export var kart_movement: Node
@export var boat_movement: Node
@export var air_movement: Node

var current_mode: VehicleMode = VehicleMode.KART


func _ready() -> void:
	change_mode(start_mode)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed and not event.echo:
			if event.keycode == KEY_1:
				change_mode(VehicleMode.KART)

			elif event.keycode == KEY_2:
				change_mode(VehicleMode.BOAT)

			elif event.keycode == KEY_3:
				change_mode(VehicleMode.AIR)


func change_mode(new_mode: VehicleMode) -> void:
	current_mode = new_mode

	disable_everything()

	if new_mode == VehicleMode.KART:
		enable_kart_mode()

	elif new_mode == VehicleMode.BOAT:
		enable_boat_mode()

	elif new_mode == VehicleMode.AIR:
		enable_air_mode()


func disable_everything() -> void:
	# Hide all visuals
	set_visual(kart_visual, false)
	set_visual(boat_visual, false)
	set_visual(air_visual, false)

	# Disable all collision shapes
	set_collision(kart_shape, false)
	set_collision(boat_shape, false)
	set_collision(air_shape, false)

	# Disable all movement scripts
	set_movement(kart_movement, false)
	set_movement(boat_movement, false)
	set_movement(air_movement, false)


func enable_kart_mode() -> void:
	set_visual(kart_visual, true)
	set_collision(kart_shape, true)
	set_movement(kart_movement, true)

	if control_frame != null:
		control_frame.enable_flight = false

	print("Vehicle Mode: KART")


func enable_boat_mode() -> void:
	set_visual(boat_visual, true)
	set_collision(boat_shape, true)
	set_movement(boat_movement, true)

	if control_frame != null:
		control_frame.enable_flight = false

	print("Vehicle Mode: BOAT")


func enable_air_mode() -> void:
	set_visual(air_visual, true)
	set_collision(air_shape, true)
	set_movement(air_movement, true)

	if control_frame != null:
		control_frame.enable_flight = true

	print("Vehicle Mode: AIR")


func set_visual(visual_node: Node3D, is_visible: bool) -> void:
	if visual_node == null:
		return

	visual_node.visible = is_visible


func set_collision(collision_shape: CollisionShape3D, is_enabled: bool) -> void:
	if collision_shape == null:
		return

	collision_shape.disabled = not is_enabled


func set_movement(movement_node: Node, is_enabled: bool) -> void:
	if movement_node == null:
		return

	movement_node.set_process(is_enabled)
	movement_node.set_physics_process(is_enabled)
	movement_node.set_physics_process(is_enabled)
	
