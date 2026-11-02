
extends Node3D

signal todos_rivais_derrotados

@export var rival_model: PackedScene
@export var radius: float = 5.0

@export var velocidade_rivais: float = 1.5
@export var distancia_ataque: float = 1.8
@export var dano_rival: int = 10
@export var intervalo_ataque: float = 1.5

@export var vida_inicial_rival: int = 3
@export var alcance_catana: float = 2.5

@export var distancia_separacao: float = 1.5
@export var forca_separacao: float = 2.5

var pode_perseguir: bool = false
var rivals: Array[Node3D] = []
var jogador_alvo: Node3D = null

var vida_rivais: Dictionary = {}
var temporizadores_ataque: Dictionary = {}
var rivais_a_recuar: Dictionary = {}


func iniciar_confronto() -> void:
	pode_perseguir = true
	print("Os rivais começaram a perseguir o jogador!")


func appear_around(player: Node3D, player_visual: Node3D) -> void:
	if rival_model == null:
		print("ERRO: Nenhum modelo de rival foi atribuído!")
		return

	if player == null or player_visual == null:
		print("ERRO: Jogador ou Visual não encontrado!")
		return

	# Limpar rivais anteriores.
	for rival in rivals:
		if is_instance_valid(rival):
			rival.queue_free()

	rivals.clear()
	vida_rivais.clear()
	temporizadores_ataque.clear()
	rivais_a_recuar.clear()

	jogador_alvo = player
	pode_perseguir = false

	var forward: Vector3 = player_visual.global_basis.z
	forward.y = 0
	forward = forward.normalized()

	var right: Vector3 = player_visual.global_basis.x
	right.y = 0
	right = right.normalized()

	# Seis posições em semicírculo à frente do jogador.
	var angulos: Array[float] = [-75.0, -45.0, -15.0, 15.0, 45.0, 75.0]

	for i in range(6):
		var rival := rival_model.instantiate() as Node3D

		if rival == null:
			continue

		add_child(rival)

		var angulo: float = deg_to_rad(angulos[i])
		var direcao: Vector3 = (forward * cos(angulo)) + (right * sin(angulo))
		var posicao: Vector3 = player.global_position + direcao * radius

		rival.global_position = posicao
		rival.look_at(player.global_position, Vector3.UP)
		rival.rotate_y(PI)

		rivals.append(rival)

		var id: int = rival.get_instance_id()
		vida_rivais[id] = vida_inicial_rival
		temporizadores_ataque[id] = randf_range(0.0, intervalo_ataque)
		rivais_a_recuar[id] = false

	print("Foram criados ", rivals.size(), " rivais!")


func _process(delta: float) -> void:
	if not pode_perseguir or jogador_alvo == null:
		return

	if not is_instance_valid(jogador_alvo):
		return

	for rival in rivals:
		if not is_instance_valid(rival):
			continue

		var id: int = rival.get_instance_id()

		# Não movimentar o rival enquanto estiver a recuar.
		if rivais_a_recuar.get(id, false):
			continue

		var direcao: Vector3 = jogador_alvo.global_position - rival.global_position
		direcao.y = 0

		var distancia: float = direcao.length()

		if distancia > 0.01:
			direcao = direcao.normalized()

		# Separar os rivais quando estão demasiado próximos.
		var forca: Vector3 = Vector3.ZERO

		for outro in rivals:
			if outro == rival or not is_instance_valid(outro):
				continue

			var diferenca: Vector3 = rival.global_position - outro.global_position
			diferenca.y = 0

			var distancia_entre: float = diferenca.length()

			if distancia_entre > 0.01 and distancia_entre < distancia_separacao:
				forca += diferenca.normalized() * (
					distancia_separacao - distancia_entre
				)

		if forca.length() > 0:
			forca = forca.normalized() * forca_separacao

		if distancia > distancia_ataque:
			var movimento: Vector3 = (direcao + forca * 0.3).normalized()
			rival.global_position += movimento * velocidade_rivais * delta

		# Virar o rival na direção do jogador.
		if distancia > 0.1:
			rival.look_at(jogador_alvo.global_position, Vector3.UP)
			rival.rotate_y(PI)

		# Atacar o jogador quando estiver próximo.
		if distancia <= distancia_ataque:
			temporizadores_ataque[id] = (
				temporizadores_ataque.get(id, 0.0) - delta
			)

			if temporizadores_ataque[id] <= 0.0:
				if jogador_alvo.has_method("receber_dano"):
					jogador_alvo.receber_dano(dano_rival)
					print("Um rival atacou o jogador!")

				temporizadores_ataque[id] = intervalo_ataque


func attack_nearest(player: Node3D) -> void:
	if player == null:
		return

	var rival_mais_proximo: Node3D = null
	var menor_distancia: float = alcance_catana

	# Encontrar o rival mais próximo dentro do alcance da catana.
	for rival in rivals:
		if not is_instance_valid(rival):
			continue

		var distancia: float = player.global_position.distance_to(
			rival.global_position
		)

		if distancia < menor_distancia:
			menor_distancia = distancia
			rival_mais_proximo = rival

	if rival_mais_proximo == null:
		print("Nenhum rival ao alcance!")
		return

	var id: int = rival_mais_proximo.get_instance_id()

	if not vida_rivais.has(id):
		vida_rivais[id] = vida_inicial_rival

	vida_rivais[id] -= 1

	print("Rival atingido! Vida restante: ", vida_rivais[id])

	# Derrotar o rival quando a vida chegar a zero.
	if vida_rivais[id] <= 0:
		vida_rivais.erase(id)
		temporizadores_ataque.erase(id)
		rivais_a_recuar.erase(id)

		rivals.erase(rival_mais_proximo)
		rival_mais_proximo.queue_free()

		print("Rival derrotado!")

		# Verificar se todos os seis rivais foram derrotados.
		if rivals.is_empty():
			pode_perseguir = false

			print("CONFRONTO TERMINADO!")
			print("A rivalidade aumentou. O campo não será reconstruído.")

			todos_rivais_derrotados.emit()

		return

	# Se ainda estiver vivo, o rival recua.
	print("O RIVAL VAI RECUAR!")
	reagir_ao_golpe(rival_mais_proximo, player)


func reagir_ao_golpe(rival: Node3D, player: Node3D) -> void:
	if not is_instance_valid(rival) or not is_instance_valid(player):
		return

	var id: int = rival.get_instance_id()

	if rivais_a_recuar.get(id, false):
		return

	rivais_a_recuar[id] = true

	var direcao: Vector3 = rival.global_position - player.global_position
	direcao.y = 0

	if direcao.length() < 0.01:
		direcao = Vector3.BACK
	else:
		direcao = direcao.normalized()

	var posicao_original: Vector3 = rival.global_position
	var posicao_recuo: Vector3 = posicao_original + direcao * 0.7

	var tween := create_tween()

	tween.tween_property(
		rival,
		"global_position",
		posicao_recuo,
		0.15
	)

	tween.tween_interval(0.25)

	tween.tween_property(
		rival,
		"global_position",
		posicao_original,
		0.2
	)

	await tween.finished

	if is_instance_valid(rival):
		rivais_a_recuar.erase(id)
