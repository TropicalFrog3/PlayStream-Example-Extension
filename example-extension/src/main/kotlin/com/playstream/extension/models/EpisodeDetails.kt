package com.playstream.extension.models

data class EpisodeDetails(
    val id: String,
    val number: Int,
    val url: String,
    val title: String? = null
)
