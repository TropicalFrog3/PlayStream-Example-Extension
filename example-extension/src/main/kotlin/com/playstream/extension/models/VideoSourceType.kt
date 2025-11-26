package com.playstream.extension.models

import com.google.gson.annotations.SerializedName

enum class VideoSourceType {
    @SerializedName("mp4")
    MP4,
    
    @SerializedName("m3u8")
    M3U8
}
