extends Node
class_name DeckManager

var deck_attack: Array[CardData] = []
var deck_support: Array[CardData] = []
var deck_energy: Array[CardData] = []

var discard_attack: Array[CardData] = []
var discard_support: Array[CardData] = []
var discard_energy: Array[CardData] = []


func setup_starter_deck() -> void:
	deck_attack = CardDB.get_starter_attack()
	deck_support = CardDB.get_starter_support()
	deck_energy = CardDB.get_starter_energy()
	deck_attack.shuffle()
	deck_support.shuffle()
	deck_energy.shuffle()
	

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
		CardData.CardType.ENERGY:
			return deck_energy
	return []
	
	
func _det_discard(type: CardData.CardType) -> Array:
	match type:
		CardData.CardType.ATTACK:
			return discard_attack
		CardData.CardType.SUPPORT:
			return discard_support
		CardData.CardType.ENERGY:
			return discard_energy
	return []
