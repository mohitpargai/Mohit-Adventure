## Development test for the mobile touch controls. Verifies that the buttons
## appear based on the setting, sit inside the screen and feed the same
## InputMap actions that the player reads.
##
## Run with:
##   godot --path . res://Tests/MobileTest.tscn
extends Node

var _passed := 0
var _failed := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameManager.suppress_story = true
	await _run()
	print("---------------------------------------------")
	print("MOBILE TEST: %d passed, %d failed" % [_passed, _failed])
	print("MOBILE TEST PASSED" if _failed == 0 else "MOBILE TEST FAILED")
	get_tree().quit(0 if _failed == 0 else 1)


func _check(condition: bool, label: String) -> void:
	if condition:
		_passed += 1
		print("  PASS  ", label)
	else:
		_failed += 1
		printerr("  FAIL  ", label)


func _run() -> void:
	print("MOHT ADVENTURE MOBILE TEST")
	GameManager.set_touch_mode(1)
	var level = load("res://Levels/Level1.tscn").instantiate()
	add_child(level)
	await _wait_physics(10)

	var controls = level.touch_controls
	_check(controls.visible, "Touch controls show when forced on")
	var viewport: Vector2 = controls.get_viewport_rect().size

	var left = controls.left_button
	var right = controls.right_button
	var jump = controls.jump_button
	for button in [left, right, jump]:
		_check(button.size.x >= 96.0 and button.size.y >= 96.0, "Touch button is comfortably large")
		_check(
			button.position.x >= 0.0 and button.position.y >= 0.0
			and button.position.x + button.size.x <= viewport.x + 1.0
			and button.position.y + button.size.y <= viewport.y + 1.0,
			"Touch button stays on screen"
		)
	_check(jump.position.x > right.position.x, "Jump button is on the right side")

	# Pressing a button should drive the same actions the keyboard uses.
	left.call("_press")
	await _wait_physics(2)
	_check(Input.is_action_pressed("move_left"), "Left button presses move_left")
	left.call("release")
	await _wait_physics(2)
	_check(not Input.is_action_pressed("move_left"), "Releasing left button clears move_left")

	jump.call("_press")
	await _wait_physics(2)
	_check(Input.is_action_pressed("jump"), "Jump button presses jump")
	await _wait_physics(4)
	jump.call("release")
	await _wait_physics(2)
	_check(not level.player.is_on_floor(), "Jump button makes the player leave the ground")
	await _wait_physics(60)

	# Pausing must release any held touch so Mohit does not run on his own.
	left.call("_press")
	await _wait_physics(2)
	level.pause_menu.open()
	await _wait_physics(2)
	_check(not Input.is_action_pressed("move_left"), "Pausing releases held touch buttons")
	level.pause_menu.close()
	await _wait_physics(2)

	# Turning touch controls off hides them.
	GameManager.set_touch_mode(2)
	await _wait_physics(2)
	_check(not controls.visible, "Touch controls hide when disabled")

	GameManager.set_touch_mode(0)
	level.queue_free()
	await get_tree().process_frame


func _wait_physics(frames: int) -> void:
	for i in frames:
		await get_tree().physics_frame
