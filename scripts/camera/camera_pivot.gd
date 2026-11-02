extends Node3D

@export_group("Camera Settings")
@export var mouse_sensitivity: float = 0.003
@export var min_vertical_angle: float =-40.0
@export var max_vertical_angle: float = 60.0

var camera_rotation_x: float = 0.0

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
func  _unhandled_input(event: InputEvent) -> void:
	#Capturar movimento do rato
	if event is InputEventMouseMotion:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		#Rotação horizontal
			rotate_y(
				-event.relative.x * mouse_sensitivity
			)
		#Rotação vertical
			camera_rotation_x -= (
				event.relative.y * mouse_sensitivity
			)
			camera_rotation_x = clamp(
				camera_rotation_x,
				deg_to_rad(min_vertical_angle),
				deg_to_rad(max_vertical_angle)
			)
			rotation.x = camera_rotation_x
	# Liberar ou recuperar o mouse
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
