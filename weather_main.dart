import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'map.dart';
import 'profile.dart';
import 'beachScreen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  double temperature = 0.0;
  String weatherDescription = "";
  double windSpeed = 0.0;
  double windDirection = 0.0;
  String lastUpdated = "";
  bool isLoading = true;

  final List<Map<String, String>> activities = [
    {"title": "Restaurant", "image": "assets/images/restaurant.jpg"},
    {"title": "Hôtel", "image": "assets/images/hotel.jpg"},
    {"title": "Sortie", "image": "assets/images/sortie.jpg"},
    {"title": "Plage", "image": "assets/images/plage.jpg"},
    {"title": "Autres", "image": "assets/images/autres.jpg"},
  ];

  @override
  void initState() {
    super.initState();
    fetchWeather();
  }

  Future<void> fetchWeather() async {
    try {
      final response = await http.get(Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=47.31&longitude=5.01&current_weather=true',
      ));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          temperature = (data['current_weather']['temperature'] as num).toDouble();
          weatherDescription = data['current_weather']['weathercode'].toString();
          windSpeed = (data['current_weather']['windspeed'] as num).toDouble();
          windDirection = (data['current_weather']['winddirection'] as num).toDouble();
          lastUpdated = data['current_weather']['time'];
          isLoading = false;
        });
      } else {
        throw Exception('Erreur de chargement');
      }
    } catch (e) {
      print("Erreur météo : $e");
      setState(() {
        isLoading = false;
        weatherDescription = "Erreur météo";
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MapScreen()),
        );
        break;
      case 2:
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ProfilePage()),
        );
        break;
      default:
        break;
    }
  }

  String getWeatherLabel(String code) {
    final int hour = DateTime.now().hour;
    bool isNight = hour >= 20 || hour < 6;
    if (isNight) {
      return "Nuit";
    }
    switch (code) {
      case "0":
        return "Soleil";
      case "1":
      case "2":
        return "Partiellement nuageux";
      case "3":
        return "Nuageux";
      case "45":
      case "48":
        return "Brouillard";
      case "51":
      case "53":
      case "55":
        return "Bruine";
      case "61":
      case "63":
      case "65":
        return "Pluie";
      default:
        return "Inconnu";
    }
  }

  IconData _getWeatherIcon(String code) {
    final int hour = DateTime.now().hour;
    bool isNight = hour >= 20 || hour < 6;
    if (isNight) {
      return Icons.nights_stay;
    }
    switch (code) {
      case "0":
        return Icons.wb_sunny;
      case "1":
      case "2":
        return Icons.wb_cloudy;
      case "3":
        return Icons.cloud;
      case "45":
      case "48":
        return Icons.cloud_queue;
      case "51":
      case "53":
      case "55":
        return Icons.grain;
      case "61":
      case "63":
      case "65":
        return Icons.umbrella;
      default:
        return Icons.error_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, String>> mainActivities = [];
    List<Map<String, String>> lastActivity = [];
    final int hour = DateTime.now().hour;
    final int minute = DateTime.now().minute;

    for (int i = 0; i < activities.length; i++) {
      if (i == activities.length - 1) {
        lastActivity.add(activities[i]);
      } else {
        mainActivities.add(activities[i]);
      }
    }

    return Scaffold(
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                alignment: Alignment.topLeft,
                children: [
                  Image.asset(
                    "assets/images/background.jpg",
                    height: 250,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    top: 75,
                    right: 16,
                    child: IconButton(
                      icon: Icon(Icons.refresh, color: Colors.white, size: 30),
                      onPressed: fetchWeather,
                    ),
                  ),
                  Positioned(
                    top: 50,
                    left: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 30),
                        Text(
                          "Météo à Béjaïa",
                          style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        isLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                    _getWeatherIcon(weatherDescription),
                                    color: Colors.yellow[700],
                                    size: 30
                                ),
                                SizedBox(width: 8),
                                Text(
                                  "${temperature.toStringAsFixed(1)}°C - ${getWeatherLabel(weatherDescription)}",
                                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Vent : ${windSpeed.toStringAsFixed(1)} km/h (${windDirection.toStringAsFixed(0)}°)",
                              style: TextStyle(color: Colors.white, fontSize: 16),
                            ),
                            Text(
                              "Mis à jour : $hour : $minute",
                              style: TextStyle(color: Colors.white70, fontSize: 16),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Activités", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    GestureDetector(
                      onTap: () {
                        print("Voir tout cliqué");
                      },
                      child: Text(
                        "Voir Tout",
                        style: TextStyle(fontSize: 18, color: Colors.blue, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(bottom: 100), // Espace pour la navigation
                  child: Column(
                    children: [
                      GridView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 15,
                          childAspectRatio: 1.1,
                        ),
                        itemCount: mainActivities.length,
                        itemBuilder: (context, index) {
                          return activityCard(mainActivities[index]);
                        },
                      ),

                      if (lastActivity.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: activityCard(lastActivity.first, isFullWidth: true),
                        ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            right: 25,
            bottom: 100,
            child: FloatingActionButton(
              onPressed: () {},
              backgroundColor: Colors.white,
              child: Icon(Icons.assistant, color: Colors.blue, size: 28),
              elevation: 4,
            ),
          ),

          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(0, Icons.home, "Accueil"),
                  _buildNavItem(1, Icons.map, "Carte"),
                  _buildNavItem(2, Icons.favorite, "Favoris"),
                  _buildNavItem(3, Icons.person, "Profil"),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.transparent,
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.blue : Colors.grey,
              size: 22,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isSelected ? Colors.blue : Colors.grey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget activityCard(Map<String, String> activity, {bool isFullWidth = false}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => BeachScreen()),
        );;
      },
      child: Container(
        width: isFullWidth ? double.infinity : null,
        height: isFullWidth ? 150 : null,
        margin: EdgeInsets.only(bottom: 10),
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                activity['image']!,
                width: double.infinity,
                height: isFullWidth ? 150 : double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                activity['title']!,
                textAlign: TextAlign.left,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isFullWidth ? 18 : 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}