extends RefCounted
class_name InputSetup
## Keyboard and mouse bindings. Remapping (plan step 85) will build on this.

const KEYS := {
	"left": [KEY_A, KEY_LEFT], "right": [KEY_D, KEY_RIGHT], "up": [KEY_W, KEY_UP], "down": [KEY_S, KEY_DOWN],
	"sprint": [KEY_SHIFT], "dodge": [KEY_SPACE], "interact": [KEY_E], "inventory": [KEY_I, KEY_TAB],
	"map": [KEY_M], "escape": [KEY_ESCAPE], "save": [KEY_F5],
}

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
