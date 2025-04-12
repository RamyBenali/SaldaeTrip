import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:untitled/models/offre_model.dart';
import 'offre_details.dart';
import 'weather_main.dart';
import 'profile.dart';
import 'map.dart';

final supabase = Supabase.instance.client;

class FavorisPage extends StatefulWidget {
  @override
  _FavorisPageState createState() => _FavorisPageState();
}

class _FavorisPageState extends State<FavorisPage> {
  List<Offre> favoris = [];
  int _selectedIndex = 2;
  bool isLoading = true;
  String searchQuery = '';
  String? selectedCategorie;
  String? selectedVille;
  double? selectedTarifMax;
  bool isAnonymous = false;

  @override
  void initState() {
    super.initState();
    _fetchFavoris();
  }

  Future<void> _fetchFavoris() async {
    final user = supabase.auth.currentUser;

    if (user?.isAnonymous == true) {
      setState(() {
        isAnonymous = true;
        isLoading = false;
      });
      return;
    }

    try {
      if (user == null) {
        setState(() {
          favoris = [];
          isLoading = false;
        });
        return;
      }

      final email = user.email;
      final response = await supabase
          .from('personne')
          .select('idpersonne')
          .eq('email', email!)
          .maybeSingle();

      final idpersonne = response?['idpersonne'];

      final favorisResponse = await supabase
          .from('ajouterfavoris')
          .select('offre(idoffre, nom, categorie, tarifs, description, adresse, image)')
          .eq('idvoyageur', idpersonne);

      final data = favorisResponse as List;

      setState(() {
        favoris = data.map((item) => Offre.fromJson(item['offre'])).toList();
        isLoading = false;
      });
    } catch (e) {
      print('Erreur lors de la récupération des favoris : $e');
      setState(() {
        isLoading = false;
      });
    }
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

  @override
  Widget build(BuildContext context) {
    final filteredOffres = favoris.where((offre) {
      final query = searchQuery.toLowerCase();
      final matchQuery = offre.nom.toLowerCase().contains(query) ||
          offre.categorie.toLowerCase().contains(query) ||
          offre.adresse.toLowerCase().contains(query);
      final matchCategorie = selectedCategorie == null || offre.categorie == selectedCategorie;
      final matchVille = selectedVille == null || offre.adresse.toLowerCase().contains(selectedVille!.toLowerCase());
      final matchTarif = selectedTarifMax == null || (() {
        final regex = RegExp(r'(\d+)(?=\s*-|\s*D|\s*da|\s*$)');
        final match = regex.firstMatch(offre.tarifs);
        if (match == null) return true;
        final firstNumber = int.tryParse(match.group(0) ?? '0');
        return firstNumber == null || firstNumber <= selectedTarifMax!;
      })();
      return matchQuery && matchCategorie && matchVille && matchTarif;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Mes Favoris', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        automaticallyImplyLeading: false, // Supprime la flèche retour
      ),
      body: Stack(
          children : [
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: const BoxDecoration(
                    color: Colors.blueAccent,
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Rechercher dans mes favoris...',
                            prefixIcon: const Icon(Icons.search, color: Colors.white),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              searchQuery = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.filter_alt_outlined, color: Colors.white),
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                            ),
                            builder: (context) => buildFilterSheet(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Visibility(
                  visible: !isAnonymous,
                  child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredOffres.length,
                  itemBuilder: (context, index) {
                    final offre = filteredOffres[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OffreDetailPage(offre: offre),
                          ),
                        );
                      },
                      child: Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 5,
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16.0),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(offre.image, width: 60, height: 60, fit: BoxFit.cover),
                          ),
                          title: Text(offre.nom, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${offre.categorie} - ${offre.tarifs}'),
                        ),
                      ),
                    );
                  },
                  ),
                ),
                Visibility(
                    visible: isAnonymous,
                    child: Positioned(
                        left: 24,
                        right: 24,
                        child: Container(
                        width: MediaQuery.of(context).size.width - 48,
                            child: Text(
                              'Veuillez vous connecter ou créer un compte afin de pouvoir ajouter ou retirer des favoris',
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
              ],
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

  Widget buildFilterSheet() {
    List<String> villes = ['Béjaïa', 'Béjaïa centre', 'Melbou', 'Tichy', 'Elkseur', 'Akbou'];
    List<String> categories = favoris.map((o) => o.categorie).toSet().where((c) => c.isNotEmpty).toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Filtres',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Catégorie',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: categories.map((c) {
              return DropdownMenuItem(value: c, child: Text(c));
            }).toList(),
            onChanged: (value) => setState(() => selectedCategorie = value),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Ville',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: villes.map((v) {
              return DropdownMenuItem(value: v, child: Text(v));
            }).toList(),
            onChanged: (value) => setState(() => selectedVille = value),
          ),
          const SizedBox(height: 12),
          TextField(
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Tarif max en DA',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) {
              setState(() {
                selectedTarifMax = double.tryParse(value);
              });
            },
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              setState(() {}); // Appliquer les filtres
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Appliquer les filtres'),
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
