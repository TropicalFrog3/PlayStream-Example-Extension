/// Request data structure for method channel communication with native code.
/// Used to invoke provider methods on native Android extensions.
class MethodChannelRequest {
  final String extensionId;
  final String method;
  final Map<String, dynamic> arguments;

  MethodChannelRequest({
    required this.extensionId,
    required this.method,
    required this.arguments,
  });

  /// Converts the request to a map for method channel transmission
  Map<String, dynamic> toMap() {
    return {
      'extensionId': extensionId,
      'method': method,
      'args': arguments,
    };
  }

  /// Creates a request from a map received from method channel
  factory MethodChannelRequest.fromMap(Map<String, dynamic> map) {
    return MethodChannelRequest(
      extensionId: map['extensionId'] as String,
      method: map['method'] as String,
      arguments: Map<String, dynamic>.from(map['args'] as Map? ?? {}),
    );
  }

  /// Creates a search request
  factory MethodChannelRequest.search(String extensionId, String query) {
    return MethodChannelRequest(
      extensionId: extensionId,
      method: 'search',
      arguments: {'query': query},
    );
  }

  /// Creates a findMovie request
  factory MethodChannelRequest.findMovie(String extensionId, String movieId) {
    return MethodChannelRequest(
      extensionId: extensionId,
      method: 'findMovie',
      arguments: {'movieId': movieId},
    );
  }

  /// Creates a findEpisode request
  factory MethodChannelRequest.findEpisode(
    String extensionId,
    String showId,
    int season,
    int episode,
  ) {
    return MethodChannelRequest(
      extensionId: extensionId,
      method: 'findEpisode',
      arguments: {
        'showId': showId,
        'season': season,
        'episode': episode,
      },
    );
  }

  /// Creates a findMovieServers request
  factory MethodChannelRequest.findMovieServers(String extensionId, String movieId) {
    return MethodChannelRequest(
      extensionId: extensionId,
      method: 'findMovieServers',
      arguments: {'movieId': movieId},
    );
  }

  /// Creates a findEpisodeServers request
  factory MethodChannelRequest.findEpisodeServers(
    String extensionId,
    String showId,
    int season,
    int episode,
  ) {
    return MethodChannelRequest(
      extensionId: extensionId,
      method: 'findEpisodeServers',
      arguments: {
        'showId': showId,
        'season': season,
        'episode': episode,
      },
    );
  }

  /// Creates a getSettings request
  factory MethodChannelRequest.getSettings(String extensionId) {
    return MethodChannelRequest(
      extensionId: extensionId,
      method: 'getSettings',
      arguments: {},
    );
  }
}
