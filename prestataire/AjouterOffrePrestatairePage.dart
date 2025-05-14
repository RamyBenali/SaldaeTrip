import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../GlovalColors.dart';

class AjouterOffrePrestatairePage extends StatefulWidget {
  const AjouterOffrePrestatairePage({super.key});

  @override
  State<AjouterOffrePrestatairePage> createState() => _AjouterOffrePrestatairePageState();
}

class _AjouterOffrePrestatairePageState extends State<AjouterOffrePrestatairePage> {
  final _formKey = GlobalKey<FormState>();
  final nomController = TextEditingController();
  final descriptionController = TextEditingController();
  final imageController = TextEditingController();
  final adresseController = TextEditingController();
  final tarifsController = TextEditingController();
  final instaController = TextEditingController();
  final fbController = TextEditingController();
  final typeController = TextEditingController();
  final serviceController = TextEditingController();
  final etoilesController = TextEditingController();
  final user = Supabase.instance.client.auth.currentUser;
  final latitudeController = TextEditingController();
  final longitudeController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile;

  String? selectedCategorie;
  bool isLoading = false;

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
  }

  Future<void> pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile;
        imageController.text = pickedFile.path;
      });
    }
  }

  Future<String?> uploadImageToStorage(XFile? imageFile) async {
    if (imageFile == null) return null;

    try {
      final filePath = 'offres/${DateTime.now().millisecondsSinceEpoch}.png';
      await Supabase.instance.client.storage
          .from('offre-image')
          .upload(filePath, File(imageFile.path));
      return Supabase.instance.client.storage.from('offre-image').getPublicUrl(filePath);
    } catch (e) {
      print('Erreur lors de l\'upload de l\'image : $e');
      return null;
    }
  }

  Future<void> ajouterOffre() async {
    String? idPrestataire = user?.id;

    if (!_formKey.currentState!.validate()) return;
    if (idPrestataire == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Identifiant du prestataire introuvable'),
          backgroundColor: GlobalColors.isDarkMode ? Colors.red[800] : Colors.red,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final imageUrl = await uploadImageToStorage(_imageFile);

      final insertResult = await Supabase.instance.client.from('offre').insert({
        'nom': nomController.text,
        'description': descriptionController.text,
        'image': imageUrl,
        'categorie': selectedCategorie,
        'user_id': idPrestataire,
        'tarifs': tarifsController.text,
        'adresse': adresseController.text,
        'offre_insta': instaController.text,
        'offre_fb': fbController.text,
        'latitude' : latitudeController.text,
        'longitude' : longitudeController.text,
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
          'services': serviceController.text,
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
          backgroundColor: GlobalColors.bleuTurquoise,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      print('Erreur lors de l\'ajout : $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'ajout de l\'offre: $e'),
          backgroundColor: GlobalColors.isDarkMode ? Colors.red[800] : Colors.red,
        ),
      );
    }

    setState(() => isLoading = false);
  }

  Widget buildCategorieSpecificFields() {
    final cardColor = GlobalColors.isDarkMode ? Colors.grey[800]!.withOpacity(0.5) : Colors.white;
    final borderColor = GlobalColors.isDarkMode ? Colors.grey[600]! : Colors.grey[300]!;
    final textColor = GlobalColors.secondaryColor;
    final secondaryTextColor = GlobalColors.isDarkMode ? Colors.white70 : Colors.black54;

    if (selectedCategorie == 'Restaurant') {
      return TextFormField(
        controller: typeController,
        style: TextStyle(color: textColor),
        decoration: InputDecoration(
          labelText: 'Type du restaurant',
          labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
          filled: true,
          fillColor: cardColor,
          border: OutlineInputBorder(
            borderSide: BorderSide(color: borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: borderColor),
          ),
        ),
        validator: (value) => value!.isEmpty ? 'Champ requis' : null,
      );
    } else if (selectedCategorie == 'Hôtel') {
      return Column(
        children: [
          TextFormField(
            controller: serviceController,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              labelText: 'Service de l\'hôtel',
              labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
              filled: true,
              fillColor: cardColor,
              border: OutlineInputBorder(
                borderSide: BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: borderColor),
              ),
            ),
            validator: (value) => value!.isEmpty ? 'Champ requis' : null,
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: etoilesController,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              labelText: 'Nombre d\'étoiles',
              labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
              filled: true,
              fillColor: cardColor,
              border: OutlineInputBorder(
                borderSide: BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: borderColor),
              ),
            ),
            keyboardType: TextInputType.number,
            validator: (value) => value!.isEmpty ? 'Champ requis' : null,
          ),
        ],
      );
    } else if (selectedCategorie != null) {
      return TextFormField(
        controller: typeController,
        style: TextStyle(color: textColor),
        decoration: InputDecoration(
          labelText: 'Type d\'activité',
          labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
          filled: true,
          fillColor: cardColor,
          border: OutlineInputBorder(
            borderSide: BorderSide(color: borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: borderColor),
          ),
        ),
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
    final secondaryTextColor = GlobalColors.isDarkMode ? Colors.white70 : Colors.black54;
    final buttonColor = GlobalColors.bleuTurquoise;

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
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: 'Nom',
                  labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                  filled: true,
                  fillColor: cardColor,
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: borderColor),
                  ),
                ),
                validator: (value) => value!.isEmpty ? 'Champ requis' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: descriptionController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                  filled: true,
                  fillColor: cardColor,
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: borderColor),
                  ),
                ),
                validator: (value) => value!.isEmpty ? 'Champ requis' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: imageController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: 'Image (URL)',
                  labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                  filled: true,
                  fillColor: cardColor,
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: borderColor),
                  ),
                ),
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
                dropdownColor: GlobalColors.isDarkMode ? Colors.grey[800] : Colors.white,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: 'Catégorie',
                  labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                  filled: true,
                  fillColor: cardColor,
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: borderColor),
                  ),
                ),
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
                controller: tarifsController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: 'Tarifs',
                  labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                  filled: true,
                  fillColor: cardColor,
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: borderColor),
                  ),
                ),
                validator: (value) => value!.isEmpty ? 'Champ requis' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: adresseController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: 'Adresse',
                  labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                  filled: true,
                  fillColor: cardColor,
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: borderColor),
                  ),
                ),
                validator: (value) => value!.isEmpty ? 'Champ requis' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: instaController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: 'Lien Instagram',
                  labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                  filled: true,
                  fillColor: cardColor,
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: borderColor),
                  ),
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: fbController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: 'Lien Facebook',
                  labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                  filled: true,
                  fillColor: cardColor,
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: borderColor),
                  ),
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: latitudeController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: 'Latitude',
                  labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                  filled: true,
                  fillColor: cardColor,
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: borderColor),
                  ),
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: longitudeController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: 'Longitude',
                  labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                  filled: true,
                  fillColor: cardColor,
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: borderColor),
                  ),
                ),
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
                    : Text(
                  'Ajouter',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}