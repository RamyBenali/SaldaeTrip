import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile.dart';
import 'weather_main.dart';
import 'favoris.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://xqbnjwedfurajossjgof.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhxYm5qd2VkZnVyYWpvc3NqZ29mIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDM2MTQzMDYsImV4cCI6MjA1OTE5MDMwNn0._1LKV9UaV-tsOt9wCwcD8Xp_WvXrumlp0Jv0az9rgp4',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'OSM Map - Béjaïa',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MapScreen(),
    );
  }
}

class Place {
  final String name;
  final String description;
  final String category;
  final String? image;
  final double latitude;
  final double longitude;

  Place({
    required this.name,
    required this.description,
    required this.category,
    this.image,
    required this.latitude,
    required this.longitude,
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      name: json['nom'] ?? json['name'] ?? '',
      description: json['description'] ?? '',
      category: json['categorie'] ?? json['category'] ?? 'other',
      image: json['image'],
      latitude: double.parse(json['latitude'].toString()),
      longitude: double.parse(json['longitude'].toString()),
    );
  }
}

class MapScreen extends StatefulWidget {
  final LatLng? initialLocation;
  final String? markerTitle;

  const MapScreen({super.key, this.initialLocation, this.markerTitle});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  bool _isLoadingMap = true;
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  int _selectedIndex = 1;
  bool _isLoadingLocation = false;
  String _locationError = '';
  LatLng? _currentLocation;
  double? _accuracy;
  late AnimationController _pulseAnimationController;
  late Animation<double> _pulseAnimation;
  late AnimationController _routeAnimationController;
  late Animation<double> _routeAnimation;
  bool _isSearching = false;
  List<Map<String, dynamic>> _searchResults = [];
  LatLng? _searchedLocation;
  List<LatLng> _routePoints = [];
  List<LatLng> _animatedRoutePoints = [];
  bool _showRoute = false;
  List<Place> _places = [];
  bool _isLoadingPlaces = false;
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isPanelOpen = false;
  Set<String> _selectedCategories = {};
  final _panelController = ScrollController();
  List<Place> _filteredPlaces = [];

  // Béjaïa boundaries
  static const double minLat = 36.5;
  static const double maxLat = 36.9;
  static const double minLon = 4.8;
  static const double maxLon = 5.3;

  @override
  void initState() {
    super.initState();
    _initLocation();
    _loadPlacesFromSupabase();

    // Pulse animation for location markers
    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(
        parent: _pulseAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // Route drawing animation
    _routeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _routeAnimation = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _routeAnimationController,
        curve: Curves.easeInOut,
      ),
    )..addListener(() {
      _updateAnimatedRoute();
    });

    if (widget.initialLocation != null) {
      _searchedLocation = widget.initialLocation;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(widget.initialLocation!, 15.0);
      });
    }

    _searchFocusNode.addListener(() {
      if (!_searchFocusNode.hasFocus) {
        setState(() {
          _searchResults.clear();
        });
      }
    });
  }

  Future<void> _initLocation() async {
    setState(() {
      _isLoadingMap = true;
    });

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _accuracy = position.accuracy;
      });

      if (widget.initialLocation == null) {
        _mapController.move(_currentLocation!, 15.0);
      }
    } catch (e) {
      setState(() {
        _locationError = 'Erreur de localisation : $e';
      });
    } finally {
      setState(() {
        _isLoadingMap = false;
      });
    }
  }

  Future<void> _loadPlacesFromSupabase() async {
    if (!mounted) return;

    setState(() => _isLoadingPlaces = true);

    try {
      final List<dynamic> data = await _supabase.from('offre').select(''' 
        nom, 
        description, 
        categorie, 
        image, 
        latitude, 
        longitude
      ''');

      if (!mounted) return;

      setState(() {
        // Convertir les données JSON en objets Place
        _places = data.map((json) => Place.fromJson(json)).toList();

        // Initialiser les lieux filtrés avec tous les lieux
        _filteredPlaces = List<Place>.from(_places);

        // Récupérer toutes les catégories uniques et les sélectionner par défaut
        _selectedCategories =
            _places
                .map((p) => p.category)
                .toSet()
                .toList()
                .whereType<String>()
                .toSet();

        // Trier les lieux par nom pour une meilleure organisation
        _places.sort((a, b) => a.name.compareTo(b.name));
        _filteredPlaces.sort((a, b) => a.name.compareTo(b.name));
      });

      // Vérifier si des catégories ont été trouvées
      if (_selectedCategories.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Aucune catégorie trouvée'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } on PostgrestException catch (e) {
      if (!mounted) return;
      _showError('Erreur Supabase: ${e.message}');
    } on SocketException catch (_) {
      if (!mounted) return;
      _showError('Erreur de connexion internet');
    } on TimeoutException catch (_) {
      if (!mounted) return;
      _showError('La requête a expiré');
    } catch (e) {
      if (!mounted) return;
      _showError('Erreur inattendue: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoadingPlaces = false);
      }
    }
  }

  void _filterPlaces() {
    setState(() {
      if (_selectedCategories.isEmpty) {
        _filteredPlaces = [];
      } else {
        _filteredPlaces =
            _places
                .where((place) => _selectedCategories.contains(place.category))
                .toList();
      }
    });
  }

  void _toggleCategory(String category) {
    setState(() {
      if (_selectedCategories.contains(category)) {
        _selectedCategories.remove(category);
      } else {
        _selectedCategories.add(category);
      }
      _filterPlaces();
    });
  }

  void _togglePanel() {
    setState(() {
      _isPanelOpen = !_isPanelOpen;
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[400],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  IconData _getIconForCategory(String category) {
    switch (category.toLowerCase()) {
      // Nourriture
      case 'restaurant':
        return FontAwesomeIcons
            .utensils; // Plus élégant que l'icône restaurant basique
      case 'pizzeria':
        return FontAwesomeIcons
            .pizzaSlice; // Icône spécifique pour les pizzerias
      case 'café':
      case 'cafe':
        return FontAwesomeIcons.mugHot; // Parfait pour les cafés

      // Hébergement
      case 'hôtel':
      case 'hotel':
        return FontAwesomeIcons.hotel; // Icône moderne d'hôtel
      case 'auberge':
        return FontAwesomeIcons.houseChimney; // Pour les petites auberges

      // Loisirs
      case 'loisirs':
        return FontAwesomeIcons.gamepad; // Icône générique pour les loisirs
      case 'cinéma':
        return FontAwesomeIcons.film;
      case 'bowling':
        return FontAwesomeIcons.bowlingBall;

      // Points d'intérêt
      case 'point dintérêt':
      case 'point d\'intérêt':
        return FontAwesomeIcons.binoculars; // Symbole d'exploration
      case 'point dintérêt historique':
      case 'point d\'intérêt historique':
        return FontAwesomeIcons.landmark; // Parfait pour les sites historiques
      case 'monument':
        return FontAwesomeIcons.monument;

      // Plages et nature
      case 'plage':
      case 'beach':
        return FontAwesomeIcons.umbrellaBeach; // Icône moderne de plage
      case 'parc':
      case 'park':
        return FontAwesomeIcons.tree; // Plus nature que l'icône park basique
      case 'jardin':
        return FontAwesomeIcons.leaf;

      // Shopping
      case 'shop':
      case 'magasin':
        return FontAwesomeIcons.bagShopping; // Plus moderne que shopping-cart
      case 'centre commercial':
        return FontAwesomeIcons.shop;

      // Santé
      case 'hôpital':
      case 'hospital':
        return FontAwesomeIcons.hospital; // Icône plus reconnaissable
      case 'pharmacie':
        return FontAwesomeIcons.pills;

      // Transport
      case 'gare':
        return FontAwesomeIcons.train;
      case 'aéroport':
        return FontAwesomeIcons.plane;

      default:
        return FontAwesomeIcons.locationDot;
    }
  }

  Color _getColorForCategory(String category) {
    final String lowerCategory = category.toLowerCase();

    const Color restaurantColor = Color(0xFFE53935); // Rouge vif
    const Color pizzeriaColor = Color(0xFFD81B60); // Rose foncé
    const Color hotelColor = Color(0xFF1E88E5); // Bleu professionnel
    const Color loisirsColor = Color(0xFF8E24AA); // Violet
    const Color pointInteretColor = Color(0xFFF4511E); // Orange vif
    const Color historiqueColor = Color(0xFF795548); // Brun terre
    const Color plageColor = Color(0xFFFFB300); // Jaune doré
    const Color parcColor = Color(0xFF43A047); // Vert nature
    const Color shopColor = Color(0xFFFB8C00); // Orange chaud
    const Color defaultColor = Color(0xFF757575); // Gris neutre

    switch (lowerCategory) {
      // Nourriture
      case 'restaurant':
        return restaurantColor;
      case 'pizzeria':
        return pizzeriaColor;
      case 'café':
      case 'cafe':
        return const Color(0xFF6D4C41); // Brun café

      // Hébergement
      case 'hôtel':
      case 'hotel':
        return hotelColor;
      case 'auberge':
        return const Color(0xFF5E35B1); // Violet profond

      // Loisirs
      case 'loisirs':
        return loisirsColor;
      case 'cinéma':
        return const Color(0xFF3949AB); // Bleu nuit
      case 'bowling':
        return const Color(0xFF00897B); // Teal

      case 'point dintérêt':
      case 'point d\'intérêt':
        return pointInteretColor;
      case 'point dintérêt historique':
      case 'point d\'intérêt historique':
        return historiqueColor;
      case 'monument':
        return const Color(0xFF6D4C41);

      case 'plage':
      case 'beach':
        return plageColor;
      case 'parc':
      case 'park':
        return parcColor;
      case 'jardin':
        return const Color(0xFF7CB342); // Vert clair

      case 'shop':
      case 'magasin':
        return shopColor;
      case 'centre commercial':
        return const Color(0xFFE040FB); // Violet fluo

      case 'hôpital':
      case 'hospital':
        return const Color(0xFFD32F2F); // Rouge foncé
      case 'pharmacie':
        return const Color(0xFF00ACC1); // Cyan

      case 'gare':
        return const Color(0xFF5C6BC0); // Bleu indigo
      case 'aéroport':
        return const Color(0xFF039BE5); // Bleu ciel

      default:
        return defaultColor;
    }
  }

  Widget _buildSidePanel() {
    final allCategories = _places.map((p) => p.category).toSet().toList();
    allCategories.sort();

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      left: 0,
      right: 0,
      top:
          _isPanelOpen
              ? MediaQuery.of(context).size.height * 0.1
              : -MediaQuery.of(context).size.height,
      child: Center(
        child: Material(
          elevation: 24,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            constraints: BoxConstraints(
              maxHeight:
                  MediaQuery.of(context).size.height *
                  0.75, // Augmenté légèrement
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header avec plus de marge en bas
                Container(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    16,
                    16,
                    16,
                  ), // Marge ajustée
                  decoration: BoxDecoration(
                    color: Colors.blue[700],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filtrer les lieux',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: _togglePanel,
                        padding: EdgeInsets.zero, // Réduit le padding
                      ),
                    ],
                  ),
                ),

                // Ajout d'un espace avant la liste
                const SizedBox(height: 8),

                // Categories List avec marge ajustée
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                    ), // Marge horizontale augmentée
                    itemCount: allCategories.length,
                    itemBuilder: (context, index) {
                      final category = allCategories[index];
                      final isSelected = _selectedCategories.contains(category);
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 8,
                        ), // Marge verticale réduite
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? _getColorForCategory(
                                      category,
                                    ).withOpacity(0.1)
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                            ), // Padding interne ajusté
                            leading: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color:
                                    isSelected
                                        ? _getColorForCategory(category)
                                        : Colors.grey[200],
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _getIconForCategory(category),
                                size: 20,
                                color:
                                    isSelected
                                        ? Colors.white
                                        : Colors.grey[700],
                              ),
                            ),
                            title: Text(
                              category,
                              style: TextStyle(
                                fontSize:
                                    15, // Taille de police légèrement réduite
                              ),
                            ),
                            trailing:
                                isSelected
                                    ? const Icon(
                                      Icons.check,
                                      color: Colors.green,
                                      size: 22,
                                    )
                                    : null,
                            onTap: () => _toggleCategory(category),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Action Buttons avec marge ajustée
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    12,
                    20,
                    20,
                  ), // Marge supérieure réduite
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue[700],
                            side: BorderSide(color: Colors.blue[700]!),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                            ), // Hauteur de bouton augmentée
                          ),
                          child: const Text('Tout sélectionner'),
                          onPressed: () {
                            setState(() {
                              _selectedCategories = allCategories.toSet();
                              _filterPlaces();
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12), // Espacement augmenté
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white, // Fond blanc
                            foregroundColor: Colors.blue[700], // Texte bleu
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: Colors.blue[700]!, // Bordure bleue
                                width: 1.5,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 2, // Légère ombre
                          ),
                          child: const Text(
                            'Appliquer',
                            style: TextStyle(
                              fontWeight:
                                  FontWeight.w600, // Texte légèrement gras
                            ),
                          ),
                          onPressed: _togglePanel,
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
    );
  }

  Widget _buildPlacesMarkers() {
    return MarkerLayer(
      markers:
          _filteredPlaces.map((place) {
            return Marker(
              point: LatLng(place.latitude, place.longitude),
              width: 50.0,
              height: 50.0,
              child: GestureDetector(
                onTap: () => _showPlaceDetails(place),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 6.0,
                        spreadRadius: 1.0,
                      ),
                    ],
                    border: Border.all(
                      color: _getColorForCategory(place.category),
                      width: 2.0,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Pulsing effect background
                      if (_selectedIndex == 1) // Only animate when on map tab
                        AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _pulseAnimation.value * 0.8,
                              child: Container(
                                width: 30.0,
                                height: 30.0,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _getColorForCategory(
                                    place.category,
                                  ).withOpacity(0.2),
                                ),
                              ),
                            );
                          },
                        ),
                      // Main icon
                      Icon(
                        _getIconForCategory(place.category),
                        color: _getColorForCategory(place.category),
                        size: 24.0,
                      ),
                      // Badge for special places
                      if (place.category.toLowerCase().contains('historique'))
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4.0),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.amber,
                              border: Border.all(
                                color: Colors.white,
                                width: 1.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.star,
                              color: Colors.white,
                              size: 10.0,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }

  void _showPlaceDetails(Place place) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {},
          child: Container(
            height: MediaQuery.of(context).size.height * 0.65,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(25),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle de drag
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  // Image avec effet de parallaxe
                  _buildImageSection(place),

                  // Contenu
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Titre avec animation
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            place.name,
                            key: ValueKey(place.name),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Catégorie avec badge stylisé
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getColorForCategory(
                              place.category,
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getIconForCategory(place.category),
                                color: _getColorForCategory(place.category),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                place.category,
                                style: TextStyle(
                                  color: _getColorForCategory(place.category),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Description avec effet de fondu
                        AnimatedOpacity(
                          opacity: 1,
                          duration: const Duration(milliseconds: 500),
                          child: Text(
                            place.description,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[700],
                              height: 1.5,
                            ),
                          ),
                        ),

                        const SizedBox(height: 25),

                        // Boutons avec animation scale
                        _buildActionButtons(place),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageSection(Place place) {
    return SizedBox(
      height: 200,
      child: Stack(
        children: [
          // Image de fond floutée
          if (place.image != null)
            Positioned.fill(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                child: Image.network(place.image!, fit: BoxFit.cover),
              ),
            ),

          // Image principale
          Positioned.fill(
            child:
                place.image != null
                    ? ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(25),
                      ),
                      child: Image.network(place.image!, fit: BoxFit.cover),
                    )
                    : Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(Icons.photo, size: 50, color: Colors.grey),
                      ),
                    ),
          ),

          // Overlay de dégradé
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.3), Colors.transparent],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Place place) {
    return Row(
      children: [
        // Bouton Itinéraire
        Expanded(
          child: AnimatedScale(
            scale: 1,
            duration: const Duration(milliseconds: 300),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.directions, size: 20),
              label: const Text('Itinéraire'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 2,
              ),
              onPressed: () {
                Navigator.pop(context);
                _setRouteToPlace(place);
              },
            ),
          ),
        ),

        const SizedBox(width: 15),

        // Bouton Fermer
        Expanded(
          child: AnimatedScale(
            scale: 1,
            duration: const Duration(milliseconds: 300),
            child: OutlinedButton.icon(
              icon: const Icon(Icons.map, size: 20),
              label: const Text('Voir sur carte'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Colors.blue),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onPressed: () {
                setState(() {
                  _searchedLocation = LatLng(place.latitude, place.longitude);
                });
                Navigator.pop(context);
                _mapController.move(_searchedLocation!, 15.0);
              },
            ),
          ),
        ),
      ],
    );
  }

  void _setRouteToPlace(Place place) {
    setState(() {
      _searchedLocation = LatLng(place.latitude, place.longitude);
    });
    _showRouteBetweenLocations();
  }

  void _updateAnimatedRoute() {
    if (_routePoints.isEmpty) return;

    final totalPoints = _routePoints.length;
    final animatedPointsCount = (totalPoints * _routeAnimation.value).round();

    setState(() {
      _animatedRoutePoints = _routePoints.sublist(
        0,
        animatedPointsCount.clamp(0, totalPoints),
      );
    });
  }

  @override
  void dispose() {
    _pulseAnimationController.dispose();
    _routeAnimationController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<bool> _checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _locationError = 'Les services de localisation sont désactivés';
      });

      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _locationError = '';
          });
        }
      });
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _locationError =
            'Les permissions de localisation sont définitivement refusées';
      });
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _locationError = '';
          });
        }
      });
      return false;
    }

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        setState(() {
          _locationError = 'Les permissions de localisation sont refusées';
        });
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _locationError = '';
            });
          }
        });
        return false;
      }
    }
    return true;
  }

  Future<void> _centerOnMyLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationError = '';
    });

    try {
      bool hasPermission = await _checkLocationPermission();
      if (!hasPermission) return;

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 10));

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _accuracy = position.accuracy;
        _showRoute = false;
      });

      _mapController.move(_currentLocation!, 15.0);
    } on TimeoutException {
      setState(() {
        _locationError = 'La demande de localisation a expiré';
      });
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _locationError = '';
          });
        }
      });
    } catch (e) {
      setState(() {
        _locationError = 'Erreur lors de la localisation: ${e.toString()}';
      });
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _locationError = '';
          });
        }
      });
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _searchLocation() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults.clear();
        _searchedLocation = null;
        _showRoute = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchResults.clear();
    });

    try {
      final response = await http.get(
        Uri.parse(
          'https://nominatim.openstreetmap.org/search?'
          'q=$query'
          '&format=json'
          '&limit=5'
          '&viewbox=$minLon,$minLat,$maxLon,$maxLat'
          '&bounded=1',
        ),
        headers: {'User-Agent': 'YourAppName/1.0'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _searchResults =
              data
                  .map(
                    (item) => {
                      'name': item['display_name'],
                      'lat': double.parse(item['lat']),
                      'lon': double.parse(item['lon']),
                    },
                  )
                  .where((result) {
                    final lat = result['lat'];
                    final lon = result['lon'];
                    return lat >= minLat &&
                        lat <= maxLat &&
                        lon >= minLon &&
                        lon <= maxLon;
                  })
                  .toList();
        });

        if (_searchResults.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Aucun résultat trouvé à Béjaïa'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        throw Exception('Failed to load search results');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la recherche: ${e.toString()}'),
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _navigateToSearchResult(Map<String, dynamic> result) {
    final latLng = LatLng(result['lat'], result['lon']);
    setState(() {
      _searchedLocation = latLng;
      _showRoute = false;
      _searchResults.clear();
    });
    _mapController.move(latLng, 15.0);
    _searchFocusNode.unfocus();
  }

  Future<void> _showRouteBetweenLocations() async {
    if (_currentLocation == null || _searchedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Veuillez sélectionner votre position et une destination',
          ),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
          'http://router.project-osrm.org/route/v1/driving/'
          '${_currentLocation!.longitude},${_currentLocation!.latitude};'
          '${_searchedLocation!.longitude},${_searchedLocation!.latitude}'
          '?overview=full&geometries=geojson',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 'Ok') {
          final coordinates = data['routes'][0]['geometry']['coordinates'];
          setState(() {
            _routePoints =
                coordinates
                    .map<LatLng>((coord) => LatLng(coord[1], coord[0]))
                    .toList();
            _showRoute = true;
            _routeAnimationController.reset();
            _routeAnimationController.forward();
          });
        } else {
          throw Exception('Routing failed: ${data['message']}');
        }
      } else {
        throw Exception('Failed to load route');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erreur lors du calcul de l\'itinéraire: ${e.toString()}',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
      // Fallback to straight line if routing fails
      setState(() {
        _routePoints = [_currentLocation!, _searchedLocation!];
        _showRoute = true;
        _routeAnimationController.reset();
        _routeAnimationController.forward();
      });
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  Widget _buildLocationMarker() {
    return MarkerLayer(
      markers: [
        if (_currentLocation != null)
          Marker(
            point: _currentLocation!,
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (_accuracy != null)
                  Positioned(
                    child: Container(
                      width: _accuracy! * 2,
                      height: _accuracy! * 2,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue.withOpacity(0.2),
                      ),
                    ),
                  ),
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blue,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                      ),
                    );
                  },
                ),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        if (_searchedLocation != null)
          Marker(
            point: _searchedLocation!,
            width: 80,
            height: 80,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Text(
                    widget.markerTitle ?? 'Destination',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.red,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildRouteLayer() {
    if (!_showRoute || _animatedRoutePoints.length < 2) {
      return Container();
    }

    return PolylineLayer(
      polylines: [
        Polyline(
          points: _animatedRoutePoints,
          color: Colors.blue,
          strokeWidth: 4,
        ),
      ],
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
        break;
      case 1:
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => FavorisPage()),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ProfilePage()),
        );
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      body: Stack(
        children: [
          // Main Map Widget
          if (_isLoadingMap)
            const Center(
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Colors.blue,
              ),
            )
          else
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: const LatLng(36.7509, 5.0566),
                initialZoom: 12.0,
                minZoom: 11.0,
                bounds: LatLngBounds(
                  const LatLng(minLat, minLon),
                  const LatLng(maxLat, maxLon),
                ),
                boundsOptions: const FitBoundsOptions(
                  padding: EdgeInsets.all(8.0),
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                  subdomains: const ['a', 'b', 'c'],
                ),
                _buildRouteLayer(),
                _buildLocationMarker(),
                _buildPlacesMarkers(),
              ],
            ),

          // Side Panel
          _buildSidePanel(),

          // Filter Button (only visible when panel is closed)
          if (!_isPanelOpen)
            Positioned(
              top: 100,
              left: 20,
              child: FloatingActionButton(
                heroTag: 'filterButton',
                backgroundColor: Colors.white,
                onPressed: _togglePanel,
                child: const Icon(Icons.filter_list, color: Colors.blue),
              ),
            ),

          // Search Bar
          Positioned(
            top: 40,
            left: 20,
            right: 20,
            child: Column(
              children: [
                Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(30),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            prefixIcon: const Icon(
                              Icons.search,
                              color: Colors.blue,
                            ),
                            suffixIcon:
                                _isSearching
                                    ? const Padding(
                                      padding: EdgeInsets.all(8),
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.blue,
                                      ),
                                    )
                                    : _searchController.text.isNotEmpty
                                    ? IconButton(
                                      icon: const Icon(
                                        Icons.close,
                                        color: Colors.grey,
                                      ),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {
                                          _searchResults.clear();
                                          _searchedLocation = null;
                                          _showRoute = false;
                                        });
                                      },
                                    )
                                    : null,
                            hintText: "Rechercher un lieu à Béjaïa...",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 20,
                            ),
                          ),
                          onSubmitted: (value) => _searchLocation(),
                        ),
                      ),
                      if (_searchedLocation != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: IconButton(
                            icon: const Icon(
                              Icons.navigation,
                              color: Colors.blue,
                              size: 28,
                            ),
                            onPressed: () {
                              _mapController.move(_searchedLocation!, 15.0);
                            },
                          ),
                        ),
                    ],
                  ),
                ),
                if (_searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children:
                          _searchResults
                              .map(
                                (result) => ListTile(
                                  leading: const Icon(
                                    Icons.place,
                                    color: Colors.red,
                                  ),
                                  title: Text(
                                    result['name'],
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  onTap: () {
                                    _navigateToSearchResult(result);
                                    _searchController.text = result['name'];
                                  },
                                ),
                              )
                              .toList(),
                    ),
                  ),
              ],
            ),
          ),

          // Loading Indicator for Places
          if (_isLoadingPlaces)
            Positioned(
              top: 100,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 10),
                      Text('Chargement des lieux...'),
                    ],
                  ),
                ),
              ),
            ),

          // Location Buttons
          Positioned(
            bottom: 160,
            right: 20,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: 'locationButton',
                  backgroundColor: Colors.white,
                  onPressed: _centerOnMyLocation,
                  child:
                      _isLoadingLocation
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.blue,
                            ),
                          )
                          : const Icon(Icons.my_location, color: Colors.blue),
                ),
                const SizedBox(height: 10),
                FloatingActionButton(
                  heroTag: 'routeButton',
                  backgroundColor: Colors.white,
                  onPressed: _showRouteBetweenLocations,
                  child:
                      _isSearching
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.green,
                            ),
                          )
                          : const Icon(Icons.directions, color: Colors.green),
                ),
              ],
            ),
          ),

          // Location Error Message
          if (_locationError.isNotEmpty)
            Positioned(
              bottom: 230,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _locationError,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        size: 18,
                        color: Colors.red,
                      ),
                      onPressed: () {
                        setState(() {
                          _locationError = '';
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
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
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.9)),
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
    );
  }


  Widget _buildNavItem(IconData icon, String label, int index) {
    final Color primaryColor = Color(0xFF4361EE);
    final Color secondaryColor = Color(0xFF1E40AF);
    final Color accentColor = Color(0xFFEC4899);
    final Color backgroundColor = Color(0xFFF9FAFB);
    final Color cardColor = Colors.white;
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color:
          isSelected ? primaryColor.withOpacity(0.1) : Colors.transparent,
        ),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? primaryColor : Colors.grey,
                size: isSelected ? 26 : 24,
              ),
              if (isSelected) ...[
                SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: primaryColor,
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
}
