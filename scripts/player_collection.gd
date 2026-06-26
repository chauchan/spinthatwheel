extends Node

const SAVE_PATH = "user://save_data.json"

var lives: int = 3
var current_floor: int = 1
var collection: Array[CardData] = []
var current_deck: Array[CardData] = []

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func new_run() -> void:
	lives = 3
	current_floor = 1
	collection = []
	current_deck = []
	save()

func lose_life() -> void:
	lives -= 1
	if lives <= 0:
		delete_save()
	else:
		save()

func add_card(card: CardData) -> void:
	collection.append(card)
	save()

func save() -> void:
	var data := {
		"lives": lives,
		"current_floor": current_floor,
		"collection": collection.map(func(c): return _card_to_dict(c)),
		"current_deck": current_deck.map(func(c): return _card_to_dict(c))
		}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()

func load_save() -> void:
	if not has_save():
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	lives = data["lives"]
	current_floor = data["current_floor"]
	collection = []
	for d in data["collection"]:
		collection.append(_dict_to_card(d))
	current_deck = []
	for d in data["current_deck"]:
		current_deck.append(_dict_to_card(d))

func delete_save() -> void:
	lives = 3
	current_floor = 1
	collection = []
	current_deck = []
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))

func _card_to_dict(card: CardData) -> Dictionary:
	return {
		"card_name": card.card_name,
		"type": card.type,
		"cost": card.cost,
		"power": card.power,
		"health": card.health,
		"description": card.description,
		"applies_rarity": card.applies_rarity,
		"rarity": card.rarity,
		"effect_duration": card.effect_duration
	}

func _dict_to_card(data: Dictionary) -> CardData:
	var card := CardData.new()
	card.card_name = data["card_name"]
	card.type = data["type"]
	card.cost = data["cost"]
	card.power = data["power"]
	card.health = data["health"]
	card.description = data["description"]
	card.applies_rarity = data["applies_rarity"]
	card.rarity = data["rarity"]
	card.effect_duration = data["effect_duration"]
	return card
