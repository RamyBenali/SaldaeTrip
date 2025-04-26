import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'favoris.dart';
import 'map.dart';
import 'models/offre_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'map.dart';
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
    final currentUser = supabase.auth.currentUser;
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
      appBar: AppBar(
        title: Text(offre.nom, style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => MapScreen(
                  initialLocation: LatLng(offre.latitude, offre.longitude),
                  markerTitle: offre.nom,
                ),
              ),
            );
          },
          icon: Icon(Icons.map, color: Colors.white),
          label: Text(
            "Localiser sur la carte",
            style: TextStyle(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(20),
                  ),
                  child: Container(
                    height: 300,
                    width: double.infinity,
                    child: Image.network(offre.image, fit: BoxFit.cover),
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
                        color: Colors.white.withOpacity(0.8),
                        shape: BoxShape.circle,
                      ),
                      padding: EdgeInsets.all(8),
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
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.75),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          favoriMessage,
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionTitle(context, "Description"),
                      if (avisList.isNotEmpty)
                        Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 20),
                            SizedBox(width: 4),
                            Text(
                              averageRating.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 6),
                            Text(
                              "(${avisList.length} avis)",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  Text(offre.description, style: TextStyle(fontSize: 16)),
                  SizedBox(height: 20),

                  _buildSectionTitle(context, "Tarifs"),
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(offre.tarifs, style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  SizedBox(height: 20),

                  _buildSectionTitle(context, "Adresse"),
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.blue),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          offre.adresse,
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  _buildSectionTitle(context, "Réseaux sociaux"),
                  Row(
                    children: [
                      if (offre.offreInsta.isNotEmpty)
                        IconButton(
                          icon: Icon(
                            FontAwesomeIcons.instagram,
                            color: Colors.purple,
                          ),
                          onPressed: () {
                            launchUrl(
                              Uri.parse(offre.offreInsta),
                              mode: LaunchMode.externalApplication,
                            );
                          },
                        ),
                      if (offre.offreFb.isNotEmpty)
                        IconButton(
                          icon: Icon(
                            FontAwesomeIcons.facebook,
                            color: Colors.blue,
                          ),
                          onPressed: () {
                            launchUrl(
                              Uri.parse(offre.offreFb),
                              mode: LaunchMode.externalApplication,
                            );
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 20.0, right: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(context, "Avis des utilisateurs"),
                  const SizedBox(height: 10),
                  ...avisList.map((avis) {
                    final profilePhoto = avis['profile_photo'] ?? '';
                    final nom = avis['nom'] ?? 'Nom non disponible';
                    final prenom = avis['prenom'] ?? 'Prénom non disponible';
                    final note = avis['note'] ?? 0;
                    final comment = avis['commentaire'] ?? 'Pas de commentaire';
                    final image = avis['image'] ?? null;

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundImage:
                                  profilePhoto != null
                                      ? NetworkImage(profilePhoto as String)
                                      : const AssetImage(
                                    'assets/default_avatar.png',
                                  )
                                  as ImageProvider,
                                  radius: 22,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  "$prenom $nom",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                Row(
                                  children: List.generate(
                                    5,
                                        (index) => Icon(
                                      Icons.star,
                                      size: 18,
                                      color:
                                      index < note
                                          ? Colors.amber
                                          : Colors.grey,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(comment),
                            if (image != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(image, height: 150),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 20),
                  _buildSectionTitle(context, "Laisser un avis"),
                  const SizedBox(height: 10),

                  Row(
                    children: List.generate(
                      5,
                          (index) => IconButton(
                        icon: Icon(
                          Icons.star,
                          color:
                          index < selectedRating
                              ? Colors.amber
                              : Colors.grey,
                        ),
                        onPressed:
                            () => setState(() => selectedRating = index + 1),
                      ),
                    ),
                  ),

                  TextField(
                    decoration: const InputDecoration(
                      hintText: 'Écris ton avis...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                    maxLines: 3,
                    onChanged: (value) => commentaire = value,
                  ),
                  const SizedBox(height: 10),

                  if (imageFile != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(imageFile!, height: 120),
                    ),

                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: pickImage,
                        icon: const Icon(Icons.image),
                        label: const Text("Ajouter une image"),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: isPublishing ? null : publishAvis,
                        child:
                        isPublishing
                            ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : const Text("Publier"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge!.copyWith(
        fontWeight: FontWeight.bold,
        color: Colors.blue,
      ),
    );
  }
}
