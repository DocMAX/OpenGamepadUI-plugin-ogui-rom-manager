extends TabContainer

# References to the packed scenes for instantiation
@export var text_input_scene: PackedScene = preload("res://core/ui/components/text_input.tscn")
@export var card_button_scene: PackedScene = preload("res://core/ui/components/card_button.tscn")
@export var label_settings: LabelSettings = preload("res://assets/label/title_label.tres")
@export var parser_tab_scene: PackedScene = preload("res://plugins/ogui-rom-manager/core/parser_tab.tscn")

var SettingsManager = load("res://core/global/settings_manager.tres") as SettingsManager
var tabs_state: TabContainerState
var parser_count = 0
var logger = Log.get_logger("TabContainer", Log.LEVEL.INFO)


func _ready():
	logger.info("Starting _ready()")
	var card_button = get_parent().get_node("ParserButton")
	if card_button:
		card_button.connect("pressed", _on_add_parser_button_pressed)
	var save_button = get_parent().get_node("SaveButton")
	if save_button:
		save_button.connect("pressed", _on_save_button_pressed)
	load_settings()


func _create_parser_tab() -> VBoxContainer:
	var parser_tab = VBoxContainer.new()
	parser_tab.name = "ParserTab" + str(parser_count)
	parser_tab.size_flags_vertical = SIZE_SHRINK_BEGIN
	
	var parser_name_input = text_input_scene.instantiate()
	parser_name_input.name = "ParserNameInput"
	parser_name_input.title = "Parser name:"
	parser_name_input.description = ""
	parser_name_input.size_flags_vertical = SIZE_EXPAND_FILL
	var default_name = "Parser" + str(parser_count + 1)
	parser_name_input.text = default_name
	parser_tab.add_child(parser_name_input)
	
	var executable_input = text_input_scene.instantiate()
	executable_input.name = "ExecutableInput"
	executable_input.title = "Executable:"
	executable_input.description = ""
	executable_input.size_flags_vertical = SIZE_EXPAND_FILL
	parser_tab.add_child(executable_input)
	
	var search_glob_input = text_input_scene.instantiate()
	search_glob_input.name = "SearchGlobInput"
	search_glob_input.title = "Search glob:"
	search_glob_input.description = ""
	search_glob_input.size_flags_vertical = SIZE_EXPAND_FILL
	parser_tab.add_child(search_glob_input)
	
	var directories_label = Label.new()
	directories_label.name = "DirectoriesLabel"
	directories_label.text = "Search Directories:"
	directories_label.label_settings = label_settings
	parser_tab.add_child(directories_label)
	
	var directories_container = VBoxContainer.new()
	directories_container.name = "DirectoriesContainer"
	directories_container.custom_minimum_size = Vector2(0, 100)
	parser_tab.add_child(directories_container)
	
	var button_container = HBoxContainer.new()
	button_container.name = "ButtonContainer"
	parser_tab.add_child(button_container)
	
	var add_button = card_button_scene.instantiate()
	add_button.name = "AddDirectoryButton"
	add_button.text = "Add Directory"
	add_button.uppercase = false
	button_container.add_child(add_button)
	
	var remove_button = card_button_scene.instantiate()
	remove_button.name = "RemoveParserButton"
	remove_button.text = "Remove Parser"
	remove_button.uppercase = false
	button_container.add_child(remove_button)
	
	return parser_tab


func library_tab_exists(name: String) -> bool:
	var tabs_state := load("res://core/ui/card_ui/library/library_tabs_state.tres") as TabContainerState
	if tabs_state:
		return name in tabs_state.tabs_text
	return false


func add_library_tab(name: String):
	var tabs_state := load("res://core/ui/card_ui/library/library_tabs_state.tres") as TabContainerState
	if not tabs_state:
		return
	
	# Check if tab already exists
	if library_tab_exists(name):
		logger.info("Library tab '" + name + "' already exists, skipping creation")
		return
		
	var scene_resource := load("res://plugins/ogui-rom-manager/core/parser_tab.tscn") as PackedScene
	var library_tab_node := scene_resource.instantiate() as ScrollContainer
	library_tab_node.name = name
	tabs_state.add_tab(name, library_tab_node)
	logger.info("Added library tab: " + name)


func remove_library_tab(name: String):
	var tabs_state := load("res://core/ui/card_ui/library/library_tabs_state.tres") as TabContainerState
	if not tabs_state:
		return
		
	if name in tabs_state.tabs_text:
		tabs_state.remove_tab(name)
		logger.info("Removed library tab: " + name)


func _update_tabs_state():
	if not tabs_state:
		tabs_state = load("res://core/ui/card_ui/library/library_tabs_state.tres") as TabContainerState
		if not tabs_state:
			return
	
	# Make sure the tab lists are in sync
	var parser_tab_names = []
	for i in range(get_tab_count()):
		parser_tab_names.append(get_tab_title(i))
	
	# Handle any library tabs that don't have corresponding parser tabs
	var tabs_to_check = tabs_state.tabs_text.duplicate()
	for tab_name in tabs_to_check:
		# Skip default tabs
		if tab_name == "All Games" or tab_name == "Installed":
			continue
			
		if not tab_name in parser_tab_names:
			remove_library_tab(tab_name)


func _on_add_parser_button_pressed():
	logger.info("Adding new parser tab")
	var parser_tab = _create_parser_tab() # Use internal method
	add_child(parser_tab)
	var tab_idx = get_tab_count() - 1
	var default_name = "Parser" + str(parser_count + 1)
	set_tab_title(tab_idx, default_name)

	# Connect signals
	var parser_name_input = parser_tab.get_node("ParserNameInput")
	var executable_input = parser_tab.get_node("ExecutableInput")
	var search_glob_input = parser_tab.get_node("SearchGlobInput")
	var add_button = parser_tab.get_node("ButtonContainer").get_node("AddDirectoryButton")
	var remove_button = parser_tab.get_node("ButtonContainer").get_node("RemoveParserButton")
	var directories_container = parser_tab.get_node("DirectoriesContainer")
	
	parser_name_input.connect("text_changed", _on_parser_name_changed.bind(parser_tab))
	parser_name_input.connect("text_submitted", func(_text): _on_save_button_pressed())
	executable_input.connect("text_submitted", func(_text): _on_save_button_pressed())
	search_glob_input.connect("text_submitted", func(_text): _on_save_button_pressed())
	add_button.connect("pressed", _on_add_directory_pressed.bind(directories_container))
	remove_button.connect("pressed", _on_remove_parser_pressed.bind(parser_tab))
	
	parser_count += 1
	logger.info("Parser tab added, new parser_count=" + str(parser_count))
	
	# When adding a tab manually, also add the corresponding library tab
	call_deferred("add_library_tab", default_name)

	save_settings()
	_update_tabs_state()
	await get_tree().create_timer(0.1).timeout
	if tabs_state:
		tabs_state.current_tab = get_tab_count() - 1

	# Populate the ParserGrid with library items
	call_deferred("_populate_parser_grid", parser_tab, default_name)


func _populate_parser_grid(parser_tab: VBoxContainer, parser_name: String) -> void:
	var library_manager = load("res://core/global/library_manager.tres") as LibraryManager
	var card_scene := load("res://core/ui/components/card.tscn") as PackedScene
	var parser_grid = parser_tab.get_node("/root/CardUI/MenuContent/FullscreenMenus/LibraryMenu/TabContainer/" + parser_name + "/MarginContainer/ParserGrid") as HFlowContainer

	# Filter library items by the parser name tag
	var library_items := library_manager.get_library_items()

	# Create and add cards to the grid
	for item in library_items:
		if not parser_name in item.tags:
			continue
		var card = card_scene.instantiate() as GameCard
		await card.set_library_item(item)
		parser_grid.add_child(card)


func _on_parser_name_changed(new_text: String, parser_tab: Node):
	if parser_tab and parser_tab in get_children():
		var tab_idx = parser_tab.get_index()
		var old_title = get_tab_title(tab_idx)
		set_tab_title(tab_idx, new_text)
		
		# Update the library tab
		if old_title != new_text:
			remove_library_tab(old_title)
			call_deferred("add_library_tab", new_text)
		
		if tabs_state:
			if tab_idx < tabs_state.tabs_text.size():
				tabs_state.tabs_text[tab_idx] = new_text
				tabs_state.tab_changed.emit(tab_idx)
		
		_update_tabs_state()
		save_settings()


func _on_add_directory_pressed(directories_container: VBoxContainer):
	var file_dialog = FileDialog.new()
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	file_dialog.size = Vector2(600, 400)
	file_dialog.title = "Select a Directory"
	file_dialog.current_dir = "/"
	
	get_tree().root.add_child(file_dialog)
	
	file_dialog.connect("dir_selected", _on_directory_selected.bind(directories_container))
	file_dialog.connect("visibility_changed", _on_file_dialog_closed.bind(file_dialog))
	file_dialog.popup_centered()


func _on_file_dialog_closed(file_dialog: FileDialog):
	if not file_dialog.visible:
		file_dialog.queue_free()


func _on_directory_selected(dir_path: String, directories_container: VBoxContainer):
	logger.info("Adding directory: " + dir_path)
	var dir_entry = HBoxContainer.new()
	dir_entry.name = "DirEntry" + str(directories_container.get_child_count())
	
	var dir_label = Label.new()
	dir_label.name = "DirLabel"
	dir_label.text = dir_path
	dir_label.size_flags_horizontal = SIZE_EXPAND_FILL
	dir_entry.add_child(dir_label)
	
	var remove_button = card_button_scene.instantiate()
	remove_button.text = "Remove"
	remove_button.uppercase = false
	dir_entry.add_child(remove_button)
	
	remove_button.connect("pressed", _on_remove_directory_pressed.bind(dir_entry, directories_container))
	
	directories_container.add_child(dir_entry)
	_on_save_button_pressed()


func _on_remove_directory_pressed(dir_entry: Node, directories_container: VBoxContainer):
	if dir_entry and dir_entry in directories_container.get_children():
		logger.info("Removing directory entry")
		directories_container.remove_child(dir_entry)
		dir_entry.queue_free()
		_on_save_button_pressed()


func _on_remove_parser_pressed(parser_tab: Node):
	if parser_tab and parser_tab in get_children():
		logger.info("Removing parser tab")
		var tab_idx = parser_tab.get_index()
		var tab_name = get_tab_title(tab_idx)
		
		# Remove the library tab first
		remove_library_tab(tab_name)
		
		# Then remove the parser tab
		remove_child(parser_tab)
		parser_tab.queue_free()

		if parser_count > 0:
			parser_count -= 1
		else:
			parser_count = 0

		_update_tabs_state() # Keep things in sync
		save_settings() # Persist removal
		
		# Ensure current_tab is valid
		if tabs_state:
			tabs_state.current_tab = clamp(tabs_state.current_tab, 0, tabs_state.tabs_text.size() -1)


func _on_save_button_pressed():
	save_settings()
	_update_tabs_state()
	logger.info("Settings saved via button press")


func load_settings():
	# Clear existing tabs and library tabs before loading
	for i in range(get_tab_count() - 1, -1, -1):
		var tab = get_child(i)
		remove_child(tab)
		tab.queue_free()
	
	# Clear any existing library tabs related to parsers
	var tabs_state := load("res://core/ui/card_ui/library/library_tabs_state.tres") as TabContainerState
	if tabs_state:
		var tab_names_to_remove = []
		for tab_name in tabs_state.tabs_text:
			# Check if this is a tab we created (excluding default tabs)
			if tab_name != "All Games" and tab_name != "Installed":
				tab_names_to_remove.append(tab_name)
		
		for tab_name in tab_names_to_remove:
			remove_library_tab(tab_name)
	
	parser_count = 0  # Reset parser count
	var config_parser_count = SettingsManager.get_value("plugin.oguirommanager", "parser_count", 0)
	logger.info("Loading settings: parser_count=" + str(config_parser_count))
	
	for i in range(config_parser_count):
		var section = "plugin.oguirommanager.parser_" + str(i)
		var parser_name = SettingsManager.get_value(section, "name", "Unnamed Parser")
		var executable = SettingsManager.get_value(section, "executable", "")
		var search_glob = SettingsManager.get_value(section, "search_glob", "")
		var rom_dirs = SettingsManager.get_value(section, "roms_dirs", [])
		
		logger.info("Loading parser " + str(i) + ": name=" + parser_name + ", executable=" + executable + ", glob=" + search_glob)
		
		# Create the parser tab
		var parser_tab = _create_parser_tab()
		add_child(parser_tab)
		var tab_idx = get_tab_count() - 1
		set_tab_title(tab_idx, parser_name)
		
		# Connect signals
		var parser_name_input = parser_tab.get_node("ParserNameInput")
		var executable_input = parser_tab.get_node("ExecutableInput")
		var search_glob_input = parser_tab.get_node("SearchGlobInput")
		var add_button = parser_tab.get_node("ButtonContainer").get_node("AddDirectoryButton")
		var remove_button = parser_tab.get_node("ButtonContainer").get_node("RemoveParserButton")
		var directories_container = parser_tab.get_node("DirectoriesContainer")
	
		parser_name_input.connect("text_changed", _on_parser_name_changed.bind(parser_tab))
		parser_name_input.connect("text_submitted", func(_text): _on_save_button_pressed())
		executable_input.connect("text_submitted", func(_text): _on_save_button_pressed())
		search_glob_input.connect("text_submitted", func(_text): _on_save_button_pressed())
		add_button.connect("pressed", _on_add_directory_pressed.bind(directories_container))
		remove_button.connect("pressed", _on_remove_parser_pressed.bind(parser_tab))
		
		# Now update the fields with the loaded values
		if parser_tab:
			parser_name_input.text = parser_name
			executable_input.text = executable
			search_glob_input.text = search_glob
			if directories_container:
				for child in directories_container.get_children():
					directories_container.remove_child(child)
					child.queue_free()
				
				# Add directories from config
				for dir_path in rom_dirs:
					var dir_entry = HBoxContainer.new()
					dir_entry.name = "DirEntry" + str(directories_container.get_child_count())
					
					var dir_label = Label.new()
					dir_label.name = "DirLabel"
					dir_label.text = dir_path
					dir_label.size_flags_horizontal = SIZE_EXPAND_FILL
					dir_entry.add_child(dir_label)
					
					var remove_dir_button = card_button_scene.instantiate()
					remove_dir_button.text = "Remove"
					remove_dir_button.uppercase = false
					dir_entry.add_child(remove_dir_button)
					
					remove_dir_button.connect("pressed", _on_remove_directory_pressed.bind(dir_entry, directories_container))
					
					directories_container.add_child(dir_entry)
					logger.info("Loaded directory: " + dir_path)
			
			# Add the library tab for this parser
			call_deferred("add_library_tab", parser_name)
	
			# Populate the ParserGrid with library items
			call_deferred("_populate_parser_grid", parser_tab, parser_name)
	
	logger.info("Load completed: parser_count=" + str(parser_count) + ", tab_count=" + str(get_tab_count()))
	_update_tabs_state()
	
	# Ensure current_tab is valid after loading
	if tabs_state:
		tabs_state.current_tab = clamp(tabs_state.current_tab, 0, get_tab_count() - 1)


func save_settings():
	logger.info("Saving settings, parser_count=" + str(get_tab_count()))
	var old_parser_count = SettingsManager.get_value("plugin.oguirommanager", "parser_count", 0)
	for i in range(old_parser_count):
		var section = "plugin.oguirommanager.parser_" + str(i)
		SettingsManager._config.erase_section(section)
	
	SettingsManager.set_value("plugin.oguirommanager", "parser_count", get_tab_count(), false)
	
	for i in range(get_tab_count()):
		var section = "plugin.oguirommanager.parser_" + str(i)
		var parser_tab = get_child(i)
		
		var parser_name_node = parser_tab.get_node("ParserNameInput")
		var parser_name = parser_name_node.text if parser_name_node else "Unnamed Parser"
		
		var executable_node = parser_tab.get_node("ExecutableInput")
		var executable = executable_node.text if executable_node else ""
		
		var search_glob_node = parser_tab.get_node("SearchGlobInput")
		var search_glob = search_glob_node.text if search_glob_node else ""
		
		var directories_container = parser_tab.get_node("DirectoriesContainer")
		var rom_dirs = []
		if directories_container:
			for dir_entry in directories_container.get_children():
				var dir_label = dir_entry.get_node("DirLabel")
				if dir_label:
					rom_dirs.append(dir_label.text)
				else:
					logger.warn("No DirLabel found in DirEntry in tab " + str(i))
		
		SettingsManager.set_value(section, "name", parser_name, false)
		SettingsManager.set_value(section, "executable", executable, false)
		SettingsManager.set_value(section, "search_glob", search_glob, false)
		SettingsManager.set_value(section, "roms_dirs", rom_dirs, false)
	
	SettingsManager.save()
	logger.info("Settings saved: parser_count=" + str(get_tab_count()))
