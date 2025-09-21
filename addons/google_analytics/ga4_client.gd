extends Node
class_name GA4Client

signal event_completed(event_name: String, success: bool)

const GA4_ENDPOINT = "https://www.google-analytics.com/mp/collect"
const REQUEST_HEADERS = [
	"Content-Type: application/json",
	"User-Agent: Godot-Game/1.0"
]
const DEFAULT_PAGE_TITLE = "Game"

var _measurement_id: String
var _api_secret: String
var _client_id: String = _generate_client_id()
var _session_id: String

var _root_url: String
var _referer: String

var retry_queue: Array = []
var max_retries: int = 1
var retry_delay: float = 0.1
var pending_events: Dictionary = {}

var _not_verbose_print: bool


func _init(
		measurement_id: String,
		api_secret: String,
		root_url: String,
		referer: String,
		not_verbose_print: bool
	) -> void:
		_debug_log("Initializing client with measurement_id: %s" % measurement_id)
		_measurement_id = measurement_id
		_api_secret = api_secret
		_root_url = root_url
		_referer = referer
		_not_verbose_print = not_verbose_print
		_session_id = str(Time.get_unix_time_from_system())


func track_page_view(page_title: String, page_location: String = "") -> void:
	var params = {
		"page_title": page_title,
		"page_location": _root_url + page_location,
		"page_referrer": _referer
	}
	params.merge(_required_event_params())
	track_event("page_view", params)


func track_event(event_name: String, params: Dictionary = {}, referer_path: String = "") -> Signal:
	var event_id = str(Time.get_ticks_msec()) + "_" + event_name
	pending_events[event_id] = event_name

	var event_params = params.duplicate()
	event_params.merge(_required_event_params())

	if not event_params.has("page_location"):
		event_params["page_location"] = _root_url + referer_path

	for key in event_params.keys():
		if event_params[key] is float or event_params[key] is int:
			event_params[key] = str(event_params[key])

	_debug_log("Sending event " + event_name + " with: " + str(event_params))
	_send_request_with_retry(event_name, event_params, 0, event_id)

	return event_completed


func _required_event_params() -> Dictionary:
	return {
		"engagement_time_msec": 100,
		"screen_resolution": "%dx%d" % [DisplayServer.window_get_size().x, DisplayServer.window_get_size().y],
		"session_id": _session_id,
		"session_engaged": 1
	}


func _generate_client_id() -> String:
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var part1 = str(rng.randi())
	var part2 = str(rng.randi())
	return part1 + "." + part2


func _send_request_with_retry(event_name: String, params: Dictionary, retry_count: int = 0, event_id: String = "") -> void:
	var url = "%s?measurement_id=%s&api_secret=%s" % [GA4_ENDPOINT, _measurement_id, _api_secret]

	var data = {
		"client_id": _client_id,
		"events": [{
			"name": event_name,
			"params": params
		}]
	}

	var body = JSON.stringify(data)

	_debug_log("Sending event " + event_name + " with: " + str(params))

	var http_request = HTTPRequest.new()
	add_child(http_request)

	http_request.request_completed.connect(
		_on_request_completed.bind(http_request, event_name, params, retry_count, event_id)
	)

	var error = http_request.request(url, REQUEST_HEADERS, HTTPClient.METHOD_POST, body)
	if error != OK:
		_handle_request_failure(http_request, event_name, params, retry_count, event_id)


func _on_request_completed(
		result: int,
		response_code: int,
		headers: PackedStringArray,
		body: PackedByteArray,
		http_request: HTTPRequest,
		event_name: String,
		params: Dictionary,
		retry_count: int,
		event_id: String) -> void:

	http_request.queue_free()

	if response_code == 204:
		_handle_request_success(event_id)
	else:
		push_error("[GA] Request failed with code: %d" % response_code)
		if body.size() > 0:
			var response = body.get_string_from_utf8()
			push_error("[GA] Response: %s" % response)
		_handle_request_failure(null, event_name, params, retry_count, event_id)


func _handle_request_success(event_id: String) -> void:
	if event_id in pending_events:
		var event_name = pending_events[event_id]
		event_completed.emit(event_name, true)
		pending_events.erase(event_id)
		_debug_log("Event sent successfully: " + event_name)


func _handle_request_failure(http_request: HTTPRequest, event_name: String, params: Dictionary, retry_count: int, event_id: String) -> void:
	if http_request != null:
		http_request.queue_free()

	if retry_count < max_retries:
		retry_queue.push_back({
			"event_name": event_name,
			"params": params,
			"retry_count": retry_count + 1,
			"timestamp": Time.get_unix_time_from_system(),
			"event_id": event_id
		})
		_schedule_retry()
	else:
		if event_id in pending_events:
			var failed_event_name = pending_events[event_id]
			event_completed.emit(failed_event_name, false)
			pending_events.erase(event_id)
			push_error("[GA] Failed to send event after %d attempts: %s" % [max_retries, failed_event_name])


func _schedule_retry() -> void:
	if retry_queue.size() > 0:
		var timer = Timer.new()
		timer.one_shot = true
		timer.wait_time = retry_delay
		timer.timeout.connect(_process_retry_queue)
		add_child(timer)
		timer.start()


func _process_retry_queue() -> void:
	if retry_queue.size() == 0:
		return

	var request_data = retry_queue.pop_front()
	_send_request_with_retry(request_data.event_name, request_data.params, request_data.retry_count, request_data.event_id)


func _debug_log(message: String) -> void:
	if _not_verbose_print or OS.is_stdout_verbose():
		print("[GA] %s" % message)
