import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../GlovalColors.dart';
import '../favoris.dart';
import 'AjouterOffrePage.dart';
import 'ModificationOffrepage.dart';

class GestionOffrePage extends StatefulWidget {
  const GestionOffrePage({super.key});

  @override
  State<GestionOffrePage> createState() => _GestionOffrePageState();
}

class _GestionOffrePageState extends State<GestionOffrePage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> offres = [];
  List<Map<String, dynamic>> filteredOffres = [];
  final TextEditingController searchController = TextEditingController();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchOffres();
    searchController.addListener(_filterOffres);
  }

  Future<void> fetchOffres() async {
    try {
      final response = await supabase
          .from('offre')
          .select('*, prestataire(entreprise)')
          .order('idoffre', ascending: false);

      setState(() {
        offres = List<Map<String, dynamic>>.from(response);
        filteredOffres = offres;
        isLoading = false;
      });
    } catch (e) {
      print("Erreur lors de la récupération des offres : $e");
      setState(() => isLoading = false);
    }
  }

  void _filterOffres() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredOffres = offres.where((offre) {
        final nomOffre = offre['nom']?.toLowerCase() ?? '';
        final entreprise = offre['prestataire']?['entreprise']?.toLowerCase() ?? '';
        return nomOffre.contains(query) || entreprise.contains(query);
      }).toList();
    });
  }

  Future<void> supprimerOffre(int idoffre, String categorie) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer cette offre ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                if (categorie == 'Restaurant') {
                  await supabase.from('restaurant').delete().eq('idoffre', idoffre);
                } else if (categorie == 'Hôtel') {
                  await supabase.from('hotel').delete().eq('idoffre', idoffre);
                } else {
                  await supabase.from('activité').delete().eq('idoffre', idoffre);
                }

                await supabase.from('offre').delete().eq('idoffre', idoffre);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Offre supprimée avec succès'),
                    backgroundColor: GlobalColors.isDarkMode ? Colors.green[800] : Colors.green,
                  ),
                );

                await fetchOffres();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erreur lors de la suppression: $e'),
                    backgroundColor: GlobalColors.isDarkMode ? Colors.red[800] : Colors.red,
                  ),
                );
              }
            },
            child: Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void modifierOffre(Map<String, dynamic> offre) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ModifierOffrePage(offre: offre),
      ),
    ).then((_) => fetchOffres());
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = GlobalColors.isDarkMode ? Colors.grey[800]!.withOpacity(0.5) : Colors.white;
    final borderColor = GlobalColors.isDarkMode ? Colors.grey[600]! : Colors.grey[300]!;
    final textColor = GlobalColors.secondaryColor;

    return Scaffold(
      backgroundColor: GlobalColors.primaryColor,
      appBar: AppBar(
        title: Text(
          'Gestion des Offres',
          style: GoogleFonts.robotoSlab(color: Colors.white),
        ),
        backgroundColor: GlobalColors.bleuTurquoise,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AjouterOffrePage()),
              );
              fetchOffres();
            },
          )
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: searchController,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: 'Rechercher par nom ou entreprise',
                hintStyle: TextStyle(color: textColor.withOpacity(0.7)),
                prefixIcon: Icon(Icons.search, color: textColor),
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
          Expanded(
            child: ListView.builder(
              itemCount: filteredOffres.length,
              itemBuilder: (context, index) {
                final o = filteredOffres[index];
                final prestataire = o['prestataire'];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: borderColor),
                  ),
                  elevation: 2,
                  child: ListTile(
                    leading: o['image'] != null
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        o['image'],
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.image_not_supported,
                          size: 30,
                          color: textColor,
                        ),
                      ),
                    )
                        : Icon(Icons.image_not_supported, size: 30, color: textColor),
                    title: Text(
                      o['nom'],
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      'Catégorie: ${o['categorie']}\nPrestataire: ${prestataire['entreprise']}',
                      style: TextStyle(color: textColor.withOpacity(0.8)),
                    ),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.orange),
                          onPressed: () => modifierOffre(o),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => supprimerOffre(o['idoffre'], o['categorie']),
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