import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    'Point dintérêt religieux'
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
        SnackBar(content: Text('Identifiant du prestataire introuvable')),
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
        SnackBar(content: Text('Offre ajoutée avec succès')),
      );
      Navigator.pop(context);
    } catch (e) {
      print('Erreur lors de l\'ajout : $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'ajout de l\'offre')),
      );
    }

    setState(() => isLoading = false);
  }

  Widget buildCategorieSpecificFields() {
    if (selectedCategorie == 'Restaurant') {
      return TextFormField(
        controller: typeController,
        decoration: InputDecoration(labelText: 'Type du restaurant'),
        validator: (value) => value!.isEmpty ? 'Champ requis' : null,
      );
    } else if (selectedCategorie == 'Hôtel') {
      return Column(
        children: [
          TextFormField(
            controller: serviceController,
            decoration: InputDecoration(labelText: 'Service de l\'hôtel'),
            validator: (value) => value!.isEmpty ? 'Champ requis' : null,
          ),
          TextFormField(
            controller: etoilesController,
            decoration: InputDecoration(labelText: 'Nombre d\'étoiles'),
            keyboardType: TextInputType.number,
            validator: (value) => value!.isEmpty ? 'Champ requis' : null,
          ),
        ],
      );
    } else if (selectedCategorie != null) {
      return TextFormField(
        controller: typeController,
        decoration: InputDecoration(labelText: 'Type d\'activité'),
        validator: (value) => value!.isEmpty ? 'Champ requis' : null,
      );
    }
    return SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ajouter une Offre', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: nomController,
                decoration: InputDecoration(labelText: 'Nom'),
                validator: (value) => value!.isEmpty ? 'Champ requis' : null,
              ),
              TextFormField(
                controller: descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
                validator: (value) => value!.isEmpty ? 'Champ requis' : null,
              ),
              TextFormField(
                controller: imageController,
                decoration: InputDecoration(labelText: 'Image (URL)'),
                enabled: false,
              ),
              GestureDetector(
                onTap: pickImage,
                child: Container(
                  color: Colors.green,
                  padding: EdgeInsets.symmetric(vertical: 15),
                  child: Text(
                    _imageFile == null ? 'Choisir une image' : 'Image sélectionnée',
                    style: TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Catégorie'),
                value: selectedCategorie,
                items: categories.map((cat) {
                  return DropdownMenuItem(value: cat, child: Text(cat));
                }).toList(),
                onChanged: (value) {
                  setState(() => selectedCategorie = value);
                },
                validator: (value) => value == null ? 'Choisir une catégorie' : null,
              ),
              buildCategorieSpecificFields(),
              TextFormField(
                controller: tarifsController,
                decoration: InputDecoration(labelText: 'Tarifs'),
                validator: (value) => value!.isEmpty ? 'Champ requis' : null,
              ),
              TextFormField(
                controller: adresseController,
                decoration: InputDecoration(labelText: 'Adresse'),
                validator: (value) => value!.isEmpty ? 'Champ requis' : null,
              ),
              TextFormField(
                controller: instaController,
                decoration: InputDecoration(labelText: 'Lien Instagram'),
              ),
              TextFormField(
                controller: fbController,
                decoration: InputDecoration(labelText: 'Lien Facebook'),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: isLoading ? null : ajouterOffre,
                child: isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Ajouter'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
