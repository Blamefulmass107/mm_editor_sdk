# packages/mm_editor/android/src/main/com/minutemastery/mm_editor/engine/MediaProbe.kt

package com.minutemastery.mm_editor.engine

import android.content.Context
import android.media.MediaMetadataRetriever
import android.net.Uri

object MediaProbe {

    fun probe(context: Context, uriString: String): Map<String, Any?> {
        val retriever = MediaMetadataRetriever()
        val uri = Uri.parse(uriString)

        retriever.setDataSource(context, uri)

        val duration = retriever.extractMetadata(
            MediaMetadataRetriever.METADATA_KEY_DURATION
        )?.toLongOrNull() ?: 0L

        val width = retriever.extractMetadata(
            MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH
        )?.toIntOrNull() ?: 0

        val height = retriever.extractMetadata(
            MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT
        )?.toIntOrNull() ?: 0

        val rotation = retriever.extractMetadata(
            MediaMetadataRetriever.METADATA_KEY_VIDEO_ROTATION
        )?.toIntOrNull() ?: 0

        val hasAudio = retriever.extractMetadata(
            MediaMetadataRetriever.METADATA_KEY_HAS_AUDIO
        ) == "yes"

        retriever.release()

        return mapOf(
            "duration_ms" to duration,
            "width" to width,
            "height" to height,
            "rotation" to rotation,
            "frame_rate" to 30, // Android does not reliably expose FPS
            "has_audio" to hasAudio,
            "audio_sample_rate" to 48000
        )
    }
}
