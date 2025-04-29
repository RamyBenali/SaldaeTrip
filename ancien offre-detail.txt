import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import 'map.dart';
import 'models/offre_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:latlong2/latlong.dart';

class OffreDetailPage extends StatefulWidget {
  final Offre offre;

  const OffreDetailPage({Key? key, required this.offre}) : super(key: key);

  @override
  State<OffreDetailPage> createState() => _OffreDetailPageState();
}

class _OffreDetailPageState extends State<OffreDetailPage> {
  bool isFavori = false;
  bool showFavoriMessage = false;
  String favoriMessage = '';
  List<Map<String, dynamic>> avisList = [];
  int selectedRating = 0;
  String commentaire = '';
  File? imageFile;
  bool isPublishing = false;
  final supabase = Supabase.instance.client;

  Future<void> checkIfFavori(int idOffre) async {
    try {
      final user = supabase.auth.currentUser;

      if (user == null) return;

      final response =
          await supabase
              .from('ajouterfavoris')
              .select()
              .eq('idoffre', idOffre)
              .eq('user_id', user.id)
              .maybeSingle();

      if (response != null) {
        setState(() {
          isFavori = true;
        });
      }
    } catch (e) {
      print("Erreur lors de la vérification des favoris: $e");
    }
  }

  Future<void> addFavori(int idOffre) async {
    try {
      final user = supabase.auth.currentUser;

      if (user == null) {
        print("Erreur: L'utilisateur n'a pas pu être trouvé.");
        return;
      }

      final response = await supabase.from('ajouterfavoris').insert([
        {'idoffre': idOffre, 'user_id': user.id},
      ]);

      if (response == null) {
      } else if (response.error != null) {
        print('Erreur lors de l\'ajout au favoris: ${response.error!.message}');
      } else {
        print('Offre ajoutée aux favoris');
      }
    } catch (e) {
      print("Erreur: $e");
    }
  }

  Future<void> removeFavori(int idOffre) async {
    try {
      final user = supabase.auth.currentUser;

      if (user == null) {
        print("Erreur: L'utilisateur n'a pas pu être trouvé.");
        return;
      }

      final response = await supabase
          .from('ajouterfavoris')
          .delete()
          .eq('idoffre', idOffre)
          .eq('user_id', user.id);

      if (response == null) {
      } else if (response.error != null) {
        print('Erreur lors du retrait des favoris: ${response.error!.message}');
      } else {
        print('Offre retirée des favoris');
      }
    } catch (e) {
      print("Erreur: $e");
    }
  }

  Future<void> fetchAvis() async {
    final response = await supabase
        .from('avis_avec_utilisateur')
        .select()
        .eq('idoffre', widget.offre.id)
        .order('idavis', ascending: false);

    setState(() {
      avisList = List<Map<String, dynamic>>.from(response);
    });
  }

  Future<void> publishAvis() async {
    setState(() => isPublishing = true);
    final user = supabase.auth.currentUser;

    if (user == null) return;

    String? imageUrl;
    if (imageFile != null) {
      final pickedImage = imageFile!;
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${user.id}.jpg';
      final fileBytes = await pickedImage.readAsBytes();

      try {
        await supabase.storage
            .from('avis-images')
            .uploadBinary('avis/$fileName', fileBytes);

        imageUrl = supabase.storage
            .from('avis-images')
            .getPublicUrl('avis/$fileName');
      } on StorageException catch (error) {
        print("Erreur lors de l'upload de l'image : ${error.message}");
      } catch (e) {
        print("Erreur inattendue : $e");
      }
    }

    await supabase.from('avis').insert({
      'user_id': user.id,
      'note': selectedRating,
      'commentaire': commentaire,
      'image': imageUrl,
      'idoffre': widget.offre.id,
      'idadministrateur': null,
      'idstatistique': null,
    });

    commentaire = '';
    selectedRating = 0;
    imageFile = null;

    await fetchAvis();

    setState(() => isPublishing = false);
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        imageFile = File(pickedFile.path);
      });
    }
  }

  double get averageRating {
    if (avisList.isEmpty) return 0.0;
    double total = 0.0;
    for (var avis in avisList) {
      total += (avis['note'] ?? 0).toDouble();
    }
    return total / avisList.length;
  }

  Future<void> incrementVisites() async {
    try {
      final response =
          await supabase
              .from('voyageur_offre')
              .select('nombres_visites')
              .eq('idoffre', widget.offre.id)
              .single();

      final currentVisites = response['nombres_visites'] ?? 0;

      final updateResponse = await supabase
          .from('voyageur_offre')
          .update({'nombres_visites': currentVisites + 1})
          .eq('idoffre', widget.offre.id);

      if (updateResponse.error != null) {
        print(
          'Erreur lors de la mise à jour : ${updateResponse.error!.message}',
        );
      } else {
        print('Nombre de visites incrémenté avec succès.');
      }
    } catch (e) {
      print('Erreur lors de l\'incrémentation des visites : $e');
    }
  }

  @override
  void initState() {
    super.initState();
    checkIfFavori(widget.offre.id);
    fetchAvis();
    incrementVisites();
  }

  @override
  Widget build(BuildContext context) {
    final offre = widget.offre;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          offre.nom,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.blue,
        elevation: 0,
        centerTitle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: Offset(0, -1),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => MapScreen(
                        positionInitiale: LatLng(
                          offre.latitude,
                          offre.longitude,
                        ),
                        titreMarqueur: offre.nom,
                      ),
                ),
              );
            },
            icon: Icon(Icons.map, color: Colors.white),
            label: Text(
              "Localiser sur la carte",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                Hero(
                  tag: 'offre_image_${offre.id}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(20),
                    ),
                    child: Container(
                      height: 300,
                      width: double.infinity,
                      child: Image.network(
                        offre.image,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey[200],
                            child: Center(
                              child: CircularProgressIndicator(
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: GestureDetector(
                    onTap: () async {
                      setState(() {
                        isFavori = !isFavori;
                        favoriMessage =
                            isFavori
                                ? "Ajouté aux favoris"
                                : "Retiré des favoris";
                        showFavoriMessage = true;
                      });

                      Future.delayed(Duration(seconds: 3), () {
                        if (mounted) {
                          setState(() {
                            showFavoriMessage = false;
                          });
                        }
                      });

                      if (isFavori) {
                        await addFavori(offre.id);
                      } else {
                        await removeFavori(offre.id);
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.all(12),
                      child: Icon(
                        isFavori ? Icons.favorite : Icons.favorite_border,
                        color: isFavori ? Colors.red : Colors.grey,
                        size: 28,
                      ),
                    ),
                  ),
                ),
                if (showFavoriMessage)
                  Positioned(
                    top: 20,
                    right: 70,
                    child: AnimatedOpacity(
                      opacity: showFavoriMessage ? 1.0 : 0.0,
                      duration: Duration(milliseconds: 300),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 5,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          favoriMessage,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Description",
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                      if (avisList.isNotEmpty)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.star, color: Colors.amber, size: 20),
                              SizedBox(width: 4),
                              Text(
                                averageRating.toStringAsFixed(1),
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue,
                                ),
                              ),
                              SizedBox(width: 6),
                              Text(
                                "(${avisList.length})",
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    offre.description,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      height: 1.5,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 24),

                  _buildModernSection(
                    context,
                    "Tarifs",
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.blue.withOpacity(0.1)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          offre.tarifs,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            height: 1.5,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                    ),
                  ),

                  _buildModernSection(
                    context,
                    "Adresse",
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.location_on, color: Colors.blue),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            offre.adresse,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  _buildModernSection(
                    context,
                    "Réseaux sociaux",
                    Row(
                      children: [
                        if (offre.offreInsta?.isNotEmpty ?? false)
                          _buildSocialButton(
                            FontAwesomeIcons.instagram,
                            Colors.purple,
                            offre.offreInsta!,
                          ),
                        if (offre.offreFb?.isNotEmpty ?? false)
                          _buildSocialButton(
                            FontAwesomeIcons.facebook,
                            Colors.blue,
                            offre.offreFb!,
                          ),
                      ],
                    ),
                  ),

                  _buildModernSection(
                    context,
                    "Avis des utilisateurs",
                    Column(
                      children:
                          avisList.map((avis) {
                            final profilePhoto = avis['profile_photo'] ?? '';
                            final nom = avis['nom'] ?? 'Nom non disponible';
                            final prenom =
                                avis['prenom'] ?? 'Prénom non disponible';
                            final note = avis['note'] ?? 0;
                            final comment =
                                avis['commentaire'] ?? 'Pas de commentaire';
                            final image = avis['image'] ?? null;

                            return Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: Colors.blue.withOpacity(0.1),
                                ),
                              ),
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundImage:
                                              profilePhoto != null
                                                  ? NetworkImage(
                                                    profilePhoto as String,
                                                  )
                                                  : AssetImage(
                                                        'assets/default_avatar.png',
                                                      )
                                                      as ImageProvider,
                                          radius: 24,
                                        ),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "$prenom $nom",
                                                style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              Row(
                                                children: List.generate(
                                                  5,
                                                  (index) => Icon(
                                                    Icons.star,
                                                    size: 16,
                                                    color:
                                                        index < note
                                                            ? Colors.amber
                                                            : Colors.grey[300],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      comment,
                                      style: GoogleFonts.poppins(
                                        fontSize: 15,
                                        height: 1.5,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                    if (image != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 12),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: Image.network(
                                            image,
                                            height: 150,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                  ),

                  _buildModernSection(
                    context,
                    "Laisser un avis",
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: List.generate(
                            5,
                            (index) => IconButton(
                              icon: Icon(
                                Icons.star,
                                color:
                                    index < selectedRating
                                        ? Colors.amber
                                        : Colors.grey[300],
                                size: 32,
                              ),
                              onPressed:
                                  () => setState(
                                    () => selectedRating = index + 1,
                                  ),
                            ),
                          ),
                        ),
                        SizedBox(height: 12),
                        TextField(
                          decoration: InputDecoration(
                            hintText: 'Écris ton avis...',
                            hintStyle: GoogleFonts.poppins(
                              color: Colors.grey[400],
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.blue.withOpacity(0.2),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.blue.withOpacity(0.2),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.blue,
                                width: 2,
                              ),
                            ),
                            contentPadding: EdgeInsets.all(16),
                          ),
                          maxLines: 3,
                          style: GoogleFonts.poppins(fontSize: 16),
                          onChanged: (value) => commentaire = value,
                        ),
                        SizedBox(height: 12),
                        if (imageFile != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              imageFile!,
                              height: 120,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        SizedBox(height: 12),
                        Row(
                          children: [
                            TextButton.icon(
                              onPressed: pickImage,
                              icon: Icon(Icons.image, color: Colors.blue),
                              label: Text(
                                "Ajouter une image",
                                style: GoogleFonts.poppins(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Spacer(),
                            ElevatedButton(
                              onPressed: isPublishing ? null : publishAvis,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child:
                                  isPublishing
                                      ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                      : Text(
                                        "Publier",
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernSection(
    BuildContext context,
    String title,
    Widget content,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 24),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.blue,
          ),
        ),
        SizedBox(height: 12),
        content,
      ],
    );
  }

  Widget _buildSocialButton(IconData icon, Color color, String url) {
    return Container(
      margin: EdgeInsets.only(right: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap:
              () => launchUrl(
                Uri.parse(url),
                mode: LaunchMode.externalApplication,
              ),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
        ),
      ),
    );
  }
}
