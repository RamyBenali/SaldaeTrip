import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../favoris.dart';
import 'modifier-voyageur.dart';

class GestionVoyageurPage extends StatefulWidget {
  const GestionVoyageurPage({super.key});

  @override
  State<GestionVoyageurPage> createState() => _GestionVoyageurPageState();
}

class _GestionVoyageurPageState extends State<GestionVoyageurPage> {
  List<Map<String, dynamic>> voyageurs = [];
  List<Map<String, dynamic>> voyageursFiltres = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchVoyageurs();
  }

  Future<void> fetchVoyageurs() async {
    try {
      final response = await supabase
          .from('personne')
          .select()
          .or("role.eq.Voyageur");

      setState(() {
        voyageurs = List<Map<String, dynamic>>.from(response);
        voyageursFiltres = voyageurs;
      });
    } catch (e) {
      print("Erreur lors de la récupération des voyageurs : $e");
    }
  }

  void rechercherVoyageurs(String query) {
    final results = voyageurs.where((v) {
      final fullName = "${v['prenom']} ${v['nom']} ${v['email']}".toLowerCase();
      return fullName.contains(query.toLowerCase());
    }).toList();

    setState(() {
      voyageursFiltres = results;
    });
  }

  void supprimerVoyageur(String id) async {
    try {
      // Supprimer d'abord dans la table "voyageur"
      await supabase.from('voyageur').delete().eq('user_id', id);

      // Ensuite, supprimer dans la table "personne"
      await supabase.from('personne').delete().eq('user_id', id);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Voyageur supprimé avec succès')),
      );
      fetchVoyageurs();
    } catch (e) {
      print("Erreur lors de la suppression : $e");
    }
  }

  void modifierVoyageur(Map<String, dynamic> voyageur) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ModifierVoyageurPage(voyageur: voyageur),
      ),
    );

    if (result == true) {
      fetchVoyageurs(); // Rafraîchir la liste après modif
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Voyageurs'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'Rechercher par nom ou prénom',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: rechercherVoyageurs,
            ),
          ),
          Expanded(
            child: voyageursFiltres.isEmpty
                ? Center(child: Text('Aucun voyageur trouvé.'))
                : ListView.builder(
              itemCount: voyageursFiltres.length,
              itemBuilder: (context, index) {
                final voyageur = voyageursFiltres[index];
                return Card(
                  margin:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                        child: Text(voyageur['prenom'][0].toUpperCase())),
                    title: Text('${voyageur['prenom']} ${voyageur['nom']}'),
                    subtitle: Text(voyageur['email']),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () =>
                              supprimerVoyageur(voyageur['user_id']),
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
