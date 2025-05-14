import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../GlovalColors.dart';

class AjouterOffrePage extends StatefulWidget {
  const AjouterOffrePage({super.key});

  @override
  State<AjouterOffrePage> createState() => _AjouterOffrePageState();
}

class Prestataire {
  final String id;
  final String nom;

  Prestataire({required this.id, required this.nom});

  factory Prestataire.fromJson(Map<String, dynamic> json) {
    return Prestataire(
      id: json['user_id'],
      nom: json['entreprise'],
    );
  }
}

class _AjouterOffrePageState extends State<AjouterOffrePage> {
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
  bool isLoadingPrestataires = true;
  List<Prestataire> prestataires = [];
  Prestataire? selectedPrestataire;

  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile;

  final List<String> categories = [
    'Restaurant',
    'Hôtel',
    'Loisirs',
    'Point dintérêt',
    'Point dintérêt historique',
    'Point dintérêt religieux',
    'randonnée',
    'sortie'
  ];

  @override
  void initState() {
    super.initState();
    fetchPrestataires();
  }

  Future<void> fetchPrestataires() async {
    try {
      final response = await Supabase.instance.client
          .from('prestataire')
          .select('user_id, entreprise');

      final List<dynamic> data = response;
      setState(() {
        prestataires = data
            .map((prestataire) => Prestataire.fromJson(prestataire))
            .cast<Prestataire>()
            .toList();
        isLoadingPrestataires = false;
      });
    } catch (e) {
      print('Erreur : $e');
      setState(() => isLoadingPrestataires = false);
    }
  }

  Future<void> pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile;
        imageController.text = _imageFile!.path;
      });
    }
  }

  Future<void> ajouterOffre() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final prestataireId = idPrestataireController.text;
      if (prestataireId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ID du prestataire invalide'),
            backgroundColor: GlobalColors.isDarkMode ? Colors.red[800] : Colors.red,
          ),
        );
        setState(() => isLoading = false);
        return;
      }

      String? imageUrl = await uploadImageToStorage(_imageFile);

      final insertResult = await Supabase.instance.client.from('offre').insert({
        'nom': nomController.text,
        'description': descriptionController.text,
        'image': imageUrl,
        'categorie': selectedCategorie,
        'user_id': prestataireId,
        'tarifs': tarifsController.text,
        'adresse': adresseController.text,
        'offre_insta': instaController.text,
        'offre_fb': fbController.text,
      }).select().single();

      final idOffre = insertResult['idoffre'];

      if (selectedCategorie == 'Restaurant') {
        await Supabase.instance.client.from('restaurant').insert({
          'idoffre': idOffre,
          'type': typeController.text,
        });
      } else if (selectedCategorie == 'Hôtel') {
        await Supabase.instance.client.from('hotel').insert({
          'idoffre': idOffre,
          'service': serviceController.text,
          'etoile': int.tryParse(etoilesController.text) ?? 0,
        });
      } else {
        await Supabase.instance.client.from('activité').insert({
          'idoffre': idOffre,
          'type': typeController.text,
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Offre ajoutée avec succès'),
          backgroundColor: GlobalColors.isDarkMode ? Colors.green[800] : Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      print('Erreur : $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'ajout de l\'offre: $e'),
          backgroundColor: GlobalColors.isDarkMode ? Colors.red[800] : Colors.red,
        ),
      );
    }

    setState(() => isLoading = false);
  }

  Future<String?> uploadImageToStorage(XFile? imageFile) async {
    if (imageFile == null) return null;

    try {
      final filePath = 'offres/${DateTime.now().millisecondsSinceEpoch}.png';
      await Supabase.instance.client.storage.from('offre-image').upload(filePath, File(imageFile.path));
      return Supabase.instance.client.storage.from('offre-image').getPublicUrl(filePath);
    } catch (e) {
      print('Erreur lors de l\'upload : $e');
      return null;
    }
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
          'Ajouter une Offre',
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
                enabled: false,
              ),
              SizedBox(height: 8),
              GestureDetector(
                onTap: pickImage,
                child: Container(
                  color: buttonColor,
                  padding: EdgeInsets.symmetric(vertical: 15),
                  child: Text(
                    _imageFile == null ? 'Choisir une image' : 'Image sélectionnée',
                    style: GoogleFonts.robotoSlab(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
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
              DropdownButtonFormField<Prestataire>(
                decoration: InputDecoration(
                  labelText: 'Prestataire',
                  labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                ),
                dropdownColor: GlobalColors.isDarkMode ? Colors.grey[800] : Colors.white,
                style: TextStyle(color: textColor),
                value: selectedPrestataire,
                items: prestataires.map((prestataire) {
                  return DropdownMenuItem(
                    value: prestataire,
                    child: Text(
                      prestataire.nom,
                      style: TextStyle(color: textColor),
                    ),
                  );
                }).toList(),
                onChanged: (Prestataire? value) {
                  setState(() {
                    selectedPrestataire = value;
                    idPrestataireController.text = value?.id ?? '';
                  });
                },
                validator: (value) => value == null ? 'Choisir un prestataire' : null,
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
                onPressed: isLoading ? null : ajouterOffre,
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                child: isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Ajouter', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}