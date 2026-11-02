extends CharacterBody3D

## Movimento
@export_group("Movement")
@export var walk_speed: float = 4.0
@export var sprint_speed: float = 7.0
@export var acceleration: float = 12.0
@export var rotation_speed: float = 10.0

## Física
@export_group("Physics")
@export var gravity: float = 9.8
@export var jump_velocity: float = 4.5

## Referências
@onready var visual: Node3D = $Visual
@onready var camera_pivot: Node3D = $CameraPivot


func _physics_process(delta: float) -> void:
	handle_gravity(delta)
	handle_jump()
	handle_movement(delta)
	move_and_slide()


## Aplica a gravidade
func handle_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta


## Movimento horizontal do Player
func handle_movement(delta: float) -> void:
	var input_vector := Input.get_vector(
		"move_left", "move_right", "move_forward", "move_backward"
	)

	# Direção relativa à câmera (apenas rotação horizontal)
	var yaw_basis := Basis(Vector3.UP, camera_pivot.global_rotation.y)
	var direction := yaw_basis * Vector3(input_vector.x, 0.0, input_vector.y)
	direction = direction.normalized()

	# Velocidade
	var current_speed := walk_speed
	if Input.is_action_pressed("sprint"):
		current_speed = sprint_speed

	var target_velocity := direction * current_speed

	# Aceleração e desaceleração
	velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * delta)

	# Rotação do modelo visual
	if direction.length() > 0.1:
		var target_angle := atan2(direction.x, direction.z)
		visual.rotation.y = lerp_angle(
			visual.rotation.y, target_angle, rotation_speed * delta
		)


## Salto
func handle_jump() -> void:
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

func _process(delta: float) -> void:
	var input_vector := Input.get_vector("move_backward","move_forward","move_left","move_right")
	if input_vector != Vector2.ZERO:
		print("Movimento", input_vector)
