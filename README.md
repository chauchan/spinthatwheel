# Spin That Wheel

A roguelite card game made in Godot 4.6 for a game jam.

## Concept

You work a soul-crushing office job and fight your way through 3 floors of card battles against an AI opponent. After each combat, spin a roulette to earn a new card for your collection. Build your deck between fights and survive with your 3 lives.

## Gameplay

- **Card combat** inspired by Pokemon TCG Pocket: turn-based, choose who attacks who
- **2 card types:** CHAR (characters that fight on the board) and SUPPORT (effect cards)
- **Energy system:** gain +1 energy per turn, spend it to play cards
- **3 board slots** per player for CHAR cards
- **Win conditions:** reach the point target first, or eliminate all enemy CHARs
- **3 lives per run:** lose a life each time you lose a combat. Lose all 3 and the run ends
- **Post-combat roulette:** spin to get a card type and rarity, earn it for your collection
- **Deck building:** add cards from your collection to your combat deck between fights
- **3 floors** of increasing difficulty

## Tech

- **Engine:** Godot 4.6 (GL Compatibility)
- **Language:** GDScript

## Project Structure

```
scripts/
  card_data.gd         # CardData resource: stats, type, rarity, effect
  card_db.gd           # Static card database (starter + full pools)
  card_factory.gd      # Generates cards with rarity multiplier applied
  deck_manager.gd      # Manages a single combat deck (shuffle, draw, discard)
  player_collection.gd # Autoload: persistent run state, save/load
  battle_manager.gd    # Autoload: full combat logic and signals
scenes/
  Roulette.tscn        # Roulette wheel UI (already functional)
```

## Team

- Ricardo Parra
- Chayanne