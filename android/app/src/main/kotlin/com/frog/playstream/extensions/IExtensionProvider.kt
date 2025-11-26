package com.frog.playstream.extensions

/**
 * Interface that all extension providers must implement.
 * This matches the Dart ExtensionProvider abstract class.
 */
interface IExtensionProvider {
    /**
     * Unique identifier for the extension
     */
    val extensionId: String
    
    /**
     * Display name of the extension
     */
    val name: String
    
    /**
     * Version of the extension
     */
    val version: String
    
    /**
     * Search for content (movies/shows)
     * @param query Search query string
     * @param imdbId Optional IMDB ID for the content
     * @param tmdbId Optional TMDB ID for the content
     * @param mediaType Optional media type: "movie" or "tv"
     * @return JSON string containing list of SearchResult objects
     */
    fun search(query: String, imdbId: String? = null, tmdbId: String? = null, mediaType: String? = null): String
    
    /**
     * Find episodes for a show
     * @param showId Unique identifier for the show
     * @return JSON string containing list of episodes with provider, id, number, url, title
     */
    fun findEpisodes(showId: String): String
    
    /**
     * Get server details for an episode
     * @param episodeId Unique identifier for the episode
     * @return JSON string containing server details with provider, server, headers, videoSources
     */
    fun findEpisodeServer(episodeId: String): String
    
    /**
     * Get extension settings/configuration
     * @return JSON string containing ExtensionSettings object
     */
    fun getSettings(): String
}
