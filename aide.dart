import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'GlovalColors.dart';
import 'package:url_launcher/url_launcher.dart';


class AidePage extends StatefulWidget {
  @override
  _AidePageState createState() => _AidePageState();
}

class _AidePageState extends State<AidePage> {
  final List<FAQItem> faqs = [
    FAQItem(
      question: "Comment créer un compte ?",
      answer:
      "Pour créer un compte, cliquez sur 'Inscription' depuis le menu de navigation. Remplissez le formulaire avec vos informations personnelles et validez. Vous recevrez un email de confirmation pour activer votre compte.",
    ),
    FAQItem(
      question: "Comment devenir prestataire de services ?",
      answer:
      "Dans le menu latéral, sélectionnez 'Devenir Prestataire'. Vous serez redirigé vers un formulaire à remplir. Notre équipe examinera votre demande et vous contactera sous 48 heures.",
    ),
    FAQItem(
      question: "Comment ajouter un lieu à mes favoris ?",
      answer:
      "Sur la carte, cliquez sur un lieu pour voir ses détails. Un bouton 'Ajouter aux favoris' apparaîtra. Vous pouvez aussi maintenir appuyé sur un lieu dans la liste des résultats pour l'ajouter rapidement.",
    ),
    FAQItem(
      question: "Comment fonctionne la météo intégrée ?",
      answer:
      "La météo s'affiche automatiquement en fonction de votre localisation. Vous pouvez personnaliser les préférences météo dans votre profil pour recevoir des recommandations adaptées.",
    ),
    FAQItem(
      question: "Comment contacter le support client ?",
      answer:
      "Notre chatbot est disponible 24/7 via le menu latéral. Pour un contact humain, envoyez un email à support@voyageo.com ou appelez le +33 1 23 45 67 89 (9h-18h, du lundi au vendredi).",
    ),
    FAQItem(
      question: "Comment modifier mes informations personnelles ?",
      answer:
      "Allez dans votre profil et cliquez sur l'icône de modification en haut à droite. Vous pouvez changer toutes vos informations sauf l'email qui nécessite une vérification de sécurité.",
    ),
    FAQItem(
      question: "L'application est-elle gratuite ?",
      answer:
      "Oui, l'application est entièrement gratuite pour les utilisateurs. Les prestataires de services payent une commission modérée sur les réservations effectuées via la plateforme.",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GlobalColors.primaryColor,
      appBar: AppBar(
        backgroundColor: GlobalColors.bleuTurquoise,
        title: Text(
          'Centre d\'aide',
          style: GoogleFonts.robotoSlab(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSearchBar(),
            SizedBox(height: 20),
            Text(
              'Foire aux questions',
              style: GoogleFonts.robotoSlab(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: GlobalColors.secondaryColor,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Trouvez rapidement des réponses à vos questions',
              style: GoogleFonts.robotoSlab(
                fontSize: 14,
                color: GlobalColors.secondaryColor.withOpacity(0.7),
              ),
            ),
            SizedBox(height: 30),
            ...faqs.map((faq) => _buildFAQItem(faq)).toList(),
            SizedBox(height: 40),
            _buildContactCard(),
            SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: GlobalColors.isDarkMode
            ? GlobalColors.accentColor.withOpacity(0.1)
            : Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: GlobalColors.isDarkMode
            ? []
            : [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Rechercher dans l\'aide...',
          hintStyle: GoogleFonts.robotoSlab(
            color: GlobalColors.secondaryColor.withOpacity(0.5),
          ),
          prefixIcon: Icon(Icons.search,
              color: GlobalColors.isDarkMode
                  ? GlobalColors.bleuTurquoise
                  : Colors.grey),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
        style: GoogleFonts.robotoSlab(
          color: GlobalColors.secondaryColor,
        ),
        onChanged: (value) {
          // Implémentez la recherche ici si nécessaire
        },
      ),
    );
  }

  Widget _buildFAQItem(FAQItem faq) {
    return Container(
      margin: EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: GlobalColors.isDarkMode
            ? GlobalColors.accentColor.withOpacity(0.1)
            : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: GlobalColors.isDarkMode
            ? []
            : [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        title: Text(
          faq.question,
          style: GoogleFonts.robotoSlab(
            fontWeight: FontWeight.w600,
            color: GlobalColors.secondaryColor,
          ),
        ),
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              faq.answer,
              style: GoogleFonts.robotoSlab(
                color: GlobalColors.secondaryColor.withOpacity(0.8),
                height: 1.5,
              ),
            ),
          ),
        ],
        iconColor: GlobalColors.bleuTurquoise,
        collapsedIconColor: GlobalColors.bleuTurquoise,
        tilePadding: EdgeInsets.symmetric(horizontal: 16),
      ),
    );
  }

  Widget _buildContactCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: GlobalColors.isDarkMode
            ? GlobalColors.bleuTurquoise.withOpacity(0.2)
            : GlobalColors.bleuTurquoise.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: GlobalColors.bleuTurquoise.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.help_outline,
            size: 40,
            color: GlobalColors.bleuTurquoise,
          ),
          SizedBox(height: 15),
          Text(
            'Vous ne trouvez pas de réponse ?',
            style: GoogleFonts.robotoSlab(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: GlobalColors.secondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 10),
          Text(
            'Notre équipe support est disponible 7j/7 pour vous aider',
            style: GoogleFonts.robotoSlab(
              color: GlobalColors.secondaryColor.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => _sendEmail(),
            style: ElevatedButton.styleFrom(
              backgroundColor: GlobalColors.bleuTurquoise,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
            ),
            child: Text(
              'Contacter le support',
              style: GoogleFonts.robotoSlab(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'saldaeTrip@gmail.com',
      queryParameters: {
        'subject': 'Demande de support - Voyageo App',
        'body': 'Bonjour,\n\nJe contacte le support concernant...',
      },
    );

    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    } else {
      // Gérer l'erreur si l'application email n'est pas disponible
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "Impossible d'ouvrir l'application email"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class FAQItem {
  final String question;
  final String answer;

  FAQItem({required this.question, required this.answer});
}