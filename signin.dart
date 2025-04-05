import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'login.dart';
import 'main.dart';
import 'TermsAndConditionScreen.dart';
import 'database_service.dart'; // Importer le service de base de données

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

        // Affichage du message de succès
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Inscription réussie !")),
        );

        // Rediriger vers l'écran de connexion
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
      // Affichage des erreurs
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
          Column(
            children: [
              PreferredSize(
                preferredSize: Size.fromHeight(kToolbarHeight),
                child: AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Inscription',
                        style: TextStyle(
                          color: Color(0xFF0D8BFF),
                          fontWeight: FontWeight.bold,
                          fontSize: 37,
                          fontFamily: 'Abril Fatface',
                        ),
                      ),
                      Text(
                        'Bienvenue, Veuillez remplir les champs ci-dessous.',
                        textAlign: TextAlign.start,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                          fontFamily: 'Arial',
                        ),
                      ),
                      SizedBox(height: 20),
                      Expanded(
                        child: PageView(
                          controller: _pageController,
                          physics: NeverScrollableScrollPhysics(),
                          children: [
                            Column(
                              children: [
                                TextField(controller: _nomController, decoration: InputDecoration(labelText: 'Nom', border: OutlineInputBorder())),
                                SizedBox(height: 15),
                                TextField(controller: _prenomController, decoration: InputDecoration(labelText: 'Prénom', border: OutlineInputBorder())),
                              ],
                            ),
                            Column(
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
                                    labelStyle: TextStyle(color: _isEmailValid ? Colors.black : Colors.red),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: _isEmailValid ? Colors.blue : Colors.red,
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
                            Column(
                              children: [
                                Text(
                                  textAlign: TextAlign.center,
                                  "le mot de passe doit contenir au moins 10 caractères \n au mois 1 minuscul, 1 majuscule, 1 chiffre et un symbole",
                                  style: TextStyle(
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
                                    labelStyle: TextStyle(color: _isPasswordError ? Colors.red : Colors.black),
                                    border: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: _isPasswordError ? Colors.red : Colors.black,
                                        width: 2,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: _isPasswordError ? Colors.red : Colors.grey,
                                        width: 1,
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
                                    labelStyle: TextStyle(color: _isPasswordMatchError ? Colors.red : Colors.black),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: _isPasswordMatchError ? Colors.red : Colors.blue, // Rouge si erreur
                                        width: 2,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: _isPasswordMatchError ? Colors.red : Colors.grey, // Rouge si erreur
                                        width: 1,
                                      ),
                                    ),
                                    errorText: _isPasswordMatchError ? _passwordMatchErrorMessage : null, // Affiche l’erreur

                                  ),
                                ),
                                SizedBox(height: 10),
                                ElevatedButton(
                                  onPressed: _register,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFF0D8BFF),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
                                    minimumSize: Size(double.infinity, 50),
                                  ),
                                  child: Text("S'inscrire", style: TextStyle(color: Colors.white, fontSize: 18)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => LoginScreen()),
                              );
                            },
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Vous avez déjà un compte? ',
                                    style: TextStyle(color: Colors.black, fontSize: 16),
                                  ),
                                  TextSpan(
                                    text: 'Connectez-vous !',
                                    style: TextStyle(color: Color(0xFF0D8BFF), fontSize: 16),
                                  ),
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
                                icon: Icon(Icons.arrow_back, color: _currentPage > 0 ? Color(0xFF0D8BFF) : Colors.grey, size: 32),
                              ),
                              IconButton(
                                onPressed: _currentPage < 2 ? _nextPage : null,
                                icon: Icon(Icons.arrow_forward, color: _currentPage < 2 ? Color(0xFF0D8BFF) : Colors.grey, size: 32),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 15),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}