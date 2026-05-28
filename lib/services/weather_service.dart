import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather.dart';

class WeatherService {
  // Provide API key via --dart-define=OPENWEATHER_API_KEY=your_key
  final String apiKey;

  WeatherService({String? apiKey})
    : apiKey = apiKey ?? const String.fromEnvironment('OPENWEATHER_API_KEY');

  Future<Weather?> fetchCurrent(double lat, double lon) async {
    if (apiKey.isEmpty) return null;
    final url = Uri.parse(
      'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&units=metric&appid=$apiKey',
    );
    final res = await http.get(url).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) return null;
    final body = json.decode(res.body) as Map<String, dynamic>;
    return Weather.fromJson(body);
  }
}
