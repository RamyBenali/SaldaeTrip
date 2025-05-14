import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../GlovalColors.dart';

class ModifierOffrePage extends StatefulWidget {
  final Map<String, dynamic> offre;
  const ModifierOffrePage({super.key, required this.offre});

  @override
  State<ModifierOffrePage> createState() => _ModifierOffrePageState();
}

class _ModifierOffrePageState extends State<ModifierOffrePage> {
  final _formKey = GlobalKey<FormState>();
  final nomController = TextEditingController();
  final descriptionController = TextEditingController();
  final imageController = TextEditingController();
  final adresseController = TextEditingController();
  final tarifsController = TextEditingController();
  final idPrestataireController = TextEditingController();
  final instaController = TextEditingController();
  final fbController = TextEditingController();

  final typeController = TextEditingController();
  final serviceController = TextEditingController();
  final etoilesController = TextEditingController();

  String? selectedCategorie;
  bool isLoading = false;

  final List<String> categories = [
    'Restaurant',
    'Hôtel',
    'Loisirs',
    'Point dintérêt',
    'Point dintérêt historique',
    'Point dintérêt religieux'
  ];

  @override
  void initState() {
    super.initState();

    nomController.text = widget.offre['nom'] ?? '';
    descriptionController.text = widget.offre['description'] ?? '';
    imageController.text = widget.offre['image'] ?? '';
    adresseController.text = widget.offre['adresse'] ?? '';
    tarifsController.text = widget.offre['tarifs'] ?? '';
    idPrestataireController.text = widget.offre['user_id']?.toString() ?? '';
    instaController.text = widget.offre['offre_insta'] ?? '';
    fbController.text = widget.offre['offre_fb'] ?? '';
    selectedCategorie = widget.offre['categorie'];

    if (selectedCategorie == 'Restaurant') {
      final restaurantData = widget.offre['restaurant'];
      if (restaurantData != null) {
        typeController.text = restaurantData['type'] ?? '';
      }
    } else if (selectedCategorie == 'Hôtel') {
      final hotelData = widget.offre['hotel'];
      if (hotelData != null) {
        serviceController.text = hotelData['service'] ?? '';
        etoilesController.text = hotelData['etoile']?.toString() ?? '';
      }
    } else {
      final activiteData = widget.offre['activité'];
      if (activiteData != null) {
        typeController.text = activiteData['type'] ?? '';
      }
    }
  }

  Future<void> modifierOffre() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final updateResult = await Supabase.instance.client.from('offre').update({
        'nom': nomController.text,
        'description': descriptionController.text,
        'image': imageController.text,
        'categorie': selectedCategorie,
        'user_id': idPrestataireController.text,
        'tarifs': tarifsController.text,
        'adresse': adresseController.text,
        'offre_insta': instaController.text,
        'offre_fb': fbController.text,
      }).eq('idoffre', widget.offre['idoffre']).select().single();

      final idOffre = updateResult['idoffre'];

      if (selectedCategorie == 'Restaurant') {
        await Supabase.instance.client.from('restaurant').upsert({
          'idoffre': idOffre,
          'type': typeController.text,
        });
      } else if (selectedCategorie == 'Hôtel') {
        await Supabase.instance.client.from('hotel').upsert({
          'idoffre': idOffre,
          'service': serviceController.text,
          'etoile': int.tryParse(etoilesController.text) ?? 0,
        });
      } else {
        await Supabase.instance.client.from('activité').upsert({
          'idoffre': idOffre,
          'type': typeController.text,
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Offre modifiée avec succès'),
          backgroundColor: GlobalColors.isDarkMode ? Colors.green[800] : Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      print('Erreur : $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la modification de l\'offre: $e'),
          backgroundColor: GlobalColors.isDarkMode ? Colors.red[800] : Colors.red,
        ),
      );
    }

    setState(() => isLoading = false);
  }

  Widget buildCategorieSpecificFields() {
    final textColor = GlobalColors.secondaryColor;

    if (selectedCategorie == 'Restaurant') {
      return TextFormField(
        controller: typeController,
        decoration: InputDecoration(
          labelText: 'Type du restaurant',
          labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
        ),
        style: TextStyle(color: textColor),
        validator: (value) => value!.isEmpty ? 'Champ requis' : null,
      );
    } else if (selectedCategorie == 'Hôtel') {
      return Column(
        children: [
          TextFormField(
            controller: serviceController,
            decoration: InputDecoration(
              labelText: 'Service de l\'hôtel',
              labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
            ),
            style: TextStyle(color: textColor),
            validator: (value) => value!.isEmpty ? 'Champ requis' : null,
          ),
          TextFormField(
            controller: etoilesController,
            decoration: InputDecoration(
              labelText: 'Nombre d\'étoiles',
              labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
            ),
            style: TextStyle(color: textColor),
            keyboardType: TextInputType.number,
            validator: (value) => value!.isEmpty ? 'Champ requis' : null,
          ),
        ],
      );
    } else if (selectedCategorie != null) {
      return TextFormField(
        controller: typeController,
        decoration: InputDecoration(
          labelText: 'Type d\'activité',
          labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
        ),
        style: TextStyle(color: textColor),
        validator: (value) => value!.isEmpty ? 'Champ requis' : null,
      );
    }
    return SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = GlobalColors.isDarkMode ? Colors.grey[800]!.withOpacity(0.5) : Colors.white;
    final borderColor = GlobalColors.isDarkMode ? Colors.grey[600]! : Colors.grey[300]!;
    final textColor = GlobalColors.secondaryColor;
    final buttonColor = GlobalColors.isDarkMode ? Colors.blueGrey : Colors.blue;

    return Scaffold(
      backgroundColor: GlobalColors.primaryColor,
      appBar: AppBar(
        title: Text(
          'Modifier l\'Offre',
          style: GoogleFonts.robotoSlab(color: Colors.white),
        ),
        backgroundColor: GlobalColors.bleuTurquoise,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: nomController,
                decoration: InputDecoration(
                  labelText: 'Nom',
                  labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                ),
                style: TextStyle(color: textColor),
                validator: (value) => value!.isEmpty ? 'Champ requis' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                ),
                style: TextStyle(color: textColor),
                validator: (value) => value!.isEmpty ? 'Champ requis' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: imageController,
                decoration: InputDecoration(
                  labelText: 'Image (URL)',
                  labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                ),
                style: TextStyle(color: textColor),
                validator: (value) => value!.isEmpty ? 'Champ requis' : null,
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Catégorie',
                  labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                ),
                dropdownColor: GlobalColors.isDarkMode ? Colors.grey[800] : Colors.white,
                style: TextStyle(color: textColor),
                value: selectedCategorie,
                items: categories.map((cat) {
                  return DropdownMenuItem(
                    value: cat,
                    child: Text(cat, style: TextStyle(color: textColor)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => selectedCategorie = value);
                },
                validator: (value) => value == null ? 'Choisir une catégorie' : null,
              ),
              SizedBox(height: 16),
              buildCategorieSpecificFields(),
              SizedBox(height: 16),
              TextFormField(
                controller: idPrestataireController,
                decoration: InputDecoration(
                  labelText: 'ID du Prestataire',
                  labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                ),
                style: TextStyle(color: textColor),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Champ requis' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: tarifsController,
                decoration: InputDecoration(
                  labelText: 'Tarifs',
                  labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                ),
                style: TextStyle(color: textColor),
                validator: (value) => value!.isEmpty ? 'Champ requis' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: adresseController,
                decoration: InputDecoration(
                  labelText: 'Adresse',
                  labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                ),
                style: TextStyle(color: textColor),
                validator: (value) => value!.isEmpty ? 'Champ requis' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: instaController,
                decoration: InputDecoration(
                  labelText: 'Lien Instagram',
                  labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                ),
                style: TextStyle(color: textColor),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: fbController,
                decoration: InputDecoration(
                  labelText: 'Lien Facebook',
                  labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                ),
                style: TextStyle(color: textColor),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: isLoading ? null : modifierOffre,
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                child: isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Modifier', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}