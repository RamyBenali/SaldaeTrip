import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login.dart';

class ManualResetScreen extends StatefulWidget {
  final String email;

  const ManualResetScreen({required this.email});

  @override
  _ManualResetScreenState createState() => _ManualResetScreenState();
}

class _ManualResetScreenState extends State<ManualResetScreen> {
  final _tokenController = TextEditingController();
  final _newPasswordController = TextEditingController();
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      print('Tentative de vérification du token OTP...');
      final response = await Supabase.instance.client.auth.verifyOTP(
        email: widget.email,
        token: _tokenController.text.trim(),
        type: OtpType.recovery,
      ).timeout(const Duration(seconds: 30));

      if (response.session == null) {
        throw Exception('Session non reçue après vérification OTP');
      }

      print('Token vérifié. Session : ${response.session}');
      print('Tentative de mise à jour du mot de passe...');

      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: _newPasswordController.text),
      );

      print('Mot de passe mis à jour avec succès.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mot de passe mis à jour avec succès')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginScreen()),
      );
    } on TimeoutException catch (_) {
      print('Erreur : délai dépassé');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Délai dépassé, veuillez réessayer')),
      );
    } on AuthException catch (e) {
      print('AuthException : ${e.message}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur d\'authentification : ${e.message}')),
      );
    } catch (e, stack) {
      print('Exception inconnue : $e');
      print('Stack trace : $stack');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Réinitialisation du mot de passe'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Un email a été envoyé à ${widget.email}. Entrez le token reçu et votre nouveau mot de passe.',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _tokenController,
                decoration: const InputDecoration(
                  labelText: 'Token',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? 'Ce champ est requis' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Nouveau mot de passe',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.length < 6
                        ? 'Le mot de passe doit contenir au moins 6 caractères'
                        : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Valider', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
