import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login.dart';

class TermsAndConditionsScreen extends StatefulWidget {
  @override
  _TermsAndConditionsScreenState createState() => _TermsAndConditionsScreenState();
}

class _TermsAndConditionsScreenState extends State<TermsAndConditionsScreen> {
  bool _isAccepted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Conditions Générales'),
        backgroundColor: Color(0xFF0D8BFF),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  "Bienvenue sur notre application de tourisme ! En vous inscrivant, vous acceptez les règles suivantes :\n\n"
                      "1. Respectez les autres utilisateurs et les guides touristiques.\n"
                      "2. Ne partagez pas de contenu inapproprié ou illégal.\n"
                      "3. Les informations fournies doivent être exactes et à jour.\n"
                      "4. Les réservations doivent être honorées ou annulées à l'avance.\n"
                      "5. Suivez les consignes de sécurité lors des excursions et visites.\n\n"
                      "En cochant la case ci-dessous, vous acceptez ces conditions générales et acceptez d'utiliser l'application conformément à ces règles.",
                  style: GoogleFonts.robotoSlab(fontSize: 16),
                ),
              ),
            ),
            Row(
              children: [
                Checkbox(
                  value: _isAccepted,
                  onChanged: (value) {
                    setState(() {
                      _isAccepted = value!;
                    });
                  },
                ),
                Expanded(
                  child: Text("J'accepte les conditions générales d'utilisation"),
                ),
              ],
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isAccepted
                  ? () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF0D8BFF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
                minimumSize: Size(double.infinity, 50),
              ),
              child: Text("Continuer", style: GoogleFonts.robotoSlab(color: Colors.white, fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
