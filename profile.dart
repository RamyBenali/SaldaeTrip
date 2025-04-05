import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'EditprofilePage.dart';
import 'map.dart';
import 'weather_main.dart';

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
  int _selectedIndex = 3;
  String? firstName;
  String? lastName;
  String? description;  // Nouvelle variable pour la description
  bool isLoading = true;  // Ajout d'un état pour le chargement

  @override
  void initState() {
    super.initState();
    _fetchUserProfile(); // Charger le profil de l'utilisateur
  }

  // Fonction pour rediriger vers la page de modification
  void _navigateToEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditProfilePage()),
    );
  }

  // Fonction pour récupérer les informations du profil
  // Fonction pour récupérer les informations du profil
  Future<void> _fetchUserProfile() async {
    final userId = '5';  // ID fixe pour tester
    if (userId != null) {
      try {
        print("Utilisateur connecté: ${userId}");

        // Récupérer les données depuis la table 'personne'
        final responsePersonne = await Supabase.instance.client
            .from('personne')
            .select('nom, prenom')
            .eq('idpersonne', userId)
            .maybeSingle();  // Utilisation de maybeSingle() pour éviter les erreurs si aucun profil n'est trouvé

        // Récupérer la description depuis la table 'profiles'
        final responseProfile = await Supabase.instance.client
            .from('profiles')
            .select('description')
            .eq('id', userId)
            .maybeSingle();

        // Ajouter un log pour voir la réponse de Supabase
        print("Réponse de profile: $responseProfile");

        if (responsePersonne != null && responseProfile != null) {
          setState(() {
            firstName = responsePersonne['prenom'];  // Accéder aux données
            lastName = responsePersonne['nom'];      // Accéder aux données
            description = responseProfile['description']; // Récupérer la description
            isLoading = false;  // On passe à l'état non-chargement
          });
        } else {
          setState(() {
            isLoading = false;
          });
          print("Aucun profil trouvé pour cet utilisateur");
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


  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                        image: AssetImage('assets/images/banniere.jpg'),
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
                    child: IconButton(
                      icon: Icon(Icons.menu, color: Colors.white, size: 30),
                      onPressed: () {
                        print("Paramètres appuyés");
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 5),
              Padding(
                padding: const EdgeInsets.only(left: 40),
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
                    Text(
                      description != null && description!.isNotEmpty
                          ? description!  // Afficher la description si elle est disponible
                          : 'Pas de description disponible',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),

                  ],
                ),
              ),
              SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _navigateToEditProfile,  // Redirige vers la page de modification
                    child: Text("Modifier"),
                  ),
                  ElevatedButton(
                    onPressed: () {},  // Action pour partager le profil
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
              backgroundImage: AssetImage('assets/images/profile.jpg'),
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

          // Navigation avec push pour chaque index
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
                MaterialPageRoute(builder: (context) => MapScreen()), // Page Carte
              );
              break;
            case 2:
            // Favoris (pas encore créée)
              break;
            case 3:

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
    );
  }
}
