// lib/weather_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherData {
  final String city;
  final double temperature;
  final String condition;

  WeatherData({
    required this.city,
    required this.temperature,
    required this.condition,
  });
}

class WeatherService {
  final String apiKey = "TA_CLE_API"; // Remplace par ta clé API

  Future<WeatherData> fetchWeather(String cityName) async {
    final url = Uri.parse(
        'https://api.weatherapi.com/v1/current.json?key=$apiKey&q=$cityName&lang=fr');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return WeatherData(
        city: data['location']['name'],
        temperature: data['current']['temp_c'],
        condition: data['current']['condition']['text'],
      );
    } else {
      throw Exception('Erreur lors de la récupération des données météo');
    }
  }
}
