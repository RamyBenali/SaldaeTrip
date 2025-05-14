import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/offre_model.dart';
import '../GlovalColors.dart';

class ModifierOffrePage extends StatefulWidget {
  final Offre offre;

  const ModifierOffrePage({Key? key, required this.offre}) : super(key: key);

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
  late TextEditingController _imageController;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(text: widget.offre.nom);
    _descriptionController = TextEditingController(text: widget.offre.description);
    _categorieController = TextEditingController(text: widget.offre.categorie);
    _tarifsController = TextEditingController(text: widget.offre.tarifs);
    _adresseController = TextEditingController(text: widget.offre.adresse);
    _offreInstaController = TextEditingController(text: widget.offre.offreInsta);
    _offreFbController = TextEditingController(text: widget.offre.offreFb);
    _imageController = TextEditingController(text: widget.offre.image);
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
    _imageController.dispose();
    super.dispose();
  }

  Future<void> modifierOffre() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      await Supabase.instance.client.from('offre').update({
        'nom': _nomController.text,
        'description': _descriptionController.text,
        'categorie': _categorieController.text,
        'tarifs': _tarifsController.text,
        'adresse': _adresseController.text,
        'offre_insta': _offreInstaController.text,
        'offre_fb': _offreFbController.text,
        'image': _imageController.text,
      }).eq('idoffre', widget.offre.id);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Offre modifiée avec succès'),
          backgroundColor: GlobalColors.isDarkMode ? Colors.green[800] : Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      print('Erreur : $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la modification: $e'),
          backgroundColor: GlobalColors.isDarkMode ? Colors.red[800] : Colors.red,
        ),
      );
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = GlobalColors.isDarkMode ? Colors.grey[800]!.withOpacity(0.5) : Colors.white;
    final borderColor = GlobalColors.isDarkMode ? Colors.grey[600]! : Colors.grey[300]!;
    final textColor = GlobalColors.secondaryColor;
    final secondaryTextColor = GlobalColors.isDarkMode ? Colors.white70 : Colors.black54;
    final buttonColor = GlobalColors.isDarkMode ? Colors.blueGrey : Colors.blueAccent;

    return Scaffold(
      backgroundColor: GlobalColors.primaryColor,
      appBar: AppBar(
        title: Text(
          'Modifier l\'offre',
          style: GoogleFonts.robotoSlab(color: Colors.white),
        ),
        backgroundColor: GlobalColors.bleuTurquoise,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nomController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: 'Nom de l\'offre',
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
                validator: (value) => value!.isEmpty ? 'Le nom est requis' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
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
                validator: (value) => value!.isEmpty ? 'La description est requise' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _categorieController,
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
                validator: (value) => value!.isEmpty ? 'La catégorie est requise' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _tarifsController,
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
                validator: (value) => value!.isEmpty ? 'Les tarifs sont requis' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _adresseController,
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
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _offreInstaController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: 'Instagram',
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
                controller: _offreFbController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: 'Facebook',
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
                controller: _imageController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: 'URL de l\'image',
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
                onPressed: isLoading ? null : modifierOffre,
                style: ElevatedButton.styleFrom(
                  backgroundColor: GlobalColors.bleuTurquoise,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                child: isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                  'Mettre à jour l\'offre',
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