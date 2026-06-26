# Scene Building Guide

This document explains how to build every game scene in Godot. Read this alongside the existing scripts before starting.

---

## Context

All backend logic is complete. Two Autoloads are globally accessible:
- `PlayerCollection` — run state (lives, floor, collection, current_deck), save/load
- `BattleManager` — full combat logic with signals

Card types: `CardData.CardType.CHAR` and `CardData.CardType.SUPPORT`.
Rarity: `CardData.Rarity` enum (COMMON → LEGENDARY) with multipliers.

---

## Scene 1: Main Menu (`scenes/MainMenu.tscn`)

### Purpose
Entry point. Lets the player start a new run or continue an existing one.

### Nodes needed
```
Control (MainMenu.gd)
├── VBoxContainer
│   ├── Label ("Spin That Wheel")
│   ├── Button "Nueva Partida" 
│   └── Button "Continuar"
```

### Script logic (`scripts/main_menu.gd`)
```gdscript
extends Control

@onready var continue_button: Button = $VBoxContainer/ContinuarButton

func _ready() -> void:
    continue_button.visible = PlayerCollection.has_save()

func _on_nueva_partida_pressed() -> void:
    PlayerCollection.new_run()
    # Give starter deck
    var starter: Array[CardData] = []
    starter.append_array(CardDB.get_starter_char())
    starter.append_array(CardDB.get_starter_support())
    PlayerCollection.current_deck = starter
    PlayerCollection.save()
    get_tree().change_scene_to_file("res://scenes/Map.tscn")

func _on_continuar_pressed() -> void:
    PlayerCollection.load_save()
    get_tree().change_scene_to_file("res://scenes/Map.tscn")
```

---

## Scene 2: Battle Scene (`scenes/Battle.tscn`)

### Purpose
The core gameplay loop. Shows both boards, the player's hand, energy, points, and handles all player input during combat.

### Nodes needed
```
Control (Battle.gd)
├── Label "EnemyPointsLabel"
├── Label "PlayerPointsLabel"  
├── Label "EnergyLabel"
├── Label "PhaseLabel"
├── HBoxContainer "EnemyBoard"
│   ├── Button "EnemySlot0"
│   ├── Button "EnemySlot1"
│   └── Button "EnemySlot2"
├── HBoxContainer "PlayerBoard"
│   ├── Button "PlayerSlot0"
│   ├── Button "PlayerSlot1"
│   └── Button "PlayerSlot2"
├── HBoxContainer "PlayerHand"  (cards added dynamically)
├── Button "EndTurnButton"
└── Button "FinishPrepButton"
```

### Flow
1. Scene loads → call `BattleManager.start_battle(points_for_floor())`
2. `battle_started` signal fires → show prep UI, hide end turn button
3. Player clicks a CHAR card in hand → selects it
4. Player clicks an empty board slot → calls `BattleManager.place_char_prep(card, slot)`
5. Player clicks "Listo" → calls `BattleManager.finish_prep()`
6. `turn_changed(true)` signal fires → show end turn button, enable player controls
7. Player clicks board card to select attacker, clicks enemy slot to attack → `BattleManager.attack(attacker_slot, target_slot)`
8. Player clicks a SUPPORT card → `BattleManager.play_support(card)`
9. Player clicks a CHAR card + empty slot → `BattleManager.play_char(card, slot)`
10. `turn_changed(false)` → disable controls, AI plays automatically
11. `battle_ended(player_won)` → transition to Roulette if won, or back to Map if lost

### Script logic (`scripts/battle.gd`)
```gdscript
extends Control

var selected_card: CardData = null
var selected_attacker_slot: int = -1

@onready var energy_label: Label = $EnergyLabel
@onready var player_points_label: Label = $PlayerPointsLabel
@onready var enemy_points_label: Label = $EnemyPointsLabel
@onready var phase_label: Label = $PhaseLabel
@onready var end_turn_button: Button = $EndTurnButton
@onready var finish_prep_button: Button = $FinishPrepButton

func _ready() -> void:
    BattleManager.battle_started.connect(_on_battle_started)
    BattleManager.turn_changed.connect(_on_turn_changed)
    BattleManager.card_played.connect(_on_card_played)
    BattleManager.card_died.connect(_on_card_died)
    BattleManager.points_changed.connect(_on_points_changed)
    BattleManager.battle_ended.connect(_on_battle_ended)
    BattleManager.energy_changed.connect(_on_energy_changed)
    
    var points := _points_for_floor()
    BattleManager.start_battle(points)

func _points_for_floor() -> int:
    match PlayerCollection.current_floor:
        1: return 5
        2: return 10
        3: return 15
    return 5

func _on_battle_started() -> void:
    end_turn_button.visible = false
    finish_prep_button.visible = true
    phase_label.text = "Preparacion: coloca un personaje"
    _update_hand()

func _on_turn_changed(is_player: bool) -> void:
    end_turn_button.visible = is_player
    finish_prep_button.visible = false
    phase_label.text = "Tu turno" if is_player else "Turno del rival"
    _update_hand()
    _update_board()

func _on_energy_changed(energy: int, is_player: bool) -> void:
    if is_player:
        energy_label.text = "Energia: " + str(energy)

func _on_points_changed(player_pts: int, ai_pts: int) -> void:
    player_points_label.text = "Puntos: " + str(player_pts)
    enemy_points_label.text = "Rival: " + str(ai_pts)

func _on_card_played(_card: CardData, _is_player: bool) -> void:
    _update_hand()
    _update_board()

func _on_card_died(_card: CardData, _is_player: bool) -> void:
    _update_board()

func _on_battle_ended(player_won: bool) -> void:
    if player_won:
        get_tree().change_scene_to_file("res://scenes/Roulette.tscn")
    else:
        get_tree().change_scene_to_file("res://scenes/Map.tscn")

func _on_end_turn_pressed() -> void:
    BattleManager.end_player_turn()

func _on_finish_prep_pressed() -> void:
    BattleManager.finish_prep()

func _on_player_slot_pressed(slot: int) -> void:
    if BattleManager.phase == BattleManager.Phase.PREP:
        if selected_card != null and selected_card.type == CardData.CardType.CHAR:
            BattleManager.place_char_prep(selected_card, slot)
            selected_card = null
            _update_board()
    elif BattleManager.phase == BattleManager.Phase.PLAYER_TURN:
        if selected_card != null and selected_card.type == CardData.CardType.CHAR:
            BattleManager.play_char(selected_card, slot)
            selected_card = null
        elif selected_attacker_slot != -1:
            selected_attacker_slot = slot
        _update_board()

func _on_enemy_slot_pressed(slot: int) -> void:
    if selected_attacker_slot != -1:
        BattleManager.attack(selected_attacker_slot, slot)
        selected_attacker_slot = -1
        _update_board()

func _on_hand_card_pressed(card: CardData) -> void:
    selected_card = card
    if card.type == CardData.CardType.SUPPORT:
        BattleManager.play_support(card)
        selected_card = null
        _update_hand()

func _update_hand() -> void:
    # Clear and rebuild hand UI
    # For each card in BattleManager.player_hand, create a Button
    pass

func _update_board() -> void:
    # Update player_board and ai_board slot displays
    # Show card name + health on each slot button
    pass
```

### Notes on _update_hand and _update_board
These functions clear the hand/board containers and rebuild them from `BattleManager.player_hand`, `BattleManager.player_board`, and `BattleManager.ai_board`. Each card becomes a Button that shows `card.card_name` and `card.health`. Connect each button's `pressed` signal dynamically using a lambda.

---

## Scene 3: Roulette / Reward (`scenes/Roulette.tscn`)

### Purpose
After winning a combat, the player spins two roulettes — one for card type, one for rarity — and earns the resulting card for their collection.

### Existing code
`scenes/roulette.gd` already has a working roulette with weighted random picks and spin animation. The existing `SpinResult` enum has: ATTACK, TANK, MISC, SUPPORT, CHOOSE, ALL — **these need to be updated** to match the current card types: CHAR and SUPPORT.

### Changes needed to `roulette.gd`
1. Update `SpinResult` enum to: `{ CHAR, SUPPORT, CHOOSE }`
2. Update `weights` dictionary accordingly
3. Update `_name_for()` and `_all_names()` to match

### New scene structure
```
Control
├── Roulette (the existing roulette node, for card type)
├── RarityRoulette (second roulette instance, for rarity)
├── Label "ResultLabel" (shows the earned card)
├── Button "AddToDeckButton" ("Añadir a baraja")
└── Button "ContinueButton" ("Continuar")
```

### Script logic (`scripts/reward.gd`)
```gdscript
extends Control

var earned_card: CardData = null
var type_result = null
var rarity_result = null

@onready var type_roulette = $Roulette
@onready var rarity_roulette = $RarityRoulette
@onready var result_label: Label = $ResultLabel
@onready var add_button: Button = $AddToDeckButton

func _ready() -> void:
    add_button.visible = false
    type_roulette.spin_finished.connect(_on_type_spin_finished)
    rarity_roulette.spin_finished.connect(_on_rarity_spin_finished)

func _on_type_spin_finished(result) -> void:
    type_result = result
    rarity_roulette.spin()  # auto-spin rarity after type

func _on_rarity_spin_finished(result) -> void:
    rarity_result = result
    var card_type = CardData.CardType.CHAR if type_result == 0 else CardData.CardType.SUPPORT
    var rarity = rarity_result as CardData.Rarity
    earned_card = CardFactory.generate_card(card_type, rarity)
    PlayerCollection.add_card(earned_card)
    result_label.text = earned_card.card_name + " (" + str(earned_card.rarity) + ")"
    add_button.visible = true

func _on_add_to_deck_pressed() -> void:
    PlayerCollection.current_deck.append(earned_card)
    PlayerCollection.save()
    get_tree().change_scene_to_file("res://scenes/Map.tscn")

func _on_continue_pressed() -> void:
    get_tree().change_scene_to_file("res://scenes/Map.tscn")
```

### Rarity roulette weights (suggested)
```gdscript
var weights := {
    CardData.Rarity.COMMON:    50,
    CardData.Rarity.UNCOMMON:  25,
    CardData.Rarity.RARE:      15,
    CardData.Rarity.EPIC:       7,
    CardData.Rarity.LEGENDARY:  3,
}
```

---

## Scene 4: Collection / Deck Building (`scenes/Collection.tscn`)

### Purpose
Lets the player view their collection and add/remove cards from their active deck before entering combat.

### Nodes needed
```
Control
├── ScrollContainer "CollectionScroll"
│   └── VBoxContainer "CollectionList"
├── ScrollContainer "DeckScroll"  
│   └── VBoxContainer "DeckList"
├── Label "DeckCountLabel"
└── Button "SaveDeckButton"
```

### Script logic (`scripts/collection.gd`)
```gdscript
extends Control

func _ready() -> void:
    _refresh()

func _refresh() -> void:
    # Clear and rebuild both lists
    # CollectionList: all cards in PlayerCollection.collection
    # DeckList: all cards in PlayerCollection.current_deck
    # Each card is a button — click to move between collection and deck
    pass

func _add_to_deck(card: CardData) -> void:
    PlayerCollection.current_deck.append(card)
    PlayerCollection.save()
    _refresh()

func _remove_from_deck(card: CardData) -> void:
    PlayerCollection.current_deck.erase(card)
    PlayerCollection.save()
    _refresh()
```

---

## Scene 5: Map (`scenes/Map.tscn`)

### Purpose
2D top-down overworld (Pokemon style). Player moves around, interacts with objects (combat triggers, loot, shops), and advances to the next floor.

### Structure
This scene uses a TileMap for the floor layout and Area2D nodes for interactable objects.

```
Node2D (Map.gd)
├── TileMapLayer (the floor tiles)
├── CharacterBody2D "Player" (player.gd)
│   ├── Sprite2D
│   ├── CollisionShape2D
│   └── Camera2D
├── Area2D "CombatTrigger1" (interactable.gd)
│   ├── Sprite2D
│   └── CollisionShape2D
├── Area2D "LootObject1" (interactable.gd)
│   ├── Sprite2D
│   └── CollisionShape2D
└── CanvasLayer "HUD"
    ├── Label "LivesLabel"
    ├── Label "FloorLabel"
    └── Button "DeckButton" (goes to Collection scene)
```

### Player script (`scripts/player.gd`)
```gdscript
extends CharacterBody2D

const SPEED = 100.0

func _physics_process(delta: float) -> void:
    var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
    velocity = direction * SPEED
    move_and_slide()
```

### Interactable script (`scripts/interactable.gd`)
```gdscript
extends Area2D

enum InteractableType { COMBAT, LOOT, SHOP, EXIT }

@export var type: InteractableType = InteractableType.COMBAT
@export var defeated: bool = false

func _ready() -> void:
    body_entered.connect(_on_body_entered)

func _on_body_entered(body) -> void:
    if body.name != "Player" or defeated:
        return
    match type:
        InteractableType.COMBAT:
            get_tree().change_scene_to_file("res://scenes/Battle.tscn")
        InteractableType.LOOT:
            _give_loot()
        InteractableType.EXIT:
            _go_to_next_floor()

func _give_loot() -> void:
    # Give a random COMMON card directly
    var types = [CardData.CardType.CHAR, CardData.CardType.SUPPORT]
    var card = CardFactory.generate_card(types[randi() % 2], CardData.Rarity.COMMON)
    PlayerCollection.add_card(card)
    defeated = true

func _go_to_next_floor() -> void:
    PlayerCollection.current_floor += 1
    PlayerCollection.save()
    get_tree().change_scene_to_file("res://scenes/Map.tscn")
```

### Map script (`scripts/map.gd`)
```gdscript
extends Node2D

@onready var lives_label: Label = $CanvasLayer/LivesLabel
@onready var floor_label: Label = $CanvasLayer/FloorLabel

func _ready() -> void:
    lives_label.text = "Vidas: " + str(PlayerCollection.lives)
    floor_label.text = "Piso: " + str(PlayerCollection.current_floor)
    
    if PlayerCollection.lives <= 0:
        get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
```

---

## Scene Flow Summary

```
MainMenu
  → (nueva partida / continuar) → Map
  
Map
  → (combate) → Battle
  → (loot) → [item given, stay on Map]
  → (salida) → Map (next floor)
  → (deck button) → Collection → Map

Battle
  → (victoria) → Roulette → Map
  → (derrota, vidas > 0) → Map
  → (derrota, vidas = 0) → [PlayerCollection deletes save] → MainMenu

Roulette
  → (continuar / añadir a baraja) → Map
```

---

## Important Notes

- `BattleManager` resets all combat state when `start_battle()` is called — cards, energy, board, everything. Run state (lives, floor, collection) is managed by `PlayerCollection`.
- `PlayerCollection.current_deck` must have at least 1 CHAR card for `_draw_initial_hand()` to work. The starter deck from `MainMenu` guarantees this.
- After losing all lives, `PlayerCollection.lose_life()` calls `delete_save()` internally — no need to call it manually.
- The Map scene should be different per floor. You can use `PlayerCollection.current_floor` to decide which TileMap or scene variant to load.
- `BattleManager` is an Autoload — do NOT add it as a child node in any scene, just call it directly.
