extends Resource
class_name CardData

enum CardType { ATTACK, SUPPORT, TANK, MISC }
enum Rarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }


@export var card_name: String = ""
@export var type: CardType = CardType.ATTACK
@export var cost: int = 0
@export var power: int = 0
@export var health: int = 0
@export var description: String = ""
@export var applies_rarity: bool = true
@export var rarity: Rarity = Rarity.COMMON



func get_rarity_multiplier() -> float:
    match rarity:
        Rarity.COMMON:    return 1.0
        Rarity.UNCOMMON:  return 1.25
        Rarity.RARE:      return 1.5
        Rarity.EPIC:      return 2.0
        Rarity.LEGENDARY: return 3.0
    return 1.0
