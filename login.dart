import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'main.dart';
import 'manual_reset_screen.dart.dart';
import 'weather_main.dart';
import 'signin.dart';
import 'database_service.dart';
import 'GlovalColors.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isFalseConnect = false;
  bool _isResetPasswordMode = false;
  bool _isLoading = false;
  bool _obscurePassword = true;


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
      _isFalseConnect = true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Erreur de connexion : l'email ou le mot de passe est incorrecte",
          ),
        ),
      );
    }
  }

  void _resetPassword() async {
  final email = _emailController.text.trim();
  if (email.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Veuillez entrer votre adresse e-mail.")),
    );
    return;
  }

  try {
    setState(() => _isLoading = true); 
    
    await DatabaseService().resetPassword(email);

    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Un OTP a été envoyé à $email. Vérifiez votre boîte de réception."),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );

    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ManualResetScreen(email: email),
      ),
    );

  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Erreur lors de l'envoi du lien: ${e.toString()}"),
        backgroundColor: Colors.red,
      ),
    );
  } finally {
    if (mounted) setState(() => _isLoading = false); 
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
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
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppBar(
                            backgroundColor: Colors.transparent,
                            elevation: 0,
                            leading:
                                _isResetPasswordMode
                                    ? Container()
                                    : IconButton(
                                      icon: Icon(
                                        Icons.arrow_back,
                                        color: Colors.black,
                                      ),
                                      onPressed:
                                          () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (context) => SplashScreen(),
                                            ),
                                          ),
                                    ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _isResetPasswordMode
                                ? 'Réinitialisation'
                                : 'Bienvenue',
                            style: GoogleFonts.robotoSlab(
                              color: GlobalColors.bleuTurquoise,
                              fontWeight: FontWeight.bold,
                              fontSize: 37,
                            ),
                          ),
                          Text(
                            _isResetPasswordMode
                                ? 'Entrez votre email pour réinitialiser votre mot de passe'
                                : 'Heureux de vous revoir, Veuillez entrer vos identifiants.',
                            textAlign: TextAlign.start,
                            style: GoogleFonts.robotoSlab(
                              color: Colors.black,
                              fontSize: 22,
                            ),
                          ),
                          const SizedBox(height: 50),
                          TextField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              border: OutlineInputBorder(),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color:
                                      !_isFalseConnect
                                          ? Colors.blue
                                          : Colors.red,
                                  width: 2,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color:
                                      !_isFalseConnect
                                          ? Colors.grey
                                          : Colors.red,
                                  width: 1,
                                ),
                              ),
                            ),
                          ),
                          if (!_isResetPasswordMode) ...[
                            const SizedBox(height: 15),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Mot de passe',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () {
                                    setState(() => _obscurePassword = !_obscurePassword);
                                  },
                                ),focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color:
                                  !_isFalseConnect
                                      ? Colors.blue
                                      : Colors.red,
                                  width: 2,
                                ),
                              ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color:
                                    !_isFalseConnect
                                        ? Colors.grey
                                        : Colors.red,
                                    width: 1,
                                  ),
                                ),
                              ),

                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Password is required';
                                if (value.length < 8) return 'Minimum 8 characters';
                                if (!value.contains(RegExp(r'[A-Z]')))
                                  return 'Include uppercase letter';
                                if (!value.contains(RegExp(r'[0-9]'))) return 'Include number';
                                if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
                                  return 'Include special character';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isResetPasswordMode = true;
                                  });
                                },
                                child: Text(
                                  'Mot de passe oublié ?',
                                  style: GoogleFonts.robotoSlab(
                                    color: Colors.black,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed:
                                _isResetPasswordMode ? _resetPassword : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: GlobalColors.bleuTurquoise,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(7),
                              ),
                              minimumSize: Size(double.infinity, 50),
                            ),
                            child: Text(
                              _isResetPasswordMode
                                  ? 'Envoyer le lien'
                                  : 'Connexion',
                              style: GoogleFonts.robotoSlab(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          if (_isResetPasswordMode) ...[
                            const SizedBox(height: 20),
                            Align(
                              alignment: Alignment.center,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isResetPasswordMode = false;
                                  });
                                },
                                child: Text(
                                  'Retour à la connexion',
                                  style: GoogleFonts.robotoSlab(
                                    color: Color(0xFF0D8BFF),
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ] else ...[
                            const SizedBox(height: 20),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SigninScreen(),
                                  ),
                                );
                              },
                              child: Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Vous n’avez pas de compte? ',
                                      style: GoogleFonts.robotoSlab(
                                        color: Colors.black,
                                        fontSize: 16,
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'Inscrivez-vous !',
                                      style: GoogleFonts.robotoSlab(
                                        color: GlobalColors.bleuTurquoise,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
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
