import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'EditprofilePage.dart';
import 'map.dart';
import 'weather_main.dart';
import 'parametres.dart';
import 'main.dart';
import 'login.dart';
import 'signin.dart';
import 'package:url_launcher/url_launcher.dart';
import 'favoris.dart';
import 'chatbot.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? profileImageUrl;
  String? bannerImageUrl;
  int _selectedIndex = 3;
  String? firstName;
  String? lastName;
  String? description;
  bool isLoading = true;
  bool isAnonymous = false;
  bool isPrestataire = false;
  List<String> userInterests = [];
  List<String> weatherPreferences = [];
  String userAddress = "Adresse non renseignée";

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      setState(() {
        isLoading = false;
        isAnonymous = true;
        firstName = "Anonyme";
        lastName = "";
        description = "Aucune description disponible";
        userInterests = [];
      });
      return;
    }

    if (user.isAnonymous == true) {
      setState(() {
        isAnonymous = true;
        firstName = "Anonyme";
        lastName = "";
        description = "Aucune description disponible";
        userInterests = [];
        isLoading = false;
      });
      return;
    }

    try {
      final userId = user.id;

      final responsePersonne =
          await Supabase.instance.client
              .from('personne')
              .select('nom, prenom,adresse,role')
              .eq('user_id', userId)
              .maybeSingle();

      if (responsePersonne == null) {
        setState(() {
          isLoading = false;
          firstName = "Utilisateur";
          lastName = "";
          description = "Profil non trouvé";
        });
        return;
      }

      final responseProfile =
          await Supabase.instance.client
              .from('profiles')
              .select(
                'description, profile_photo, banner_photo, centre_interet, preferences_meteo',
              )
              .eq('user_id', userId)
              .maybeSingle();

      setState(() {
        userAddress = responsePersonne['adresse'] ?? "Adresse non renseignée";
        firstName = responsePersonne['prenom'];
        lastName = responsePersonne['nom'];
        description =
            responseProfile?['description'] ?? "Pas de description disponible";
        profileImageUrl = responseProfile?['profile_photo'];
        bannerImageUrl = responseProfile?['banner_photo'];
        isPrestataire = responsePersonne['role'] == 'Prestataire';

        if (responseProfile?['centre_interet'] != null) {
          userInterests = List<String>.from(responseProfile!['centre_interet']);
        } else {
          userInterests = [];
        }

        if (responseProfile?['preferences_meteo'] != null) {
          weatherPreferences = List<String>.from(
            responseProfile!['preferences_meteo'],
          );
        }

        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        profileImageUrl = null;
        bannerImageUrl = null;
        userInterests = [];
      });
      print("Erreur lors de la récupération du profil : $e");
    }
  }

  void _navigateToEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditProfilePage()),
    ).then((_) => _fetchUserProfile());
  }

  Drawer _buildSideMenu() {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      elevation: 20,
      backgroundColor: Colors.white.withOpacity(0.97),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 180,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade700, Colors.lightBlue.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(30),
                ),
              ),
              padding: EdgeInsets.only(
                top: 40,
                left: 20,
                right: 20,
                bottom: 20,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    child: CircleAvatar(
                      radius: 36,
                      backgroundImage:
                          profileImageUrl != null
                              ? NetworkImage(profileImageUrl!)
                              : AssetImage('assets/images/profile.jpg')
                                  as ImageProvider,
                    ),
                  ),
                  SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$firstName $lastName',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Text(
                          isPrestataire ? 'Prestataire' : 'Explorateur',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // --- Section Principale ---
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              child: Column(
                children: [
                  // --- Item Service Client ---
                  _buildMenuItem(
                    icon: Icons.help_center_outlined,
                    iconColor: Colors.blue.shade600,
                    iconBg: Colors.blue.shade50,
                    title: "Service Client",
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatBotScreen(),
                          ),
                        ),
                    badge: null,
                  ),

                  // --- Devenir Prestataire ---
                  if (!isAnonymous && !isPrestataire)
                    _buildMenuItem(
                      icon: Icons.verified_user_outlined,
                      iconColor: Colors.purple.shade600,
                      iconBg: Colors.purple.shade50,
                      title: "Devenir Prestataire",
                      onTap: () {
                        final url = Uri.parse(
                          'https://docs.google.com/forms/d/e/1FAIpQLScWylpUlA71rmHhQzWWj3TGVdjOZtmAqaqvJxXmAa4ES-xaEA/viewform?usp=dialog',
                        );
                        launchUrl(url, mode: LaunchMode.externalApplication);
                      },
                    ),

                  // --- Séparateur ---
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(
                      color: Colors.grey.shade300,
                      height: 1,
                      thickness: 1,
                      indent: 20,
                      endIndent: 20,
                    ),
                  ),

                  // --- Paramètres ---
                  _buildMenuItem(
                    icon: Icons.settings_outlined,
                    iconColor: Colors.orange.shade600,
                    iconBg: Colors.orange.shade50,
                    title: "Paramètres",
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ParametresPage(),
                          ),
                        ),
                  ),

                  // --- Mode Sombre (Exemple) ---
                  _buildMenuItem(
                    icon: Icons.dark_mode_outlined,
                    iconColor: Colors.grey.shade700,
                    iconBg: Colors.grey.shade100,
                    title: "Mode Sombre",
                    onTap: () {
                      // Implémentez le dark mode ici
                    },
                    trailing: Switch(
                      value: false,
                      onChanged: (val) {},
                      activeColor: Colors.blue,
                    ),
                  ),

                  // --- Séparateur ---
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(
                      color: Colors.grey.shade300,
                      height: 1,
                      thickness: 1,
                      indent: 20,
                      endIndent: 20,
                    ),
                  ),

                  // --- Déconnexion/Connexion ---
                  if (!isAnonymous)
                    _buildMenuItem(
                      icon: Icons.logout,
                      iconColor: Colors.red.shade600,
                      iconBg: Colors.red.shade50,
                      title: "Déconnexion",
                      onTap: () async {
                        await Supabase.instance.client.auth.signOut();
                        Navigator.pop(context);
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SplashScreen(),
                          ),
                          (route) => false,
                        );
                      },
                    ),

                  if (isAnonymous)
                    Column(
                      children: [
                        _buildMenuItem(
                          icon: Icons.login,
                          iconColor: Colors.green.shade600,
                          iconBg: Colors.green.shade50,
                          title: "Connexion",
                          onTap:
                              () => Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LoginScreen(),
                                ),
                              ),
                        ),
                        _buildMenuItem(
                          icon: Icons.person_add_alt_1,
                          iconColor: Colors.teal.shade600,
                          iconBg: Colors.teal.shade50,
                          title: "Inscription",
                          onTap:
                              () => Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SigninScreen(),
                                ),
                              ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required VoidCallback onTap,
    Widget? trailing,
    Widget? badge,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Colors.grey.shade800,
        ),
      ),
      trailing:
          trailing ??
          (badge != null
              ? badge
              : Icon(Icons.chevron_right, color: Colors.grey.shade400)),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
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
        // Already on profile page
        break;
      default:
        break;
    }
  }

  Widget _buildBottomNavBar() {
    return Positioned(
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
              color:
                  isSelected
                      ? Colors.blue.withOpacity(0.2)
                      : Colors.transparent,
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

  Widget _buildInterestsSection() {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 2),
        ],
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.interests, color: Colors.green, size: 20),
              SizedBox(width: 10),
              Text(
                'CENTRES D\'INTÉRÊT',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          SizedBox(height: 15),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                userInterests.map((interest) {
                  return Chip(
                    avatar: CircleAvatar(
                      backgroundColor: Colors.green.shade100,
                      child: Icon(
                        _getInterestIcon(interest),
                        size: 16,
                        color: Colors.green.shade700,
                      ),
                    ),
                    label: Text(interest),
                    backgroundColor: Colors.green.shade50,
                    labelStyle: TextStyle(color: Colors.green.shade700),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  IconData _getInterestIcon(String interest) {
    switch (interest.toLowerCase()) {
      case 'parcs':
        return Icons.park;
      case 'randonnée':
        return Icons.hiking;
      case 'plages':
        return Icons.beach_access;
      case 'monuments':
        return Icons.account_balance;
      case 'culture':
        return Icons.museum;
      case 'gastronomie':
        return Icons.restaurant;
      case 'sport':
        return Icons.sports;
      case 'nature':
        return Icons.nature;
      default:
        return Icons.interests;
    }
  }

  Widget _buildAddressSection() {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 2),
        ],
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_pin,
                color: Colors.pink,
                size: 22,
              ), // Icône jolie
              SizedBox(width: 10),
              Text(
                'ADRESSE',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.pink,
                ),
              ),
            ],
          ),
          SizedBox(height: 15),
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.pink.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.home_rounded, // Icône moderne
                  color: Colors.pink,
                  size: 28,
                ),
              ),
              SizedBox(width: 15),
              Expanded(
                child: Text(
                  userAddress,
                  style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherPreferencesSection() {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[100]!, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 2),
        ],
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.wb_sunny, color: Colors.orange, size: 20),
              SizedBox(width: 10),
              Text(
                'PRÉFÉRENCES MÉTÉO',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          SizedBox(height: 15),
          Wrap(
            spacing: 20,
            runSpacing: 15,
            children:
                weatherPreferences.map((weather) {
                  return _buildWeatherPreference(
                    weather,
                    _getWeatherIcon(weather),
                    _getWeatherColor(weather),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherPreference(String label, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 30),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: color.withAlpha(200),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  IconData _getWeatherIcon(String weather) {
    switch (weather.toLowerCase()) {
      case 'ensoleillé':
        return Icons.wb_sunny;
      case 'nuageux':
        return Icons.cloud;
      case 'pluvieux':
        return Icons.water_drop;
      case 'chaud':
        return Icons.thermostat;
      case 'froid':
        return Icons.ac_unit;
      case 'venteux':
        return Icons.air;
      default:
        return Icons.wb_sunny;
    }
  }

  Color _getWeatherColor(String weather) {
    switch (weather.toLowerCase()) {
      case 'ensoleillé':
        return Colors.orange;
      case 'nuageux':
        return Colors.blueGrey;
      case 'pluvieux':
        return Colors.blue;
      case 'chaud':
        return Colors.red;
      case 'froid':
        return Colors.lightBlue;
      case 'venteux':
        return Colors.cyan;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildSideMenu(),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                automaticallyImplyLeading:
                    false, // Supprime le bouton menu noir
                expandedHeight: 200.0,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image:
                                bannerImageUrl != null
                                    ? NetworkImage(bannerImageUrl!)
                                    : AssetImage('assets/images/banniere.jpg')
                                        as ImageProvider,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withOpacity(0.5),
                              Colors.transparent,
                              Colors.black.withOpacity(0.3),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                pinned: true,
                actions: [Container()],
              ),
              SliverList(
                delegate: SliverChildListDelegate([
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 100),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    spreadRadius: 3,
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 60,
                                backgroundColor: Colors.white,
                                child: CircleAvatar(
                                  radius: 56,
                                  backgroundImage:
                                      profileImageUrl != null
                                          ? NetworkImage(profileImageUrl!)
                                          : AssetImage(
                                                'assets/images/profile.jpg',
                                              )
                                              as ImageProvider,
                                ),
                              ),
                            ),
                            SizedBox(width: 20),
                            Expanded(
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: Text(
                                      isLoading
                                          ? 'Chargement...'
                                          : (firstName != null &&
                                                  lastName != null
                                              ? '$firstName $lastName'
                                              : 'Profil invité'),
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blueGrey[900],
                                      ),
                                    ),
                                  ),
                                  if (!isAnonymous)
                                    IconButton(
                                      icon: Icon(
                                        Icons.edit_note_rounded,
                                        size: 35,
                                        color: Colors.blueGrey[700],
                                      ),
                                      onPressed: _navigateToEditProfile,
                                      tooltip: 'Modifier le profil',
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Colors.blue,
                                    size: 20,
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    'À PROPOS',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 10),
                              Text(
                                description != null && description!.isNotEmpty
                                    ? description!
                                    : 'Pas de description disponible',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[700],
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 20),
                        if (!isAnonymous) ...[
                          _buildInterestsSection(),
                          SizedBox(height: 20),
                          _buildAddressSection(),
                          SizedBox(height: 20),
                          _buildWeatherPreferencesSection(),
                        ],
                        if (isAnonymous)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20.0),
                            child: Center(
                              child: Text(
                                'Veuillez vous connecter ou créer un compte afin de pouvoir personnaliser votre profil',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.black.withOpacity(0.6),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        SizedBox(height: 100),
                      ],
                    ),
                  ),
                ]),
              ),
            ],
          ),

          Positioned(
            top: 40,
            left: 20,
            child: Builder(
              builder:
                  (context) => IconButton(
                    icon: Icon(Icons.menu, color: Colors.white, size: 40),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
            ),
          ),

          _buildBottomNavBar(),
        ],
      ),
    );
  }
}
