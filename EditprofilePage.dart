import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:google_fonts/google_fonts.dart';
import 'profile.dart';
import 'GlovalColors.dart';

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
              .select('prenom, nom, adresse')
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
        _locationController.text = personneData?['adresse'] ?? '';
        _descriptionController.text = profileData?['description'] ?? '';

        _existingProfilePhotoUrl = profileData?['profile_photo'];
        _existingBannerPhotoUrl = profileData?['banner_photo'];

        if (profileData?['centre_interet'] != null) {
          selectedInterests = List<String>.from(profileData?['centre_interet']);
        }

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
      backgroundColor: GlobalColors.cardColor,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: GlobalColors.cardColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isProfileImage ? "Photo de profil" : "Bannière",
                style: GoogleFonts.poppins(
                  textStyle: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: GlobalColors.secondaryColor,
                  ),
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.camera_alt,
                          size: 30,
                          color: GlobalColors.blueColor,
                        ),
                        onPressed:
                            () => Navigator.pop(context, ImageSource.camera),
                      ),
                      Text(
                        "Appareil photo",
                        style: TextStyle(color: GlobalColors.accentColor),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.photo_library,
                          size: 30,
                          color: GlobalColors.blueColor,
                        ),
                        onPressed:
                            () => Navigator.pop(context, ImageSource.gallery),
                      ),
                      Text(
                        "Galerie",
                        style: TextStyle(color: GlobalColors.accentColor),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
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
            toolbarColor: GlobalColors.blueColor,
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
        final compressedFile = File(croppedFile.path);

        setState(() {
          if (isProfileImage) {
            _profileImage = compressedFile;
          } else {
            _bannerImage = compressedFile;
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
        backgroundColor:
            message.contains("Erreur")
                ? GlobalColors.pinkColor
                : GlobalColors.greenColor,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: Duration(seconds: 3),
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
            backgroundColor: GlobalColors.accentColor.withOpacity(0.2),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: () => _pickImage(true),
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: GlobalColors.blueColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: GlobalColors.cardColor, width: 2),
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
          color: GlobalColors.accentColor.withOpacity(0.2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child:
              _bannerImage != null
                  ? Image.file(_bannerImage!, fit: BoxFit.cover)
                  : _existingBannerPhotoUrl != null
                  ? Image.network(_existingBannerPhotoUrl!, fit: BoxFit.cover)
                  : Center(
                    child: Icon(
                      Icons.image,
                      size: 50,
                      color: GlobalColors.accentColor,
                    ),
                  ),
        ),
      ),
    );
  }

  Widget _buildInterestsSection() {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 12),
      color: GlobalColors.cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Centres d'intérêt",
              style: GoogleFonts.poppins(
                textStyle: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: GlobalColors.secondaryColor,
                ),
              ),
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
                      selectedColor: GlobalColors.greenColor.withOpacity(0.2),
                      checkmarkColor: GlobalColors.greenColor,
                      labelStyle: GoogleFonts.poppins(
                        textStyle: TextStyle(
                          color:
                              isSelected
                                  ? GlobalColors.greenColor
                                  : GlobalColors.secondaryColor,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      backgroundColor: GlobalColors.primaryColor,
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
      color: GlobalColors.cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Préférences météo",
              style: GoogleFonts.poppins(
                textStyle: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: GlobalColors.secondaryColor,
                ),
              ),
            ),
            SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  availableWeatherPrefs.map((weather) {
                    final isSelected = weatherPreferences.contains(weather);
                    final weatherColor = _getWeatherColor(weather);

                    return FilterChip(
                      label: Text(weather),
                      selected: isSelected,
                      avatar: Icon(
                        _getWeatherIcon(weather),
                        color:
                            isSelected
                                ? weatherColor
                                : GlobalColors.accentColor,
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
                      selectedColor: weatherColor.withOpacity(0.2),
                      checkmarkColor: weatherColor,
                      labelStyle: GoogleFonts.poppins(
                        textStyle: TextStyle(
                          color:
                              isSelected
                                  ? weatherColor
                                  : GlobalColors.secondaryColor,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      backgroundColor: GlobalColors.primaryColor,
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
        return GlobalColors.amberColor;
      case 'nuageux':
        return Colors.blueGrey;
      case 'pluvieux':
        return GlobalColors.blueColor;
      case 'chaud':
        return Colors.red;
      case 'froid':
        return Colors.lightBlue;
      case 'venteux':
        return Colors.cyan;
      default:
        return GlobalColors.accentColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GlobalColors.primaryColor,
      appBar: AppBar(
        title: Text(
          "Modifier le profil",
          style: GoogleFonts.poppins(
            textStyle: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        backgroundColor: GlobalColors.blueColor,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline),
            onPressed:
                () => showDialog(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        backgroundColor: GlobalColors.cardColor,
                        title: Text(
                          "Aide",
                          style: GoogleFonts.poppins(
                            textStyle: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: GlobalColors.secondaryColor,
                            ),
                          ),
                        ),
                        content: Text(
                          "Modifiez les informations de votre profil ici.",
                          style: TextStyle(color: GlobalColors.accentColor),
                        ),
                        actions: [
                          TextButton(
                            child: Text(
                              "OK",
                              style: TextStyle(color: GlobalColors.blueColor),
                            ),
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
              ? Center(
                child: CircularProgressIndicator(color: GlobalColors.blueColor),
              )
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
                        color: GlobalColors.cardColor,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _firstNameController,
                                decoration: InputDecoration(
                                  labelText: "Prénom*",
                                  labelStyle: TextStyle(
                                    color: GlobalColors.accentColor,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.person_outline,
                                    color: GlobalColors.accentColor,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: GlobalColors.accentColor
                                          .withOpacity(0.2),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: GlobalColors.accentColor
                                          .withOpacity(0.2),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: GlobalColors.blueColor,
                                      width: 2,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: GlobalColors.primaryColor,
                                ),
                                style: TextStyle(
                                  color: GlobalColors.secondaryColor,
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
                                  labelStyle: TextStyle(
                                    color: GlobalColors.accentColor,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.person_outline,
                                    color: GlobalColors.accentColor,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: GlobalColors.accentColor
                                          .withOpacity(0.2),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: GlobalColors.accentColor
                                          .withOpacity(0.2),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: GlobalColors.blueColor,
                                      width: 2,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: GlobalColors.primaryColor,
                                ),
                                style: TextStyle(
                                  color: GlobalColors.secondaryColor,
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
                                  labelStyle: TextStyle(
                                    color: GlobalColors.accentColor,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.location_on_outlined,
                                    color: GlobalColors.accentColor,
                                  ),
                                  hintText: "Ex: Paris, France",
                                  hintStyle: TextStyle(
                                    color: GlobalColors.accentColor.withOpacity(
                                      0.5,
                                    ),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: GlobalColors.accentColor
                                          .withOpacity(0.2),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: GlobalColors.accentColor
                                          .withOpacity(0.2),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: GlobalColors.blueColor,
                                      width: 2,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: GlobalColors.primaryColor,
                                ),
                                style: TextStyle(
                                  color: GlobalColors.secondaryColor,
                                ),
                              ),
                              SizedBox(height: 16),
                              TextFormField(
                                controller: _descriptionController,
                                maxLines: 4,
                                decoration: InputDecoration(
                                  labelText: "Description",
                                  labelStyle: TextStyle(
                                    color: GlobalColors.accentColor,
                                  ),
                                  alignLabelWithHint: true,
                                  hintText: "Décrivez-vous en quelques mots...",
                                  hintStyle: TextStyle(
                                    color: GlobalColors.accentColor.withOpacity(
                                      0.5,
                                    ),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: GlobalColors.accentColor
                                          .withOpacity(0.2),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: GlobalColors.accentColor
                                          .withOpacity(0.2),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: GlobalColors.blueColor,
                                      width: 2,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: GlobalColors.primaryColor,
                                ),
                                style: TextStyle(
                                  color: GlobalColors.secondaryColor,
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
                            backgroundColor: GlobalColors.blueColor,
                            disabledBackgroundColor: GlobalColors.accentColor
                                .withOpacity(0.2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
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
                                    style: GoogleFonts.poppins(
                                      textStyle: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                        ),
                      ),
                      SizedBox(height: 12),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          "Annuler",
                          style: GoogleFonts.poppins(
                            textStyle: TextStyle(
                              color: GlobalColors.blueColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
    );
  }
}
