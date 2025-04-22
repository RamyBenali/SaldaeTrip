import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'profile.dart';
import 'weather_main.dart';
import 'favoris.dart';
import 'models/offre_model.dart';

void main() {
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

class MapScreen extends StatefulWidget {
  final LatLng? initialLocation;
  final String? markerTitle;

  const MapScreen({
    super.key, 
    this.initialLocation,
    this.markerTitle,
  });

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

  // Béjaïa boundaries
  static const double minLat = 36.5;
  static const double maxLat = 36.9;
  static const double minLon = 4.8;
  static const double maxLon = 5.3;

  @override
  void initState() {
    super.initState();
    _initLocation();

    // Pulse animation for location markers
    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseAnimationController, curve: Curves.easeInOut),
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

    // Si une position initiale est fournie (depuis offre_details)
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

      // Si aucune position initiale n'est fournie, centrer sur la position actuelle
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
        _locationError = 'Les permissions de localisation sont définitivement refusées';
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

      _mapController.move(
        _currentLocation!,
        15.0,
      );

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
        Uri.parse('https://nominatim.openstreetmap.org/search?'
            'q=$query'
            '&format=json'
            '&limit=5'
            '&viewbox=$minLon,$minLat,$maxLon,$maxLat'
            '&bounded=1'),
        headers: {'User-Agent': 'YourAppName/1.0'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _searchResults = data.map((item) => {
            'name': item['display_name'],
            'lat': double.parse(item['lat']),
            'lon': double.parse(item['lon']),
          }).where((result) {
            final lat = result['lat'];
            final lon = result['lon'];
            return lat >= minLat && lat <= maxLat && lon >= minLon && lon <= maxLon;
          }).toList();
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
          content: Text('Veuillez sélectionner votre position et une destination'),
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
        Uri.parse('http://router.project-osrm.org/route/v1/driving/'
            '${_currentLocation!.longitude},${_currentLocation!.latitude};'
            '${_searchedLocation!.longitude},${_searchedLocation!.latitude}'
            '?overview=full&geometries=geojson'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 'Ok') {
          final coordinates = data['routes'][0]['geometry']['coordinates'];
          setState(() {
            _routePoints = coordinates.map<LatLng>((coord) =>
                LatLng(coord[1], coord[0])).toList();
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
          content: Text('Erreur lors du calcul de l\'itinéraire: ${e.toString()}'),
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
                          border: Border.all(
                            color: Colors.white,
                            width: 3,
                          ),
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
                          border: Border.all(
                            color: Colors.white,
                            width: 3,
                          ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      body: Stack(
        children: [
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
                  urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                  subdomains: const ['a', 'b', 'c'],
                ),
                _buildRouteLayer(),
                _buildLocationMarker(),
              ],
            ),

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
                            prefixIcon: const Icon(Icons.search, color: Colors.blue),
                            suffixIcon: _isSearching
                                ? const Padding(
                              padding: EdgeInsets.all(8),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.blue,
                              ),
                            )
                                : _searchController.text.isNotEmpty
                                ? IconButton(
                              icon: const Icon(Icons.close, color: Colors.grey),
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
                            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                          ),
                          onSubmitted: (value) => _searchLocation(),
                        ),
                      ),
                      if (_searchedLocation != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: IconButton(
                            icon: const Icon(Icons.navigation, color: Colors.blue, size: 28),
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
                      children: _searchResults.map((result) => ListTile(
                        leading: const Icon(Icons.place, color: Colors.red),
                        title: Text(
                          result['name'],
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14),
                        ),
                        onTap: () {
                          _navigateToSearchResult(result);
                          _searchController.text = result['name'];
                        },
                      )).toList(),
                    ),
                  ),
              ],
            ),
          ),
          Positioned(
            bottom: 160,
            right: 20,
            child: Column(
              children: [
                FloatingActionButton(
                  backgroundColor: Colors.white,
                  onPressed: _centerOnMyLocation,
                  child: _isLoadingLocation
                      ? const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.blue,
                  )
                      : const Icon(Icons.my_location, color: Colors.blue),
                ),
                const SizedBox(height: 10),
                FloatingActionButton(
                  backgroundColor: Colors.white,
                  onPressed: _showRouteBetweenLocations,
                  child: _isSearching
                      ? const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.green,
                  )
                      : const Icon(Icons.directions, color: Colors.green),
                ),
              ],
            ),
          ),
          
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
                child: Text(
                  _locationError,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(0, Icons.home, "Accueil"),
                  _buildNavItem(1, Icons.map, "Carte"),
                  _buildNavItem(2, Icons.favorite, "Favoris"),
                  _buildNavItem(3, Icons.person, "Profil"),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.transparent,
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.blue : Colors.grey,
              size: 22,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isSelected ? Colors.blue : Colors.grey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}