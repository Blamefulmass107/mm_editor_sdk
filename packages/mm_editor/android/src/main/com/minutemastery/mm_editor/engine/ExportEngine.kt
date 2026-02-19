# packages/mm_editor/android/src/main/com/minutemastery/mm_editor/engine/ExportEngine.kt

package com.minutemastery.mm_editor.engine

import android.content.Context
import com.arthenica.ffmpegkit.FFmpegKit
import com.arthenica.ffmpegkit.ReturnCode
import com.minutemastery.mm_editor.engine.transitions.TransitionFactory
import org.json.JSONObject
import java.io.File
import java.util.UUID

object ExportEngine {

    fun export(
        context: Context,
        projectJson: String,
        outputDir: String
    ): Map<String, Any?> {

        val project = JSONObject(projectJson)

        val clips = project
            .getJSONObject("tracks")
            .getJSONObject("video")
            .getJSONArray("clips")

        val transitions = project
            .getJSONObject("tracks")
            .getJSONObject("video")
            .optJSONArray("transitions")

        val assets = project
            .getJSONObject("assets")
            .getJSONArray("media")

        val inputs = mutableListOf<String>()
        val filterParts = mutableListOf<String>()

        var totalDurationMs = 0L
        var offsetSeconds = 0.0

        // 1 Build inputs
        for (i in 0 until clips.length()) {
            val clip = clips.getJSONObject(i)
            val assetId = clip.getString("asset_id")
            val source = clip.getJSONObject("source")

            val inMs = source.getLong("in_ms")
            val outMs = source.getLong("out_ms")

            val asset = findAsset(assets, assetId)
            val uri = asset.getString("uri").replace("file://", "")

            inputs.add("-i \"$uri\"")

            val durationMs = outMs - inMs
            totalDurationMs += durationMs
        }

        // 2 Trim each input in filtergraph
        for (i in 0 until clips.length()) {
            val clip = clips.getJSONObject(i)
            val source = clip.getJSONObject("source")

            val inMs = source.getLong("in_ms")
            val outMs = source.getLong("out_ms")

            filterParts.add(
                "[$i:v]trim=start=${inMs/1000.0}:end=${outMs/1000.0},setpts=PTS-STARTPTS[v$i]"
            )
            filterParts.add(
                "[$i:a]atrim=start=${inMs/1000.0}:end=${outMs/1000.0},asetpts=PTS-STARTPTS[a$i]"
            )
        }

        // 3 Apply transitions chain
        var lastVideo = "[v0]"
        var lastAudio = "[a0]"
        offsetSeconds = (clips.getJSONObject(0)
            .getJSONObject("source")
            .getLong("out_ms")
            - clips.getJSONObject(0)
            .getJSONObject("source")
            .getLong("in_ms")) / 1000.0

        for (i in 1 until clips.length()) {

            val transition = transitions?.optJSONObject(i - 1)
            val durationMs = transition?.optLong("duration_ms") ?: 0L
            val type = transition?.optString("type") ?: "crossfade"

            val durationS = durationMs / 1000.0
            offsetSeconds -= durationS

            val transitionImpl = TransitionFactory.fromType(type)

            val outV = "[vxf$i]"
            val outA = "[axf$i]"

            filterParts.add(
                "$lastVideo[v$i]xfade=transition=${transitionImpl.ffmpegName}:duration=$durationS:offset=$offsetSeconds$outV"
            )

            filterParts.add(
                "$lastAudio[a$i]acrossfade=d=$durationS$outA"
            )

            lastVideo = outV
            lastAudio = outA

            val clipDurationS =
                (clips.getJSONObject(i)
                    .getJSONObject("source")
                    .getLong("out_ms")
                 - clips.getJSONObject(i)
                    .getJSONObject("source")
                    .getLong("in_ms")) / 1000.0

            offsetSeconds += clipDurationS
        }

        // 4 Optional music mix
        var finalAudio = lastAudio

        val musicTrack = project.getJSONObject("tracks").optJSONObject("music")

        if (musicTrack != null && musicTrack.optBoolean("enabled", false)) {

            val musicAssetId = musicTrack.getString("asset_id")
            val audioAssets = project.getJSONObject("assets").getJSONArray("audio")
            val musicAsset = findAsset(audioAssets, musicAssetId)
            val musicUri = musicAsset.getString("uri").replace("file://", "")

            inputs.add("-i \"$musicUri\"")

            val musicInputIndex = inputs.size - 1

            filterParts.add(
                "[$musicInputIndex:a]volume=${musicTrack.optDouble("gain",1.0)}[music]"
            )

            filterParts.add(
                "$lastAudio[music]amix=inputs=2:duration=shortest[finala]"
            )

            finalAudio = "[finala]"
        }

        val filterComplex = filterParts.joinToString(";")

        val outputFile = File(outputDir, "mm_export_${UUID.randomUUID()}.mp4")

        val command = """
            -y
            ${inputs.joinToString(" ")}
            -filter_complex "$filterComplex"
            -map $lastVideo
            -map $finalAudio
            -c:v libx264 -preset fast -crf 18
            -c:a aac -b:a 192k
            "${outputFile.absolutePath}"
        """.trimIndent()

        val session = FFmpegKit.execute(command)

        if (!ReturnCode.isSuccess(session.returnCode)) {
            return error("EXPORT_FAILED", "Unified render failed")
        }

        return mapOf(
            "uri" to "file://${outputFile.absolutePath}",
            "duration_ms" to totalDurationMs
        )
    }

    private fun findAsset(array: org.json.JSONArray, assetId: String): JSONObject {
        for (i in 0 until array.length()) {
            val asset = array.getJSONObject(i)
            if (asset.getString("id") == assetId) return asset
        }
        throw IllegalArgumentException("Asset not found")
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
