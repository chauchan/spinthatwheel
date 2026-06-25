extends Node
class_name DeckManager

var deck_attack: Array[CardData] = []
var deck_support: Array[CardData] = []
var deck_tank: Array[CardData] = []
var deck_misc: Array[CardData] = []

var discard_attack: Array[CardData] = []
var discard_support: Array[CardData] = []
var discard_tank: Array[CardData] = []
var discard_misc: Array[CardData] = []


func setup_starter_deck() -> void:
	deck_attack = CardDB.get_starter_attack()
	deck_support = CardDB.get_starter_support()
	deck_tank = CardDB.get_starter_tank()
	deck_misc = CardDB.get_starter_misc()
	deck_attack.shuffle()
	deck_support.shuffle()
	deck_tank.shuffle()
	deck_misc.shuffle()
	

func draw_from(type: CardData.CardType) -> CardData:
	var deck := _get_deck(type)
	if deck.is_empty():
		var discard := _get_discard(type)
		if discard.is_empty():
			return null
		deck.append_array(discard)
		discard.clear()
		deck.shuffle()
	return deck.pop_back()
	
func _get_deck(type: CardData.CardType) -> Array:
	match type:
		CardData.CardType.ATTACK:
			return deck_attack
		CardData.CardType.SUPPORT:
			return deck_support
		CardData.CardType.TANK:
			return deck_tank
		CardData.CardType.MISC:
			return deck_misc
	return []
	
	
func _get_discard(type: CardData.CardType) -> Array:
	match type:
		CardData.CardType.ATTACK:
			return discard_attack
		CardData.CardType.SUPPORT:
			return discard_support
		CardData.CardType.TANK:
			return discard_tank
		CardData.CardType.MISC:
			return discard_misc
	return []
