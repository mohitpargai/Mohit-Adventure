## Development validation: loads every scene and script in the project so
## broken paths or parse errors are reported in one pass.
##
## Run with:
##   godot --headless --path . res://Tests/ValidateResources.tscn
extends Node

const FOLDERS := ["res://Scenes", "res://UI", "res://Levels", "res://Scripts", "res://Tests"]

var _scenes := 0
var _scripts := 0
var _failed := 0


func _ready() -> void:
	for folder in FOLDERS:
		_scan(folder)
	print("---------------------------------------------")
	print("RESOURCE CHECK: %d scenes, %d scripts, %d failures" % [_scenes, _scripts, _failed])
	print("RESOURCE CHECK PASSED" if _failed == 0 else "RESOURCE CHECK FAILED")
	get_tree().quit(0 if _failed == 0 else 1)


func _scan(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		_failed += 1
		printerr("  FAIL  could not open folder ", path)
		return
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if name.begins_with("."):
			name = dir.get_next()
			continue
		var full_path := path.path_join(name)
		if dir.current_is_dir():
			_scan(full_path)
		elif name.ends_with(".tscn"):
			_check_resource(full_path, true)
		elif name.ends_with(".gd"):
			_check_resource(full_path, false)
		name = dir.get_next()
	dir.list_dir_end()


func _check_resource(path: String, is_scene: bool) -> void:
	var resource := ResourceLoader.load(path)
	if resource == null:
		_failed += 1
		printerr("  FAIL  could not load ", path)
		return
	if is_scene:
		_scenes += 1
		if not resource is PackedScene:
			_failed += 1
			printerr("  FAIL  not a PackedScene: ", path)
	else:
		_scripts += 1
		if not resource is Script:
			_failed += 1
			printerr("  FAIL  not a Script: ", path)
