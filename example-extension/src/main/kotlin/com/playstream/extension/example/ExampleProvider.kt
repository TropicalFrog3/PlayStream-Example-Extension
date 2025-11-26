package com.playstream.extension.example

import com.playstream.extension.MediaProvider
import com.playstream.extension.models.*
import com.playstream.extension.utils.Fetch

/**
 * Example extension provider for PlayStream.
 * This is a template that you can use to create your own extension.
 */
class ExampleProvider : MediaProvider() {
    
    override val extensionId = "example-extension"
    override val name = "Example Extension"
    override val version = "1.0.0"
    
    private val baseUrl = "https://www.vidking.net"
    private val videoExtractor = VideoExtractor()
    
    override fun searchMedia(opts: SearchOptions): List<SearchResult> {
        // Example using Fetch utility:
        // val doc = Fetch.document("$baseUrl/search?q=${Fetch.encode(opts.query)}")
        // val items = doc.select(".search-result")
        // return items.map { item ->
        //     SearchResult(
        //         id = item.attr("href"),
        //         title = item.select(".title").text(),
        //         url = item.attr("href"),
        //         subOrDub = "sub"
        //     )
        // }
        val ID = opts.media.tmdbId
        val TYPE = opts.media.format
        // TODO: add season count to MEDIA MODEL
        // val season = opts.media.seasonCount
        val SEASON = if (TYPE == "TV") 1 else null
        val EPISODE = if (TYPE == "TV") opts.media.episodeCount else null

        val RESULT = "${baseUrl}/embed/${TYPE}/${ID}/${SEASON}/${EPISODE}"
        
        return listOf(
            SearchResult(
                id = RESULT,
                title = opts.query,
                url = RESULT,
                subOrDub = "dub"
            )
        )
    }
    
    override fun getEpisodes(id: String): List<EpisodeDetails> {
        // Parse the embed URL to get episode count
        // Format: https://www.vidking.net/embed/TV/119051/1/8
        val parts = id.split("/")
        val epCount = parts.lastOrNull()?.toIntOrNull() ?: 1
        
        // Create base URL without episode number
        val baseEmbedUrl = parts.dropLast(1).joinToString("/")
        
        // Generate episode list
        return (1..epCount).map { episodeNum ->
            EpisodeDetails(
                id = "$baseEmbedUrl/$episodeNum",
                number = episodeNum,
                url = "$baseEmbedUrl/$episodeNum",
                title = "Episode $episodeNum"
            )
        }
    }
    
    override fun getEpisodeServer(episode: EpisodeDetails, server: String): EpisodeServer {
        // Extract video URL using headless browser
        println("Extracting video URL for: ${episode.url}")
        val videoUrl = videoExtractor.extractVideoUrl(episode.url)
        
        if (videoUrl == null) {
            println("⚠ Failed to extract video URL, returning empty sources")
            return EpisodeServer(
                server = server,
                headers = mapOf("Referer" to baseUrl),
                videoSources = emptyList()
            )
        }
        
        return EpisodeServer(
            server = server,
            headers = mapOf(
                "Referer" to baseUrl,
                "Origin" to baseUrl,
                "User-Agent" to "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
            ),
            videoSources = listOf(
                VideoSource(
                    url = videoUrl,
                    type = VideoSourceType.M3U8,
                    quality = "auto"
                )
            )
        )
    }
    

    
    override fun getProviderSettings(): Settings {
        return Settings(
            episodeServers = listOf("server1", "server2"),
            supportsDub = true
        )
    }
}
