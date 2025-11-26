package com.frog.playstream.extensions

/**
 * Interface that all extension providers must implement.
 * This matches the Dart ExtensionProvider abstract class.
 */
interface IExtensionProvider {
    val extensionId: String
    val name: String
    val version: String
    
    fun search(query: String, imdbId: String? = null, tmdbId: String? = null, mediaType: String? = null): String
    fun findEpisodes(showId: String): String
    fun findEpisodeServer(episodeId: String): String
    fun getSettings(): String
}
