import 'package:flutter/material.dart';

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
            // Titre "Plage"
            const Positioned(
              left: 21,
              top: 76,
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
              top: 125,
              child: Container(
                width: 371,
                height: 48,
                padding: const EdgeInsets.all(10),
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
                      'Search',
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
                'Meilleures plages',
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
      {'name': 'Melbou', 'top': 263, 'left': 17},
      {'name': 'Ait Mendil', 'top': 263, 'left': 221},
      {'name': 'les Aiguades', 'top': 389, 'left': 17},
      {'name': 'Afaghir', 'top': 389, 'left': 221},
      {'name': 'Boulimat', 'top': 516, 'left': 17},
      {'name': 'Acherchour', 'top': 516, 'left': 221},
      {'name': 'Saket', 'top': 642, 'left': 17},
      {'name': 'Aokas', 'top': 642, 'left': 221},
      {'name': 'Boukhelifa', 'top': 768, 'left': 17},
      {'name': 'Tamelaht', 'top': 768, 'left': 221},
    ];

    return beaches.map((beach) {
      return Positioned(
        left: beach['left'].toDouble(),
        top: beach['top'].toDouble(),
        child: Column(
          children: [
          // Image de la plage
          Container(
          width: 186,
          height: 108,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            image: const DecorationImage(
              image: NetworkImage("https://placehold.co/186x108"),
              fit: BoxFit.cover,
            ),
          ),
        ),
        // Nom de la plage
        Container(
          width: 110,
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(5),
              boxShadow: [
          BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 2,
          offset: const Offset(0, 1),
          ),
          ],
        ),
        child: Text(
          beach['name'],
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 12,
            fontFamily: 'ABeeZee',
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
      ],
      ),
      );
    }).toList();
  }
}