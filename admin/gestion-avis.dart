import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../GlovalColors.dart';

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
  int? selectedAvisId;

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
          .select('user_id, nom, prenom')
          .eq('user_id', avis['user_id'])
          .maybeSingle();

      final reponses = await Supabase.instance.client
          .from('reponses_avis')
          .select()
          .eq('id_avis', avis['idavis'])
          .order('date', ascending: true);

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
      avis['isExpanded'] = false;
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
        title: Text('Confirmer la suppression', style: TextStyle(color: GlobalColors.secondaryColor)),
        content: Text('Voulez-vous vraiment supprimer cet avis ?', style: TextStyle(color: GlobalColors.secondaryColor)),
        backgroundColor: GlobalColors.isDarkMode ? Colors.grey[800] : Colors.white,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Annuler', style: TextStyle(color: GlobalColors.isDarkMode ? Colors.blue[200] : Colors.blue)),
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
          .eq('id_avis', idavis);

      await Supabase.instance.client
          .from('avis')
          .delete()
          .eq('idavis', idavis);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Avis et réponses supprimés'),
          backgroundColor: GlobalColors.isDarkMode ? Colors.green[800] : Colors.green,
        ),
      );

      await chargerAvis();
    }
  }

  Future<void> supprimerReponse(int idReponse) async {
    final confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Confirmer la suppression', style: TextStyle(color: GlobalColors.secondaryColor)),
        content: Text('Voulez-vous vraiment supprimer cette réponse ?', style: TextStyle(color: GlobalColors.secondaryColor)),
        backgroundColor: GlobalColors.isDarkMode ? Colors.grey[800] : Colors.white,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Annuler', style: TextStyle(color: GlobalColors.isDarkMode ? Colors.blue[200] : Colors.blue)),
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
        SnackBar(
          content: Text('Réponse supprimée'),
          backgroundColor: GlobalColors.isDarkMode ? Colors.green[800] : Colors.green,
        ),
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
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: GlobalColors.isDarkMode ? Colors.red[800] : Colors.red,
        ),
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
    final cardColor = GlobalColors.isDarkMode ? Colors.grey[800]!.withOpacity(0.5) : Colors.white;
    final borderColor = GlobalColors.isDarkMode ? Colors.grey[600]! : Colors.grey[300]!;
    final textColor = GlobalColors.secondaryColor;
    final secondaryTextColor = GlobalColors.isDarkMode ? Colors.white70 : Colors.black54;

    return Scaffold(
      backgroundColor: GlobalColors.primaryColor,
      appBar: AppBar(
        title: Text('Gestion des Avis', style: GoogleFonts.robotoSlab(color: Colors.white)),
        backgroundColor: GlobalColors.bleuTurquoise,
        iconTheme: IconThemeData(color: Colors.white),
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
                hintText: 'Rechercher par nom ou prénom',
                hintStyle: TextStyle(color: secondaryTextColor),
                prefixIcon: Icon(Icons.search, color: secondaryTextColor),
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
            child: filteredAvisList.isEmpty
                ? Center(child: Text('Aucun avis trouvé', style: TextStyle(color: textColor)))
                : ListView.builder(
              itemCount: filteredAvisList.length,
              itemBuilder: (context, index) {
                final avis = filteredAvisList[index];
                final utilisateur = avis['voyageur'];
                final reponses = avis['reponses'] as List<dynamic>;
                final isExpanded = avis['isExpanded'] as bool;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: borderColor),
                  ),
                  elevation: 2,
                  child: Column(
                    children: [
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: GlobalColors.isDarkMode ? Colors.blueGrey : Colors.blue[100],
                          child: Text('${avis['note']}', style: TextStyle(color: Colors.white)),
                        ),
                        title: Text(
                          utilisateur != null ? '${utilisateur['prenom']} ${utilisateur['nom']}' : 'Voyageur inconnu',
                          style: TextStyle(color: textColor),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (avis['commentaire'] != null)
                              Text(avis['commentaire'], style: TextStyle(color: secondaryTextColor)),
                            if (avis['image'] != null && avis['image'] != '')
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
                                isExpanded ? Icons.expand_less : Icons.expand_more,
                                color: textColor,
                              ),
                              onPressed: () {
                                setState(() {
                                  avis['isExpanded'] = !isExpanded;
                                });
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => supprimerAvis(avis['idavis']),
                            ),
                          ],
                        ),
                      ),
                      if (isExpanded) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Divider(color: borderColor),
                              Text('Réponses:',
                                  style: GoogleFonts.robotoSlab(
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  )),
                              if (reponses.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text('Aucune réponse pour cet avis', style: TextStyle(color: secondaryTextColor)),
                                )
                              else
                                ...reponses.map((reponse) {
                                  final auteur = reponse['auteur'];
                                  return ListTile(
                                    leading: Icon(Icons.reply, color: textColor),
                                    title: Text(
                                      auteur != null ? '${auteur['prenom']} ${auteur['nom']}' : 'Auteur inconnu',
                                      style: TextStyle(color: textColor),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(reponse['reponse'], style: TextStyle(color: secondaryTextColor)),
                                        Text(
                                          DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(reponse['date'])),
                                          style: GoogleFonts.robotoSlab(
                                            fontSize: 12,
                                            color: secondaryTextColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                    trailing: IconButton(
                                      icon: Icon(Icons.delete, color: Colors.red, size: 20),
                                      onPressed: () => supprimerReponse(reponse['id']),
                                    ),
                                  );
                                }).toList(),
                              const SizedBox(height: 8),
                              TextField(
                                controller: reponseController,
                                style: TextStyle(color: textColor),
                                decoration: InputDecoration(
                                  hintText: 'Ajouter une réponse...',
                                  hintStyle: TextStyle(color: secondaryTextColor),
                                  filled: true,
                                  fillColor: GlobalColors.isDarkMode ? Colors.grey[700] : Colors.grey[100],
                                  suffixIcon: IconButton(
                                    icon: Icon(Icons.send, color: textColor),
                                    onPressed: () => ajouterReponse(avis['idavis']),
                                  ),
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide(color: borderColor),
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