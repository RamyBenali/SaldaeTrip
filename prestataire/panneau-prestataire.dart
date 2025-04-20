import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'GestionOffresPrestatairePage.dart';
import 'AjouterOffrePrestatairePage.dart';

class PanneauPrestatairePage extends StatefulWidget {
  const PanneauPrestatairePage({super.key});

  @override
  State<PanneauPrestatairePage> createState() => _PanneauPrestatairePageState();
}

class _PanneauPrestatairePageState extends State<PanneauPrestatairePage> {
  int nbVisites = 0;
  int nbAvis = 0;
  int nbOffres = 0;

  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    fetchStats();
  }


  Future<void> fetchStats() async {
    final user = Supabase.instance.client.auth.currentUser;

    if(user == null){
      print("erreur");
      return;
    }

    try {
      final offresResponse = await supabase
          .from('offre')
          .select('idoffre')
          .eq('user_id', user.id);

      final offres = (offresResponse as List).cast<Map<String, dynamic>>();
      final offresIds = offres.map((e) => e['idoffre']).toList();

      setState(() {
        nbOffres = offres.length;
      });

      // Récupération des visites de ces offres
      final visitesResponse = await supabase
          .from('voyageur_offre')
          .select('nombres_visites, idoffre');

      final visites = (visitesResponse as List).cast<Map<String, dynamic>>();

      int totalVisites = 0;
      for (var item in visites) {
        if (offresIds.contains(item['idoffre'])) {
          totalVisites += (item['nombres_visites'] as num).toInt();
        }
      }

      // Récupération des avis liés à ses offres
      final avisResponse = await supabase
          .from('avis')
          .select('idavis, idoffre');

      final avis = (avisResponse as List).cast<Map<String, dynamic>>();

      int totalAvis = avis.where((a) => offresIds.contains(a['idoffre'])).length;

      setState(() {
        nbVisites = totalVisites;
        nbAvis = totalAvis;
      });
    } catch (e) {
      print("Erreur de récupération des stats : $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tableau de bord Prestataire', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Statistiques
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatCard("Visites", nbVisites, Icons.visibility),
                _buildStatCard("Avis", nbAvis, Icons.reviews),
                _buildStatCard("Offres", nbOffres, Icons.local_offer),
              ],
            ),
            SizedBox(height: 30),
            // Actions
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildActionCard("Voir mes Offres", Icons.list, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ListeOffresPrestatairePage()),
                    );                  }),
                  _buildActionCard("Ajouter une Offre", Icons.add_business, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AjouterOffrePrestatairePage()),
                    );
                  }),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, int value, IconData icon) {
    return Expanded(
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 36, color: Colors.green),
              SizedBox(height: 12),
              Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('$value', style: TextStyle(fontSize: 24)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.green[100],
            borderRadius: BorderRadius.circular(16),
          ),
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.green[800]),
              SizedBox(height: 12),
              Text(title, style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
