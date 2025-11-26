package com.playstream.extension.models

data class EpisodeServer(
    val server: String,
    val headers: Map<String, String> = emptyMap(),
    val videoSources: List<VideoSource>
)
