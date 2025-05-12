import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'login.dart';
import 'main.dart';
import 'TermsAndConditionScreen.dart';
import 'database_service.dart';
import 'GlovalColors.dart';

class SigninScreen extends StatefulWidget {
  @override
  _SigninScreenState createState() => _SigninScreenState();
}

class _SigninScreenState extends State<SigninScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _prenomController = TextEditingController();
  final TextEditingController _adresseController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  final DatabaseService _databaseService = DatabaseService();

  bool _isPasswordError = true;
  bool _isPasswordMatchError = false;
  String _passwordMatchErrorMessage = "";

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() {
        _dateController.text = DateFormat('dd/MM/yyyy').format(pickedDate);
      });
    }
  }

  bool _isPasswordSyntaxValid(String password) {
    final regex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[\W_]).{10,}$');
    return regex.hasMatch(password);
  }

  bool _validateEmail(String email) {
    final RegExp emailRegExp = RegExp(
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'); // Regex pour email valide
    return emailRegExp.hasMatch(email);
  }
  bool _isEmailValid = true;

  void _nextPage() {
    if (_currentPage < 2) {
      setState(() {
        _currentPage++;
      });
      _pageController.animateToPage(
        _currentPage,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
      });
      _pageController.animateToPage(
        _currentPage,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _register() async {
    setState(() {
      _isPasswordError = _isPasswordSyntaxValid(_passwordController.text);
      _isPasswordMatchError = _passwordController.text != _confirmPasswordController.text;
    });

    if (_isPasswordError && !_isPasswordMatchError && _validateEmail(_emailController.text)) {
      try {
        await _databaseService.ajouterPersonne(
          nom: _nomController.text,
          prenom: _prenomController.text,
          email: _emailController.text,
          motdepasse: _passwordController.text,
          datenaiss: _dateController.text,
          adresse: _adresseController.text,
          role: 'Voyageur',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Inscription réussie !")),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => TermsAndConditionsScreen()),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur lors de l'inscription : $e")),
        );
      }
    } else {
      if (!_isPasswordError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Mot de passe invalide")),
        );
      }
      if (_isPasswordMatchError) {
        setState(() {
          _passwordMatchErrorMessage = "Les mots de passe ne correspondent pas";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            child: Column(
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Inscription',
                        style: GoogleFonts.robotoSlab(
                          color: GlobalColors.bleuTurquoise,
                          fontWeight: FontWeight.bold,
                          fontSize: 37,
                        ),
                      ),
                      Text(
                        'Bienvenue, Veuillez remplir les champs ci-dessous.',
                        style: GoogleFonts.robotoSlab(
                          color: Colors.black,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                    child: PageView(
                      controller: _pageController,
                      physics: NeverScrollableScrollPhysics(),
                      children: [
                        SingleChildScrollView(
                          child: Column(
                            children: [
                              TextField(controller: _nomController, decoration: InputDecoration(labelText: 'Nom', border: OutlineInputBorder())),
                              SizedBox(height: 15),
                              TextField(controller: _prenomController, decoration: InputDecoration(labelText: 'Prénom', border: OutlineInputBorder())),
                            ],
                          ),
                        ),
                        SingleChildScrollView(
                          child: Column(
                            children: [
                              TextField(controller: _dateController, readOnly: true, decoration: InputDecoration(labelText: 'Date de Naissance', suffixIcon: Icon(Icons.calendar_today), border: OutlineInputBorder()), onTap: () => _selectDate(context)),
                              SizedBox(height: 15),
                              TextField(controller: _adresseController, decoration: InputDecoration(labelText: 'Adresse', border: OutlineInputBorder())),
                              SizedBox(height: 15),
                              TextField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                onChanged: (value) {
                                  setState(() {
                                    _isEmailValid = _validateEmail(value);
                                  });
                                },
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  labelStyle: GoogleFonts.robotoSlab(color: _isEmailValid ? Colors.black : Colors.red),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: _isEmailValid ?  GlobalColors.bleuTurquoise : Colors.red,
                                      width: 2,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: _isEmailValid ? Colors.grey : Colors.red,
                                      width: 1,
                                    ),
                                  ),
                                  errorText: _isEmailValid ? null : "Format d'email invalide",
                                ),
                              ),
                            ],
                          ),
                        ),
                        SingleChildScrollView(
                          child: Column(
                            children: [
                              Text(
                                "Le mot de passe doit contenir au moins 10 caractères,\n1 minuscule, 1 majuscule, 1 chiffre et 1 symbole.",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.robotoSlab(
                                  color: _isPasswordError ? Colors.red : Colors.grey,
                                  fontSize: 13,
                                ),
                              ),
                              SizedBox(height: 5),
                              TextField(
                                controller: _passwordController,
                                obscureText: true,
                                decoration: InputDecoration(
                                  labelText: 'Mot de passe',
                                  labelStyle: GoogleFonts.robotoSlab(color: _isPasswordError ? Colors.red : Colors.black),
                                  border: OutlineInputBorder(),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: _isPasswordError ? Colors.red : Colors.grey,
                                    ),
                                  ),
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    _isPasswordError = !_isPasswordSyntaxValid(value);
                                  });
                                },
                              ),
                              SizedBox(height: 10),
                              TextField(
                                controller: _confirmPasswordController,
                                obscureText: true,
                                onChanged: (value) {
                                  setState(() {
                                    _isPasswordMatchError = _passwordController.text != value;
                                    _passwordMatchErrorMessage =
                                    _isPasswordMatchError ? "Les mots de passe ne correspondent pas" : "";
                                  });
                                },
                                decoration: InputDecoration(
                                  labelText: 'Confirmez le mot de passe',
                                  labelStyle: GoogleFonts.robotoSlab(color: _isPasswordMatchError ? Colors.red : Colors.black),
                                  border: OutlineInputBorder(),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: _isPasswordMatchError ? Colors.red : Colors.grey,
                                    ),
                                  ),
                                  errorText: _isPasswordMatchError ? _passwordMatchErrorMessage : null,
                                ),
                              ),
                              SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: _register,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: GlobalColors.bleuTurquoise,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
                                  minimumSize: Size(double.infinity, 50),
                                ),
                                child: Text("S'inscrire", style: GoogleFonts.robotoSlab(color: Colors.white, fontSize: 18)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => LoginScreen()));
                        },
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(text: 'Vous avez déjà un compte? ', style: GoogleFonts.robotoSlab(color: Colors.black, fontSize: 14)),
                              TextSpan(text: 'Connectez-vous !', style: GoogleFonts.robotoSlab(color: GlobalColors.bleuTurquoise, fontSize: 14)),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: _currentPage > 0 ? _previousPage : null,
                            icon: Icon(Icons.arrow_back, color: _currentPage > 0 ? GlobalColors.bleuTurquoise : Colors.grey, size: 32),
                          ),
                          IconButton(
                            onPressed: _currentPage < 2 ? _nextPage : null,
                            icon: Icon(Icons.arrow_forward, color: _currentPage < 2 ? GlobalColors.bleuTurquoise : Colors.grey, size: 32),
                          ),
                        ],
                      ),
                      SizedBox(height: 15),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
