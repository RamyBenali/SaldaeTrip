import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models/offre_model.dart';
import 'offre_details.dart';

final supabase = Supabase.instance.client;

class OffresPage extends StatefulWidget {
  @override
  _OffresPageState createState() => _OffresPageState();
}

class _OffresPageState extends State<OffresPage> {
  List<Offre> offres = [];
  bool isLoading = true;
  String searchQuery = '';
  String? selectedVille;
  String? selectedCategorie;
  double? selectedTarifMax;
  final ScrollController _scrollController = ScrollController();

  // Couleurs par catégorie cohérentes avec votre DA
  final Map<String, Color> categoryColors = {
    'Hôtel': Color(0xFF0367A6),
    'Restaurant': Color(0xFFC5283D),
    'Loisirs': Color(0xFF6A4C93),
    'Plage': Color(0xFF1E88E5),
    'Point d\'intérêt': Color(0xFF4CAF50),
  };

  @override
  void initState() {
    super.initState();
    fetchAllOffres();
  }

  Future<void> fetchAllOffres() async {
    try {
      final response = await supabase.from('offre').select();
      final data = response as List;

      setState(() {
        offres = data.map((json) => Offre.fromJson(json)).toList();
        isLoading = false;
      });
    } catch (e) {
      print("Erreur lors de la récupération : $e");
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
                color: Colors.white,
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
                  hintText: 'Rechercher...',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  prefixIcon: Icon(Icons.search, color: Colors.blue[800]),
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
              color: Colors.blue[800],
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
    final List<String> villes = ['Béjaïa', 'Melbou', 'Tichy', 'Akbou'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
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
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  'Filtrer les offres',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
                SizedBox(height: 20),
                _buildFilterField(
                  label: 'Catégorie',
                  value: selectedCategorie,
                  items: categoryColors.keys.toList(),
                  onChanged: (value) => setState(() => selectedCategorie = value),
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
                  onChanged: (value) => setState(() => selectedVille = value),
                ),
                SizedBox(height: 16),
                TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Tarif maximum (DA)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  onChanged: (value) => setState(() {
                    selectedTarifMax = double.tryParse(value);
                  }),
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
                        child: Text('Réinitialiser'),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[800],
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text('Appliquer'),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
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
              Text(item),
            ],
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildOffreCard(Offre offre) {
    // Couleur par défaut si la catégorie n'est pas trouvée
    final categoryColor = categoryColors[offre.categorie] ?? Colors.grey[600];

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      elevation: 1,
      child: InkWell(
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
              // Image de l'offre
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 70,
                  height: 70,
                  color: Colors.grey[200],
                  child: (offre.image != null && offre.image.isNotEmpty)
                      ? Image.network(
                    offre.image,
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
                      return _buildPlaceholderIcon(offre.categorie ?? '');
                    },
                  )
                      : _buildPlaceholderIcon(offre.categorie ?? ''),
                ),
              ),
              SizedBox(width: 12),
              // Détails texte
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nom et catégorie
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            offre.nom ?? 'Nom non disponible',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
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
                            offre.categorie ?? 'Autre',
                            style: TextStyle(
                              color: categoryColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    // Adresse
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            offre.adresse ?? 'Adresse non disponible',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    // Tarif et note
                    Row(
                      children: [
                        // Tarif
                        Icon(
                          (offre.tarifs == null || offre.tarifs!.isEmpty)
                              ? Icons.money_off
                              : Icons.attach_money,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        SizedBox(width: 4),
                        Text(
                          (offre.tarifs == null || offre.tarifs!.isEmpty)
                              ? 'Gratuit'
                              : offre.tarifs!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[800],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Spacer(),
                        // Note
                        Icon(Icons.star, size: 14, color: Colors.amber),
                        FutureBuilder<double>(
                          future: getAverageRating(offre.id ?? 0),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return Container(
                                  width: 30,
                                  child: LinearProgressIndicator());
                            }
                            final rating = snapshot.data ?? 0.0;
                            return Text(
                              rating.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
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
            style: TextStyle(
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
              style: TextStyle(color: Colors.blue[800]),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredOffres = offres.where((offre) {
      // Filtre recherche
      final matchesSearch = searchQuery.isEmpty ||
          offre.nom.toLowerCase().contains(searchQuery.toLowerCase()) ||
          offre.adresse.toLowerCase().contains(searchQuery.toLowerCase());

      // Filtre ville
      final matchesVille = selectedVille == null ||
          offre.adresse.toLowerCase().contains(selectedVille!.toLowerCase());

      // Filtre catégorie
      final matchesCategory = selectedCategorie == null ||
          offre.categorie.toLowerCase() == selectedCategorie!.toLowerCase();

      // Filtre tarif
      final matchesTarif = selectedTarifMax == null ||
          offre.tarifs!.isEmpty ?? true ||
          _extractFirstNumber(offre.tarifs!) <= selectedTarifMax!;

      return matchesSearch && matchesVille && matchesCategory && matchesTarif;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Toutes les offres',
          style: TextStyle(
            color: Colors.blue[900],
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.blue[800]),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.blue[800]))
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
                itemBuilder: (context, index) =>
                    _buildOffreCard(filteredOffres[index]),
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