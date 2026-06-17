extends Node
class_name VehicleStats2


@export_group("Speed")

## Top speed while driving forward.
## Higher = faster kart.
@export var max_forward_speed: float = 28.0

## Top speed while reversing.
## Usually lower than forward speed.
@export var max_reverse_speed: float = 12.0

## Hard speed limit for the vehicle.
## Stops the kart from going too fast from boosts, hills, or bugs.
@export var max_total_speed: float = 40.0


@export_group("Movement")

## How hard the kart pushes forward when accelerating.
## Higher = reaches top speed faster.
@export var acceleration_force: float = 70.0

## How hard the kart pushes backward when reversing.
## Higher = reverses faster.
@export var reverse_force: float = 40.0

## How hard the kart slows down when pressing brake/reverse while moving forward.
## Higher = stops faster.
@export var brake_force: float = 65.0


@export_group("Steering")

## How fast the visual body turns while grounded.
## Higher = sharper turning.
@export var turn_speed: float = 4.5

## How fast the visual body turns while airborne.
## Usually lower than normal turn speed.
@export var air_turn_speed: float = 2.0

## The vehicle must move at least this fast before steering works.
## Lower = can turn almost while standing still.
@export var min_speed_to_turn: float = 0.3


@export_group("Grip")

## How strongly the kart fights sideways sliding.
## Higher = more grip.
## Lower = more drift/sliding.
@export var side_grip_force: float = 22.0

## Drag/friction while on the ground.
## Higher = slows down faster when not accelerating.
@export var ground_drag: float = 1.2

## Drag/friction while in the air.
## Usually lower than ground drag.
@export var air_drag: float = 0.15


@export_group("Ground")

## Extra force pushing the ball toward the ground.
## Higher = sticks to slopes better.
## Too high = can feel heavy or glued down.
@export var ground_snap_force: float = 35.0
