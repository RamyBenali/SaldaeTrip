import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../GlovalColors.dart';

class ModifierPrestatairePage extends StatefulWidget {
  final Map<String, dynamic> prestataire;

  const ModifierPrestatairePage({super.key, required this.prestataire});

  @override
  State<ModifierPrestatairePage> createState() => _ModifierPrestatairePageState();
}

class _ModifierPrestatairePageState extends State<ModifierPrestatairePage> {
  final supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController nomController;
  late TextEditingController prenomController;
  late TextEditingController emailController;
  late TextEditingController adresseController;
  late TextEditingController dateNaissController;
  late TextEditingController entrepriseController;
  late TextEditingController typeServiceController;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    nomController = TextEditingController(text: widget.prestataire['nom']);
    prenomController = TextEditingController(text: widget.prestataire['prenom']);
    emailController = TextEditingController(text: widget.prestataire['email']);
    adresseController = TextEditingController(text: widget.prestataire['adresse']);
    dateNaissController = TextEditingController(text: widget.prestataire['datenaiss']);
    entrepriseController = TextEditingController(text: widget.prestataire['entreprise']);
    typeServiceController = TextEditingController(text: widget.prestataire['typeservice']);
  }

  Future<void> modifierPrestataire() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final id = widget.prestataire['idpersonne'];

      // MAJ table personne
      await supabase.from('personne').update({
        'nom': nomController.text,
        'prenom': prenomController.text,
        'email': emailController.text,
        'adresse': adresseController.text,
        'datenaiss': dateNaissController.text,
      }).eq('idpersonne', id);

      // MAJ table prestataire
      await supabase.from('prestataire').update({
        'entreprise': entrepriseController.text,
        'typeservice': typeServiceController.text,
      }).eq('idpersonne', id);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Prestataire modifié avec succès'),
          backgroundColor: GlobalColors.isDarkMode ? Colors.green[800] : Colors.green,
        ),
      );

      Navigator.pop(context);
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
    final buttonColor = GlobalColors.isDarkMode ? Colors.blueGrey : Colors.blue;

    return Scaffold(
      backgroundColor: GlobalColors.primaryColor,
      appBar: AppBar(
        title: Text(
          'Modifier Prestataire',
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
                ),
                validator: (value) => value!.isEmpty ? 'Champ requis' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: prenomController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: 'Prénom',
                  labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                  filled: true,
                  fillColor: cardColor,
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: borderColor),
                  ),
                ),
                validator: (value) => value!.isEmpty ? 'Champ requis' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: emailController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                  filled: true,
                  fillColor: cardColor,
                  border: OutlineInputBorder(
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
                ),
                validator: (value) => value!.isEmpty ? 'Champ requis' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: dateNaissController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: 'Date de naissance',
                  labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                  filled: true,
                  fillColor: cardColor,
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: borderColor),
                  ),
                ),
                validator: (value) => value!.isEmpty ? 'Champ requis' : null,
              ),
              Divider(color: borderColor),
              SizedBox(height: 16),
              TextFormField(
                controller: entrepriseController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: 'Entreprise',
                  labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                  filled: true,
                  fillColor: cardColor,
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: borderColor),
                  ),
                ),
                validator: (value) => value!.isEmpty ? 'Champ requis' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: typeServiceController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: 'Type de service',
                  labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                  filled: true,
                  fillColor: cardColor,
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: borderColor),
                  ),
                ),
                validator: (value) => value!.isEmpty ? 'Champ requis' : null,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: isLoading ? null : modifierPrestataire,
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