import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'GlovalColors.dart';

class UserProfilePage extends StatefulWidget {
  final String userId; // L'ID de l'utilisateur à afficher

  const UserProfilePage({Key? key, required this.userId}) : super(key: key);

  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  String? profileImageUrl;
  String? bannerImageUrl;
  String? firstName;
  String? lastName;
  String? description;
  bool isLoading = true;
  List<String> userInterests = [];
  List<String> weatherPreferences = [];
  String userAddress = "Adresse non renseignée";

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    try {
      final responsePersonne = await Supabase.instance.client
          .from('personne')
          .select('nom, prenom, adresse')
          .eq('user_id', widget.userId)
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

      final responseProfile = await Supabase.instance.client
          .from('profiles')
          .select(
        'description, profile_photo, banner_photo, centre_interet, preferences_meteo',
      )
          .eq('user_id', widget.userId)
          .maybeSingle();

      setState(() {
        userAddress = responsePersonne['adresse'] ?? "Adresse non renseignée";
        firstName = responsePersonne['prenom'];
        lastName = responsePersonne['nom'];
        description =
            responseProfile?['description'] ?? "Pas de description disponible";
        profileImageUrl = responseProfile?['profile_photo'];
        bannerImageUrl = responseProfile?['banner_photo'];

        userInterests = responseProfile?['centre_interet'] != null
            ? List<String>.from(responseProfile!['centre_interet'])
            : [];

        weatherPreferences = responseProfile?['preferences_meteo'] != null
            ? List<String>.from(responseProfile!['preferences_meteo'])
            : [];

        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        profileImageUrl = null;
        bannerImageUrl = null;
        userInterests = [];
      });
      print("Erreur lors de la récupération du profil: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GlobalColors.primaryColor,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200.0,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: bannerImageUrl != null
                                ? NetworkImage(bannerImageUrl!)
                                : const AssetImage('assets/images/banniere.jpg')
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
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              SliverList(
                delegate: SliverChildListDelegate([
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 100),
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
                                  backgroundImage: profileImageUrl != null
                                      ? NetworkImage(profileImageUrl!)
                                      : const AssetImage(
                                    'assets/images/profile.jpg',
                                  ) as ImageProvider,
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Text(
                                isLoading
                                    ? 'Chargement...'
                                    : (firstName != null && lastName != null
                                    ? '$firstName $lastName'
                                    : 'Profil invité'),
                                style: GoogleFonts.robotoSlab(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: GlobalColors.secondaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildAboutSection(),
                        const SizedBox(height: 20),
                        if (userInterests.isNotEmpty) _buildInterestsSection(),
                        if (userInterests.isNotEmpty) const SizedBox(height: 20),
                        _buildAddressSection(),
                        const SizedBox(height: 20),
                        if (weatherPreferences.isNotEmpty)
                          _buildWeatherPreferencesSection(),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: GlobalColors.isDarkMode
            ? GlobalColors.accentColor.withOpacity(0.1)
            : GlobalColors.primaryColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: GlobalColors.isDarkMode ? Colors.transparent : Colors.black12,
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.blue, size: 20),
              const SizedBox(width: 10),
              Text(
                'À PROPOS',
                style: GoogleFonts.robotoSlab(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: GlobalColors.isDarkMode
                  ? GlobalColors.accentColor.withOpacity(0.2)
                  : GlobalColors.primaryColor,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(10),
            child: Text(
              description != null && description!.isNotEmpty
                  ? description!
                  : 'Pas de description disponible',
              style: GoogleFonts.robotoSlab(
                fontSize: 16,
                color: GlobalColors.secondaryColor,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterestsSection() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: GlobalColors.isDarkMode
            ? GlobalColors.accentColor.withOpacity(0.1)
            : GlobalColors.primaryColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: GlobalColors.isDarkMode ? Colors.transparent : Colors.black12,
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.interests, color: Colors.green, size: 20),
              const SizedBox(width: 10),
              Text(
                'CENTRES D\'INTÉRÊT',
                style: GoogleFonts.robotoSlab(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: userInterests.map((interest) {
              return Chip(
                label: Text(interest),
                backgroundColor: GlobalColors.isDarkMode
                    ? Colors.grey.shade800
                    : Colors.green.shade50,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressSection() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: GlobalColors.isDarkMode
            ? GlobalColors.accentColor.withOpacity(0.1)
            : GlobalColors.primaryColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: GlobalColors.isDarkMode ? Colors.transparent : Colors.black12,
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_pin, color: Colors.pink, size: 22),
              const SizedBox(width: 10),
              Text(
                'ADRESSE',
                style: GoogleFonts.robotoSlab(
                  fontWeight: FontWeight.bold,
                  color: Colors.pink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: GlobalColors.isDarkMode
                      ? GlobalColors.accentColor.withOpacity(0.2)
                      : Colors.pink.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.home_rounded, color: Colors.pink, size: 28),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  userAddress,
                  style: GoogleFonts.robotoSlab(
                    fontSize: 16,
                    color: GlobalColors.isDarkMode
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
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: GlobalColors.isDarkMode
            ? GlobalColors.accentColor.withOpacity(0.1)
            : GlobalColors.primaryColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: GlobalColors.isDarkMode ? Colors.transparent : Colors.black12,
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.wb_sunny, color: Colors.orange, size: 20),
              const SizedBox(width: 10),
              Text(
                'PRÉFÉRENCES MÉTÉO',
                style: GoogleFonts.robotoSlab(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Wrap(
            spacing: 20,
            runSpacing: 15,
            children: weatherPreferences.map((weather) {
              return _buildWeatherPreference(weather);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherPreference(String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: GlobalColors.isDarkMode
                ? GlobalColors.accentColor.withOpacity(0.2)
                : Colors.orange.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.wb_sunny, color: Colors.orange, size: 30),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.robotoSlab(
            color: GlobalColors.isDarkMode
                ? Colors.white.withOpacity(0.9)
                : Colors.orange.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}