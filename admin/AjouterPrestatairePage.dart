import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../GlovalColors.dart';
import '../favoris.dart';

class AjouterPrestatairePage extends StatefulWidget {
  const AjouterPrestatairePage({super.key});

  @override
  State<AjouterPrestatairePage> createState() => _AjouterPrestatairePageState();
}

class _AjouterPrestatairePageState extends State<AjouterPrestatairePage> {
  final supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  final typeServiceController = TextEditingController();
  final entrepriseController = TextEditingController();
  bool isLoading = false;
  dynamic selectedVoyageur;
  List<dynamic> voyageurs = [];

  @override
  void initState() {
    super.initState();
    fetchVoyageurs();
  }

  Future<void> fetchVoyageurs() async {
    final response = await supabase
        .from('personne')
        .select('user_id, nom, prenom, email')
        .eq('role', 'Voyageur');

    setState(() {
      voyageurs = response;
    });
  }

  Future<void> ajouterPrestataire() async {
    if (!_formKey.currentState!.validate() || selectedVoyageur == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Veuillez sélectionner un voyageur'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      // Vérification que user_id existe
      if (selectedVoyageur['user_id'] == null) {
        throw Exception('ID utilisateur (user_id) non trouvé');
      }

      await supabase.from('personne').update({'role': 'Prestataire'})
          .eq('user_id', selectedVoyageur['user_id']);

      await supabase.from('prestataire').insert({
        'user_id': selectedVoyageur['user_id'],
        'typeservice': typeServiceController.text,
        'entreprise': entrepriseController.text,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Prestataire ajouté avec succès'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'ajout: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = GlobalColors.secondaryColor;
    final cardColor = GlobalColors.isDarkMode
        ? Colors.grey[800]!.withOpacity(0.5)
        : Colors.white;
    final borderColor = GlobalColors.isDarkMode
        ? Colors.grey[600]!
        : Colors.grey[300]!;

    return Scaffold(
      backgroundColor: GlobalColors.primaryColor,
      appBar: AppBar(
        title: Text(
          'Ajouter un Prestataire',
          style: GoogleFonts.robotoSlab(color: Colors.white),
        ),
        backgroundColor: GlobalColors.isDarkMode
            ? GlobalColors.bleuTurquoise
            : GlobalColors.bleuTurquoise,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Dropdown pour sélectionner le voyageur
              Card(
                color: cardColor,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: borderColor),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownSearch<dynamic>(
                    items: voyageurs,
                    itemAsString: (voyageur) =>
                    "${voyageur['nom']} ${voyageur['prenom']} - ${voyageur['email']}",
                    onChanged: (value) => setState(() => selectedVoyageur = value),
                    selectedItem: selectedVoyageur,
                    dropdownDecoratorProps: DropDownDecoratorProps(
                      dropdownSearchDecoration: InputDecoration(
                        labelText: "Sélectionner un voyageur",
                        labelStyle: TextStyle(color: GlobalColors.secondaryColor),
                        border: InputBorder.none,
                      ),
                    ),
                    popupProps: PopupProps.modalBottomSheet(
                      showSearchBox: true,
                      searchFieldProps: TextFieldProps(
                        decoration: InputDecoration(
                          hintText: 'Rechercher...',
                          prefixIcon: Icon(Icons.search, color: textColor),
                        ),
                      ),
                      containerBuilder: (context, popupWidget) => Container(
                        decoration: BoxDecoration(
                          color: GlobalColors.isDarkMode
                              ? Colors.grey[900]
                              : Colors.white,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        child: Column(
                          children: [
                            AppBar(
                              title: Text('Sélectionner un voyageur',
                                  style: TextStyle(color: textColor)),
                              backgroundColor: GlobalColors.isDarkMode
                                  ? Colors.grey[800]
                                  : Colors.blue,
                              automaticallyImplyLeading: false,
                              actions: [
                                IconButton(
                                  icon: Icon(Icons.close, color: Colors.white),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ],
                            ),
                            Expanded(child: popupWidget),
                          ],
                        ),
                      ),
                    ),
                    dropdownBuilder: (context, selectedItem) => Text(
                      selectedItem != null
                          ? "${selectedItem['nom']} ${selectedItem['prenom']}"
                          : "Sélectionner un voyageur",
                      style: TextStyle(color: textColor),
                    ),
                    validator: (value) =>
                    value == null ? 'Veuillez sélectionner un voyageur' : null,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Champ Type de service
              TextFormField(
                controller: typeServiceController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: 'Type de service',
                  labelStyle: TextStyle(color: textColor),
                  filled: true,
                  fillColor: cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: borderColor),
                  ),
                ),
                validator: (value) => value!.isEmpty ? 'Champ requis' : null,
              ),

              const SizedBox(height: 16),

              // Champ Entreprise
              TextFormField(
                controller: entrepriseController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: 'Entreprise',
                  labelStyle: TextStyle(color: textColor),
                  filled: true,
                  fillColor: cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: borderColor),
                  ),
                ),
                validator: (value) => value!.isEmpty ? 'Champ requis' : null,
              ),

              const SizedBox(height: 30),

              // Bouton d'ajout
              ElevatedButton(
                onPressed: isLoading ? null : ajouterPrestataire,
                style: ElevatedButton.styleFrom(
                  backgroundColor: GlobalColors.isDarkMode
                      ? GlobalColors.bleuTurquoise
                      : Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                  'Ajouter le prestataire',
                  style: GoogleFonts.robotoSlab(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}