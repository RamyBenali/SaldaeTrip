import 'dart:ui';

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
  final PageController _pageController = PageController(viewportFraction: 0.9);
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
      final response = await supabase
          .from('avis_avec_utilisateur')
          .select('*')
          .eq('idoffre', widget.offre.id)
          .order('idavis', ascending: false);

      if (response != null) {
        setState(() {
          avisList = List<Map<String, dynamic>>.from(response);
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
    checkIfFavori(widget.offre.id);
    fetchAvis();
    incrementVisites();
    isFreeOffre();
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
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          _buildImageCarousel(),

          // Overlay sombre
          Positioned.fill(
            child: IgnorePointer( // Important: désactive les gestes pour l'overlay
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                    stops: [0.0, 0.5],
                  ),
                ),
              ),
            ),
          ),

          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(height: 450),
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
                            Colors.white.withOpacity(0.4),
                            Colors.white.withOpacity(1.0),
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
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        offre.nom,
                                        style: const TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
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
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
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
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[700],
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
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.blue[800],
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
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.5,
                              color: Colors.black87,
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
                                      style: GoogleFonts.roboto(
                                        color: Colors.grey,
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
                                            icon: const Icon(Icons.image, color: Color(0xFF2864B5)),
                                            label: Text(
                                              "Ajouter une photo",
                                              style: GoogleFonts.roboto(
                                                color: Color(0xFF2864B5),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          const Spacer(),
                                          ElevatedButton(
                                            onPressed: isPublishing ? null : publishAvis,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Color(0xFF2864B5),
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
                                              style: GoogleFonts.roboto(
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

          Positioned(
            top: 50,
            right: 20,
            child: _buildFavoriteButton(),
          ),

          Positioned(
            top: 50,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
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
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: MediaQuery.of(context).size.height * 0.75,
      child: Listener(
        onPointerDown: (_) => print("Carousel touched"), // Debug
        behavior: HitTestBehavior.translucent,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Image.network(
              widget.offre.images[_currentPage],
              height: MediaQuery.of(context).size.height * 0.75,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),

            // Bouton précédent
            if (widget.offre.images.length > 1)
              Positioned(
                left: 10,
                top: 0,
                bottom: 0,
                child: Center(
                  child: RawMaterialButton(
                    onPressed: () {
                      print("Previous button pressed");
                      _goToPreviousImage();
                    },
                    elevation: 0,
                    fillColor: Colors.black.withOpacity(0.3),
                    shape: CircleBorder(),
                    child: Icon(Icons.chevron_left, color: Colors.white),
                  ),
                ),
              ),

            // Bouton suivant
            if (widget.offre.images.length > 1)
              Positioned(
                right: 10,
                top: 0,
                bottom: 0,
                child: Center(
                  child: RawMaterialButton(
                    onPressed: () {
                      print("Next button pressed");
                      _goToNextImage();
                    },
                    elevation: 0,
                    fillColor: Colors.black.withOpacity(0.3),
                    shape: CircleBorder(),
                    child: Icon(Icons.chevron_right, color: Colors.white),
                  ),
                ),
              ),

            // Indicateurs
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.offre.images.length,
                      (index) => GestureDetector(
                    onTap: () {
                      print("Dot $index pressed");
                      setState(() => _currentPage = index);
                    },
                    child: Container(
                      width: 8,
                      height: 8,
                      margin: EdgeInsets.symmetric(horizontal: 4),
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
    print("suivant");
    if (widget.offre.images.isEmpty) return;
    setState(() {
      _currentPage = (_currentPage + 1) % widget.offre.images.length;
    });
  }

  void _goToPreviousImage() {
    if (widget.offre.images.isEmpty) return;
    print("suivant");
    setState(() {
      _currentPage = _currentPage == 0
          ? widget.offre.images.length - 1
          : _currentPage - 1;
    });
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
        color: const Color(0xFF2864B5).withOpacity(1),
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
          child: const Center(
            child: Text(
              'Localiser',
              style: TextStyle(
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
          style: GoogleFonts.roboto(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
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

      // Méthode recommandée pour Flutter 3.x+
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

  Widget _buildAvisList() {
    if (avisList.isEmpty) {
      return Center(
        child: Text(
          'Aucun avis pour le moment',
          style: GoogleFonts.poppins(color: Colors.grey),
        ),
      );
    }

    return Column(
      children: avisList.map((avis) => _buildAvisCard(avis)).toList(),
    );
  }

  Widget _buildAvisCard(Map<String, dynamic> avis) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: avis['profile_photo'] != null
                      ? NetworkImage(avis['profile_photo'] as String)
                      : AssetImage('assets/default_avatar.png') as ImageProvider,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${avis['prenom'] ?? 'Anonyme'} ${avis['nom'] ?? ''}',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
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
            SizedBox(height: 12),
            Text(
              avis['commentaire'] ?? 'Pas de commentaire',
              style: GoogleFonts.poppins(),
            ),
            if (avis['image'] != null) ...[
              SizedBox(height: 12),
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
          ],
        ),
      ),
    );
  }
}

class _NavigationButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _NavigationButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onPressed,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 30),
        ),
      ),
    );
  }
}

class _DotsIndicator extends StatelessWidget {
  final int count;
  final int currentIndex;
  final ValueChanged<int> onDotTap;

  const _DotsIndicator({
    required this.count,
    required this.currentIndex,
    required this.onDotTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        return GestureDetector(
          onTap: () => onDotTap(index),
          child: Container(
            width: 10,
            height: 10,
            margin: EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: currentIndex == index
                  ? Colors.white
                  : Colors.white.withOpacity(0.5),
            ),
          ),
        );
      }),
    );
  }
}