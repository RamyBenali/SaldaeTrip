import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../favoris.dart';
import 'gestion-offres.dart';
import 'gestion-prestataire.dart';
import 'gestion-voyageur.dart';
import 'gestion-avis.dart';

class AdminPanelPage extends StatefulWidget {
  @override
  _AdminPanelPageState createState() => _AdminPanelPageState();
}

class _AdminPanelPageState extends State<AdminPanelPage> {
  int numVoyageurs = 0;
  int numPrestataires = 0;
  int numOffres = 0;
  int numAvis = 0;

  @override
  void initState() {
    super.initState();
    fetchStatistics();
  }

  // Fonction pour récupérer les statistiques
  Future<void> fetchStatistics() async {
    try {
      // Récupération du nombre de voyageurs
      final voyageurResponse = await supabase
          .from('personne')
          .select('idpersonne')
          .eq('role', 'Voyageur')
          .count();
      final prestataireResponse = await supabase
          .from('personne')
          .select('idpersonne')
          .eq('role', 'Prestataire')
          .count();
      final offreResponse = await supabase.from('offre').select('idoffre').count();
      final avisResponse = await supabase.from('avis').select('idavis').count();

      setState(() {
        // Accéder au premier (et seul) élément de la réponse pour récupérer le count
        numVoyageurs = voyageurResponse.count ?? 0;
        numPrestataires = prestataireResponse.count ?? 0;
        numOffres = offreResponse.count ?? 0;
        numAvis = avisResponse.count ?? 0;
      });
    } catch (e) {
      print("Erreur lors de la récupération des statistiques : $e");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Panneau Administrateur',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // GridView des actions administratives
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildAdminCard(
                    context,
                    icon: Icons.person,
                    title: 'Voyageurs',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => GestionVoyageurPage()),
                      );
                    },
                  ),
                  _buildAdminCard(
                    context,
                    icon: Icons.business,
                    title: 'Prestataires',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => GestionPrestatairePage()),
                      );
                    },
                  ),
                  _buildAdminCard(
                    context,
                    icon: Icons.local_offer,
                    title: 'Offres',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => GestionOffrePage()),
                      );
                    },
                  ),
                  _buildAdminCard(
                    context,
                    icon: Icons.reviews,
                    title: 'Avis',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => AdminAvisPage()),
                      );
                    },
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            // Section des statistiques en bas
            _buildStatSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statistiques',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueAccent),
        ),
        SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildStatCard("Voyageurs", numVoyageurs, Icons.person),
            _buildStatCard("Prestataires", numPrestataires, Icons.business),
          ],
        ),
        SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildStatCard("Offres", numOffres, Icons.local_offer),
            _buildStatCard("Avis", numAvis, Icons.reviews),
          ],
        ),
      ],
    );
  }

  Widget _buildAdminCard(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.blue[50],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.blueAccent),
              SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, int count, IconData icon) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.45, // Largeur fixe, ajustée
      height: 150, // Hauteur fixe pour uniformité
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.blue[100],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center, // Centrer le contenu
            children: [
              Icon(icon, size: 50, color: Colors.blueAccent), // Icone plus grande
              SizedBox(height: 1),
              Text(
                title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 2),
              Text(
                "$count",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueAccent),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


