import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminAvisPage extends StatefulWidget {
  const AdminAvisPage({Key? key}) : super(key: key);

  @override
  State<AdminAvisPage> createState() => _AdminAvisPageState();
}

class _AdminAvisPageState extends State<AdminAvisPage> {
  List<dynamic> avisList = [];
  List<dynamic> filteredAvisList = [];
  bool isLoading = true;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    chargerAvis();
    searchController.addListener(_filterAvis);
  }

  Future<void> chargerAvis() async {
    setState(() => isLoading = true);

    final data = await Supabase.instance.client
        .from('avis')
        .select()
        .order('idavis', ascending: false);

    for (var avis in data) {
      final voyageur = await Supabase.instance.client
          .from('personne')
          .select('idpersonne, nom, prenom')
          .eq('idpersonne', avis['idvoyageur'])
          .maybeSingle();

      avis['voyageur'] = voyageur;
    }

    setState(() {
      avisList = data;
      filteredAvisList = data; // Initial copy
      isLoading = false;
    });
  }

  void _filterAvis() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredAvisList = avisList.where((avis) {
        final utilisateur = avis['voyageur'];
        if (utilisateur == null) return false;
        final fullName =
        '${utilisateur['prenom']} ${utilisateur['nom']}'.toLowerCase();
        return fullName.contains(query);
      }).toList();
    });
  }

  Future<void> supprimerAvis(int idavis) async {
    final confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer cet avis ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await Supabase.instance.client
          .from('avis')
          .delete()
          .eq('idavis', idavis);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Avis supprimé')),
      );

      await chargerAvis(); // Refresh après suppression
    }
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
        title: Text('Gestion des Avis'),
        backgroundColor: Colors.blue,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher par nom ou prénom',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child: filteredAvisList.isEmpty
                ? Center(child: Text('Aucun avis trouvé'))
                : ListView.builder(
              itemCount: filteredAvisList.length,
              itemBuilder: (context, index) {
                final avis = filteredAvisList[index];
                final utilisateur = avis['voyageur'];
                return Card(
                  margin: EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue[100],
                      child: Text('${avis['note']}'),
                    ),
                    title: Text(utilisateur != null
                        ? '${utilisateur['prenom']} ${utilisateur['nom']}'
                        : 'Voyageur inconnu'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (avis['commentaire'] != null)
                          Text(avis['commentaire']),
                        if (avis['image'] != null &&
                            avis['image'] != '')
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Image.network(
                              avis['image'],
                              height: 100,
                              width: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () =>
                          supprimerAvis(avis['idavis']),
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
