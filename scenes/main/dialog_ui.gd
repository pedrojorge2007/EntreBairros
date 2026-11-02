
extends CanvasLayer

signal choice_selected(choice: String)

@onready var dialogue_panel = $DialoguePanel
@onready var name_label = $DialoguePanel/Panel/VBoxContainer/NameLabel
@onready var message_label = $DialoguePanel/Panel/VBoxContainer/MessageLabel
@onready var continue_label = $DialoguePanel/Panel/VBoxContainer/ContinueLabel

var dialogue_open := false
var previous_mouse_mode := Input.MOUSE_MODE_CAPTURED
var dialogue_lines: Array = []
var current_line := 0
var is_sequence := false
var choices_open := false

var confront_button: Button
var avoid_button: Button


func _ready():
	dialogue_panel.hide()

	# Criar os botões de escolha
	create_choice_buttons()
	dialogue_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	confront_button.mouse_filter = Control.MOUSE_FILTER_STOP
	avoid_button.mouse_filter = Control.MOUSE_FILTER_STOP
	print("DIALOGUE UI CARREGADO")
	print("PAINEL: ", dialogue_panel)


func create_choice_buttons():
	var container = $DialoguePanel/Panel/VBoxContainer

	confront_button = Button.new()
	confront_button.text = "Enfrentar os rivais"
	confront_button.hide()
	container.add_child(confront_button)

	avoid_button = Button.new()
	avoid_button.text = "Evitar o confronto"
	avoid_button.hide()
	container.add_child(avoid_button)

	confront_button.pressed.connect(
		func():
			select_choice("confrontar")
	)

	avoid_button.pressed.connect(
		func():
			select_choice("evitar")
	)


func show_dialogue(npc_name: String, message: String):
	hide_choice_buttons()

	is_sequence = false
	choices_open = false
	dialogue_open = true

	name_label.text = npc_name
	message_label.text = message
	continue_label.text = "[E] Continuar / Fechar"

	dialogue_panel.show()


func show_sequence(lines: Array):
	hide_choice_buttons()

	print("DIALOGUE: show_sequence foi chamada")

	dialogue_lines = lines
	current_line = 0
	is_sequence = true
	choices_open = false
	dialogue_open = true

	dialogue_panel.show()

	print("PAINEL VISÍVEL: ", dialogue_panel.visible)

	display_current_line()


func display_current_line():
	if current_line >= dialogue_lines.size():
		close_dialogue()
		return

	name_label.text = dialogue_lines[current_line]["name"]
	message_label.text = dialogue_lines[current_line]["message"]
	continue_label.text = "[E] Continuar"


func show_choice_dialogue(npc_name: String, message: String):
	is_sequence = false
	choices_open = true
	dialogue_open = true

	previous_mouse_mode = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	name_label.text = npc_name
	message_label.text = message
	continue_label.text = "Escolhe uma opção:"

	confront_button.show()
	avoid_button.show()

	dialogue_panel.show()

func select_choice(choice: String):
	if not choices_open:
		return

	print("ESCOLHA DO JOGADOR: ", choice)

	choices_open = false
	hide_choice_buttons()
	close_dialogue()

	Input.mouse_mode = previous_mouse_mode

	choice_selected.emit(choice)

func hide_choice_buttons():
	if confront_button != null:
		confront_button.hide()

	if avoid_button != null:
		avoid_button.hide()


func close_dialogue():
	var was_kito_dialogue = (
		dialogue_open
		and name_label.text == "Morador Kito"
	)

	dialogue_panel.hide()
	dialogue_open = false
	is_sequence = false
	choices_open = false

	hide_choice_buttons()

	if was_kito_dialogue:
		var manager = get_tree().get_first_node_in_group("game_manager")

		if manager != null:
			manager.on_kito_dialogue_finished()


func _unhandled_input(event):
	if event.is_action_pressed("interact") and dialogue_open:
		# Não permitir fechar o diálogo enquanto o jogador escolhe
		if choices_open:
			get_viewport().set_input_as_handled()
			return

		if is_sequence:
			current_line += 1
			display_current_line()
		else:
			close_dialogue()

		get_viewport().set_input_as_handled()
