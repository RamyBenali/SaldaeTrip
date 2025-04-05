import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseService {
  final SupabaseClient supabase = Supabase.instance.client;

  Future<void> ajouterPersonne({
    required String nom,
    required String prenom,
    required String email,
    required String motdepasse,
    required String datenaiss,
    required String adresse,
    required String role,
  }) async {
    try {
      // Création de l'utilisateur dans Supabase Auth
      final authResponse = await supabase.auth.signUp(
        email: email,
        password: motdepasse,
      );

      // Vérification que l'utilisateur a bien été créé
      if (authResponse.user == null) {
        throw Exception('Erreur de création de compte dans Supabase Auth');
      }

      final response = await supabase.from('personne').insert([
        {
          'nom': nom,
          'prenom': prenom,
          'email': email,
          'motdepasse': motdepasse,
          'datenaiss': datenaiss,
          'adresse': adresse,
          'role': role,
        }
      ]);
      print('✅ Insertion réussie : $response');
    } catch (error) {
      print('❌ Erreur lors de l\'ajout : $error');
      throw Exception('Erreur lors de l\'ajout : $error'); // 🔹 On lève une exception
    }
  }
}
