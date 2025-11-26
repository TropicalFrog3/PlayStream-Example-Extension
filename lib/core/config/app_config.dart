class AppConfig {
  static const String traktClientId = '50c188038028be73436f3e4e5d113a21a08ac997f85f704f502b7e479d5bd4cf';
  static const String traktClientSecret = '4cb8261fd71d877b0b07ee154cd28adf1298dca9c373366764413d7fadb788c3';
  static const String traktRedirectUri = 'urn:ietf:wg:oauth:2.0:oob';
  
  static const String auth0Domain = 'dev-fdnv5dxycvsoopwa.eu.auth0.com';
  static const String auth0ClientId = 'Ar4MYmMaBUcreB591dmDhXo24YtmgDZD';
  
  static const String appName = 'PlayStream';
  static const String appVersion = '1.0.0';
  
  static Future<void> initialize() async {
    // Initialize any required services
  }
}
