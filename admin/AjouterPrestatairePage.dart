import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../favoris.dart';

class AjouterPrestatairePage extends StatefulWidget {
  const AjouterPrestatairePage({super.key});

  @override
  State<AjouterPrestatairePage> createState() => _AjouterPrestatairePageState();
}

class _AjouterPrestatairePageState extends State<AjouterPrestatairePage> {
  final _formKey = GlobalKey<FormState>();

  final typeServiceController = TextEditingController();
  final entrepriseController = TextEditingController();

  bool isLoading = false;
  dynamic selectedVoyageur;
  List<dynamic> voyageurs = [];

  @override
  void initState() {
    super.initState();
    fetchVoyageurs();
  }

  Future<void> fetchVoyageurs() async {
    final response = await supabase
        .from('personne')
        .select('idpersonne, nom, prenom, email')
        .eq('role', 'Voyageur');

    setState(() {
      voyageurs = response;
    });
  }

  Future<void> ajouterPrestataire() async {
    if (!_formKey.currentState!.validate() || selectedVoyageur == null) return;

    setState(() => isLoading = true);

    final idPersonne = selectedVoyageur['idpersonne'];

    try {
      // 1. Mettre à jour le rôle
      await supabase.from('personne').update({
        'role': 'Prestataire',
      }).eq('idpersonne', idPersonne);

      // 2. Ajouter à la table prestataire
      await supabase.from('prestataire').insert({
        'idpersonne': idPersonne,
        'typeservice': typeServiceController.text,
        'entreprise': entrepriseController.text,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Prestataire ajouté avec succès')),
      );
      Navigator.pop(context);
    } catch (e) {
      print('Erreur : $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'ajout du prestataire')),
      );
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ajouter un Prestataire'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownSearch<dynamic>(
                items: voyageurs,
                itemAsString: (voyageur) =>
                "${voyageur['nom']} ${voyageur['prenom']} - ${voyageur['email']}",
                onChanged: (value) {
                  setState(() {
                    selectedVoyageur = value;
                  });
                },
                selectedItem: selectedVoyageur,
                dropdownDecoratorProps: DropDownDecoratorProps(
                  dropdownSearchDecoration: InputDecoration(
                    labelText: "Sélectionner un voyageur",
                    border: OutlineInputBorder(),
                  ),
                ),
                filterFn: (voyageur, filter) {
                  final nom = voyageur['nom'].toString().toLowerCase();
                  final prenom = voyageur['prenom'].toString().toLowerCase();
                  return nom.contains(filter.toLowerCase()) ||
                      prenom.contains(filter.toLowerCase());
                },
                validator: (value) =>
                value == null ? 'Veuillez sélectionner un voyageur' : null,
                popupProps: PopupProps.menu(
                  showSearchBox: true,
                  searchFieldProps: TextFieldProps(
                    decoration: InputDecoration(
                      hintText: 'Rechercher par nom ou prénom',
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: typeServiceController,
                decoration: InputDecoration(labelText: 'Type de service'),
                validator: (value) => value!.isEmpty ? 'Champ requis' : null,
              ),
              TextFormField(
                controller: entrepriseController,
                decoration: InputDecoration(labelText: 'Entreprise'),
                validator: (value) => value!.isEmpty ? 'Champ requis' : null,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: isLoading ? null : ajouterPrestataire,
                child: isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Ajouter le prestataire'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
