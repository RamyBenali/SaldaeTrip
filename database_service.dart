import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class DatabaseService {
  Future<void> ajouterPersonne({
    required String nom,
    required String prenom,
    required String email,
    required String motdepasse,
    required String datenaiss,
    required String adresse,
    required String role,
  }) async {
    final supabase = Supabase.instance.client;

    final inputFormat = DateFormat('dd/MM/yyyy');
    final outputFormat = DateFormat('yyyy-MM-dd');
    final parsedDate = inputFormat.parse(datenaiss);
    final formattedDate = outputFormat.format(parsedDate);

    final authResponse = await supabase.auth.signUp(
      email: email,
      password: motdepasse,
    );

    final user = authResponse.user;
    if (user == null) throw Exception("Erreur lors de l’inscription Supabase.");

    final userId = user.id;

    // Insertion dans la table `personne` avec le user_id
    final insertResponse = await supabase.from('personne').insert({
      'user_id': userId,
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'datenaiss': formattedDate,
      'adresse': adresse,
      'role': role,
    });

    // Insertion dans la table `profiles` (lié aussi par user_id)
    await supabase.from('profiles').insert({
      'user_id': userId,
      'profile_photo': null,
      'banner_photo': null,
      'description': 'Aucune description pour le moment',
    });

    // Insertion dans la table `voyageur` (lié aussi par user_id)
    await supabase.from('voyageur').insert({
      'user_id': userId,
      'idlieu': null,
      'idoffre': null,
      'idservice': null,
    });
  }
}
