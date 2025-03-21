# res://plugins/ogui-rom-manager/core/parser_tab_ui.gd
extends Node

var data_manager: Node
var active_tab_index: int = -1
var focused_line_edit: LineEdit = null

func _input(event):
	if focused_line_edit != null and event is InputEventKey and event.pressed:
		if event.is_action("ui_accept") or event.is_action("ui_select") or \
		   event.is_action("ui_left") or event.is_action("ui_right") or \
		   event.is_action("ui_up") or event.is_action("ui_down") or \
		   event.is_action("ui_page_up") or event.is_action("ui_page_down") or \
		   event.is_action("ui_home") or event.is_action("ui_end"):
			get_viewport().set_input_as_handled()

func add_new_tab_in_edit_mode():
	var tab_container = HBoxContainer.new()
	tab_container.layout_mode = 2
	
	var name_input = LineEdit.new()
	name_input.layout_mode = 2
	name_input.size_flags_horizontal = 3
	name_input.placeholder_text = "Enter Parser Name"
	name_input.connect("focus_entered", Callable(self, "_on_line_edit_focus_entered").bind(name_input))
	name_input.connect("focus_exited", Callable(self, "_on_line_edit_focus_exited"))
	
	var confirm_button = Button.new()
	confirm_button.text = "✔"
	confirm_button.layout_mode = 2
	
	tab_container.add_child(name_input)
	tab_container.add_child(confirm_button)
	
	var vbox = get_parent().get_node("HBoxContainer/VBoxContainer")
	var create_button = vbox.get_node("CreateNewParserTab")
	vbox.remove_child(create_button)
	vbox.add_child(tab_container)
	vbox.add_child(create_button)
	
	var tab_index = data_manager.parser_tabs.size()
	data_manager.parser_tabs.append(tab_container)
	confirm_button.connect("pressed", Callable(self, "_on_confirm_parser_name").bind(tab_index))
	name_input.connect("text_submitted", Callable(self, "_on_parser_name_submitted").bind(tab_index))

func _on_line_edit_focus_entered(line_edit: LineEdit):
	focused_line_edit = line_edit

func _on_line_edit_focus_exited():
	focused_line_edit = null

func _on_confirm_parser_name(tab_index):
	var tab_container = data_manager.parser_tabs[tab_index]
	var name_input = tab_container.get_child(0) as LineEdit
	var parser_name = name_input.text.strip_edges()
	if parser_name == "":
		parser_name = "Unnamed Parser"
	finalize_tab(tab_index, parser_name)
	data_manager.save_settings()

func _on_parser_name_submitted(_text, tab_index):
	var tab_container = data_manager.parser_tabs[tab_index]
	var name_input = tab_container.get_child(0) as LineEdit
	var parser_name = name_input.text.strip_edges()
	if parser_name == "":
		parser_name = "Unnamed Parser"
	finalize_tab(tab_index, parser_name)
	data_manager.save_settings()

func finalize_tab(tab_index, parser_name):
	print("Finalizing tab: ", parser_name, " at index: ", tab_index)
	var tab_container = data_manager.parser_tabs[tab_index]
	for child in tab_container.get_children():
		tab_container.remove_child(child)
		child.queue_free()
	
	var tab_button = Button.new()
	tab_button.text = parser_name
	tab_button.layout_mode = 2
	tab_button.size_flags_horizontal = 3
	
	var close_button = Button.new()
	close_button.text = "X"
	close_button.layout_mode = 2
	
	tab_container.add_child(tab_button)
	tab_container.add_child(close_button)
	
	tab_button.connect("pressed", Callable(self, "_on_tab_pressed").bind(tab_index))
	close_button.connect("pressed", Callable(self, "_on_close_tab").bind(tab_index))
	
	var tab_content = create_tab_content(parser_name, tab_index)
	data_manager.tab_contents.append(tab_content)
	data_manager.tab_titles.append(parser_name)
	
	var panel_vbox = get_parent().get_node("HBoxContainer/PanelContainer/VBoxContainer")
	panel_vbox.add_child(tab_content)
	tab_content.hide()
	print("Tab Content Added: ", tab_content)  # Debug print
	
	set_active_tab(tab_index)

func create_tab_content(parser_name, tab_index):
	print("Creating tab content for: ", parser_name)
	var content = VBoxContainer.new()
	content.layout_mode = 2
	content.name = "TabContent" + str(tab_index)
	
	var parser_type_hbox = HBoxContainer.new()
	parser_type_hbox.layout_mode = 2
	parser_type_hbox.name = "HBoxContainer"
	var parser_type_label = Label.new()
	parser_type_label.text = "Parser Type:"
	parser_type_label.layout_mode = 2
	var parser_type_option = OptionButton.new()
	parser_type_option.name = "OptionButton"
	parser_type_option.add_item("Glob")
	parser_type_option.layout_mode = 2
	parser_type_option.connect("item_selected", Callable(self, "_on_parser_type_changed").bind(tab_index))
	parser_type_hbox.add_child(parser_type_label)
	parser_type_hbox.add_child(parser_type_option)
	
	var parser_title_hbox = HBoxContainer.new()
	parser_title_hbox.layout_mode = 2
	parser_title_hbox.name = "HBoxContainer2"
	var parser_title_label = Label.new()
	parser_title_label.text = "Parser Title:"
	parser_title_label.layout_mode = 2
	var parser_title_input = LineEdit.new()
	parser_title_input.name = "LineEdit"
	parser_title_input.text = parser_name
	parser_title_input.layout_mode = 2
	parser_title_input.size_flags_horizontal = 3
	parser_title_input.connect("focus_entered", Callable(self, "_on_line_edit_focus_entered").bind(parser_title_input))
	parser_title_input.connect("focus_exited", Callable(self, "_on_line_edit_focus_exited"))
	parser_title_input.connect("text_changed", Callable(self, "_on_parser_title_changed").bind(tab_index))
	parser_title_input.connect("text_submitted", Callable(self, "save_settings"))
	parser_title_input.connect("focus_exited", Callable(self, "save_settings"))
	parser_title_hbox.add_child(parser_title_label)
	parser_title_hbox.add_child(parser_title_input)
	
	var roms_dirs_vbox = VBoxContainer.new()
	roms_dirs_vbox.layout_mode = 2
	roms_dirs_vbox.name = "VBoxContainer"
	var roms_dirs_label = Label.new()
	roms_dirs_label.text = "Roms Directories:"
	roms_dirs_label.layout_mode = 2
	roms_dirs_vbox.add_child(roms_dirs_label)
	
	var dirs_list = VBoxContainer.new()
	dirs_list.layout_mode = 2
	dirs_list.name = "DirsList"
	roms_dirs_vbox.add_child(dirs_list)
	print("Dirs List Created: ", dirs_list)  # Debug print
	
	var add_dir_button = Button.new()
	add_dir_button.text = "Add Directory"
	add_dir_button.layout_mode = 2
	add_dir_button.connect("pressed", Callable(self, "on_add_directory_pressed").bind(dirs_list))
	print("Add Directory Button Connected: ", add_dir_button.is_connected("pressed", Callable(self, "on_add_directory_pressed")))  # Debug print
	roms_dirs_vbox.add_child(add_dir_button)
	
	var search_glob_hbox = HBoxContainer.new()
	search_glob_hbox.layout_mode = 2
	search_glob_hbox.name = "HBoxContainer3"
	var search_glob_label = Label.new()
	search_glob_label.text = "Search Glob:"
	search_glob_label.layout_mode = 2
	var search_glob_input = LineEdit.new()
	search_glob_input.name = "LineEdit"
	search_glob_input.layout_mode = 2
	search_glob_input.size_flags_horizontal = 3
	search_glob_input.connect("focus_entered", Callable(self, "_on_line_edit_focus_entered").bind(search_glob_input))
	search_glob_input.connect("focus_exited", Callable(self, "_on_line_edit_focus_exited"))
	search_glob_input.connect("text_submitted", Callable(self, "save_settings"))
	search_glob_input.connect("focus_exited", Callable(self, "save_settings"))
	search_glob_hbox.add_child(search_glob_label)
	search_glob_hbox.add_child(search_glob_input)
	
	var executable_hbox = HBoxContainer.new()
	executable_hbox.layout_mode = 2
	executable_hbox.name = "HBoxContainer4"
	var executable_label = Label.new()
	executable_label.text = "Executable:"
	executable_label.layout_mode = 2
	var executable_input = LineEdit.new()
	executable_input.name = "LineEdit"
	executable_input.layout_mode = 2
	executable_input.size_flags_horizontal = 3
	executable_input.connect("focus_entered", Callable(self, "_on_line_edit_focus_entered").bind(executable_input))
	executable_input.connect("focus_exited", Callable(self, "_on_line_edit_focus_exited"))
	executable_input.connect("text_submitted", Callable(self, "save_settings"))
	executable_input.connect("focus_exited", Callable(self, "save_settings"))
	executable_hbox.add_child(executable_label)
	executable_hbox.add_child(executable_input)
	
	content.add_child(parser_type_hbox)
	content.add_child(parser_title_hbox)
	content.add_child(roms_dirs_vbox)
	content.add_child(search_glob_hbox)
	content.add_child(executable_hbox)
	
	return content

func _on_parser_type_changed(index: int, tab_index: int):
	data_manager.save_settings()

func _on_parser_title_changed(new_text: String, tab_index: int):
	data_manager.tab_titles[tab_index] = new_text
	var tab_container = data_manager.parser_tabs[tab_index]
	var tab_button = tab_container.get_child(0) as Button
	tab_button.text = new_text

func on_add_directory_pressed(dirs_list: VBoxContainer):
	print("Dirs List Node: ", dirs_list)  # Debug print
	print("Dirs List Children (Before Adding): ", dirs_list.get_children())  # Debug print
	
	var dir_entry = HBoxContainer.new()
	dir_entry.layout_mode = 2
	dir_entry.name = "DirEntry"  # Add a name for debugging
	print("Dir Entry Created: ", dir_entry)  # Debug print
	
	var dir_input = LineEdit.new()
	dir_input.layout_mode = 2
	dir_input.size_flags_horizontal = 3
	dir_input.placeholder_text = "Enter directory path"
	dir_input.connect("focus_entered", Callable(self, "_on_line_edit_focus_entered").bind(dir_input))
	dir_input.connect("focus_exited", Callable(self, "_on_line_edit_focus_exited"))
	dir_input.connect("text_submitted", Callable(self, "save_settings"))
	dir_input.connect("focus_exited", Callable(self, "save_settings"))
	dir_entry.add_child(dir_input)
	print("LineEdit Added: ", dir_input)  # Debug print
	
	var remove_button = Button.new()
	remove_button.text = "Remove"
	remove_button.layout_mode = 2
	remove_button.connect("pressed", Callable(self, "_on_remove_directory_pressed").bind(dir_entry))
	dir_entry.add_child(remove_button)
	
	dirs_list.add_child(dir_entry)
	print("Dir Entry Added to Dirs List: ", dir_entry)  # Debug print
	print("Dirs List Children (After Adding): ", dirs_list.get_children())  # Debug print

	data_manager.save_settings()

func _on_remove_directory_pressed(dir_entry: HBoxContainer):
	print("Removing directory entry: ", dir_entry)
	var dir_input = dir_entry.get_child(0)  # Get the LineEdit node (first child of DirEntry)
	print("LineEdit Node: ", dir_input)  # Debug print
	dir_entry.get_parent().remove_child(dir_entry)
	dir_entry.queue_free()
	data_manager.save_settings()

func _on_tab_pressed(tab_index):
	print("Tab pressed: ", tab_index)
	set_active_tab(tab_index)

func set_active_tab(tab_index):
	print("Setting active tab: ", tab_index)
	if active_tab_index == tab_index:
		return
	
	if active_tab_index >= 0 and active_tab_index < data_manager.tab_contents.size():
		var prev_content = data_manager.tab_contents[active_tab_index]
		if is_instance_valid(prev_content):
			prev_content.hide()
			print("Hid content for tab: ", active_tab_index)
	
	active_tab_index = tab_index
	
	if tab_index >= 0 and tab_index < data_manager.tab_contents.size():
		var new_content = data_manager.tab_contents[tab_index]
		if is_instance_valid(new_content):
			new_content.show()
			print("Showed content for tab: ", tab_index)
		else:
			print("Error: Content for tab ", tab_index, " is invalid")
	else:
		print("No tab content to show for tab_index: ", tab_index)

func _on_close_tab(tab_index):
	print("Closing tab: ", tab_index)
	if tab_index < 0 or tab_index >= data_manager.parser_tabs.size():
		return
	
	var tab_container = data_manager.parser_tabs[tab_index]
	get_parent().get_node("HBoxContainer/VBoxContainer").remove_child(tab_container)
	tab_container.queue_free()
	
	if tab_index < data_manager.tab_contents.size():
		var content = data_manager.tab_contents[tab_index]
		if content.get_parent():
			content.get_parent().remove_child(content)
		content.queue_free()
	
	var removed_title = data_manager.tab_titles[tab_index]
	data_manager.parser_tabs.remove_at(tab_index)
	data_manager.tab_contents.remove_at(tab_index)
	data_manager.tab_titles.remove_at(tab_index)
	
	for i in range(data_manager.parser_tabs.size()):
		var tab = data_manager.parser_tabs[i]
		var tab_button = tab.get_child(0)
		var close_button = tab.get_child(1)
		tab_button.disconnect("pressed", Callable(self, "_on_tab_pressed"))
		close_button.disconnect("pressed", Callable(self, "_on_close_tab"))
		tab_button.connect("pressed", Callable(self, "_on_tab_pressed").bind(i))
		close_button.connect("pressed", Callable(self, "_on_close_tab").bind(i))
	
	if active_tab_index == tab_index:
		if data_manager.parser_tabs.size() > 0:
			set_active_tab(0)
		else:
			active_tab_index = -1
			set_active_tab(-1)
	elif active_tab_index > tab_index:
		active_tab_index -= 1
	
	data_manager.save_settings()

func save_settings():
	data_manager.save_settings()
