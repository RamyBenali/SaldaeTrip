import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../favoris.dart';
import 'gestion-offres.dart';
import 'gestion-prestataire.dart';
import 'gestion-voyageur.dart';
import 'gestion-avis.dart';
import 'GestionRecommendations.dart';
import '../GlovalColors.dart';

class AdminPanelPage extends StatefulWidget {
  @override
  _AdminPanelPageState createState() => _AdminPanelPageState();
}

class _AdminPanelPageState extends State<AdminPanelPage> {
  final primaryBackColor = GlobalColors.primaryColor;
  final cardColor = GlobalColors.cardColor;
  final textColor = GlobalColors.secondaryColor;
  final accentGlobalColor = GlobalColors.accentColor;
  final supabase = Supabase.instance.client;
  int numVoyageurs = 0;
  int numPrestataires = 0;
  int numOffres = 0;
  int numAvis = 0;
  int numRecommandations = 0;

  @override
  void initState() {
    super.initState();
    fetchStatistics();
  }

  Future<void> fetchStatistics() async {
    try {
      final voyageurResponse = await supabase
          .from('personne')
          .select('user_id')
          .eq('role', 'Voyageur')
          .count();
      final prestataireResponse = await supabase
          .from('personne')
          .select('user_id')
          .eq('role', 'Prestataire')
          .count();
      final offreResponse = await supabase.from('offre').select('idoffre').count();
      final avisResponse = await supabase.from('avis').select('idavis').count();
      final recommandationResponse = await supabase.from('offre_recommandations').select('id').count();

      setState(() {
        numVoyageurs = voyageurResponse.count ?? 0;
        numPrestataires = prestataireResponse.count ?? 0;
        numOffres = offreResponse.count ?? 0;
        numAvis = avisResponse.count ?? 0;
        numRecommandations = recommandationResponse.count ?? 0;
      });
    } catch (e) {
      print("Erreur lors de la récupération des statistiques : $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryBackColor,
      appBar: AppBar(
        title: Text(
          'Panneau Administrateur',
          style: GoogleFonts.robotoSlab(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section des cartes d'administration
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                childAspectRatio: 1.2, // Rend les cartes plus carrées
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
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
                  _buildAdminCard(
                    context,
                    icon: Icons.star,
                    title: 'Recommandations',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => GestionRecommandationsPage()),
                      );
                    },
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            // Section des statistiques compacte
            _buildCompactStatSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactStatSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statistiques',
          style: GoogleFonts.robotoSlab(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent
          ),
        ),
        SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildCompactStatCard("Voyageurs", numVoyageurs, Icons.person),
              SizedBox(width: 8),
              _buildCompactStatCard("Prestataires", numPrestataires, Icons.business),
              SizedBox(width: 8),
              _buildCompactStatCard("Offres", numOffres, Icons.local_offer),
              SizedBox(width: 8),
              _buildCompactStatCard("Avis", numAvis, Icons.reviews),
              SizedBox(width: 8),
              _buildCompactStatCard("Recommandations", numRecommandations, Icons.star),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAdminCard(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap}) {
    bool isDarkMode = GlobalColors.isDarkMode;
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isDarkMode ? cardColor : Colors.blue[50],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: Colors.blueAccent),
              SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.robotoSlab(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : Colors.black
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactStatCard(String title, int count, IconData icon) {
    bool isDarkMode = GlobalColors.isDarkMode;
    return Container(
      width: 110,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: isDarkMode ? cardColor : Colors.blue[100],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 28, color: Colors.blueAccent),
              SizedBox(height: 4),
              Text(
                title,
                style: GoogleFonts.robotoSlab(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : Colors.black
                ),
              ),
              SizedBox(height: 4),
              Text(
                "$count",
                style: GoogleFonts.robotoSlab(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}