

extends StaticBody3D

var mission_started := false
var mission_completed := false


func interact(_player):
	var dialogue_ui = get_tree().get_first_node_in_group("dialog_ui")
	var manager = get_tree().get_first_node_in_group("game_manager")

	if dialogue_ui == null:
		print("DialogueUI não encontrado!")
		return

	if manager == null:
		print("GameManager não encontrado!")
		return

	# Missão já concluída
	if mission_completed:
		dialogue_ui.show_dialogue(
			"Morador Kito",
			"Conseguimos! O nosso campo voltou a ser um espaço de união. Obrigado por ajudares o bairro!"
		)
		return

	# Primeira conversa: iniciar missão
	if not mission_started:
		mission_started = true
		manager.start_mission()

		dialogue_ui.show_dialogue(
			"Morador Kito",
			"Vamos recuperar o nosso campo! Precisamos de madeira, ferro e tinta. Conto contigo!"
		)
		return

	# Verificar se os três materiais foram recolhidos
	if manager.get_material_count() == 3:
		mission_completed = true
		manager.complete_mission()

		dialogue_ui.show_dialogue(
			"Morador Kito",
			"Conseguiste! Temos todos os materiais. Agora podemos recuperar o nosso campo. Este bairro voltou a trabalhar unido!"
		)
	else:
		var quantidade = manager.get_material_count()

		dialogue_ui.show_dialogue(
			"Morador Kito",
			"Ainda precisamos dos três materiais. Já encontraste %d de 3. Continua à procura!" % quantidade
		)
