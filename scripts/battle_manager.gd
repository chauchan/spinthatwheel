extends Node

enum Phase {PREP, PLAYER_TURN, AI_TURN, BATTLE_END}

signal battle_started
signal turn_changed(is_player_turn: bool)
signal card_played(card: CardData, is_player: bool)
signal card_died(card: CardData, is_player: bool)
signal points_changed(player_points: int, ai_points: int)
signal battle_ended(player_won: bool)
signal energy_changed(energy: int, is_player: bool)


var phase: Phase = Phase.PREP
var points_to_win: int = 5

var player_energy: int = 0
var player_energy_gain: int = 1
var player_hand: Array[CardData] = []
var player_board: Array[CardData] = [null, null, null]
var player_support: Array[CardData] = []
var player_points: int = 0
var player_deck: DeckManager = DeckManager.new()
var player_attacked_slots: Array[bool] = [false, false, false]

var ai_energy: int = 0
var ai_energy_gain: int = 1
var ai_hand: Array[CardData] = []
var ai_board: Array[CardData] = [null, null, null]
var ai_support: Array[CardData] = []
var ai_points: int = 0
var ai_deck: DeckManager = DeckManager.new()
var ai_attacked_slots: Array[bool] = [false, false, false]


func start_battle(target_points: int) -> void:
	points_to_win = target_points
	phase = Phase.PREP
	player_energy = 0
	player_energy_gain = 1
	player_points = 0
	player_hand = []
	player_board = [null, null, null]
	player_support = []
	ai_energy = 0
	ai_energy_gain = 1
	ai_points = 0
	ai_hand = []
	ai_board = [null, null, null]
	ai_support = []
	_setup_decks()
	_draw_initial_hand(player_deck, player_hand)
	_draw_initial_hand(ai_deck, ai_hand)
	battle_started.emit()


func _setup_decks() -> void:
	var player_cards: Array[CardData] = []
	for card in PlayerCollection.current_deck:
		player_cards.append(card.duplicate())
	player_deck.setup_combat_deck(player_cards)
	
	var ai_cards: Array[CardData] = []
	for card in CardDB.get_starter_char() + CardDB.get_starter_support():
		ai_cards.append(card.duplicate())
	ai_deck.setup_combat_deck(ai_cards)

func _draw_initial_hand(deck: DeckManager, hand: Array[CardData]) -> void:
	var char_card: CardData = null
	for i in range(deck.deck.size() - 1, -1, -1):
		if deck.deck[i].type == CardData.CardType.CHAR:
			char_card = deck.deck[i]
			deck.deck.remove_at(i)
			break
	if char_card:
		hand.append(char_card)
	deck.deck.shuffle()
	for i in range(4):
		var card := deck.draw_from()
		if card:
			hand.append(card)

func draw_card(deck: DeckManager, hand: Array[CardData]) -> void:
	var card := deck.draw_from()
	if card:
		hand.append(card)

func start_player_turn() -> void:
	phase = Phase.PLAYER_TURN
	player_energy += player_energy_gain
	draw_card(player_deck, player_hand)
	player_attacked_slots = [false, false, false]
	_apply_persistent_effects(true)
	turn_changed.emit(true)
	energy_changed.emit(player_energy, true)




func play_char(card: CardData, slot: int) -> bool:
	if phase != Phase.PLAYER_TURN:
		return false
	if player_energy < card.cost:
		return false
	if slot < 0 or slot > 2:
		return false
	if player_board[slot] != null:
		return false
	if card.type != CardData.CardType.CHAR:
		return false
	player_hand.erase(card)
	player_board[slot] = card
	player_energy -= card.cost
	card_played.emit(card, true)
	energy_changed.emit(player_energy, true)
	return true

func play_support(card: CardData) -> bool:
	if phase != Phase.PLAYER_TURN:
		return false
	if player_energy < card.cost:
		return false
	if card.type != CardData.CardType.SUPPORT:
		return false
	player_hand.erase(card)
	player_energy -= card.cost
	if card.effect_duration == CardData.EffectDuration.INSTANT:
		_resolve_support_effect(card, true)
		player_deck.discard.append(card)
	else:
		_resolve_persistent_on_play(card, true)
		player_support.append(card)
	card_played.emit(card, true)
	energy_changed.emit(player_energy, true)
	return true


#aqui las support instantaneas
func _resolve_support_effect(card: CardData, is_player: bool) -> void:
	var own_board := player_board if is_player else ai_board
	var enemy_board := ai_board if is_player else player_board
	var own_hand := player_hand if is_player else ai_hand
	
	match card.card_name:
		"Gossip":
			var targets := enemy_board.filter(func(c): return c != null)
			if not targets.is_empty():
				var target = targets[randi() % targets.size()]
				target.power = max(0, target.power - 1)
		"Day Off":
			var targets := own_board.filter(func(c): return c != null)
			if not targets.is_empty():
				targets[randi() % targets.size()].health += 3
		"9 to 5":
			if is_player: player_energy += 2
			else: ai_energy += 2
		"Productivity Bonus":
			if is_player:
				player_energy += 1
				draw_card(player_deck, player_hand)
			else:
				ai_energy += 1
				draw_card(ai_deck, ai_hand)
		"Savings Account":
			if is_player: player_energy += own_hand.size()
			else: ai_energy += own_hand.size()
		"I QUIT":
			var own_chars := own_board.filter(func(c): return c != null)
			var enemy_chars := enemy_board.filter(func(c): return c != null)
			if not own_chars.is_empty() and not enemy_chars.is_empty():
				_remove_char(own_chars[randi() % own_chars.size()], is_player)
				enemy_chars[randi() % enemy_chars.size()].health -= 3
		"Transfer Request":
			var own_slots: Array = []
			var enemy_slots: Array = []
			for i in range(3):
				if own_board[i] != null: own_slots.append(i)
				if enemy_board[i] != null: enemy_slots.append(i)
			if not own_slots.is_empty() and not enemy_slots.is_empty():
				var oi = own_slots[randi() % own_slots.size()]
				var ei = enemy_slots[randi() % enemy_slots.size()]
				var temp = own_board[oi]
				own_board[oi] = enemy_board[ei]
				enemy_board[ei] = temp


func _remove_char(card: CardData, is_player: bool) -> void:
	var board := player_board if is_player else ai_board
	var discard := player_deck.discard if is_player else ai_deck.discard
	for i in range(3):
		if board[i] == card:
			board[i] = null
			discard.append(card)
			card_died.emit(card, is_player)
			return

func attack(attacker_slot: int, target_slot: int) -> bool:
	if phase != Phase.PLAYER_TURN:
		return false
	if player_board[attacker_slot] == null:
		return false
	if ai_board[target_slot] == null:
		return false
	if player_attacked_slots[attacker_slot]:
		return false
	var attacker := player_board[attacker_slot]
	var target := ai_board[target_slot]
	target.health -= attacker.power
	player_attacked_slots[attacker_slot] = true
	if target.health <= 0:
		_remove_char(target, false)
		player_points += 1
		points_changed.emit(player_points, ai_points)
		_check_win_condition()
	_check_all_attacked()
	return true

func _check_all_attacked() -> void:
	for i in range(3):
		if player_board[i] != null and not player_attacked_slots[i]:
			return
	end_player_turn()

func end_player_turn() -> void:
	phase = Phase.AI_TURN
	start_ai_turn()

func _check_win_condition() -> void:
	if player_points >= points_to_win:
		_end_battle(true)
		return
	if ai_points >= points_to_win:
		_end_battle(false)
		return
	var player_has_chars := player_board.any(func(c): return c != null) or \
		player_hand.any(func(c): return c != null and c.type == CardData.CardType.CHAR) or \
		player_deck.deck.any(func(c): return c.type == CardData.CardType.CHAR)
	var ai_has_chars := ai_board.any(func(c): return c != null) or \
		ai_hand.any(func(c): return c != null and c.type == CardData.CardType.CHAR) or \
		ai_deck.deck.any(func(c): return c.type == CardData.CardType.CHAR)
	if not player_has_chars:
		_end_battle(false)
		return
	if not ai_has_chars:
		_end_battle(true)

func _end_battle(player_won: bool) -> void:
	battle_ended.emit(player_won)
	phase = Phase.BATTLE_END
	if player_won:
		PlayerCollection.current_floor += 1
	else:
		PlayerCollection.lose_life()

func start_ai_turn() -> void:
	phase = Phase.AI_TURN
	turn_changed.emit(false)
	ai_attacked_slots = [false, false, false]
	ai_energy += ai_energy_gain
	draw_card(ai_deck, ai_hand)
	_apply_persistent_effects(false)
	_ai_play_cards()
	_ai_attack()
	end_ai_turn()


func _ai_play_cards() -> void:
	for card in ai_hand.duplicate():
		if card.type == CardData.CardType.CHAR and ai_energy >= card.cost:
			for i in range(3):
				if ai_board[i] == null:
					ai_board[i] = card
					ai_hand.erase(card)
					ai_energy -= card.cost
					break
		elif card.type == CardData.CardType.SUPPORT and ai_energy >= card.cost:
			ai_hand.erase(card)
			ai_energy -= card.cost
			if card.effect_duration == CardData.EffectDuration.INSTANT:
				_resolve_support_effect(card, false)
				ai_deck.discard.append(card)
			else:
				_resolve_persistent_on_play(card, false)
				ai_support.append(card)


func _ai_attack() -> void:
	var player_targets: Array = []
	for i in range(3):
		if player_board[i] != null:
			player_targets.append(i)
	if player_targets.is_empty():
		return
	for i in range(3):
		if ai_board[i] != null:
			var target_slot = player_targets[randi() % player_targets.size()]
			var target := player_board[target_slot]
			var damage := ai_board[i].power
			damage = _apply_company_policy(damage, true)
			target.health -= damage

			ai_attacked_slots[i] = true
			if target.health <= 0:
				_remove_char(target, true)
				ai_points += 1
				points_changed.emit(player_points, ai_points)
				player_targets.erase(target_slot)
				_check_win_condition()
				if phase == Phase.BATTLE_END:
					return
				player_targets = []
				for j in range(3):
					if player_board[j] != null:
						player_targets.append(j)
				if player_targets.is_empty():
					return

func end_ai_turn() -> void:
	start_player_turn()

func _apply_persistent_effects(is_player: bool) -> void:
	var support := player_support if is_player else ai_support
	for card in support.duplicate():
		match card.card_name:
			"Loan":
				if is_player: player_energy -= 1
				else: ai_energy -= 1
				card.turns_remaining -= 1
				if card.turns_remaining <= 0:
					support.erase(card)
			"Investing":
				card.turns_remaining -= 1
				if card.turns_remaining <= 0:
					if is_player: player_energy += 2
					else: ai_energy += 2
					support.erase(card)


func _resolve_persistent_on_play(card: CardData, is_player: bool) -> void:
	match card.card_name:
		"Loan":
			if is_player: player_energy += 3
			else: ai_energy += 3
			card.turns_remaining = 2
		"Investing":
			if is_player: player_energy += 1
			else: ai_energy += 1
			card.turns_remaining = 2
		"Company Policy":
			card.turns_remaining = -1


func _apply_company_policy(damage: int, is_player: bool) -> int:
	var support := player_support if is_player else ai_support
	for card in support:
		if card.card_name == "Company Policy":
			support.erase(card)
			return max(0, damage - 2)
	return damage

func place_char_prep(card: CardData, slot: int) -> bool:
	if phase != Phase.PREP:
		return false
	if card.type != CardData.CardType.CHAR:
		return false
	if player_board[slot] != null:
		return false
	if slot < 0 or slot > 2:
		return false
	player_hand.erase(card)
	player_board[slot] = card
	return true

func finish_prep() -> void:
	var has_char := player_board.any(func(c): return c != null)
	if not has_char:
		return
	_ai_prep()
	start_player_turn()

func _ai_prep() -> void:
	for card in ai_hand.duplicate():
		if card.type == CardData.CardType.CHAR:
			for i in range(3):
				if ai_board[i] == null:
					ai_board[i] = card
					ai_hand.erase(card)
					break
