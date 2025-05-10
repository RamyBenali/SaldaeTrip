import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import 'map.dart';
import 'models/offre_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'GlovalColors.dart';
import 'package:latlong2/latlong.dart';
import 'UserProfilePage.dart';


class OffreDetailPage extends StatefulWidget {
  final Offre offre;

  const OffreDetailPage({Key? key, required this.offre}) : super(key: key);

  @override
  State<OffreDetailPage> createState() => _OffreDetailPageState();
}

class _OffreDetailPageState extends State<OffreDetailPage> {
  final textColor = GlobalColors.secondaryColor;
  final primaryColor = GlobalColors.primaryColor;
  int? hotelEtoiles;
  late PageController _pageController;
  int _currentPage = 0;
  bool isFavori = false;
  bool showFavoriMessage = false;
  String favoriMessage = '';
  List<Map<String, dynamic>> avisList = [];
  int selectedRating = 0;
  String commentaire = '';
  File? imageFile;
  bool isPublishing = false;
  String tarifs = '';
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
    try {
      final avisResponse = await supabase
          .from('avis_avec_utilisateur')
          .select('*')
          .eq('idoffre', widget.offre.id)
          .order('idavis', ascending: false);

      if (avisResponse != null) {
        final List<Map<String, dynamic>> completeAvisList = [];

        for (final avis in avisResponse) {
          // Conversion explicite en Map<String, dynamic>
          final avisMap = Map<String, dynamic>.from(avis);

          final reponsesResponse = await supabase
              .from('reponses_avis')
              .select('*')
              .eq('id_avis', avisMap['idavis']);

          // Conversion des réponses et ajout des utilisateurs
          final reponsesWithUsers = await Future.wait(
            (reponsesResponse as List).map((reponse) async {
              final reponseMap = Map<String, dynamic>.from(reponse);

              // Récupération des données depuis la table personne
              final personneData = await supabase
                  .from('personne')
                  .select('prenom, nom')
                  .eq('user_id', reponseMap['user_id'])
                  .maybeSingle();

              // Récupération de la photo depuis la table profiles
              final profileData = await supabase
                  .from('profiles')
                  .select('profile_photo')
                  .eq('user_id', reponseMap['user_id'])
                  .maybeSingle();

              return {
                ...reponseMap,
                'user': {
                  'prenom': personneData?['prenom'] ?? 'Anonyme',
                  'nom': personneData?['nom'] ?? '',
                  'profile_photo': profileData?['profile_photo'],
                },
              };
            }),
          );

          final likesResponse = await supabase
              .from('avis_likes')
              .select('user_id')
              .eq('avis_id', avisMap['idavis']);

          completeAvisList.add({
            ...avisMap,
            'reponses': reponsesWithUsers,
            'likes': likesResponse != null
                ? List<Map<String, dynamic>>.from(likesResponse.map((like) => Map<String, dynamic>.from(like)))
                : [],
            'isExpanded': false,
            'reponseText': '',
            'showReplyField': false,
          });
        }

        setState(() {
          avisList = completeAvisList;
        });
      }
    } catch (e) {
      print("Erreur lors de la récupération des avis: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur lors du chargement des avis")),
        );
      }
    }
  }

  Future<List<Map<String, dynamic>>> _getReponsesWithUsers(List<dynamic> reponses) async {
    final List<Map<String, dynamic>> result = [];

    for (final reponse in reponses) {
      final user = await supabase
          .from('profiles')
          .select('*')
          .eq('user_id', reponse['user_id'])
          .single();

      result.add({
        ...reponse,
        'user': user,
      });
    }

    return result;
  }

  Future<void> toggleLike(int avisId) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vous devez être connecté pour liker')),
      );
      return;
    }

    try {
      // Trouver l'avis dans la liste
      final avisIndex = avisList.indexWhere((a) => a['idavis'] == avisId);
      if (avisIndex == -1) return;

      final avis = avisList[avisIndex];
      final isLiked = (avis['likes'] as List).any((like) => like['user_id'] == user.id);

      if (isLiked) {
        await supabase
            .from('avis_likes')
            .delete()
            .eq('avis_id', avisId)
            .eq('user_id', user.id);
      } else {
        await supabase.from('avis_likes').insert({
          'avis_id': avisId,
          'user_id': user.id,
        });
      }

      // Rafraîchir les données
      await fetchAvis();
    } catch (e) {
      print("Erreur lors du like: $e");
    }
  }

  Future<void> addReponse(int avisId, String reponseText) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vous devez être connecté pour répondre')),
      );
      return;
    }

    if (reponseText.isEmpty) return;

    try {
      await supabase.from('reponses_avis').insert({
        'id_avis': avisId,
        'user_id': user.id,
        'reponse': reponseText,
        'date': DateTime.now().toIso8601String(),
      });

      // Rafraîchir les données et masquer le champ de réponse
      setState(() {
        final avisIndex = avisList.indexWhere((a) => a['idavis'] == avisId);
        if (avisIndex != -1) {
          avisList[avisIndex]['showReplyField'] = false;
          avisList[avisIndex]['reponseText'] = '';
        }
      });

      await fetchAvis();
    } catch (e) {
      print("Erreur lors de l'ajout de la réponse: $e");
    }
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

  Future<int?> fetchHotelEtoiles(int idOffre) async {
    try {
      final response = await supabase
          .from('hotel')
          .select('etoile')
          .eq('idoffre', idOffre)
          .maybeSingle();

      return response?['etoile'] as int?;
    } catch (e) {
      print("Erreur lors de la récupération des étoiles: $e");
      return null;
    }
  }

  Future<void> _fetchHotelEtoilesIfNeeded() async {
    if (widget.offre.categorie.toLowerCase() == 'hôtel' ||
        widget.offre.categorie.toLowerCase() == 'hotel') {
      final etoiles = await fetchHotelEtoiles(widget.offre.id);
      setState(() {
        hotelEtoiles = etoiles;
      });
    }
  }

  Future<void> isFreeOffre() async {
    final offre = widget.offre;
    if(offre.tarifs == '0'){
      if(offre.categorie == 'Plage'){
        tarifs = 'Entrée gratuite';
      }else if(offre.categorie == "Loisir" ||
          offre.categorie == "Point dintérêt historique" ||
          offre.categorie == "Point dintérêt religieux" ||
          offre.categorie == "Point dintérêt"
      ){
        tarifs = 'Activités gratuite';
      }else{
        tarifs = 'Tarifs non précisé';
      }
    }else{
      tarifs = offre.tarifs;
    }
  }

  @override
  void initState() {
    super.initState();
    _currentPage = 0;
    _pageController = PageController();
    checkIfFavori(widget.offre.id);
    fetchAvis();
    incrementVisites();
    isFreeOffre();
    _fetchHotelEtoilesIfNeeded();

  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final offre = widget.offre;

    return Scaffold(
      backgroundColor: GlobalColors.primaryColor,
      body: Stack(
        children: [
          _buildImageCarousel(),

          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5],
                  ),
                ),
              ),
            ),
          ),

          CustomScrollView(
            physics: const ClampingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.65,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onVerticalDragUpdate: (_) {}, // Bloque le scroll vertical sur cette zone
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            GlobalColors.primaryColor.withOpacity(0.2),
                            GlobalColors.primaryColor.withOpacity(1.0),
                          ],
                          stops: const [0.0, 0.1],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Section titre
                          Container(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if ((widget.offre.categorie.toLowerCase() == 'hôtel' ||
                                    widget.offre.categorie.toLowerCase() == 'hotel') &&
                                    hotelEtoiles != null)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 0),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: List.generate(
                                        hotelEtoiles!,
                                            (index) => const Icon(Icons.star, color: Colors.amber, size: 20),
                                      ),
                                    ),
                                  ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              widget.offre.nom,
                                              style: GoogleFonts.robotoSlab(
                                                fontSize: 28,
                                                fontWeight: FontWeight.bold,
                                                color: GlobalColors.secondaryColor,
                                              )
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.amber[200]?.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.star, color: Colors.amber, size: 20),
                                          const SizedBox(width: 4),
                                          Text(
                                            averageRating.toStringAsFixed(1),
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: GlobalColors.secondaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on, size: 14, color: Colors.grey),
                                    const SizedBox(width: 5),
                                    Text(
                                      offre.adresse,
                                      style: GoogleFonts.robotoSlab(
                                        fontSize: 12,
                                        color: GlobalColors.accentColor,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      tarifs,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF41A6B4),
                                      ),
                                    ),
                                    if (offre.offreFb != null || offre.offreInsta != null) // Condition d'affichage
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (offre.offreFb != null && offre.offreFb.isNotEmpty) // Facebook si URL existe
                                            Padding(
                                              padding: const EdgeInsets.only(left: 8),
                                              child: IconButton(
                                                icon: Icon(FontAwesomeIcons.facebook,
                                                    size: 40,
                                                    color: Colors.blue[800]),
                                                onPressed: () => _launchUrl(offre.offreFb),
                                              ),
                                            ),
                                          if (offre.offreInsta != null && offre.offreInsta.isNotEmpty) // Instagram si URL existe
                                            Padding(
                                              padding: const EdgeInsets.only(left: 8),
                                              child: IconButton(
                                                icon: Icon(FontAwesomeIcons.instagram,
                                                    size: 40,
                                                    color: Colors.pink),
                                                onPressed: () => _launchUrl(offre.offreInsta),
                                              ),
                                            ),
                                        ],
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Text(
                            offre.description,
                            style: GoogleFonts.robotoSlab(
                              fontSize: 16,
                              height: 1.5,
                              color: GlobalColors.secondaryColor,
                            ),
                          ),

                          const SizedBox(height: 30),

                          // Avis
                          _buildModernSection(
                            context,
                            "Avis des utilisateurs",
                            Column(
                              children: [
                                if (avisList.isEmpty)
                                  Center(
                                    child: Text(
                                      'Aucun avis pour le moment',
                                      style: GoogleFonts.robotoSlab(
                                        color: GlobalColors.accentColor,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ...avisList.map((avis) => _buildAvisCard(avis)).toList(),

                                const SizedBox(height: 24),

                                _buildModernSection(
                                  context,
                                  "Donnez votre avis",
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Center(
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          children: List.generate(5, (index) {
                                            return IconButton(
                                              icon: Icon(
                                                Icons.star,
                                                size: 32,
                                                color: index < selectedRating
                                                    ? Colors.amber
                                                    : Colors.grey[300],
                                              ),
                                              onPressed: () => setState(() => selectedRating = index + 1),
                                            );
                                          }),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      TextField(
                                        decoration: InputDecoration(
                                          hintText: 'Écrivez votre avis...',
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
                                          contentPadding: const EdgeInsets.all(16),
                                        ),
                                        maxLines: 3,
                                        style: GoogleFonts.poppins(fontSize: 16),
                                        onChanged: (value) => commentaire = value,
                                      ),
                                      const SizedBox(height: 12),
                                      if (imageFile != null)
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Image.file(
                                            imageFile!,
                                            height: 150,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          TextButton.icon(
                                            onPressed: pickImage,
                                            icon: const Icon(Icons.image, color: Color(0xFF41A6B4)),
                                            label: Text(
                                              "Ajouter une photo",
                                              style: GoogleFonts.robotoSlab(
                                                color: Color(0xFF41A6B4),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          const Spacer(),
                                          ElevatedButton(
                                            onPressed: isPublishing ? null : publishAvis,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Color(0xFF41A6B4),
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 24,
                                                vertical: 12,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                            ),
                                            child: isPublishing
                                                ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                                : Text(
                                              "Publier",
                                              style: GoogleFonts.robotoSlab(
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
                  ),
                ),
              ),
            ],
          ),

          Positioned.fill(
            top: 0,
            right: 0,
            left: 0,
            bottom: 250,
            child: GestureDetector(
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity! < 0) {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 100),
                    curve: Curves.easeInOutCubic,
                  );
                } else if (details.primaryVelocity! > 0) {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 100),
                    curve: Curves.easeInOutCubic,
                  );
                }
              },
            ),
          ),

          Positioned(
            top: 50,
            right: 20,
            child: _buildFavoriteButton(),
          ),

          Positioned(
            top: 50,
            left: 20,
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: _buildLocationButton(),
          ),
        ],
      ),
    );
  }
  Widget _buildImageCarousel() {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: Stack(
        children: [
          // PageView pour afficher les images
          PageView.builder(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(), // Désactiver les gestes natifs
            itemCount: widget.offre.images.length,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemBuilder: (context, index) {
              String imageUrl = widget.offre.images[index]
                  .replaceAll('["', '')
                  .replaceAll('"]', '')
                  .trim();

              return Image.network(
                imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image, size: 50),
                  );
                },
              );
            },
          ),
          // Indicateurs de page
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.offre.images.length,
                    (index) => GestureDetector(
                  onTap: () => _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: _currentPage == index ? 12 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentPage == index
                          ? Colors.white
                          : Colors.white.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.robotoSlab(
          fontSize: 24,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF333333),
        ),
      ),
    );
  }

  void _goToNextImage() {
    print('Next image requested');
    if (widget.offre.images.isEmpty) return;
    final nextPage = (_currentPage + 1) % widget.offre.images.length;
    print('Moving to page $nextPage');
    _pageController.animateToPage(
      nextPage,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _goToPreviousImage() {
    if (widget.offre.images.isEmpty) return;
    final prevPage = _currentPage == 0
        ? widget.offre.images.length - 1
        : _currentPage - 1;
    _pageController.animateToPage(
      prevPage,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
  Widget _buildFavoriteButton() {
    return GestureDetector(
      onTap: () {
        setState(() {
          isFavori = !isFavori;
        });
        if (isFavori) {
          addFavori(widget.offre.id);
        } else {
          removeFavori(widget.offre.id);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isFavori ? Icons.favorite : Icons.favorite_border,
          color: isFavori ? Colors.red : Colors.white,
          size: 28,
        ),
      ),
    );
  }



  Widget _buildLocationButton() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        color: const Color(0xFF41A6B4).withOpacity(1),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MapScreen(
                  positionInitiale: LatLng(
                    widget.offre.latitude,
                    widget.offre.longitude,
                  ),
                  titreMarqueur: widget.offre.nom,
                ),
              ),
            );
          },
          child: Center(
            child: Text(
              'Localiser',
              style: GoogleFonts.robotoSlab(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernSection(BuildContext context, String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 24),
        Text(
          title,
          style: GoogleFonts.robotoSlab(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: GlobalColors.secondaryColor,
          ),
        ),
        SizedBox(height: 12),
        content,
        SizedBox(height: 30),
      ],
    );
  }

  Future<void> _launchUrl(String url) async {
    // Vérification basique de l'URL
    if (url.isEmpty || !url.startsWith('http')) {
      debugPrint('URL invalide: $url');
      _showError();
      return;
    }

    try {
      final uri = Uri.parse(url);

      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
          webOnlyWindowName: '_blank', // Pour le web
        );
      } else {
        _showError();
      }
    } catch (e) {
      debugPrint('Erreur de lancement: $e');
      _showError();
    }
  }

  void _showError() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ouverture impossible - Vérifiez le lien'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Widget _buildAvisCard(Map<String, dynamic> avis) {
    final user = supabase.auth.currentUser;
    final isLiked = (avis['likes'] as List).any((like) => like['user_id'] == user?.id);
    final reponses = avis['reponses'] as List<dynamic>? ?? [];
    final isExpanded = avis['isExpanded'] as bool;
    final showReplyField = avis['showReplyField'] as bool;
    final reponseController = TextEditingController(text: avis['reponseText'] ?? '');

    // Les infos viennent directement de avis_avec_utilisateur
    final userName = '${avis['prenom'] ?? 'Anonyme'} ${avis['nom'] ?? ''}';
    final userPhoto = avis['profile_photo'];

    return Card(
      color: GlobalColors.cardColor,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: userPhoto != null
                      ? NetworkImage(userPhoto as String)
                      : const AssetImage('assets/images/profile.jpg') as ImageProvider,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: GlobalColors.accentColor,
                        ),
                      ),
                      Row(
                        children: List.generate(
                          5,
                              (index) => Icon(
                            Icons.star,
                            size: 16,
                            color: index < (avis['note'] ?? 0)
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
            const SizedBox(height: 12),
            Text(
              avis['commentaire'] ?? 'Pas de commentaire',
              style: TextStyle(color: GlobalColors.accentColor),
            ),
            if (avis['image'] != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  avis['image'] as String,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],
            // Boutons Like et Répondre
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked ? Colors.red : null,
                  ),
                  onPressed: () => toggleLike(avis['idavis']),
                ),
                Text('${(avis['likes'] as List).length}'),
                const SizedBox(width: 10),
                IconButton(
                  icon: const Icon(Icons.reply),
                  onPressed: () {
                    setState(() {
                      avis['showReplyField'] = !showReplyField;
                    });
                  },
                ),
                if (reponses.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        avis['isExpanded'] = !isExpanded;
                      });
                    },
                    child: Text(
                      isExpanded ? 'Masquer les réponses' : 'Voir les réponses (${reponses.length})',
                      style: const TextStyle(color: Colors.blue),
                    ),
                  ),
              ],
            ),
            // Champ de réponse
            if (showReplyField)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: reponseController,
                        decoration: InputDecoration(
                          hintText: 'Écrire une réponse...',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10),
                        ),
                        onChanged: (value) {
                          avis['reponseText'] = value;
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: () {
                        if (reponseController.text.isNotEmpty) {
                          addReponse(avis['idavis'], reponseController.text);
                        }
                      },
                    ),
                  ],
                ),
              ),
            // Affichage des réponses
            if (isExpanded && reponses.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 16.0, top: 8.0),
                child: Column(
                  children: reponses.map((reponse) {
                    final reponseMap = reponse is Map<String, dynamic>
                        ? reponse
                        : Map<String, dynamic>.from(reponse as Map);
                    return _buildReponseItem(reponseMap);
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReponseItem(dynamic reponse) {
    final reponseMap = reponse is Map<String, dynamic>
        ? reponse
        : Map<String, dynamic>.from(reponse as Map);

    final userInfo = reponseMap['user'] as Map<String, dynamic>? ?? {};
    final prenom = userInfo['prenom'] ?? 'Anonyme';
    final nom = userInfo['nom'] ?? '';
    final userName = nom.isEmpty ? prenom : '$prenom $nom';
    final userPhoto = userInfo['profile_photo'];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: Colors.grey[100],
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: userPhoto != null
                      ? NetworkImage(userPhoto as String)
                      : const AssetImage('assets/images/profile.jpg') as ImageProvider,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(
                            DateTime.parse(reponseMap['date'].toString())
                        ),
                        style: TextStyle(color: Colors.grey, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 40.0),
              child: Text(reponseMap['reponse']?.toString() ?? ''),
            ),
          ],
        ),
      ),
    );
  }

  void _showAvisOptions(BuildContext context, Map<String, dynamic> avis) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('Voir le profil'),
                  onTap: () {
                    Navigator.pop(context); // Fermer la fenêtre
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserProfilePage(userId: avis['user_id']),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.flag),
                  title: const Text('Signaler l\'avis'),
                  onTap: () async {
                    Navigator.pop(context);
                    if (avis['idavis'] != null) {
                      await _signalerAvis(avis['idavis']);
                    } else {
                      print('Erreur : idavis est null ou invalide.');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Impossible de signaler cet avis.'),
                          duration: Duration(seconds: 3),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _signalerAvis(int idAvis) async {
    try {
      final response = await Supabase.instance.client
          .from('avis')
          .update({'issignale' : true})
          .eq('idavis', idAvis);

      print('Réponse Supabase : $response');

      if (response != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Avis signalé avec succès !'),
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        print('Aucune réponse de Supabase.');
      }
    } catch (e) {
      print('Erreur lors du signalement de l\'avis : $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Une erreur est survenue lors du signalement.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
}