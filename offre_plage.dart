import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models/offre_model.dart';
import 'offre_details.dart';
import 'GlovalColors.dart';

final supabase = Supabase.instance.client;

class OffrePlagePage extends StatefulWidget {
  @override
  _OffrePlagePageState createState() => _OffrePlagePageState();
}

class _OffrePlagePageState extends State<OffrePlagePage> {
  final primaryBackColor = GlobalColors.primaryColor;
  final cardColor = GlobalColors.cardColor;
  final textColor = GlobalColors.secondaryColor;
  final accentGlobalColor = GlobalColors.accentColor;
  List<Offre> offres = [];
  bool isLoading = true;
  String searchQuery = '';
  String? selectedVille;
  double? selectedTarifMax;
  final ScrollController _scrollController = ScrollController();
  bool isFree = true;

  final Color primaryColor = Color(0xFF1E88E5);  // Bleu vif (océan)
  final Color secondaryColor = Color(0xFF4FC3F7); // Bleu clair (vagues)
  final Color accentColor = Color(0xFFFFD54F);    // Jaune doré (sable)

  final Color darkBlue = Color(0xFF0D47A1);      // Bleu profond
  final Color lightSand = Color(0xFFFFF176);     // Sable clair
  final Color whiteFoam = Color(0xFFE3F2FD);     // Écume
  final Color bleuTurquoise = Color(0xFF41A6B4);

  @override
  void initState() {
    super.initState();
    fetchOffres();
  }

  Future<void> fetchOffres() async {
    try {
      debugPrint('Début de la récupération des offres...');

      final response = await supabase
          .from('offre')
          .select('''
          idoffre, nom,description , adresse, categorie, tarifs, images,
          offre_recommandations (priorite)
        ''')
          .eq('categorie', 'Plage')
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
        final totalRating = data.fold(0.0, (sum, element) => sum + (element['note'] as num).toDouble());
        return totalRating / data.length;
      }
      return 0.0;
    } catch (e) {
      print("Erreur lors de la récupération des avis : $e");
      return 0.0;
    }
  }

  Widget buildFilterSheet() {
    List<String> villes = [
      'Béjaïa',
      'Béjaïa centre',
      'Melbou',
      'Tichy',
      'Elkseur',
      'Akbou'
    ];

    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setModalState) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                GlobalColors.cardColor.withOpacity(0.9),
                GlobalColors.cardColor.withOpacity(0.9),
              ],
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 60,
                      height: 5,
                      decoration: BoxDecoration(
                        color: GlobalColors.bleuTurquoise.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Filtrer les restaurants',
                    style: GoogleFonts.robotoSlab(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: GlobalColors.bleuTurquoise,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Localisation',
                    style: GoogleFonts.robotoSlab(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: GlobalColors.bleuTurquoise,
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: GlobalColors.accentColor.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonFormField<String>(
                      dropdownColor: GlobalColors.cardColor,
                      style: GoogleFonts.robotoSlab(color: GlobalColors.secondaryColor),
                      decoration: InputDecoration(
                        labelStyle: GoogleFonts.robotoSlab(color: GlobalColors.secondaryColor),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      ),
                      items: villes.map((v) {
                        return DropdownMenuItem(
                          value: v,
                          child: Text(v, style: GoogleFonts.robotoSlab(fontSize: 14)),
                        );
                      }).toList(),
                      onChanged: (value) => setModalState(() => selectedVille = value),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Budget maximum',
                    style: GoogleFonts.robotoSlab(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: GlobalColors.bleuTurquoise,
                    ),
                  ),
                  SizedBox(height: 8),
                  Slider(
                    value: selectedTarifMax ?? 5000,
                    min: 500,
                    max: 10000,
                    divisions: 19,
                    activeColor: GlobalColors.bleuTurquoise,
                    inactiveColor: secondaryColor.withOpacity(0.2),
                    label: '${(selectedTarifMax ?? 5000).round()} DA',
                    onChanged: (value) {
                      print("Nouvelle valeur du slider: $value");
                      setModalState(() {
                        selectedTarifMax = value;
                      });
                    },
                  ),
                  SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {}); // Met à jour l'écran parent
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GlobalColors.bleuTurquoise,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: Text(
                      'Appliquer les filtres',
                      style: GoogleFonts.robotoSlab(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  TextButton(
                    onPressed: () {
                      setModalState(() {
                        selectedVille = null;
                        selectedTarifMax = null;
                      });
                    },
                    child: Text(
                      'Réinitialiser les filtres',
                      style: GoogleFonts.robotoSlab(
                        color: GlobalColors.bleuTurquoise,
                        fontWeight: FontWeight.w600,
                      ),
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

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Rechercher une plage...',
                      hintStyle: GoogleFonts.robotoSlab(color: textColor),
                      prefixIcon: Icon(Icons.search, color: bleuTurquoise),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                  ),
                ),
              ),
              SizedBox(width: 10),
              Container(
                decoration: BoxDecoration(
                  color: bleuTurquoise,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(Icons.filter_list, color: Colors.white),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => buildFilterSheet(),
                    );
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          if (selectedVille != null || selectedTarifMax != null)
            Wrap(
              spacing: 8,
              children: [
                if (selectedVille != null)
                  Chip(
                    label: Text('Ville: $selectedVille'),
                    backgroundColor: Colors.white,
                    deleteIcon: Icon(Icons.close, size: 16, color: primaryColor),
                    onDeleted: () {
                      setState(() {
                        selectedVille = null;
                      });
                    },
                  ),
                if (selectedTarifMax != null)
                  Chip(
                    label: Text('Max: ${selectedTarifMax!.toInt()} DA'),
                    backgroundColor: Colors.white,
                    deleteIcon: Icon(Icons.close, size: 16, color: primaryColor),
                    onDeleted: () {
                      setState(() {
                        selectedTarifMax = null;
                      });
                    },
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildOffreCard(Offre offre) {
    return FutureBuilder<double>(
      future: getAverageRating(offre.id),
      builder: (context, snapshot) {
        final averageRating = snapshot.data ?? 0.0;

        return Container(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            child: Stack(
              children: [
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: offre.estRecommandee
                        ? BorderSide(color: accentColor, width: 2)
                        : BorderSide.none,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                        child: Stack(
                          children: [
                            Image.network(
                              offre.images.isNotEmpty ? offre.images.first : '',
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  height: 180,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Colors.transparent, primaryColor.withOpacity(0.3)],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                  ),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                          : null,
                                      color: Colors.white,
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 180,
                                  color: primaryColor.withOpacity(0.1),
                                  child: Center(
                                    child: Icon(Icons.hotel, size: 50, color: primaryColor),
                                  ),
                                );
                              },
                            ),
                            Container(
                              height: 180,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.5),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    offre.nom,
                                    style: GoogleFonts.robotoSlab(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (averageRating > 0)
                                  Row(
                                    children: [
                                      Text(
                                        averageRating.toStringAsFixed(1),
                                        style: GoogleFonts.robotoSlab(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.amber[800],
                                        ),
                                      ),
                                      Icon(Icons.star, color: Colors.amber, size: 18),
                                    ],
                                  ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.location_on, size: 16, color: primaryColor),
                                SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    offre.adresse,
                                    style: GoogleFonts.robotoSlab(
                                      color: accentGlobalColor,
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  offre.tarifs.isEmpty ? Icons.money_off : Icons.attach_money,
                                  size: 16,
                                  color: offre.tarifs.isEmpty ? textColor.withOpacity(0.8) : Colors.green[700],
                                ),
                                SizedBox(width: 4),
                                Text(
                                  offre.tarifs.isEmpty ? 'Prix non spécifié' : offre.tarifs,
                                  style: GoogleFonts.robotoSlab(
                                    color: offre.tarifs.isEmpty ? textColor.withOpacity(0.8) : Colors.green[700],
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
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
                if (offre.estRecommandee)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [accentColor, Colors.amber[700]!],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '⭐ Recommandé',
                        style: GoogleFonts.robotoSlab(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, color: accentColor, size: 16),
                        SizedBox(width: 4),
                        Text(
                          averageRating.toStringAsFixed(1),
                          style: GoogleFonts.robotoSlab(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final sortedOffres = [...offres]
      ..sort((a, b) {
        if (a.estRecommandee != b.estRecommandee) {
          return b.estRecommandee ? 1 : -1;
        }
        if (a.estRecommandee && b.estRecommandee) {
          return b.prioriteRecommandation.compareTo(a.prioriteRecommandation);
        }
        return a.nom.compareTo(b.nom);
      });

    final filteredOffres = sortedOffres.where((offre) {
      final matchesSearch = searchQuery.isEmpty ||
          offre.nom.toLowerCase().contains(searchQuery.toLowerCase()) ||
          offre.adresse.toLowerCase().contains(searchQuery.toLowerCase());

      final matchesVille = selectedVille == null ||
          offre.adresse.toLowerCase().contains(selectedVille!.toLowerCase());

      final matchesTarif = selectedTarifMax == null ||
          offre.tarifs.isEmpty ||
          _extractFirstNumber(offre.tarifs)! <= selectedTarifMax!;

      return matchesSearch && matchesVille && matchesTarif;
    }).toList();

    return Scaffold(
      backgroundColor: primaryBackColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        centerTitle: false,
        title: Text(
          'Plages 🏖️',
          style: GoogleFonts.robotoSlab(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 4,
                offset: Offset(1, 1),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              primaryColor.withOpacity(0.2),
              primaryBackColor,
            ],
            stops: [0.0, 0.3],
          ),
        ),
        child: isLoading
            ? Center(child: CircularProgressIndicator(color: primaryColor))
            : Column(
          children: [
            SizedBox(height: MediaQuery.of(context).padding.top + kToolbarHeight),
            _buildSearchBar(),
            SizedBox(height: 10),
            Expanded(
              child: RefreshIndicator(
                onRefresh: fetchOffres,
                color: primaryColor,
                child: filteredOffres.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 60, color: Colors.grey[400]),
                      SizedBox(height: 16),
                      Text(
                        'Aucune plage trouvé',
                        style: GoogleFonts.robotoSlab(
                          color: Colors.grey[600],
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Essayez de modifier vos critères',
                        style: GoogleFonts.robotoSlab(
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
                    : ListView.builder(
                  controller: _scrollController,
                  physics: AlwaysScrollableScrollPhysics(),
                  itemCount: filteredOffres.length,
                  itemBuilder: (context, index) {
                    return _buildOffreCard(filteredOffres[index]);
                  },
                ),
              ),
            ),
          ],
        ),
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
      debugPrint("Erreur d'extraction du tarif: $e");
      return 0.0;
    }
  }
}
