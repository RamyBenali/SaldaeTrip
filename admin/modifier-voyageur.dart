import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../favoris.dart';

class ModifierVoyageurPage extends StatefulWidget {
  final Map<String, dynamic> voyageur;

  const ModifierVoyageurPage({super.key, required this.voyageur});

  @override
  State<ModifierVoyageurPage> createState() => _ModifierVoyageurPageState();
}

class _ModifierVoyageurPageState extends State<ModifierVoyageurPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController nomController;
  late TextEditingController prenomController;
  late TextEditingController emailController;
  late TextEditingController adresseController;
  late TextEditingController dateNaissanceController;

  @override
  void initState() {
    super.initState();
    nomController = TextEditingController(text: widget.voyageur['nom']);
    prenomController = TextEditingController(text: widget.voyageur['prenom']);
    emailController = TextEditingController(text: widget.voyageur['email']);
    adresseController = TextEditingController(text: widget.voyageur['adresse'] ?? '');
    dateNaissanceController = TextEditingController(text: widget.voyageur['datenaiss'] ?? '');
  }

  Future<void> modifierVoyageur() async {
    if (_formKey.currentState!.validate()) {
      try {
        await supabase.from('personne').update({
          'nom': nomController.text,
          'prenom': prenomController.text,
          'email': emailController.text,
          'adresse': adresseController.text,
          'datenaiss': dateNaissanceController.text,
        }).eq('idpersonne', widget.voyageur['idpersonne']);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Voyageur modifié avec succès')),
        );
        Navigator.pop(context, true); // On retourne à la page précédente
      } catch (e) {
        print('Erreur lors de la modification : $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la modification')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Modifier Voyageur'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: nomController,
                decoration: InputDecoration(labelText: 'Nom'),
                validator: (value) =>
                value!.isEmpty ? 'Champ obligatoire' : null,
              ),
              TextFormField(
                controller: prenomController,
                decoration: InputDecoration(labelText: 'Prénom'),
                validator: (value) =>
                value!.isEmpty ? 'Champ obligatoire' : null,
              ),
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(labelText: 'Email'),
                validator: (value) =>
                value!.isEmpty ? 'Champ obligatoire' : null,
              ),
              TextFormField(
                controller: adresseController,
                decoration: InputDecoration(labelText: 'Adresse'),
              ),
              TextFormField(
                controller: dateNaissanceController,
                decoration: InputDecoration(labelText: 'Date de naissance'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: modifierVoyageur,
                child: Text('Enregistrer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
