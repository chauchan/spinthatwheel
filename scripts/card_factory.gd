extends Node
class_name CardFactory


static func generate_card(type: CardData.CardType, rarity: CardData.Rarity) -> CardData:
	var pool := _get_pool(type)
	if pool.is_empty():
		return null
	var base_card: CardData = pool[randi() % pool.size()]
	return _apply_rarity(base_card, rarity)



static func _get_pool(type: CardData.CardType) -> Array[CardData]:
	match type:
		CardData.CardType.CHAR:  return CardDB.get_all_char()
		CardData.CardType.SUPPORT: return CardDB.get_all_support()
	return []

static func _apply_rarity(base: CardData, rarity: CardData.Rarity) -> CardData:
	var card := CardData.new()
	card.card_name = base.card_name
	card.type = base.type
	card.description = base.description
	card.applies_rarity = base.applies_rarity
	card.rarity = rarity
	if base.applies_rarity:
		var mult := card.get_rarity_multiplier()
		card.cost = roundi(base.cost * mult)
		card.power = roundi(base.power * mult)
		card.health = roundi(base.health * mult)
	else:
		card.cost = base.cost
		card.power = base.power
		card.health = base.health
	return card
