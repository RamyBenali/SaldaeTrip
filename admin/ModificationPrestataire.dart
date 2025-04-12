import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../favoris.dart';

class ModifierPrestatairePage extends StatefulWidget {
  final Map<String, dynamic> prestataire;

  const ModifierPrestatairePage({super.key, required this.prestataire});

  @override
  State<ModifierPrestatairePage> createState() => _ModifierPrestatairePageState();
}

class _ModifierPrestatairePageState extends State<ModifierPrestatairePage> {
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
        SnackBar(content: Text('Prestataire modifié avec succès')),
      );

      Navigator.pop(context);
    } catch (e) {
      print('Erreur : $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la modification')),
      );
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Modifier Prestataire'),
        backgroundColor: Colors.orange,
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
                controller: prenomController,
                decoration: InputDecoration(labelText: 'Prénom'),
                validator: (value) => value!.isEmpty ? 'Champ requis' : null,
              ),
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(labelText: 'Email'),
                validator: (value) => value!.isEmpty ? 'Champ requis' : null,
              ),
              TextFormField(
                controller: adresseController,
                decoration: InputDecoration(labelText: 'Adresse'),
                validator: (value) => value!.isEmpty ? 'Champ requis' : null,
              ),
              TextFormField(
                controller: dateNaissController,
                decoration: InputDecoration(labelText: 'Date de naissance'),
                validator: (value) => value!.isEmpty ? 'Champ requis' : null,
              ),
              Divider(),
              TextFormField(
                controller: entrepriseController,
                decoration: InputDecoration(labelText: 'Entreprise'),
                validator: (value) => value!.isEmpty ? 'Champ requis' : null,
              ),
              TextFormField(
                controller: typeServiceController,
                decoration: InputDecoration(labelText: 'Type de service'),
                validator: (value) => value!.isEmpty ? 'Champ requis' : null,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: isLoading ? null : modifierPrestataire,
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
