import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lottie/lottie.dart' hide Marker;
import 'GlovalColors.dart';
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
      title: 'Carte OSM - Béjaïa',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MapScreen(),
    );
  }
}

class Lieu {
  final String nom;
  final String description;
  final String categorie;
  final String? image;
  final double latitude;
  final double longitude;

  Lieu({
    required this.nom,
    required this.description,
    required this.categorie,
    this.image,
    required this.latitude,
    required this.longitude,
  });

  factory Lieu.fromJson(Map<String, dynamic> json) {
    return Lieu(
      nom: json['nom'] ?? json['name'] ?? '',
      description: json['description'] ?? '',
      categorie: json['categorie'] ?? json['category'] ?? 'autre',
      image: json['image'],
      latitude: double.parse(json['latitude'].toString()),
      longitude: double.parse(json['longitude'].toString()),
    );
  }
}

class MapScreen extends StatefulWidget {
  final LatLng? positionInitiale;
  final String? titreMarqueur;

  const MapScreen({super.key, this.positionInitiale, this.titreMarqueur});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  final Color bleuTurquoise = Color(0xFF41A6B4);
  bool _chargementCarte = true;
  final MapController _controleurCarte = MapController();
  final TextEditingController _controleurRecherche = TextEditingController();
  final FocusNode _focusRecherche = FocusNode();
  int _indexSelectionne = 1;
  bool _chargementPosition = false;
  String _erreurLocalisation = '';
  LatLng? _positionActuelle;
  double? _precision;
  late AnimationController _controleurAnimationPulse;
  late Animation<double> _animationPulse;
  late AnimationController _controleurAnimationItineraire;
  late Animation<double> _animationItineraire;
  bool _rechercheEnCours = false;
  List<Map<String, dynamic>> _resultatsRecherche = [];
  LatLng? _positionRecherchee;
  List<LatLng> _pointsItineraire = [];
  List<LatLng> _pointsItineraireAnime = [];
  bool _afficherItineraire = false;
  List<Lieu> _lieux = [];
  bool _chargementLieux = false;
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _panneauOuvert = false;
  Set<String> _categoriesSelectionnees = {};
  List<Lieu> _lieuxFiltres = [];
  Timer? _timerErreur;

  static const double latMin = 36.5;
  static const double latMax = 36.9;
  static const double lonMin = 4.8;
  static const double lonMax = 5.3;

  bool isDarkMode  = GlobalColors.isDarkMode;

  @override
  void initState() {
    super.initState();
    _initialiserLocalisation();
    _chargerLieuxDepuisSupabase();

    _controleurAnimationPulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _animationPulse = Tween(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(
        parent: _controleurAnimationPulse,
        curve: Curves.easeInOut,
      ),
    );

    _controleurAnimationItineraire = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _animationItineraire = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controleurAnimationItineraire,
        curve: Curves.easeInOut,
      ),
    )..addListener(() {
      _mettreAJourItineraireAnime();
    });

    if (widget.positionInitiale != null) {
      _positionRecherchee = widget.positionInitiale;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controleurCarte.move(widget.positionInitiale!, 15.0);
      });
    }

    _focusRecherche.addListener(() {
      if (!_focusRecherche.hasFocus) {
        setState(() {
          _resultatsRecherche.clear();
        });
      }
    });
  }

  @override
  void dispose() {
    _controleurAnimationPulse.dispose();
    _controleurAnimationItineraire.dispose();
    _controleurRecherche.dispose();
    _focusRecherche.dispose();
    _timerErreur?.cancel();
    super.dispose();
  }

  void _afficherErreurTemporaire(String message) {
    setState(() {
      _erreurLocalisation = message;
    });

    _timerErreur?.cancel();
    _timerErreur = Timer(const Duration(seconds: 0), () {
      if (mounted) {
        setState(() {
          _erreurLocalisation = '';
        });
      }
    });
  }

  Future<void> _initialiserLocalisation() async {
    setState(() {
      _chargementCarte = true;
    });

    try {
      bool permissionAccordee = await _verifierPermissionLocalisation();
      if (!permissionAccordee) return;

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _positionActuelle = LatLng(position.latitude, position.longitude);
        _precision = position.accuracy;
      });

      if (widget.positionInitiale == null) {
        _controleurCarte.move(_positionActuelle!, 15.0);
      }
    } catch (e) {
      _afficherErreurTemporaire('Erreur de localisation : $e');
    } finally {
      setState(() {
        _chargementCarte = false;
      });
    }
  }

  Future<bool> _verifierPermissionLocalisation() async {
    bool serviceActive = await Geolocator.isLocationServiceEnabled();
    if (!serviceActive) {
      bool ouvrirParametres = await showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Service de localisation désactivé'),
              content: const Text(
                'Voulez-vous activer la localisation dans les paramètres ?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Non'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Oui'),
                ),
              ],
            ),
      );

      if (ouvrirParametres) {
        await Geolocator.openLocationSettings();
      }

      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      return false;
    }

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    }

    return true;
  }

  Future<void> _chargerLieuxDepuisSupabase() async {
    if (!mounted) return;

    setState(() => _chargementLieux = true);

    try {
      final List<dynamic> donnees = await _supabase.from('offre').select(''' 
        nom, 
        description, 
        categorie, 
        image, 
        latitude, 
        longitude
      ''');

      if (!mounted) return;

      setState(() {
        _lieux = donnees.map((json) => Lieu.fromJson(json)).toList();
        _lieuxFiltres = List<Lieu>.from(_lieux);
        _categoriesSelectionnees =
            _lieux
                .map((p) => p.categorie)
                .toSet()
                .toList()
                .whereType<String>()
                .toSet();
        _lieux.sort((a, b) => a.nom.compareTo(b.nom));
        _lieuxFiltres.sort((a, b) => a.nom.compareTo(b.nom));
      });

      if (_categoriesSelectionnees.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aucune catégorie trouvée'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } on PostgrestException catch (e) {
      if (!mounted) return;
      _afficherErreur('Erreur Supabase: ${e.message}');
    } on SocketException catch (_) {
      if (!mounted) return;
      _afficherErreur('Erreur de connexion internet');
    } on TimeoutException catch (_) {
      if (!mounted) return;
      _afficherErreur('La requête a expiré');
    } catch (e) {
      if (!mounted) return;
      _afficherErreur('Erreur inattendue: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _chargementLieux = false);
      }
    }
  }

  void _filtrerLieux() {
    setState(() {
      if (_categoriesSelectionnees.isEmpty) {
        _lieuxFiltres = [];
      } else {
        _lieuxFiltres =
            _lieux
                .where(
                  (lieu) => _categoriesSelectionnees.contains(lieu.categorie),
                )
                .toList();
      }
    });
  }

  void _basculerCategorie(String categorie) {
    setState(() {
      if (_categoriesSelectionnees.contains(categorie)) {
        _categoriesSelectionnees.remove(categorie);
      } else {
        _categoriesSelectionnees.add(categorie);
      }
      _filtrerLieux();
    });
  }

  void _basculerPanneau() {
    setState(() {
      _panneauOuvert = !_panneauOuvert;
    });
  }

  void _afficherErreur(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[400],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  IconData _obtenirIconePourCategorie(String categorie) {
    switch (categorie.toLowerCase()) {
      case 'restaurant':
        return FontAwesomeIcons.utensils;
      case 'pizzeria':
        return FontAwesomeIcons.pizzaSlice;
      case 'café':
      case 'cafe':
        return FontAwesomeIcons.mugHot;
      case 'hôtel':
      case 'hotel':
        return FontAwesomeIcons.hotel;
      case 'auberge':
        return FontAwesomeIcons.houseChimney;
      case 'loisirs':
        return FontAwesomeIcons.gamepad;
      case 'cinéma':
        return FontAwesomeIcons.film;
      case 'bowling':
        return FontAwesomeIcons.bowlingBall;
      case 'point dintérêt':
      case 'point d\'intérêt':
        return FontAwesomeIcons.binoculars;
      case 'point dintérêt historique':
      case 'point d\'intérêt historique':
        return FontAwesomeIcons.landmark;
      case 'monument':
        return FontAwesomeIcons.monument;
      case 'plage':
      case 'beach':
        return FontAwesomeIcons.umbrellaBeach;
      case 'parc':
      case 'park':
        return FontAwesomeIcons.tree;
      case 'jardin':
        return FontAwesomeIcons.leaf;
      case 'shop':
      case 'magasin':
        return FontAwesomeIcons.bagShopping;
      case 'centre commercial':
        return FontAwesomeIcons.shop;
      case 'hôpital':
      case 'hospital':
        return FontAwesomeIcons.hospital;
      case 'pharmacie':
        return FontAwesomeIcons.pills;
      case 'gare':
        return FontAwesomeIcons.train;
      case 'aéroport':
        return FontAwesomeIcons.plane;
      default:
        return FontAwesomeIcons.locationDot;
    }
  }

  Color _obtenirCouleurPourCategorie(String categorie) {
    final String categorieMin = categorie.toLowerCase();

    const Color rouge = Color(0xFFE53935);
    const Color rose = Color(0xFFD81B60);
    const Color bleu = Color(0xFF1E88E5);
    const Color violet = Color(0xFF8E24AA);
    const Color orange = Color(0xFFF4511E);
    const Color brun = Color(0xFF795548);
    const Color jaune = Color(0xFFFFB300);
    const Color vert = Color(0xFF43A047);
    const Color gris = Color(0xFF757575);

    switch (categorieMin) {
      case 'restaurant':
        return rouge;
      case 'pizzeria':
        return rose;
      case 'café':
      case 'cafe':
        return const Color(0xFF6D4C41);
      case 'hôtel':
      case 'hotel':
        return bleu;
      case 'auberge':
        return const Color(0xFF5E35B1);
      case 'loisirs':
        return violet;
      case 'cinéma':
        return const Color(0xFF3949AB);
      case 'bowling':
        return const Color(0xFF00897B);
      case 'point dintérêt':
      case 'point d\'intérêt':
        return orange;
      case 'point dintérêt historique':
      case 'point d\'intérêt historique':
        return brun;
      case 'monument':
        return const Color(0xFF6D4C41);
      case 'plage':
      case 'beach':
        return jaune;
      case 'parc':
      case 'park':
        return vert;
      case 'jardin':
        return const Color(0xFF7CB342);
      case 'shop':
      case 'magasin':
        return const Color(0xFFFB8C00);
      case 'centre commercial':
        return const Color(0xFFE040FB);
      case 'hôpital':
      case 'hospital':
        return const Color(0xFFD32F2F);
      case 'pharmacie':
        return const Color(0xFF00ACC1);
      case 'gare':
        return const Color(0xFF5C6BC0);
      case 'aéroport':
        return const Color(0xFF039BE5);
      default:
        return gris;
    }
  }

  Widget _construirePanneauLateral() {
    final toutesCategories = _lieux.map((p) => p.categorie).toSet().toList();
    toutesCategories.sort();

    return Stack(
      children: [
        // Overlay flou avec fond semi-transparent
        if (_panneauOuvert)
          Positioned.fill(
            child: GestureDetector(
              onTap: _basculerPanneau,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                child: Container(
                  color:
                      GlobalColors.isDarkMode
                          ? Colors.black.withOpacity(0.5)
                          : Colors.black.withOpacity(0.3),
                ),
              ),
            ),
          ),

        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          left: 0,
          right: 0,
          top:
              _panneauOuvert
                  ? MediaQuery.of(context).size.height * 0.1
                  : -MediaQuery.of(context).size.height,
          child: Center(
            child: Material(
              elevation: 24,
              borderRadius: BorderRadius.circular(20),
              color: Colors.transparent,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.85,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.75,
                ),
                decoration: BoxDecoration(
                  color:
                      GlobalColors.isDarkMode
                          ? Colors.grey[900]!.withOpacity(0.95)
                          : Colors.white.withOpacity(0.97),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                  border:
                      GlobalColors.isDarkMode
                          ? Border.all(color: Colors.grey[800]!)
                          : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // En-tête du panneau
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
                      decoration: BoxDecoration(
                        color:
                            GlobalColors.isDarkMode
                                ? GlobalColors.bleuTurquoise
                                : GlobalColors.bleuTurquoise,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Filtrer les lieux',
                            style: GoogleFonts.robotoSlab(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, color: Colors.white),
                            onPressed: _basculerPanneau,
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Liste des catégories
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: toutesCategories.length,
                        itemBuilder: (context, index) {
                          final categorie = toutesCategories[index];
                          final estSelectionnee = _categoriesSelectionnees
                              .contains(categorie);

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 6,
                              horizontal: 8,
                            ),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color:
                                    estSelectionnee
                                        ? _obtenirCouleurPourCategorie(
                                          categorie,
                                        ).withOpacity(0.1)
                                        : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                leading: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color:
                                        estSelectionnee
                                            ? _obtenirCouleurPourCategorie(
                                              categorie,
                                            )
                                            : GlobalColors.isDarkMode
                                            ? Colors.grey[800]!
                                            : Colors.grey[200]!,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _obtenirIconePourCategorie(categorie),
                                    size: 20,
                                    color:
                                        estSelectionnee
                                            ? Colors.white
                                            : GlobalColors.isDarkMode
                                            ? Colors.grey[300]!
                                            : Colors.grey[700]!,
                                  ),
                                ),
                                title: Text(
                                  categorie,
                                  style: GoogleFonts.robotoSlab(
                                    fontSize: 15,
                                    color:
                                        GlobalColors.isDarkMode
                                            ? Colors.white
                                            : Colors.black,
                                  ),
                                ),
                                trailing:
                                    estSelectionnee
                                        ? Icon(
                                          Icons.check,
                                          color: Colors.green,
                                          size: 22,
                                        )
                                        : null,
                                onTap: () => _basculerCategorie(categorie),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Boutons en bas du panneau
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                      child: Row(
                        children: [
                          // Bouton "Tout sélectionner"
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor:
                                    GlobalColors.isDarkMode
                                        ? Colors.blue[200]
                                        : Colors.blue[700],
                                side: BorderSide(
                                  color:
                                      GlobalColors.isDarkMode
                                          ? GlobalColors.bleuTurquoise
                                          : GlobalColors.bleuTurquoise,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              child: Text('Tout sélectionner', style: GoogleFonts.robotoSlab(color: GlobalColors.bleuTurquoise),),
                              onPressed: () {
                                setState(() {
                                  _categoriesSelectionnees =
                                      toutesCategories.toSet();
                                  _filtrerLieux();
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Bouton "Appliquer"
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    GlobalColors.isDarkMode
                                        ? Colors.blue[800]!
                                        : Colors.white,
                                foregroundColor:
                                    GlobalColors.isDarkMode
                                        ? Colors.white
                                        : Colors.blue[700],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: BorderSide(
                                    color:
                                        GlobalColors.isDarkMode
                                            ? GlobalColors.bleuTurquoise
                                            : GlobalColors.bleuTurquoise,
                                    width: 1.5,
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                elevation: 2,
                              ),
                              child: Text(
                                'Appliquer',
                                style: GoogleFonts.robotoSlab
                                  (fontWeight: FontWeight.w600, color: GlobalColors.bleuTurquoise),
                              ),
                              onPressed: _basculerPanneau,
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
    );
  }

  Widget _construireMarqueursLieux() {
    return MarkerLayer(
      markers: _lieuxFiltres.map((lieu) {
        return Marker(
          point: LatLng(lieu.latitude, lieu.longitude),
          width: 80.0, // Augmenter la largeur si nécessaire
          height: 80.0, // Augmenter la hauteur si nécessaire
          child: GestureDetector(
            onTap: () => _afficherDetailsLieu(lieu),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Conteneur pour l'icône
                Container(
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
                      color: _obtenirCouleurPourCategorie(lieu.categorie),
                      width: 2.0,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (_indexSelectionne == 1)
                        AnimatedBuilder(
                          animation: _animationPulse,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _animationPulse.value * 0.8,
                              child: Container(
                                width: 30.0,
                                height: 30.0,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _obtenirCouleurPourCategorie(
                                    lieu.categorie,
                                  ).withOpacity(0.2),
                                ),
                              ),
                            );
                          },
                        ),
                      Icon(
                        _obtenirIconePourCategorie(lieu.categorie),
                        color: _obtenirCouleurPourCategorie(lieu.categorie),
                        size: 24.0,
                      ),
                      if (lieu.categorie.toLowerCase().contains('historique'))
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
                // Ajout du nom avec contraintes
                const SizedBox(height: 4),
                Container(
                  constraints: BoxConstraints(
                    maxWidth: 100, // Largeur maximale pour le texte
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    lieu.nom,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2, // Limite à 2 lignes
                    overflow: TextOverflow.ellipsis, // Points de suspension si trop long
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  void _afficherDetailsLieu(Lieu lieu) {
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
              color:
                  GlobalColors.isDarkMode
                      ? Colors.grey[900]!.withOpacity(0.95)
                      : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(25),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
              border:
                  GlobalColors.isDarkMode
                      ? Border.all(color: Colors.grey[800]!)
                      : null,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle drag
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color:
                          GlobalColors.isDarkMode
                              ? Colors.grey[700]
                              : Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  // Image section
                  _construireSectionImage(lieu),

                  // Content
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            lieu.nom,
                            key: ValueKey(lieu.nom),
                            style: GoogleFonts.robotoSlab(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                              color:
                                  GlobalColors.isDarkMode
                                      ? Colors.white
                                      : Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Category chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _obtenirCouleurPourCategorie(
                              lieu.categorie,
                            ).withOpacity(GlobalColors.isDarkMode ? 0.2 : 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border:
                                GlobalColors.isDarkMode
                                    ? Border.all(
                                      color: _obtenirCouleurPourCategorie(
                                        lieu.categorie,
                                      ).withOpacity(0.4),
                                      width: 1,
                                    )
                                    : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _obtenirIconePourCategorie(lieu.categorie),
                                color: _obtenirCouleurPourCategorie(
                                  lieu.categorie,
                                ),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                lieu.categorie,
                                style: GoogleFonts.robotoSlab(
                                  color: _obtenirCouleurPourCategorie(
                                    lieu.categorie,
                                  ),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Description
                        AnimatedOpacity(
                          opacity: 1,
                          duration: const Duration(milliseconds: 500),
                          child: Text(
                            lieu.description,
                            style: GoogleFonts.robotoSlab(
                              fontSize: 16,
                              color:
                                  GlobalColors.isDarkMode
                                      ? Colors.grey[300]
                                      : Colors.grey[700],
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 25),

                        // Action buttons
                        _construireBoutonsAction(lieu),
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

  Widget _construireSectionImage(Lieu lieu) {
    return SizedBox(
      height: 200,
      child: Stack(
        children: [
          if (lieu.image != null)
            Positioned.fill(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(
                  sigmaX: GlobalColors.isDarkMode ? 4 : 2,
                  sigmaY: GlobalColors.isDarkMode ? 4 : 2,
                ),
                child: Image.network(
                  lieu.image!,
                  fit: BoxFit.cover,
                  color:
                      GlobalColors.isDarkMode
                          ? Colors.black.withOpacity(0.3)
                          : null,
                  colorBlendMode:
                      GlobalColors.isDarkMode
                          ? BlendMode.darken
                          : BlendMode.dst,
                ),
              ),
            ),
          Positioned.fill(
            child:
                lieu.image != null
                    ? ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(25),
                      ),
                      child: Image.network(lieu.image!, fit: BoxFit.cover),
                    )
                    : Container(
                      color:
                          GlobalColors.isDarkMode
                              ? Colors.grey[850]
                              : Colors.grey[200],
                      child: Center(
                        child: Icon(
                          Icons.photo,
                          size: 50,
                          color:
                              GlobalColors.isDarkMode
                                  ? Colors.grey[600]
                                  : Colors.grey,
                        ),
                      ),
                    ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(
                      GlobalColors.isDarkMode ? 0.5 : 0.3,
                    ),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construireBoutonsAction(Lieu lieu) {
    return Row(
      children: [
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
                _definirItineraireVersLieu(lieu);
              },
            ),
          ),
        ),
        const SizedBox(width: 15),
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
                  _positionRecherchee = LatLng(lieu.latitude, lieu.longitude);
                });
                Navigator.pop(context);
                _controleurCarte.move(_positionRecherchee!, 15.0);
              },
            ),
          ),
        ),
      ],
    );
  }

  void _definirItineraireVersLieu(Lieu lieu) {
    setState(() {
      _positionRecherchee = LatLng(lieu.latitude, lieu.longitude);
    });
    _afficherItineraireEntrePositions();
  }

  void _mettreAJourItineraireAnime() {
    if (_pointsItineraire.isEmpty) return;

    final totalPoints = _pointsItineraire.length;
    final pointsAnimes = (totalPoints * _animationItineraire.value).round();

    setState(() {
      _pointsItineraireAnime = _pointsItineraire.sublist(
        0,
        pointsAnimes.clamp(0, totalPoints),
      );
    });
  }

  Future<void> _centrerSurMaPosition() async {
    setState(() {
      _chargementPosition = true;
      _erreurLocalisation = '';
    });

    try {
      bool permissionAccordee = await _verifierPermissionLocalisation();
      if (!permissionAccordee) return;

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 10));

      setState(() {
        _positionActuelle = LatLng(position.latitude, position.longitude);
        _precision = position.accuracy;
        _afficherItineraire = false;
      });

      _controleurCarte.move(_positionActuelle!, 15.0);
    } on TimeoutException {
      _afficherErreurTemporaire('La demande de localisation a expiré');
    } catch (e) {
      _afficherErreurTemporaire(
        'Erreur lors de la localisation: ${e.toString()}',
      );
    } finally {
      setState(() {
        _chargementPosition = false;
      });
    }
  }

  Future<void> _rechercherLieu() async {
    final requete = _controleurRecherche.text.trim();
    if (requete.isEmpty) {
      setState(() {
        _rechercheEnCours = false;
        _resultatsRecherche.clear();
        _positionRecherchee = null;
        _afficherItineraire = false;
      });
      return;
    }

    setState(() {
      _rechercheEnCours = true;
      _resultatsRecherche.clear();
    });

    try {
      final reponse = await http.get(
        Uri.parse(
          'https://nominatim.openstreetmap.org/search?'
          'q=$requete'
          '&format=json'
          '&limit=5'
          '&viewbox=$lonMin,$latMin,$lonMax,$latMax'
          '&bounded=1',
        ),
        headers: {'User-Agent': 'YourAppName/1.0'},
      );

      if (reponse.statusCode == 200) {
        final List<dynamic> donnees = json.decode(reponse.body);
        setState(() {
          _resultatsRecherche =
              donnees
                  .map(
                    (item) => {
                      'name': item['display_name'],
                      'lat': double.parse(item['lat']),
                      'lon': double.parse(item['lon']),
                    },
                  )
                  .where((resultat) {
                    final lat = resultat['lat'];
                    final lon = resultat['lon'];
                    return lat >= latMin &&
                        lat <= latMax &&
                        lon >= lonMin &&
                        lon <= lonMax;
                  })
                  .toList();
        });

        if (_resultatsRecherche.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Aucun résultat trouvé à Béjaïa'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        throw Exception('Échec du chargement des résultats');
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
        _rechercheEnCours = false;
      });
    }
  }

  void _naviguerVersResultatRecherche(Map<String, dynamic> resultat) {
    final latLng = LatLng(resultat['lat'], resultat['lon']);
    setState(() {
      _positionRecherchee = latLng;
      _afficherItineraire = false;
      _resultatsRecherche.clear();
    });
    _controleurCarte.move(latLng, 15.0);
    _focusRecherche.unfocus();
  }

  Future<void> _afficherItineraireEntrePositions() async {
    if (_positionActuelle == null || _positionRecherchee == null) {
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
      _rechercheEnCours = true;
    });

    try {
      final reponse = await http.get(
        Uri.parse(
          'http://router.project-osrm.org/route/v1/driving/'
          '${_positionActuelle!.longitude},${_positionActuelle!.latitude};'
          '${_positionRecherchee!.longitude},${_positionRecherchee!.latitude}'
          '?overview=full&geometries=geojson',
        ),
      );

      if (reponse.statusCode == 200) {
        final donnees = json.decode(reponse.body);
        if (donnees['code'] == 'Ok') {
          final coordonnees = donnees['routes'][0]['geometry']['coordinates'];
          setState(() {
            _pointsItineraire =
                coordonnees
                    .map<LatLng>((coord) => LatLng(coord[1], coord[0]))
                    .toList();
            _afficherItineraire = true;
            _controleurAnimationItineraire.reset();
            _controleurAnimationItineraire.forward();
          });
        } else {
          throw Exception('Calcul itinéraire échoué: ${donnees['message']}');
        }
      } else {
        throw Exception('Échec du chargement de l\'itinéraire');
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

      setState(() {
        _pointsItineraire = [_positionActuelle!, _positionRecherchee!];
        _afficherItineraire = true;
        _controleurAnimationItineraire.reset();
        _controleurAnimationItineraire.forward();
      });
    } finally {
      setState(() {
        _rechercheEnCours = false;
      });
    }
  }

  Widget _construireMarqueurPosition() {
    return MarkerLayer(
      markers: [
        if (_positionActuelle != null)
          Marker(
            point: _positionActuelle!,
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (_precision != null)
                  Positioned(
                    child: Container(
                      width: _precision! * 2,
                      height: _precision! * 2,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue.withOpacity(0.2),
                      ),
                    ),
                  ),
                AnimatedBuilder(
                  animation: _animationPulse,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _animationPulse.value,
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
        if (_positionRecherchee != null)
          Marker(
            point: _positionRecherchee!,
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
                    widget.titreMarqueur ?? 'Destination',
                    style: GoogleFonts.robotoSlab(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedBuilder(
                  animation: _animationPulse,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _animationPulse.value,
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

  Widget _construireCoucheItineraire() {
    if (!_afficherItineraire || _pointsItineraireAnime.length < 2) {
      return Container();
    }

    return PolylineLayer(
      polylines: [
        Polyline(
          points: _pointsItineraireAnime,
          color: Colors.blue,
          strokeWidth: 4,
        ),
      ],
    );
  }

  void _surItemSelectionne(int index) {
    setState(() {
      _indexSelectionne = index;
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
      backgroundColor: Colors.grey[100],
      body: Stack(
        children: [
          if (_chargementCarte)
            Container(
              color: Colors.white,
              child: Center(
                child: Lottie.network(
                  'https://assets3.lottiefiles.com/private_files/lf30_cgfdhxgx.json',
                  width: 200,
                  height: 200,
                ),
              ),
            )
          else
            FlutterMap(
              mapController: _controleurCarte,
              options: MapOptions(
                initialCenter: const LatLng(36.7509, 5.0566),
                initialZoom: 12.0,
                minZoom: 11.0,
                bounds: LatLngBounds(
                  LatLng(latMin, lonMin),
                  LatLng(latMax, lonMax),
                ),
                boundsOptions: const FitBoundsOptions(
                  padding: EdgeInsets.all(12.0),
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                  subdomains: const ['a', 'b', 'c'],
                  userAgentPackageName: 'com.example.app',
                  tileBuilder: (context, widget, tile) {
                    return TweenAnimationBuilder(
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 300),
                      builder: (context, value, child) {
                        return Opacity(opacity: value, child: child);
                      },
                      child: widget,
                    );
                  },
                ),
                _construireCoucheItineraire(),
                _construireMarqueurPosition(),
                _construireMarqueursLieux(),
              ],
            ),

          _construirePanneauLateral(),

          if (!_panneauOuvert)
            Positioned(
              top: 110,
              left: 20,
              child: Material(
                elevation: 6,
                shadowColor: Colors.black26,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [GlobalColors.bleuTurquoise, GlobalColors.bleuTurquoise],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.filter_list, color: Colors.white),
                    onPressed: _basculerPanneau,
                    iconSize: 26,
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              ),
            ),

          Positioned(
            top: 45,
            left: 20,
            right: 20,
            child: Visibility(
              visible: !_panneauOuvert,
              child: Column(
              children: [
                Material(
                elevation: 8,
                shadowColor: Colors.black38,
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: LinearGradient(
                    colors: [
                    GlobalColors.isDarkMode ? Colors.grey[900]! : Colors.white,
                    GlobalColors.isDarkMode ? Colors.grey[850]! : Colors.grey[50]!,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  ),
                  child: Row(
                  children: [
                    Expanded(
                    child: TextField(
                      controller: _controleurRecherche,
                      focusNode: _focusRecherche,
                      style: GoogleFonts.robotoSlab(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: GlobalColors.isDarkMode ? Colors.grey[200] : Colors.black87,
                      ),
                      decoration: InputDecoration(
                      filled: true,
                      fillColor: GlobalColors.isDarkMode 
                        ? Colors.grey[850]!.withOpacity(0.7)
                        : Colors.grey[50],
                      prefixIcon: Icon(
                        Icons.search,
                        color: GlobalColors.isDarkMode 
                          ? GlobalColors.bleuTurquoise
                          : GlobalColors.bleuTurquoise,
                        size: 26,
                      ),
                      suffixIcon: _rechercheEnCours
                        ? Padding(
                          padding: const EdgeInsets.all(10),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: GlobalColors.isDarkMode 
                              ? Colors.blue[300]
                              : Colors.blue[600],
                          ),
                          )
                        : _controleurRecherche.text.isNotEmpty
                          ? IconButton(
                            icon: Icon(
                              Icons.close,
                              color: GlobalColors.isDarkMode 
                                ? Colors.grey[400]
                                : Colors.grey[600],
                            ),
                            onPressed: () {
                              _controleurRecherche.clear();
                              setState(() {
                              _resultatsRecherche.clear();
                              _positionRecherchee = null;
                              _afficherItineraire = false;
                              });
                            },
                            )
                          : null,
                      hintText: "Rechercher un lieu à Béjaïa...",
                      hintStyle: GoogleFonts.robotoSlab(
                        color: GlobalColors.isDarkMode 
                          ? Colors.grey[400]
                          : Colors.grey[500],
                        fontWeight: FontWeight.w400,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(
                        color: GlobalColors.isDarkMode 
                          ? Colors.grey[700]!
                          : Colors.grey[300]!,
                        width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(
                        color: GlobalColors.isDarkMode 
                          ? GlobalColors.bleuTurquoise
                          : GlobalColors.bleuTurquoise,
                        width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 20,
                      ),
                      ),
                      onSubmitted: (value) => _rechercherLieu(),
                    ),
                    ),
                    if (_positionRecherchee != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Container(
                      decoration: BoxDecoration(
                        color: GlobalColors.isDarkMode 
                          ? GlobalColors.bleuTurquoise
                          : GlobalColors.bleuTurquoise,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                        Icons.navigation,
                        color: GlobalColors.isDarkMode 
                          ? Colors.blue[300]
                          : Colors.blue[600],
                        size: 28,
                        ),
                        onPressed: () {
                        _controleurCarte.move(
                          _positionRecherchee!,
                          15.0,
                        );
                        },
                      ),
                      ),
                    ),
                  ],
                  ),
                ),
                ),

                  // Search results
                  if (_resultatsRecherche.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            spreadRadius: 1,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Material(
                          color: Colors.transparent,
                          child: Column(
                            children:
                                _resultatsRecherche.map((resultat) {
                                  return InkWell(
                                    onTap: () {
                                      _naviguerVersResultatRecherche(resultat);
                                      _controleurRecherche.text =
                                          resultat['name'];
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                        horizontal: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                            color: Colors.grey[200]!,
                                            width: 1,
                                          ),
                                        ),
                                      ),
                                      child: ListTile(
                                        leading: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.red[50],
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.place,
                                            color: Colors.red[400],
                                            size: 20,
                                          ),
                                        ),
                                        title: Text(
                                          resultat['name'],
                                          overflow: TextOverflow.ellipsis,
                                          style:  GoogleFonts.robotoSlab(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        subtitle: Text(
                                          'Distance: ${resultat['distance'] ?? 'Inconnue'}',
                                          style: GoogleFonts.robotoSlab(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        trailing: Icon(
                                          Icons.arrow_forward_ios,
                                          size: 16,
                                          color: Colors.grey[400],
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Loading places indicator
          if (_chargementLieux)
            Positioned(
              top: 110,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 1,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.blue[600]!,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        'Chargement des lieux...',
                        style: GoogleFonts.robotoSlab(
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          Positioned(
            bottom: 160,
            right: 20,
            child: Visibility(
              visible: !_panneauOuvert,
              child: Column(
                children: [
                  // Location button
                  Container(
                    decoration: BoxDecoration(
                      boxShadow:
                          GlobalColors.isDarkMode
                              ? []
                              : [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Material(
                      elevation: 0,
                      borderRadius: BorderRadius.circular(24),
                      color:
                          GlobalColors.isDarkMode
                              ? Colors.grey[800]!.withOpacity(0.8)
                              : Colors.white,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: _centrerSurMaPosition,
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            border:
                                GlobalColors.isDarkMode
                                    ? Border.all(
                                      color: Colors.blue[200]!.withOpacity(0.2),
                                      width: 1,
                                    )
                                    : null,
                          ),
                          child:
                              _chargementPosition
                                  ? SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        GlobalColors.isDarkMode
                                            ? Colors.blue[200]!
                                            : Colors.blue[600]!,
                                      ),
                                    ),
                                  )
                                  : Icon(
                                    Icons.my_location,
                                    color:
                                        GlobalColors.isDarkMode
                                            ? Colors.blue[200]
                                            : Colors.blue[600],
                                    size: 24,
                                  ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Directions button
                  Container(
                    decoration: BoxDecoration(
                      boxShadow:
                          GlobalColors.isDarkMode
                              ? []
                              : [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Material(
                      elevation: 0,
                      borderRadius: BorderRadius.circular(24),
                      color:
                          GlobalColors.isDarkMode
                              ? Colors.grey[800]!.withOpacity(0.8)
                              : Colors.white,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: _afficherItineraireEntrePositions,
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            border:
                                GlobalColors.isDarkMode
                                    ? Border.all(
                                      color: Colors.green[200]!.withOpacity(
                                        0.2,
                                      ),
                                      width: 1,
                                    )
                                    : null,
                          ),
                          child:
                              _rechercheEnCours
                                  ? SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        GlobalColors.isDarkMode
                                            ? Colors.green[200]!
                                            : Colors.green[600]!,
                                      ),
                                    ),
                                  )
                                  : Icon(
                                    Icons.directions,
                                    color:
                                        GlobalColors.isDarkMode
                                            ? Colors.green[200]
                                            : Colors.green[600],
                                    size: 24,
                                  ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_erreurLocalisation.isNotEmpty)
            Positioned(
              bottom: 230,
              left: 20,
              right: 20,
              child: GestureDetector(
                onTap: () => _centrerSurMaPosition(),
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 300),
                  builder: (context, value, child) {
                    return Opacity(opacity: value, child: child);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color:
                          GlobalColors.isDarkMode
                              ? Colors.red[900]!.withOpacity(0.3)
                              : Colors.red[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color:
                            GlobalColors.isDarkMode
                                ? Colors.red[700]!
                                : Colors.red[300]!,
                      ),
                      boxShadow:
                          GlobalColors.isDarkMode
                              ? []
                              : [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.1),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                              ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color:
                                GlobalColors.isDarkMode
                                    ? Colors.red[800]!.withOpacity(0.5)
                                    : Colors.red[100],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.error_outline,
                            color:
                                GlobalColors.isDarkMode
                                    ? Colors.red[200]
                                    : Colors.red[700],
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _erreurLocalisation,
                            style: GoogleFonts.robotoSlab(
                              color:
                                  GlobalColors.isDarkMode
                                      ? Colors.red[200]
                                      : Colors.red[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.settings,
                            color:
                                GlobalColors.isDarkMode
                                    ? Colors.red[300]
                                    : Colors.red[600],
                          ),
                          onPressed: () => Geolocator.openLocationSettings(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: GlobalColors.isDarkMode
                      ? Colors.grey[800]!.withOpacity(0.8)
                      : Colors.transparent,
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
                  filter: !isDarkMode ? ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0) : ImageFilter.blur(sigmaX: 0.0, sigmaY: 0.0),
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
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    bool isSelected = _indexSelectionne == index;
    Color selectedColor =
        GlobalColors.isDarkMode ? bleuTurquoise : bleuTurquoise;

    return GestureDetector(
      onTap: () => _surItemSelectionne(index),
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
                  style: GoogleFonts.robotoSlab(
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
}
