package com.playstream.extension.models

data class VideoSource(
    val url: String,
    val type: VideoSourceType,
    val quality: String,
    val subtitles: List<VideoSubtitle> = emptyList()
)
