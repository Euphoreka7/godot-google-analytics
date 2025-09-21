extends Node

var _client: GA4Client = null
var _pending_events: Array = []

func _ready() -> void:
	var measurement_id = ProjectSettings.get_setting_with_override("addons/google_analytics/measurement_id")
	var api_secret = ProjectSettings.get_setting_with_override("addons/google_analytics/api_secret")
	var not_verbose_print = ProjectSettings.get_setting("addons/google_analytics/not_verbose_print", false)
	var root_url = ProjectSettings.get_setting("addons/google_analytics/root_url", "app://game")
	var referer = ProjectSettings.get_setting("addons/google_analytics/referer", "app://game")

	if measurement_id == null or api_secret == null or measurement_id.is_empty() or api_secret.is_empty():
		push_warning("[GA] Google Analytics settings are not configured. Events will not be tracked.")
		return

	_client = GA4Client.new(measurement_id, api_secret, root_url, referer, not_verbose_print)
	add_child(_client)
	_process_pending_events()


func _process_pending_events() -> void:
	for event in _pending_events:
		if event.get("type") == "page_view":
			track_page_view(event.page_title, event.page_location)
		elif event.get("type") == "event":
			track_event(event.event_name, event.params, event.referer_path)
	_pending_events.clear()


func track_page_view(page_title: String, page_location: String = "") -> void:
	if _client:
		await _client.track_page_view(page_title, page_location)
	else:
		_pending_events.append({
			"type": "page_view",
			"page_title": page_title,
			"page_location": page_location
		})

func track_event(event_name: String, params: Dictionary = {}, referer_path: String = "") -> void:
	if _client:
		await _client.track_event(event_name, params)
	else:
		_pending_events.append({
			"type": "event",
			"event_name": event_name,
			"params": params,
			"referer_path": referer_path
		})
