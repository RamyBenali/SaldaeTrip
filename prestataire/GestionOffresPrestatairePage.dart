import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../offre_details.dart';
import '../models/offre_model.dart';
import 'ModifierOffresPage.dart';

class ListeOffresPrestatairePage extends StatefulWidget {
  @override
  _ListeOffresPrestatairePageState createState() =>
      _ListeOffresPrestatairePageState();
}

class _ListeOffresPrestatairePageState extends State<ListeOffresPrestatairePage> {
  final supabase = Supabase.instance.client;
  List<dynamic> offres = [];
  List<dynamic> filteredOffres = [];
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchOffresPrestataire();
  }

  Future<void> fetchOffresPrestataire() async {
    final user = Supabase.instance.client.auth.currentUser;

    setState(() => isLoading = true);

    if (user == null) {
      setState(() => isLoading = false);
      return;
    }

    final idpersonne = user.id;

    final response = await supabase
        .from('offre')
        .select('*')
        .eq('user_id', idpersonne);

    setState(() {
      // Utiliser la méthode fromJson pour convertir chaque Map en objet Offre
      offres = response.map<Offre>((offreMap) => Offre.fromJson(offreMap)).toList();
      filteredOffres = offres; // Initially, display all offers
      isLoading = false;
    });
  }

  void filterOffres(String query) {
    setState(() {
      searchQuery = query;
      filteredOffres = offres
          .where((offre) =>
          (offre.nom ?? '').toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  Future<void> supprimerOffre(int id) async {
    await supabase.from('offre').delete().eq('idoffre', id);
    fetchOffresPrestataire();
  }

  void modifierOffre(Offre offre) {
    // Naviguer vers la page de modification
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ModifierOffrePage(offre: offre),
      ),
    ).then((modified) {
      if (modified != null && modified) {
        // Si la modification a été effectuée, actualiser la liste des offres
        fetchOffresPrestataire();
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Mes Offres"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: filterOffres,
              decoration: InputDecoration(
                labelText: 'Rechercher par nom',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          isLoading
              ? Center(child: CircularProgressIndicator())
              : filteredOffres.isEmpty
              ? Center(child: Text("Aucune offre trouvée"))
              : Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(10),
              itemCount: filteredOffres.length,
              itemBuilder: (context, index) {
                final offre = filteredOffres[index];
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 3,
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: offre.image != null && offre.image.isNotEmpty
                          ? Image.network(offre.image, width: 60, height: 60, fit: BoxFit.cover)
                          : Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[300],
                        child: Icon(Icons.image_not_supported, color: Colors.grey[700]),
                      ),
                    ),
                    title: Text(offre.nom ?? 'Nom inconnu', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      "${offre.categorie ?? 'Catégorie inconnue'}\nTarif: ${offre.tarifs ?? 'N/A'} DA",
                      style: TextStyle(height: 1.4),
                    ),
                    isThreeLine: true,
                    onTap: () {
                      // Naviguer vers la page de détails de l'offre
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OffreDetailPage(offre: offre),
                        ),
                      );
                    },
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'modifier') {
                          modifierOffre(offre);
                        } else if (value == 'supprimer') {
                          supprimerOffre(offre.id);
                        } else if (value == 'voir') {
                          // Naviguer vers la page de détails de l'offre
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OffreDetailPage(offre: offre),
                            ),
                          );
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(value: 'modifier', child: Text('Modifier')),
                        PopupMenuItem(value: 'supprimer', child: Text('Supprimer')),
                        PopupMenuItem(value: 'voir', child: Text('Voir')),
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}

