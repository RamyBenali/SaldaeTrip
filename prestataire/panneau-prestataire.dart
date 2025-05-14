import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'GestionOffresPrestatairePage.dart';
import 'AjouterOffrePrestatairePage.dart';
import '../GlovalColors.dart';

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
    final cardColor = GlobalColors.isDarkMode ? Colors.grey[800]!.withOpacity(0.5) : Colors.white;
    final statCardColor = GlobalColors.cardColor;
    final actionCardColor = GlobalColors.cardColor;
    final textColor = GlobalColors.bleuTurquoise;
    final iconColor = GlobalColors.isDarkMode ? GlobalColors.bleuTurquoise : GlobalColors.bleuTurquoise;

    return Scaffold(
      backgroundColor: GlobalColors.primaryColor,
      appBar: AppBar(
        title: Text(
            'Tableau de bord Prestataire',
            style: GoogleFonts.robotoSlab(color: Colors.white)
        ),
        backgroundColor: GlobalColors.bleuTurquoise,
        iconTheme: IconThemeData(color: Colors.white),
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
                _buildStatCard("Visites", nbVisites, Icons.visibility, statCardColor!, iconColor!, textColor),
                _buildStatCard("Avis", nbAvis, Icons.reviews, statCardColor, iconColor!, textColor),
                _buildStatCard("Offres", nbOffres, Icons.local_offer, statCardColor, iconColor, textColor),
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
                  _buildActionCard(
                      "Voir mes Offres",
                      Icons.list,
                      actionCardColor!,
                      iconColor!,
                      textColor,
                          () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ListeOffresPrestatairePage()),
                        );
                      }
                  ),
                  _buildActionCard(
                      "Ajouter une Offre",
                      Icons.add_business,
                      actionCardColor!,
                      iconColor!,
                      textColor,
                          () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => AjouterOffrePrestatairePage()),
                        );
                      }
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, int value, IconData icon, Color bgColor, Color iconColor, Color textColor) {
    return Expanded(
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: bgColor,
        child: Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 36, color: iconColor),
              SizedBox(height: 12),
              Text(
                  title,
                  style: GoogleFonts.robotoSlab(
                      fontWeight: FontWeight.bold,
                      color: textColor
                  )
              ),
              SizedBox(height: 8),
              Text(
                  '$value',
                  style: GoogleFonts.robotoSlab(
                      fontSize: 24,
                      color: textColor
                  )
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color bgColor, Color iconColor, Color textColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: bgColor,
        child: Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: iconColor),
              SizedBox(height: 12),
              Text(
                  title,
                  style: GoogleFonts.robotoSlab(
                      fontWeight: FontWeight.w600,
                      color: textColor
                  )
              ),
            ],
          ),
        ),
      ),
    );
  }
}