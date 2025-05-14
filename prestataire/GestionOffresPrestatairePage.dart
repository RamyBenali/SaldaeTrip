import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../offre_details.dart';
import '../models/offre_model.dart';
import 'ModifierOffresPage.dart';
import '../GlovalColors.dart';

class ListeOffresPrestatairePage extends StatefulWidget {
  @override
  _ListeOffresPrestatairePageState createState() =>
      _ListeOffresPrestatairePageState();
}

class _ListeOffresPrestatairePageState extends State<ListeOffresPrestatairePage> {
  final supabase = Supabase.instance.client;
  List<Offre> offres = [];
  List<Offre> filteredOffres = [];
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchOffresPrestataire();
  }

  Future<void> fetchOffresPrestataire() async {
    final user = supabase.auth.currentUser;

    setState(() => isLoading = true);

    if (user == null) {
      setState(() => isLoading = false);
      return;
    }

    try {
      final response = await supabase
          .from('offre')
          .select('*')
          .eq('user_id', user.id);

      setState(() {
        offres = response.map<Offre>((offreMap) => Offre.fromJson(offreMap)).toList();
        filteredOffres = offres;
        isLoading = false;
      });
    } catch (e) {
      print("Erreur lors de la récupération des offres: $e");
      setState(() => isLoading = false);
    }
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
    try {
      await supabase.from('offre').delete().eq('idoffre', id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Offre supprimée avec succès'),
          backgroundColor: GlobalColors.isDarkMode ? Colors.green[800] : Colors.green,
        ),
      );
      await fetchOffresPrestataire();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la suppression: $e'),
          backgroundColor: GlobalColors.isDarkMode ? Colors.red[800] : Colors.red,
        ),
      );
    }
  }

  void modifierOffre(Offre offre) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ModifierOffrePage(offre: offre),
      ),
    ).then((modified) {
      if (modified != null && modified) {
        fetchOffresPrestataire();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = GlobalColors.isDarkMode ? Colors.grey[800]!.withOpacity(0.5) : Colors.white;
    final borderColor = GlobalColors.isDarkMode ? Colors.grey[600]! : Colors.grey[300]!;
    final textColor = GlobalColors.secondaryColor;
    final secondaryTextColor = GlobalColors.isDarkMode ? Colors.white70 : Colors.black54;

    return Scaffold(
      backgroundColor: GlobalColors.primaryColor,
      appBar: AppBar(
        title: Text(
          "Mes Offres",
          style: GoogleFonts.robotoSlab(color: Colors.white),
        ),
        backgroundColor: GlobalColors.bleuTurquoise,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: filterOffres,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                labelText: 'Rechercher par nom',
                labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                prefixIcon: Icon(Icons.search, color: textColor.withOpacity(0.7)),
                filled: true,
                fillColor: cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor),
                ),
              ),
            ),
          ),
          isLoading
              ? Center(child: CircularProgressIndicator())
              : filteredOffres.isEmpty
              ? Center(
            child: Text(
              "Aucune offre trouvée",
              style: TextStyle(color: textColor),
            ),
          )
              : Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemCount: filteredOffres.length,
              itemBuilder: (context, index) {
                final offre = filteredOffres[index];
                return Card(
                  margin: EdgeInsets.only(bottom: 12),
                  color: cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: borderColor),
                  ),
                  elevation: 3,
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: offre.image != null && offre.image.isNotEmpty
                          ? Image.network(
                        offre.image,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[300],
                          child: Icon(
                            Icons.image_not_supported,
                            color: Colors.grey[700],
                          ),
                        ),
                      )
                          : Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[300],
                        child: Icon(
                          Icons.image_not_supported,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                    title: Text(
                      offre.nom ?? 'Nom inconnu',
                      style: GoogleFonts.robotoSlab(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    subtitle: Text(
                      "${offre.categorie ?? 'Catégorie inconnue'}\nTarif: ${offre.tarifs ?? 'N/A'} DA",
                      style: GoogleFonts.robotoSlab(
                        height: 1.4,
                        color: secondaryTextColor,
                      ),
                    ),
                    isThreeLine: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OffreDetailPage(offre: offre),
                        ),
                      );
                    },
                    trailing: PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: textColor),
                      onSelected: (value) {
                        if (value == 'modifier') {
                          modifierOffre(offre);
                        } else if (value == 'supprimer') {
                          supprimerOffre(offre.id);
                        } else if (value == 'voir') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OffreDetailPage(offre: offre),
                            ),
                          );
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'modifier',
                          child: Text('Modifier'),
                        ),
                        PopupMenuItem(
                          value: 'supprimer',
                          child: Text('Supprimer'),
                        ),
                        PopupMenuItem(
                          value: 'voir',
                          child: Text('Voir'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}