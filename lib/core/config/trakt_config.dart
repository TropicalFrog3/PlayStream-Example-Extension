class TraktConfig {
  static const String host = 'api.trakt.tv';
  static const String baseUrl = 'https://api.trakt.tv';
  static const String websiteBaseUrl = 'https://trakt.tv';
  
  static const String version = '2';
  static const String oauth2AuthorizationUrl = 'https://trakt.tv/oauth/authorize';
  
  static const int pageLimit = 10;
  static const int pageLimitRecommendation = 20;
  static const int pageInitial = 0;
  static const int pageMaxLimit = 20;
}

class TraktHeader {
  static const String apiKey = 'trakt-api-key';
  static const String apiVersion = 'trakt-api-version';
  static const String contentType = 'Content-Type';
  static const String paginationPage = 'X-Pagination-Page';
  static const String paginationPageCount = 'X-Pagination-Page-Count';
  static const String paginationItemCount = 'X-Pagination-Item-Count';
}

enum TraktExtended {
  full('full'),
  noSeasons('noseasons'),
  episodes('episodes'),
  fullEpisodes('full,episodes'),
  images('images'),
  fullImages('full,images');
  
  final String value;
  const TraktExtended(this.value);
}
