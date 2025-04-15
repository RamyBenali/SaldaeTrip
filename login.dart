import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'main.dart';
import 'weather_main.dart';
import 'signin.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      final authResponse = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (authResponse.user != null) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Email ou mot de passe incorrect')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de connexion : $e')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, // important pour que ça remonte bien
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/backimg.png',
              opacity: const AlwaysStoppedAnimation(.3),
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppBar(
                            backgroundColor: Colors.transparent,
                            elevation: 0,
                            leading: IconButton(
                              icon: Icon(Icons.arrow_back, color: Colors.black),
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => SplashScreen()),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Bienvenue',
                            style: TextStyle(
                              color: Color(0xFF0D8BFF),
                              fontWeight: FontWeight.bold,
                              fontSize: 37,
                              fontFamily: 'Abril Fatface',
                            ),
                          ),
                          Text(
                            'Heureux de vous revoir, Veuillez entrer vos identifiants.',
                            textAlign: TextAlign.start,
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 22,
                              fontFamily: 'Arial',
                            ),
                          ),
                          const SizedBox(height: 50),
                          TextField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 15),
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: 'Mot de passe',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(

                              child: Text(
                              'Mot de passe oublié ?',
                              style: TextStyle(color: Colors.black, fontSize: 15),
                            ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF0D8BFF),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
                              minimumSize: Size(double.infinity, 50),
                            ),
                            child: Text(
                              'Connexion',
                              style: TextStyle(color: Colors.white, fontSize: 18),
                            ),
                          ),
                          const SizedBox(height: 20),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => SigninScreen()),
                              );
                            },
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Vous n’avez pas de compte? ',
                                    style: TextStyle(color: Colors.black, fontSize: 16),
                                  ),
                                  TextSpan(
                                    text: 'Inscrivez-vous !',
                                    style: TextStyle(color: Color(0xFF0D8BFF), fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
