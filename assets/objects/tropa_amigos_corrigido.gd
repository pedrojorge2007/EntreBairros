extends Node3D

# ==================================================
# CONFIGURAÇÕES
# ==================================================

@export var amigo_model: PackedScene

# Arrasta aqui o nó AudioStreamPlayer com a música do combate.
@export var musica_combate: AudioStreamPlayer

@export var velocidade_amigos: float = 3.0
@export var distancia_entre_amigos: float = 1.5
@export var distancia_combate: float = 0.25
@export var intervalo_entre_golpes: float = 0.5

# 🔴 ALTERAR AQUI apenas se o nome real da caminhada for diferente.
@export var animacao_caminhada: String = "mixamo_com"

# 🔴 ALTERAR AQUI apenas se o nome real do ataque for diferente.
@export var animacao_ataque: String = "Stable Sword Outward Slash/mixamo_com"

# Opcional: animação de repouso entre golpes. Se ficar vazio, a animação para.
@export var animacao_idle: String = ""

@export var inverter_frente_modelo: bool = true


# ==================================================
# VARIÁVEIS
# ==================================================

var amigos: Array[Node3D] = []
var grupo_rival: Node3D = null
var combate_ativo: bool = false

var tempos_ataque: Dictionary = {}      # id -> segundos até ao próximo golpe
var animation_players: Dictionary = {}  # id -> AnimationPlayer (cache)
var amigos_prontos: Dictionary = {}     # id -> true quando terminou a entrada
var alvos: Dictionary = {}              # id -> rival atual


# ==================================================
# APARECER COM OS CINCO AMIGOS (ENTRADA SEQUENCIAL)
# ==================================================

func aparecer_com_amigos(player: Node3D, player_visual: Node3D) -> void:

	if amigo_model == null:
		print("ERRO: Modelo dos amigos não foi atribuído!")
		return

	if player == null or player_visual == null:
		print("ERRO: Jogador ou Visual não encontrado!")
		return

	amigos.clear()
	tempos_ataque.clear()
	animation_players.clear()
	amigos_prontos.clear()
	alvos.clear()
	combate_ativo = false

	var forward: Vector3 = -player_visual.global_basis.z
	forward.y = 0
	forward = forward.normalized()

	var right: Vector3 = player_visual.global_basis.x
	right.y = 0
	right = right.normalized()

	var posicoes: Array[float] = [-4.0, -2.0, 0.0, 2.0, 4.0]

	for i in range(5):

		var amigo := amigo_model.instantiate() as Node3D

		if amigo == null:
			continue

		add_child(amigo)
		amigo.scale = Vector3.ONE

		var id: int = amigo.get_instance_id()

		# Guardar o AnimationPlayer uma única vez (evita find_child por frame).
		var animation_player := amigo.find_child(
			"AnimationPlayer", true, false
		) as AnimationPlayer

		animation_players[id] = animation_player
		tempos_ataque[id] = 0.0
		amigos_prontos[id] = false

		# O ataque tem de tocar uma só vez, senão nunca "termina".
		if animation_player != null and animation_player.has_animation(animacao_ataque):
			animation_player.get_animation(animacao_ataque).loop_mode = Animation.LOOP_NONE

		var destino: Vector3 = (
			player.global_position
			- forward * 3.5
			+ right * posicoes[i]
		)

		var inicio: Vector3 = destino - forward * 5.0

		amigo.global_position = inicio
		orientar_direcao(amigo, forward)

		amigos.append(amigo)

		# Caminhada durante a entrada.
		tocar_animacao(animation_player, animacao_caminhada)

		var tween := create_tween()
		tween.tween_property(amigo, "global_position", destino, 0.8)

		# MANTIDO: entrada sequencial, um amigo de cada vez.
		await tween.finished

		if is_instance_valid(amigo):
			# Só agora o _process pode controlar este amigo.
			amigos_prontos[id] = true
			parar_ou_idle(animation_player)

		await get_tree().create_timer(0.4).timeout

	print("Os cinco amigos chegaram!")


# ==================================================
# ORIENTAR MODELO
# ==================================================

func orientar_direcao(amigo: Node3D, direcao: Vector3) -> void:

	if direcao.length_squared() < 0.001:
		return

	amigo.look_at(
		amigo.global_position + direcao,
		Vector3.UP
	)

	if inverter_frente_modelo:
		amigo.rotate_y(PI)


func orientar_amigo(amigo: Node3D, rival: Node3D) -> void:

	if not is_instance_valid(amigo):
		return

	if not is_instance_valid(rival):
		return

	var direcao: Vector3 = rival.global_position - amigo.global_position
	direcao.y = 0

	orientar_direcao(amigo, direcao)


# ==================================================
# INICIAR COMBATE
# ==================================================

func iniciar_combate(rivais: Node3D) -> void:

	if rivais == null:
		print("ERRO: GrupoRival não encontrado!")
		return

	grupo_rival = rivais
	combate_ativo = true

	tempos_ataque.clear()
	alvos.clear()

	for amigo in amigos:
		if is_instance_valid(amigo):
			tempos_ataque[amigo.get_instance_id()] = 0.0

	iniciar_musica_combate()

	print("A Tropa do Flamengo entrou no combate!")


# ==================================================
# ESCOLHER RIVAL (MANTÉM O ALVO ATÉ ELE SER ELIMINADO)
# ==================================================

func escolher_rival(amigo: Node3D, rivais: Array) -> Node3D:

	var id: int = amigo.get_instance_id()

	# Mantém o alvo atual se ainda existir e ainda estiver na lista.
	var atual = alvos.get(id)
	if is_instance_valid(atual) and rivais.has(atual):
		return atual

	# Caso contrário, procura o mais próximo.
	var rival_mais_proximo: Node3D = null
	var menor_distancia: float = INF

	for rival in rivais:

		if not is_instance_valid(rival):
			continue

		var distancia: float = amigo.global_position.distance_to(
			rival.global_position
		)

		if distancia < menor_distancia:
			menor_distancia = distancia
			rival_mais_proximo = rival

	alvos[id] = rival_mais_proximo
	return rival_mais_proximo


# ==================================================
# AUXILIARES DE ANIMAÇÃO
# ==================================================

# Toca a animação só se ainda não estiver a tocar.
func tocar_animacao(animation_player: AnimationPlayer, nome: String) -> void:

	if animation_player == null:
		return

	if not animation_player.has_animation(nome):
		print("ERRO: Animação não encontrada: ", nome)
		print("Animações disponíveis: ", animation_player.get_animation_list())
		return

	if animation_player.current_animation != nome or not animation_player.is_playing():
		animation_player.play(nome)


func parar_ou_idle(animation_player: AnimationPlayer) -> void:

	if animation_player == null:
		return

	if animacao_idle != "" and animation_player.has_animation(animacao_idle):
		tocar_animacao(animation_player, animacao_idle)
	else:
		animation_player.stop()


func a_atacar(animation_player: AnimationPlayer) -> bool:
	return (
		animation_player.is_playing()
		and animation_player.current_animation == animacao_ataque
	)


# ==================================================
# MOVIMENTO E ANIMAÇÕES DURANTE O COMBATE
# ==================================================

func _process(delta: float) -> void:

	if not combate_ativo:
		return

	if not is_instance_valid(grupo_rival):
		return

	var rivais = grupo_rival.get("rivals")

	if rivais == null or rivais.is_empty():
		return

	for i in range(amigos.size()):

		var amigo: Node3D = amigos[i]

		if not is_instance_valid(amigo):
			continue

		var id: int = amigo.get_instance_id()

		# Não mexer em quem ainda está na entrada sequencial (tween).
		if not amigos_prontos.get(id, false):
			continue

		var animation_player: AnimationPlayer = animation_players.get(id)

		if animation_player == null:
			continue

		var rival: Node3D = escolher_rival(amigo, rivais)

		if rival == null:
			continue

		# Cooldown entre golpes.
		tempos_ataque[id] = maxf(0.0, float(tempos_ataque.get(id, 0.0)) - delta)

		# Um golpe a decorrer não é interrompido: só orienta.
		if a_atacar(animation_player):
			orientar_amigo(amigo, rival)
			continue

		# Posição própria de cada amigo à volta do rival.
		var angulo: float = TAU * float(i) / float(maxi(amigos.size(), 1))

		var deslocamento := Vector3(
			cos(angulo) * distancia_entre_amigos,
			0.0,
			sin(angulo) * distancia_entre_amigos
		)

		var destino: Vector3 = rival.global_position + deslocamento
		destino.y = amigo.global_position.y

		var direcao: Vector3 = destino - amigo.global_position
		var distancia: float = direcao.length()

		# ------------------------------------------
		# CAMINHAR ATÉ AO RIVAL
		# ------------------------------------------

		if distancia > distancia_combate:

			# Passo limitado à distância restante (sem overshoot).
			var passo: float = minf(velocidade_amigos * delta, distancia)
			amigo.global_position += direcao.normalized() * passo

			orientar_amigo(amigo, rival)
			tocar_animacao(animation_player, animacao_caminhada)

		# ------------------------------------------
		# CHEGOU: A CAMINHADA É INTERROMPIDA PELO ATAQUE
		# ------------------------------------------

		else:

			orientar_amigo(amigo, rival)

			# Em cooldown: sai da caminhada e fica parado / em idle.
			if tempos_ataque[id] > 0.0:
				parar_ou_idle(animation_player)
				continue

			if not animation_player.has_animation(animacao_ataque):
				print("ERRO: Ataque não encontrado: ", animacao_ataque)
				print("Animações disponíveis: ", animation_player.get_animation_list())
				continue

			# play() substitui a caminhada na hora.
			animation_player.play(animacao_ataque)

			tempos_ataque[id] = (
				animation_player.get_animation(animacao_ataque).length
				+ intervalo_entre_golpes
			)

			print("Amigo ", i + 1, " atacou o rival!")


# ==================================================
# TERMINAR COMBATE
# ==================================================

func terminar_combate() -> void:

	combate_ativo = false

	for amigo in amigos:

		if not is_instance_valid(amigo):
			continue

		parar_ou_idle(animation_players.get(amigo.get_instance_id()))

	tempos_ataque.clear()
	alvos.clear()

	parar_musica_combate()

	print("A Tropa do Flamengo terminou o combate!")


# ==================================================
# MÚSICA DO COMBATE
# ==================================================

func iniciar_musica_combate() -> void:
	if musica_combate != null and musica_combate.stream != null:
		if not musica_combate.playing:
			musica_combate.play()


func parar_musica_combate() -> void:
	if musica_combate != null:
		musica_combate.stop()
