import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../GlovalColors.dart';

class GestionRecommandationsPage extends StatefulWidget {
  @override
  _GestionRecommandationsPageState createState() => _GestionRecommandationsPageState();
}

class _GestionRecommandationsPageState extends State<GestionRecommandationsPage> {
  final supabase = Supabase.instance.client;
  final primaryBackColor = GlobalColors.primaryColor;
  final cardColor = GlobalColors.cardColor;
  final textColor = GlobalColors.secondaryColor;

  List<Map<String, dynamic>> recommandations = [];
  bool isLoading = true;
  String? selectedOffreId;
  int? selectedPriorite;
  DateTime? selectedDateDebut;
  DateTime? selectedDateFin;
  TextEditingController prioriteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchRecommandations();
  }

  Future<void> _fetchRecommandations() async {
    setState(() => isLoading = true);
    try {
      final response = await supabase
          .from('offre_recommandations')
          .select('*, offre(nom)')
          .order('priorite', ascending: false);

      setState(() {
        recommandations = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      print("Erreur lors de la récupération des recommandations: $e");
      setState(() => isLoading = false);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchOffres() async {
    try {
      final response = await supabase
          .from('offre')
          .select('idoffre, nom')
          .order('nom', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print("Erreur lors de la récupération des offres: $e");
      return [];
    }
  }

  Future<void> _addRecommandation() async {
    if (selectedOffreId == null ||
        prioriteController.text.isEmpty ||
        selectedDateDebut == null ||
        selectedDateFin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veuillez remplir tous les champs')),
      );
      return;
    }

    try {
      await supabase.from('offre_recommandations').insert({
        'idoffre': selectedOffreId,
        'priorite': int.parse(prioriteController.text),
        'date_debut': selectedDateDebut!.toIso8601String(),
        'date_fin': selectedDateFin!.toIso8601String(),
      });

      // Reset form
      setState(() {
        selectedOffreId = null;
        selectedPriorite = null;
        selectedDateDebut = null;
        selectedDateFin = null;
        prioriteController.clear();
      });

      // Refresh list
      await _fetchRecommandations();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Recommandation ajoutée avec succès')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'ajout: $e')),
      );
    }
  }

  Future<void> _deleteRecommandation(int id) async {
    try {
      await supabase.from('offre_recommandations').delete().eq('id', id);
      await _fetchRecommandations();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Recommandation supprimée avec succès')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la suppression: $e')),
      );
    }
  }

  Future<void> _selectDate(BuildContext context, bool isDebut) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isDebut) {
          selectedDateDebut = picked;
        } else {
          selectedDateFin = picked;
        }
      });
    }
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Ajouter une recommandation'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: _fetchOffres(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return CircularProgressIndicator();
                        }
                        final offres = snapshot.data ?? [];
                        return DropdownButtonFormField<String>(
                          value: selectedOffreId,
                          decoration: InputDecoration(
                            labelText: 'Offre',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          ),
                          isExpanded: true, // Cette ligne est cruciale
                          items: offres.map((offre) {
                            return DropdownMenuItem<String>(
                              value: offre['idoffre'].toString(),
                              child: Text(
                                offre['nom'],
                                overflow: TextOverflow.ellipsis, // Gère le texte trop long
                                style: GoogleFonts.robotoSlab(fontSize: 14),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) => setState(() => selectedOffreId = value),
                        );
                      },
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: prioriteController,
                      decoration: InputDecoration(
                        labelText: 'Priorité (1-5)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 16),
                    ListTile(
                      title: Text(
                        selectedDateDebut == null
                            ? 'Sélectionner date début'
                            : 'Date début: ${DateFormat('dd/MM/yyyy').format(selectedDateDebut!)}',
                      ),
                      trailing: Icon(Icons.calendar_today),
                      onTap: () => _selectDate(context, true),
                    ),
                    ListTile(
                      title: Text(
                        selectedDateFin == null
                            ? 'Sélectionner date fin'
                            : 'Date fin: ${DateFormat('dd/MM/yyyy').format(selectedDateFin!)}',
                      ),
                      trailing: Icon(Icons.calendar_today),
                      onTap: () => _selectDate(context, false),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await _addRecommandation();
                    Navigator.pop(context);
                  },
                  child: Text('Ajouter'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryBackColor,
      appBar: AppBar(
        title: Text('Gestion des recommandations', style: GoogleFonts.robotoSlab(color: Colors.white)),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: Colors.white),
            onPressed: _showAddDialog,
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : recommandations.isEmpty
          ? Center(child: Text('Aucune recommandation trouvée'))
          : ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: recommandations.length,
        itemBuilder: (context, index) {
          final reco = recommandations[index];
          final offreNom = reco['offre']?['nom'] ?? 'Offre inconnue';
          final dateDebut = reco['date_debut'] != null
              ? DateFormat('dd/MM/yyyy').format(DateTime.parse(reco['date_debut']))
              : 'Non définie';
          final dateFin = reco['date_fin'] != null
              ? DateFormat('dd/MM/yyyy').format(DateTime.parse(reco['date_fin']))
              : 'Non définie';

          return Card(
            elevation: 2,
            margin: EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(offreNom, style: GoogleFonts.robotoSlab(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Priorité: ${reco['priorite']}'),
                  SizedBox(height: 4),
                  Text('Début: $dateDebut'),
                  Text('Fin: $dateFin'),
                ],
              ),
              trailing: IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteRecommandation(reco['id']),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    prioriteController.dispose();
    super.dispose();
  }
}