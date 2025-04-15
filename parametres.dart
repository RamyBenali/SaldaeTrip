import 'package:flutter/material.dart';
import 'profile.dart';
import 'main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:ui';


class ParametresPage extends StatelessWidget {
  const ParametresPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF555353),
      body: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              width: 428,
              height: 52,
              child: Stack(
                children: [
                  Positioned(
                    left: 383.87,
                    top: 20.48,
                    child: Opacity(
                      opacity: 0.35,
                      child: Container(
                        width: 25.11,
                        height: 13.39,
                        decoration: ShapeDecoration(
                          shape: RoundedRectangleBorder(
                            side: BorderSide(width: 1, color: Colors.white),
                            borderRadius: BorderRadius.circular(2.67),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 386.15,
                    top: 22.85,
                    child: Container(
                      width: 20.54,
                      height: 8.67,
                      decoration: ShapeDecoration(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(1.33),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 25,
            top: 65,
            child: IconButton(
              icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: 30),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfilePage()),
                );
              },
            ),
          ),
          Positioned(
            left: 133,
            top: 75,
            child: Text(
              'Paramètres et activité',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: 'ADLaM Display',
                fontWeight: FontWeight.w400,
                letterSpacing: -0.30,
              ),
            ),
          ),
          Positioned(
            left: 65,
            top: 152,
            child: Text(
              'Service Client',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: 'ADLaM Display',
                fontWeight: FontWeight.w400,
                letterSpacing: -0.30,
              ),
            ),
          ),
          Positioned(
            left: 25,
            top: 148,
            child: Icon(Icons.android, color: Colors.white, size: 30),
            ),
          Positioned(
            left: 66,
            top: 193,
            child: Text(
              'Aide',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: 'ADLaM Display',
                fontWeight: FontWeight.w400,
                letterSpacing: -0.30,
              ),
            ),
          ),
          Positioned(
            left: 25,
            top: 190,
            child: Icon(Icons.help, color: Colors.white, size: 30),
          ),
          // Ligne de séparation 1
          Positioned(
            left: 25,
            top: 240,
            child: Container(
              width: 378,
              height: 2,
              decoration: ShapeDecoration(
                color: const Color(0x7FD9D9D9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
          // Devenir prestataire
          Positioned(
            left: 65,
            top: 266,
            child: Text(
              'Devenir prestataire officiel',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: 'ADLaM Display',
                fontWeight: FontWeight.w400,
                letterSpacing: -0.30,
              ),
            ),
          ),
          Positioned(
            left: 25,
            top: 263,
            child: Icon(Icons.verified_user, color: Colors.white, size: 30),
          ),
          // Ligne de séparation 2
          Positioned(
            left: 25,
            top: 313,
            child: Container(
              width: 378,
              height: 2,
              decoration: ShapeDecoration(
                color: const Color(0x7FD9D9D9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
          // Se déconnecter
          Positioned(
            left: 32,
            top: 338,
            child: GestureDetector(
              onTap: () async {
                await Supabase.instance.client.auth.signOut(); // déconnexion Supabase
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => SplashScreen()),
                      (route) => false, // supprime tout l'historique
                );
              },
              child: Text(
                'Se déconnecter',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFFE33123),
                  fontSize: 16,
                  fontFamily: 'ADLaM Display',
                  fontWeight: FontWeight.w400,
                  letterSpacing: -0.30,
                ),
              ),
            ),
          ),
          Positioned(
            left: 32,
            top: 382,
            child: GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext context) {
                    return BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
                      child: AlertDialog(
                        backgroundColor: Colors.white.withOpacity(0.95),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        title: Text(
                          "Confirmation",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        content: Text(
                          "Êtes-vous sûr de vouloir supprimer votre compte ? Cette action est irréversible.",
                          style: TextStyle(color: Colors.black87),
                        ),
                        actions: <Widget>[
                          TextButton(
                            child: Text("Annuler", style: TextStyle(color: Colors.grey[700])),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                          TextButton(
                            child: Text("Supprimer", style: TextStyle(color: Colors.red)),
                            onPressed: () async {
                              final user = Supabase.instance.client.auth.currentUser;

                              if (user == null || user.isAnonymous == true) {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Impossible de supprimer un compte anonyme."),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              try {
                                await Supabase.instance.client.auth.admin.deleteUser(user.id);
                                await Supabase.instance.client.auth.signOut();
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(builder: (context) => SplashScreen()),
                                      (route) => false,
                                );
                              } catch (e) {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Erreur lors de la suppression : $e"),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              child: Text(
                'Supprimer son compte',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFFE33123),
                  fontSize: 16,
                  fontFamily: 'ADLaM Display',
                  fontWeight: FontWeight.w400,
                  letterSpacing: -0.30,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
