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
        SnackBar(
          content: Text('Veuillez remplir tous les champs'),
          backgroundColor: GlobalColors.isDarkMode ? Colors.red[800] : Colors.red,
        ),
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
        SnackBar(
          content: Text('Recommandation ajoutée avec succès'),
          backgroundColor: GlobalColors.isDarkMode ? Colors.green[800] : Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'ajout: $e'),
          backgroundColor: GlobalColors.isDarkMode ? Colors.red[800] : Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteRecommandation(int id) async {
    try {
      await supabase.from('offre_recommandations').delete().eq('id', id);
      await _fetchRecommandations();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Recommandation supprimée avec succès'),
          backgroundColor: GlobalColors.isDarkMode ? Colors.green[800] : Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la suppression: $e'),
          backgroundColor: GlobalColors.isDarkMode ? Colors.red[800] : Colors.red,
        ),
      );
    }
  }

  Future<void> _selectDate(BuildContext context, bool isDebut) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: GlobalColors.isDarkMode ? Colors.blueGrey : Colors.blue,
              onPrimary: Colors.white,
              onSurface: GlobalColors.isDarkMode ? Colors.white : Colors.black,
            ),
            dialogBackgroundColor: GlobalColors.isDarkMode ? Colors.grey[800] : Colors.white,
          ),
          child: child!,
        );
      },
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
            final cardColor = GlobalColors.isDarkMode ? Colors.grey[800] : Colors.white;
            final textColor = GlobalColors.secondaryColor;
            final borderColor = GlobalColors.isDarkMode ? Colors.grey[600]! : Colors.grey[300]!;

            return AlertDialog(
              backgroundColor: GlobalColors.isDarkMode ? Colors.grey[900] : Colors.white,
              title: Text(
                'Ajouter une recommandation',
                style: TextStyle(color: textColor),
              ),
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
                          dropdownColor: GlobalColors.isDarkMode ? Colors.grey[800] : Colors.white,
                          decoration: InputDecoration(
                            labelText: 'Offre',
                            labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(color: borderColor),
                            ),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                            filled: true,
                            fillColor: cardColor,
                          ),
                          isExpanded: true,
                          style: TextStyle(color: textColor),
                          items: offres.map((offre) {
                            return DropdownMenuItem<String>(
                              value: offre['idoffre'].toString(),
                              child: Text(
                                offre['nom'],
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.robotoSlab(
                                  fontSize: 14,
                                  color: textColor,
                                ),
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
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        labelText: 'Priorité (1-5)',
                        labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: borderColor),
                        ),
                        filled: true,
                        fillColor: cardColor,
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 16),
                    ListTile(
                      title: Text(
                        selectedDateDebut == null
                            ? 'Sélectionner date début'
                            : 'Date début: ${DateFormat('dd/MM/yyyy').format(selectedDateDebut!)}',
                        style: TextStyle(color: textColor),
                      ),
                      trailing: Icon(Icons.calendar_today, color: textColor),
                      onTap: () => _selectDate(context, true),
                    ),
                    ListTile(
                      title: Text(
                        selectedDateFin == null
                            ? 'Sélectionner date fin'
                            : 'Date fin: ${DateFormat('dd/MM/yyyy').format(selectedDateFin!)}',
                        style: TextStyle(color: textColor),
                      ),
                      trailing: Icon(Icons.calendar_today, color: textColor),
                      onTap: () => _selectDate(context, false),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Annuler',
                    style: TextStyle(
                      color: GlobalColors.isDarkMode ? Colors.blue[200] : Colors.blue,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GlobalColors.isDarkMode ? Colors.blueGrey : Colors.blue,
                  ),
                  onPressed: () async {
                    await _addRecommandation();
                    Navigator.pop(context);
                  },
                  child: Text('Ajouter', style: TextStyle(color: Colors.white)),
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
    final cardColor = GlobalColors.isDarkMode ? Colors.grey[800]!.withOpacity(0.5) : Colors.white;
    final borderColor = GlobalColors.isDarkMode ? Colors.grey[600]! : Colors.grey[300]!;
    final textColor = GlobalColors.secondaryColor;
    final secondaryTextColor = GlobalColors.isDarkMode ? Colors.white70 : Colors.black54;

    return Scaffold(
      backgroundColor: GlobalColors.primaryColor,
      appBar: AppBar(
        title: Text(
          'Gestion des recommandations',
          style: GoogleFonts.robotoSlab(color: Colors.white),
        ),
        backgroundColor: GlobalColors.bleuTurquoise,
        iconTheme: IconThemeData(color: Colors.white),
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
          ? Center(
        child: Text(
          'Aucune recommandation trouvée',
          style: TextStyle(color: textColor),
        ),
      )
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
            color: cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: borderColor),
            ),
            child: ListTile(
              title: Text(
                offreNom,
                style: GoogleFonts.robotoSlab(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Priorité: ${reco['priorite']}',
                    style: TextStyle(color: secondaryTextColor),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Début: $dateDebut',
                    style: TextStyle(color: secondaryTextColor),
                  ),
                  Text(
                    'Fin: $dateFin',
                    style: TextStyle(color: secondaryTextColor),
                  ),
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