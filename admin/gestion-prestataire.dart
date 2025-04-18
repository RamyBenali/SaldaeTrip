import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../favoris.dart';
import 'AjouterPrestatairePage.dart';
import 'ModificationPrestataire.dart';

class GestionPrestatairePage extends StatefulWidget {
  const GestionPrestatairePage({super.key});

  @override
  State<GestionPrestatairePage> createState() => _GestionPrestatairePageState();
}

class _GestionPrestatairePageState extends State<GestionPrestatairePage> {
  List<Map<String, dynamic>> prestataires = [];
  List<Map<String, dynamic>> filteredPrestataires = [];
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchPrestataires();
    searchController.addListener(_filterPrestataires);
  }

  Future<void> fetchPrestataires() async {
    try {
      final response = await supabase
          .from('personne')
          .select('*, prestataire(*)')
          .eq('role', 'Prestataire');

      setState(() {
        prestataires = List<Map<String, dynamic>>.from(response);
        filteredPrestataires = prestataires; // copie initiale
      });
    } catch (e) {
      print("Erreur lors de la récupération des prestataires : $e");
    }
  }

  void _filterPrestataires() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredPrestataires = prestataires.where((prestataire) {
        final nom = prestataire['nom']?.toLowerCase() ?? '';
        final prenom = prestataire['prenom']?.toLowerCase() ?? '';
        final entreprise = prestataire['prestataire']?['entreprise']?.toLowerCase() ?? '';
        return nom.contains(query) || prenom.contains(query) || entreprise.contains(query);
      }).toList();
    });
  }

  void supprimerPrestataire(int id) async {
    try {
      // Supprimer d'abord dans "prestataire"
      await supabase.from('prestataire').delete().eq('idpersonne', id);
      // Puis dans "personne"
      await supabase.from('personne').delete().eq('idpersonne', id);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Prestataire supprimé avec succès')),
      );
      fetchPrestataires();
    } catch (e) {
      print("Erreur lors de la suppression : $e");
    }
  }

  void modifierPrestataire(Map<String, dynamic> prestataire) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ModifierPrestatairePage(prestataire: prestataire),
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
        title: Text('Gestion des Prestataires'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AjouterPrestatairePage()),
              );
              fetchPrestataires();
            },
          )
        ],
      ),
      body: prestataires.isEmpty
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher par nom, prénom ou entreprise',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredPrestataires.length,
              itemBuilder: (context, index) {
                final p = filteredPrestataires[index];
                final infos = p['prestataire'];

                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(child: Text(p['prenom'][0])),
                    title: Text('${p['prenom']} ${p['nom']}'),
                    subtitle: Text('Service: ${infos['typeservice']} • Entreprise: ${infos['entreprise']}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.orange),
                          onPressed: () {
                            final prestataireComplet = {
                              ...p,
                              'entreprise': p['prestataire']?['entreprise'] ?? '',
                              'typeservice': p['prestataire']?['typeservice'] ?? '',
                            };
                            modifierPrestataire(prestataireComplet);
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => supprimerPrestataire(p['idpersonne']),
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
