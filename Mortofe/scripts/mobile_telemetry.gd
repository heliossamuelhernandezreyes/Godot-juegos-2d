extends Node

signal report_ready(report: Dictionary)

const REPORT_INTERVAL := 10.0
const MAX_SAMPLES := 900

var elapsed := 0.0
var frame_ms: Array[float] = []
var latest_report: Dictionary = {}

func _process(delta: float) -> void:
	if delta <= 0.0:
		return
	frame_ms.append(delta * 1000.0)
	if frame_ms.size() > MAX_SAMPLES:
		frame_ms.remove_at(0)
	elapsed += delta
	if elapsed >= REPORT_INTERVAL:
		_emit_report()
		elapsed = 0.0
		frame_ms.clear()

func _emit_report() -> void:
	if frame_ms.is_empty():
		return
	var ordered := frame_ms.duplicate()
	ordered.sort()
	var viewport := get_viewport().get_visible_rect().size
	var report := {
		"scope": "mobile" if OS.has_feature("mobile") else "desktop",
		"os": OS.get_name(),
		"device": OS.get_model_name(),
		"renderer": RenderingServer.get_video_adapter_name(),
		"renderer_vendor": RenderingServer.get_video_adapter_vendor(),
		"resolution": [viewport.x, viewport.y],
		"frames": ordered.size(),
		"p50_ms": _percentile(ordered, 0.50),
		"p95_ms": _percentile(ordered, 0.95),
		"p99_ms": _percentile(ordered, 0.99),
		"max_ms": ordered[ordered.size() - 1]
	}
	latest_report = report
	report_ready.emit(report)
	print("MORTOFE_TELEMETRY " + JSON.stringify(report))

func _percentile(values: Array[float], percentile: float) -> float:
	if values.is_empty():
		return 0.0
	var index := clampi(int(round((values.size() - 1) * percentile)), 0, values.size() - 1)
	return snappedf(values[index], 0.001)
