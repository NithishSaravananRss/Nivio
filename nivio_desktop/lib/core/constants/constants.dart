import '../config/app_environment.dart';

// API Constants
String get tmdbApiKey => AppEnvironment.tmdbApiKey;
String get tmdbBaseUrl => AppEnvironment.imageProxyUrl;

// TMDB Image Base URLs
String get tmdbImageBaseUrl => '${AppEnvironment.imageProxyUrl}/t/p';
const String posterSize = 'w500';
const String backdropSize = 'original';

// Video Quality Priority
const List<String> qualityPriority = [
  '2160p',
  '1440p',
  '1080p',
  '720p',
  '480p',
  '360p',
  'auto',
];
