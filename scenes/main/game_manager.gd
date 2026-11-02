
extends Node

var current_mission := ""
var mission_active := false
var mission_failed := false
var rivals_spawned := false
var waiting_for_kito_dialogue := false
var confrontation_choice := ""

var materials := {
	"wood": 0,
	"iron": 0,
	"paint": 0
}

const TOTAL_MATERIALS := 3

var material_names := {
	"wood": "Madeira",
	"iron": "Ferro",
	"paint": "Tinta"
}


func _ready():
	var hud = get_tree().get_first_node_in_group("mission_label")

	if hud != null:
		hud.hide()

	var dialogue_ui = get_tree().get_first_node_in_group("dialog_ui")

	if dialogue_ui != null:
		if not dialogue_ui.choice_selected.is_connected(_on_choice_selected):
			dialogue_ui.choice_selected.connect(_on_choice_selected)

	# Ligar o sinal que avisa quando os seis rivais forem derrotados.
	var grupo_rival = get_node_or_null("../GrupoRival")

	if grupo_rival != null:
		if not grupo_rival.todos_rivais_derrotados.is_connected(_on_all_rivals_defeated):
			grupo_rival.todos_rivais_derrotados.connect(_on_all_rivals_defeated)
	else:
		print("ERRO: GrupoRival não encontrado!")

	call_deferred("play_intro")


func play_intro():
	var dialogue_ui = get_tree().get_first_node_in_group("dialog_ui")

	if dialogue_ui == null:
		print("DialogueUI não encontrado!")
		return

	var story = [
		{
			"name": "Narrador",
			"message": "Houve um tempo em que este campo era o coração do bairro. Crianças jogavam futebol e os jovens reuniam-se aqui."
		},
		{
			"name": "Narrador",
			"message": "Mas as rivalidades entre bairros começaram a crescer. O campo passou a ser território de confrontos entre grupos rivais."
		},
		{
			"name": "Narrador",
			"message": "As lutas de wowo tornaram-se frequentes. Havia facas, catanas, pedras e bidões usados como escudos improvisados."
		},
		{
			"name": "Narrador",
			"message": "O medo tomou conta do bairro. O campo ficou abandonado e a comunidade perdeu o seu espaço de encontro."
		},
		{
			"name": "Narrador",
			"message": "Agora, uma nova geração tem a oportunidade de mudar esta história. Será que antigos rivais conseguem trabalhar juntos?
			Interage com Kito (personagem em T pose para saber mais)
			"
		}
	]

	dialogue_ui.show_sequence(story)


func start_mission():
	print(">>> START_MISSION EXECUTADA!")

	if mission_active or mission_failed:
		return

	current_mission = "recuperar_campo"
	mission_active = true

	materials["wood"] = 0
	materials["iron"] = 0
	materials["paint"] = 0

	update_mission_hud()

	waiting_for_kito_dialogue = true


func spawn_rivals():
	print("SPAWN_RIVALS FOI EXECUTADA")

	if rivals_spawned:
		return

	var player = get_node_or_null("../TestLevel/Player")
	var grupo = get_node_or_null("../GrupoRival")

	if player == null:
		print("ERRO: Player não encontrado em TestLevel!")
		return

	if grupo == null:
		print("ERRO: GrupoRival não encontrado em Main!")
		return

	var player_visual = player.get_node_or_null("Visual")

	if player_visual == null:
		print("ERRO: Visual do jogador não encontrado!")
		return

	grupo.call("appear_around", player, player_visual)

	rivals_spawned = true
	print("Os seis rivais apareceram!")

	var dialogue_ui = get_tree().get_first_node_in_group("dialog_ui")

	if dialogue_ui == null:
		print("ERRO: DialogueUI não encontrado no grupo dialog_ui!")
		return

	dialogue_ui.show_choice_dialogue(
		"Tandela - 12 de Mata",
		"Oi ché meu nengue vocé inimigo, teus wis confundiram a tropa, isso é os 12 de mata do Malueca vamo vos fatigar yá, eu sou tandela 12 de mata"
	)

	print("Provocação de Tandela apresentada!")


func collect_material(material_type: String) -> bool:
	if not mission_active or mission_failed:
		print("Não tens uma missão ativa!")
		return false

	if not materials.has(material_type):
		print("Material desconhecido: ", material_type)
		return false

	if materials[material_type] >= 1:
		print("Já recolheste este material!")
		return false

	materials[material_type] = 1

	print("Material recolhido: ", material_names[material_type])

	update_mission_hud()

	if get_material_count() == TOTAL_MATERIALS:
		print("Todos os materiais foram recolhidos!")
		print("Regressa ao morador!")

	return true


func get_material_count() -> int:
	return materials["wood"] + materials["iron"] + materials["paint"]


func update_mission_hud():
	var hud = get_tree().get_first_node_in_group("mission_label")

	if hud == null:
		print("ERRO: MissionLabel não encontrado!")
		return

	var canvas = hud.get_parent()

	if canvas is CanvasLayer:
		canvas.visible = true
		canvas.layer = 20

	hud.visible = true
	hud.show()
	hud.queue_redraw()

	hud.modulate = Color(1, 1, 1, 1)
	hud.z_index = 100

	hud.set_anchors_preset(Control.PRESET_TOP_LEFT)
	hud.position = Vector2(25, 25)
	hud.size = Vector2(300, 180)

	hud.add_theme_color_override("font_color", Color.BLACK)
	hud.add_theme_font_size_override("font_size", 22)
	hud.autowrap_mode = TextServer.AUTOWRAP_WORD

	hud.text = "RECUPERAR O CAMPO\n"
	hud.text += "Madeira: %d/1\n" % materials["wood"]
	hud.text += "Ferro: %d/1\n" % materials["iron"]
	hud.text += "Tinta: %d/1\n" % materials["paint"]
	hud.text += "Total: %d/3" % get_material_count()

	print("HUD VISÍVEL: ", hud.is_visible_in_tree())
	print("RETÂNGULO: ", hud.get_global_rect())
	print("TEXTO: ", hud.text)


func complete_mission():
	if mission_failed:
		return

	mission_active = false
	current_mission = ""

	print("MISSÃO CONCLUÍDA!")


func on_kito_dialogue_finished():
	if not waiting_for_kito_dialogue:
		return

	waiting_for_kito_dialogue = false

	if not rivals_spawned:
		spawn_rivals()


# ==================================================
# MISSÃO FALHADA: OS SEIS RIVAIS FORAM DERROTADOS
# ==================================================

func _on_all_rivals_defeated() -> void:
	if confrontation_choice != "confrontar":
		return

	if mission_failed:
		return

	mission_failed = true
	mission_active = false
	current_mission = ""
	waiting_for_kito_dialogue = false

	# Parar a Tropa do Flamengo.
	var amigos_tropa = get_node_or_null("../AmigosTropa")

	if amigos_tropa != null:
		amigos_tropa.terminar_combate()

	var hud = get_tree().get_first_node_in_group("mission_label")

	if hud != null:
		hud.hide()

	print("MISSÃO FALHADA!")
	print("A rivalidade entre os grupos aumentou.")

	var dialogue_ui = get_tree().get_first_node_in_group("dialog_ui")

	if dialogue_ui != null:
		dialogue_ui.show_dialogue(
			"Kito",
			"Estou muito triste... Eu confiei em ti para ajudar a recuperar este campo. Pensei que conseguirias unir os grupos,\nmas acabaste por aumentar ainda mais a rivalidade.\nAgora já não será possível reconstruir o campo.\nPerdemos uma oportunidade de voltar a estar juntos."
		)


# ==================================================
# ESCOLHA DO JOGADOR
# ==================================================

func _on_choice_selected(choice: String) -> void:
	confrontation_choice = choice

	var player = get_node_or_null("../TestLevel/Player")
	var player_visual = player.get_node_or_null("Visual") if player != null else null
	var amigos_tropa = get_node_or_null("../AmigosTropa")
	var grupo_rival = get_node_or_null("../GrupoRival")

	if player == null or player_visual == null:
		print("ERRO: Não encontrei o Player ou o Visual!")
		return

	if amigos_tropa == null:
		print("ERRO: AmigosTropa não foi encontrado!")
		return

	print("A Tropa do Flamengo está a entrar!")

	await amigos_tropa.aparecer_com_amigos(player, player_visual)

	# INICIAR O COMBATE DA TROPA DO FLAMENGO.
	if choice == "confrontar":
		if grupo_rival != null:
			grupo_rival.iniciar_confronto()

			amigos_tropa.iniciar_combate(grupo_rival)

			print("O jogador escolheu enfrentar os rivais!")
			print("A Tropa do Flamengo entrou no combate!")
		else:
			print("ERRO: GrupoRival não foi encontrado!")

	var dialogue_ui = get_tree().get_first_node_in_group("dialog_ui")

	if dialogue_ui == null:
		return

	if choice == "confrontar":
		dialogue_ui.show_dialogue(
			"Tropa do Flamengo",
			"Manda dego essa é a Tropa do Flamengo, não tem nada essa tropa não corre! querem pânico então podem vir "
		)

	elif choice == "evitar":
		dialogue_ui.show_dialogue(
			"Tropa do Flamengo",
			"Wey fiquem calmos nos somos do mesmo gueto, vamos continuar a se aleijar até quando.\nessa vida não tem lucro é mesmo só ganhar muitos sinais, vamos trabalhar juntos para reconstruir o campo"
		)
