import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models/offre_model.dart';
import 'offre_details.dart';

final supabase = Supabase.instance.client;

class OffrePlagePage extends StatefulWidget {
  @override
  _OffrePlagePageState createState() => _OffrePlagePageState();
}

class _OffrePlagePageState extends State<OffrePlagePage> {
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

  @override
  void initState() {
    super.initState();
    fetchOffres();
  }

  Future<void> fetchOffres() async {
    try {
      final response = await supabase
          .from('offre')
          .select()
          .eq('categorie', 'Plage');
      final data = response as List;

      setState(() {
        offres = data.map((json) => Offre.fromJson(json)).toList();
        isLoading = false;
      });

    } catch (e) {
      print("Erreur lors du fetch : $e");
      setState(() {
        isLoading = false;
      });
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
                primaryColor.withOpacity(0.95),
                primaryColor.withOpacity(0.9),
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
                        color: Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Filtrer les restaurants',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Localisation',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonFormField<String>(
                      dropdownColor: primaryColor,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Ville',
                        labelStyle: TextStyle(color: Colors.white70),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      ),
                      items: villes.map((v) {
                        return DropdownMenuItem(
                          value: v,
                          child: Text(v, style: TextStyle(fontSize: 14)),
                        );
                      }).toList(),
                      onChanged: (value) => setModalState(() => selectedVille = value),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Budget maximum',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Slider(
                    value: selectedTarifMax ?? 5000,
                    min: 500,
                    max: 10000,
                    divisions: 19,
                    activeColor: accentColor,
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
                      backgroundColor: accentColor,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: Text(
                      'Appliquer les filtres',
                      style: TextStyle(
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
                      style: TextStyle(
                        color: Colors.white,
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
                    color: Colors.white,
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
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      prefixIcon: Icon(Icons.search, color: primaryColor),
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
                  color: primaryColor,
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
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                        child: Stack(
                          children: [
                            Image.network(
                              offre.image,
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
                                  color: whiteFoam,
                                  child: Row(
                                    children: [
                                      Icon(Icons.umbrella, color: accentColor),
                                      Text('Plage de...', style: TextStyle(color: darkBlue)),
                                    ],
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
                            Positioned(
                              bottom: 10,
                              left: 10,
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.beach_access, size: 16, color: Colors.white),
                                    SizedBox(width: 4),
                                    Text(
                                      offre.categorie,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
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
                          color: Colors.white,
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
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[900],
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
                                        style: TextStyle(
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
                                    style: TextStyle(
                                      color: Colors.grey[700],
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
                                  offre.tarifs?.isEmpty ?? true ? Icons.money_off : Icons.attach_money,
                                  size: 16,
                                  color: offre.tarifs?.isEmpty ?? true ? Colors.grey[600] : Colors.green[700],
                                ),
                                SizedBox(width: 4),
                                Text(
                                  offre.tarifs?.isEmpty ?? true ? 'Entrée gratuite' : offre.tarifs!,
                                  style: TextStyle(
                                    color: offre.tarifs?.isEmpty ?? true ? Colors.grey[600] : Colors.green[700],
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
                          style: TextStyle(
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
    final filteredOffres = offres.where((offre) {
      final query = searchQuery.toLowerCase();
      final matchQuery = offre.nom.toLowerCase().contains(query) ||
          offre.categorie.toLowerCase().contains(query) ||
          offre.adresse.toLowerCase().contains(query);
      final matchVille = selectedVille == null ||
          offre.adresse.toLowerCase().contains(selectedVille!.toLowerCase());
      final matchTarif = selectedTarifMax == null ||
          (() {
            final regex = RegExp(r'(\d+)(?=\s*-|\s*D|\s*da|\s*$)', caseSensitive: false);
            final match = regex.firstMatch(offre.tarifs);
            if (match == null) return true;
            final firstNumberString = match.group(0);
            final firstNumber = int.tryParse(firstNumberString ?? '0');
            if (firstNumber == null) return true;
            return firstNumber <= selectedTarifMax!;
          })();
      return matchQuery && matchVille && matchTarif;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        centerTitle: false,
        title: Text(
          'Plages 🏖️',
          style: TextStyle(
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
              Colors.grey[100]!,
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
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Essayez de modifier vos critères',
                        style: TextStyle(
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
}
