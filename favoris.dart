import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'dart:ui';

import 'GlovalColors.dart';
import 'login.dart';
import 'map.dart';
import 'models/offre_model.dart';
import 'offre_details.dart';
import 'offre_page.dart';
import 'profile.dart';
import 'weather_main.dart';

class FavorisPage extends StatefulWidget {
  @override
  _FavorisPageState createState() => _FavorisPageState();
}

class _FavorisPageState extends State<FavorisPage>
    with SingleTickerProviderStateMixin {
  final Color bleuTurquoise = Color(0xFF41A6B4);
  int _selectedIndex = 2;
  bool isLoading = true;
  String searchQuery = '';
  String? selectedCategorie;
  int? selectedRating;
  double? selectedTarifMax;
  bool isAnonymous = false;
  List<Offre> favoris = [];
  List<Offre> filteredFavoris = [];

  late AnimationController _animationController;

  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _fetchFavoris();

    _animationController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchFavoris() async {
    final user = _supabase.auth.currentUser;
    if (user?.isAnonymous == true) {
      setState(() {
        isAnonymous = true;
        isLoading = false;
      });
      return;
    }

    try {
      if (user == null) {
        setState(() {
          favoris = [];
          isLoading = false;
        });
        return;
      }

      final favorisResponse = await _supabase
          .from('ajouterfavoris')
          .select('''
        offre(
          idoffre, 
          nom, 
          categorie, 
          tarifs, 
          description, 
          adresse, 
          image,
          avis:avis(note)
        )
      ''')
          .eq('user_id', user.id);

      final data = favorisResponse as List;

      setState(() {
        favoris =
            data.map((item) {
              final offreData = item['offre'];
              final avisList =
                  (offreData['avis'] as List).cast<Map<String, dynamic>>();

              double? noteMoyenne;
              if (avisList.isNotEmpty) {
                final total = avisList.fold(
                  0.0,
                  (sum, avis) => sum + (avis['note'] as num),
                );
                noteMoyenne = total / avisList.length;
              }

              final jsonData = {...offreData, 'note_moyenne': noteMoyenne};
              return Offre.fromJson(Map<String, dynamic>.from(jsonData));
            }).toList();

        filteredFavoris = List.from(favoris);
        isLoading = false;
      });
    } catch (e) {
      print('Erreur lors de la récupération des favoris : $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void applyFilters() {
    setState(() {
      filteredFavoris =
          favoris.where((offre) {
            bool matchCategorie =
                selectedCategorie == null ||
                offre.categorie == selectedCategorie;
            bool matchRating =
                selectedRating == null ||
                (offre.noteMoyenne) >= selectedRating!;
            bool matchTarif =
                selectedTarifMax == null ||
                (() {
                  final regex = RegExp(r'(\d+)(?=\s*-|\s*D|\s*da|\s*$)');
                  final match = regex.firstMatch(offre.tarifs);
                  if (match == null) return true;
                  final firstNumber = int.tryParse(match.group(0) ?? '0') ?? 0;
                  return firstNumber <= selectedTarifMax!;
                })();

            return matchCategorie && matchRating && matchTarif;
          }).toList();
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MapScreen()),
        );
        break;
      case 2:
        return;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ProfilePage()),
        );
        break;
      default:
        return;
    }
  }

  Future<void> _toggleFavorite(Offre offre) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    setState(() {
      favoris.removeWhere((item) => item.id == offre.id);
      filteredFavoris.removeWhere((item) => item.id == offre.id);
    });

    try {
      await _supabase
          .from('ajouterfavoris')
          .delete()
          .eq('user_id', user.id)
          .eq('offre_id', offre.id);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Retiré des favoris'),
          backgroundColor: GlobalColors.pinkColor,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          action: SnackBarAction(
            label: 'Annuler',
            textColor: Colors.white,
            onPressed: () {
              _fetchFavoris();
            },
          ),
        ),
      );
    } catch (e) {
      print('Erreur lors de la suppression du favori: $e');
      _fetchFavoris();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredOffres =
        filteredFavoris.where((offre) {
          final query = searchQuery.toLowerCase();
          return offre.nom.toLowerCase().contains(query) ||
              offre.categorie.toLowerCase().contains(query) ||
              offre.adresse.toLowerCase().contains(query);
        }).toList();

    return Scaffold(
      backgroundColor: GlobalColors.primaryColor,
      extendBody: true,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            stretch: true,
            elevation: 0,
            backgroundColor: GlobalColors.blueColor,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: EdgeInsets.only(left: 20, bottom: 16),
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.favorite, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Mes Favoris',
                    style: GoogleFonts.poppins(
                      textStyle: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      GlobalColors.darkBlueColor,
                      GlobalColors.blueColor,
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -30,
                      top: -20,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                    Positioned(
                      left: -20,
                      bottom: -50,
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.08),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            automaticallyImplyLeading: false,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Container(
                decoration: BoxDecoration(
                  color: GlobalColors.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.all(4),
                  child: TextField(
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: GlobalColors.blueColor,
                      ),
                      suffixIcon: GestureDetector(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => _buildRatingFilter(),
                          );
                        },
                        child: Container(
                          margin: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: GlobalColors.blueColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.filter_list_rounded,
                            color: GlobalColors.blueColor,
                          ),
                        ),
                      ),
                      hintText: 'Rechercher...',
                      hintStyle: TextStyle(color: GlobalColors.accentColor),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                  ),
                ),
              ),
            ),
          ),
          if (selectedCategorie != null ||
              selectedRating != null ||
              selectedTarifMax != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      if (selectedCategorie != null)
                        _buildFilterChip(
                          label: selectedCategorie!,
                          icon: Icons.category_rounded,
                          onTap: () {
                            setState(() {
                              selectedCategorie = null;
                              applyFilters();
                            });
                          },
                        ),
                      if (selectedRating != null)
                        _buildFilterChip(
                          label: '$selectedRating+ étoiles',
                          icon: Icons.star_rounded,
                          onTap: () {
                            setState(() {
                              selectedRating = null;
                              applyFilters();
                            });
                          },
                        ),
                      if (selectedTarifMax != null)
                        _buildFilterChip(
                          label: '${selectedTarifMax!.toInt()} DA Max',
                          icon: Icons.payments_rounded,
                          onTap: () {
                            setState(() {
                              selectedTarifMax = null;
                              applyFilters();
                            });
                          },
                        ),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            selectedCategorie = null;
                            selectedRating = null;
                            selectedTarifMax = null;
                            applyFilters();
                          });
                        },
                        icon: Icon(Icons.clear_all_rounded, size: 16),
                        label: Text('Effacer tout'),
                        style: TextButton.styleFrom(
                          foregroundColor: GlobalColors.accentColor,
                          textStyle: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (isLoading)
            SliverFillRemaining(child: _buildLoadingShimmer())
          else if (isAnonymous)
            SliverFillRemaining(child: _buildAnonymousContent())
          else if (filteredOffres.isEmpty)
            SliverFillRemaining(child: _buildEmptyFavorites())
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 90),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) =>
                      _buildFavoriteCard(filteredOffres[index], index),
                  childCount: filteredOffres.length,
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: EdgeInsets.only(right: 8),
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8),
        child: Material(
          color: GlobalColors.blueColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(30),
          child: InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 16, color: GlobalColors.blueColor),
                  SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: GlobalColors.blueColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.close, size: 16, color: GlobalColors.blueColor),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor:
          GlobalColors.isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
      highlightColor:
          GlobalColors.isDarkMode ? Colors.grey[600]! : Colors.grey[100]!,
      child: ListView.builder(
        padding: EdgeInsets.only(bottom: 90),
        itemCount: 6,
        itemBuilder:
            (_, __) => Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: GlobalColors.cardColor,
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildAnonymousContent() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: 100, top: 32, left: 16, right: 16),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.network(
                'https://assets8.lottiefiles.com/packages/lf20_t24tpvcu.json',
                width: 150,
                height: 150,
              ),
              SizedBox(height: 20),
              Text(
                'Connectez-vous pour accéder\nà vos favoris',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  textStyle: TextStyle(
                    fontSize: 18,
                    color: GlobalColors.secondaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  );
                },
                icon: Icon(Icons.login_rounded),
                label: Text('Se connecter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: GlobalColors.blueColor,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyFavorites() {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.network(
                'https://assets3.lottiefiles.com/private_files/lf30_cgfdhxgx.json',
                width: 180,
                height: 180,
              ),
              SizedBox(height: 16),
              Text(
                'Aucun favori trouvé',
                style: GoogleFonts.poppins(
                  textStyle: TextStyle(
                    fontSize: 20,
                    color: GlobalColors.secondaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 8),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Ajoutez des offres à vos favoris pour les retrouver facilement',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: GlobalColors.accentColor,
                    fontSize: 14,
                  ),
                ),
              ),
              SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => OffresPage()),
                  );
                },
                icon: Icon(Icons.explore_rounded),
                label: Text('Explorer les offres'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: GlobalColors.blueColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFavoriteCard(Offre offre, int index) {
    return Hero(
      tag: 'offre-${offre.id}',
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: GlobalColors.cardColor,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OffreDetailPage(offre: offre),
                ),
              );
            },
            child: Container(
              padding: EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CachedNetworkImage(
                          imageUrl: offre.image,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          placeholder:
                              (context, url) => Container(
                                color:
                                    GlobalColors.isDarkMode
                                        ? Colors.grey[800]
                                        : Colors.grey[300],
                                child: Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        GlobalColors.blueColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          errorWidget:
                              (context, url, error) => Container(
                                width: 100,
                                height: 100,
                                color:
                                    GlobalColors.isDarkMode
                                        ? Colors.grey[800]
                                        : Colors.grey[200],
                                child: Icon(
                                  Icons.image_not_supported_rounded,
                                  color: GlobalColors.accentColor,
                                ),
                              ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.7),
                              ],
                            ),
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(16),
                              bottomRight: Radius.circular(16),
                            ),
                          ),
                          padding: EdgeInsets.all(8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _getCategoryIcon(offre.categorie),
                                color: Colors.white,
                                size: 12,
                              ),
                              SizedBox(width: 4),
                              Text(
                                offre.categorie,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                offre.nom,
                                style: GoogleFonts.poppins(
                                  textStyle: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: GlobalColors.secondaryColor,
                                  ),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: GlobalColors.pinkColor.withOpacity(0.1),
                              ),
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: Icon(
                                  Icons.favorite_rounded,
                                  color: GlobalColors.pinkColor,
                                  size: 20,
                                ),
                                onPressed: () => _toggleFavorite(offre),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 6),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: GlobalColors.greenColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.paid_rounded,
                                size: 14,
                                color: GlobalColors.greenColor,
                              ),
                              SizedBox(width: 4),
                              Text(
                                offre.tarifs,
                                style: TextStyle(
                                  color: GlobalColors.greenColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ...[
                          SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.star_rounded,
                                size: 14,
                                color: GlobalColors.amberColor,
                              ),
                              SizedBox(width: 4),
                              Text(
                                offre.noteMoyenne.toStringAsFixed(1),
                                style: TextStyle(
                                  color: GlobalColors.secondaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              SizedBox(width: 4),
                              Text(
                                '(${(offre.noteMoyenne * 2).round() / 2})',
                                style: TextStyle(
                                  color: GlobalColors.accentColor,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.place_rounded,
                              size: 14,
                              color: GlobalColors.blueColor,
                            ),
                            SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                offre.adresse,
                                style: TextStyle(
                                  color: GlobalColors.accentColor,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) =>
                                            OffreDetailPage(offre: offre),
                                  ),
                                );
                              },
                              icon: Icon(Icons.visibility_rounded, size: 16),
                              label: Text('Voir détails'),
                              style: TextButton.styleFrom(
                                foregroundColor: GlobalColors.blueColor,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                textStyle: TextStyle(
                                  fontSize: 12,
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
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow:
              GlobalColors.isDarkMode
                  ? []
                  : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: Container(
              height: 65,
              padding: EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color:
                    GlobalColors.isDarkMode
                        ? GlobalColors.accentColor.withOpacity(0.2)
                        : GlobalColors.primaryColor.withOpacity(0.9),
                border:
                    GlobalColors.isDarkMode
                        ? Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        )
                        : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(Icons.home_rounded, 'Accueil', 0),
                  _buildNavItem(Icons.map_rounded, 'Carte', 1),
                  _buildNavItem(Icons.favorite_rounded, 'Favoris', 2),
                  _buildNavItem(Icons.person_rounded, 'Profil', 3),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    bool isSelected = _selectedIndex == index;
    Color selectedColor =
        GlobalColors.isDarkMode ? bleuTurquoise : bleuTurquoise;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color:
              isSelected
                  ? (GlobalColors.isDarkMode
                      ? bleuTurquoise.withOpacity(0.2)
                      : bleuTurquoise.withOpacity(0.1))
                  : Colors.transparent,
        ),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color:
                    isSelected
                        ? selectedColor
                        : (GlobalColors.isDarkMode
                            ? Colors.grey.shade400
                            : Colors.grey),
                size: isSelected ? 26 : 24,
              ),
              if (isSelected) ...[
                SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: selectedColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    final Map<String, IconData> categoryIcons = {
      'Restaurant': Icons.restaurant_rounded,
      'Hôtel': Icons.hotel_rounded,
      'Café': Icons.local_cafe_rounded,
      'Centre commercial': Icons.shopping_cart_rounded,
      'Attraction': Icons.attractions_rounded,
      'Plage': Icons.beach_access_rounded,
      'Sport': Icons.sports_rounded,
      'Art': Icons.palette_rounded,
      'Musée': Icons.museum_rounded,
    };

    return categoryIcons[category] ?? Icons.place_rounded;
  }

  Widget _buildRatingFilter() {
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setModalState) {
        return Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: GlobalColors.cardColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filtrer les favoris',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: GlobalColors.secondaryColor,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Note minimale',
                style: TextStyle(
                  fontSize: 14,
                  color: GlobalColors.accentColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(5, (index) {
                  final rating = index + 1;
                  return GestureDetector(
                    onTap: () {
                      setModalState(() {
                        selectedRating =
                            selectedRating == rating ? null : rating;
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color:
                            selectedRating != null && rating <= selectedRating!
                                ? Colors.amber.withOpacity(0.2)
                                : GlobalColors.primaryColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              selectedRating != null &&
                                      rating <= selectedRating!
                                  ? Colors.amber
                                  : GlobalColors.accentColor,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.star_rounded,
                            color:
                                selectedRating != null &&
                                        rating <= selectedRating!
                                    ? Colors.amber
                                    : GlobalColors.accentColor,
                            size: 20,
                          ),
                          if (rating == 5) ...[
                            SizedBox(width: 4),
                            Text(
                              '+',
                              style: TextStyle(
                                color:
                                    selectedRating != null &&
                                            rating <= selectedRating!
                                        ? Colors.amber
                                        : GlobalColors.accentColor,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
              ),
              SizedBox(height: 20),
              Text(
                'Tarif maximum (DA)',
                style: TextStyle(
                  fontSize: 14,
                  color: GlobalColors.accentColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              Slider(
                value: selectedTarifMax ?? 5000,
                min: 500,
                max: 10000,
                divisions: 19,
                activeColor: GlobalColors.blueColor,
                inactiveColor: GlobalColors.blueColor.withOpacity(0.2),
                label: '${(selectedTarifMax ?? 5000).round()} DA',
                onChanged: (value) {
                  setModalState(() {
                    selectedTarifMax = value;
                  });
                },
              ),
              SizedBox(height: 20),
              Text(
                'Catégorie',
                style: TextStyle(
                  fontSize: 14,
                  color: GlobalColors.accentColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    [
                      'Restaurant',
                      'Hôtel',
                      'Café',
                      'Centre commercial',
                      'Attraction',
                    ].map((category) {
                      return FilterChip(
                        label: Text(category),
                        selected: selectedCategorie == category,
                        onSelected: (selected) {
                          setModalState(() {
                            selectedCategorie = selected ? category : null;
                          });
                        },
                        selectedColor: GlobalColors.blueColor.withOpacity(0.2),
                        backgroundColor: GlobalColors.primaryColor,
                        checkmarkColor: GlobalColors.blueColor,
                        labelStyle: TextStyle(
                          color:
                              selectedCategorie == category
                                  ? GlobalColors.blueColor
                                  : GlobalColors.secondaryColor,
                        ),
                      );
                    }).toList(),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      setModalState(() {
                        selectedRating = null;
                        selectedTarifMax = null;
                        selectedCategorie = null;
                      });
                    },
                    child: Text('Réinitialiser', style: TextStyle(color: GlobalColors.secondaryColor),),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      applyFilters();
                      Navigator.pop(context);
                    },
                    child: Text('Appliquer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GlobalColors.blueColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
