import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile.dart';

class EditProfilePage extends StatefulWidget {
  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  File? _profileImage;
  File? _bannerImage;
  final ImagePicker _picker = ImagePicker();
  bool isLoading = true;
  int? userId;
  String? _existingProfilePhotoUrl;
  String? _existingBannerPhotoUrl;



  Future<void> _fetchCurrentProfile() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      print("Utilisateur non connecté.");
      return;
    }

    try {
      final personneResponse = await Supabase.instance.client
          .from('personne')
          .select('prenom, nom, email')
          .eq('user_id', user.id)
          .maybeSingle();

      if (personneResponse == null) {
        print("Aucun utilisateur trouvé avec cet email.");
        setState(() {
          isLoading = false;
        });
        return;
      }

      final profileResponse = await Supabase.instance.client
          .from('profiles')
          .select('description, profile_photo, banner_photo')
          .eq('user_id', user.id)
          .maybeSingle();

      setState(() {
        _firstNameController.text = personneResponse['prenom'] ?? '';
        _lastNameController.text = personneResponse['nom'] ?? '';
        _descriptionController.text = profileResponse?['description'] ?? '';
        _existingProfilePhotoUrl = profileResponse?['profile_photo'];
        _existingBannerPhotoUrl = profileResponse?['banner_photo'];
        isLoading = false;
      });
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
    _fetchCurrentProfile();
  }

  Future<void> _pickProfileImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _profileImage = File(image.path);
      });
    }
  }

  Future<String> _uploadImageToStorage(File image, String fileName) async {
    try {
      final storageResponse = await Supabase.instance.client.storage
          .from('profile-images') // Nom du bucket
          .upload(
        fileName,
        image,
      );

      // Obtenir l'URL publique du fichier téléchargé
      final publicUrlResponse = Supabase.instance.client.storage
          .from('profile-images')
          .getPublicUrl(fileName);

      return publicUrlResponse.toString();
    } catch (e) {
      print("Erreur lors du téléchargement de l'image : $e");
      return "";
    }
  }

  Future<void> _pickBannerImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _bannerImage = File(image.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      String? profileImageUrl;
      String? bannerImageUrl;

      if (_profileImage != null) {
        profileImageUrl = await _uploadImageToStorage(_profileImage!, 'profile_${userId}_image.jpg');
      }

      // Télécharger l'image de bannière si elle est présente
      if (_bannerImage != null) {
        bannerImageUrl = await _uploadImageToStorage(_bannerImage!, 'banner_${userId}_image.jpg');
      }

      // Mise à jour des données utilisateur
      await Supabase.instance.client
          .from('personne')
          .update({
        'prenom': _firstNameController.text,
        'nom': _lastNameController.text,
      })
          .eq('user_id', user.id);

      // Mise à jour des données de profil avec l'URL des images
      await Supabase.instance.client
          .from('profiles')
          .update({
        'description': _descriptionController.text,
        'profile_photo': profileImageUrl ?? _existingProfilePhotoUrl,
        'banner_photo': bannerImageUrl ?? _existingBannerPhotoUrl,
      })
          .eq('user_id', user.id);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ProfilePage()),
      );
    } catch (e) {
      print("Erreur lors de la sauvegarde du profil : $e");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Modifier le profil")),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _pickProfileImage,
              child: _profileImage != null
                  ? CircleAvatar(radius: 60, backgroundImage: FileImage(_profileImage!))
                  : _existingProfilePhotoUrl != null
                  ? CircleAvatar(radius: 60, backgroundImage: NetworkImage(_existingProfilePhotoUrl!))
                  : CircleAvatar(radius: 60, child: Icon(Icons.add_a_photo)),
            ),
            SizedBox(height: 20),
            GestureDetector(
              onTap: _pickBannerImage,
              child: _bannerImage != null
                  ? Container(
                height: 200,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: FileImage(_bannerImage!),
                    fit: BoxFit.cover,
                  ),
                ),
              )
                  : _existingBannerPhotoUrl != null
                  ? Container(
                height: 200,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(_existingBannerPhotoUrl!),
                    fit: BoxFit.cover,
                  ),
                ),
              )
                  : Container(
                height: 200,
                color: Colors.grey[300],
                child: Center(child: Icon(Icons.add_a_photo)),
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
              onPressed: _saveProfile,
              child: Text("Enregistrer les modifications"),
            ),
          ],
        ),
      ),
    );
  }
}
