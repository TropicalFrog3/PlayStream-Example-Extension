package com.playstream.extension.template

import com.playstream.extension.MediaProvider
import com.playstream.extension.models.*

/**
 * Template extension provider for PlayStream.
 * Replace this with your own implementation.
 */
class TemplateProvider : MediaProvider() {
    
    override val extensionId = "template-extension"
    override val name = "Template Extension"
    override val version = "1.0.0"
    
    private val baseUrl = "https://example.com"
    
    override fun searchMedia(opts: SearchOptions): List<SearchResult> {
        // TODO: Implement search logic
        // Example:
        // val doc = Fetch.document("$baseUrl/search?q=${Fetch.encode(opts.query)}")
        // Parse and return search results
        
        return emptyList()
    }
    
    override fun getEpisodes(id: String): List<EpisodeDetails> {
        // TODO: Implement episode fetching logic
        // Parse the media ID and return list of episodes
        
        return emptyList()
    }
    
    override fun getEpisodeServer(episode: EpisodeDetails, server: String): EpisodeServer {
        // TODO: Implement video source extraction
        // Extract video URLs from the episode page
        
        return EpisodeServer(
            server = server,
            headers = mapOf("Referer" to baseUrl),
            videoSources = emptyList()
        )
    }
    
    override fun getProviderSettings(): Settings {
        return Settings(
            episodeServers = listOf("default"),
            supportsDub = true
        )
    }
}
