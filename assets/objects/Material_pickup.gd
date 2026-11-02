
extends StaticBody3D

@export_enum("wood", "iron", "paint")
var material_type: String = "wood"

func interact(_player):
	var manager = get_tree().get_first_node_in_group("game_manager")

	if manager == null:
		print("GameManager não encontrado!")
		return

	if manager.collect_material(material_type):
		print("Material recolhido: ", material_type)
		queue_free()
