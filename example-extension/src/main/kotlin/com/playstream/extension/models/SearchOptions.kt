package com.playstream.extension.models

data class SearchOptions(
    val media: Media,
    val query: String,
    val year: Int? = null,
    val dub: Boolean = true
)
