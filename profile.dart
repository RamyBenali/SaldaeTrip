import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'EditprofilePage.dart';

import 'GlovalColors.dart';
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
  String role = "Invité";

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
        role = responsePersonne['role'];

        if(role == 'Prestataire'){
          isPrestataire = true;
        }

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
      width: MediaQuery.of(context).size.width * 0.75,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      elevation: 20,
      backgroundColor:
          GlobalColors.isDarkMode
              ? Colors.grey[900]!.withOpacity(0.97)
              : Colors.white.withOpacity(0.97),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: Colors.blue,
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
                    backgroundColor:
                        GlobalColors.isDarkMode
                            ? Colors.white.withOpacity(0.2)
                            : Colors.white.withOpacity(0.3),
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
                            color: GlobalColors.secondaryColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Text(
                          role == 'prestataire'
                              ? 'Prestataire'
                              : role == 'client'
                              ? 'Client'
                              : role == 'Administrateur'
                              ? 'Administrateur'
                              : 'Invité',
                          style: TextStyle(
                            color: GlobalColors.secondaryColor.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              child: Column(
                children: [
                  _buildMenuItem(
                    icon: Icons.help_center_outlined,
                    iconColor:
                        GlobalColors.isDarkMode
                            ? Colors.lightBlue[200]!
                            : Colors.blue.shade600,
                    iconBg:
                        GlobalColors.isDarkMode
                            ? Colors.blueGrey[800]!.withOpacity(0.3)
                            : Colors.blue.shade50,
                    title: "Service Client",
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatBotScreen(),
                          ),
                        ),
                  ),

                  if (!isAnonymous && !isPrestataire)
                    _buildMenuItem(
                      icon: Icons.verified_user_outlined,
                      iconColor:
                          GlobalColors.isDarkMode
                              ? Colors.purple[200]!
                              : Colors.purple.shade600,
                      iconBg:
                          GlobalColors.isDarkMode
                              ? Colors.purple[900]!.withOpacity(0.3)
                              : Colors.purple.shade50,
                      title: "Devenir Prestataire",
                      onTap: () {
                        final url = Uri.parse(
                          'https://docs.google.com/forms/d/e/1FAIpQLScWylpUlA71rmHhQzWWj3TGVdjOZtmAqaqvJxXmAa4ES-xaEA/viewform?usp=dialog',
                        );
                        launchUrl(url, mode: LaunchMode.externalApplication);
                      },
                    ),

                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(
                      color: GlobalColors.secondaryColor.withOpacity(0.2),
                      height: 1,
                      thickness: 1,
                      indent: 20,
                      endIndent: 20,
                    ),
                  ),

                  _buildMenuItem(
                    icon: Icons.settings_outlined,
                    iconColor:
                        GlobalColors.isDarkMode
                            ? Colors.orange[200]!
                            : Colors.orange.shade600,
                    iconBg:
                        GlobalColors.isDarkMode
                            ? Colors.orange[900]!.withOpacity(0.3)
                            : Colors.orange.shade50,
                    title: "Paramètres",
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ParametresPage(),
                          ),
                        ),
                  ),

                  _buildMenuItem(
                    icon: Icons.dark_mode_outlined,
                    iconColor:
                        GlobalColors.isDarkMode
                            ? Colors.amber[200]!
                            : Colors.grey.shade700,
                    iconBg:
                        GlobalColors.isDarkMode
                            ? Colors.amber[900]!.withOpacity(0.3)
                            : Colors.grey.shade200,
                    title: "Mode Sombre",
                    onTap: () {
                      setState(() {
                        GlobalColors.isDarkMode = !GlobalColors.isDarkMode;
                      });
                    },
                    trailing: Switch(
                      value: GlobalColors.isDarkMode,
                      onChanged: (value) {
                        setState(() {
                          GlobalColors.isDarkMode = value;
                        });
                      },
                      activeColor: Colors.amber,
                      activeTrackColor: Colors.amber.withOpacity(0.3),
                      inactiveThumbColor: Colors.grey.shade400,
                      inactiveTrackColor: Colors.grey.shade300,
                    ),
                  ),

                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(
                      color: GlobalColors.secondaryColor.withOpacity(0.2),
                      height: 1,
                      thickness: 1,
                      indent: 20,
                      endIndent: 20,
                    ),
                  ),

                  if (!isAnonymous)
                    _buildMenuItem(
                      icon: Icons.logout,
                      iconColor:
                          GlobalColors.isDarkMode
                              ? Colors.red[300]!
                              : Colors.red.shade600,
                      iconBg:
                          GlobalColors.isDarkMode
                              ? Colors.red[900]!.withOpacity(0.3)
                              : Colors.red.shade50,
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
                          iconColor:
                              GlobalColors.isDarkMode
                                  ? Colors.green[300]!
                                  : Colors.green.shade600,
                          iconBg:
                              GlobalColors.isDarkMode
                                  ? Colors.green[900]!.withOpacity(0.3)
                                  : Colors.green.shade50,
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
                          iconColor:
                              GlobalColors.isDarkMode
                                  ? Colors.teal[300]!
                                  : Colors.teal.shade600,
                          iconBg:
                              GlobalColors.isDarkMode
                                  ? Colors.teal[900]!.withOpacity(0.3)
                                  : Colors.teal.shade50,
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
          color: GlobalColors.secondaryColor,
        ),
      ),
      trailing:
          trailing ??
          (badge != null
              ? badge
              : Icon(
                Icons.chevron_right,
                color: GlobalColors.secondaryColor.withOpacity(0.4),
              )),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;

    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MapScreen()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => FavorisPage()),
        );
        break;
      case 3:
        break;
      default:
        break;
    }
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
        GlobalColors.isDarkMode ? Colors.blue.shade200 : Colors.blue;

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
                      ? Colors.blue.withOpacity(0.2)
                      : Colors.blue.withOpacity(0.1))
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

  Widget _buildInterestsSection() {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color:
            GlobalColors.isDarkMode
                ? GlobalColors.accentColor.withOpacity(0.1)
                : GlobalColors.primaryColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color:
                GlobalColors.isDarkMode ? Colors.transparent : Colors.black12,
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
                      backgroundColor:
                          GlobalColors.isDarkMode
                              ? GlobalColors.accentColor.withOpacity(0.3)
                              : Colors.green.shade100,
                      child: Icon(
                        _getInterestIcon(interest),
                        size: 16,
                        color: Colors.green.shade700,
                      ),
                    ),
                    label: Text(
                      interest,
                      style: TextStyle(
                        color:
                            GlobalColors.isDarkMode
                                ? Colors.white70
                                : Colors.green.shade700,
                      ),
                    ),
                    backgroundColor:
                        GlobalColors.isDarkMode
                            ? Colors.grey.shade800
                            : Colors.green.shade50,
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
        color:
            GlobalColors.isDarkMode
                ? GlobalColors.accentColor.withOpacity(0.1)
                : GlobalColors.primaryColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color:
                GlobalColors.isDarkMode ? Colors.transparent : Colors.black12,
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
              Icon(Icons.location_pin, color: Colors.pink, size: 22),
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
                  color:
                      GlobalColors.isDarkMode
                          ? GlobalColors.accentColor.withOpacity(0.2)
                          : Colors.pink.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.home_rounded, color: Colors.pink, size: 28),
              ),
              SizedBox(width: 15),
              Expanded(
                child: Text(
                  userAddress,
                  style: TextStyle(
                    fontSize: 16,
                    color:
                        GlobalColors.isDarkMode
                            ? Colors.white
                            : GlobalColors.secondaryColor,
                  ),
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
        color:
            GlobalColors.isDarkMode
                ? GlobalColors.accentColor.withOpacity(0.1)
                : GlobalColors.primaryColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color:
                GlobalColors.isDarkMode ? Colors.transparent : Colors.black12,
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
            color:
                GlobalColors.isDarkMode
                    ? GlobalColors.accentColor.withOpacity(0.2)
                    : color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 30),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color:
                GlobalColors.isDarkMode
                    ? Colors.white.withOpacity(0.9)
                    : color.withAlpha(200),
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
      backgroundColor: GlobalColors.primaryColor,
      drawer: _buildSideMenu(),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                automaticallyImplyLeading: false,
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
                                        color: GlobalColors.secondaryColor,
                                      ),
                                    ),
                                  ),
                                  if (!isAnonymous)
                                    IconButton(
                                      icon: Icon(
                                        Icons.edit_note_rounded,
                                        size: 35,
                                        color: GlobalColors.secondaryColor
                                            .withOpacity(0.7),
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
                            color:
                                GlobalColors.isDarkMode
                                    ? GlobalColors.accentColor.withOpacity(0.1)
                                    : GlobalColors.primaryColor,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    GlobalColors.isDarkMode
                                        ? Colors.transparent
                                        : Colors.black12,
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
                              Container(
                                decoration: BoxDecoration(
                                  color:
                                      GlobalColors.isDarkMode
                                          ? GlobalColors.accentColor
                                              .withOpacity(0.2)
                                          : GlobalColors.primaryColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: EdgeInsets.all(10),
                                child: Text(
                                  description != null && description!.isNotEmpty
                                      ? description!
                                      : 'Pas de description disponible',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: GlobalColors.secondaryColor,
                                    height: 1.4,
                                  ),
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
                                  color: GlobalColors.secondaryColor
                                      .withOpacity(0.6),
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
