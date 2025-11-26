/// Model representing a streaming server provided by an extension
class StreamServer {
  final String id;
  final String name;
  final String quality; // '1080p', '720p', '480p', etc.
  final String type; // 'mp4', 'm3u8', 'dash', etc.
  final String url;
  final Map<String, String>? headers;

  StreamServer({
    required this.id,
    required this.name,
    required this.quality,
    required this.type,
    required this.url,
    this.headers,
  });

  factory StreamServer.fromJson(Map<String, dynamic> json) {
    return StreamServer(
      id: json['id'] as String,
      name: json['name'] as String,
      quality: json['quality'] as String,
      type: json['type'] as String,
      url: json['url'] as String,
      headers: json['headers'] != null
          ? Map<String, String>.from(json['headers'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'quality': quality,
      'type': type,
      'url': url,
      'headers': headers,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StreamServer && other.id == id && other.url == url;
  }

  @override
  int get hashCode => Object.hash(id, url);
}
