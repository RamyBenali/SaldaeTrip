import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/offre_model.dart';

class ModifierOffrePage extends StatefulWidget {
  final Offre offre; // Reçoit l'offre à modifier

  ModifierOffrePage({required this.offre});

  @override
  _ModifierOffrePageState createState() => _ModifierOffrePageState();
}

class _ModifierOffrePageState extends State<ModifierOffrePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomController;
  late TextEditingController _descriptionController;
  late TextEditingController _categorieController;
  late TextEditingController _tarifsController;
  late TextEditingController _adresseController;
  late TextEditingController _offreInstaController;
  late TextEditingController _offreFbController;
  late String _imageUrl;
  bool isLoading = false; // Variable pour gérer l'état de chargement


  @override
  void initState() {
    super.initState();
    // Initialiser les contrôleurs avec les valeurs actuelles de l'offre
    _nomController = TextEditingController(text: widget.offre.nom);
    _descriptionController = TextEditingController(text: widget.offre.description);
    _categorieController = TextEditingController(text: widget.offre.categorie);
    _tarifsController = TextEditingController(text: widget.offre.tarifs);
    _adresseController = TextEditingController(text: widget.offre.adresse);
    _offreInstaController = TextEditingController(text: widget.offre.offreInsta);
    _offreFbController = TextEditingController(text: widget.offre.offreFb);
    _imageUrl = widget.offre.image;
  }

  @override
  void dispose() {
    _nomController.dispose();
    _descriptionController.dispose();
    _categorieController.dispose();
    _tarifsController.dispose();
    _adresseController.dispose();
    _offreInstaController.dispose();
    _offreFbController.dispose();
    super.dispose();
  }

  Future<void> modifierOffre() async {
    // Valider le formulaire
    if (!_formKey.currentState!.validate()) return; // Si la validation échoue, ne rien faire

    setState(() => isLoading = true); // Afficher l'indicateur de chargement

    try {
      // Appeler la méthode Supabase pour mettre à jour l'offre
      final response = await Supabase.instance.client.from('offre').update({
        'nom': _nomController.text,
        'description': _descriptionController.text,
        'categorie': _categorieController.text,
        'tarifs': _tarifsController.text,
        'adresse': _adresseController.text,
        'offre_insta': _offreInstaController.text,
        'offre_fb': _offreFbController.text,
        'image': _imageUrl, // URL de l'image
      }).eq('idoffre', widget.offre.id).select().single(); // Utiliser maybeSingle() pour récupérer une seule ligne ou null

      // Vérification des erreurs
        // Si la mise à jour a réussi, revenir à la page précédente
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Offre modifiée avec succès')),
        );
        Navigator.pop(context, true); // Indiquer que la modification a été effectuée
    } catch (e) {
      // Gérer les erreurs si une exception se produit
      print('Erreur : $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la modification de l\'offre')),
      );
    }

    setState(() => isLoading = false); // Masquer l'indicateur de chargement
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Modifier l\'offre', style: GoogleFonts.robotoSlab(color: Colors.white)),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nomController,
                decoration: InputDecoration(labelText: 'Nom de l\'offre'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le nom est requis';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'La description est requise';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _categorieController,
                decoration: InputDecoration(labelText: 'Catégorie'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'La catégorie est requise';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _tarifsController,
                decoration: InputDecoration(labelText: 'Tarifs'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Les tarifs sont requis';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _adresseController,
                decoration: InputDecoration(labelText: 'Adresse'),
              ),
              TextFormField(
                controller: _offreInstaController,
                decoration: InputDecoration(labelText: 'Instagram'),
              ),
              TextFormField(
                controller: _offreFbController,
                decoration: InputDecoration(labelText: 'Facebook'),
              ),
              // Champ d'image - tu peux utiliser un champ pour l'URL de l'image
              TextFormField(
                controller: TextEditingController(text: _imageUrl),
                decoration: InputDecoration(labelText: 'URL de l\'image'),
                onChanged: (value) {
                  setState(() {
                    _imageUrl = value;
                  });
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: modifierOffre,
                child: Text('Mettre à jour l\'offre'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
