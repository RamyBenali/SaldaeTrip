import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'login.dart';
import 'signin.dart';
import 'weather_main.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://xqbnjwedfurajossjgof.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhxYm5qd2VkZnVyYWpvc3NqZ29mIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDM2MTQzMDYsImV4cCI6MjA1OTE5MDMwNn0._1LKV9UaV-tsOt9wCwcD8Xp_WvXrumlp0Jv0az9rgp4',                   // Replace with your Supabase anon key
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  bool isConnected = true;
  late AnimationController _controller;
  late Animation<double> _logoAnimation;
  late Animation<double> _fadeAnimation;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  @override
  void initState() {
    super.initState();
    checkInternetConnection();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );

    _logoAnimation = Tween<double>(begin: 0, end: -80).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );

    _subscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      setState(() {
        isConnected = results.isNotEmpty && results.contains(ConnectivityResult.wifi) || results.contains(ConnectivityResult.mobile);
      });
    });

    Future.delayed(Duration(milliseconds: 2000), () {
      _controller.forward();
    });
  }

  Future<void> checkInternetConnection() async {
    var connectivityResults = await Connectivity().checkConnectivity();
    setState(() {
      isConnected = connectivityResults.isNotEmpty &&
          (connectivityResults.contains(ConnectivityResult.wifi) || connectivityResults.contains(ConnectivityResult.mobile));
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 🎨 Background
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/backimg.png'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.6),
                  BlendMode.srcOver,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 50,
            left: 100,
            child: GestureDetector(
              onTap: () async {
                try {
                  final response = await Supabase.instance.client.auth.signInAnonymously();
                  if (response.user != null) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => HomePage()),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur en mode invité : $e')),
                  );
                }
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Continuer sans se connecter',
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _logoAnimation.value),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/images/logo.png', width: 120, height: 120),
                      SizedBox(height: 10),
                      Text(
                        'SaldaTrip',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.56,
                        ),
                      ),
                      Text(
                        'Explore the real Béjaia',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontFamily: 'ABeeZee',
                          fontWeight: FontWeight.w400,
                          letterSpacing: -0.32,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          // 🎭 Affichage après animation
          Positioned(
            bottom: 100,
            left: 50,
            right: 50,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: isConnected
                  ? Column(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => LoginScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      minimumSize: Size(double.infinity, 50),
                    ),
                    child: Text("Se connecter", style: TextStyle(color: Colors.white, fontSize: 18)),
                  ),
                  SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SigninScreen()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.blue),
                      backgroundColor: Colors.white.withOpacity(0.7),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      minimumSize: Size(double.infinity, 50),
                    ),
                    child: Text("S'inscrire", style: TextStyle(color: Colors.blue, fontSize: 18)),
                  ),
                ],
              )
                  : Column(
                children: [
                  Icon(Icons.wifi_off, size: 50, color: Colors.white),
                  SizedBox(height: 10),
                  Text(
                    "Vous n’êtes pas connecter a internet, Veuillez vérifier votre connexion ",
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 30),
                  Text(
                    "OU",
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      minimumSize: Size(double.infinity, 50),
                    ),
                    child: Text("Acceder au mode hors ligne", style: TextStyle(color: Colors.white, fontSize: 17)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
