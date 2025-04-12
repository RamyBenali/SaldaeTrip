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

void main() async {
  // Initialisation de Supabase
  await Supabase.initialize(
    url: 'https://xqbnjwedfurajossjgof.supabase.co', // Remplace avec l'URL de ton projet Supabase
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhxYm5qd2VkZnVyYWpvc3NqZ29mIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDM2MTQzMDYsImV4cCI6MjA1OTE5MDMwNn0._1LKV9UaV-tsOt9wCwcD8Xp_WvXrumlp0Jv0az9rgp4', // Remplace avec la clé anonyme de ton projet Supabase
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ProfilePage(),
    );
  }
}

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
  String? description;  // Nouvelle variable pour la description
  bool isLoading = true;  // Ajout d'un état pour le chargement
  bool isAnonymous = false;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _navigateToEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditProfilePage()),
    );
  }

  Future<void> _fetchUserProfile() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user != null) {
      if (user.isAnonymous == true) {
        setState(() {
          isAnonymous = true;
          firstName = "Anonyme";
          lastName = "";
          description = "Aucune description disponible";
          isLoading = false;
        });
        return;
      }

      final userEmail = user.email;

      try {
        print("Utilisateur connecté avec email : $userEmail");

        // Récupère les infos dans la table 'personne' à partir de l'email
        final responsePersonne = await Supabase.instance.client
            .from('personne')
            .select('idpersonne, nom, prenom, email')
            .eq('email', userEmail as Object)
            .maybeSingle();

        if (responsePersonne != null) {
          final userId = responsePersonne['idpersonne'];

          final responseProfile = await Supabase.instance.client
              .from('profiles')
              .select('description, profile_photo, banner_photo' )
              .eq('id', userId)
              .maybeSingle();

          setState(() {
            firstName = responsePersonne['prenom'];
            lastName = responsePersonne['nom'];
            description = responseProfile?['description'] ?? "Pas de description disponible";
            profileImageUrl = responseProfile?['profile_photo'];
            bannerImageUrl = responseProfile?['banner_photo'];
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
          });
          print("Aucune correspondance trouvée dans la table personne pour l'email.");
        }
      } catch (e) {
        setState(() {
          isLoading = false;
        });
        print("Erreur lors de la récupération du profil : $e");
      }
    } else {
      setState(() {
        isLoading = false;
      });
      print("Aucun utilisateur connecté");
    }
  }
  Drawer _buildSideMenu() {
    return Drawer(
      backgroundColor: Colors.white.withOpacity(0.95),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Text(
              'Paramètres',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.android),
            title: Text('Service Client'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ParametresPage()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.help),
            title: Text('Aide'),
            onTap: () {
            },
          ),
          ListTile(
            leading: Icon(Icons.verified_user),
            title: Text('Devenir prestataire'),
            onTap: () {
              if (isAnonymous) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Veuillez créer un compte pour devenir prestataire.'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Colors.redAccent,
                  ),
                );
              } else {
                final url = Uri.parse('https://docs.google.com/forms/d/e/1FAIpQLScWylpUlA71rmHhQzWWj3TGVdjOZtmAqaqvJxXmAa4ES-xaEA/viewform?usp=dialog');
                launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
          ),
          Container(
            width: 378,
            height: 2,
            decoration: ShapeDecoration(
              color: const Color(0x7FD9D9D9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
          Visibility(
            visible: !isAnonymous,
            child: ListTile(
              leading: Icon(Icons.logout),
              title: Text('Déconnexion'),
              onTap: () async {
                await Supabase.instance.client.auth.signOut();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Déconnecté")),
                );
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => SplashScreen()),
                      (route) => false,
                );
              },
            ),
          ),
          Visibility(
            visible: isAnonymous,
            child: ListTile(
              leading: Icon(Icons.logout),
              title: Text('Se connecter'),
              onTap: () async {
                await Supabase.instance.client.auth.signOut();
                Navigator.pop(context);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                      (route) => false,
                );
              },
            ),
          ),
          Visibility(
            visible: isAnonymous,
            child: ListTile(
              leading: Icon(Icons.logout),
              title: Text("S'inscrire"),
              onTap: () async {
                await Supabase.instance.client.auth.signOut();
                Navigator.pop(context);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => SigninScreen()),
                      (route) => false,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Navigation logic
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
      // Favoris (not implemented yet)
        break;
      case 3:

        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildSideMenu(),
      body: Stack(
        children: [
          Column(
            children: [
              Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: profileImageUrl != null
                            ? NetworkImage(bannerImageUrl!)
                            : AssetImage('assets/images/banniere.jpg') as ImageProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.center,
                        colors: [
                          Colors.white.withOpacity(0.8),
                          Colors.white.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    right: 16,
                    top: 50,
                    child: Builder(
                      builder: (context) => IconButton(
                        icon: Icon(Icons.menu, color: Colors.white, size: 30),
                        onPressed: () {
                          Scaffold.of(context).openDrawer();
                        },
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 5),
              Padding(
                padding: isAnonymous ? const EdgeInsets.only(left: 150) : const EdgeInsets.only(left: 150),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isLoading
                          ? 'Chargement...'
                          : (firstName != null && lastName != null
                          ? '$firstName $lastName'
                          : 'Erreur de profil'),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    // Remplacer Expanded par un widget Container ou un SizedBox
                    Container(
                      width: double.infinity, // Assure que le container occupe toute la largeur disponible
                      child: Text(
                        description != null && description!.isNotEmpty
                            ? description!
                            : 'Pas de description disponible',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        softWrap: true,  // Assure que le texte se casse bien à la ligne
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 50),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: isAnonymous ? null : _navigateToEditProfile,
                    child: Text("Modifier"),
                  ),
                  ElevatedButton(
                    onPressed: isAnonymous ? null : () {
                    },
                    child: Text("Partager le profil"),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            left: 24,
            top: 170,
            child: CircleAvatar(
              radius: 60,
              backgroundImage: profileImageUrl != null
                  ? NetworkImage(profileImageUrl!)  // Utiliser l'URL de l'image du profil
                  : AssetImage('assets/images/profile.jpg') as ImageProvider,  // Image par défaut si l'URL est null
            ),
          ),
          Visibility(
            visible: isAnonymous,
            child: Positioned(
              left: 24,
              right: 24,
              top: 500,
              child: Container(
                width: MediaQuery.of(context).size.width - 48,
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
}
