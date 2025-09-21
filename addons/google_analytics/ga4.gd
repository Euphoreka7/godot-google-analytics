@tool
extends EditorPlugin

const SETTINGS_PATH = "addons/google_analytics"
const AUTOLOAD_NAME = "GA4"
const GA4_SINGLETON_PATH = "res://addons/google_analytics/ga4_singleton.gd"

func _enter_tree() -> void:
	print("GA4 plugin entered tree")
	# Add project settings for GA4 configuration
	add_project_setting("measurement_id", "", TYPE_STRING)
	add_project_setting("api_secret", "", TYPE_STRING)
	add_project_setting("root_url", "app://game", TYPE_STRING)
	add_project_setting("referer", "app://game", TYPE_STRING)
	add_project_setting("not_verbose_print", false, TYPE_BOOL)

	# Add GA4 singleton
	add_autoload_singleton(AUTOLOAD_NAME, GA4_SINGLETON_PATH)

func _exit_tree() -> void:
	# Remove GA4 singleton
	remove_autoload_singleton(AUTOLOAD_NAME)

func add_project_setting(name: String, default_value, type: int) -> void:
	var setting_path = SETTINGS_PATH + "/" + name
	if not ProjectSettings.has_setting(setting_path):
		ProjectSettings.set_setting(setting_path, default_value)
		ProjectSettings.set_initial_value(setting_path, default_value)
		ProjectSettings.add_property_info({
			"name": setting_path,
			"type": type,
			"hint": PROPERTY_HINT_NONE,
			"hint_string": "",
		})

		ProjectSettings.save()
