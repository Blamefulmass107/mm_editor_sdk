# packages/mm_editor/android/src/main/com/minutemastery/mm_editor/bridge/MethodHandlers.kt

package com.minutemastery.mm_editor

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject

class MethodHandlers {

    fun handle(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {

            "probeMedia" -> {
                val uri = call.argument<String>("uri")
                if (uri == null) {
                    result.success(error("INVALID_ARGUMENT", "Missing uri"))
                    return
                }

                val media = MediaProbe.probe(context, uri)
                result.success(success(mapOf("media" to media)))
            }

            "exportProject" -> {
                val project = call.argument<String>("project")
                val export = call.argument<Map<String, Any>>("export")

                if (project == null) {
                    result.success(error("INVALID_ARGUMENT", "Missing project"))
                    return
                }

                val output = ExportEngine.export(
                    context,
                    project,
                    context.cacheDir.absolutePath
                )

                result.success(success(mapOf("output" to output)))
            }

            else -> result.notImplemented()
        }
    }

    private fun success(payload: Map<String, Any?>): Map<String, Any?> {
        return mapOf("ok" to true) + payload
    }

    private fun error(code: String, message: String): Map<String, Any?> {
        return mapOf(
            "ok" to false,
            "error" to mapOf(
                "code" to code,
                "message" to message
            )
        )
    }
}
