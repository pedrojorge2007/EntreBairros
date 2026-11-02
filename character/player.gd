
extends CharacterBody3D

## Movimento
@export_group("Movement")
@export var walk_speed: float = 4.0
@export var sprint_speed: float = 7.0
@export var acceleration: float = 12.0
@export var rotation_speed: float = 10.0



@export_group("Equipamento")
@export var catana_modelo: PackedScene
@export_group("Posição da Catana")
@export var catana_posicao := Vector3.ZERO
@export var catana_rotacao := Vector3.ZERO


@export_group("Physics")
@export var gravity: float = 9.8
@export var jump_velocity: float = 4.5

## Referências
@onready var visual: Node3D = $Visual
@onready var camera_pivot: Node3D = $CameraPivot
@onready var interaction_ray: RayCast3D = $Visual/InteractionRay

@onready var ponto_arma: BoneAttachment3D = $Visual/Personagem3D/Skeleton3D/MaoDireita

## Animação 3D
@onready var animation_player: AnimationPlayer = $Visual/Personagem3D/AnimationPlayer
var pode_atacar := true
@export_group("Combate")
@export var vida_maxima: int = 100

var vida_atual: int = 100
var pode_receber_dano: bool = true
func _physics_process(delta: float) -> void:
	handle_gravity(delta)
	handle_jump()
	handle_movement(delta)
	move_and_slide()


## Aplica a gravidade
func handle_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		if velocity.y < 0:
			velocity.y = 0


## Movimento horizontal do Player
func handle_movement(delta: float) -> void:
	var input_vector := Input.get_vector(
		"move_left", "move_right",
		"move_forward", "move_backward"
	)

	print("INPUT: ", input_vector, " | VELOCIDADE: ", velocity)
	var yaw_basis := Basis(Vector3.UP, camera_pivot.global_rotation.y)

	var direction := yaw_basis * Vector3(
		input_vector.x, 0.0, input_vector.y
	)

	direction = direction.normalized()

	var current_speed := walk_speed

	if Input.is_action_pressed("sprint"):
		current_speed = sprint_speed

	var target_velocity := direction * current_speed

	velocity.x = move_toward(
		velocity.x, target_velocity.x, acceleration * delta
	)

	velocity.z = move_toward(
		velocity.z, target_velocity.z, acceleration * delta
	)

	# Rotação do protagonista
	if direction.length() > 0.1:
		var target_angle := atan2(direction.x, direction.z)

		visual.rotation.y = lerp_angle(
			visual.rotation.y,
			target_angle,
			rotation_speed * delta
		)

	# Animação de andar
	update_animation(direction)


func update_animation(direction: Vector3) -> void:
	# Não interromper o ataque
	if not pode_atacar:
		return

	if animation_player == null:
		return

	if direction.length() > 0.1:
		if animation_player.has_animation("mixamo_com"):
			if animation_player.current_animation != "mixamo_com":
				animation_player.play("mixamo_com")
	else:
		if animation_player.is_playing():
			animation_player.pause()
	if animation_player == null:
		print("ERRO: AnimationPlayer não encontrado!")
		return

	print("Animações disponíveis: ", animation_player.get_animation_list())

	if direction.length() > 0.1:
		if animation_player.has_animation("mixamo_com"):
			if not animation_player.is_playing():
				animation_player.play("mixamo_com")
		else:
			print("ERRO: A animação mixamo.com não foi encontrada!")
	else:
		if animation_player.is_playing():
			animation_player.pause()


## Salto
func handle_jump() -> void:
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity


## Recebe o comando de interação
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and not event.is_echo():
		interact_with_object()
		get_viewport().set_input_as_handled()
	if event.is_action_pressed("attack") and not event.is_echo():
		atacar()
		get_viewport().set_input_as_handled()


## Interação com NPCs e materiais
func interact_with_object() -> void:
	interaction_ray.force_raycast_update()

	print("A testar deteção...")

	if interaction_ray.is_colliding():
		var target = interaction_ray.get_collider()

		print("OBJETO DETETADO: ", target.name)

		if target.has_method("interact"):
			target.interact(self)
		else:
			print("O objeto não tem a função interact()")
	else:
		print("NÃO DETETOU NADA")


func _ready() -> void:
	interaction_ray.enabled = true
	interaction_ray.collide_with_bodies = true
	interaction_ray.target_position = Vector3(0, 0, 3)
	interaction_ray.collision_mask = 0xFFFFFFFF
	vida_atual = vida_maxima
	print("RAIO ATIVO: ", interaction_ray.enabled)
	print("MÁSCARA: ", interaction_ray.collision_mask)
	print("ANIMATION PLAYER: ", animation_player)
	if animation_player != null:
		print("LISTA DE ANIMAÇÕES: ", animation_player.get_animation_list())
	equipar_personagem()


func equipar_personagem() -> void:
	if catana_modelo != null:
		var catana = catana_modelo.instantiate()
		ponto_arma.add_child(catana)
		catana.position = Vector3(0.5, 0.1, 0.0)
		catana.rotation_degrees = Vector3(0, 180, 0)
		catana.scale = Vector3(0.2, 0.2, 0.2)
		
		print("Posição aplicada: ", catana.position)
		print("Rotação aplicada: ", catana.rotation_degrees)

func atacar() -> void:
	if not pode_atacar:
		return

	pode_atacar = false

	animation_player.play("Stable Sword Outward Slash/mixamo_com")

	# Esperar pelo momento do impacto
	await get_tree().create_timer(1).timeout

	var grupo_rival = get_node_or_null("../../GrupoRival")

	if grupo_rival != null:
		grupo_rival.attack_nearest(self)

	await animation_player.animation_finished

	pode_atacar = true
func receber_dano(quantidade: int) -> void:
	if not pode_receber_dano:
		return

	vida_atual -= quantidade
	vida_atual = max(vida_atual, 0)

	print("PROTAGONISTA ATINGIDO! Vida: ", vida_atual)

	pode_receber_dano = false

	await get_tree().create_timer(1.0).timeout

	pode_receber_dano = true

	if vida_atual <= 0:
		print("PROTAGONISTA DERROTADO!")
