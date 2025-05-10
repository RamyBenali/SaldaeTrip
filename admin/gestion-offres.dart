import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
        filteredOffres = offres; // copie initiale
      });
    } catch (e) {
      print("Erreur lors de la récupération des offres : $e");
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
        SnackBar(content: Text('Offre supprimée avec succès')),
      );

      await fetchOffres();
    } catch (e) {
      print("Erreur lors de la suppression : $e");
    }
  }

  void modifierOffre(Map<String, dynamic> offre) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ModifierOffrePage(offre: offre),
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gestion des Offres' , style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
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
      body: offres.isEmpty
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher par nom ou entreprise',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
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
                  margin:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: o['image'] != null
                        ? Image.network(o['image'],
                        width: 60, height: 60, fit: BoxFit.cover)
                        : Icon(Icons.image_not_supported),
                    title: Text(o['nom']),
                    subtitle: Text(
                        'Catégorie: ${o['categorie']}\nPrestataire: ${prestataire['entreprise']}'),
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
                          onPressed: () =>
                              supprimerOffre(o['idoffre'], o['categorie']),
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
