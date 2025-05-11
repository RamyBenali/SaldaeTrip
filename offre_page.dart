import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models/offre_model.dart';
import 'offre_details.dart';
import 'GlovalColors.dart';

final supabase = Supabase.instance.client;

class OffresPage extends StatefulWidget {
  @override
  _OffresPageState createState() => _OffresPageState();
}

class _OffresPageState extends State<OffresPage> {
  final primaryBackColor = GlobalColors.primaryColor;
  final cardColor = GlobalColors.cardColor;
  final textColor = GlobalColors.secondaryColor;
  final accentGlobalColor = GlobalColors.accentColor;
  List<Offre> offres = [];
  bool isLoading = true;
  String searchQuery = '';
  String? selectedVille;
  String? selectedCategorie;
  double? selectedTarifMax;
  final ScrollController _scrollController = ScrollController();

  final Map<String, Color> categoryColors = {
    'Hôtel': Color(0xFF0367A6),
    'Restaurant': Color(0xFFC5283D),
    'Loisirs': Color(0xFF6A4C93),
    'Plage': GlobalColors.bleuTurquoise,
    'Point d\'intérêt': Color(0xFF4CAF50),
  };

  @override
  void initState() {
    super.initState();
    fetchAllOffres();
  }

  Future<void> fetchAllOffres() async {
    try {
      debugPrint('Début de la récupération des offres...');

      final response = await supabase
          .from('offre')
          .select('''
          idoffre, nom, adresse, categorie, tarifs, images,
          offre_recommandations (priorite)
        ''')
          .order('offre_recommandations(priorite)', ascending: false);

      debugPrint('Réponse reçue: ${response.toString()}');
      debugPrint('Type de réponse: ${response.runtimeType}');

      List<Offre> loadedOffres = [];

      if (response is List) {
        loadedOffres = response.map((json) {
          debugPrint('Processing offre: ${json['nom']}');
          return Offre.fromJson(json);
        }).toList();
      } else if (response is Map) {
        loadedOffres.add(Offre.fromJson(response as Map<String, dynamic>));
      }

      if (mounted) {
        setState(() {
          offres = loadedOffres;
          isLoading = false;
        });
      }


      debugPrint('${loadedOffres.length} offres chargées avec succès');
    } catch (e) {
      debugPrint('Erreur fetchAllOffres: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
          offres = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de chargement: ${e.toString()}'),
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<double> getAverageRating(int offreId) async {
    try {
      final response = await supabase
          .from('avis')
          .select('note')
          .eq('idoffre', offreId);

      final data = response as List;
      if (data.isNotEmpty) {
        final total = data.fold(0.0, (sum, item) => sum + (item['note'] as num).toDouble());
        return total / data.length;
      }
      return 0.0;
    } catch (e) {
      print("Erreur avis : $e");
      return 0.0;
    }
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Rechercher une offre',
                  hintStyle: GoogleFonts.robotoSlab(color: textColor),
                  prefixIcon: Icon(Icons.search, color: GlobalColors.bleuTurquoise),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                ),
                onChanged: (value) => setState(() => searchQuery = value),
              ),
            ),
          ),
          SizedBox(width: 10),
          Container(
            decoration: BoxDecoration(
              color: GlobalColors.bleuTurquoise,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(Icons.filter_list, color: Colors.white, size: 22),
              onPressed: _showFilterSheet,
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet() {
    bool isDarkMode = GlobalColors.isDarkMode;
    final List<String> villes = ['Béjaïa', 'Melbou', 'Tichy', 'Akbou'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: primaryBackColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Container(
                          width: 50,
                          height: 4,
                          margin: EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: isDarkMode ? accentGlobalColor : Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Text(
                        'Filtrer les offres',
                        style: GoogleFonts.robotoSlab(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? accentGlobalColor : GlobalColors.bleuTurquoise,
                        ),
                      ),
                      SizedBox(height: 20),
                      _buildFilterField(
                        label: 'Catégorie',
                        value: selectedCategorie,
                        items: categoryColors.keys.toList(),
                        onChanged: (value) => setModalState(() => selectedCategorie = value),
                        icon: (cat) => Container(
                          width: 12,
                          height: 12,
                          margin: EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: categoryColors[cat],
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      _buildFilterField(
                        label: 'Ville',
                        value: selectedVille,
                        items: villes,
                        onChanged: (value) => setModalState(() => selectedVille = value),
                      ),
                      SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tarif maximum: ${selectedTarifMax?.round() ?? 0} DA',
                              style: GoogleFonts.robotoSlab(
                                fontSize: 16,
                                color: isDarkMode ? accentGlobalColor : Colors.grey[800],
                              ),
                            ),
                            SizedBox(height: 8),
                            Slider(
                              value: selectedTarifMax ?? 5000,
                              min: 0,
                              max: 10000,
                              divisions: 20,
                              activeColor: GlobalColors.bleuTurquoise,
                              inactiveColor: Colors.blue[100],
                              label: '${selectedTarifMax?.round() ?? 0} DA',
                              onChanged: (value) {
                                setModalState(() {
                                  selectedTarifMax = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 25),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () {
                                setState(() {
                                  selectedCategorie = null;
                                  selectedVille = null;
                                  selectedTarifMax = null;
                                });
                                Navigator.pop(context);
                              },
                              child: Text('Réinitialiser', style: GoogleFonts.robotoSlab(color: isDarkMode ? textColor : GlobalColors.bleuTurquoise)),
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDarkMode ? GlobalColors.bleuTurquoise : GlobalColors.bleuTurquoise,
                                padding: EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text('Appliquer', style: GoogleFonts.robotoSlab(color: isDarkMode ? Colors.white : Colors.white)),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterField({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    Widget Function(String)? icon,
  }) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
      value: value,
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Row(
            children: [
              if (icon != null) icon(item),
              Text(item, style: GoogleFonts.robotoSlab(color: accentGlobalColor)),
            ],
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildOffreCard(Offre offre) {
    bool isDarkMode = GlobalColors.isDarkMode;
    final categoryColor = categoryColors[offre.categorie] ?? Colors.grey[600];

    return Card(
      color: isDarkMode ? cardColor : Colors.grey[350],
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      elevation: offre.estRecommandee ? 4 : 1,
      child: Stack(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(15),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => OffreDetailPage(offre: offre)),
              );
            },
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 70,
                      height: 70,
                      color: cardColor,
                      child: (offre.images.isNotEmpty)
                          ? Image.network(
                        offre.images.first,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return _buildPlaceholderIcon(offre.categorie);
                        },
                      )
                          : _buildPlaceholderIcon(offre.categorie),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                offre.nom,
                                style: GoogleFonts.robotoSlab(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: textColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: categoryColor?.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                offre.categorie,
                                style: GoogleFonts.robotoSlab(
                                  color: categoryColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 14, color: accentGlobalColor),
                            SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                offre.adresse,
                                style: GoogleFonts.robotoSlab(
                                  fontSize: 12,
                                  color: accentGlobalColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              offre.tarifs.isEmpty ? Icons.money_off : Icons.attach_money,
                              size: 14,
                              color: accentGlobalColor,
                            ),
                            SizedBox(width: 4),
                            Text(
                              offre.tarifs.isEmpty ? 'Gratuit' : offre.tarifs,
                              style: GoogleFonts.robotoSlab(
                                fontSize: 12,
                                color: accentGlobalColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Spacer(),
                            Icon(Icons.star, size: 14, color: Colors.amber),
                            FutureBuilder<double>(
                              future: getAverageRating(offre.id),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return Container(
                                      width: 30,
                                      child: LinearProgressIndicator());
                                }
                                final rating = snapshot.data ?? 0.0;
                                return Text(
                                  rating.toStringAsFixed(1),
                                  style: GoogleFonts.robotoSlab(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                );
                              },
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
          if (offre.estRecommandee)
            Positioned(
              top: 8,
              left: 12,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.amber[300]!, Colors.amber[600]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Text(
                  'Recommandé',
                  style: GoogleFonts.robotoSlab(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 1,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderIcon(String category) {
    IconData icon;
    switch (category) {
      case 'Hôtel':
        icon = Icons.hotel;
        break;
      case 'Restaurant':
        icon = Icons.restaurant;
        break;
      case 'Plage':
        icon = Icons.beach_access;
        break;
      default:
        icon = Icons.place;
    }
    return Center(
      child: Icon(icon, size: 28, color: Colors.grey[400]),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 60, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'Aucune offre trouvée',
            style: GoogleFonts.robotoSlab(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          TextButton(
            onPressed: () {
              setState(() {
                searchQuery = '';
                selectedVille = null;
                selectedCategorie = null;
                selectedTarifMax = null;
              });
            },
            child: Text(
              'Réinitialiser les filtres',
              style: GoogleFonts.robotoSlab(color: Colors.blue[800]),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = GlobalColors.isDarkMode;

    // Triez les offres
    final sortedOffres = [...offres]
      ..sort((a, b) {
        // D'abord par recommandation
        if (a.estRecommandee != b.estRecommandee) {
          return b.estRecommandee ? 1 : -1;
        }
        // Ensuite par priorité si les deux sont recommandées
        if (a.estRecommandee && b.estRecommandee) {
          return b.prioriteRecommandation.compareTo(a.prioriteRecommandation);
        }
        // Enfin par nom
        return a.nom.compareTo(b.nom);
      });

    // Appliquez les filtres
    final filteredOffres = sortedOffres.where((offre) {
      final matchesSearch = searchQuery.isEmpty ||
          offre.nom.toLowerCase().contains(searchQuery.toLowerCase()) ||
          offre.adresse.toLowerCase().contains(searchQuery.toLowerCase());

      final matchesVille = selectedVille == null ||
          offre.adresse.toLowerCase().contains(selectedVille!.toLowerCase());

      final matchesCategory = selectedCategorie == null ||
          offre.categorie.toLowerCase() == selectedCategorie!.toLowerCase();

      final matchesTarif = selectedTarifMax == null ||
          offre.tarifs.isEmpty ||
          _extractFirstNumber(offre.tarifs) <= selectedTarifMax!;

      return matchesSearch && matchesVille && matchesCategory && matchesTarif;
    }).toList();

    return Scaffold(
      backgroundColor: primaryBackColor,
      appBar: AppBar(
        title: Text(
          'Toutes les offres',
          style: GoogleFonts.robotoSlab(
            color: isDarkMode ? textColor : GlobalColors.bleuTurquoise,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: primaryBackColor,
        elevation: 0,
        iconTheme: IconThemeData(color: isDarkMode ? textColor : GlobalColors.bleuTurquoise),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: isDarkMode ? textColor : Colors.blue[900]))
          : Column(
        children: [
          _buildSearchBar(),
          if (selectedVille != null || selectedCategorie != null || selectedTarifMax != null)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (selectedCategorie != null)
                      Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Chip(
                          label: Text(selectedCategorie!),
                          backgroundColor:
                          categoryColors[selectedCategorie]?.withOpacity(0.1),
                          deleteIcon: Icon(Icons.close, size: 16),
                          onDeleted: () => setState(() => selectedCategorie = null),
                        ),
                      ),
                    if (selectedVille != null)
                      Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Chip(
                          label: Text('Ville: $selectedVille'),
                          backgroundColor: Colors.blue[50],
                          deleteIcon: Icon(Icons.close, size: 16),
                          onDeleted: () => setState(() => selectedVille = null),
                        ),
                      ),
                    if (selectedTarifMax != null)
                      Chip(
                        label: Text('Max: ${selectedTarifMax!.toInt()} DA'),
                        backgroundColor: Colors.green[50],
                        deleteIcon: Icon(Icons.close, size: 16),
                        onDeleted: () => setState(() => selectedTarifMax = null),
                      ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: fetchAllOffres,
              color: Colors.blue[800],
              child: filteredOffres.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                controller: _scrollController,
                itemCount: filteredOffres.length,
                itemBuilder: (context, index) => _buildOffreCard(filteredOffres[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _extractFirstNumber(String tarifs) {
    try {
      if (tarifs.isEmpty) return 0.0;

      final match = RegExp(r'(\d+)').firstMatch(tarifs);
      if (match == null || match.group(0) == null) return 0.0;

      final numberString = match.group(0)!;
      return double.tryParse(numberString) ?? 0.0;
    } catch (e) {
      print("Erreur d'extraction du tarif: $e");
      return 0.0;
    }
  }
}
