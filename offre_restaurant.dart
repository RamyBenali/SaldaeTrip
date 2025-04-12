import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:untitled/models/offre_model.dart';
import 'offre_details.dart';

final supabase = Supabase.instance.client;

class OffreRestaurantPage extends StatefulWidget {
  @override
  _OffreRestaurantPageState createState() => _OffreRestaurantPageState();
}

class _OffreRestaurantPageState extends State<OffreRestaurantPage> {
  List<Offre> offres = [];
  bool isLoading = true;
  String searchQuery = '';
  String? selectedVille;
  double? selectedTarifMax;

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
          .eq('categorie', 'Restaurant');
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

  Widget buildFilterSheet() {
    List<String> villes = [
      'Béjaïa',
      'Béjaïa centre',
      'Melbou',
      'Tichy',
      'Elkseur',
      'Akbou'
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Filtres',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Ville',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: villes.map((v) {
              return DropdownMenuItem(value: v, child: Text(v));
            }).toList(),
            onChanged: (value) => setState(() => selectedVille = value),
          ),
          const SizedBox(height: 12),
          TextField(
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Tarif max en DA',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) {
              setState(() {
                selectedTarifMax = double.tryParse(value);
              });
            },
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              setState(() {}); // Appliquer les filtres
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: EdgeInsets.symmetric(vertical: 14, horizontal: 32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('Appliquer les filtres'),
          )
        ],
      ),
    );
  }

  @override
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Offres Restaurants', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.blueAccent,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Rechercher une offre...',
                        prefixIcon: Icon(Icons.search, color: Colors.white),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.filter_alt_outlined, color: Colors.white),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        builder: (context) => buildFilterSheet(),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: filteredOffres.length,
              itemBuilder: (context, index) {
                final offre = filteredOffres[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OffreDetailPage(offre: offre),
                      ),
                    );
                  },
                  child: Card(
                    margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 5,
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16.0),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          offre.image,
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                        ),
                      ),
                      title: Text(
                        offre.nom,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        '${offre.categorie} - ${offre.tarifs}',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
