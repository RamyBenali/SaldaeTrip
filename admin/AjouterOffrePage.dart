import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io'; // Pour gérer le fichier de l'image
import 'package:supabase_flutter/supabase_flutter.dart';

class AjouterOffrePage extends StatefulWidget {
  const AjouterOffrePage({super.key});

  @override
  State<AjouterOffrePage> createState() => _AjouterOffrePageState();
}

class Prestataire {
  final int id;
  final String nom;

  Prestataire({required this.id, required this.nom});

  factory Prestataire.fromJson(Map<String, dynamic> json) {
    return Prestataire(
      id: json['idpersonne'], // Corrigé ici
      nom: json['entreprise'], // Corrigé ici
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
  bool isLoadingPrestataires = true; // Pour gérer le chargement des prestataires
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
    'Point dintérêt religieux'
  ];

  Future<void> fetchPrestataires() async {
    try {
      final response = await Supabase.instance.client
          .from('prestataire')  // Nom de la table
          .select('idpersonne, entreprise');  // Utilisez seulement .select()

        final List<dynamic> data = response;  // Accédez directement aux données via response.data
        setState(() {
          prestataires = data
              .map((prestataire) => Prestataire.fromJson(prestataire)).cast<Prestataire>()
              .toList();
        });
    } catch (e) {
      print('Erreur : $e');
    }
  }


  @override
  void initState() {
    super.initState();
    fetchPrestataires();
  }

  Future<void> pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile;
        imageController.text = _imageFile!.path; // Mettre le chemin du fichier dans le champ
      });
    }
  }

  Future<void> ajouterOffre() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      // Vérifiez que l'ID du prestataire est valide
      final prestataireId = int.tryParse(idPrestataireController.text);
      if (prestataireId == null) {
        print('ID du prestataire invalide');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ID du prestataire invalide')),
        );
        setState(() => isLoading = false);
        return;
      }

      // Ici tu devras uploader l'image sur un service, comme Supabase Storage
      String? imageUrl = await uploadImageToStorage(_imageFile);

      // Ajouter l'offre dans la base de données
      final insertResult = await Supabase.instance.client.from('offre').insert({
        'nom': nomController.text,
        'description': descriptionController.text,
        'image': imageUrl, // Lien de l'image après upload
        'categorie': selectedCategorie,
        'idprestataire': prestataireId,  // Utilisation de prestataireId valide
        'tarifs': tarifsController.text,
        'adresse': adresseController.text,
        'offre_insta': instaController.text,
        'offre_fb': fbController.text,
      }).select().single();

      final idOffre = insertResult['idoffre'];

      // Selon la catégorie, on ajoute les données dans la table spécifique
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
      if (selectedPrestataire == null) {
        throw Exception('ID du prestataire manquant');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Offre ajoutée avec succès')),
      );
      Navigator.pop(context);
    } catch (e) {
      print('Erreur : $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'ajout de l\'offre')),
      );
    }

    setState(() => isLoading = false);
  }

  Future<String?> uploadImageToStorage(XFile? imageFile) async {
    if (imageFile == null) return null;

    try {
      final filePath = 'offres/${DateTime.now().millisecondsSinceEpoch}.png';
      final response = await Supabase.instance.client.storage.from('offre-image').upload(filePath, File(imageFile.path));
      final imageUrl = Supabase.instance.client.storage.from('offre-image').getPublicUrl(filePath);
      return imageUrl;
    } catch (e) {
      print('Erreur lors de l\'upload : $e');
      return null;
    }
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
        title: Text('Ajouter une Offre'),
        backgroundColor: Colors.blue,
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
                enabled: false, // Désactive le champ pour éviter la saisie manuelle
              ),
              GestureDetector(
                onTap: pickImage,
                child: Container(
                  color: Colors.blueAccent,
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
              DropdownButtonFormField<Prestataire>(
                decoration: InputDecoration(labelText: 'ID du Prestataire'),
                value: selectedPrestataire,
                items: prestataires.map((prestataire) {
                  return DropdownMenuItem(
                    value: prestataire,
                    child: Text(prestataire.nom),
                  );
                }).toList(),
                onChanged: (Prestataire? value) {
                  setState(() {
                    selectedPrestataire = value;
                    // Vérifier si selectedPrestataire n'est pas null avant de mettre à jour le contrôleur
                    idPrestataireController.text = value?.id.toString() ?? ''; // Mettre l'ID dans le contrôleur de texte
                  });
                },
                validator: (value) => value == null ? 'Choisir un prestataire' : null,
              ),
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
