extends Node
class_name CardDB

static func get_starter_attack() -> Array[CardData]:
	var cards: Array[CardData] = []
	cards.append(_make("Intern", CardData.CardType.ATTACK, 1, 1, 2, "Cannon Fodder"))
	cards.append(_make("Salesman", CardData.CardType.ATTACK, 3, 4, 3, "Glass Cannon"))
	return cards
	
static func get_starter_tank() -> Array[CardData]:
	var cards: Array[CardData] = []
	cards.append(_make("Accountant", CardData.CardType.TANK, 2, 2, 4, "Tank"))
	cards.append(_make("Shift Manager", CardData.CardType.TANK, 4, 6, 5, "BigBoi"))
	return cards

static func get_starter_misc() -> Array[CardData]:
	var cards: Array[CardData] = []
	cards.append(_make("HR", CardData.CardType.MISC, 2, 1, 3, "Gets energy back when this card dies"))
	return cards


static func get_starter_support() -> Array[CardData]:
	var cards: Array[CardData] = []
	cards.append(_make("Company Policy", CardData.CardType.SUPPORT, 1, 0, 0, "Takes -2 damage next time you get berated"))
	cards.append(_make("Gossip", CardData.CardType.SUPPORT, 1, 0, 0, "You know what they did. -1 ATK to one of their cards"))
	cards.append(_make("Day Off", CardData.CardType.SUPPORT, 2, 0, 0, "Finally, you get some rest. Gets 3 HP"))
	cards.append(_make("Transfer Request", CardData.CardType.SUPPORT, 2, 0, 0, "Trade a card on your field for one on your opponent's field"))
	cards.append(_make("I QUIT", CardData.CardType.SUPPORT, 0, 0, 0, "Sacrifice one card from your field: deal 3 damage directly"))
	cards.append(_make("9 to 5", CardData.CardType.SUPPORT, 0, 0, 0, "+2 energy"))
	cards.append(_make("Productivity Bonus", CardData.CardType.SUPPORT, 1, 0, 0, "+1 energy, draw from attack deck"))
	cards.append(_make("Loan", CardData.CardType.SUPPORT, 0, 0, 0, "+3 energy, -1 energy next 2 turns"))
	cards.append(_make("Investing", CardData.CardType.SUPPORT, 0, 0, 0, "+1 energy this turn, +2 energy after 2 turns"))
	cards.append(_make("Savings Account", CardData.CardType.SUPPORT, 0, 0, 0, "Gain energy for each card you have in your hand"))
	return cards


static func _make(n: String, t: CardData.CardType, c: int, p: int, h: int, d: String) -> CardData:
	var card := CardData.new()
	card.card_name = n
	card.type = t
	card.cost = c
	card.power = p
	card.health = h
	card.description = d
	return card
