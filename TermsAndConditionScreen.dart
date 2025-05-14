import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'GlovalColors.dart';
import 'login.dart';

class TermsAndConditionsScreen extends StatefulWidget {
  const TermsAndConditionsScreen({Key? key}) : super(key: key);

  @override
  State<TermsAndConditionsScreen> createState() => _TermsAndConditionsScreenState();
}

class _TermsAndConditionsScreenState extends State<TermsAndConditionsScreen> {
  bool _isAccepted = false;
  final Color primaryColor = const Color(0xFF0D8BFF);
  final Color backgroundColor = Colors.grey[50]!;
  final Color textColor = Colors.grey[800]!;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Conditions Générales',
          style: GoogleFonts.robotoSlab(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: GlobalColors.bleuTurquoise,
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bienvenue sur notre application',
                              style: GoogleFonts.robotoSlab(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: GlobalColors.bleuTurquoise,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Divider(color: Colors.grey[300]),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text(
                          "En vous inscrivant, vous acceptez les règles suivantes :\n\n"
                              "1. Respectez les autres utilisateurs et les guides touristiques.\n\n"
                              "2. Ne partagez pas de contenu inapproprié ou illégal.\n\n"
                              "3. Les informations fournies doivent être exactes et à jour.\n\n"
                              "4. Les réservations doivent être honorées ou annulées à l'avance.\n\n"
                              "5. Suivez les consignes de sécurité lors des excursions et visites.\n\n"
                              "En cochant la case ci-dessous, vous acceptez ces conditions générales et acceptez d'utiliser l'application conformément à ces règles.",
                          style: GoogleFonts.robotoSlab(
                            fontSize: 15,
                            height: 1.5,
                            color: textColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                child: Row(
                  children: [
                    Transform.scale(
                      scale: 1.2,
                      child: Checkbox(
                        value: _isAccepted,
                        onChanged: (value) => setState(() => _isAccepted = value!),
                        activeColor: GlobalColors.bleuTurquoise,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "J'accepte les conditions générales d'utilisation",
                        style: GoogleFonts.robotoSlab(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isAccepted
                    ? () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                )
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: GlobalColors.bleuTurquoise,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                ),
                child: Text(
                  "Continuer",
                  style: GoogleFonts.robotoSlab(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}