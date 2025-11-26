package com.playstream.extension

import com.google.gson.Gson
import com.playstream.extension.models.*
import com.frog.playstream.extensions.IExtensionProvider

abstract class MediaProvider : IExtensionProvider {
    
    protected val gson = Gson()
    
    abstract override val extensionId: String
    abstract override val name: String
    abstract override val version: String

    abstract fun searchMedia(opts: SearchOptions): List<SearchResult>
    abstract fun getEpisodes(id: String): List<EpisodeDetails>
    abstract fun getEpisodeServer(episode: EpisodeDetails, server: String): EpisodeServer
    abstract fun getProviderSettings(): Settings
    
    override fun search(query: String, imdbId: String?, tmdbId: String?, mediaType: String?): String {
        val media = Media(
            id = 0,
            imdbId = imdbId,
            tmdbId = tmdbId,
            format = mediaType?.uppercase(),
            englishTitle = query,
            synonyms = emptyList(),
            isAdult = false
        )
        
        val searchOptions = SearchOptions(
            media = media,
            query = query,
            dub = true
        )
        
        val results = searchMedia(searchOptions)
        return gson.toJson(results)
    }
    
    override fun findEpisodes(showId: String): String {
        val episodes = getEpisodes(showId)
        return gson.toJson(episodes)
    }
    
    override fun findEpisodeServer(episodeId: String): String {
        val episode = EpisodeDetails(
            id = episodeId,
            number = 1,
            url = ""
        )
        
        val settings = getProviderSettings()
        val server = settings.episodeServers.firstOrNull() ?: ""
        
        val episodeServer = getEpisodeServer(episode, server)
        return gson.toJson(episodeServer)
    }
    
    override fun getSettings(): String {
        val settings = getProviderSettings()
        return gson.toJson(settings)
    }
}
