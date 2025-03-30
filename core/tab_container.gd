extends TabContainer

# References to the packed scenes for instantiation
@export var text_input_scene: PackedScene = preload("res://core/ui/components/text_input.tscn")
@export var card_button_scene: PackedScene = preload("res://core/ui/components/card_button.tscn")
@export var label_settings: LabelSettings = preload("res://assets/label/title_label.tres")

var SettingsManager = load("res://core/global/settings_manager.tres") as SettingsManager
var tabs_state: TabContainerState
var parser_count = 0
var is_loading = false  # Flag to mark loading process
var logger = Log.get_logger("TabContainer", Log.LEVEL.INFO)

func _ready():
	logger.info("Starting _ready()")
	var card_button = get_parent().get_node("CardButton")
	if card_button:
		card_button.connect("pressed", _on_add_parser_button_pressed)
	
	# Load the TabContainerState
	tabs_state = load("res://core/ui/card_ui/library/library_tabs_state.tres") as TabContainerState
	
	# Load saved settings
	is_loading = true
	load_settings()
	is_loading = false
	logger.info("Finished _ready() with parser_count=" + str(parser_count) + ", tab_count=" + str(get_tab_count()))

func _on_add_parser_button_pressed():
	logger.info("Adding new parser tab")
	add_parser_tab()
	save_settings()
	_update_tabs_state()

func add_parser_tab():
	logger.info("Creating parser tab #" + str(parser_count))
	var parser_tab = VBoxContainer.new()
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
	
	add_child(parser_tab)
	var tab_idx = get_tab_count() - 1
	set_tab_title(tab_idx, default_name)
	
	# Connect signals
	parser_name_input.connect("text_changed", _on_parser_name_changed.bind(parser_tab))
	parser_name_input.connect("text_submitted", func(_text): save_settings())
	executable_input.connect("text_submitted", func(_text): save_settings())
	search_glob_input.connect("text_submitted", func(_text): save_settings())
	add_button.connect("pressed", _on_add_directory_pressed.bind(directories_container))
	remove_button.connect("pressed", _on_remove_parser_pressed.bind(parser_tab))
	
	current_tab = tab_idx
	
	parser_count += 1
	logger.info("Parser tab added, new parser_count=" + str(parser_count))

func _on_parser_name_changed(new_text: String, parser_tab: Node):
	if parser_tab and parser_tab in get_children():
		var tab_idx = parser_tab.get_index()
		set_tab_title(tab_idx, new_text)
		_update_tabs_state()

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
	save_settings()

func _on_remove_directory_pressed(dir_entry: Node, directories_container: VBoxContainer):
	if dir_entry and dir_entry in directories_container.get_children():
		logger.info("Removing directory entry")
		directories_container.remove_child(dir_entry)
		dir_entry.queue_free()
		save_settings()

func _on_remove_parser_pressed(parser_tab: Node):
	if parser_tab and parser_tab in get_children():
		logger.info("Removing parser tab")
		var tab_idx = parser_tab.get_index()
		var tab_name = get_tab_title(tab_idx)
		remove_child(parser_tab)
		parser_tab.queue_free()
		if parser_count > 0:
			parser_count -= 1
		if get_tab_count() > 0:
			current_tab = clamp(current_tab, 0, get_tab_count() - 1)
		else:
			current_tab = -1
		save_settings()
		_update_tabs_state()

func _update_tabs_state():
	if not tabs_state:
		return
	
	# Update tabs_state with current parser names
	var parser_names = []
	for i in range(get_tab_count()):
		var parser_name = get_tab_title(i)
		if parser_name != "Installed" and parser_name != "All Games":
			parser_names.append(parser_name)
	
	# This will trigger tab_added/tab_removed signals in library_menu.gd
	tabs_state.tabs_text = ["Installed", "All Games"] + parser_names

func save_settings():
	if is_loading:
		logger.info("Skipping save_settings() during loading")
		return
	
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

func load_settings():
	var parser_count = SettingsManager.get_value("plugin.oguirommanager", "parser_count", 0)
	logger.info("Loading settings: parser_count=" + str(parser_count))
	
	for i in range(parser_count):
		var section = "plugin.oguirommanager.parser_" + str(i)
		var parser_name = SettingsManager.get_value(section, "name", "Unnamed Parser")
		var executable = SettingsManager.get_value(section, "executable", "")
		var search_glob = SettingsManager.get_value(section, "search_glob", "")
		var rom_dirs = SettingsManager.get_value(section, "roms_dirs", [])
		
		logger.info("Loading parser " + str(i) + ": name=" + parser_name)
		add_parser_tab()
		var parser_tab = get_child(i)
		
		var parser_name_node = parser_tab.get_node("ParserNameInput")
		if parser_name_node:
			# Temporarily disconnect signals to avoid save_settings() during load
			if parser_name_node.is_connected("text_changed", _on_parser_name_changed):
				parser_name_node.disconnect("text_changed", _on_parser_name_changed)
			parser_name_node.text = parser_name
			parser_name_node.connect("text_changed", _on_parser_name_changed.bind(parser_tab))
			set_tab_title(i, parser_name)
		
		var executable_node = parser_tab.get_node("ExecutableInput")
		if executable_node:
			executable_node.text = executable
		
		var search_glob_node = parser_tab.get_node("SearchGlobInput")
		if search_glob_node:
			search_glob_node.text = search_glob
		
		var directories_container = parser_tab.get_node("DirectoriesContainer")
		if directories_container:
			for dir_path in rom_dirs:
				_on_directory_selected(dir_path, directories_container)
				logger.info("Loaded directory: " + dir_path)
	
	self.parser_count = get_tab_count()
	logger.info("Load completed: parser_count=" + str(self.parser_count) + ", tab_count=" + str(get_tab_count()))
	_update_tabs_state()
