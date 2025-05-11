import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
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
  final TextEditingController reponseController = TextEditingController();
  int? selectedAvisId; // Pour gérer les réponses

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
      // Récupération du voyageur
      final voyageur = await Supabase.instance.client
          .from('personne')
          .select('user_id, nom, prenom')
          .eq('user_id', avis['user_id'])
          .maybeSingle();

      // Récupération des réponses pour cet avis
      final reponses = await Supabase.instance.client
          .from('reponses_avis')
          .select()
          .eq('id_avis', avis['idavis'])
          .order('date', ascending: true);

      // Récupération des infos utilisateur pour chaque réponse
      for (var reponse in reponses) {
        final auteurReponse = await Supabase.instance.client
            .from('personne')
            .select('nom, prenom')
            .eq('user_id', reponse['user_id'])
            .maybeSingle();

        reponse['auteur'] = auteurReponse;
      }

      avis['voyageur'] = voyageur;
      avis['reponses'] = reponses;
      avis['isExpanded'] = false; // Pour gérer l'affichage des réponses
    }

    setState(() {
      avisList = data;
      filteredAvisList = data;
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
        title: const Text('Confirmer la suppression'),
        content: const Text('Voulez-vous vraiment supprimer cet avis ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Supprimer', style: GoogleFonts.robotoSlab(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // D'abord supprimer les réponses associées
      await Supabase.instance.client
          .from('reponses_avis')
          .delete()
          .eq('id_avis', idavis);

      // Puis supprimer l'avis
      await Supabase.instance.client
          .from('avis')
          .delete()
          .eq('idavis', idavis);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Avis et réponses supprimés')),
      );

      await chargerAvis();
    }
  }

  Future<void> supprimerReponse(int idReponse) async {
    final confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Voulez-vous vraiment supprimer cette réponse ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Supprimer', style: GoogleFonts.robotoSlab(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await Supabase.instance.client
          .from('reponses_avis')
          .delete()
          .eq('id', idReponse);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Réponse supprimée')),
      );

      await chargerAvis();
    }
  }

  Future<void> ajouterReponse(int avisId) async {
    if (reponseController.text.isEmpty) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      await Supabase.instance.client.from('reponses_avis').insert({
        'id_avis': avisId,
        'user_id': user.id,
        'reponse': reponseController.text,
        'date': DateTime.now().toIso8601String(),
      });

      reponseController.clear();
      await chargerAvis();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    reponseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gestion des Avis', style: GoogleFonts.robotoSlab(color: Colors.white)),
        backgroundColor: Colors.blue,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher par nom ou prénom',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child: filteredAvisList.isEmpty
                ? const Center(child: Text('Aucun avis trouvé'))
                : ListView.builder(
              itemCount: filteredAvisList.length,
              itemBuilder: (context, index) {
                final avis = filteredAvisList[index];
                final utilisateur = avis['voyageur'];
                final reponses = avis['reponses'] as List<dynamic>;
                final isExpanded = avis['isExpanded'] as bool;

                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      ListTile(
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
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                isExpanded
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                              ),
                              onPressed: () {
                                setState(() {
                                  avis['isExpanded'] = !isExpanded;
                                });
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete,
                                  color: Colors.red),
                              onPressed: () =>
                                  supprimerAvis(avis['idavis']),
                            ),
                          ],
                        ),
                      ),
                      if (isExpanded) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16),
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              const Divider(),
                              Text('Réponses:',
                                  style: GoogleFonts.robotoSlab(
                                      fontWeight: FontWeight.bold)),
                              if (reponses.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text(
                                      'Aucune réponse pour cet avis'),
                                )
                              else
                                ...reponses.map((reponse) {
                                  final auteur = reponse['auteur'];
                                  return ListTile(
                                    leading: const Icon(Icons.reply),
                                    title: Text(auteur != null
                                        ? '${auteur['prenom']} ${auteur['nom']}'
                                        : 'Auteur inconnu'),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(reponse['reponse']),
                                        Text(
                                          DateFormat('dd/MM/yyyy HH:mm')
                                              .format(DateTime.parse(
                                              reponse['date'])),
                                          style: GoogleFonts.robotoSlab(
                                              fontSize: 12),
                                        ),
                                      ],
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red,
                                          size: 20),
                                      onPressed: () =>
                                          supprimerReponse(
                                              reponse['id']),
                                    ),
                                  );
                                }).toList(),
                              const SizedBox(height: 8),
                              TextField(
                                controller: reponseController,
                                decoration: InputDecoration(
                                  hintText: 'Ajouter une réponse...',
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.send),
                                    onPressed: () =>
                                        ajouterReponse(avis['idavis']),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ],
                    ],
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