import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile.dart'; // Assurez-vous d'importer votre page Profile

class EditProfilePage extends StatefulWidget {
  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  File? _profileImage;
  File? _bannerImage;  // Ajout de la variable pour la bannière
  final ImagePicker _picker = ImagePicker();
  bool isLoading = true;

  // Fonction pour récupérer les informations actuelles du profil
  Future<void> _fetchCurrentProfile() async {
    final userId = '5'; // ID fixe pour les tests
    try {
      // Récupérer les données de la table `personne`
      final personneResponse = await Supabase.instance.client
          .from('personne')
          .select('prenom, nom')
          .eq('idpersonne', userId)
          .maybeSingle();

      // Récupérer la description de la table `profiles`
      final profileResponse = await Supabase.instance.client
          .from('profiles')
          .select('description')
          .eq('id', userId)  // Utilisation de l'ID utilisateur pour récupérer la description
          .maybeSingle();

      if (personneResponse != null && profileResponse != null) {
        setState(() {
          _firstNameController.text = personneResponse['prenom'] ?? '';
          _lastNameController.text = personneResponse['nom'] ?? '';
          _descriptionController.text = profileResponse['description'] ?? '';
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        print("Aucun profil ou description trouvé");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("Erreur lors de la récupération du profil : $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchCurrentProfile();  // Charger les informations actuelles dès le début
  }

  // Fonction pour choisir une photo de profil
  Future<void> _pickProfileImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _profileImage = File(image.path);
      });
    }
  }

  // Fonction pour choisir une photo de bannière
  Future<void> _pickBannerImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _bannerImage = File(image.path);
      });
    }
  }

  // Fonction pour enregistrer les informations modifiées
  Future<void> _saveProfile() async {
    final userId = '5';  // ID fixe pour les tests
    try {
      // Mettre à jour les données dans la table `personne`
      final personneResponse = await Supabase.instance.client
          .from('personne')
          .update({
        'prenom': _firstNameController.text,
        'nom': _lastNameController.text,
      })
          .eq('idpersonne', userId);

      // Mettre à jour la description dans la table `profiles`
      final profileResponse = await Supabase.instance.client
          .from('profiles')
          .update({
        'description': _descriptionController.text,
      })
          .eq('id', userId);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ProfilePage()),  // ProfilePage() doit être la page d'affichage du profil
      );
    } catch (e) {
      print("Erreur lors de la sauvegarde du profil : $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Modifier le profil"),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())  // Affichage du loader pendant le chargement
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _pickProfileImage,
              child: _profileImage == null
                  ? CircleAvatar(radius: 60, child: Icon(Icons.add_a_photo))
                  : CircleAvatar(radius: 60, backgroundImage: FileImage(_profileImage!)),
            ),
            SizedBox(height: 20),
            GestureDetector(
              onTap: _pickBannerImage,
              child: _bannerImage == null
                  ? Container(
                height: 200,
                color: Colors.grey[300],
                child: Center(child: Icon(Icons.add_a_photo)),
              )
                  : Container(
                height: 200,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: FileImage(_bannerImage!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _firstNameController,
              decoration: InputDecoration(labelText: "Prénom"),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _lastNameController,
              decoration: InputDecoration(labelText: "Nom"),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: "Description"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveProfile,  // Enregistrer les informations modifiées
              child: Text("Enregistrer les modifications"),
            ),
          ],
        ),
      ),
    );
  }
}
