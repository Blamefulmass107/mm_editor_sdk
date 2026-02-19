# packages/mm_editor/android/src/main/com/minutemastery/mm_editor/engine/transitions/Transition.kt

package com.minutemastery.mm_editor.engine.transitions

interface Transition {
    val ffmpegName: String
}

object TransitionFactory {
    fun fromType(type: String): Transition {
        return when (type) {
            "crossfade" -> XfadeTransition()
            "dip_black" -> DipBlackTransition()
            "dip_white" -> DipWhiteTransition()
            "wipe_lr" -> WipeLRTransition()
            "slide_lr" -> SlideLRTransition()
            "slide_rl" -> SlideRLTransition()
            else -> XfadeTransition()
        }
    }
}
