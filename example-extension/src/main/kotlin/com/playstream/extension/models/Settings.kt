package com.playstream.extension.models

data class Settings(
    val episodeServers: List<String>,
    val supportsDub: Boolean = true
)
