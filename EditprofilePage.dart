import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'profile.dart';

class EditProfilePage extends StatefulWidget {
  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  File? _profileImage;
  File? _bannerImage;
  final ImagePicker _picker = ImagePicker();
  bool isLoading = true;
  bool _isSaving = false;
  String? _existingProfilePhotoUrl;
  String? _existingBannerPhotoUrl;
  final _formKey = GlobalKey<FormState>();
  List<String> selectedInterests = [];
  List<String> weatherPreferences = [];

  final List<String> availableInterests = [
    "Parcs",
    "Randonnée",
    "Plages",
    "Monuments",
    "Culture",
    "Gastronomie",
    "Sport",
    "Nature",
  ];

  final List<String> availableWeatherPrefs = [
    "Ensoleillé",
    "Nuageux",
    "Chaud",
    "Froid",
    "Pluvieux",
    "Venteux",
  ];

  @override
  void initState() {
    super.initState();
    _fetchCurrentProfile();
  }

  Future<void> _fetchCurrentProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      _showSnackBar("Utilisateur non connecté");
      Navigator.pop(context);
      return;
    }

    try {
      
      final personneData =
          await Supabase.instance.client
              .from('personne')
              .select('prenom, nom,adresse')
              .eq('user_id', user.id)
              .maybeSingle();

      


      final profileData =
          await Supabase.instance.client
              .from('profiles')
              .select(
                'description, profile_photo, banner_photo, centre_interet, preferences_meteo',
              )
              .eq('user_id', user.id)
              .maybeSingle();

      setState(() {
        
        _firstNameController.text = personneData?['prenom'] ?? '';
        _lastNameController.text = personneData?['nom'] ?? '';
        _locationController.text = personneData?['location'] ?? '';
        _descriptionController.text = profileData?['description'] ?? '';

        
        _existingProfilePhotoUrl = profileData?['profile_photo'];
        _existingBannerPhotoUrl = profileData?['banner_photo'];

        
        if (profileData?['centre_interet'] != null) {
          selectedInterests = List<String>.from(profileData?['centre_interet']);
        }

        // Préférences météo
        if (profileData?['preferences_meteo'] != null) {
          weatherPreferences = List<String>.from(
            profileData?['preferences_meteo'],
          );
        }

        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showSnackBar("Erreur de chargement: ${e.toString()}");
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isProfileImage) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder:
          (context) => Container(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isProfileImage ? "Photo de profil" : "Bannière",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        IconButton(
                          icon: Icon(Icons.camera_alt, size: 30),
                          onPressed:
                              () => Navigator.pop(context, ImageSource.camera),
                        ),
                        Text("Appareil photo"),
                      ],
                    ),
                    Column(
                      children: [
                        IconButton(
                          icon: Icon(Icons.photo_library, size: 30),
                          onPressed:
                              () => Navigator.pop(context, ImageSource.gallery),
                        ),
                        Text("Galerie"),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
    );

    if (source == null) return;

    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile == null) return;

      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio:
            isProfileImage
                ? CropAspectRatio(ratioX: 1, ratioY: 1)
                : CropAspectRatio(ratioX: 16, ratioY: 9),
        compressQuality: 85,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle:
                isProfileImage ? "Recadrer la photo" : "Recadrer la bannière",
            toolbarColor: Colors.blue,
            toolbarWidgetColor: Colors.white,
            initAspectRatio:
                isProfileImage
                    ? CropAspectRatioPreset.square
                    : CropAspectRatioPreset.ratio16x9,
            lockAspectRatio: true,
          ),
        ],
      );

      if (croppedFile != null) {
        final compressedFile = await FlutterImageCompress.compressAndGetFile(
          croppedFile.path,
          path.join(
            (await getTemporaryDirectory()).path,
            '${DateTime.now().millisecondsSinceEpoch}.jpg',
          ),
          quality: 80,
        );

        setState(() {
          if (isProfileImage) {
            _profileImage =
                compressedFile != null
                    ? File(compressedFile.path)
                    : File(croppedFile.path);
          } else {
            _bannerImage =
                compressedFile != null
                    ? File(compressedFile.path)
                    : File(croppedFile.path);
          }
        });
      }
    } catch (e) {
      _showSnackBar("Erreur: ${e.toString()}");
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      _showSnackBar("Veuillez remplir tous les champs obligatoires");
      return;
    }

    setState(() => _isSaving = true);
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      _showSnackBar("Non connecté");
      setState(() => _isSaving = false);
      return;
    }

    try {
      // Upload des nouvelles images
      String? newProfileUrl = _existingProfilePhotoUrl;
      String? newBannerUrl = _existingBannerPhotoUrl;
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      if (_profileImage != null) {
        await Supabase.instance.client.storage
            .from('profile-images')
            .upload('profile_${user.id}_$timestamp.jpg', _profileImage!);
        newProfileUrl = Supabase.instance.client.storage
            .from('profile-images')
            .getPublicUrl('profile_${user.id}_$timestamp.jpg');
      }

      if (_bannerImage != null) {
        await Supabase.instance.client.storage
            .from('profile-images')
            .upload('banner_${user.id}_$timestamp.jpg', _bannerImage!);
        newBannerUrl = Supabase.instance.client.storage
            .from('profile-images')
            .getPublicUrl('banner_${user.id}_$timestamp.jpg');
      }

      // Mise à jour des données
      await Supabase.instance.client
          .from('personne')
          .update({
            'prenom': _firstNameController.text.trim(),
            'nom': _lastNameController.text.trim(),
            'adresse': _locationController.text.trim(),
          })
          .eq('user_id', user.id);

      await Supabase.instance.client
          .from('profiles')
          .update({
            'description': _descriptionController.text.trim(),
            'profile_photo': newProfileUrl,
            'banner_photo': newBannerUrl,
            'centre_interet': selectedInterests,
            'preferences_meteo': weatherPreferences,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', user.id);

      _showSnackBar("Profil mis à jour avec succès");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ProfilePage()),
      );
    } catch (e) {
      _showSnackBar("Erreur: ${e.toString()}");
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 3),
        backgroundColor: message.contains("Erreur") ? Colors.red : Colors.green,
      ),
    );
  }

  Widget _buildProfileImageSection() {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundImage:
                _profileImage != null
                    ? FileImage(_profileImage!)
                    : _existingProfilePhotoUrl != null
                    ? NetworkImage(_existingProfilePhotoUrl!)
                    : null,
            child:
                _profileImage == null && _existingProfilePhotoUrl == null
                    ? Icon(Icons.person, size: 50, color: Colors.white)
                    : null,
            backgroundColor: Colors.grey[300],
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: () => _pickImage(true),
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Icon(Icons.edit, size: 20, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerImageSection() {
    return GestureDetector(
      onTap: () => _pickImage(false),
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[300],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child:
              _bannerImage != null
                  ? Image.file(_bannerImage!, fit: BoxFit.cover)
                  : _existingBannerPhotoUrl != null
                  ? Image.network(_existingBannerPhotoUrl!, fit: BoxFit.cover)
                  : Center(
                    child: Icon(Icons.image, size: 50, color: Colors.white),
                  ),
        ),
      ),
    );
  }

  Widget _buildInterestsSection() {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 12),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Centres d'intérêt",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  availableInterests.map((interest) {
                    final isSelected = selectedInterests.contains(interest);
                    return FilterChip(
                      label: Text(interest),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            selectedInterests.add(interest);
                          } else {
                            selectedInterests.remove(interest);
                          }
                        });
                      },
                      selectedColor: Colors.green.withOpacity(0.2),
                      checkmarkColor: Colors.green,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.green[800] : Colors.black87,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    );
                  }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherPreferencesSection() {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 12),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Préférences météo",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  availableWeatherPrefs.map((weather) {
                    final isSelected = weatherPreferences.contains(weather);
                    return FilterChip(
                      label: Text(weather),
                      selected: isSelected,
                      avatar: Icon(
                        _getWeatherIcon(weather),
                        color:
                            isSelected
                                ? _getWeatherColor(weather)
                                : Colors.grey,
                      ),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            weatherPreferences.add(weather);
                          } else {
                            weatherPreferences.remove(weather);
                          }
                        });
                      },
                      selectedColor: _getWeatherColor(weather).withOpacity(0.1),
                      checkmarkColor: _getWeatherColor(weather),
                      labelStyle: TextStyle(
                        color:
                            isSelected
                                ? _getWeatherColor(weather)
                                : Colors.black87,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    );
                  }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getWeatherIcon(String weather) {
    switch (weather.toLowerCase()) {
      case 'ensoleillé':
        return Icons.wb_sunny;
      case 'nuageux':
        return Icons.cloud;
      case 'pluvieux':
        return Icons.water_drop;
      case 'chaud':
        return Icons.thermostat;
      case 'froid':
        return Icons.ac_unit;
      case 'venteux':
        return Icons.air;
      default:
        return Icons.wb_sunny;
    }
  }

  Color _getWeatherColor(String weather) {
    switch (weather.toLowerCase()) {
      case 'ensoleillé':
        return Colors.orange;
      case 'nuageux':
        return Colors.blueGrey;
      case 'pluvieux':
        return Colors.blue;
      case 'chaud':
        return Colors.red;
      case 'froid':
        return Colors.lightBlue;
      case 'venteux':
        return Colors.cyan;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Modifier le profil"),
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline),
            onPressed:
                () => showDialog(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: Text("Aide"),
                        content: Text(
                          "Modifiez les informations de votre profil ici.",
                        ),
                        actions: [
                          TextButton(
                            child: Text("OK"),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                ),
          ),
        ],
      ),
      body:
          isLoading
              ? Center(child: CircularProgressIndicator())
              : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildProfileImageSection(),
                      SizedBox(height: 20),
                      _buildBannerImageSection(),
                      SizedBox(height: 24),
                      Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _firstNameController,
                                decoration: InputDecoration(
                                  labelText: "Prénom*",
                                  prefixIcon: Icon(Icons.person_outline),
                                  border: OutlineInputBorder(),
                                ),
                                validator:
                                    (value) =>
                                        value?.isEmpty ?? true
                                            ? "Ce champ est requis"
                                            : null,
                              ),
                              SizedBox(height: 16),
                              TextFormField(
                                controller: _lastNameController,
                                decoration: InputDecoration(
                                  labelText: "Nom*",
                                  prefixIcon: Icon(Icons.person_outline),
                                  border: OutlineInputBorder(),
                                ),
                                validator:
                                    (value) =>
                                        value?.isEmpty ?? true
                                            ? "Ce champ est requis"
                                            : null,
                              ),
                              SizedBox(height: 16),
                              TextFormField(
                                controller: _locationController,
                                decoration: InputDecoration(
                                  labelText: "Localisation",
                                  prefixIcon: Icon(Icons.location_on_outlined),
                                  hintText: "Ex: Paris, France",
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              SizedBox(height: 16),
                              TextFormField(
                                controller: _descriptionController,
                                maxLines: 4,
                                decoration: InputDecoration(
                                  labelText: "Description",
                                  alignLabelWithHint: true,
                                  hintText: "Décrivez-vous en quelques mots...",
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      _buildInterestsSection(),
                      _buildWeatherPreferencesSection(),
                      SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.blue,
                          ),
                          child:
                              _isSaving
                                  ? SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 3,
                                    ),
                                  )
                                  : Text(
                                    "ENREGISTRER LES MODIFICATIONS",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                        ),
                      ),
                      SizedBox(height: 12),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text("Annuler"),
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
    );
  }
}
