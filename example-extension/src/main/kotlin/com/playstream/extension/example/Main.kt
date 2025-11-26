package com.playstream.extension.example

import com.playstream.extension.models.*
import com.playstream.extension.utils.Fetch

/**
 * Simple test runner for the Example Extension provider.
 */
fun main() {
    println("=== Example Extension Test ===\n")
    val provider = ExampleProvider()
    
    println("Extension ID: ${provider.extensionId}")
    println("Name: ${provider.name}")
    println("Version: ${provider.version}")
    println()
    
    // Test settings
    println("--- Settings ---")
    val settings = provider.getProviderSettings()
    println("Available servers: ${settings.episodeServers.joinToString(", ")}")
    println("Supports dub: ${settings.supportsDub}")
    println()
    
    // Test search
    println("--- Search Test ---")
    val searchOpts = SearchOptions(
        media = Media(
            id = 0, // manually put into the sandbox extension
            format = "TV", // auto fetch (use the ID to find)
            englishTitle = "Wednesday", // auto fetch ( \ \ )
            episodeCount = 8, // auto fetch ( \ \ )
            synonyms = emptyList(), // auto fetch ( \ \ )
            isAdult = false, // auto fetch ( \ \ )
            tmdbId = "119051" // auto fetch ( \ \ )
        ),
        query = "Wednesday", // auto fetch ( \ \ )
        dub = true // will be removed
    )
    
    println("Searching for: ${searchOpts.query}")
    val results = provider.searchMedia(searchOpts)
    
    if (results.isNotEmpty()) {
        println("Found ${results.size} result(s):")
        results.forEach { result ->
            println("  - ${result.title}")
            println("    ID: ${result.id}")
            println("    URL: ${result.url}")
            println("    Sub/Dub: ${result.subOrDub}")
        }
        
        // Test episodes
        println("\n--- Episodes Test ---")
        val firstResult = results.first()
        val episodes = provider.getEpisodes(firstResult.id)
        
        println("Found ${episodes.size} episode(s)")
        episodes.forEach { ep ->
            println("  - Episode ${ep.number}: ${ep.title ?: ep.id}")
        }
        
        // Test server
        if (episodes.isNotEmpty()) {
            println("\n--- Server Test ---")
            val firstEp = episodes.first()
            val server = provider.getEpisodeServer(firstEp, "server1")
            
            println("Server: ${server.server}")
            println("Headers: ${server.headers}")
            println("Video sources: ${server.videoSources.size}")
            server.videoSources.forEach { source ->
                println("  - ${source.quality}: ${source.url}")
            }
        }
    } else {
        println("No results found")
    }
    
    println("\n=== Test Complete ===")
}
