## Full-screen fade used for scene changes. Lives in an autoload CanvasLayer.
extends CanvasLayer

@onready var cover: ColorRect = $Cover

var _busy := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	cover.color = Color(0.035, 0.06, 0.05, 1.0)
	cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Fade in the very first scene.
	_busy = true
	await get_tree().process_frame
	await _fade_to(0.0, 0.45)
	_busy = false


func change_scene(path: String) -> void:
	# If the startup fade (or another transition) is still running, wait for
	# it instead of silently dropping the request.
	while _busy:
		await get_tree().process_frame
	_busy = true
	cover.mouse_filter = Control.MOUSE_FILTER_STOP
	await _fade_to(1.0, 0.28)
	get_tree().paused = false
	var error := get_tree().change_scene_to_file(path)
	if error != OK:
		push_error("Mohit Adventure could not load scene: %s (error %s)" % [path, error])
		await _fade_to(0.0, 0.25)
		cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_busy = false
		return
	# Wait for the new scene to finish its _ready() pass.
	await get_tree().process_frame
	await get_tree().process_frame
	cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	await _fade_to(0.0, 0.35)
	_busy = false


func _fade_to(alpha: float, duration: float) -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(cover, "color:a", alpha, duration)
	await tween.finished
