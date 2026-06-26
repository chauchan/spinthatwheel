extends Node
class_name DeckManager

var deck: Array[CardData] = []

var discard: Array[CardData] = []


func setup_starter_deck() -> void:
	deck = CardDB.get_starter_char()
	deck.append_array(CardDB.get_starter_support())
	deck.shuffle()
	

func draw_from() -> CardData:
	if deck.is_empty():
		return null
	return deck.pop_back()
	
	
