# res://plugins/ogui-rom-manager/core/parser_data_manager.gd
extends Node

var SettingsManager := load("res://core/global/settings_manager.tres") as SettingsManager
var parser_tabs: Array = []
var tab_contents: Array = []
var tab_titles: Array = []

func save_settings():
	var old_parser_count = SettingsManager.get_value("plugin.oguirommanager", "parser_count", 0)
	for i in range(old_parser_count):
		var section = "plugin.oguirommanager.parser_" + str(i)
		SettingsManager._config.erase_section(section)
	
	SettingsManager.set_value("plugin.oguirommanager", "parser_count", parser_tabs.size(), false)
	
	for i in range(parser_tabs.size()):
		var section = "plugin.oguirommanager.parser_" + str(i)
		var content = tab_contents[i]
		
		var parser_type_node = content.get_node("HBoxContainer/OptionButton")
		var parser_type = 0
		if parser_type_node:
			parser_type = parser_type_node.selected
		
		var parser_title_node = content.get_node("HBoxContainer2/LineEdit")
		var parser_title = parser_title_node.text if parser_title_node else tab_titles[i]
		
		var search_glob_node = content.get_node("HBoxContainer3/LineEdit")
		var search_glob = search_glob_node.text if search_glob_node else ""
		
		var executable_node = content.get_node("HBoxContainer4/LineEdit")
		var executable = executable_node.text if executable_node else ""
		
		var dirs_list = content.get_node("VBoxContainer/DirsList")
		var rom_dirs = []
		if dirs_list:
			for dir_entry in dirs_list.get_children():
				var dir_input = dir_entry.get_child(0)  # Safe access
				if dir_input and dir_input is LineEdit:
					rom_dirs.append(dir_input.text)
					print("Saving LineEdit text: ", dir_input.text)  # Debug
				else:
					print("Warning: No LineEdit in DirEntry at index ", i)
		
		print("Saving rom_dirs for parser ", i, ": ", rom_dirs)  # Should print ["/mnt"]
		
		SettingsManager.set_value(section, "name", tab_titles[i], false)
		SettingsManager.set_value(section, "type", parser_type, false)
		SettingsManager.set_value(section, "title", parser_title, false)
		SettingsManager.set_value(section, "roms_dirs", rom_dirs, false)
		SettingsManager.set_value(section, "search_glob", search_glob, false)
		SettingsManager.set_value(section, "executable", executable, false)
	
	SettingsManager.save()
	print("Settings saved")

func load_settings(tab_ui: Node):
	var parser_count = SettingsManager.get_value("plugin.oguirommanager", "parser_count", 0)
	print("Parser count: ", parser_count)
	
	for i in range(parser_count):
		var section = "plugin.oguirommanager.parser_" + str(i)
		var parser_name = SettingsManager.get_value(section, "name", "Unnamed Parser")
		print("Loading parser ", i, " with name: ", parser_name)
		
		tab_ui.add_new_tab_in_edit_mode()
		tab_ui.finalize_tab(i, parser_name)
		
		var content = tab_contents[i]
		var parser_type = SettingsManager.get_value(section, "type", 0)
		var parser_title = SettingsManager.get_value(section, "title", parser_name)
		var rom_dirs = SettingsManager.get_value(section, "roms_dirs", [])
		var search_glob = SettingsManager.get_value(section, "search_glob", "")
		var executable = SettingsManager.get_value(section, "executable", "")
		
		print("Loaded rom_dirs: ", rom_dirs)  # Should print ["/mnt"]
		
		var parser_type_node = content.get_node("HBoxContainer/OptionButton")
		if parser_type_node:
			parser_type_node.selected = parser_type
		
		var parser_title_node = content.get_node("HBoxContainer2/LineEdit")
		if parser_title_node:
			parser_title_node.text = parser_title
		
		var search_glob_node = content.get_node("HBoxContainer3/LineEdit")
		if search_glob_node:
			search_glob_node.text = search_glob
		
		var executable_node = content.get_node("HBoxContainer4/LineEdit")
		if executable_node:
			executable_node.text = executable
		
		var dirs_list = content.get_node("VBoxContainer/DirsList")
		if dirs_list:
			for dir_path in rom_dirs:
				var dir_entry = HBoxContainer.new()
				dir_entry.layout_mode = 2
				dir_entry.name = "DirEntry"
				
				var dir_input = LineEdit.new()
				dir_input.layout_mode = 2
				dir_input.size_flags_horizontal = 3
				dir_input.placeholder_text = "Enter directory path"
				dir_input.text = dir_path  # Set text immediately
				print("Set LineEdit text to: ", dir_input.text)  # Confirm "/mnt" is set
				
				dir_input.connect("focus_entered", Callable(tab_ui, "_on_line_edit_focus_entered").bind(dir_input))
				dir_input.connect("focus_exited", Callable(tab_ui, "_on_line_edit_focus_exited"))
				# Do NOT connect save_settings yet to avoid premature saving
				dir_entry.add_child(dir_input)
				
				var remove_button = Button.new()
				remove_button.text = "Remove"
				remove_button.layout_mode = 2
				remove_button.connect("pressed", Callable(tab_ui, "_on_remove_directory_pressed").bind(dir_entry))
				dir_entry.add_child(remove_button)
				
				dirs_list.add_child(dir_entry)
				print("Added DirEntry with text: ", dir_input.text)  # Confirm text persists
	
	# Wait for the scene tree to stabilize
	await get_tree().process_frame
	print("Scene tree stabilized, connecting save signals")
	
	# Now connect save_settings signals
	for i in range(tab_contents.size()):
		var content = tab_contents[i]
		var dirs_list = content.get_node("VBoxContainer/DirsList")
		if dirs_list:
			for dir_entry in dirs_list.get_children():
				var dir_input = dir_entry.get_child(0)  # Safe access to LineEdit
				if dir_input and dir_input is LineEdit:
					dir_input.connect("text_submitted", Callable(tab_ui, "save_settings"))
					dir_input.connect("focus_exited", Callable(tab_ui, "save_settings"))
					print("Post-setup LineEdit text: ", dir_input.text)  # Should still be "/mnt"
