import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'map.dart';
import 'profile.dart';

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
  }

  String getWeatherLabel(String code) {
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

  @override
  Widget build(BuildContext context) {
    List<Map<String, String>> mainActivities = [];
    List<Map<String, String>> lastActivity = [];

    // Séparer les activités normales et "Autres"
    for (int i = 0; i < activities.length; i++) {
      if (i == activities.length - 1) {
        lastActivity.add(activities[i]); // "Autres" seul
      } else {
        mainActivities.add(activities[i]);
      }
    }

    return Scaffold(
      body: Column(
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
                            Icon(Icons.wb_sunny, color: Colors.yellow[700], size: 30),
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
                          "Mis à jour : $lastUpdated",
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
              child: Column(
                children: [
                  GridView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: 16),
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
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });

          switch (index) {
            case 0:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => HomePage()), // Page Accueil
              );
              break;
            case 1:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MapScreen()), // Page Carte
              );
              break;
            case 2:
            // Tu peux ajouter ici la logique pour "Favoris" si tu as une page associée
              break;
            case 3:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfilePage()), // Page Profil
              );
              break;
            default:
              break;
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Accueil",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: "Carte",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: "Favoris",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profil",
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.blue.withOpacity(0.9),
        child: Icon(Icons.android, color: Colors.white.withOpacity(0.9),),
      ),
    );
  }

  Widget activityCard(Map<String, String> activity, {bool isFullWidth = false}) {
    return GestureDetector(
      onTap: () {
        print("Clicked on ${activity['title']}");
      },
      child: Container(
        width: isFullWidth ? double.infinity : null,
        height: isFullWidth ? 150 : null,
        child: Stack(
          alignment: Alignment.bottomLeft,
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
              padding: EdgeInsets.all(8),
              color: Colors.black.withOpacity(0.5),
              child: Text(
                activity['title']!,
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
