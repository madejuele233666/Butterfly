package dev.linwood.butterfly

import android.os.Build
import android.os.SystemClock
import android.view.InputDevice
import android.view.KeyEvent
import android.view.MotionEvent
import androidx.annotation.UiThread
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject
import java.util.ArrayDeque

/**
 * M1 application-boundary input probe.
 *
 * Records into a bounded in-memory ring and never performs per-event disk or
 * Logcat I/O. Flutter explicitly snapshots the ring after a test action.
 */
class StylusProbePlugin(
    private val activity: MainActivity,
    flutterEngine: FlutterEngine,
) : MethodChannel.MethodCallHandler {
    companion object {
        private const val CHANNEL = "dev.linwood.notea/m1_probe"
        private const val DEFAULT_CAPACITY = 32768
        private const val MAX_CHUNK = 1024
    }

    private val records = ArrayDeque<String>(DEFAULT_CAPACITY)
    private var capacity = DEFAULT_CAPACITY
    private var dropped = 0L
    private var captured = 0L
    private var running = false
    private val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)

    init {
        channel.setMethodCallHandler(this)
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "start" -> {
                val requested = call.argument<Int>("capacity") ?: DEFAULT_CAPACITY
                capacity = requested.coerceIn(1024, 131072)
                running = BuildConfig.M1_PROBE_ENABLED
                result.success(status())
            }
            "stop" -> {
                running = false
                result.success(status())
            }
            "reset" -> {
                records.clear()
                dropped = 0
                captured = 0
                result.success(status())
            }
            "status" -> result.success(status())
            "records" -> {
                val offset = (call.argument<Int>("offset") ?: 0).coerceAtLeast(0)
                val limit = (call.argument<Int>("limit") ?: MAX_CHUNK).coerceIn(1, MAX_CHUNK)
                result.success(records.drop(offset).take(limit))
            }
            else -> result.notImplemented()
        }
    }

    @UiThread
    fun captureTouch(event: MotionEvent) = captureMotion("touch", event)

    @UiThread
    fun captureGenericMotion(event: MotionEvent) = captureMotion("generic_motion", event)

    @UiThread
    fun captureKey(event: KeyEvent) {
        if (!running || !BuildConfig.M1_PROBE_ENABLED) return
        val device = event.device
        append(
            JSONObject()
                .put("schema", "notea.m1.key/v1")
                .put("sourceLayer", "android")
                .put("recordedElapsedNanos", SystemClock.elapsedRealtimeNanos())
                .put("eventTimeNanos", event.eventTime * 1_000_000L)
                .put("downTimeNanos", event.downTime * 1_000_000L)
                .put("action", event.action)
                .put("keyCode", event.keyCode)
                .put("scanCode", event.scanCode)
                .put("repeatCount", event.repeatCount)
                .put("metaState", event.metaState)
                .put("flags", event.flags)
                .put("source", event.source)
                .put("device", deviceJson(device))
                .toString(),
        )
    }

    private fun captureMotion(kind: String, event: MotionEvent) {
        if (!running || !BuildConfig.M1_PROBE_ENABLED) return
        val pointers = JSONArray()
        for (pointerIndex in 0 until event.pointerCount) {
            val history = JSONArray()
            for (historyIndex in 0 until event.historySize) {
                history.put(sampleJson(event, pointerIndex, historyIndex))
            }
            pointers.put(
                sampleJson(event, pointerIndex, null)
                    .put("pointerId", event.getPointerId(pointerIndex))
                    .put("toolType", event.getToolType(pointerIndex))
                    .put("history", history),
            )
        }
        append(
            JSONObject()
                .put("schema", "notea.m1.motion/v1")
                .put("sourceLayer", "android")
                .put("dispatch", kind)
                .put("recordedElapsedNanos", SystemClock.elapsedRealtimeNanos())
                .put("eventTimeNanos", event.eventTime * 1_000_000L)
                .put("downTimeNanos", event.downTime * 1_000_000L)
                .put("action", event.action)
                .put("actionMasked", event.actionMasked)
                .put("actionIndex", event.actionIndex)
                .put("actionButton", if (Build.VERSION.SDK_INT >= 23) event.actionButton else 0)
                .put("buttonState", event.buttonState)
                .put("source", event.source)
                .put("deviceId", event.deviceId)
                .put("flags", event.flags)
                .put("canceled", event.actionMasked == MotionEvent.ACTION_CANCEL)
                .put("historySize", event.historySize)
                .put("pointerCount", event.pointerCount)
                .put("refreshRateHz", activity.currentRefreshRate())
                .put("device", deviceJson(event.device))
                .put("pointers", pointers)
                .toString(),
        )
    }

    private fun sampleJson(event: MotionEvent, pointerIndex: Int, historyIndex: Int?): JSONObject {
        fun axis(axis: Int): Float = if (historyIndex == null) {
            event.getAxisValue(axis, pointerIndex)
        } else {
            event.getHistoricalAxisValue(axis, pointerIndex, historyIndex)
        }
        fun x(): Float = if (historyIndex == null) event.getX(pointerIndex) else event.getHistoricalX(pointerIndex, historyIndex)
        fun y(): Float = if (historyIndex == null) event.getY(pointerIndex) else event.getHistoricalY(pointerIndex, historyIndex)
        fun pressure(): Float = if (historyIndex == null) event.getPressure(pointerIndex) else event.getHistoricalPressure(pointerIndex, historyIndex)
        fun size(): Float = if (historyIndex == null) event.getSize(pointerIndex) else event.getHistoricalSize(pointerIndex, historyIndex)
        val timeNanos = if (historyIndex == null) {
            event.eventTime * 1_000_000L
        } else {
            event.getHistoricalEventTime(historyIndex) * 1_000_000L
        }
        return JSONObject()
            .put("eventTimeNanos", timeNanos)
            .put("x", x().toDouble())
            .put("y", y().toDouble())
            .put("pressure", pressure().toDouble())
            .put("size", size().toDouble())
            .put("tilt", axis(MotionEvent.AXIS_TILT).toDouble())
            .put("orientation", axis(MotionEvent.AXIS_ORIENTATION).toDouble())
            .put("distance", axis(MotionEvent.AXIS_DISTANCE).toDouble())
    }

    private fun deviceJson(device: InputDevice?): Any {
        if (device == null) return JSONObject.NULL
        return JSONObject()
            .put("id", device.id)
            .put("name", device.name)
            .put("descriptor", device.descriptor)
            .put("vendorId", if (Build.VERSION.SDK_INT >= 19) device.vendorId else 0)
            .put("productId", if (Build.VERSION.SDK_INT >= 19) device.productId else 0)
            .put("sources", device.sources)
    }

    private fun append(record: String) {
        captured += 1
        while (records.size >= capacity) {
            records.removeFirst()
            dropped += 1
        }
        records.addLast(record)
    }

    private fun status(): Map<String, Any> = mapOf(
        "available" to BuildConfig.M1_PROBE_ENABLED,
        "running" to running,
        "capacity" to capacity,
        "retained" to records.size,
        "captured" to captured,
        "dropped" to dropped,
        "refreshRateHz" to activity.currentRefreshRate(),
        "sdkInt" to Build.VERSION.SDK_INT,
        "fingerprint" to Build.FINGERPRINT,
        "manufacturer" to Build.MANUFACTURER,
        "model" to Build.MODEL,
    )
}
