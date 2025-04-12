import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'models/offre_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class OffreDetailPage extends StatefulWidget {
  final Offre offre;

  const OffreDetailPage({Key? key, required this.offre}) : super(key: key);

  @override
  State<OffreDetailPage> createState() => _OffreDetailPageState();
}
class _OffreDetailPageState extends State<OffreDetailPage> {
  bool isFavori = false;
  bool showFavoriMessage = false;
  String favoriMessage = '';

  Future<void> checkIfFavori(int idOffre) async {
    try {
      final userEmail = await getCurrentUserId();
      final userId = await getPersonIdByEmail(userEmail);

      if (userId == null) return;

      final response = await Supabase.instance.client
          .from('ajouterfavoris')
          .select()
          .eq('idoffre', idOffre)
          .eq('idvoyageur', userId)
          .maybeSingle();

      if (response != null) {
        setState(() {
          isFavori = true;
        });
      }
    } catch (e) {
      print("Erreur lors de la vérification des favoris: $e");
    }
  }

  Future<String> getCurrentUserId() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      return user.email!; // On retourne l'email pour pouvoir rechercher dans la table 'personne'
    } else {
      throw Exception("User is not logged in");
    }
  }

  Future<int?> getPersonIdByEmail(String email) async {
    final responsePersonne = await Supabase.instance.client
        .from('personne')
        .select('idpersonne')
        .eq('email', email as Object)
        .maybeSingle();

    if (responsePersonne == null) {
      return null;
    }
    final userId = responsePersonne['idpersonne'];


    return userId;
  }

  Future<void> addFavori(int idOffre) async {
    try {
      final userEmail = await getCurrentUserId(); // Récupère l'email de l'utilisateur
      final userId = await getPersonIdByEmail(userEmail); // Récupère l'idpersonne à partir de l'email

      if (userId == null) {
        print("Erreur: L'utilisateur n'a pas pu être trouvé.");
        return;
      }

      final response = await Supabase.instance.client
          .from('ajouterfavoris')
          .insert([
        {'idoffre': idOffre, 'idvoyageur': userId}
      ]);

      if (response == null) {
      } else if (response.error != null) {
        print('Erreur lors de l\'ajout au favoris: ${response.error!.message}');
      } else {
        print('Offre ajoutée aux favoris');
      }
    } catch (e) {
      print("Erreur: $e");
    }
  }

  Future<void> removeFavori(int idOffre) async {
    try {
      final userEmail = await getCurrentUserId(); // Récupère l'email de l'utilisateur
      final userId = await getPersonIdByEmail(userEmail); // Récupère l'idpersonne à partir de l'email

      if (userId == null) {
        print("Erreur: L'utilisateur n'a pas pu être trouvé.");
        return;
      }

      final response = await Supabase.instance.client
          .from('ajouterfavoris')
          .delete()
          .eq('idoffre', idOffre)
          .eq('idvoyageur', userId);

      if (response == null) {
      } else if (response.error != null) {
        print('Erreur lors du retrait des favoris: ${response.error!.message}');
      } else {
        print('Offre retirée des favoris');
      }
    } catch (e) {
      print("Erreur: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    checkIfFavori(widget.offre.id);
  }

  @override
  Widget build(BuildContext context) {
    final offre = widget.offre;

    return Scaffold(
      appBar: AppBar(
        title: Text(offre.nom, style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ElevatedButton.icon(
          onPressed: () {
          },
          icon: Icon(Icons.map, color: Colors.white),
          label: Text("Localiser sur la carte", style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      body: SingleChildScrollView(
          child: Column(
              children: [
          Stack(
          children: [
          ClipRRect(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      child: Image.network(
        offre.image,
        height: 500,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    ),

            Positioned(
              top: 16,
              right: 16,
              child: GestureDetector(
                onTap: () async {
                  setState(() {
                    isFavori = !isFavori;
                    favoriMessage = isFavori
                        ? "Ajouté aux favoris"
                        : "Retiré des favoris";
                    showFavoriMessage = true;
                  });

                  // Masquer le message après 3 secondes
                  Future.delayed(Duration(seconds: 3), () {
                    if (mounted) {
                      setState(() {
                        showFavoriMessage = false;
                      });
                    }
                  });

                  if (isFavori) {
                    await addFavori(offre.id);
                  } else {
                    await removeFavori(offre.id);
                  }
                },

                child: Container(
            decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            shape: BoxShape.circle,
            ),
            padding: EdgeInsets.all(8),
                  child: Icon(
            isFavori ? Icons.favorite : Icons.favorite_border,
            color: isFavori ? Colors.red : Colors.grey,
            size: 28,
                  ),
            ),
            ),
            ),
            if (showFavoriMessage)
              Positioned(
                top: 20,
                right: 70,
                child: AnimatedOpacity(
                  opacity: showFavoriMessage ? 1.0 : 0.0,
                  duration: Duration(milliseconds: 300),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      favoriMessage,
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ),
              ),
            ],
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(context, "Description"),
                  Text(
                    offre.description,
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 20),

                  _buildSectionTitle(context, "Tarifs"),
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        offre.tarifs,
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),

                  _buildSectionTitle(context, "Adresse"),
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.blue),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          offre.adresse,
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  _buildSectionTitle(context, "Réseaux sociaux"),
                  Row(
                    children: [
                      if (offre.offreInsta.isNotEmpty)
                        IconButton(
                          icon: Icon(FontAwesomeIcons.instagram, color: Colors.purple),
                          onPressed: () {
                            launchUrl(Uri.parse(offre.offreInsta), mode: LaunchMode.externalApplication);
                          },
                        ),
                      if (offre.offreFb.isNotEmpty)
                        IconButton(
                          icon: Icon(FontAwesomeIcons.facebook, color: Colors.blue),
                          onPressed: () {
                            launchUrl(Uri.parse(offre.offreFb), mode: LaunchMode.externalApplication);
                          },
                        ),
                    ],
                  ),
                  SizedBox(height: 80), // Un peu d'espace en bas pour éviter que ça touche le bouton
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge!.copyWith(
        fontWeight: FontWeight.bold,
        color: Colors.blue,
      ),
    );
  }
}
