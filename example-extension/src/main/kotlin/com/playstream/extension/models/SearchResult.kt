package com.playstream.extension.models

data class SearchResult(
    val id: String,
    val title: String,
    val url: String,
    val subOrDub: String? = null
)
