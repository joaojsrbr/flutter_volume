package com.jsr.flutter_volume

import android.media.AudioManager

enum class AudioStream {
    SYSTEM, MUSIC;

    val streamType: Int
        get() {
            return when (this) {
                SYSTEM -> AudioManager.STREAM_SYSTEM
                MUSIC -> AudioManager.STREAM_MUSIC
            }
        }
}