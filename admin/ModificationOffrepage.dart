import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  final typeController = TextEditingController(); // Pour restaurant et activité
  final serviceController = TextEditingController(); // Pour hôtel
  final etoilesController = TextEditingController(); // Pour hôtel

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
    idPrestataireController.text = widget.offre['idprestataire']?.toString() ?? '';
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
        'idprestataire': int.parse(idPrestataireController.text),
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
        SnackBar(content: Text('Offre modifiée avec succès')),
      );
      Navigator.pop(context);
    } catch (e) {
      print('Erreur : $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la modification de l\'offre')),
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
        title: Text('Modifier l\'Offre', style: TextStyle(color: Colors.white)),
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
                validator: (value) => value!.isEmpty ? 'Champ requis' : null,
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
                controller: idPrestataireController,
                decoration: InputDecoration(labelText: 'ID du Prestataire'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Champ requis' : null,
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
                onPressed: isLoading ? null : modifierOffre,
                child: isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Modifier'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
