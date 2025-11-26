package com.playstream.extension.models

data class Media(
    val id: Int,
    val imdbId: String? = null,
    val tmdbId: String? = null,
    val status: String? = null,
    val format: String? = null,
    val englishTitle: String? = null,
    val episodeCount: Int? = null,
    val absoluteSeasonOffset: Int? = null,
    val synonyms: List<String> = emptyList(),
    val isAdult: Boolean,
    val startDate: FuzzyDate? = null
)

data class FuzzyDate(
    val year: Int? = null,
    val month: Int? = null,
    val day: Int? = null
)
