import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'offre_restaurant.dart';
import 'dart:convert';
import 'map.dart';
import 'profile.dart';
import 'offre_page.dart';
import 'offre_hotel.dart';
import 'offre_loisirs.dart';
import 'favoris.dart';
import 'chatbot.dart';
import 'admin/panneau-admin.dart';
import 'prestataire/panneau-prestataire.dart';
import 'offre_plage.dart';
import 'GlovalColors.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Poppins',
        colorScheme: ColorScheme.light(
          primary: Color(0xFF4361EE),
          secondary: Color(0xFF3F37C9),
          surface: Color(0xFFF8F9FA),
          background: Color(0xFFF8F9FA),
        ),
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Color primaryColor = Color(0xFF4361EE);
  final Color secondaryColor = Color(0xFF3F37C9);
  final Color accentColor = Color(0xFF7209B7);
  final Color backgroundColor = Color(0xFFF8F9FA);
  final Color bleuTurquoise = Color(0xFF41A6B4);
  final Color cardColor = Colors.white;
  String userRole = "Voyageur";
  int _selectedIndex = 0;
  double temperature = 0.0;
  String weatherDescription = "";
  double windSpeed = 0.0;
  double windDirection = 0.0;
  String lastUpdated = "";
  bool isLoading = true;
  bool isAdmin = false;
  bool isPrestataire = false;

  final List<Map<String, dynamic>> activities = [
    {
      "title": "Restaurant",
      "image": "assets/images/restaurant.jpg",
      "icon": Icons.restaurant,
      "color": Color(0xFF4CC9F0)
    },
    {
      "title": "Hôtel",
      "image": "assets/images/hotel.jpg",
      "icon": Icons.hotel,
      "color": Color(0xFF4895EF)
    },
    {
      "title": "Sortie",
      "image": "assets/images/sortie.jpg",
      "icon": Icons.local_activity,
      "color": Color(0xFF560BAD)
    },
    {
      "title": "Plage",
      "image": "assets/images/plage.jpg",
      "icon": Icons.beach_access,
      "color": Color(0xFFB5179E)
    },
  ];

  final List<Map<String, dynamic>> allactivities = [
    {
      "title": "Toutes les offres",
      "image": "assets/images/autres.jpg",
      "icon": Icons.explore,
      "color": Color(0xFF41A6B4),
    },
  ];

  @override
  void initState() {
    super.initState();
    fetchWeather();
    getUserRole();
  }

  Future<void> fetchWeather() async {
    try {
      final response = await http.get(Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=36.7509&longitude=5.0567&current_weather=true',
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
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => FavorisPage()),
        );
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

  Future<void> getUserRole() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      print("Aucun utilisateur connecté");
      return;
    }

    try {
      final response = await supabase
          .from('personne')
          .select('role')
          .eq('user_id', user.id)
          .single();

      if (response != null && response['role'] != null) {
        setState(() {
          userRole = response['role'] as String;
          if (userRole == "Administrateur") {
            isAdmin = true;
          } else if (userRole == "Prestataire") {
            isPrestataire = true;
          } else {
            isAdmin = false;
            isPrestataire = false;
          }
        });
      } else {
        print("Rôle non trouvé pour cet utilisateur.");
      }
    } catch (e) {
      print("Erreur lors de la récupération du rôle : $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final int hour = DateTime.now().hour;
    final int minute = DateTime.now().minute;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: GlobalColors.primaryColor,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // En-tête avec météo
              SliverAppBar(
                expandedHeight: 300,
                floating: false,
                pinned: true,
                automaticallyImplyLeading: false,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        "assets/images/background.jpg",
                        fit: BoxFit.cover,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.6),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 50,
                        left: 20,
                        right: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Explorez Béjaïa",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Découvrez les meilleures activités",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 20),
                            // Widget météo
                            Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                ),
                              ),
                              child: isLoading
                                  ? Center(child: CircularProgressIndicator(color: Colors.white))
                                  : Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Météo actuelle",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(
                                            _getWeatherIcon(weatherDescription),
                                            color: Colors.amber,
                                            size: 32,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            "${temperature.toStringAsFixed(1)}°C",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 28,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        getWeatherLabel(weatherDescription),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.air, color: Colors.white, size: 16),
                                          SizedBox(width: 4),
                                          Text(
                                            "${windSpeed.toStringAsFixed(1)} km/h",
                                            style: TextStyle(color: Colors.white),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        "Mis à jour: $hour:$minute",
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.8),
                                          fontSize: 12,
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.refresh, color: Colors.white),
                                        onPressed: fetchWeather,
                                        iconSize: 20,
                                        padding: EdgeInsets.zero,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 15),

                    // Boutons admin/prestataire
                    if (isAdmin || isPrestataire)
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          alignment: AlignmentDirectional.center,
                          child: Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              if (isAdmin)
                                ElevatedButton.icon(
                                  icon: Icon(Icons.admin_panel_settings, color: Colors.white),
                                  label: Text(
                                    "Panneau Admin",
                                    style: TextStyle(fontSize: 16, color: Colors.white),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: GlobalColors.bleuTurquoise,
                                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => AdminPanelPage()));
                                  },
                                ),
                              if (isPrestataire)
                                ElevatedButton.icon(
                                  icon: Icon(Icons.business, color: Colors.white),
                                  label: Text(
                                    "Espace Prestataire",
                                    style: TextStyle(fontSize: 16, color: Colors.white),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: GlobalColors.bleuTurquoise,
                                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => PanneauPrestatairePage()));
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),

                    // Section activités
                    Padding(
                      padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
                      child: Text(
                        "Catégories d'activités",
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                            color: GlobalColors.secondaryColor,
                        ),
                      ),
                    ),

                    // Grille d'activités
                    GridView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 15,
                        mainAxisSpacing: 15,
                        childAspectRatio: 0.9,
                      ),
                      itemCount: activities.length,
                      itemBuilder: (context, index) {
                        return _buildActivityCard(activities[index]);
                      },
                    ),

                    SizedBox(height: 15),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 1,
                        crossAxisSpacing: 15,
                        mainAxisSpacing: 15,
                        childAspectRatio: 6,
                      ),
                      itemCount: allactivities.length,
                      itemBuilder: (context, index) {
                          return _buildAllOffersCard(allactivities[index]);
                      },
                    ),
                    SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ),
          _buildBottomNavBar(),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ChatBotScreen()),
            );
          },
          backgroundColor: bleuTurquoise,
          child: Icon(Icons.assistant, color: Colors.white),
          elevation: 15,
        ),
      ),
    );
  }

  Widget _buildAllOffersCard(Map<String, dynamic> activity) {
    bool isDarkMode = GlobalColors.isDarkMode;
    Color selectedColor = GlobalColors.isDarkMode ? bleuTurquoise : bleuTurquoise;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => OffresPage()),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: GlobalColors.secondaryColor.withOpacity(0.1),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            height: 100,
            color: isDarkMode ? GlobalColors.darkCard : Colors.white,
            child: Stack(
              alignment: AlignmentDirectional.center,
              children: [
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        activity['icon'],
                        color: selectedColor,
                        size: 24,
                      ),
                      SizedBox(width: 8),
                      Text(
                        activity['title'],
                        style: TextStyle(
                          color: GlobalColors.secondaryColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow:
          GlobalColors.isDarkMode
              ? []
              : [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: Container(
              height: 65,
              padding: EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color:
                GlobalColors.isDarkMode
                    ? GlobalColors.accentColor.withOpacity(0.2)
                    : GlobalColors.primaryColor.withOpacity(0.9),
                border:
                GlobalColors.isDarkMode
                    ? Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                )
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(Icons.home_rounded, 'Accueil', 0),
                  _buildNavItem(Icons.map_rounded, 'Carte', 1),
                  _buildNavItem(Icons.favorite_rounded, 'Favoris', 2),
                  _buildNavItem(Icons.person_rounded, 'Profil', 3),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    bool isSelected = _selectedIndex == index;
    Color selectedColor =
    GlobalColors.isDarkMode ? bleuTurquoise : bleuTurquoise;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color:
          isSelected
              ? (GlobalColors.isDarkMode
              ? bleuTurquoise.withOpacity(0.2)
              : bleuTurquoise.withOpacity(0.1))
              : Colors.transparent,
        ),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color:
                isSelected
                    ? selectedColor
                    : (GlobalColors.isDarkMode
                    ? Colors.grey.shade400
                    : Colors.grey),
                size: isSelected ? 26 : 24,
              ),
              if (isSelected) ...[
                SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: selectedColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> activity) {
    return GestureDetector(
      onTap: () {
        switch (activity['title']) {
          case 'Restaurant':
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => OffreRestaurantPage()));
            break;
          case 'Hôtel':
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => OffreHotelPage()));
            break;
          case 'Sortie':
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => OffreLoisirsPage()));
            break;
          case 'Plage':
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => OffrePlagePage()));
            break;
          default:
            print('Aucune page définie pour cette activité.');
            break;
        }
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Image de fond
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      (activity['color'] as Color).withOpacity(0.8),
                      (activity['color'] as Color).withOpacity(0.4),
                    ],
                  ),
                ),
                child: Image.asset(
                  activity['image'],
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),

              // Overlay sombre
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.5),
                    ],
                  ),
                ),
              ),

              // Contenu
              Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        activity['icon'],
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      activity['title'],
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Découvrir →",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}