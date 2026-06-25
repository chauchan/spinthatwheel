extends Resource
class_name CardData

enum CardType { ATTACK, SUPPORT, ENERGY }

@export var card_name: String = ""
@export var type: CardType = CardType.ATTACK
@export var cost: int = 0
@export var power: int = 0
@export var health: int = 0
@export var description: String = ""
