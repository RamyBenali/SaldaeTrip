import 'package:flutter/material.dart';
import 'weather_main.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Plages d\'Algérie',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const BeachScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class BeachScreen extends StatelessWidget {
  const BeachScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        clipBehavior: Clip.antiAlias,
        decoration: const BoxDecoration(color: Colors.white),
        child: Stack(
          children: [
            // Bouton retour en haut à gauche
            Positioned(
              top: 40,
              left: 16,
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => HomePage()),
                  );
                },
                color: Colors.black,
                iconSize: 30,
              ),
            ),
            // Titre "Plage"
            const Positioned(
              left: 21,
              top: 90,
              child: Text(
                'Plage',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 24,
                  fontFamily: 'Abril Fatface',
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),

            // Barre de recherche
            Positioned(
              left: 17,
              top: 145,
              child: Container(
                width: MediaQuery.of(context).size.width - 34,
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: ShapeDecoration(
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(width: 1, color: Color(0xFF0D8BFF)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Rechercher une plage',
                      style: TextStyle(
                        color: Color(0xFFC4C4C4),
                        fontSize: 16,
                        fontFamily: 'ABeeZee',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    Icon(Icons.search, size: 24, color: Colors.grey[600]),
                  ],
                ),
              ),
            ),

            // Titre "Meilleures plages"
            const Positioned(
              left: 24,
              top: 224,
              child: Text(
                'Meilleures plages algériennes',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontFamily: 'Abril Fatface',
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),

            // Grille des plages (2 colonnes)
            ..._buildBeachGrid(context),

            // Barre de statut (simplifiée)
            Positioned(
              left: 0,
              top: 0,
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('9:41',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Avenir'
                        )),
                    Icon(Icons.signal_cellular_alt, size: 20, color: Colors.grey[800]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildBeachGrid(BuildContext context) {
    final List<Map<String, dynamic>> beaches = [
      {
        'name': 'Melbou, Béjaïa',
        'top': 263,
        'left': 17,
        'image': 'assets/images/Rectangle2(1).png'
      },
      {
        'name': 'Ait Mendil, Jijel',
        'top': 263,
        'left': MediaQuery.of(context).size.width / 2 + 4,
        'image': 'assets/images/Rectangle3.png'
      },
      {
        'name': 'Les Aiguades, Béjaïa',
        'top': 389,
        'left': 17,
        'image': 'assets/images/Rectangle9.png'
      },
      {
        'name': 'Afaghir, Tizi Ouzou',
        'top': 389,
        'left': MediaQuery.of(context).size.width / 2 + 4,
        'image': 'assets/images/Rectangle10.png'
      },
      {
        'name': 'Boulimat, Béjaïa',
        'top': 516,
        'left': 17,
        'image': 'assets/images/Rectangle2(2).png'
      },
      {
        'name': 'Acherchour, Tipaza',
        'top': 516,
        'left': MediaQuery.of(context).size.width / 2 + 4,
        'image': 'assets/images/Rectanglex.png'
      },
      {
        'name': 'Saket, bejaia',
        'top': 642,
        'left': 17,
        'image': 'assets/images/Rectangle9(1).png'
      },
      {
        'name': 'Aokas, Béjaïa',
        'top': 642,
        'left': MediaQuery.of(context).size.width / 2 + 4,
        'image': 'assets/images/Rectangle10(1).png'
      },
      {
        'name': 'Boukhelifa, Tipaza',
        'top': 768,
        'left': 17,
        'image': 'assets/images/Rectangle9(2).png'
      },
      {
        'name': 'Tamelaht, bejaia',
        'top': 768,
        'left': MediaQuery.of(context).size.width / 2 + 4,
        'image': 'assets/images/Rectangle9(3).png'
      },
    ];

    return beaches.map((beach) {
      return Positioned(
        left: beach['left'].toDouble(),
        top: beach['top'].toDouble(),
        child: Column(
          children: [
            // Container pour l'image avec le texte à l'intérieur en bas à gauche
            Container(
              width: MediaQuery.of(context).size.width / 2 - 34,
              height: 108,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(
                  image: AssetImage(beach['image']), // Utilisation des images locales
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.2),
                    BlendMode.darken,
                  ),
                ),
              ),
              child: Stack(
                children: [
                  // Le texte en bas à gauche de l'image
                  Positioned(
                    left: 8, // Décalage horizontal
                    bottom: 8, // Décalage vertical à partir du bas
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5), // Fond semi-transparent pour lisibilité
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        beach['name'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'ABeeZee',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}
