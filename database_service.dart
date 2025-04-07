import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseService {
  final supabase = Supabase.instance.client;

  Future<void> ajouterPersonne({
    required String nom,
    required String prenom,
    required String email,
    required String motdepasse,
    required String datenaiss,
    required String adresse,
    required String role,
  }) async {
    // Étape 1 : Création de l’utilisateur avec Supabase Auth
    final authResponse = await supabase.auth.signUp(
      email: email,
      password: motdepasse,
    );

    final user = authResponse.user;
    if (user == null) throw Exception("Erreur lors de l’inscription Supabase.");

    final insertResponse = await supabase.from('personne').insert({
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'motdepasse': motdepasse,
      'datenaiss': datenaiss,
      'adresse': adresse,
      'role': role,
    }).select('idpersonne');

    if (insertResponse.isEmpty) throw Exception("Insertion dans `personne` échouée.");

    final idpersonne = insertResponse.first['idpersonne'];

    await supabase.from('profiles').insert({
      'id': idpersonne,
      'profile_photo': null,
      'banner_photo': null,
      'description': 'Aucune description pour le moment',
    });
  }
}
