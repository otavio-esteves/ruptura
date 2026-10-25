extends RefCounted
## Runtime InputMap is installed before instantiating the gameplay scene.

static func install(alternate_jump: bool = false) -> void:
	_key("move_left", [KEY_A, KEY_LEFT])
	_key("move_right", [KEY_D, KEY_RIGHT])
	_key("crouch", [KEY_S, KEY_DOWN])
	_key("jump", [KEY_SPACE])
	_key("dodge", [KEY_SHIFT])
	_key("sprint", [KEY_CTRL])
	_key("restart", [KEY_F5])
	_key("reload", [KEY_R])
	_key("fire", [])
	_key("melee", [])
	_key("switch_weapon", [KEY_Q])
	_key("weapon_1", [KEY_1])
	_key("weapon_2", [KEY_2])
	_key("interact", [KEY_E])
	_key("fullscreen", [KEY_F11])
	_mouse("fire", MOUSE_BUTTON_LEFT)
	_mouse("melee", MOUSE_BUTTON_RIGHT)
	_mouse("switch_weapon", MOUSE_BUTTON_WHEEL_UP)
	_mouse("switch_weapon", MOUSE_BUTTON_WHEEL_DOWN)
	_key("pause", [KEY_ESCAPE])
	_key("switch_preset", [KEY_F2])
	_key("toggle_fps", [KEY_F3])
	_key("benchmark", [KEY_F6])
	_axis("move_left", JOY_AXIS_LEFT_X, -1.0)
	_axis("move_right", JOY_AXIS_LEFT_X, 1.0)
	_axis("aim_left", JOY_AXIS_RIGHT_X, -1.0)
	_axis("aim_right", JOY_AXIS_RIGHT_X, 1.0)
	_axis("aim_up", JOY_AXIS_RIGHT_Y, -1.0)
	_axis("aim_down", JOY_AXIS_RIGHT_Y, 1.0)
	_button("jump", JOY_BUTTON_LEFT_SHOULDER if alternate_jump else JOY_BUTTON_A)
	_button("crouch", JOY_BUTTON_DPAD_DOWN)
	_button("dodge", JOY_BUTTON_B)
	_button("sprint", JOY_BUTTON_LEFT_STICK)
	_button("restart", JOY_BUTTON_BACK)
	_button("pause", JOY_BUTTON_START)
	_axis("fire", JOY_AXIS_TRIGGER_RIGHT, 1.0)
	_button("melee", JOY_BUTTON_RIGHT_SHOULDER)
	_button("reload", JOY_BUTTON_X)
	_button("switch_weapon", JOY_BUTTON_Y)
	_button("switch_weapon", JOY_BUTTON_DPAD_RIGHT)
	_button("interact", JOY_BUTTON_DPAD_UP)

static func _mouse(action: StringName, button: MouseButton) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = button
	InputMap.action_add_event(action, event)

static func _key(action: StringName, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.2)
	InputMap.action_erase_events(action)
	for code: int in keys:
		var event := InputEventKey.new()
		event.physical_keycode = code
		InputMap.action_add_event(action, event)

static func _axis(action: StringName, axis: JoyAxis, value: float) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.2)
	else:
		for event: InputEvent in InputMap.action_get_events(action):
			if event is InputEventJoypadMotion:
				InputMap.action_erase_event(action, event)
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = value
	InputMap.action_add_event(action, event)

static func _button(action: StringName, button: JoyButton) -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	InputMap.action_add_event(action, event)
