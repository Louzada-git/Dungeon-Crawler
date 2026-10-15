extends RefCounted
class_name InputSetup
## Keyboard and mouse bindings. The habilidade bar keys are the player's choice
## (main.technique_keys, saved in the user settings); full remapping is plan step 85.

const KEYS := {
	"left": [KEY_A, KEY_LEFT], "right": [KEY_D, KEY_RIGHT], "up": [KEY_W, KEY_UP], "down": [KEY_S, KEY_DOWN],
	"sprint": [KEY_SHIFT], "dodge": [KEY_SPACE], "interact": [KEY_E], "inventory": [KEY_I, KEY_TAB],
	"map": [KEY_M], "escape": [KEY_ESCAPE], "save": [KEY_F5], "sneak": [KEY_C],
}

## Default keys of the habilidade bar (the player can change them in the T window).
const TECHNIQUE_KEYS := [KEY_Q, KEY_R, KEY_F, KEY_G]

## Keys the game uses outside the KEYS actions.
const FIXED := {
	KEY_T: "habilidades", KEY_H: "condição física", KEY_P: "proficiências",
}

const KEYPAD := {
	KEY_KP_0: "Num 0", KEY_KP_1: "Num 1", KEY_KP_2: "Num 2", KEY_KP_3: "Num 3", KEY_KP_4: "Num 4",
	KEY_KP_5: "Num 5", KEY_KP_6: "Num 6", KEY_KP_7: "Num 7", KEY_KP_8: "Num 8", KEY_KP_9: "Num 9",
	KEY_KP_ADD: "Num +", KEY_KP_SUBTRACT: "Num −", KEY_KP_MULTIPLY: "Num ×", KEY_KP_DIVIDE: "Num ÷",
	KEY_KP_PERIOD: "Num ,", KEY_KP_ENTER: "Num Enter",
}

const ACTION_NAMES := {
	"left": "mover", "right": "mover", "up": "mover", "down": "mover", "sprint": "correr",
	"dodge": "esquivar", "interact": "interagir", "inventory": "mochila", "map": "mapa",
	"escape": "pausa", "save": "salvar", "sneak": "andar furtivo",
}

## Short name of a key for the HUD ("Q", "Num 1", "Shift").
static func key_name(code: int) -> String:
	if KEYPAD.has(code):
		return KEYPAD[code]
	var text: String = OS.get_keycode_string(code)
	return text if text != "" else "?"

## What already uses a key ("" when it is free for a habilidade). The number
## row belongs to the quick bar.
static func reserved(code: int) -> String:
	if code >= KEY_0 and code <= KEY_9:
		return "barra rápida"
	if code == KEY_NONE or code == KEY_UNKNOWN:
		return "tecla desconhecida"
	if FIXED.has(code):
		return FIXED[code]
	for action in KEYS:
		if code in KEYS[action]:
			return ACTION_NAMES.get(action, action)
	return ""

static func configure() -> void:
	for action in KEYS:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key in KEYS[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action, event)
	if not InputMap.has_action("aim"):
		InputMap.add_action("aim")
	var aim_event := InputEventMouseButton.new()
	aim_event.button_index = MOUSE_BUTTON_RIGHT
	InputMap.action_add_event("aim", aim_event)
