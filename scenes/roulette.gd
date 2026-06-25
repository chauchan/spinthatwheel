extends Control
class_name Roulette

enum SpinResult { ATTACK, SUPPORT, ENERGY, CHOSE, ALL}

var weights := {
	SpinResult.ATTACK: 35,
	SpinResult.SUPPORT: 25,
	SpinResult.ENERGY: 25,
	SpinResult.CHOSE: 10,
	SpinResult.ALL: 5,
}

signal spin_finished(result: SpinResult)

@onready var result_label: Label = $ResultLabel
@onready var spin_button: Button = $SpinButton

var _spinning := false


func _ready() -> void:
	spin_button.pressed.connect(_on_spin_pressed)
	result_label.text = "SPIN THAT WHEEL"

func _on_spin_pressed() -> void:
	if _spinning:
		return
	_spinning = true
	spin_button.disabled = true
	var final_result := _weighted_pick()
	await _play_spin_animation(final_result)
	_spinning = false
	spin_button.disabled = false
	spin_finished.emit(final_result)
	
	
	
func _weighted_pick() -> SpinResult:
	var total := 0
	for w in weights.values():
		total += w
	var roll := randi() % total
	var acc := 0
	for key in weights.keys():
		acc += weights[key]
		if roll<acc:
			return key
	return SpinResult.ATTACK

func _play_spin_animation(final_result: SpinResult) -> void:
	var names := _all_names()
	var cycles := 14
	var delay := 0
	for i in range(cycles):
		result_label.text = names[randi() % names.size()]
		await get_tree().create_timer(delay).timeout
		delay = min(delay + 0.02, 0.28)
	result_label.text = _name_for(final_result)


func _name_for(r: SpinResult) -> String:
	match r:
		SpinResult.ATTACK:
			return "Draw from attack deck"
		SpinResult.SUPPORT:
			return "Draw from support deck"
		SpinResult.ENERGY:
			return "Draw from energy deck"
		SpinResult.CHOSE:
			return "Chose ONE deck to draw from"
		SpinResult.ALL:
			return "Draw one from each deck"
	return "?"
	
func _all_names() -> Array[String]:
	return ["Draw from attack deck", 
	"Draw from support deck", 
	"Draw from energy deck",
	"Chose ONE deck to draw from",
	"Draw one from each deck"]	
	



	
